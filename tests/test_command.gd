extends GutTest

## Commandベースクラスのテスト
## フェーズ5: コマンドパターン導入

var CommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	CommandClass = load("res://scripts/commands/command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_command_class_exists() -> void:
	assert_not_null(CommandClass, "Command class should exist")


func test_command_can_be_instantiated() -> void:
	var cmd = CommandClass.new()
	assert_not_null(cmd, "Command should be instantiable")


# =============================================================================
# 基本プロパティテスト
# =============================================================================

func test_command_has_timestamp() -> void:
	var cmd = CommandClass.new()
	assert_true("_timestamp" in cmd or cmd.has_method("get_timestamp"), "Command should have timestamp")


func test_command_has_element_ids() -> void:
	var cmd = CommandClass.new()
	assert_true("_element_ids" in cmd or cmd.has_method("get_element_ids"), "Command should have element_ids")


func test_command_has_executed_flag() -> void:
	var cmd = CommandClass.new()
	assert_true("_executed" in cmd, "Command should have _executed flag")


# =============================================================================
# 基本メソッドテスト
# =============================================================================

func test_command_has_execute_method() -> void:
	var cmd = CommandClass.new()
	assert_true(cmd.has_method("execute"), "Command should have execute method")


func test_command_has_undo_method() -> void:
	var cmd = CommandClass.new()
	assert_true(cmd.has_method("undo"), "Command should have undo method")


func test_command_has_is_valid_method() -> void:
	var cmd = CommandClass.new()
	assert_true(cmd.has_method("is_valid"), "Command should have is_valid method")


func test_command_has_get_description_method() -> void:
	var cmd = CommandClass.new()
	assert_true(cmd.has_method("get_description"), "Command should have get_description method")


func test_command_has_to_dict_method() -> void:
	var cmd = CommandClass.new()
	assert_true(cmd.has_method("to_dict"), "Command should have to_dict method")


# =============================================================================
# is_valid テスト
# =============================================================================

func test_is_valid_returns_true_for_empty_element_ids() -> void:
	var cmd = CommandClass.new()
	var world_model = WorldModelClass.new()

	# element_idsが空の場合はtrue
	assert_true(cmd.is_valid(world_model), "Empty element_ids should be valid")


func test_is_valid_returns_true_for_existing_element() -> void:
	var cmd = CommandClass.new()
	var world_model = WorldModelClass.new()

	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	cmd._element_ids.append(element.id)

	assert_true(cmd.is_valid(world_model), "Command should be valid for existing element")


func test_is_valid_returns_false_for_nonexistent_element() -> void:
	var cmd = CommandClass.new()
	var world_model = WorldModelClass.new()

	cmd._element_ids.append("nonexistent_id")

	assert_false(cmd.is_valid(world_model), "Command should be invalid for nonexistent element")


# =============================================================================
# to_dict テスト
# =============================================================================

func test_to_dict_returns_dictionary() -> void:
	var cmd = CommandClass.new()
	cmd._timestamp = 100
	cmd._element_ids.append("test_id")

	var result = cmd.to_dict()

	assert_typeof(result, TYPE_DICTIONARY, "to_dict should return Dictionary")


func test_to_dict_contains_type() -> void:
	var cmd = CommandClass.new()

	var result = cmd.to_dict()

	assert_true("type" in result, "to_dict should contain 'type'")


func test_to_dict_contains_timestamp() -> void:
	var cmd = CommandClass.new()
	cmd._timestamp = 123

	var result = cmd.to_dict()

	assert_true("timestamp" in result, "to_dict should contain 'timestamp'")
	assert_eq(result.timestamp, 123, "timestamp should match")


func test_to_dict_contains_element_ids() -> void:
	var cmd = CommandClass.new()
	cmd._element_ids.append("id1")
	cmd._element_ids.append("id2")

	var result = cmd.to_dict()

	assert_true("element_ids" in result, "to_dict should contain 'element_ids'")
	assert_eq(result.element_ids.size(), 2, "element_ids should have 2 elements")


# =============================================================================
# get_description テスト
# =============================================================================

func test_get_description_returns_string() -> void:
	var cmd = CommandClass.new()

	var result = cmd.get_description()

	assert_typeof(result, TYPE_STRING, "get_description should return String")
