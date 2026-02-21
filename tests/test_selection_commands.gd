extends GutTest

## ユニット選択とコマンド実行のユニットテスト
## バグ防止: 選択していないユニットへのコマンド発行を防ぐ

var world_model: WorldModel
var map_data: MapData
var movement_system: MovementSystem
var vision_system: VisionSystem

var _inf_type: ElementData.ElementType
var _tank_type: ElementData.ElementType


func before_each() -> void:
	world_model = WorldModel.new()
	map_data = _create_test_map_data()
	movement_system = MovementSystem.new()
	vision_system = VisionSystem.new()
	vision_system.setup(world_model, map_data)

	_inf_type = _create_infantry_type()
	_tank_type = _create_tank_type()


func _create_test_map_data() -> MapData:
	var data := MapData.new()
	data.map_id = "test_map"
	data.size_m = Vector2(2000, 2000)
	data.cp_radius_m = 40.0
	return data


func _create_infantry_type() -> ElementData.ElementType:
	var et := ElementData.ElementType.new()
	et.id = "inf_rifle"
	et.display_name = "Rifle Squad"
	et.category = ElementData.Category.INF
	et.symbol_type = ElementData.SymbolType.INF_RIFLE
	et.mobility_class = GameEnums.MobilityType.FOOT
	et.road_speed = 5.0
	et.cross_speed = 3.0
	et.max_strength = 10
	et.spot_range_base = 300.0
	return et


func _create_tank_type() -> ElementData.ElementType:
	var et := ElementData.ElementType.new()
	et.id = "tank_mbt"
	et.display_name = "Main Battle Tank"
	et.category = ElementData.Category.VEH
	et.symbol_type = ElementData.SymbolType.ARMOR_TANK
	et.mobility_class = GameEnums.MobilityType.TRACKED
	et.road_speed = 12.0
	et.cross_speed = 8.0
	et.max_strength = 4
	et.spot_range_base = 500.0
	return et


# =============================================================================
# 選択状態管理テスト
# =============================================================================

func test_empty_selection_array() -> void:
	var selected: Array[ElementData.ElementInstance] = []
	assert_eq(selected.size(), 0, "初期状態で選択は空")


func test_add_to_selection() -> void:
	var selected: Array[ElementData.ElementInstance] = []
	var elem := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))

	if elem not in selected:
		selected.append(elem)

	assert_eq(selected.size(), 1, "1ユニットが選択された")
	assert_true(selected.has(elem), "選択配列に含まれている")


func test_add_duplicate_to_selection() -> void:
	var selected: Array[ElementData.ElementInstance] = []
	var elem := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))

	# 2回追加しようとする
	if elem not in selected:
		selected.append(elem)
	if elem not in selected:
		selected.append(elem)

	assert_eq(selected.size(), 1, "重複追加されない")


func test_remove_from_selection() -> void:
	var selected: Array[ElementData.ElementInstance] = []
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	selected.append(elem1)
	selected.append(elem2)
	assert_eq(selected.size(), 2)

	selected.erase(elem1)
	assert_eq(selected.size(), 1)
	assert_false(selected.has(elem1), "elem1は削除された")
	assert_true(selected.has(elem2), "elem2は残っている")


func test_clear_selection() -> void:
	var selected: Array[ElementData.ElementInstance] = []
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	selected.append(elem1)
	selected.append(elem2)
	selected.clear()

	assert_eq(selected.size(), 0, "選択がクリアされた")


# =============================================================================
# 選択ユニットへのコマンド実行テスト（コア機能）
# =============================================================================

func test_move_command_only_affects_selected() -> void:
	# 3ユニット作成
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))
	var elem3 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(300, 100))

	# elem1のみ選択
	var selected: Array[ElementData.ElementInstance] = [elem1]

	# 選択ユニットにMOVE命令
	var target_pos := Vector2(500, 500)
	_execute_move_for_selected(selected, target_pos)

	# elem1のみ移動中
	assert_true(elem1.is_moving, "選択されたelem1は移動中")
	assert_false(elem2.is_moving, "選択されていないelem2は移動していない")
	assert_false(elem3.is_moving, "選択されていないelem3は移動していない")


func test_move_command_multiple_selected() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))
	var elem3 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(300, 100))

	# elem1とelem2を選択
	var selected: Array[ElementData.ElementInstance] = [elem1, elem2]

	var target_pos := Vector2(500, 500)
	_execute_move_for_selected(selected, target_pos)

	assert_true(elem1.is_moving, "elem1は移動中")
	assert_true(elem2.is_moving, "elem2は移動中")
	assert_false(elem3.is_moving, "elem3は移動していない")


func test_move_command_empty_selection_no_effect() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))

	# 空の選択
	var selected: Array[ElementData.ElementInstance] = []

	var target_pos := Vector2(500, 500)
	_execute_move_for_selected(selected, target_pos)

	assert_false(elem1.is_moving, "選択がないのでelem1は移動しない")


func test_move_command_ignores_enemy_units() -> void:
	var blue := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_inf_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 両方選択しても敵ユニットは無視
	var selected: Array[ElementData.ElementInstance] = [blue, red]
	var player_faction := GameEnums.Faction.BLUE

	var target_pos := Vector2(500, 500)
	_execute_move_for_selected_with_faction(selected, target_pos, player_faction)

	assert_true(blue.is_moving, "味方blueは移動中")
	assert_false(red.is_moving, "敵redは移動しない")


func test_move_command_ignores_destroyed_units() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))
	elem2.state = GameEnums.UnitState.DESTROYED

	var selected: Array[ElementData.ElementInstance] = [elem1, elem2]

	var target_pos := Vector2(500, 500)
	_execute_move_for_selected(selected, target_pos)

	assert_true(elem1.is_moving, "elem1は移動中")
	assert_false(elem2.is_moving, "破壊されたelem2は移動しない")


# =============================================================================
# ATTACK命令テスト
# =============================================================================

func test_attack_command_only_affects_selected() -> void:
	var blue1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var blue2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))
	var red := world_model.create_test_element(_inf_type, GameEnums.Faction.RED, Vector2(150, 200))

	# blue1のみ選択
	var selected: Array[ElementData.ElementInstance] = [blue1]
	var player_faction := GameEnums.Faction.BLUE

	_execute_attack_for_selected(selected, red, player_faction)

	assert_eq(blue1.forced_target_id, red.id, "blue1は目標を設定")
	assert_eq(blue1.current_order_type, GameEnums.OrderType.ATTACK, "blue1はATTACK命令")
	assert_eq(blue2.forced_target_id, "", "blue2は目標なし")


func test_attack_command_sets_order_type() -> void:
	var blue := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_inf_type, GameEnums.Faction.RED, Vector2(150, 200))

	var selected: Array[ElementData.ElementInstance] = [blue]
	var player_faction := GameEnums.Faction.BLUE

	_execute_attack_for_selected(selected, red, player_faction)

	assert_eq(blue.current_order_type, GameEnums.OrderType.ATTACK)
	assert_eq(blue.forced_target_id, red.id)
	assert_eq(blue.order_target_id, red.id)


# =============================================================================
# DEFEND命令テスト
# =============================================================================

func test_defend_command_only_affects_selected() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	var selected: Array[ElementData.ElementInstance] = [elem1]
	var target_pos := Vector2(500, 500)

	_execute_defend_for_selected(selected, target_pos)

	assert_eq(elem1.current_order_type, GameEnums.OrderType.DEFEND, "elem1はDEFEND命令")
	assert_ne(elem2.current_order_type, GameEnums.OrderType.DEFEND, "elem2はDEFEND命令ではない")


# =============================================================================
# 選択状態の永続性テスト
# =============================================================================

func test_selection_persists_after_command() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	# elem2は選択されないユニットとして存在確認用
	var _elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	var selected: Array[ElementData.ElementInstance] = [elem1]

	# コマンド実行
	_execute_move_for_selected(selected, Vector2(500, 500))

	# 選択は維持される
	assert_eq(selected.size(), 1, "選択状態は維持")
	assert_true(selected.has(elem1), "elem1は選択されたまま")


func test_selection_removed_when_unit_destroyed() -> void:
	var elem := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))

	var selected: Array[ElementData.ElementInstance] = [elem]
	assert_eq(selected.size(), 1)

	# 破壊時に選択から削除
	elem.state = GameEnums.UnitState.DESTROYED
	if elem in selected:
		selected.erase(elem)

	assert_eq(selected.size(), 0, "破壊されたユニットは選択から削除")


# =============================================================================
# ボックス選択テスト
# =============================================================================

func test_box_selection_selects_units_in_rect() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(150, 150))
	var elem3 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(500, 500))

	var rect := Rect2(50, 50, 200, 200)  # (50,50) to (250,250)
	var selected: Array[ElementData.ElementInstance] = []
	var player_faction := GameEnums.Faction.BLUE

	for element in world_model.get_elements_for_faction(player_faction):
		if rect.has_point(element.position):
			selected.append(element)

	assert_eq(selected.size(), 2, "2ユニットが範囲内")
	assert_true(selected.has(elem1), "elem1は範囲内")
	assert_true(selected.has(elem2), "elem2は範囲内")
	assert_false(selected.has(elem3), "elem3は範囲外")


func test_box_selection_ignores_enemy_units() -> void:
	var blue := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	# redは範囲内だがget_elements_for_faction(BLUE)に含まれないため選択されない
	var _red := world_model.create_test_element(_inf_type, GameEnums.Faction.RED, Vector2(150, 150))

	var rect := Rect2(50, 50, 200, 200)
	var selected: Array[ElementData.ElementInstance] = []
	var player_faction := GameEnums.Faction.BLUE

	for element in world_model.get_elements_for_faction(player_faction):
		if rect.has_point(element.position):
			selected.append(element)

	assert_eq(selected.size(), 1, "味方のみ選択")
	assert_true(selected.has(blue), "blueは選択される")


# =============================================================================
# 複合テスト
# =============================================================================

func test_consecutive_commands_affect_only_current_selection() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))
	var elem3 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(300, 100))

	# 最初にelem1を選択して移動
	var selected: Array[ElementData.ElementInstance] = [elem1]
	_execute_move_for_selected(selected, Vector2(400, 100))
	assert_true(elem1.is_moving)

	# 選択を変更してelem2を選択して移動
	selected.clear()
	selected.append(elem2)
	_execute_move_for_selected(selected, Vector2(400, 200))

	assert_true(elem2.is_moving, "elem2は移動中")
	assert_false(elem3.is_moving, "elem3は移動していない（一度も選択されていない）")


func test_shift_selection_adds_to_existing() -> void:
	var elem1 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var elem2 := world_model.create_test_element(_inf_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	var selected: Array[ElementData.ElementInstance] = []

	# elem1を選択
	selected.append(elem1)
	assert_eq(selected.size(), 1)

	# Shift選択でelem2を追加（既存の選択を維持）
	if elem2 not in selected:
		selected.append(elem2)

	assert_eq(selected.size(), 2)
	assert_true(selected.has(elem1))
	assert_true(selected.has(elem2))


# =============================================================================
# ヘルパー関数（Main.gdの_execute_command_for_selectedを模倣）
# =============================================================================

func _execute_move_for_selected(selected: Array[ElementData.ElementInstance], target_pos: Vector2) -> void:
	_execute_move_for_selected_with_faction(selected, target_pos, GameEnums.Faction.BLUE)


func _execute_move_for_selected_with_faction(
	selected: Array[ElementData.ElementInstance],
	target_pos: Vector2,
	player_faction: GameEnums.Faction
) -> void:
	if selected.size() == 0:
		return

	for element in selected:
		if element.faction != player_faction:
			continue
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		element.forced_target_id = ""
		element.current_order_type = GameEnums.OrderType.MOVE
		# テスト用: nav_managerなしで動作するよう直接状態を設定
		# 実際のゲームではmovement_system.issue_move_order()を使用
		element.current_path = PackedVector2Array([element.position, target_pos])
		element.path_index = 1
		element.is_moving = true
		element.order_target_position = target_pos


func _execute_attack_for_selected(
	selected: Array[ElementData.ElementInstance],
	target: ElementData.ElementInstance,
	player_faction: GameEnums.Faction
) -> void:
	if not target:
		return

	for element in selected:
		if element.faction != player_faction:
			continue
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		element.forced_target_id = target.id
		element.order_target_id = target.id
		element.current_order_type = GameEnums.OrderType.ATTACK


func _execute_defend_for_selected(selected: Array[ElementData.ElementInstance], target_pos: Vector2) -> void:
	for element in selected:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		element.forced_target_id = ""
		element.current_order_type = GameEnums.OrderType.DEFEND
		# テスト用: nav_managerなしで動作するよう直接状態を設定
		element.current_path = PackedVector2Array([element.position, target_pos])
		element.path_index = 1
		element.is_moving = true
		element.order_target_position = target_pos
