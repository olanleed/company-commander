extends Node2D

## Company Commander - メインシーン
## 2D現代戦リアルタイムストラテジー
##
## Phase 1 実装: GameLoop + マップ読み込み

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
var background_sprite: Sprite2D

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	print("Company Commander 起動")

	_setup_sim_runner()
	_load_test_map()
	_setup_camera()
	_connect_signals()

	# シミュレーション開始
	sim_runner.start()

	_update_status_label()


func _process(_delta: float) -> void:
	_handle_input()
	_update_status_label()


func _setup_sim_runner() -> void:
	sim_runner = SimRunner.new()
	sim_runner.name = "SimRunner"
	add_child(sim_runner)


func _load_test_map() -> void:
	var map_path := "res://maps/MVP_01_CROSSROADS/"
	map_data = MapLoader.load_map(map_path)

	if map_data:
		print("マップ読み込み完了: " + map_data.map_id)
		print("  拠点数: " + str(map_data.capture_points.size()))
		print("  地形ゾーン数: " + str(map_data.terrain_zones.size()))
		_setup_map_visuals()
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
		# 背景がない場合は仮の矩形を描画
		_draw_placeholder_background()

	# デバッグ用: 拠点とスポーンポイントを表示
	_draw_debug_markers()


func _draw_placeholder_background() -> void:
	# ColorRectで仮背景
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.3, 0.2)  # 暗い緑
	bg.size = map_data.size_m
	map_layer.add_child(bg)


func _draw_debug_markers() -> void:
	# 拠点マーカー
	for cp in map_data.capture_points:
		var marker := _create_cp_marker(cp)
		map_layer.add_child(marker)

	# 初期スポーンポイント
	for ep in map_data.entry_points:
		var marker := _create_entry_point_marker(ep)
		map_layer.add_child(marker)

	# 地形ゾーンのアウトライン
	for zone in map_data.terrain_zones:
		var outline := _create_zone_outline(zone)
		map_layer.add_child(outline)


func _create_cp_marker(cp: MapData.CapturePoint) -> Node2D:
	var container := Node2D.new()
	container.position = cp.position

	# 拠点円
	var circle := _create_circle(map_data.cp_radius_m, _get_faction_color(cp.initial_owner, 0.3))
	container.add_child(circle)

	# 拠点ラベル
	var label := Label.new()
	label.text = cp.id
	label.position = Vector2(-10, -30)
	label.add_theme_font_size_override("font_size", 24)
	container.add_child(label)

	return container


func _create_entry_point_marker(ep: MapData.EntryPoint) -> Node2D:
	var marker := _create_circle(15, _get_faction_color(ep.faction, 0.6))
	marker.position = ep.position
	return marker


func _create_zone_outline(zone: MapData.TerrainZone) -> Line2D:
	var line := Line2D.new()
	line.points = zone.polygon
	if zone.polygon.size() > 0:
		line.add_point(zone.polygon[0])  # 閉じる
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


func _setup_camera() -> void:
	# マップ中央にカメラを配置
	camera.position = map_data.size_m / 2 if map_data else Vector2(1000, 1000)
	camera.zoom = Vector2(0.5, 0.5)  # 広めに見えるように


func _connect_signals() -> void:
	sim_runner.tick_advanced.connect(_on_tick_advanced)
	sim_runner.speed_changed.connect(_on_speed_changed)

# =============================================================================
# 入力処理
# =============================================================================

func _handle_input() -> void:
	# カメラ移動
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

	# ズーム
	if Input.is_action_just_pressed("ui_page_up"):
		camera.zoom *= 1.2
	if Input.is_action_just_pressed("ui_page_down"):
		camera.zoom /= 1.2
	camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))

	# 時間操作
	if Input.is_action_just_pressed("ui_select"):  # Space
		sim_runner.toggle_pause()
	if Input.is_key_pressed(KEY_EQUAL):  # +
		sim_runner.speed_up()
	if Input.is_key_pressed(KEY_MINUS):  # -
		sim_runner.speed_down()

# =============================================================================
# UI更新
# =============================================================================

func _update_status_label() -> void:
	if not sim_runner:
		return

	var speed_text := "Paused" if sim_runner.is_paused() else str(sim_runner.sim_speed) + "x"
	var time_text := "%.1f" % sim_runner.get_sim_time()

	status_label.text = "Company Commander | Tick: %d | Time: %s sec | Speed: %s" % [
		sim_runner.tick_index,
		time_text,
		speed_text
	]

# =============================================================================
# シグナルハンドラ
# =============================================================================

func _on_tick_advanced(_tick: int) -> void:
	# 毎tick処理 (将来的にはここでシム更新)
	pass


func _on_speed_changed(_new_speed: float) -> void:
	_update_status_label()
