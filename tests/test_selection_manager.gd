extends GutTest

## SelectionManagerテスト
## フェーズ4: UIリアクティブ化

var SelectionManagerClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	SelectionManagerClass = load("res://scripts/ui/selection_manager.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_selection_manager_exists() -> void:
	assert_not_null(SelectionManagerClass, "SelectionManager should exist")


func test_selection_manager_can_be_instantiated() -> void:
	var manager = SelectionManagerClass.new()
	assert_not_null(manager, "SelectionManager should be instantiable")


# =============================================================================
# 基本シグナルテスト
# =============================================================================

func test_has_selection_changed_signal() -> void:
	var manager = SelectionManagerClass.new()
	assert_true(manager.has_signal("selection_changed"), "Should have selection_changed signal")


func test_has_selection_cleared_signal() -> void:
	var manager = SelectionManagerClass.new()
	assert_true(manager.has_signal("selection_cleared"), "Should have selection_cleared signal")


func test_has_primary_selection_changed_signal() -> void:
	var manager = SelectionManagerClass.new()
	assert_true(manager.has_signal("primary_selection_changed"), "Should have primary_selection_changed signal")


# =============================================================================
# 単一選択テスト
# =============================================================================

func test_select_single_emits_signal() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	var received_data := {"elements": []}
	manager.selection_changed.connect(func(elements): received_data.elements = elements)

	manager.select_single(element)

	assert_eq(received_data.elements.size(), 1, "Should emit 1 element")
	assert_eq(received_data.elements[0], element, "Should be the selected element")


func test_select_single_sets_primary() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	var received_data := {"primary": null}
	manager.primary_selection_changed.connect(func(elem): received_data.primary = elem)

	manager.select_single(element)

	assert_eq(manager.get_primary(), element, "Primary should be the selected element")
	assert_eq(received_data.primary, element, "Should emit primary_selection_changed")


func test_get_selected_returns_selected_elements() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	manager.select_single(element)

	var selected = manager.get_selected()
	assert_eq(selected.size(), 1)
	assert_eq(selected[0], element)


# =============================================================================
# 複数選択テスト
# =============================================================================

func test_select_multiple_elements() -> void:
	var manager = SelectionManagerClass.new()
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

	var elements: Array[ElementData.ElementInstance] = [element1, element2]
	manager.select(elements)

	var selected = manager.get_selected()
	assert_eq(selected.size(), 2, "Should have 2 selected elements")
	assert_eq(manager.get_primary(), element1, "Primary should be first element")


func test_add_to_selection() -> void:
	var manager = SelectionManagerClass.new()
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

	manager.select_single(element1)
	manager.add_to_selection(element2)

	var selected = manager.get_selected()
	assert_eq(selected.size(), 2, "Should have 2 elements after add")


func test_add_duplicate_does_not_add() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	manager.select_single(element)
	manager.add_to_selection(element)  # 同じ要素を追加

	var selected = manager.get_selected()
	assert_eq(selected.size(), 1, "Should still have 1 element")


# =============================================================================
# 選択解除テスト
# =============================================================================

func test_remove_from_selection() -> void:
	var manager = SelectionManagerClass.new()
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

	var elements: Array[ElementData.ElementInstance] = [element1, element2]
	manager.select(elements)
	manager.remove_from_selection(element1)

	var selected = manager.get_selected()
	assert_eq(selected.size(), 1, "Should have 1 element after remove")
	assert_eq(selected[0], element2, "Should have element2 remaining")


func test_remove_primary_updates_primary() -> void:
	var manager = SelectionManagerClass.new()
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

	var elements: Array[ElementData.ElementInstance] = [element1, element2]
	manager.select(elements)
	manager.remove_from_selection(element1)  # primaryを削除

	assert_eq(manager.get_primary(), element2, "Primary should be updated to element2")


func test_clear_selection() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	var signal_data := {"cleared": false}
	manager.selection_cleared.connect(func(): signal_data.cleared = true)

	manager.select_single(element)
	manager.clear_selection()

	assert_true(signal_data.cleared, "Should emit selection_cleared")
	assert_eq(manager.get_selected().size(), 0, "Should have no selected elements")
	assert_null(manager.get_primary(), "Primary should be null")


# =============================================================================
# is_selected テスト
# =============================================================================

func test_is_selected_returns_true_for_selected() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	manager.select_single(element)

	assert_true(manager.is_selected(element), "Should return true for selected element")


func test_is_selected_returns_false_for_not_selected() -> void:
	var manager = SelectionManagerClass.new()
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

	manager.select_single(element1)

	assert_false(manager.is_selected(element2), "Should return false for non-selected element")


# =============================================================================
# WorldModel連携テスト
# =============================================================================

func test_element_removal_clears_from_selection() -> void:
	var world_model = WorldModelClass.new()
	var manager = SelectionManagerClass.new()
	manager.set_world_model(world_model)

	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	manager.select_single(element)
	assert_eq(manager.get_selected().size(), 1, "Should have 1 selected")

	# ユニットを破壊（WorldModelから削除）- elementオブジェクトを渡す
	world_model.remove_element(element)

	assert_eq(manager.get_selected().size(), 0, "Should have 0 selected after removal")


func test_multiple_element_removal() -> void:
	var world_model = WorldModelClass.new()
	var manager = SelectionManagerClass.new()
	manager.set_world_model(world_model)

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

	var elements: Array[ElementData.ElementInstance] = [element1, element2]
	manager.select(elements)

	# element1を削除 - elementオブジェクトを渡す
	world_model.remove_element(element1)

	assert_eq(manager.get_selected().size(), 1, "Should have 1 selected after removal")
	assert_eq(manager.get_primary(), element2, "Primary should be element2")


# =============================================================================
# 選択による破壊ユニット除外テスト
# =============================================================================

func test_destroyed_unit_not_selectable() -> void:
	var manager = SelectionManagerClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.is_destroyed = true

	manager.select_single(element)

	# 破壊されたユニットは選択されない
	assert_eq(manager.get_selected().size(), 0, "Destroyed unit should not be selected")
