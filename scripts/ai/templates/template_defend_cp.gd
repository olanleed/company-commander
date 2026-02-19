class_name TemplateDefendCP
extends TacticalTemplate

## TPL_DEFEND_CP - 拠点防御テンプレート
## 仕様書: docs/company_ai_v0.1.md Section 5.3
##
## フェーズ:
## 0: OCCUPY_POSITIONS - 配置占領
## 1: SET_SECTORS - セクター設定
## 2: HOLD_AND_COUNTER - 保持と対応
## 3: REPOSITION - 再配置

# =============================================================================
# フェーズ定数
# =============================================================================

enum Phase {
	OCCUPY_POSITIONS = 0,
	SET_SECTORS = 1,
	HOLD_AND_COUNTER = 2,
	REPOSITION = 3,
}

# =============================================================================
# 内部状態
# =============================================================================

var _defense_positions: Dictionary = {}  # element_id -> Vector2
var _facing_direction: Vector2 = Vector2.RIGHT

# =============================================================================
# リスク閾値（TPL_DEFEND_CP）
# =============================================================================

func get_risk_threshold_green() -> int:
	return 35

func get_risk_threshold_yellow() -> int:
	return 60

func get_risk_threshold_orange() -> int:
	return 80

func get_risk_threshold_red() -> int:
	return 80

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	template_type = GameEnums.TacticalTemplate.TPL_DEFEND_CP

# =============================================================================
# 役割配分
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	var support_count := 0

	for element in elements:
		if not element.element_type:
			element_roles[element.id] = GameEnums.ElementRole.ASSAULT
			continue

		var category := element.element_type.category

		match category:
			ElementData.Category.INF:
				# MG/重火器ならSUPPORT
				if "mg" in element.element_type.id.to_lower() and support_count < 2:
					element_roles[element.id] = GameEnums.ElementRole.SUPPORT
					support_count += 1
				elif "at" in element.element_type.id.to_lower():
					element_roles[element.id] = GameEnums.ElementRole.SECURITY
				else:
					element_roles[element.id] = GameEnums.ElementRole.ASSAULT

			ElementData.Category.VEH:
				element_roles[element.id] = GameEnums.ElementRole.OVERWATCH

			ElementData.Category.REC:
				element_roles[element.id] = GameEnums.ElementRole.SCOUT

			ElementData.Category.WEAP:
				element_roles[element.id] = GameEnums.ElementRole.FIRE_SUPPORT

			_:
				element_roles[element.id] = GameEnums.ElementRole.ASSAULT

# =============================================================================
# フェーズ処理
# =============================================================================

func _on_phase_enter(phase: int, current_tick: int) -> void:
	match phase:
		Phase.OCCUPY_POSITIONS:
			_enter_occupy_positions(current_tick)
		Phase.SET_SECTORS:
			_enter_set_sectors(current_tick)
		Phase.HOLD_AND_COUNTER:
			_enter_hold_and_counter(current_tick)
		Phase.REPOSITION:
			_enter_reposition(current_tick)


func _enter_occupy_positions(current_tick: int) -> void:
	var elements := get_all_elements()

	# 防御位置を計算
	_calculate_defense_positions(elements)

	# 敵方向を推定
	_facing_direction = _estimate_threat_direction()

	# 各要素を防御位置へ移動
	for element in elements:
		if element.id in _defense_positions:
			var pos: Vector2 = _defense_positions[element.id]
			issue_move_order(element, pos, current_tick)


func _enter_set_sectors(current_tick: int) -> void:
	var elements := get_all_elements()

	# 各要素をDefend態勢に
	for element in elements:
		var facing_target := target_position + _facing_direction * 200.0
		issue_defend_order(element, facing_target, current_tick)


func _enter_hold_and_counter(_current_tick: int) -> void:
	# 保持状態：特別な処理なし
	# update_tacticalで接触対応を行う
	pass


func _enter_reposition(current_tick: int) -> void:
	# 再配置が必要な場合
	# TODO: 撤退位置を計算

	var elements := get_all_elements()
	for element in elements:
		# v0.1では単純に後退
		var retreat_pos := element.position - _facing_direction * 100.0
		issue_move_order(element, retreat_pos, current_tick)

	# BreakContactテンプレートへの切り替えを通知
	# TODO: CompanyAIにテンプレート変更を要請

# =============================================================================
# 更新
# =============================================================================

func update_tactical(current_tick: int) -> void:
	if not is_active:
		return

	match current_phase:
		Phase.OCCUPY_POSITIONS:
			_update_occupy_positions(current_tick)
		Phase.SET_SECTORS:
			_update_set_sectors(current_tick)
		Phase.HOLD_AND_COUNTER:
			_update_hold_and_counter(current_tick)


func _update_occupy_positions(current_tick: int) -> void:
	var elements := get_all_elements()

	# 全員が位置についたかチェック
	var all_in_position := true
	for element in elements:
		if element.id in _defense_positions:
			var pos: Vector2 = _defense_positions[element.id]
			if not has_element_reached_target(element, pos, 20.0):
				all_in_position = false
				break

	if all_in_position:
		transition_to_phase(Phase.SET_SECTORS, current_tick)


func _update_set_sectors(current_tick: int) -> void:
	# セクター設定完了後、HOLDへ
	var elapsed := get_phase_elapsed_ticks(current_tick)

	if elapsed >= 20:  # 2秒後
		transition_to_phase(Phase.HOLD_AND_COUNTER, current_tick)


func _update_hold_and_counter(current_tick: int) -> void:
	var elements := get_all_elements()

	# 状態チェック：撤退条件
	var avg_suppression := 0.0
	var total_strength := 0
	var max_strength := 0

	for element in elements:
		avg_suppression += element.suppression
		total_strength += element.current_strength
		if element.element_type:
			max_strength += element.element_type.max_strength

	if elements.size() > 0:
		avg_suppression /= float(elements.size())

	# 撤退条件チェック
	var strength_ratio := float(total_strength) / float(max_strength) if max_strength > 0 else 1.0

	if avg_suppression > 0.7 or strength_ratio < 0.6:
		transition_to_phase(Phase.REPOSITION, current_tick)
		return

	# SUS接触への対応（面制圧）
	_handle_sus_contacts(current_tick)


func _handle_sus_contacts(current_tick: int) -> void:
	if not _vision_system:
		return

	var elements := get_all_elements()
	if elements.size() == 0:
		return

	var faction := elements[0].faction
	var contacts := _vision_system.get_contacts_for_faction(faction)

	for contact in contacts:
		if contact.state == GameEnums.ContactState.SUSPECTED:
			var distance := target_position.distance_to(contact.pos_est_m)
			if distance <= GameConstants.SUPPORT_BY_FIRE_MAX_M:
				# TODO: 面制圧命令
				pass

# =============================================================================
# 防御位置計算
# =============================================================================

func _calculate_defense_positions(elements: Array[ElementData.ElementInstance]) -> void:
	_defense_positions.clear()

	var count := elements.size()
	if count == 0:
		return

	# CP縁に分散配置
	var cp_radius := GameConstants.CP_RADIUS_M

	for i in range(count):
		var element := elements[i]
		var role: GameEnums.ElementRole = element_roles.get(element.id, GameEnums.ElementRole.ASSAULT)

		var pos: Vector2

		match role:
			GameEnums.ElementRole.ASSAULT, GameEnums.ElementRole.SUPPORT:
				# CP縁に配置
				var angle := TAU * float(i) / float(count) + PI / 4.0  # 少しずらす
				pos = target_position + Vector2(cos(angle), sin(angle)) * cp_radius * 0.9

			GameEnums.ElementRole.OVERWATCH:
				# 少し後方
				pos = target_position - _estimate_threat_direction() * cp_radius * 1.5

			GameEnums.ElementRole.SECURITY:
				# 側面
				var perp := Vector2(-_facing_direction.y, _facing_direction.x)
				pos = target_position + perp * cp_radius * 1.2

			GameEnums.ElementRole.SCOUT:
				# 前方
				pos = target_position + _facing_direction * cp_radius * 2.0

			_:
				pos = target_position

		_defense_positions[element.id] = pos


func _estimate_threat_direction() -> Vector2:
	if not _vision_system or not _world_model:
		return Vector2.RIGHT

	var elements := get_all_elements()
	if elements.size() == 0:
		return Vector2.RIGHT

	var faction := elements[0].faction
	var contacts := _vision_system.get_contacts_for_faction(faction)

	if contacts.size() == 0:
		# 敵情報がない場合、マップ中央から離れる方向
		var map_center := Vector2(1000, 1000)  # TODO: MapDataから取得
		return (target_position - map_center).normalized()

	# 最も近いCONF/SUS敵の方向
	var nearest_contact: VisionSystem.ContactRecord = null
	var nearest_distance := INF

	for contact in contacts:
		if contact.state in [GameEnums.ContactState.CONFIRMED, GameEnums.ContactState.SUSPECTED]:
			var distance := target_position.distance_to(contact.pos_est_m)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_contact = contact

	if nearest_contact:
		return (nearest_contact.pos_est_m - target_position).normalized()

	return Vector2.RIGHT
