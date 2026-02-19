extends Node

## MovementSystemのユニットテスト

var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== MovementSystem Tests ===")
	_run_all_tests()
	_print_summary()


func _run_all_tests() -> void:
	_test_is_moving()
	_test_update_element_stationary()
	_test_update_element_moving()
	_test_stop_at_goal()
	_test_suppression_slows_movement()
	_test_get_remaining_distance()


# =============================================================================
# テストケース
# =============================================================================

func _test_is_moving() -> void:
	var name := "is_moving"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)

	ei.is_moving = false
	_assert_eq(ms.is_moving(ei), false, name + ": not moving")

	ei.is_moving = true
	_assert_eq(ms.is_moving(ei), true, name + ": moving")


func _test_update_element_stationary() -> void:
	var name := "update_stationary"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(100, 100)
	ei.is_moving = false

	var initial_pos := ei.position
	ms.update_element(ei, 0.1)

	_assert_eq(ei.position, initial_pos, name + ": position unchanged")


func _test_update_element_moving() -> void:
	var name := "update_moving"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.is_moving = true
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei.path_index = 0

	# 0.1秒移動 (cross_speed=3.0 m/s -> 0.3m移動)
	ms.update_element(ei, 0.1)

	_assert_true(ei.position.x > 0, name + ": moved in x")
	_assert_approx(ei.position.y, 0.0, 0.01, name + ": y unchanged")


func _test_stop_at_goal() -> void:
	var name := "stop_at_goal"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(99, 0)  # ゴール近く
	ei.is_moving = true
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei.path_index = 1  # 最後のウェイポイントへ

	# ゴールに到達
	ms.update_element(ei, 0.5)

	_assert_eq(ei.is_moving, false, name + ": stopped moving")
	_assert_eq(ei.current_path.size(), 0, name + ": path cleared")


func _test_suppression_slows_movement() -> void:
	var name := "suppression_slows"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()

	# 抑圧なし
	var ei1 := ElementData.ElementInstance.new(et)
	ei1.position = Vector2(0, 0)
	ei1.suppression = 0.0
	ei1.is_moving = true
	ei1.current_path = PackedVector2Array([Vector2(0, 0), Vector2(1000, 0)])
	ei1.path_index = 0

	ms.update_element(ei1, 1.0)
	var dist1 := ei1.position.x

	# 抑圧あり (50%)
	var ei2 := ElementData.ElementInstance.new(et)
	ei2.position = Vector2(0, 0)
	ei2.suppression = 1.0  # 100% suppression -> 50% speed
	ei2.is_moving = true
	ei2.current_path = PackedVector2Array([Vector2(0, 0), Vector2(1000, 0)])
	ei2.path_index = 0

	ms.update_element(ei2, 1.0)
	var dist2 := ei2.position.x

	_assert_true(dist2 < dist1, name + ": suppressed unit slower")
	_assert_approx(dist2 / dist1, 0.5, 0.1, name + ": ~50% speed")


func _test_get_remaining_distance() -> void:
	var name := "get_remaining_distance"
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])
	ei.path_index = 0

	var dist := ms.get_remaining_distance(ei)
	_assert_approx(dist, 200.0, 0.01, name + ": total distance")

	ei.path_index = 1
	dist = ms.get_remaining_distance(ei)
	_assert_approx(dist, 200.0, 0.01, name + ": from waypoint 1")

	ei.position = Vector2(50, 0)
	ei.path_index = 1
	dist = ms.get_remaining_distance(ei)
	_assert_approx(dist, 150.0, 0.01, name + ": from midpoint")


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


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message)


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
