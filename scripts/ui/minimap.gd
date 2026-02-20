class_name Minimap
extends PanelContainer

## ミニマップ
## マップ全体を縮小表示、クリックでカメラジャンプ

# =============================================================================
# シグナル
# =============================================================================

signal clicked(world_pos: Vector2)

# =============================================================================
# UI要素
# =============================================================================

var _draw_area: Control

# =============================================================================
# 状態
# =============================================================================

var _map_data: MapData
var _world_model: WorldModel
var _player_faction: GameEnums.Faction
var _camera_rect: Rect2 = Rect2()

# =============================================================================
# 定数
# =============================================================================

const MINIMAP_SIZE := Vector2(200, 150)
const MARGIN := 10

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func setup(map_data: MapData, world_model: WorldModel, player_faction: GameEnums.Faction) -> void:
	_map_data = map_data
	_world_model = world_model
	_player_faction = player_faction
	queue_redraw()


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size = MINIMAP_SIZE

	# 描画エリア
	_draw_area = Control.new()
	_draw_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_area.draw.connect(_on_draw)
	_draw_area.gui_input.connect(_on_gui_input)
	add_child(_draw_area)


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)

# =============================================================================
# 描画
# =============================================================================

func _on_draw() -> void:
	if not _map_data:
		return

	var draw_size := _draw_area.size - Vector2(8, 8)  # パディング
	var offset := Vector2(4, 4)

	# スケール計算
	var scale := Vector2(
		draw_size.x / _map_data.size_m.x,
		draw_size.y / _map_data.size_m.y
	)

	# 地形ゾーンを描画
	for zone in _map_data.terrain_zones:
		var color := _get_terrain_color(zone.terrain_type)
		var scaled_polygon := PackedVector2Array()
		for point in zone.polygon:
			scaled_polygon.append(point * scale + offset)
		if scaled_polygon.size() >= 3:
			_draw_area.draw_polygon(scaled_polygon, [color])

	# 拠点を描画
	for cp in _map_data.capture_points:
		var pos := cp.position * scale + offset
		var color := _get_faction_color(cp.initial_owner)
		_draw_area.draw_circle(pos, 6, color)
		_draw_area.draw_circle(pos, 6, Color.WHITE, false, 1.0)

	# ユニットを描画
	if _world_model:
		for element in _world_model.elements:
			var pos := element.position * scale + offset
			var color := _get_faction_color(element.faction)

			# 敵はFoW状態に応じて表示
			if element.faction != _player_faction:
				# TODO: VisionSystem連携
				color = color.darkened(0.5)

			_draw_area.draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), color)

	# カメラ範囲を描画
	if _camera_rect.size.x > 0:
		var cam_rect := Rect2(
			_camera_rect.position * scale + offset,
			_camera_rect.size * scale
		)
		_draw_area.draw_rect(cam_rect, Color(1, 1, 1, 0.3), false, 1.0)


func _get_terrain_color(terrain: GameEnums.TerrainType) -> Color:
	match terrain:
		GameEnums.TerrainType.ROAD:
			return Color(0.35, 0.3, 0.25)
		GameEnums.TerrainType.FOREST:
			return Color(0.15, 0.35, 0.15)
		GameEnums.TerrainType.URBAN:
			return Color(0.4, 0.4, 0.4)
		GameEnums.TerrainType.WATER:
			return Color(0.2, 0.3, 0.5)
		_:
			return Color(0.25, 0.3, 0.2)


func _get_faction_color(faction: GameEnums.Faction) -> Color:
	match faction:
		GameEnums.Faction.BLUE:
			return Color(0.3, 0.5, 1.0)
		GameEnums.Faction.RED:
			return Color(1.0, 0.3, 0.3)
		_:
			return Color(0.6, 0.6, 0.6)

# =============================================================================
# カメラ範囲更新
# =============================================================================

func set_camera_rect(rect: Rect2) -> void:
	_camera_rect = rect
	queue_redraw()

# =============================================================================
# 入力処理
# =============================================================================

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_click(mouse_event.position)


func _handle_click(local_pos: Vector2) -> void:
	if not _map_data:
		return

	var draw_size := _draw_area.size - Vector2(8, 8)
	var offset := Vector2(4, 4)

	# ローカル座標からワールド座標へ変換
	var relative_pos := (local_pos - offset) / draw_size
	var world_pos := Vector2(
		relative_pos.x * _map_data.size_m.x,
		relative_pos.y * _map_data.size_m.y
	)

	clicked.emit(world_pos)
