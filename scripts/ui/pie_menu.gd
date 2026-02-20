class_name PieMenu
extends Control

## 放射状コマンドメニュー（Pie Menu / Marking Menu）
## 右クリック長押しで表示、8方向でコマンド選択
## 仕様: docs/ui_design_v0.1.md, docs/ui_input_v0.1.md

# =============================================================================
# 定数
# =============================================================================

const INNER_RADIUS := 40.0
const OUTER_RADIUS := 120.0
const ACTIVATION_DELAY := 0.2  # 右クリック長押し判定（秒）
const DEADZONE_RADIUS := 30.0  # 中心のデッドゾーン

## 8方向コマンド配置（12時から時計回り）
## N=Move, NE=Defend, E=Attack, SE=Recon, S=Break, SW=Smoke, W=Support, NW=Suppress
const COMMANDS := [
	{"name": "Move", "type": GameEnums.OrderType.MOVE, "angle": 270, "color": Color(0.3, 0.6, 0.9)},
	{"name": "Defend", "type": GameEnums.OrderType.DEFEND, "angle": 315, "color": Color(0.3, 0.8, 0.3)},
	{"name": "Attack", "type": GameEnums.OrderType.ATTACK, "angle": 0, "color": Color(0.9, 0.3, 0.3)},
	{"name": "Recon", "type": GameEnums.OrderType.RECON, "angle": 45, "color": Color(0.7, 0.7, 0.3)},
	{"name": "Break", "type": GameEnums.OrderType.BREAK_CONTACT, "angle": 90, "color": Color(0.5, 0.5, 0.5)},
	{"name": "Smoke", "type": GameEnums.OrderType.SMOKE, "angle": 135, "color": Color(0.6, 0.6, 0.7)},
	{"name": "Support", "type": GameEnums.OrderType.SUPPORT, "angle": 180, "color": Color(0.4, 0.7, 0.4)},
	{"name": "Suppress", "type": GameEnums.OrderType.SUPPRESS, "angle": 225, "color": Color(0.8, 0.5, 0.2)},
]

# =============================================================================
# シグナル
# =============================================================================

signal command_selected(command_type: GameEnums.OrderType, world_pos: Vector2)
signal menu_cancelled()

# =============================================================================
# 状態
# =============================================================================

var _is_active := false
var _center_pos := Vector2.ZERO
var _world_pos := Vector2.ZERO  # ワールド座標（命令の目標位置）
var _hovered_index := -1
var _selected_command: GameEnums.OrderType = GameEnums.OrderType.NONE


# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	# 全画面オーバーレイ
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 非表示時はマウスイベントを通過させる
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _draw() -> void:
	if not _is_active:
		return

	# 背景オーバーレイ
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))

	# メニュー描画
	_draw_pie_segments()
	_draw_center_circle()
	_draw_labels()


func _draw_pie_segments() -> void:
	var segment_angle := TAU / COMMANDS.size()

	for i in range(COMMANDS.size()):
		var cmd: Dictionary = COMMANDS[i]
		var start_angle: float = deg_to_rad(cmd.angle) - segment_angle / 2
		var end_angle: float = start_angle + segment_angle

		var is_hovered := i == _hovered_index
		var color: Color = cmd.color
		if is_hovered:
			color = color.lightened(0.3)
		else:
			color = color.darkened(0.3)
			color.a = 0.7

		# セグメントを描画（多角形近似）
		var points := PackedVector2Array()
		var steps := 16

		# 内側の弧
		for j in range(steps + 1):
			var angle: float = start_angle + (end_angle - start_angle) * j / steps
			points.append(_center_pos + Vector2(cos(angle), sin(angle)) * INNER_RADIUS)

		# 外側の弧（逆順）
		for j in range(steps, -1, -1):
			var angle: float = start_angle + (end_angle - start_angle) * j / steps
			points.append(_center_pos + Vector2(cos(angle), sin(angle)) * OUTER_RADIUS)

		draw_polygon(points, [color])

		# 境界線
		var border_color := Color.WHITE if is_hovered else Color(0.4, 0.4, 0.5)
		for j in range(points.size()):
			var next_j := (j + 1) % points.size()
			draw_line(points[j], points[next_j], border_color, 1.0 if is_hovered else 0.5)


func _draw_center_circle() -> void:
	# 中心円（キャンセルゾーン）
	var center_color := Color(0.2, 0.2, 0.25, 0.9)
	if _hovered_index == -1:
		center_color = Color(0.3, 0.3, 0.35, 0.9)

	draw_circle(_center_pos, INNER_RADIUS, center_color)
	draw_arc(_center_pos, INNER_RADIUS, 0, TAU, 32, Color(0.5, 0.5, 0.6), 2.0)

	# キャンセルテキスト
	var font := ThemeDB.fallback_font
	var font_size := 12
	var text := "Cancel"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, _center_pos - text_size / 2 + Vector2(0, font_size / 3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.7, 0.7, 0.7))


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 14

	for i in range(COMMANDS.size()):
		var cmd: Dictionary = COMMANDS[i]
		var angle: float = deg_to_rad(cmd.angle)
		var label_radius: float = (INNER_RADIUS + OUTER_RADIUS) / 2
		var label_pos := _center_pos + Vector2(cos(angle), sin(angle)) * label_radius

		var is_hovered := i == _hovered_index
		var color := Color.WHITE if is_hovered else Color(0.85, 0.85, 0.85)

		var text: String = cmd.name
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, label_pos - text_size / 2 + Vector2(0, font_size / 3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

# =============================================================================
# 入力処理
# =============================================================================

func _input(event: InputEvent) -> void:
	# アクティブ時のみ入力を処理
	if _is_active:
		_handle_active_input(event)


func _handle_active_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse := event as InputEventMouseMotion
		_update_hover(mouse.position)
		queue_redraw()
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT and not mouse.pressed:
			# 右クリックリリースで確定
			_confirm_selection()
			get_viewport().set_input_as_handled()
		elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			# 左クリックでキャンセル
			cancel()
			get_viewport().set_input_as_handled()




func _update_hover(mouse_pos: Vector2) -> void:
	var offset := mouse_pos - _center_pos
	var distance := offset.length()

	if distance < DEADZONE_RADIUS:
		_hovered_index = -1
		return

	# 角度からセグメントを特定
	var angle := fmod(offset.angle() + TAU, TAU)  # 0〜TAU に正規化
	var segment_angle := TAU / COMMANDS.size()

	for i in range(COMMANDS.size()):
		var cmd: Dictionary = COMMANDS[i]
		var cmd_angle := fmod(deg_to_rad(cmd.angle) + TAU, TAU)
		var start_angle := fmod(cmd_angle - segment_angle / 2 + TAU, TAU)
		var end_angle := fmod(cmd_angle + segment_angle / 2 + TAU, TAU)

		# 角度が範囲内かチェック
		if _angle_in_range(angle, start_angle, end_angle):
			_hovered_index = i
			return

	_hovered_index = -1


func _angle_in_range(angle: float, start: float, end: float) -> bool:
	# 範囲が0をまたぐ場合の処理
	if start > end:
		return angle >= start or angle <= end
	return angle >= start and angle <= end


func _confirm_selection() -> void:
	if _hovered_index >= 0 and _hovered_index < COMMANDS.size():
		var cmd: Dictionary = COMMANDS[_hovered_index]
		_selected_command = cmd.type
		command_selected.emit(_selected_command, _world_pos)
	else:
		menu_cancelled.emit()

	hide_menu()

# =============================================================================
# メニュー表示/非表示
# =============================================================================

## メニューを表示
func show_menu(screen_pos: Vector2, world_pos: Vector2) -> void:
	_center_pos = screen_pos
	_world_pos = world_pos
	_hovered_index = -1
	_is_active = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP  # 表示時はイベントをキャプチャ
	queue_redraw()


## メニューを非表示
func hide_menu() -> void:
	_is_active = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 非表示時はイベントを通過
	_hovered_index = -1


## メニューをキャンセル
func cancel() -> void:
	menu_cancelled.emit()
	hide_menu()

# =============================================================================
# クエリ
# =============================================================================

func is_active() -> bool:
	return _is_active


func get_activation_delay() -> float:
	return ACTIVATION_DELAY
