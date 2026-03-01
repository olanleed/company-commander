## アーカイブ: 旧CaptureSystem
## 現在は scripts/systems/capture_system.gd を使用
## class_name は競合を避けるため削除済み
extends RefCounted

## 拠点制圧システム
## 仕様書: docs/capture_v0.1.md
##
## 拠点制圧の計算を行う。
## - CapturePower（確保）: 0→自陣営支配へ進める力
## - NeutralizePower（奪取）: 敵支配を0へ戻す力
## - ContestPower（争奪）: 敵の占領進行を止める力

# =============================================================================
# シグナル
# =============================================================================

signal cp_state_changed(cp_id: String, old_state: GameEnums.CPState, new_state: GameEnums.CPState)
signal cp_captured(cp_id: String, faction: GameEnums.Faction)
signal cp_neutralized(cp_id: String)
signal cp_contested(cp_id: String, is_contested: bool)

# =============================================================================
# 定数
# =============================================================================

## 1tickあたりのdelta_milli基準 = CAPTURE_RATE × 1000 × dt
const DELTA_MILLI_PER_POWER: float = GameConstants.CAPTURE_RATE * 1000.0 * GameConstants.SIM_DT  # = 150

# =============================================================================
# 公開メソッド
# =============================================================================

## 占領更新を実行
## world_model: WorldModel（Element情報を持つ）
## map_data: MapData（CapturePoint情報を持つ）
func update(world_model: WorldModel, map_data: MapData) -> void:
	for cp in map_data.capture_points:
		_update_capture_point(cp, world_model, map_data.cp_radius_m)


## Element が占領に寄与できるかどうか
func can_contribute_to_capture(element: ElementData.ElementInstance) -> bool:
	# DESTROYED は寄与しない
	if element.state == GameEnums.UnitState.DESTROYED:
		return false

	# Strength <= 15 は寄与しない
	if element.current_strength <= GameConstants.STRENGTH_COMBAT_INEFFECTIVE:
		return false

	# カテゴリチェック（LOG/HQ/WEAP は寄与しない）
	if not element.element_type:
		return false

	var category := element.element_type.category
	match category:
		ElementData.Category.LOG, ElementData.Category.HQ, ElementData.Category.WEAP:
			return false

	return true


## Element の占領パワーを取得
## Returns: {capture: float, neutralize: float, contest: float}
func get_element_power(element: ElementData.ElementInstance) -> Dictionary:
	if not can_contribute_to_capture(element):
		return {"capture": 0.0, "neutralize": 0.0, "contest": 0.0}

	# 基礎パワーを取得
	var base := _get_base_power(element)

	# 倍率を計算
	var m_strength := _get_strength_multiplier(element)
	var m_supp := _get_suppression_multiplier(element)
	var m_posture := _get_posture_multiplier(element)

	var total_mult := m_strength * m_supp * m_posture

	return {
		"capture": base.capture * total_mult,
		"neutralize": base.neutralize * total_mult,
		"contest": base.contest * total_mult,
	}


## 拠点の各陣営の有効パワーを取得
func get_cp_effective_power(cp: MapData.CapturePoint, world_model: WorldModel, radius_m: float) -> Dictionary:
	var blue_cap := 0.0
	var blue_neut := 0.0
	var blue_contest := 0.0
	var red_cap := 0.0
	var red_neut := 0.0
	var red_contest := 0.0

	for element in world_model.elements:
		if not _is_in_cp_zone(element.position, cp.position, radius_m):
			continue

		var power := get_element_power(element)

		if element.faction == GameEnums.Faction.BLUE:
			blue_cap += power.capture
			blue_neut += power.neutralize
			blue_contest += power.contest
		elif element.faction == GameEnums.Faction.RED:
			red_cap += power.capture
			red_neut += power.neutralize
			red_contest += power.contest

	# スタッキング上限を適用
	return {
		"blue_capture": minf(blue_cap, GameConstants.CAPTURE_CAP),
		"blue_neutralize": minf(blue_neut, GameConstants.NEUTRALIZE_CAP),
		"blue_contest": minf(blue_contest, GameConstants.CONTEST_CAP),
		"red_capture": minf(red_cap, GameConstants.CAPTURE_CAP),
		"red_neutralize": minf(red_neut, GameConstants.NEUTRALIZE_CAP),
		"red_contest": minf(red_contest, GameConstants.CONTEST_CAP),
	}


# =============================================================================
# 内部メソッド
# =============================================================================

## 個別のCPを更新
func _update_capture_point(cp: MapData.CapturePoint, world_model: WorldModel, radius_m: float) -> void:
	var old_state := cp.state
	var power := get_cp_effective_power(cp, world_model, radius_m)

	# Step 1: Contest判定
	var is_contested: bool = power.blue_contest > GameConstants.CONTEST_THRESHOLD and power.red_contest > GameConstants.CONTEST_THRESHOLD

	if is_contested:
		if cp.state != GameEnums.CPState.CONTESTED:
			cp.state = GameEnums.CPState.CONTESTED
			cp_contested.emit(cp.id, true)
			if old_state != cp.state:
				cp_state_changed.emit(cp.id, old_state, cp.state)
		return  # CONTESTEDでは値は変化しない

	# Step 2: 片方だけ存在する場合
	var blue_present: bool = power.blue_contest > GameConstants.CONTEST_THRESHOLD
	var red_present: bool = power.red_contest > GameConstants.CONTEST_THRESHOLD

	if blue_present:
		_process_blue_control(cp, power)
	elif red_present:
		_process_red_control(cp, power)
	# 誰もいない場合は値を維持

	# 状態を確定
	_finalize_state(cp)

	# 状態変化をシグナル
	if old_state != cp.state:
		cp_state_changed.emit(cp.id, old_state, cp.state)

		# 制圧完了イベント
		if cp.state == GameEnums.CPState.CONTROLLED_BLUE:
			cp_captured.emit(cp.id, GameEnums.Faction.BLUE)
		elif cp.state == GameEnums.CPState.CONTROLLED_RED:
			cp_captured.emit(cp.id, GameEnums.Faction.RED)

		# 中立化イベント
		if cp.state == GameEnums.CPState.NEUTRAL and old_state != GameEnums.CPState.NEUTRAL:
			cp_neutralized.emit(cp.id)

		# CONTESTED解除
		if old_state == GameEnums.CPState.CONTESTED and cp.state != GameEnums.CPState.CONTESTED:
			cp_contested.emit(cp.id, false)


## Blueによる占領進行
func _process_blue_control(cp: MapData.CapturePoint, power: Dictionary) -> void:
	if cp.control_milli < 0:
		# Red寄り → Neutralize
		var delta := int(DELTA_MILLI_PER_POWER * power.blue_neutralize)
		cp.control_milli = mini(cp.control_milli + delta, 0)
	else:
		# 0以上 → Capture
		var delta := int(DELTA_MILLI_PER_POWER * power.blue_capture)
		cp.control_milli = mini(cp.control_milli + delta, GameConstants.CONTROL_MILLI_MAX)


## Redによる占領進行
func _process_red_control(cp: MapData.CapturePoint, power: Dictionary) -> void:
	if cp.control_milli > 0:
		# Blue寄り → Neutralize
		var delta := int(DELTA_MILLI_PER_POWER * power.red_neutralize)
		cp.control_milli = maxi(cp.control_milli - delta, 0)
	else:
		# 0以下 → Capture
		var delta := int(DELTA_MILLI_PER_POWER * power.red_capture)
		cp.control_milli = maxi(cp.control_milli - delta, GameConstants.CONTROL_MILLI_MIN)


## 最終状態を確定
func _finalize_state(cp: MapData.CapturePoint) -> void:
	if cp.control_milli == GameConstants.CONTROL_MILLI_MAX:
		cp.state = GameEnums.CPState.CONTROLLED_BLUE
	elif cp.control_milli == GameConstants.CONTROL_MILLI_MIN:
		cp.state = GameEnums.CPState.CONTROLLED_RED
	elif cp.control_milli == 0:
		cp.state = GameEnums.CPState.NEUTRAL
	elif cp.control_milli > 0:
		# 0より大きいがMAXではない
		if cp.state == GameEnums.CPState.CONTROLLED_RED or cp.state == GameEnums.CPState.NEUTRALIZING_RED:
			# 以前はRed支配だった → Blue が Neutralize 中
			cp.state = GameEnums.CPState.NEUTRALIZING_BLUE
		else:
			# Blue が Capture 中
			cp.state = GameEnums.CPState.CAPTURING_BLUE
	else:
		# 0より小さいがMINではない
		if cp.state == GameEnums.CPState.CONTROLLED_BLUE or cp.state == GameEnums.CPState.NEUTRALIZING_BLUE:
			# 以前はBlue支配だった → Red が Neutralize 中
			cp.state = GameEnums.CPState.NEUTRALIZING_RED
		else:
			# Red が Capture 中
			cp.state = GameEnums.CPState.CAPTURING_RED


## 基礎パワーを取得
func _get_base_power(element: ElementData.ElementInstance) -> Dictionary:
	if not element.element_type:
		return {"capture": 0.0, "neutralize": 0.0, "contest": 0.0}

	var category := element.element_type.category

	match category:
		ElementData.Category.INF:
			return {
				"capture": GameConstants.CP_POWER_INF_CAPTURE,
				"neutralize": GameConstants.CP_POWER_INF_NEUTRALIZE,
				"contest": GameConstants.CP_POWER_INF_CONTEST,
			}
		ElementData.Category.REC:
			return {
				"capture": GameConstants.CP_POWER_REC_CAPTURE,
				"neutralize": GameConstants.CP_POWER_REC_NEUTRALIZE,
				"contest": GameConstants.CP_POWER_REC_CONTEST,
			}
		ElementData.Category.VEH:
			# IFV/APC
			return {
				"capture": GameConstants.CP_POWER_VEH_CAPTURE,
				"neutralize": GameConstants.CP_POWER_VEH_NEUTRALIZE,
				"contest": GameConstants.CP_POWER_VEH_CONTEST,
			}
		ElementData.Category.ENG:
			# 工兵は歩兵扱い
			return {
				"capture": GameConstants.CP_POWER_INF_CAPTURE,
				"neutralize": GameConstants.CP_POWER_INF_NEUTRALIZE,
				"contest": GameConstants.CP_POWER_INF_CONTEST,
			}
		_:
			return {
				"capture": GameConstants.CP_POWER_NONE_CAPTURE,
				"neutralize": GameConstants.CP_POWER_NONE_NEUTRALIZE,
				"contest": GameConstants.CP_POWER_NONE_CONTEST,
			}


## Strength倍率
func _get_strength_multiplier(element: ElementData.ElementInstance) -> float:
	if element.current_strength <= GameConstants.STRENGTH_COMBAT_INEFFECTIVE:
		return 0.0
	return float(element.current_strength) / 100.0


## Suppression倍率
func _get_suppression_multiplier(element: ElementData.ElementInstance) -> float:
	match element.state:
		GameEnums.UnitState.ACTIVE:
			return 1.0
		GameEnums.UnitState.SUPPRESSED:
			return GameConstants.CAP_MULT_SUPPRESSED
		GameEnums.UnitState.PINNED:
			return GameConstants.CAP_MULT_PINNED
		GameEnums.UnitState.BROKEN, GameEnums.UnitState.ROUTING:
			return GameConstants.CAP_MULT_BROKEN
		_:
			return 0.0


## 姿勢倍率
func _get_posture_multiplier(element: ElementData.ElementInstance) -> float:
	match element.current_order_type:
		GameEnums.OrderType.DEFEND, GameEnums.OrderType.HOLD:
			return GameConstants.CP_POSTURE_DEFEND
		GameEnums.OrderType.ATTACK, GameEnums.OrderType.ATTACK_MOVE:
			return GameConstants.CP_POSTURE_ATTACK
		GameEnums.OrderType.MOVE, GameEnums.OrderType.MOVE_FAST:
			return GameConstants.CP_POSTURE_MOVE
		GameEnums.OrderType.BREAK_CONTACT, GameEnums.OrderType.RETREAT:
			return GameConstants.CP_POSTURE_BREAK_CONTACT
		_:
			return GameConstants.CP_POSTURE_DEFEND


## ゾーン内判定
func _is_in_cp_zone(element_pos: Vector2, cp_center: Vector2, radius_m: float) -> bool:
	return element_pos.distance_to(cp_center) <= radius_m

# =============================================================================
# ユーティリティ
# =============================================================================

## 陣営別保持拠点数を取得
func get_controlled_count(map_data: MapData) -> Dictionary:
	var blue_count := 0
	var red_count := 0

	for cp in map_data.capture_points:
		if cp.state == GameEnums.CPState.CONTROLLED_BLUE:
			blue_count += 1
		elif cp.state == GameEnums.CPState.CONTROLLED_RED:
			red_count += 1

	return {"blue": blue_count, "red": red_count}


## 拠点状態のデバッグ文字列
func get_cp_state_string(cp: MapData.CapturePoint) -> String:
	var state_str := ""
	match cp.state:
		GameEnums.CPState.NEUTRAL:
			state_str = "NEUTRAL"
		GameEnums.CPState.CONTROLLED_BLUE:
			state_str = "BLUE"
		GameEnums.CPState.CONTROLLED_RED:
			state_str = "RED"
		GameEnums.CPState.CAPTURING_BLUE:
			state_str = "CAP→BLUE"
		GameEnums.CPState.CAPTURING_RED:
			state_str = "CAP→RED"
		GameEnums.CPState.NEUTRALIZING_BLUE:
			state_str = "NEUT→BLUE"
		GameEnums.CPState.NEUTRALIZING_RED:
			state_str = "NEUT→RED"
		GameEnums.CPState.CONTESTED:
			state_str = "CONTESTED"

	var ratio := cp.get_control_ratio() * 100.0
	return "%s [%s] %.0f%%" % [cp.id, state_str, ratio]
