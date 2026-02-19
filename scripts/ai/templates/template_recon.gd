class_name TemplateRecon
extends TacticalTemplate

## TPL_RECON - 偵察テンプレート
## 仕様書: docs/company_ai_v0.1.md Section 5.4
##
## フェーズ:
## 0: MOVE_IN_BOUNDS - 段階移動
## 1: OBSERVE - 観測
## 2: REPORT - 報告
## 3: EVADE - 回避

# =============================================================================
# フェーズ定数
# =============================================================================

enum Phase {
	MOVE_IN_BOUNDS = 0,
	OBSERVE = 1,
	REPORT = 2,
	EVADE = 3,
}

# =============================================================================
# 内部状態
# =============================================================================

var _waypoints: PackedVector2Array = PackedVector2Array()
var _current_waypoint_index: int = 0
var _observe_start_tick: int = -1
var _evade_target: Vector2 = Vector2.ZERO

const WAYPOINT_SPACING_M: float = 200.0
const OBSERVE_DURATION_TICKS: int = 100  # 10秒

# =============================================================================
# リスク閾値（TPL_RECON）- 最も低い
# =============================================================================

func get_risk_threshold_green() -> int:
	return 20

func get_risk_threshold_yellow() -> int:
	return 35

func get_risk_threshold_orange() -> int:
	return 50

func get_risk_threshold_red() -> int:
	return 50

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	template_type = GameEnums.TacticalTemplate.TPL_RECON

# =============================================================================
# 役割配分
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	# 偵察テンプレートでは全員がSCOUT
	for element in elements:
		element_roles[element.id] = GameEnums.ElementRole.SCOUT

# =============================================================================
# テンプレート開始
# =============================================================================

func start(current_tick: int, elements: Array[ElementData.ElementInstance], target_pos: Vector2 = Vector2.ZERO, cp_id: String = "") -> void:
	super.start(current_tick, elements, target_pos, cp_id)

	# ウェイポイントを生成
	_generate_waypoints(elements)

# =============================================================================
# フェーズ処理
# =============================================================================

func _on_phase_enter(phase: int, current_tick: int) -> void:
	match phase:
		Phase.MOVE_IN_BOUNDS:
			_enter_move_in_bounds(current_tick)
		Phase.OBSERVE:
			_enter_observe(current_tick)
		Phase.REPORT:
			_enter_report(current_tick)
		Phase.EVADE:
			_enter_evade(current_tick)


func _enter_move_in_bounds(current_tick: int) -> void:
	if _waypoints.size() == 0:
		transition_to_phase(Phase.OBSERVE, current_tick)
		return

	var elements := get_all_elements()
	var waypoint := _waypoints[_current_waypoint_index]

	for element in elements:
		# ROE: HoldFire
		# TODO: SOPモードを設定
		issue_move_order(element, waypoint, current_tick)


func _enter_observe(current_tick: int) -> void:
	_observe_start_tick = current_tick

	var elements := get_all_elements()

	for element in elements:
		# 停止して観測
		issue_hold_order(element, current_tick)


func _enter_report(current_tick: int) -> void:
	# 報告フェーズ：ContactDBの更新は自動的に行われる
	# 次のウェイポイントへ、または完了

	if _current_waypoint_index < _waypoints.size() - 1:
		_current_waypoint_index += 1
		transition_to_phase(Phase.MOVE_IN_BOUNDS, current_tick)
	else:
		# 全ウェイポイント完了
		template_completed.emit()


func _enter_evade(current_tick: int) -> void:
	var elements := get_all_elements()

	# 回避位置を計算
	_evade_target = _find_evade_position(elements)

	for element in elements:
		issue_move_order(element, _evade_target, current_tick)

# =============================================================================
# 更新
# =============================================================================

func update_tactical(current_tick: int) -> void:
	if not is_active:
		return

	# 常にCONF敵をチェック
	if _has_conf_contact():
		if current_phase != Phase.EVADE:
			_emit_contact_report(current_tick)
			transition_to_phase(Phase.EVADE, current_tick)
			return

	match current_phase:
		Phase.MOVE_IN_BOUNDS:
			_update_move_in_bounds(current_tick)
		Phase.OBSERVE:
			_update_observe(current_tick)
		Phase.EVADE:
			_update_evade(current_tick)


func _update_move_in_bounds(current_tick: int) -> void:
	if _waypoints.size() == 0:
		return

	var waypoint := _waypoints[_current_waypoint_index]
	var elements := get_all_elements()

	# ウェイポイント到達チェック
	var all_reached := true
	for element in elements:
		if not has_element_reached_target(element, waypoint, 30.0):
			all_reached = false
			break

	if all_reached:
		transition_to_phase(Phase.OBSERVE, current_tick)


func _update_observe(current_tick: int) -> void:
	var elapsed := current_tick - _observe_start_tick

	if elapsed >= OBSERVE_DURATION_TICKS:
		transition_to_phase(Phase.REPORT, current_tick)


func _update_evade(current_tick: int) -> void:
	var elements := get_all_elements()

	# 回避位置に到達したかチェック
	var all_reached := true
	for element in elements:
		if not has_element_reached_target(element, _evade_target, 30.0):
			all_reached = false
			break

	if all_reached:
		# 敵がまだ近ければ後退を継続
		if _has_conf_contact():
			_evade_target = _find_evade_position(elements)
			for element in elements:
				issue_move_order(element, _evade_target, current_tick)
		else:
			# 安全になったら観測に戻る
			transition_to_phase(Phase.MOVE_IN_BOUNDS, current_tick)

# =============================================================================
# ヘルパー
# =============================================================================

func _generate_waypoints(elements: Array[ElementData.ElementInstance]) -> void:
	_waypoints.clear()
	_current_waypoint_index = 0

	if elements.size() == 0:
		return

	var start_pos := elements[0].position
	var distance := start_pos.distance_to(target_position)
	var direction := (target_position - start_pos).normalized()

	# 150-250mごとにウェイポイント
	var spacing := WAYPOINT_SPACING_M
	var num_waypoints := int(distance / spacing)

	for i in range(1, num_waypoints + 1):
		var waypoint := start_pos + direction * spacing * float(i)
		_waypoints.append(waypoint)

	# 最終目標を追加
	_waypoints.append(target_position)


func _has_conf_contact() -> bool:
	if not _vision_system:
		return false

	var elements := get_all_elements()
	if elements.size() == 0:
		return false

	var faction := elements[0].faction
	var contacts := _vision_system.get_contacts_for_faction(faction)

	for element in elements:
		for contact in contacts:
			if contact.state == GameEnums.ContactState.CONFIRMED:
				var distance := element.position.distance_to(contact.pos_est_m)
				if distance <= GameConstants.CONTACT_NEAR_M:
					return true

	return false


func _find_evade_position(elements: Array[ElementData.ElementInstance]) -> Vector2:
	if elements.size() == 0:
		return Vector2.ZERO

	var element := elements[0]
	var faction := element.faction

	# 最も近い遮蔽を探す
	if _map_data:
		var best_pos := element.position
		var best_score := -INF

		for angle in range(0, 360, 45):
			var rad := deg_to_rad(angle)
			var dir := Vector2(cos(rad), sin(rad))

			for dist in [50, 100, 150]:
				var candidate := element.position + dir * float(dist)
				var terrain := _map_data.get_terrain_at(candidate)

				var score := 0.0

				# 遮蔽があれば加点
				if terrain == GameEnums.TerrainType.FOREST:
					score += 50.0
				elif terrain == GameEnums.TerrainType.URBAN:
					score += 40.0

				# 敵から離れていれば加点
				if _vision_system:
					var contacts := _vision_system.get_contacts_for_faction(faction)
					for contact in contacts:
						if contact.state == GameEnums.ContactState.CONFIRMED:
							var enemy_dist := candidate.distance_to(contact.pos_est_m)
							score += enemy_dist * 0.1

				if score > best_score:
					best_score = score
					best_pos = candidate

		return best_pos

	# マップデータがない場合、単純に後退
	return element.position - (target_position - element.position).normalized() * 100.0


func _emit_contact_report(current_tick: int) -> void:
	if not _event_bus or not _vision_system:
		return

	var elements := get_all_elements()
	if elements.size() == 0:
		return

	var faction := elements[0].faction
	var contacts := _vision_system.get_contacts_for_faction(faction)

	for contact in contacts:
		if contact.state == GameEnums.ContactState.CONFIRMED:
			# 接触報告イベント
			_event_bus.emit_contact_event(
				true,
				faction,
				current_tick,
				contact.pos_est_m,
				contact.element_id,
				GameEnums.TargetClass.UNKNOWN,
				elements[0].position.distance_to(contact.pos_est_m)
			)
