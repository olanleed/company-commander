class_name BottomBar
extends PanelContainer

## 下部コマンドバー
## 8コマンド + ホットキー表示

# =============================================================================
# シグナル
# =============================================================================

signal command_pressed(command_type: GameEnums.OrderType)

# =============================================================================
# UI要素
# =============================================================================

var _hbox: HBoxContainer
var _command_buttons: Array[Button] = []

# =============================================================================
# コマンド定義
# =============================================================================

const COMMANDS := [
	{"name": "Move", "key": "Q", "type": GameEnums.OrderType.MOVE, "color": Color(0.3, 0.6, 0.9)},
	{"name": "Defend", "key": "W", "type": GameEnums.OrderType.DEFEND, "color": Color(0.3, 0.8, 0.3)},
	{"name": "Attack", "key": "E", "type": GameEnums.OrderType.ATTACK, "color": Color(0.9, 0.3, 0.3)},
	{"name": "Recon", "key": "R", "type": GameEnums.OrderType.RECON, "color": Color(0.7, 0.7, 0.3)},
	{"name": "Suppress", "key": "A", "type": GameEnums.OrderType.ATTACK, "color": Color(0.9, 0.5, 0.2)},
	{"name": "Smoke", "key": "D", "type": GameEnums.OrderType.NONE, "color": Color(0.6, 0.6, 0.6)},
	{"name": "Support", "key": "F", "type": GameEnums.OrderType.NONE, "color": Color(0.8, 0.4, 0.8)},
	{"name": "Break", "key": "X", "type": GameEnums.OrderType.NONE, "color": Color(0.5, 0.3, 0.3)},
]

# =============================================================================
# 定数
# =============================================================================

const BAR_HEIGHT := 80
const BUTTON_SIZE := Vector2(80, 60)

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func setup() -> void:
	pass


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size.y = BAR_HEIGHT

	# 中央揃えコンテナ
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# 横並びコンテナ
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 8)
	center.add_child(_hbox)

	# コマンドボタンを作成
	for cmd in COMMANDS:
		var btn := _create_command_button(cmd)
		_hbox.add_child(btn)
		_command_buttons.append(btn)


func _create_command_button(cmd: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = BUTTON_SIZE

	# ボタンスタイル
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.17, 0.2)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.border_width_bottom = 3
	normal_style.border_color = cmd["color"]
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.2, 0.22, 0.25)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.25, 0.27, 0.3)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# ボタン内容（VBoxで名前とホットキーを表示）
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)

	var name_label := Label.new()
	name_label.text = cmd["name"]
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var key_label := Label.new()
	key_label.text = "[%s]" % cmd["key"]
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(key_label)

	# クリックイベント
	btn.pressed.connect(_on_button_pressed.bind(cmd["type"]))

	return btn


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_top = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# イベントハンドラ
# =============================================================================

func _on_button_pressed(command_type: GameEnums.OrderType) -> void:
	command_pressed.emit(command_type)

# =============================================================================
# ホットキー処理
# =============================================================================

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		var keycode := key_event.keycode

		match keycode:
			KEY_Q:
				command_pressed.emit(GameEnums.OrderType.MOVE)
				get_viewport().set_input_as_handled()
			KEY_W:
				command_pressed.emit(GameEnums.OrderType.DEFEND)
				get_viewport().set_input_as_handled()
			KEY_E:
				command_pressed.emit(GameEnums.OrderType.ATTACK)
				get_viewport().set_input_as_handled()
			KEY_R:
				command_pressed.emit(GameEnums.OrderType.RECON)
				get_viewport().set_input_as_handled()
