class_name VisionSystem
extends RefCounted

## 視界・索敵システム
## 仕様書: docs/vision_v0.1.md
##
## 敵ユニットの発見・追跡・状態遷移（CONF/SUS/LOST）を管理

# =============================================================================
# ContactRecord（接触情報）
# =============================================================================

class ContactRecord:
	var element_id: String                          ## 対象のElement ID
	var state: GameEnums.ContactState = GameEnums.ContactState.UNKNOWN
	var last_visible_tick: int = -1                 ## 最後に視認できたtick
	var pos_est_m: Vector2 = Vector2.ZERO           ## 推定位置
	var vel_est_mps: Vector2 = Vector2.ZERO         ## 推定速度
	var pos_error_m: float = 0.0                    ## 位置誤差半径
	var type_hint: String = ""                      ## ユニット種別ヒント
	var visible_streak_scans: int = 0               ## 連続視認回数
	var classify_progress: float = 0.0              ## 同定進捗（0-1）

	func _init(p_element_id: String) -> void:
		element_id = p_element_id

# =============================================================================
# 内部状態
# =============================================================================

## 陣営ごとのContactRecord辞書 { element_id: ContactRecord }
var _contacts: Dictionary = {
	GameEnums.Faction.BLUE: {},
	GameEnums.Faction.RED: {},
}

## 視認ダーティフラグ（イベント駆動の前倒しトリガ用）
var _vision_dirty: bool = true

## 最後にスキャンしたtick
var _last_scan_tick: int = -1

## 依存
var _world_model: WorldModel
var _map_data: MapData

# =============================================================================
# 初期化
# =============================================================================

func setup(world_model: WorldModel, map_data: MapData) -> void:
	_world_model = world_model
	_map_data = map_data


func mark_dirty() -> void:
	_vision_dirty = true

# =============================================================================
# Tick更新
# =============================================================================

## 毎tick呼ばれる更新処理
func update(current_tick: int, dt: float) -> void:
	# 状態遷移は毎tick
	_update_contact_states(current_tick, dt)

	# 視認チェックは間引き（5Hz = 2tickごと）またはダーティ時
	var should_scan := _vision_dirty or (current_tick - _last_scan_tick >= GameConstants.VISION_SCAN_INTERVAL_TICKS)
	if should_scan:
		_perform_vision_scan(current_tick)
		_last_scan_tick = current_tick
		_vision_dirty = false


## Contact状態の更新（毎tick）
func _update_contact_states(current_tick: int, dt: float) -> void:
	for faction in [GameEnums.Faction.BLUE, GameEnums.Faction.RED]:
		var contacts: Dictionary = _contacts[faction]
		var to_remove: Array[String] = []

		for element_id in contacts:
			var contact: ContactRecord = contacts[element_id]
			var ticks_since_visible := current_tick - contact.last_visible_tick

			match contact.state:
				GameEnums.ContactState.CONFIRMED:
					if ticks_since_visible >= GameConstants.T_CONF_TO_SUS_TICKS:
						contact.state = GameEnums.ContactState.SUSPECTED
						# SUSに移行時、誤差成長開始
						contact.pos_error_m = 0.0

				GameEnums.ContactState.SUSPECTED:
					if ticks_since_visible >= GameConstants.T_SUS_TO_LOST_TICKS:
						contact.state = GameEnums.ContactState.LOST
					else:
						# 位置誤差の成長
						_grow_position_error(contact, dt)

				GameEnums.ContactState.LOST:
					if ticks_since_visible >= GameConstants.T_LOST_TO_FORGET_TICKS:
						to_remove.append(element_id)
					else:
						_grow_position_error(contact, dt)

		# 忘却されたContactを削除
		for element_id in to_remove:
			contacts.erase(element_id)


## 位置誤差の成長
func _grow_position_error(contact: ContactRecord, dt: float) -> void:
	contact.pos_error_m = minf(
		GameConstants.ERROR_MAX_M,
		contact.pos_error_m + GameConstants.ERROR_GROWTH_MPS * dt
	)
	# 推定位置も速度で移動
	contact.pos_est_m += contact.vel_est_mps * dt

# =============================================================================
# 視認スキャン
# =============================================================================

## 全要素の視認チェック
func _perform_vision_scan(current_tick: int) -> void:
	if not _world_model:
		return

	# BLUE陣営がRED陣営を観測
	_scan_faction_vs_faction(GameEnums.Faction.BLUE, GameEnums.Faction.RED, current_tick)
	# RED陣営がBLUE陣営を観測
	_scan_faction_vs_faction(GameEnums.Faction.RED, GameEnums.Faction.BLUE, current_tick)


## 観測側陣営が目標陣営を観測
func _scan_faction_vs_faction(observer_faction: GameEnums.Faction, target_faction: GameEnums.Faction, current_tick: int) -> void:
	var observers := _world_model.get_elements_for_faction(observer_faction)
	var targets := _world_model.get_elements_for_faction(target_faction)
	var contacts: Dictionary = _contacts[observer_faction]

	for target in targets:
		# DESTROYEDな目標はスキップ
		if target.state == GameEnums.UnitState.DESTROYED:
			continue

		var is_visible := false
		var best_t_los: float = 0.0

		# 各観測者からの視認チェック
		for observer in observers:
			# DESTROYEDな観測者はスキップ
			if observer.state == GameEnums.UnitState.DESTROYED:
				continue
			var result := _check_visibility(observer, target)
			if result.visible:
				is_visible = true
				best_t_los = maxf(best_t_los, result.t_los)

		# Contactの更新
		_update_contact(contacts, target, is_visible, best_t_los, current_tick)


## 観測者から目標への視認チェック
func _check_visibility(observer: ElementData.ElementInstance, target: ElementData.ElementInstance) -> Dictionary:
	var result := {
		"visible": false,
		"t_los": 0.0,
		"los_result": GameEnums.LoSResult.CLEAR,
	}

	# 距離チェック
	var distance := observer.position.distance_to(target.position)
	var r_eff := _calculate_effective_range(observer, target)

	if distance > r_eff:
		return result

	# LoSチェック
	var los := _check_line_of_sight(observer.position, target.position)
	result.los_result = los.result
	result.t_los = los.transmittance

	# 透過率が閾値以下なら視認不可
	if los.transmittance < GameConstants.LOS_BLOCK_THRESHOLD:
		return result

	result.visible = true
	return result


## 実効発見距離の計算
func _calculate_effective_range(observer: ElementData.ElementInstance, target: ElementData.ElementInstance) -> float:
	if not observer.element_type:
		return 0.0

	var r_base := observer.element_type.spot_range_base

	# 目標位置の隠蔽係数
	var m_terrain := _get_concealment_modifier(target.position)

	# 目標の活動係数
	var m_activity := _get_activity_modifier(target)

	# 観測側の状態係数
	var m_observer := _get_observer_modifier(observer)

	return r_base * m_terrain * m_activity * m_observer


## 地形による隠蔽係数
func _get_concealment_modifier(pos: Vector2) -> float:
	if not _map_data:
		return 1.0

	var terrain := _map_data.get_terrain_at(pos)
	match terrain:
		GameEnums.TerrainType.OPEN:
			return 1.00
		GameEnums.TerrainType.ROAD:
			return 1.00
		GameEnums.TerrainType.FOREST:
			return 0.60
		GameEnums.TerrainType.URBAN:
			return 0.70
		GameEnums.TerrainType.WATER:
			return 1.00
		_:
			return 1.00


## 目標の活動による係数
func _get_activity_modifier(target: ElementData.ElementInstance) -> float:
	# 移動中は見つかりやすい
	if target.is_moving:
		if target.element_type and target.element_type.mobility_class == GameEnums.MobilityType.FOOT:
			return 1.15
		else:
			return 1.25

	# TODO: 射撃中の判定
	return 1.00


## 観測側の状態による係数
func _get_observer_modifier(observer: ElementData.ElementInstance) -> float:
	var suppression := observer.suppression
	if suppression < 0.40:
		return 1.00
	elif suppression < 0.70:
		return 0.75
	elif suppression < 0.90:
		return 0.40
	else:
		return 0.20

# =============================================================================
# LoS判定
# =============================================================================

## 2点間のLoSチェック
func _check_line_of_sight(from: Vector2, to: Vector2) -> Dictionary:
	var result := {
		"result": GameEnums.LoSResult.CLEAR,
		"transmittance": 1.0,
	}

	if not _map_data:
		return result

	# HardBlock判定（v0.1では建物ポリゴンがないため省略）
	# TODO: 建物・崖ポリゴンとの交差判定

	# SoftOcclusion: 森林の透過率計算
	var forest_distance := _calculate_forest_crossing_distance(from, to)
	var t_forest := exp(-forest_distance / GameConstants.FOREST_LOS_DECAY_M)

	# SoftOcclusion: 煙の透過率計算（v0.1では煙幕未実装）
	var t_smoke := 1.0

	# 最終透過率
	var t_los := t_forest * t_smoke
	result.transmittance = t_los

	if t_los < GameConstants.LOS_BLOCK_THRESHOLD:
		result.result = GameEnums.LoSResult.HARD_BLOCKED
	elif t_los < 1.0:
		result.result = GameEnums.LoSResult.SOFT_OCCLUDED

	return result


## 森林内通過距離の計算
func _calculate_forest_crossing_distance(from: Vector2, to: Vector2) -> float:
	if not _map_data:
		return 0.0

	# 簡易実装: 線分をサンプリングして森林内の距離を計算
	var total_distance := from.distance_to(to)
	if total_distance < 1.0:
		return 0.0

	var forest_distance := 0.0
	var sample_count := int(total_distance / 10.0) + 1  # 10mごとにサンプリング
	sample_count = mini(sample_count, 50)  # 上限

	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var sample_pos := from.lerp(to, t)
		var terrain := _map_data.get_terrain_at(sample_pos)
		if terrain == GameEnums.TerrainType.FOREST:
			forest_distance += total_distance / float(sample_count)

	return forest_distance

# =============================================================================
# Contact更新
# =============================================================================

## Contactの更新
func _update_contact(contacts: Dictionary, target: ElementData.ElementInstance, is_visible: bool, t_los: float, current_tick: int) -> void:
	var element_id := target.id

	# 新規Contact作成
	if element_id not in contacts:
		if is_visible:
			var contact := ContactRecord.new(element_id)
			contact.visible_streak_scans = 1
			contact.last_visible_tick = current_tick
			contact.pos_est_m = target.position
			contact.vel_est_mps = target.velocity
			contacts[element_id] = contact
		return

	var contact: ContactRecord = contacts[element_id]

	if is_visible:
		contact.visible_streak_scans += 1
		contact.last_visible_tick = current_tick
		contact.pos_est_m = target.position
		contact.vel_est_mps = target.velocity
		contact.pos_error_m = 0.0

		# CONF確定判定
		if contact.visible_streak_scans >= GameConstants.CONF_ACQUIRE_STREAK:
			contact.state = GameEnums.ContactState.CONFIRMED
			contact.type_hint = target.element_type.id if target.element_type else ""
	else:
		contact.visible_streak_scans = 0

# =============================================================================
# 公開API
# =============================================================================

## 指定陣営から見た敵のContactリストを取得
func get_contacts_for_faction(faction: GameEnums.Faction) -> Array[ContactRecord]:
	var result: Array[ContactRecord] = []
	var contacts: Dictionary = _contacts[faction]
	for element_id in contacts:
		result.append(contacts[element_id])
	return result


## 指定陣営から見た特定敵のContactを取得
func get_contact(faction: GameEnums.Faction, element_id: String) -> ContactRecord:
	var contacts: Dictionary = _contacts[faction]
	if element_id in contacts:
		return contacts[element_id]
	return null


## 指定陣営から敵Elementが見えているか
func is_element_visible(viewer_faction: GameEnums.Faction, element_id: String) -> bool:
	var contact := get_contact(viewer_faction, element_id)
	if contact:
		return contact.state == GameEnums.ContactState.CONFIRMED
	return false


## 指定陣営の敵Elementの表示状態を取得
func get_element_visibility_state(viewer_faction: GameEnums.Faction, element_id: String) -> GameEnums.ContactState:
	var contact := get_contact(viewer_faction, element_id)
	if contact:
		return contact.state
	return GameEnums.ContactState.UNKNOWN
