extends Node

## WorldModelのユニットテスト

var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== WorldModel Tests ===")
	_run_all_tests()
	_print_summary()


func _run_all_tests() -> void:
	_test_add_element()
	_test_remove_element()
	_test_get_by_id()
	_test_get_by_faction()
	_test_get_elements_near()
	_test_get_elements_in_rect()
	_test_create_test_element()


# =============================================================================
# テストケース
# =============================================================================

func _test_add_element() -> void:
	var name := "add_element"
	var wm := WorldModel.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.faction = GameEnums.Faction.BLUE

	wm.add_element(ei)

	_assert_eq(wm.elements.size(), 1, name + ": elements size")
	_assert_eq(ei.id.is_empty(), false, name + ": element has id")


func _test_remove_element() -> void:
	var name := "remove_element"
	var wm := WorldModel.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.faction = GameEnums.Faction.BLUE

	wm.add_element(ei)
	_assert_eq(wm.elements.size(), 1, name + ": added")

	wm.remove_element(ei)
	_assert_eq(wm.elements.size(), 0, name + ": removed")


func _test_get_by_id() -> void:
	var name := "get_by_id"
	var wm := WorldModel.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	wm.add_element(ei)

	var found := wm.get_element_by_id(ei.id)
	_assert_eq(found, ei, name + ": found element")

	var not_found := wm.get_element_by_id("nonexistent")
	_assert_eq(not_found, null, name + ": not found returns null")


func _test_get_by_faction() -> void:
	var name := "get_by_faction"
	var wm := WorldModel.new()

	var et := _create_test_element_type()

	var blue1 := ElementData.ElementInstance.new(et)
	blue1.faction = GameEnums.Faction.BLUE
	wm.add_element(blue1)

	var blue2 := ElementData.ElementInstance.new(et)
	blue2.faction = GameEnums.Faction.BLUE
	wm.add_element(blue2)

	var red1 := ElementData.ElementInstance.new(et)
	red1.faction = GameEnums.Faction.RED
	wm.add_element(red1)

	var blues: Array[ElementData.ElementInstance] = wm.get_elements_for_faction(GameEnums.Faction.BLUE)
	_assert_eq(blues.size(), 2, name + ": blue count")

	var reds: Array[ElementData.ElementInstance] = wm.get_elements_for_faction(GameEnums.Faction.RED)
	_assert_eq(reds.size(), 1, name + ": red count")


func _test_get_elements_near() -> void:
	var name := "get_elements_near"
	var wm := WorldModel.new()

	var et := _create_test_element_type()

	var e1 := ElementData.ElementInstance.new(et)
	e1.position = Vector2(100, 100)
	wm.add_element(e1)

	var e2 := ElementData.ElementInstance.new(et)
	e2.position = Vector2(150, 100)
	wm.add_element(e2)

	var e3 := ElementData.ElementInstance.new(et)
	e3.position = Vector2(500, 500)
	wm.add_element(e3)

	var near: Array[ElementData.ElementInstance] = wm.get_elements_near(Vector2(100, 100), 100)
	_assert_eq(near.size(), 2, name + ": near count")

	var far: Array[ElementData.ElementInstance] = wm.get_elements_near(Vector2(100, 100), 10)
	_assert_eq(far.size(), 1, name + ": far count")


func _test_get_elements_in_rect() -> void:
	var name := "get_elements_in_rect"
	var wm := WorldModel.new()

	var et := _create_test_element_type()

	var e1 := ElementData.ElementInstance.new(et)
	e1.position = Vector2(50, 50)
	wm.add_element(e1)

	var e2 := ElementData.ElementInstance.new(et)
	e2.position = Vector2(150, 50)
	wm.add_element(e2)

	var rect := Rect2(0, 0, 100, 100)
	var in_rect: Array[ElementData.ElementInstance] = wm.get_elements_in_rect(rect)
	_assert_eq(in_rect.size(), 1, name + ": in rect count")


func _test_create_test_element() -> void:
	var name := "create_test_element"
	var wm := WorldModel.new()

	var et := _create_test_element_type()
	var ei := wm.create_test_element(et, GameEnums.Faction.BLUE, Vector2(200, 300))

	_assert_eq(ei.faction, GameEnums.Faction.BLUE, name + ": faction")
	_assert_eq(ei.position, Vector2(200, 300), name + ": position")
	_assert_eq(wm.elements.size(), 1, name + ": added to world")


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
