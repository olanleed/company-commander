extends GutTest

## FireMissionCommandのテスト
## フェーズ5: コマンドパターン導入

var FireMissionCommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	FireMissionCommandClass = load("res://scripts/commands/fire_mission_command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_fire_mission_command_class_exists() -> void:
	assert_not_null(FireMissionCommandClass, "FireMissionCommand class should exist")


func test_fire_mission_command_can_be_instantiated() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))
	assert_not_null(cmd, "FireMissionCommand should be instantiable")


# =============================================================================
# execute テスト
# =============================================================================

func test_execute_sets_order_type_to_fire_mission() -> void:
	var world_model = WorldModelClass.new()
	# 砲兵ユニットを作成
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M109A7_Paladin",  # 自走砲
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var target_pos := Vector2(500, 500)
	var cmd = FireMissionCommandClass.new(element_ids, target_pos)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true for artillery")
	assert_eq(element.current_order_type, GameEnums.OrderType.FIRE_MISSION, "Order type should be FIRE_MISSION")
	assert_eq(element.fire_mission_target, target_pos, "Fire mission target should be set")


func test_execute_fails_for_non_artillery() -> void:
	var world_model = WorldModelClass.new()
	# 戦車ユニットを作成（砲兵ではない）
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))

	var result = cmd.execute(world_model)

	assert_false(result, "execute should return false for non-artillery")


func test_execute_stops_movement() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M109A7_Paladin",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.is_moving = true
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))

	cmd.execute(world_model)

	assert_false(element.is_moving, "Element should not be moving")


# =============================================================================
# undo テスト
# =============================================================================

func test_undo_restores_previous_state() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M109A7_Paladin",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.current_order_type = GameEnums.OrderType.MOVE
	element.fire_mission_active = false
	var original_target := Vector2(200, 200)
	element.fire_mission_target = original_target
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))

	cmd.execute(world_model)
	assert_eq(element.current_order_type, GameEnums.OrderType.FIRE_MISSION, "Should be FIRE_MISSION after execute")

	var undo_result = cmd.undo(world_model)

	assert_true(undo_result, "undo should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Order should be restored to MOVE")
	assert_eq(element.fire_mission_target, original_target, "Fire mission target should be restored")


func test_undo_fails_if_not_executed() -> void:
	var world_model = WorldModelClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))

	var result = cmd.undo(world_model)

	assert_false(result, "undo should return false if not executed")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 300))

	var description = cmd.get_description()

	assert_true("500" in description, "Description should include x coordinate")
	assert_true("300" in description, "Description should include y coordinate")
	assert_true("Fire Mission" in description, "Description should include 'Fire Mission'")


# =============================================================================
# シリアライズテスト
# =============================================================================

func test_to_dict_contains_target_position() -> void:
	var element_ids: Array[String] = ["test_id"]
	var cmd = FireMissionCommandClass.new(element_ids, Vector2(500, 500))

	var dict = cmd.to_dict()

	assert_true("target_position" in dict, "Dict should contain target_position")
	assert_eq(dict.target_position.x, 500.0, "X should be 500")
	assert_eq(dict.target_position.y, 500.0, "Y should be 500")
