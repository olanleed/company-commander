extends GutTest

## DefendCommandのテスト
## フェーズ5: コマンドパターン導入

var DefendCommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	DefendCommandClass = load("res://scripts/commands/defend_command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_defend_command_class_exists() -> void:
	assert_not_null(DefendCommandClass, "DefendCommand class should exist")


func test_defend_command_can_be_instantiated() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = DefendCommandClass.new(element_ids, Vector2(100, 100))
	assert_not_null(cmd, "DefendCommand should be instantiable")


# =============================================================================
# プロパティテスト
# =============================================================================

func test_defend_command_stores_position() -> void:
	var element_ids: Array[String] = ["test_id"]
	var position := Vector2(200, 300)
	var cmd = DefendCommandClass.new(element_ids, position)

	assert_eq(cmd._position, position, "Position should be stored")


# =============================================================================
# execute テスト
# =============================================================================

func test_execute_sets_order_type_to_defend() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var position := Vector2(100, 100)
	var cmd = DefendCommandClass.new(element_ids, position)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.DEFEND, "Order type should be DEFEND")


func test_execute_stops_movement() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.is_moving = true
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = DefendCommandClass.new(element_ids, Vector2(100, 100))

	cmd.execute(world_model)

	assert_false(element.is_moving, "Element should not be moving")


func test_execute_sets_order_target_position() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var position := Vector2(200, 200)
	var cmd = DefendCommandClass.new(element_ids, position)

	cmd.execute(world_model)

	assert_eq(element.order_target_position, position, "Order target position should be set")


func test_execute_uses_current_position_if_not_specified() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(150, 250)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = DefendCommandClass.new(element_ids, Vector2.ZERO)  # 位置未指定

	cmd.execute(world_model)

	assert_eq(element.order_target_position, element.position, "Order target should be element's current position")


# =============================================================================
# undo テスト
# =============================================================================

func test_undo_restores_previous_state() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.current_order_type = GameEnums.OrderType.MOVE
	element.is_moving = true
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = DefendCommandClass.new(element_ids, Vector2(100, 100))

	cmd.execute(world_model)
	assert_eq(element.current_order_type, GameEnums.OrderType.DEFEND, "Should be DEFEND after execute")

	var undo_result = cmd.undo(world_model)

	assert_true(undo_result, "undo should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Order should be restored to MOVE")


func test_undo_fails_if_not_executed() -> void:
	var world_model = WorldModelClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = DefendCommandClass.new(element_ids, Vector2.ZERO)

	var result = cmd.undo(world_model)

	assert_false(result, "undo should return false if not executed")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description_with_position() -> void:
	var element_ids: Array[String] = ["test_id"]
	var position := Vector2(500, 300)
	var cmd = DefendCommandClass.new(element_ids, position)

	var description = cmd.get_description()

	assert_true("500" in description, "Description should include x coordinate")
	assert_true("300" in description, "Description should include y coordinate")


func test_get_description_without_position() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = DefendCommandClass.new(element_ids, Vector2.ZERO)

	var description = cmd.get_description()

	assert_eq(description, "Defend", "Description should be 'Defend' without position")
