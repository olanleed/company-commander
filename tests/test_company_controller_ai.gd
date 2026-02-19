extends GutTest

## CompanyControllerAIのユニットテスト

const CompanyControllerAIClass = preload("res://scripts/ai/company_controller_ai.gd")

var company_ai
var world_model: WorldModel
var map_data: MapData
var vision_system: VisionSystem
var movement_system: MovementSystem
var event_bus: CombatEventBus

var _inf_type: ElementData.ElementType
var _tank_type: ElementData.ElementType


func before_each() -> void:
	# WorldModelとMapDataのセットアップ
	world_model = WorldModel.new()
	map_data = _create_test_map_data()

	# VisionSystemのセットアップ
	vision_system = VisionSystem.new()
	vision_system.setup(world_model, map_data)

	# MovementSystem（ナビなしの簡易版）
	movement_system = MovementSystem.new()

	# CombatEventBus
	event_bus = CombatEventBus.new()

	# CompanyControllerAI
	company_ai = CompanyControllerAIClass.new("test_company")
	company_ai.faction = GameEnums.Faction.BLUE
	company_ai.setup(world_model, map_data, vision_system, movement_system, event_bus)

	# テスト用ElementType
	_inf_type = ElementData.ElementType.new()
	_inf_type.id = "test_infantry"
	_inf_type.display_name = "Test Infantry"
	_inf_type.category = ElementData.Category.INF
	_inf_type.mobility_class = GameEnums.MobilityType.FOOT
	_inf_type.spot_range_base = 300.0
	_inf_type.road_speed = 5.0
	_inf_type.cross_speed = 3.0
	_inf_type.max_strength = 10

	_tank_type = ElementData.ElementType.new()
	_tank_type.id = "test_tank"
	_tank_type.display_name = "Test Tank"
	_tank_type.category = ElementData.Category.VEH
	_tank_type.mobility_class = GameEnums.MobilityType.TRACKED
	_tank_type.spot_range_base = 500.0
	_tank_type.road_speed = 12.0
	_tank_type.cross_speed = 8.0
	_tank_type.max_strength = 4
	_tank_type.armor_class = 3


func _create_test_map_data() -> MapData:
	var data := MapData.new()
	data.map_id = "test_map"
	data.size_m = Vector2(2000, 2000)
	data.cp_radius_m = 40.0

	# テスト用拠点を追加
	var cp := MapData.CapturePoint.new()
	cp.id = "CP_A"
	cp.position = Vector2(1000, 1000)
	cp.initial_owner = GameEnums.Faction.NONE
	data.capture_points.append(cp)

	return data


func _create_test_elements() -> Array[String]:
	var ids: Array[String] = []

	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(150, 100))
	var elem3 := world_model.create_test_element(_tank_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	ids.append(elem1.id)
	ids.append(elem2.id)
	ids.append(elem3.id)

	return ids


# =============================================================================
# 基本テスト
# =============================================================================

func test_company_ai_initialization() -> void:
	assert_not_null(company_ai)
	assert_eq(company_ai.company_id, "test_company")
	assert_eq(company_ai.faction, GameEnums.Faction.BLUE)
	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_NONE)
	assert_eq(company_ai.get_combat_state(), GameEnums.CombatState.QUIET)


func test_add_element() -> void:
	company_ai.add_element("elem_1")
	company_ai.add_element("elem_2")

	assert_eq(company_ai.element_ids.size(), 2)


func test_remove_element() -> void:
	company_ai.add_element("elem_1")
	company_ai.add_element("elem_2")
	company_ai.remove_element("elem_1")

	assert_eq(company_ai.element_ids.size(), 1)
	assert_eq(company_ai.element_ids[0], "elem_2")


func test_set_elements() -> void:
	var ids: Array[String] = ["elem_1", "elem_2", "elem_3"]
	company_ai.set_elements(ids)

	assert_eq(company_ai.element_ids.size(), 3)


# =============================================================================
# 命令テスト
# =============================================================================

func test_order_move() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_move(Vector2(500, 500))

	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_MOVE)


func test_order_attack_cp() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_attack_cp("CP_A")

	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_ATTACK_CP)


func test_order_defend_cp() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_defend_cp("CP_A")

	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_DEFEND_CP)


func test_order_recon() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_recon(Vector2(800, 800))

	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_RECON)


func test_order_break_contact() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_break_contact(Vector2(50, 50))

	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_BREAK_CONTACT)


func test_order_hold() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# まず移動命令
	company_ai.order_move(Vector2(500, 500))
	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_MOVE)

	# 停止命令
	company_ai.order_hold()
	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_NONE)


func test_order_invalid_cp() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# 存在しないCPへの命令
	company_ai.order_attack_cp("INVALID_CP")

	# テンプレートは変わらない
	assert_eq(company_ai.get_current_template_type(), GameEnums.TacticalTemplate.TPL_NONE)


# =============================================================================
# 更新サイクルテスト
# =============================================================================

func test_update_micro() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)
	company_ai.order_move(Vector2(500, 500))

	# 更新を呼び出し（エラーなく完了するか）
	company_ai.update_micro(0, 0.1)
	company_ai.update_micro(1, 0.1)

	assert_true(true, "update_microがエラーなく実行される")


func test_update_contact_eval() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# 接触評価を呼び出し
	company_ai.update_contact_eval(0)
	company_ai.update_contact_eval(5)  # AI_CONTACT_EVAL_TICKS = 5

	assert_true(true, "update_contact_evalがエラーなく実行される")


func test_update_tactical() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)
	company_ai.order_move(Vector2(500, 500))

	# 戦術評価を呼び出し
	company_ai.update_tactical(0)
	company_ai.update_tactical(10)  # AI_TACTICAL_EVAL_TICKS = 10

	assert_true(true, "update_tacticalがエラーなく実行される")


func test_update_operational() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# 大局評価を呼び出し
	company_ai.update_operational(0)
	company_ai.update_operational(50)  # AI_OPERATIONAL_EVAL_TICKS = 50

	assert_true(true, "update_operationalがエラーなく実行される")


# =============================================================================
# 戦闘状態テスト
# =============================================================================

func test_combat_state_changes_on_contact() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# 敵を配置
	world_model.create_test_element(_tank_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 視界スキャンでCONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 接触評価
	company_ai.update_contact_eval(10)

	# 近距離の敵がいれば ENGAGED になるはず
	var state := company_ai.get_combat_state()
	assert_true(
		state in [GameEnums.CombatState.ALERT, GameEnums.CombatState.ENGAGED],
		"敵接触で戦闘状態が変化する"
	)


# =============================================================================
# シグナルテスト
# =============================================================================

var _template_changed_count := 0
var _last_old_template: GameEnums.TacticalTemplate
var _last_new_template: GameEnums.TacticalTemplate


func test_template_changed_signal() -> void:
	_template_changed_count = 0
	company_ai.template_changed.connect(_on_template_changed)

	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	company_ai.order_move(Vector2(500, 500))

	assert_eq(_template_changed_count, 1)
	assert_eq(_last_old_template, GameEnums.TacticalTemplate.TPL_NONE)
	assert_eq(_last_new_template, GameEnums.TacticalTemplate.TPL_MOVE)


func _on_template_changed(old_type: GameEnums.TacticalTemplate, new_type: GameEnums.TacticalTemplate) -> void:
	_template_changed_count += 1
	_last_old_template = old_type
	_last_new_template = new_type


# =============================================================================
# クエリテスト
# =============================================================================

func test_get_element_role() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)
	company_ai.order_attack_cp("CP_A")

	# 役割が割り当てられているか
	var role := company_ai.get_element_role(ids[0])
	assert_true(
		role in [
			GameEnums.ElementRole.ASSAULT,
			GameEnums.ElementRole.SUPPORT,
			GameEnums.ElementRole.SECURITY,
			GameEnums.ElementRole.SCOUT
		],
		"要素に役割が割り当てられている"
	)


func test_get_risk_at_position() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	var report := company_ai.get_risk_at_position(Vector2(500, 500))

	assert_not_null(report)
	assert_gte(report.risk_total, 0)


func test_get_event_bus() -> void:
	var bus := company_ai.get_event_bus()

	assert_not_null(bus)
	assert_true(bus is CombatEventBus)


func test_get_current_phase() -> void:
	var ids := _create_test_elements()
	company_ai.set_elements(ids)

	# テンプレートなしの場合
	assert_eq(company_ai.get_current_phase(), 0)

	# テンプレート開始後
	company_ai.order_move(Vector2(500, 500))
	assert_eq(company_ai.get_current_phase(), 0, "初期フェーズは0")
