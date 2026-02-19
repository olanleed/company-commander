class_name TemplateMove
extends TacticalTemplate

## TPL_MOVE - 移動テンプレート
## 仕様書: docs/company_ai_v0.1.md Section 5.1
##
## フェーズ:
## 0: PLAN_ROUTE - 経路計画
## 1: MOVE - 移動中
## 2: REACT_CONTACT - 接触対応
## 3: ARRIVE - 到着/保持

# =============================================================================
# フェーズ定数
# =============================================================================

enum Phase {
	PLAN_ROUTE = 0,
	MOVE = 1,
	REACT_CONTACT = 2,
	ARRIVE = 3,
}

# =============================================================================
# 設定
# =============================================================================

var use_road_priority: bool = false  # 道路優先モード

# =============================================================================
# リスク閾値（TPL_MOVE）
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

func _init() -> void:
	template_type = GameEnums.TacticalTemplate.TPL_MOVE

# =============================================================================
# 役割配分
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	# 移動テンプレートでは全員がASSAULT（移動要員）
	for element in elements:
		element_roles[element.id] = GameEnums.ElementRole.ASSAULT

# =============================================================================
# フェーズ処理
# =============================================================================

func _on_phase_enter(phase: int, current_tick: int) -> void:
	match phase:
		Phase.PLAN_ROUTE:
			_enter_plan_route(current_tick)
		Phase.MOVE:
			_enter_move(current_tick)
		Phase.REACT_CONTACT:
			_enter_react_contact(current_tick)
		Phase.ARRIVE:
			_enter_arrive(current_tick)


func _enter_plan_route(current_tick: int) -> void:
	# 経路を計画し、すぐにMOVEフェーズへ
	var elements := get_all_elements()

	for element in elements:
		# リスク評価
		var risk := evaluate_risk_for_element(element)

		if risk.risk_total > get_risk_threshold_red():
			# リスクが高すぎる場合は煙幕要請を検討
			if GameEnums.Mitigation.SMOKE in risk.recommended_mitigations:
				# TODO: 煙幕要請
				pass

	# すぐにMOVEフェーズへ遷移
	transition_to_phase(Phase.MOVE, current_tick)


func _enter_move(current_tick: int) -> void:
	var elements := get_all_elements()

	# 間隔を考慮した位置を計算
	var spacing := _calculate_spacing(elements)

	for i in range(elements.size()):
		var element := elements[i]
		var offset := spacing[i] if i < spacing.size() else Vector2.ZERO
		var adjusted_target := target_position + offset

		issue_move_order(element, adjusted_target, current_tick, use_road_priority)


func _enter_react_contact(_current_tick: int) -> void:
	# 接触対応：停止して遮蔽へ
	var elements := get_all_elements()

	for element in elements:
		# TODO: 遮蔽位置を探索して移動
		# v0.1では単純に停止
		issue_hold_order(element, _current_tick)


func _enter_arrive(current_tick: int) -> void:
	# 到着：Defend態勢へ
	var elements := get_all_elements()

	for element in elements:
		# 進行方向を向いてDefend
		issue_defend_order(element, target_position, current_tick)

	# テンプレート完了
	template_completed.emit()

# =============================================================================
# 更新
# =============================================================================

func update_tactical(current_tick: int) -> void:
	if not is_active:
		return

	match current_phase:
		Phase.MOVE:
			_update_move_phase(current_tick)
		Phase.REACT_CONTACT:
			_update_react_contact_phase(current_tick)


func _update_move_phase(current_tick: int) -> void:
	var elements := get_all_elements()

	# 到着チェック
	var all_arrived := true
	for element in elements:
		if not has_element_reached_target(element, target_position, 30.0):
			all_arrived = false
			break

	if all_arrived:
		transition_to_phase(Phase.ARRIVE, current_tick)
		return

	# 接触チェック
	if _has_near_contact():
		transition_to_phase(Phase.REACT_CONTACT, current_tick)
		return


func _update_react_contact_phase(current_tick: int) -> void:
	# 接触が解消されたらMOVEに戻る
	if not _has_near_contact():
		var elapsed := get_phase_elapsed_ticks(current_tick)
		if elapsed >= 50:  # 5秒待機後
			transition_to_phase(Phase.MOVE, current_tick)


func _has_near_contact() -> bool:
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

# =============================================================================
# 間隔計算
# =============================================================================

func _calculate_spacing(elements: Array[ElementData.ElementInstance]) -> Array[Vector2]:
	var spacing: Array[Vector2] = []
	var count := elements.size()

	if count <= 1:
		spacing.append(Vector2.ZERO)
		return spacing

	# 移動方向を計算
	var first_element := elements[0]
	var move_dir := (target_position - first_element.position).normalized()
	var perpendicular := Vector2(-move_dir.y, move_dir.x)

	# 間隔を決定
	var base_spacing := GameConstants.FOOT_SPACING_M
	if first_element.element_type:
		if first_element.element_type.mobility_class != GameEnums.MobilityType.FOOT:
			base_spacing = GameConstants.VEHICLE_SPACING_M

	# 横一列に配置
	var start_offset := -perpendicular * base_spacing * float(count - 1) / 2.0

	for i in range(count):
		var offset := start_offset + perpendicular * base_spacing * float(i)
		spacing.append(offset)

	return spacing
