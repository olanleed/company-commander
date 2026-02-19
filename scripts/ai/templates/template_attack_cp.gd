class_name TemplateAttackCP
extends TacticalTemplate

## TPL_ATTACK_CP - 拠点攻撃テンプレート
## 仕様書: docs/company_ai_v0.1.md Section 5.2
##
## フェーズ:
## 0: RECON_AND_SHAPE - 偵察・形作り
## 1: SET_SUPPORT_BY_FIRE - 支援火力位置へ
## 2: ASSAULT_MOVE - 突入
## 3: CAPTURE_AND_CONSOLIDATE - 確保と再編
## 4: HOLD_DEFEND - 保持

# =============================================================================
# フェーズ定数
# =============================================================================

enum Phase {
	RECON_AND_SHAPE = 0,
	SET_SUPPORT_BY_FIRE = 1,
	ASSAULT_MOVE = 2,
	CAPTURE_AND_CONSOLIDATE = 3,
	HOLD_DEFEND = 4,
}

# =============================================================================
# 内部状態
# =============================================================================

var _support_position: Vector2 = Vector2.ZERO
var _observation_position: Vector2 = Vector2.ZERO
var _observation_complete: bool = false
var _contested_start_tick: int = -1

# =============================================================================
# リスク閾値（TPL_ATTACK_CP）
# =============================================================================

func get_risk_threshold_green() -> int:
	return 30

func get_risk_threshold_yellow() -> int:
	return 55

func get_risk_threshold_orange() -> int:
	return 75

func get_risk_threshold_red() -> int:
	return 75

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	template_type = GameEnums.TacticalTemplate.TPL_ATTACK_CP

# =============================================================================
# 役割配分
# =============================================================================

func _assign_roles(elements: Array[ElementData.ElementInstance]) -> void:
	# 歩兵/偵察/車両に基づいて役割を配分
	var inf_count := 0
	var support_assigned := false
	var security_assigned := false

	for element in elements:
		if not element.element_type:
			element_roles[element.id] = GameEnums.ElementRole.ASSAULT
			continue

		var category := element.element_type.category

		match category:
			ElementData.Category.INF:
				# 最初のINFはASSAULT、2番目以降は状況次第
				if not support_assigned and inf_count > 0:
					# MG/重火器ならSUPPORT
					if "mg" in element.element_type.id.to_lower():
						element_roles[element.id] = GameEnums.ElementRole.SUPPORT
						support_assigned = true
					else:
						element_roles[element.id] = GameEnums.ElementRole.ASSAULT
				elif not security_assigned and inf_count > 1:
					# ATならSECURITY
					if "at" in element.element_type.id.to_lower():
						element_roles[element.id] = GameEnums.ElementRole.SECURITY
						security_assigned = true
					else:
						element_roles[element.id] = GameEnums.ElementRole.ASSAULT
				else:
					element_roles[element.id] = GameEnums.ElementRole.ASSAULT
				inf_count += 1

			ElementData.Category.VEH:
				# 車両はOVERWATCH
				if not support_assigned:
					element_roles[element.id] = GameEnums.ElementRole.OVERWATCH
					support_assigned = true
				else:
					element_roles[element.id] = GameEnums.ElementRole.MANEUVER

			ElementData.Category.REC:
				# 偵察はSCOUT
				element_roles[element.id] = GameEnums.ElementRole.SCOUT

			ElementData.Category.WEAP:
				# 火器はFIRE_SUPPORT
				element_roles[element.id] = GameEnums.ElementRole.FIRE_SUPPORT

			_:
				element_roles[element.id] = GameEnums.ElementRole.ASSAULT

# =============================================================================
# フェーズ処理
# =============================================================================

func _on_phase_enter(phase: int, current_tick: int) -> void:
	match phase:
		Phase.RECON_AND_SHAPE:
			_enter_recon_and_shape(current_tick)
		Phase.SET_SUPPORT_BY_FIRE:
			_enter_set_support_by_fire(current_tick)
		Phase.ASSAULT_MOVE:
			_enter_assault_move(current_tick)
		Phase.CAPTURE_AND_CONSOLIDATE:
			_enter_capture_and_consolidate(current_tick)
		Phase.HOLD_DEFEND:
			_enter_hold_defend(current_tick)


func _enter_recon_and_shape(current_tick: int) -> void:
	_observation_complete = false

	# 観測点を計算
	_observation_position = find_observation_position(target_position)

	# SCOUTがいればSCOUTを送る、いなければSUPPORTを送る
	var scouts := get_elements_by_role(GameEnums.ElementRole.SCOUT)

	if scouts.size() > 0:
		for scout in scouts:
			issue_move_order(scout, _observation_position, current_tick)
	else:
		# SUPPORTを観測役に
		var supports := get_elements_by_role(GameEnums.ElementRole.SUPPORT)
		if supports.size() > 0:
			issue_move_order(supports[0], _observation_position, current_tick)

	# 他の要素は待機
	var other_elements := get_all_elements()
	for element in other_elements:
		var role: GameEnums.ElementRole = element_roles.get(element.id, GameEnums.ElementRole.ASSAULT)
		if role != GameEnums.ElementRole.SCOUT and role != GameEnums.ElementRole.SUPPORT:
			issue_hold_order(element, current_tick)


func _enter_set_support_by_fire(current_tick: int) -> void:
	# 支援位置を計算
	_support_position = find_support_by_fire_position(
		get_all_elements()[0].position if get_all_elements().size() > 0 else target_position,
		target_position
	)

	# SUPPORT/OVERWATCH要素を支援位置へ
	var support_elements := get_elements_by_role(GameEnums.ElementRole.SUPPORT)
	support_elements.append_array(get_elements_by_role(GameEnums.ElementRole.OVERWATCH))

	for element in support_elements:
		issue_move_order(element, _support_position, current_tick)

	# SECURITY要素は側面警戒位置へ
	var security_elements := get_elements_by_role(GameEnums.ElementRole.SECURITY)
	var flank_dir := Vector2(-1, 0).rotated(randf() * TAU)  # 簡易的にランダム方向
	for element in security_elements:
		var security_pos := _support_position + flank_dir * 100.0
		issue_move_order(element, security_pos, current_tick)

	# ASSAULT要素は待機
	var assault_elements := get_elements_by_role(GameEnums.ElementRole.ASSAULT)
	for element in assault_elements:
		issue_hold_order(element, current_tick)


func _enter_assault_move(current_tick: int) -> void:
	# ASSAULT要素をCP縁へ
	var assault_elements := get_elements_by_role(GameEnums.ElementRole.ASSAULT)
	assault_elements.append_array(get_elements_by_role(GameEnums.ElementRole.MANEUVER))

	# CP縁の位置を計算（CP中心から少し外側）
	var cp_edge := _calculate_cp_edge_position()

	# リスク評価
	var sample_element := assault_elements[0] if assault_elements.size() > 0 else null
	if sample_element:
		var risk := evaluate_risk_for_element(sample_element)

		# OPEN横断が必要なら煙幕要請
		if risk.has_flag(GameEnums.RiskFlag.OPEN_CROSSING_TRIGGER):
			_request_smoke_support(current_tick)

	# 突入命令
	for i in range(assault_elements.size()):
		var element := assault_elements[i]
		# 複数要素は分散して突入
		var angle := TAU * float(i) / float(assault_elements.size())
		var offset := Vector2(cos(angle), sin(angle)) * GameConstants.CP_RADIUS_M * 0.8
		var entry_point := target_position + offset
		issue_move_order(element, entry_point, current_tick)

	# SUPPORT要素はDefend（CP方向を向く）
	var support_elements := get_elements_by_role(GameEnums.ElementRole.SUPPORT)
	support_elements.append_array(get_elements_by_role(GameEnums.ElementRole.OVERWATCH))

	for element in support_elements:
		issue_defend_order(element, target_position, current_tick)


func _enter_capture_and_consolidate(current_tick: int) -> void:
	# ASSAULT要素はCP内でDefend
	var assault_elements := get_elements_by_role(GameEnums.ElementRole.ASSAULT)
	assault_elements.append_array(get_elements_by_role(GameEnums.ElementRole.MANEUVER))

	for element in assault_elements:
		issue_defend_order(element, target_position + Vector2(100, 0), current_tick)  # 仮の敵方向

	# SUPPORT要素は前進
	var support_elements := get_elements_by_role(GameEnums.ElementRole.SUPPORT)
	support_elements.append_array(get_elements_by_role(GameEnums.ElementRole.OVERWATCH))

	var forward_support_pos := target_position.lerp(_support_position, 0.3)
	for element in support_elements:
		issue_move_order(element, forward_support_pos, current_tick)


func _enter_hold_defend(current_tick: int) -> void:
	# 全要素Defend
	var elements := get_all_elements()

	for element in elements:
		issue_defend_order(element, target_position + Vector2(100, 0), current_tick)

	# テンプレート完了
	template_completed.emit()

# =============================================================================
# 更新
# =============================================================================

func update_tactical(current_tick: int) -> void:
	if not is_active:
		return

	match current_phase:
		Phase.RECON_AND_SHAPE:
			_update_recon_and_shape(current_tick)
		Phase.SET_SUPPORT_BY_FIRE:
			_update_set_support_by_fire(current_tick)
		Phase.ASSAULT_MOVE:
			_update_assault_move(current_tick)
		Phase.CAPTURE_AND_CONSOLIDATE:
			_update_capture_and_consolidate(current_tick)


func _update_recon_and_shape(current_tick: int) -> void:
	# 観測完了チェック（12秒 = 120tick）
	var elapsed := get_phase_elapsed_ticks(current_tick)

	if elapsed >= 120:
		_observation_complete = true
		transition_to_phase(Phase.SET_SUPPORT_BY_FIRE, current_tick)
		return

	# SCOUTが観測点に到達したかチェック
	var scouts := get_elements_by_role(GameEnums.ElementRole.SCOUT)
	if scouts.size() == 0:
		scouts = get_elements_by_role(GameEnums.ElementRole.SUPPORT)

	if scouts.size() > 0:
		if has_element_reached_target(scouts[0], _observation_position, 30.0):
			if elapsed >= 60:  # 到達後6秒観測
				_observation_complete = true
				transition_to_phase(Phase.SET_SUPPORT_BY_FIRE, current_tick)


func _update_set_support_by_fire(current_tick: int) -> void:
	# SUPPORT要素が支援位置に到達したかチェック
	var support_elements := get_elements_by_role(GameEnums.ElementRole.SUPPORT)
	support_elements.append_array(get_elements_by_role(GameEnums.ElementRole.OVERWATCH))

	var all_in_position := true
	for element in support_elements:
		if not has_element_reached_target(element, _support_position, 50.0):
			all_in_position = false
			break

	if all_in_position:
		transition_to_phase(Phase.ASSAULT_MOVE, current_tick)


func _update_assault_move(current_tick: int) -> void:
	var assault_elements := get_elements_by_role(GameEnums.ElementRole.ASSAULT)
	assault_elements.append_array(get_elements_by_role(GameEnums.ElementRole.MANEUVER))

	# CP内に到達したかチェック
	var any_in_cp := false
	for element in assault_elements:
		if element.position.distance_to(target_position) <= GameConstants.CP_RADIUS_M:
			any_in_cp = true
			break

	if any_in_cp:
		# TODO: CPがCONTROLLEDになったかチェック
		transition_to_phase(Phase.CAPTURE_AND_CONSOLIDATE, current_tick)
		return

	# CONTESTED状態のチェック
	# TODO: CPのCONTESTED状態を確認
	if _contested_start_tick > 0:
		var contested_elapsed := current_tick - _contested_start_tick
		if contested_elapsed >= int(GameConstants.CONTESTED_HE_TRIGGER_SEC * GameConstants.SIM_HZ):
			# HE要請
			_request_he_support(current_tick)


func _update_capture_and_consolidate(current_tick: int) -> void:
	# 5秒後にHOLD_DEFENDへ
	var elapsed := get_phase_elapsed_ticks(current_tick)

	if elapsed >= 50:
		transition_to_phase(Phase.HOLD_DEFEND, current_tick)

# =============================================================================
# ヘルパー
# =============================================================================

func _calculate_cp_edge_position() -> Vector2:
	# CP縁の位置を計算
	var elements := get_all_elements()
	if elements.size() == 0:
		return target_position

	# 要素の平均位置からCPへの方向
	var avg_pos := Vector2.ZERO
	for element in elements:
		avg_pos += element.position
	avg_pos /= float(elements.size())

	var dir := (target_position - avg_pos).normalized()

	# CP縁（半径の少し内側）
	return target_position - dir * GameConstants.CP_RADIUS_M * 0.5


func _request_smoke_support(current_tick: int) -> void:
	# 煙幕要請イベントを生成
	if _event_bus:
		var elements := get_all_elements()
		var faction := elements[0].faction if elements.size() > 0 else GameEnums.Faction.BLUE

		# 煙幕位置：CP手前150m
		var smoke_pos := target_position.lerp(elements[0].position if elements.size() > 0 else target_position, 0.15)

		var subject_ids: Array[String] = []
		var tags := {"mission_type": "SMOKE"}
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


func _request_he_support(current_tick: int) -> void:
	# HE要請イベントを生成
	if _event_bus:
		var elements := get_all_elements()
		var faction := elements[0].faction if elements.size() > 0 else GameEnums.Faction.BLUE

		var subject_ids: Array[String] = []
		var tags := {"mission_type": "HE"}
		_event_bus.emit_event(
			GameEnums.CombatEventType.EV_FIRE_SUPPORT_REQUESTED,
			GameEnums.EventSeverity.S1_ALERT,
			faction,
			current_tick,
			target_position,
			"",
			subject_ids,
			tags
		)
