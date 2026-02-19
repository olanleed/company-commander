class_name TemplateBreakContact
extends TacticalTemplate

## TPL_BREAK_CONTACT - 接触離脱テンプレート
## 仕様書: docs/company_ai_v0.1.md Section 5.6
##
## フェーズ:
## 0: SMOKE_AND_COVER - 煙幕展開
## 1: DISENGAGE_MOVE - 離脱移動
## 2: RALLY - 集合
## 3: HOLD - 保持

# =============================================================================
# フェーズ定数
# =============================================================================

enum Phase {
	SMOKE_AND_COVER = 0,
	DISENGAGE_MOVE = 1,
	RALLY = 2,
	HOLD = 3,
}

# =============================================================================
# 内部状態
# =============================================================================

var _rally_point: Vector2 = Vector2.ZERO
var _smoke_requested: bool = false

const RALLY_STABLE_TICKS: int = 50  # 5秒間suppression < 0.4で完了

# =============================================================================
# リスク閾値（TPL_BREAK_CONTACT）- 常に許容
# =============================================================================

func get_risk_threshold_green() -> int:
	return 100  # 常に許容

func get_risk_threshold_yellow() -> int:
	return 100

func get_risk_threshold_orange() -> int:
	return 100

func get_risk_threshold_red() -> int:
	return 100

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	template_type = GameEnums.TacticalTemplate.TPL_BREAK_CONTACT

# =============================================================================
# 役割配分
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	# 全員がASSAULT（離脱）
	for element in elements:
		element_roles[element.id] = GameEnums.ElementRole.ASSAULT

# =============================================================================
# テンプレート開始
# =============================================================================

func start(current_tick: int, elements: Array[ElementData.ElementInstance], target_pos: Vector2 = Vector2.ZERO, cp_id: String = "") -> void:
	# 目標位置が指定されていない場合、撤退位置を計算
	if target_pos == Vector2.ZERO:
		target_pos = _find_rally_point(elements)

	_rally_point = target_pos
	super.start(current_tick, elements, target_pos, cp_id)

# =============================================================================
# フェーズ処理
# =============================================================================

func _on_phase_enter(phase: int, current_tick: int) -> void:
	match phase:
		Phase.SMOKE_AND_COVER:
			_enter_smoke_and_cover(current_tick)
		Phase.DISENGAGE_MOVE:
			_enter_disengage_move(current_tick)
		Phase.RALLY:
			_enter_rally(current_tick)
		Phase.HOLD:
			_enter_hold(current_tick)


func _enter_smoke_and_cover(current_tick: int) -> void:
	_smoke_requested = false

	var elements := get_all_elements()
	if elements.size() == 0:
		transition_to_phase(Phase.DISENGAGE_MOVE, current_tick)
		return

	# 煙幕要請
	_request_smoke(current_tick, elements)
	_smoke_requested = true

	# 遮蔽へ移動
	for element in elements:
		var cover_pos := _find_nearest_cover(element.position)
		if cover_pos != element.position:
			issue_move_order(element, cover_pos, current_tick)
		else:
			issue_hold_order(element, current_tick)


func _enter_disengage_move(current_tick: int) -> void:
	var elements := get_all_elements()

	for element in elements:
		issue_move_order(element, _rally_point, current_tick)


func _enter_rally(current_tick: int) -> void:
	# 集合点に到達、回復待ち
	var elements := get_all_elements()

	for element in elements:
		issue_hold_order(element, current_tick)


func _enter_hold(current_tick: int) -> void:
	var elements := get_all_elements()

	for element in elements:
		# 敵方向を向いてDefend
		var facing_target := element.position + Vector2(100, 0)  # TODO: 敵方向を計算
		issue_defend_order(element, facing_target, current_tick)

	# テンプレート完了
	template_completed.emit()

# =============================================================================
# 更新
# =============================================================================

func update_micro(current_tick: int, _dt: float) -> void:
	if not is_active:
		return

	# SMOKE_AND_COVERフェーズは短時間で次へ
	if current_phase == Phase.SMOKE_AND_COVER:
		var elapsed := get_phase_elapsed_ticks(current_tick)
		if elapsed >= 20:  # 2秒後
			transition_to_phase(Phase.DISENGAGE_MOVE, current_tick)


func update_tactical(current_tick: int) -> void:
	if not is_active:
		return

	match current_phase:
		Phase.DISENGAGE_MOVE:
			_update_disengage_move(current_tick)
		Phase.RALLY:
			_update_rally(current_tick)


func _update_disengage_move(current_tick: int) -> void:
	var elements := get_all_elements()

	# 全員がラリーポイントに到達したかチェック
	var all_reached := true
	for element in elements:
		if not has_element_reached_target(element, _rally_point, 50.0):
			all_reached = false
			break

	if all_reached:
		transition_to_phase(Phase.RALLY, current_tick)


func _update_rally(current_tick: int) -> void:
	var elements := get_all_elements()

	# suppression < 0.4が5秒継続で完了
	var all_recovered := true
	for element in elements:
		if element.suppression >= 0.4:
			all_recovered = false
			break

	var elapsed := get_phase_elapsed_ticks(current_tick)

	if all_recovered and elapsed >= RALLY_STABLE_TICKS:
		transition_to_phase(Phase.HOLD, current_tick)

# =============================================================================
# ヘルパー
# =============================================================================

func _find_rally_point(elements: Array[ElementData.ElementInstance]) -> Vector2:
	if elements.size() == 0:
		return Vector2.ZERO

	var element := elements[0]
	var faction := element.faction

	# 敵のThreatMapから最も遠い遮蔽セルを探す
	var best_pos := element.position
	var best_score := -INF

	# 360度、複数距離で候補を探索
	for angle in range(0, 360, 30):
		var rad := deg_to_rad(angle)
		var dir := Vector2(cos(rad), sin(rad))

		for dist in [100, 200, 300]:
			var candidate := element.position + dir * float(dist)

			var score := _evaluate_rally_position(candidate, element.position, faction)

			if score > best_score:
				best_score = score
				best_pos = candidate

	return best_pos


func _evaluate_rally_position(pos: Vector2, current_pos: Vector2, faction: GameEnums.Faction) -> float:
	var score := 0.0

	# 遮蔽があれば加点
	if _map_data:
		var terrain := _map_data.get_terrain_at(pos)
		if terrain == GameEnums.TerrainType.FOREST:
			score += 100.0
		elif terrain == GameEnums.TerrainType.URBAN:
			score += 80.0

	# 敵から離れていれば加点
	if _vision_system:
		var contacts := _vision_system.get_contacts_for_faction(faction)
		for contact in contacts:
			if contact.state in [GameEnums.ContactState.CONFIRMED, GameEnums.ContactState.SUSPECTED]:
				var enemy_dist := pos.distance_to(contact.pos_est_m)
				score += enemy_dist * 0.2

	# 現在位置から離れすぎると減点
	var move_dist := pos.distance_to(current_pos)
	if move_dist > 400:
		score -= (move_dist - 400) * 0.1

	return score


func _find_nearest_cover(pos: Vector2) -> Vector2:
	if not _map_data:
		return pos

	var best_pos := pos
	var best_dist := INF

	# 近くの遮蔽を探す
	for angle in range(0, 360, 45):
		var rad := deg_to_rad(angle)
		var dir := Vector2(cos(rad), sin(rad))

		for dist in [20, 40, 60, 80]:
			var candidate := pos + dir * float(dist)
			var terrain := _map_data.get_terrain_at(candidate)

			if terrain == GameEnums.TerrainType.FOREST or terrain == GameEnums.TerrainType.URBAN:
				if dist < best_dist:
					best_dist = dist
					best_pos = candidate

	return best_pos


func _request_smoke(current_tick: int, elements: Array[ElementData.ElementInstance]) -> void:
	if not _event_bus:
		return

	if elements.size() == 0:
		return

	var faction := elements[0].faction

	# 敵方向に煙幕
	var smoke_pos := elements[0].position

	if _vision_system:
		var contacts := _vision_system.get_contacts_for_faction(faction)
		for contact in contacts:
			if contact.state == GameEnums.ContactState.CONFIRMED:
				# 自分と敵の間に煙幕
				smoke_pos = elements[0].position.lerp(contact.pos_est_m, 0.3)
				break

	var subject_ids: Array[String] = []
	var tags := {"mission_type": "SMOKE", "priority": "urgent"}

	_event_bus.emit_event(
		GameEnums.CombatEventType.EV_FIRE_SUPPORT_REQUESTED,
		GameEnums.EventSeverity.S1_ALERT,
		faction,
		current_tick,
		smoke_pos,
		"",
		subject_ids,
		tags
	)
