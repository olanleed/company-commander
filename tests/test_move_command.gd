extends GutTest

## MoveCommandのテスト
## フェーズ5: コマンドパターン導入

var MoveCommandClass: GDScript
var CommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	MoveCommandClass = load("res://scripts/commands/move_command.gd")
	CommandClass = load("res://scripts/commands/command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_move_command_class_exists() -> void:
	assert_not_null(MoveCommandClass, "MoveCommand class should exist")


func test_move_command_can_be_instantiated() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100))
	assert_not_null(cmd, "MoveCommand should be instantiable")


func test_move_command_extends_command() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100))
	# CommandClassをinstanceofで確認
	assert_true(cmd.has_method("execute"), "MoveCommand should have execute method from Command")


# =============================================================================
# プロパティテスト
# =============================================================================

func test_move_command_stores_destination() -> void:
	var element_ids: Array[String] = ["test_id"]
	var destination := Vector2(200, 300)
	var cmd = MoveCommandClass.new(element_ids, destination)

	assert_eq(cmd._destination, destination, "Destination should be stored")


func test_move_command_stores_use_road() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100), true)

	assert_true(cmd._use_road, "use_road should be true")


func test_move_command_default_use_road_is_false() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100))

	assert_false(cmd._use_road, "use_road should default to false")


# =============================================================================
# execute テスト
# =============================================================================

func test_execute_sets_order_type_to_move() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var destination := Vector2(500, 500)
	var cmd = MoveCommandClass.new(element_ids, destination)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Order type should be MOVE")


func test_execute_sets_order_target_position() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var destination := Vector2(500, 500)
	var cmd = MoveCommandClass.new(element_ids, destination)

	cmd.execute(world_model)

	assert_eq(element.order_target_position, destination, "Order target position should be set")


func test_execute_marks_command_as_executed() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	cmd.execute(world_model)

	assert_true(cmd._executed, "Command should be marked as executed")


func test_execute_multiple_elements() -> void:
	var world_model = WorldModelClass.new()
	var element1 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var element2 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A3_Bradley",
		GameEnums.Faction.BLUE,
		Vector2(200, 200)
	)
	world_model.add_element(element1)
	world_model.add_element(element2)

	var element_ids: Array[String] = [element1.id, element2.id]
	var destination := Vector2(500, 500)
	var cmd = MoveCommandClass.new(element_ids, destination)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true")
	assert_eq(element1.current_order_type, GameEnums.OrderType.MOVE, "Element1 order type should be MOVE")
	assert_eq(element2.current_order_type, GameEnums.OrderType.MOVE, "Element2 order type should be MOVE")


func test_execute_saves_previous_state_for_undo() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	# 初期状態を設定
	element.current_order_type = GameEnums.OrderType.HOLD
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	cmd.execute(world_model)

	assert_true(element.id in cmd._previous_states, "Previous state should be saved")
	assert_eq(cmd._previous_states[element.id].order_type, GameEnums.OrderType.HOLD, "Previous order type should be HOLD")


# =============================================================================
# undo テスト
# =============================================================================

func test_undo_restores_previous_order_type() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.current_order_type = GameEnums.OrderType.DEFEND
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	cmd.execute(world_model)
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Order should be MOVE after execute")

	var undo_result = cmd.undo(world_model)

	assert_true(undo_result, "undo should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.DEFEND, "Order should be restored to DEFEND")


func test_undo_fails_if_not_executed() -> void:
	var world_model = WorldModelClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	var result = cmd.undo(world_model)

	assert_false(result, "undo should return false if not executed")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description_includes_destination() -> void:
	var element_ids: Array[String] = ["test_id"]
	var destination := Vector2(500, 300)
	var cmd = MoveCommandClass.new(element_ids, destination)

	var description = cmd.get_description()

	assert_true("500" in description, "Description should include x coordinate")
	assert_true("300" in description, "Description should include y coordinate")


# =============================================================================
# to_dict テスト
# =============================================================================

func test_to_dict_includes_destination() -> void:
	var element_ids: Array[String] = ["test_id"]
	var destination := Vector2(500, 300)
	var cmd = MoveCommandClass.new(element_ids, destination)

	var result = cmd.to_dict()

	assert_true("destination" in result, "to_dict should include destination")
	assert_eq(result.destination.x, 500.0, "destination.x should be 500")
	assert_eq(result.destination.y, 300.0, "destination.y should be 300")


func test_to_dict_includes_use_road() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100), true)

	var result = cmd.to_dict()

	assert_true("use_road" in result, "to_dict should include use_road")
	assert_true(result.use_road, "use_road should be true")
