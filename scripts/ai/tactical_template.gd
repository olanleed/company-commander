class_name TacticalTemplate
extends RefCounted

## 戦術テンプレート基底クラス
## 仕様書: docs/company_ai_v0.1.md
##
## 各テンプレート（TPL_MOVE, TPL_ATTACK_CP等）の基底

# =============================================================================
# シグナル
# =============================================================================

signal phase_changed(old_phase: int, new_phase: int)
signal template_completed()
signal order_generated(element_id: String, order: Dictionary)

# =============================================================================
# プロパティ
# =============================================================================

var template_type: GameEnums.TacticalTemplate = GameEnums.TacticalTemplate.TPL_NONE
var current_phase: int = 0
var is_active: bool = false

## 目標
var target_position: Vector2 = Vector2.ZERO
var target_cp_id: String = ""

## 配下要素と役割
var element_roles: Dictionary = {}  # element_id -> ElementRole
var element_orders: Dictionary = {}  # element_id -> 現在の命令情報

## 最後の命令発行tick
var last_order_ticks: Dictionary = {}  # element_id -> tick

## 開始tick
var start_tick: int = 0

## フェーズ開始tick
var phase_start_tick: int = 0

# =============================================================================
# 依存（サブクラスで使用）
# =============================================================================

var _company_ai  # CompanyControllerAI への参照
var _world_model: WorldModel
var _map_data: MapData
var _vision_system: VisionSystem
var _risk_assessment: RiskAssessment
var _movement_system: MovementSystem
var _event_bus: CombatEventBus

# =============================================================================
# 許容リスク閾値（サブクラスでオーバーライド）
# =============================================================================

func get_risk_threshold_green() -> int:
	return 25

func get_risk_threshold_yellow() -> int:
	return 45

func get_risk_threshold_orange() -> int:
	return 65

func get_risk_threshold_red() -> int:
	return 65

# =============================================================================
# 初期化
# =============================================================================

func setup(
	company_ai,
	world_model: WorldModel,
	map_data: MapData,
	vision_system: VisionSystem,
	risk_assessment: RiskAssessment,
	movement_system: MovementSystem,
	event_bus: CombatEventBus
) -> void:
	_company_ai = company_ai
	_world_model = world_model
	_map_data = map_data
	_vision_system = vision_system
	_risk_assessment = risk_assessment
	_movement_system = movement_system
	_event_bus = event_bus


## テンプレート開始
func start(current_tick: int, elements: Array[ElementData.ElementInstance], target_pos: Vector2 = Vector2.ZERO, cp_id: String = "") -> void:
	is_active = true
	start_tick = current_tick
	phase_start_tick = current_tick
	current_phase = 0
	target_position = target_pos
	target_cp_id = cp_id

	# 役割配分
	_assign_roles(elements)

	# 初期フェーズ処理
	_on_phase_enter(current_phase, current_tick)


## テンプレート停止
func stop() -> void:
	is_active = false
	element_roles.clear()
	element_orders.clear()


## フェーズ遷移
func transition_to_phase(new_phase: int, current_tick: int) -> void:
	var old_phase := current_phase
	_on_phase_exit(old_phase, current_tick)

	current_phase = new_phase
	phase_start_tick = current_tick

	_on_phase_enter(new_phase, current_tick)
	phase_changed.emit(old_phase, new_phase)

# =============================================================================
# 更新（サブクラスでオーバーライド）
# =============================================================================

## 毎tick更新（10Hz）
func update_micro(current_tick: int, _dt: float) -> void:
	if not is_active:
		return
	# サブクラスで実装


## 接触評価（2Hz）
func update_contact_eval(current_tick: int) -> void:
	if not is_active:
		return
	# サブクラスで実装


## 戦術評価（1Hz）
func update_tactical(current_tick: int) -> void:
	if not is_active:
		return
	# サブクラスで実装

# =============================================================================
# 役割配分（サブクラスでオーバーライド）
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	# デフォルト実装：全員ASSAULT
	for element in elements:
		element_roles[element.id] = GameEnums.ElementRole.ASSAULT

# =============================================================================
# フェーズ処理（サブクラスでオーバーライド）
# =============================================================================

func _on_phase_enter(_phase: int, _current_tick: int) -> void:
	pass


func _on_phase_exit(_phase: int, _current_tick: int) -> void:
	pass

# =============================================================================
# 命令生成ヘルパー
# =============================================================================

## 移動命令を発行
func issue_move_order(element: ElementData.ElementInstance, target: Vector2, current_tick: int, use_road: bool = false) -> bool:
	if not _can_issue_order(element.id, current_tick):
		return false

	if _movement_system:
		_movement_system.issue_move_order(element, target, use_road)

	last_order_ticks[element.id] = current_tick
	element_orders[element.id] = {
		"type": GameEnums.OrderType.MOVE,
		"target": target,
		"tick": current_tick,
	}

	order_generated.emit(element.id, element_orders[element.id])
	return true


## 停止命令を発行
func issue_hold_order(element: ElementData.ElementInstance, current_tick: int) -> bool:
	if not _can_issue_order(element.id, current_tick):
		return false

	element.current_order_type = GameEnums.OrderType.HOLD
	element.current_path.clear()
	element.is_moving = false

	last_order_ticks[element.id] = current_tick
	element_orders[element.id] = {
		"type": GameEnums.OrderType.HOLD,
		"tick": current_tick,
	}

	order_generated.emit(element.id, element_orders[element.id])
	return true


## 防御命令を発行
func issue_defend_order(element: ElementData.ElementInstance, facing_target: Vector2, current_tick: int) -> bool:
	if not _can_issue_order(element.id, current_tick):
		return false

	element.current_order_type = GameEnums.OrderType.DEFEND
	element.current_path.clear()
	element.is_moving = false

	# Facingを設定
	var dir := (facing_target - element.position).normalized()
	element.facing = atan2(dir.y, dir.x)

	last_order_ticks[element.id] = current_tick
	element_orders[element.id] = {
		"type": GameEnums.OrderType.DEFEND,
		"facing_target": facing_target,
		"tick": current_tick,
	}

	order_generated.emit(element.id, element_orders[element.id])
	return true


## 命令発行可能かチェック（再命令抑制）
func _can_issue_order(element_id: String, current_tick: int) -> bool:
	if element_id not in last_order_ticks:
		return true

	var last_tick: int = last_order_ticks[element_id]
	var min_interval_ticks := int(GameConstants.MIN_REORDER_INTERVAL_SEC * GameConstants.SIM_HZ)

	return current_tick - last_tick >= min_interval_ticks

# =============================================================================
# 位置計算ヘルパー
# =============================================================================

## 支援射撃ラインの位置を計算
func find_support_by_fire_position(from_pos: Vector2, target_pos: Vector2) -> Vector2:
	if not _map_data:
		return from_pos

	var dir := (target_pos - from_pos).normalized()
	var perpendicular := Vector2(-dir.y, dir.x)

	# 目標から500-800mの位置を探索
	var best_pos := from_pos
	var best_score := -1.0

	for dist in range(int(GameConstants.SUPPORT_BY_FIRE_MIN_M), int(GameConstants.SUPPORT_BY_FIRE_MAX_M), 50):
		for offset in [-100, -50, 0, 50, 100]:
			var candidate: Vector2 = target_pos - dir * float(dist) + perpendicular * float(offset)
			var score := _evaluate_support_position(candidate, target_pos)
			if score > best_score:
				best_score = score
				best_pos = candidate

	return best_pos


func _evaluate_support_position(pos: Vector2, target_pos: Vector2) -> float:
	if not _map_data:
		return 0.0

	var score := 0.0
	var terrain := _map_data.get_terrain_at(pos)

	# 遮蔽がある位置を優先
	if terrain == GameEnums.TerrainType.FOREST or terrain == GameEnums.TerrainType.URBAN:
		score += 50.0

	# OPENは減点
	if terrain == GameEnums.TerrainType.OPEN:
		score -= 30.0

	# 目標への射線が通ることを確認（簡易）
	var mid_terrain := _map_data.get_terrain_at(pos.lerp(target_pos, 0.5))
	if mid_terrain == GameEnums.TerrainType.FOREST:
		score -= 20.0  # 森林越しは減点

	return score


## 観測点の位置を計算
func find_observation_position(target_pos: Vector2) -> Vector2:
	if not _map_data:
		return target_pos

	var best_pos := target_pos
	var best_score := -1.0

	# 目標周囲のR_standoff距離に観測点を探索
	for angle in range(0, 360, 30):
		var rad := deg_to_rad(angle)
		var dir := Vector2(cos(rad), sin(rad))
		var candidate := target_pos + dir * GameConstants.STANDOFF_RECON_M

		var score := _evaluate_observation_position(candidate, target_pos)
		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos


func _evaluate_observation_position(pos: Vector2, target_pos: Vector2) -> float:
	if not _map_data:
		return 0.0

	var score := 0.0
	var terrain := _map_data.get_terrain_at(pos)

	# 遮蔽がある位置を優先
	if terrain == GameEnums.TerrainType.FOREST:
		score += 40.0
	elif terrain == GameEnums.TerrainType.URBAN:
		score += 30.0

	# 目標への視線が通ることを確認
	var los_blocked := false
	var sample_count := 5
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var sample_pos := pos.lerp(target_pos, t)
		var sample_terrain := _map_data.get_terrain_at(sample_pos)
		if sample_terrain == GameEnums.TerrainType.URBAN:
			los_blocked = true
			break

	if los_blocked:
		score -= 100.0

	return score

# =============================================================================
# 役割別要素取得
# =============================================================================

func get_elements_by_role(role: GameEnums.ElementRole) -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []

	for element_id in element_roles:
		if element_roles[element_id] == role:
			var element := _world_model.get_element_by_id(element_id)
			if element:
				result.append(element)

	return result


func get_all_elements() -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []

	for element_id in element_roles:
		var element := _world_model.get_element_by_id(element_id)
		if element:
			result.append(element)

	return result

# =============================================================================
# リスク評価
# =============================================================================

func evaluate_risk_for_element(element: ElementData.ElementInstance) -> RiskAssessment.RiskReport:
	if not _risk_assessment:
		return RiskAssessment.RiskReport.new()

	return _risk_assessment.evaluate_point_risk(
		element.position,
		element.faction,
		element.element_type.category if element.element_type else ElementData.Category.INF,
		element.element_type.mobility_class if element.element_type else GameEnums.MobilityType.FOOT
	)


func evaluate_route_risk_for_element(element: ElementData.ElementInstance, path: PackedVector2Array) -> RiskAssessment.RiskReport:
	if not _risk_assessment:
		return RiskAssessment.RiskReport.new()

	var speed := element.element_type.cross_speed if element.element_type else 3.0

	return _risk_assessment.evaluate_route_risk(
		path,
		element.faction,
		element.element_type.category if element.element_type else ElementData.Category.INF,
		element.element_type.mobility_class if element.element_type else GameEnums.MobilityType.FOOT,
		speed
	)

# =============================================================================
# ユーティリティ
# =============================================================================

## フェーズ経過時間（tick）
func get_phase_elapsed_ticks(current_tick: int) -> int:
	return current_tick - phase_start_tick


## テンプレート経過時間（tick）
func get_elapsed_ticks(current_tick: int) -> int:
	return current_tick - start_tick


## 要素が目標に到達したか
func has_element_reached_target(element: ElementData.ElementInstance, target: Vector2, threshold: float = 20.0) -> bool:
	return element.position.distance_to(target) <= threshold


## 全要素が目標に到達したか
func have_all_elements_reached_target(target: Vector2, threshold: float = 20.0) -> bool:
	for element in get_all_elements():
		if not has_element_reached_target(element, target, threshold):
			return false
	return true
