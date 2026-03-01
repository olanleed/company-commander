extends GutTest

## AttackCommandパターンのテスト
## フェーズ5: コマンドパターン導入

var AttackCommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	AttackCommandClass = load("res://scripts/commands/attack_command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_attack_command_class_exists() -> void:
	assert_not_null(AttackCommandClass, "AttackCommand class should exist")


func test_attack_command_can_be_instantiated() -> void:
	var element_ids: Array[String] = ["shooter_id"]
	var cmd = AttackCommandClass.new(element_ids, "target_id")
	assert_not_null(cmd, "AttackCommand should be instantiable")


# =============================================================================
# プロパティテスト
# =============================================================================

func test_attack_command_stores_target_id() -> void:
	var element_ids: Array[String] = ["shooter_id"]
	var target_id := "enemy_unit"
	var cmd = AttackCommandClass.new(element_ids, target_id)

	assert_eq(cmd._target_id, target_id, "Target ID should be stored")


# =============================================================================
# execute テスト
# =============================================================================

func test_execute_sets_order_type_to_attack() -> void:
	var world_model = WorldModelClass.new()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnums.Faction.RED,
		Vector2(500, 500)
	)
	world_model.add_element(shooter)
	world_model.add_element(target)

	var element_ids: Array[String] = [shooter.id]
	var cmd = AttackCommandClass.new(element_ids, target.id)

	var result = cmd.execute(world_model)

	assert_true(result, "execute should return true")
	assert_eq(shooter.current_order_type, GameEnums.OrderType.ATTACK, "Order type should be ATTACK")


func test_execute_sets_forced_target_id() -> void:
	var world_model = WorldModelClass.new()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnums.Faction.RED,
		Vector2(500, 500)
	)
	world_model.add_element(shooter)
	world_model.add_element(target)

	var element_ids: Array[String] = [shooter.id]
	var cmd = AttackCommandClass.new(element_ids, target.id)

	cmd.execute(world_model)

	assert_eq(shooter.forced_target_id, target.id, "Forced target ID should be set")


func test_execute_marks_command_as_executed() -> void:
	var world_model = WorldModelClass.new()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnums.Faction.RED,
		Vector2(500, 500)
	)
	world_model.add_element(shooter)
	world_model.add_element(target)

	var element_ids: Array[String] = [shooter.id]
	var cmd = AttackCommandClass.new(element_ids, target.id)

	cmd.execute(world_model)

	assert_true(cmd._executed, "Command should be marked as executed")


# =============================================================================
# undo テスト
# =============================================================================

func test_undo_restores_previous_target() -> void:
	var world_model = WorldModelClass.new()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnums.Faction.RED,
		Vector2(500, 500)
	)
	world_model.add_element(shooter)
	world_model.add_element(target)

	# 元の状態
	shooter.forced_target_id = ""

	var element_ids: Array[String] = [shooter.id]
	var cmd = AttackCommandClass.new(element_ids, target.id)

	cmd.execute(world_model)
	assert_eq(shooter.forced_target_id, target.id, "Target should be set after execute")

	var undo_result = cmd.undo(world_model)

	assert_true(undo_result, "undo should return true")
	assert_eq(shooter.forced_target_id, "", "Target should be restored to empty")


func test_undo_fails_if_not_executed() -> void:
	var world_model = WorldModelClass.new()
	var element_ids: Array[String] = ["shooter_id"]
	var cmd = AttackCommandClass.new(element_ids, "target_id")

	var result = cmd.undo(world_model)

	assert_false(result, "undo should return false if not executed")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description_includes_target() -> void:
	var element_ids: Array[String] = ["shooter_id"]
	var target_id := "enemy_tank_001"
	var cmd = AttackCommandClass.new(element_ids, target_id)

	var description = cmd.get_description()

	assert_true(target_id in description, "Description should include target ID")
