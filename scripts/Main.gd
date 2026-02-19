extends Node2D

## Company Commander - メインシーン
## 2D現代戦リアルタイムストラテジー
##
## Phase 1: GameLoop + マップ読み込み
## Phase 2: Element表示 + ナビゲーション + 移動

# =============================================================================
# ノード参照
# =============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var map_layer: Node2D = $MapLayer
@onready var units_layer: Node2D = $UnitsLayer
@onready var hud: Control = $UILayer/HUD
@onready var status_label: Label = $UILayer/HUD/Label

# =============================================================================
# コンポーネント
# =============================================================================

var sim_runner: SimRunner
var map_data: MapData
var world_model: WorldModel
var nav_manager: NavigationManager
var movement_system: MovementSystem
var symbol_manager: SymbolManager

var background_sprite: Sprite2D
var _element_views: Dictionary = {}  # element_id -> ElementView
var _selected_elements: Array[ElementData.ElementInstance] = []

# =============================================================================
# プレイヤー設定
# =============================================================================

var player_faction: GameEnums.Faction = GameEnums.Faction.BLUE

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	print("Company Commander 起動")

	_setup_systems()
	_connect_signals()

	# マップ読み込みとナビゲーション構築を待機
	await _load_test_map_async()

	_setup_camera()
	_spawn_test_units()

	# シミュレーション開始
	sim_runner.start()

	_update_status_label()


func _process(_delta: float) -> void:
	_handle_input()
	_update_element_views()
	_update_status_label()


func _setup_systems() -> void:
	# SimRunner
	sim_runner = SimRunner.new()
	sim_runner.name = "SimRunner"
	add_child(sim_runner)

	# WorldModel
	world_model = WorldModel.new()

	# SymbolManager
	symbol_manager = SymbolManager.new()
	symbol_manager.preload_all_symbols()

	# NavigationManager
	nav_manager = NavigationManager.new()
	nav_manager.name = "NavigationManager"
	add_child(nav_manager)

	# MovementSystem
	movement_system = MovementSystem.new()


func _load_test_map_async() -> void:
	var map_path := "res://maps/MVP_01_CROSSROADS/"
	map_data = MapLoader.load_map(map_path)

	if map_data:
		print("マップ読み込み完了: " + map_data.map_id)
		print("  拠点数: " + str(map_data.capture_points.size()))
		print("  地形ゾーン数: " + str(map_data.terrain_zones.size()))
		_setup_map_visuals()

		# MovementSystem をセットアップ (nav_managerへの参照を先に設定)
		movement_system.setup(nav_manager, map_data)

		# ナビゲーション構築 (完了を待機)
		await nav_manager.build_from_map_data(map_data)
		print("ナビゲーション構築完了")
	else:
		push_error("マップ読み込み失敗")


func _setup_map_visuals() -> void:
	# 背景画像があれば読み込む
	var bg_path := "res://maps/MVP_01_CROSSROADS/" + map_data.background_file
	if ResourceLoader.exists(bg_path):
		var texture := load(bg_path) as Texture2D
		if texture:
			background_sprite = Sprite2D.new()
			background_sprite.texture = texture
			background_sprite.centered = false
			background_sprite.scale = Vector2(
				map_data.size_m.x / texture.get_width(),
				map_data.size_m.y / texture.get_height()
			)
			map_layer.add_child(background_sprite)
	else:
		_draw_placeholder_background()

	_draw_debug_markers()


func _draw_placeholder_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.3, 0.2)
	bg.size = map_data.size_m
	map_layer.add_child(bg)


func _draw_debug_markers() -> void:
	# 拠点マーカー
	for cp in map_data.capture_points:
		var marker := _create_cp_marker(cp)
		map_layer.add_child(marker)

	# 地形ゾーンのアウトライン
	for zone in map_data.terrain_zones:
		var outline := _create_zone_outline(zone)
		map_layer.add_child(outline)


func _setup_camera() -> void:
	camera.position = map_data.size_m / 2 if map_data else Vector2(1000, 1000)
	camera.zoom = Vector2(0.5, 0.5)


func _connect_signals() -> void:
	sim_runner.tick_advanced.connect(_on_tick_advanced)
	sim_runner.speed_changed.connect(_on_speed_changed)
	world_model.element_added.connect(_on_element_added)
	world_model.element_removed.connect(_on_element_removed)

# =============================================================================
# テストユニット生成
# =============================================================================

func _spawn_test_units() -> void:
	# 歩兵タイプ
	var inf_type := ElementData.ElementType.new()
	inf_type.id = "inf_rifle"
	inf_type.display_name = "Rifle Squad"
	inf_type.category = ElementData.Category.INF
	inf_type.symbol_type = ElementData.SymbolType.INF_RIFLE
	inf_type.mobility_class = GameEnums.MobilityType.FOOT
	inf_type.road_speed = 5.0
	inf_type.cross_speed = 3.0
	inf_type.max_strength = 10
	inf_type.spot_range_base = 300.0

	# 戦車タイプ
	var tank_type := ElementData.ElementType.new()
	tank_type.id = "armor_tank"
	tank_type.display_name = "Tank Platoon"
	tank_type.category = ElementData.Category.VEH
	tank_type.symbol_type = ElementData.SymbolType.ARMOR_TANK
	tank_type.mobility_class = GameEnums.MobilityType.TRACKED
	tank_type.road_speed = 12.0
	tank_type.cross_speed = 8.0
	tank_type.max_strength = 4
	tank_type.spot_range_base = 500.0
	tank_type.armor_class = 3

	# IFVタイプ
	var ifv_type := ElementData.ElementType.new()
	ifv_type.id = "armor_ifv"
	ifv_type.display_name = "IFV Section"
	ifv_type.category = ElementData.Category.VEH
	ifv_type.symbol_type = ElementData.SymbolType.ARMOR_IFV
	ifv_type.mobility_class = GameEnums.MobilityType.TRACKED
	ifv_type.road_speed = 15.0
	ifv_type.cross_speed = 10.0
	ifv_type.max_strength = 3
	ifv_type.armor_class = 2

	# BLUE陣営
	var entry_points := map_data.get_entry_points_for_faction(GameEnums.Faction.BLUE)
	if entry_points.size() >= 3:
		world_model.create_test_element(inf_type, GameEnums.Faction.BLUE, entry_points[0].position)
		world_model.create_test_element(inf_type, GameEnums.Faction.BLUE, entry_points[1].position)
		world_model.create_test_element(tank_type, GameEnums.Faction.BLUE, entry_points[2].position)

	# RED陣営
	entry_points = map_data.get_entry_points_for_faction(GameEnums.Faction.RED)
	if entry_points.size() >= 3:
		world_model.create_test_element(inf_type, GameEnums.Faction.RED, entry_points[0].position)
		world_model.create_test_element(ifv_type, GameEnums.Faction.RED, entry_points[1].position)
		world_model.create_test_element(tank_type, GameEnums.Faction.RED, entry_points[2].position)

	print("テストユニット生成完了: ", world_model.elements.size(), " elements")

# =============================================================================
# Element表示
# =============================================================================

func _on_element_added(element: ElementData.ElementInstance) -> void:
	var view := ElementView.new()
	view.setup(element, symbol_manager, player_faction)
	units_layer.add_child(view)
	_element_views[element.id] = view


func _on_element_removed(element: ElementData.ElementInstance) -> void:
	if element.id in _element_views:
		var view: ElementView = _element_views[element.id]
		view.queue_free()
		_element_views.erase(element.id)


func _update_element_views() -> void:
	var alpha := sim_runner.alpha if sim_runner else 0.0

	for element_id in _element_views:
		var view: ElementView = _element_views[element_id]
		view.update_position_interpolated(alpha)
		view.queue_redraw()

# =============================================================================
# 入力処理
# =============================================================================

func _handle_input() -> void:
	_handle_camera_input()
	_handle_time_input()
	_handle_selection_input()
	_handle_order_input()


func _handle_camera_input() -> void:
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1
	if Input.is_action_pressed("ui_up"):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_dir.y += 1

	if move_dir != Vector2.ZERO:
		camera.position += move_dir.normalized() * 500 * get_process_delta_time() / camera.zoom.x

	if Input.is_action_just_pressed("ui_page_up"):
		camera.zoom *= 1.2
	if Input.is_action_just_pressed("ui_page_down"):
		camera.zoom /= 1.2
	camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))


func _handle_time_input() -> void:
	if Input.is_action_just_pressed("ui_select"):
		sim_runner.toggle_pause()
	if Input.is_key_pressed(KEY_EQUAL):
		sim_runner.speed_up()
	if Input.is_key_pressed(KEY_MINUS):
		sim_runner.speed_down()


func _handle_selection_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):  # Enter
		# テスト用: 全味方ユニットを選択
		_clear_selection()
		for element in world_model.get_elements_for_faction(player_faction):
			_add_to_selection(element)


func _handle_order_input() -> void:
	# Escで移動命令（右クリック代替）
	if Input.is_action_just_pressed("ui_cancel"):
		if _selected_elements.size() > 0:
			var target := _get_world_mouse_position()
			for element in _selected_elements:
				if element.faction == player_faction:
					movement_system.issue_move_order(element, target, false)


func _get_world_mouse_position() -> Vector2:
	var viewport_mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var canvas_xform_inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	return canvas_xform_inv * viewport_mouse_pos


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var canvas_xform_inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
		var world_pos: Vector2 = canvas_xform_inv * mouse_event.position

		# 左クリックで選択
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var clicked_element := _get_element_at_position(world_pos)

			if clicked_element:
				if not Input.is_key_pressed(KEY_SHIFT):
					_clear_selection()
				_add_to_selection(clicked_element)
				print("選択: ", clicked_element.id, " (total: ", _selected_elements.size(), ")")
			else:
				# 何もないところをクリックしたら選択解除
				if not Input.is_key_pressed(KEY_SHIFT):
					_clear_selection()
					print("選択解除")

		# 右クリックで移動命令
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if _selected_elements.size() > 0:
				print("移動命令: ", _selected_elements.size(), " units to ", world_pos)
				for element in _selected_elements:
					if element.faction == player_faction:
						print("  Element ", element.id, " at ", element.position, " -> ", world_pos)
						movement_system.issue_move_order(element, world_pos, false)


func _get_element_at_position(pos: Vector2) -> ElementData.ElementInstance:
	for element_id in _element_views:
		var view: ElementView = _element_views[element_id]
		if view.contains_point(pos):
			return view.element
	return null


func _clear_selection() -> void:
	for element in _selected_elements:
		if element.id in _element_views:
			_element_views[element.id].set_selected(false)
	_selected_elements.clear()


func _add_to_selection(element: ElementData.ElementInstance) -> void:
	if element not in _selected_elements:
		_selected_elements.append(element)
		if element.id in _element_views:
			_element_views[element.id].set_selected(true)

# =============================================================================
# Tick処理
# =============================================================================

func _on_tick_advanced(_tick: int) -> void:
	# 全Elementの状態を保存
	world_model.save_prev_states()

	# 移動更新
	for element in world_model.elements:
		movement_system.update_element(element, GameConstants.SIM_DT)


func _on_speed_changed(_new_speed: float) -> void:
	_update_status_label()

# =============================================================================
# UI更新
# =============================================================================

func _update_status_label() -> void:
	if not sim_runner:
		return

	var speed_text := "Paused" if sim_runner.is_paused() else str(sim_runner.sim_speed) + "x"
	var time_text := "%.1f" % sim_runner.get_sim_time()
	var selected_text := str(_selected_elements.size()) + " selected"

	status_label.text = "Tick: %d | Time: %s sec | Speed: %s | %s | RClick=Move" % [
		sim_runner.tick_index,
		time_text,
		speed_text,
		selected_text
	]

# =============================================================================
# マーカー作成ヘルパー
# =============================================================================

func _create_cp_marker(cp: MapData.CapturePoint) -> Node2D:
	var container := Node2D.new()
	container.position = cp.position

	var circle := _create_circle(map_data.cp_radius_m, _get_faction_color(cp.initial_owner, 0.3))
	container.add_child(circle)

	var label := Label.new()
	label.text = cp.id
	label.position = Vector2(-10, -30)
	label.add_theme_font_size_override("font_size", 24)
	container.add_child(label)

	return container


func _create_zone_outline(zone: MapData.TerrainZone) -> Line2D:
	var line := Line2D.new()
	line.points = zone.polygon
	if zone.polygon.size() > 0:
		line.add_point(zone.polygon[0])
	line.width = 2.0
	line.default_color = _get_terrain_color(zone.terrain_type)
	return line


func _create_circle(radius: float, color: Color) -> Node2D:
	var circle := Node2D.new()
	circle.set_script(preload("res://scripts/debug/circle_drawer.gd"))
	circle.set("radius", radius)
	circle.set("color", color)
	return circle


func _get_faction_color(faction: GameEnums.Faction, alpha: float = 1.0) -> Color:
	match faction:
		GameEnums.Faction.BLUE:
			return Color(0.2, 0.4, 0.8, alpha)
		GameEnums.Faction.RED:
			return Color(0.8, 0.2, 0.2, alpha)
		_:
			return Color(0.5, 0.5, 0.5, alpha)


func _get_terrain_color(terrain: GameEnums.TerrainType) -> Color:
	match terrain:
		GameEnums.TerrainType.ROAD:
			return Color(0.4, 0.3, 0.2)
		GameEnums.TerrainType.FOREST:
			return Color(0.1, 0.5, 0.1)
		GameEnums.TerrainType.URBAN:
			return Color(0.5, 0.5, 0.5)
		GameEnums.TerrainType.WATER:
			return Color(0.2, 0.3, 0.7)
		_:
			return Color(0.3, 0.4, 0.3)
