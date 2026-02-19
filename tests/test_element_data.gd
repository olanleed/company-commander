extends Node

## ElementDataのユニットテスト

var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== ElementData Tests ===")
	_run_all_tests()
	_print_summary()


func _run_all_tests() -> void:
	_test_element_type_creation()
	_test_element_instance_creation()
	_test_symbol_name_friendly()
	_test_symbol_name_hostile()
	_test_speed_calculation()
	_test_interpolation()
	_test_prev_state_save()


# =============================================================================
# テストケース
# =============================================================================

func _test_element_type_creation() -> void:
	var name := "element_type_creation"

	var et := ElementData.ElementType.new()
	et.id = "inf_rifle"
	et.display_name = "Rifle Squad"
	et.category = ElementData.Category.INF
	et.symbol_type = ElementData.SymbolType.INF_RIFLE
	et.mobility_class = GameEnums.MobilityType.FOOT
	et.road_speed = 5.0
	et.cross_speed = 3.0
	et.max_strength = 10

	_assert_eq(et.id, "inf_rifle", name + ": id")
	_assert_eq(et.category, ElementData.Category.INF, name + ": category")
	_assert_eq(et.mobility_class, GameEnums.MobilityType.FOOT, name + ": mobility")
	_assert_eq(et.max_strength, 10, name + ": max_strength")


func _test_element_instance_creation() -> void:
	var name := "element_instance_creation"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)

	_assert_eq(ei.element_type, et, name + ": element_type")
	_assert_eq(ei.current_strength, et.max_strength, name + ": current_strength")
	_assert_eq(ei.state, GameEnums.UnitState.ACTIVE, name + ": state")
	_assert_eq(ei.is_moving, false, name + ": is_moving")


func _test_symbol_name_friendly() -> void:
	var name := "symbol_name_friendly"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.faction = GameEnums.Faction.BLUE
	ei.contact_state = GameEnums.ContactState.CONFIRMED

	var symbol_name := ei.get_symbol_name(GameEnums.Faction.BLUE)
	_assert_eq(symbol_name, "inf_rifle_friendly_conf", name)


func _test_symbol_name_hostile() -> void:
	var name := "symbol_name_hostile"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.faction = GameEnums.Faction.RED
	ei.contact_state = GameEnums.ContactState.SUSPECTED

	var symbol_name := ei.get_symbol_name(GameEnums.Faction.BLUE)
	_assert_eq(symbol_name, "inf_rifle_hostile_sus", name)


func _test_speed_calculation() -> void:
	var name := "speed_calculation"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)

	var road_speed := ei.get_speed(GameEnums.TerrainType.ROAD)
	_assert_eq(road_speed, 5.0, name + ": road_speed")

	var open_speed := ei.get_speed(GameEnums.TerrainType.OPEN)
	_assert_eq(open_speed, 3.0, name + ": open_speed")

	var forest_speed := ei.get_speed(GameEnums.TerrainType.FOREST)
	_assert_approx(forest_speed, 1.8, 0.01, name + ": forest_speed")  # 3.0 * 0.6


func _test_interpolation() -> void:
	var name := "interpolation"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.prev_position = Vector2(0, 0)
	ei.position = Vector2(100, 0)

	var mid := ei.get_interpolated_position(0.5)
	_assert_approx(mid.x, 50.0, 0.01, name + ": mid.x")
	_assert_approx(mid.y, 0.0, 0.01, name + ": mid.y")


func _test_prev_state_save() -> void:
	var name := "prev_state_save"

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(100, 200)
	ei.facing = PI / 2

	ei.save_prev_state()

	_assert_eq(ei.prev_position, Vector2(100, 200), name + ": prev_position")
	_assert_eq(ei.prev_facing, PI / 2, name + ": prev_facing")


# =============================================================================
# ヘルパー
# =============================================================================

func _create_test_element_type() -> ElementData.ElementType:
	var et := ElementData.ElementType.new()
	et.id = "inf_rifle"
	et.display_name = "Rifle Squad"
	et.category = ElementData.Category.INF
	et.symbol_type = ElementData.SymbolType.INF_RIFLE
	et.mobility_class = GameEnums.MobilityType.FOOT
	et.road_speed = 5.0
	et.cross_speed = 3.0
	et.max_strength = 10
	return et


# =============================================================================
# アサーション
# =============================================================================

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) <= tolerance:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _print_summary() -> void:
	print("")
	for result in _test_results:
		print(result)
	print("")
	print("=== Summary: " + str(_passed) + " passed, " + str(_failed) + " failed ===")

	if _failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
