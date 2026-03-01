extends GutTest

## HaltCommandのテスト
## フェーズ5: コマンドパターン導入

var HaltCommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	HaltCommandClass = load("res://scripts/commands/halt_command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_halt_command_class_exists() -> void:
	assert_not_null(HaltCommandClass, "HaltCommand class should exist")


func test_halt_command_can_be_instantiated() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = HaltCommandClass.new(element_ids)
	assert_not_null(cmd, "HaltCommand should be instantiable")


# =============================================================================
# execute テスト
# =============================================================================

func test_execute_sets_order_type_to_hold() -> void:
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
	var cmd = HaltCommandClass.new(element_ids)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.HOLD, "Order type should be HOLD")


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
	var cmd = HaltCommandClass.new(element_ids)

	cmd.execute(world_model)

	assert_false(element.is_moving, "Element should not be moving")


func test_execute_clears_path() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.current_path = PackedVector2Array([Vector2(200, 200), Vector2(300, 300)])
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = HaltCommandClass.new(element_ids)

	cmd.execute(world_model)

	assert_eq(element.current_path.size(), 0, "Path should be cleared")


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
	var cmd = HaltCommandClass.new(element_ids)

	cmd.execute(world_model)
	assert_eq(element.current_order_type, GameEnums.OrderType.HOLD, "Should be HOLD after execute")

	var undo_result = cmd.undo(world_model)

	assert_true(undo_result, "undo should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Order should be restored to MOVE")
	assert_true(element.is_moving, "is_moving should be restored to true")


func test_undo_fails_if_not_executed() -> void:
	var world_model = WorldModelClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = HaltCommandClass.new(element_ids)

	var result = cmd.undo(world_model)

	assert_false(result, "undo should return false if not executed")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = HaltCommandClass.new(element_ids)

	var description = cmd.get_description()

	assert_eq(description, "Halt", "Description should be 'Halt'")
