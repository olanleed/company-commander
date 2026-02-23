class_name PieMenu
extends Control

## 放射状コマンドメニュー（Pie Menu / Marking Menu）
## 右クリック長押しで表示、8方向でコマンド選択
## 仕様: docs/pie_menu_commands_v0.2.md

# =============================================================================
# 定数
# =============================================================================

const INNER_RADIUS := 40.0
const OUTER_RADIUS := 120.0
const ACTIVATION_DELAY := 0.2  # 右クリック長押し判定（秒）
const DEADZONE_RADIUS := 30.0  # 中心のデッドゾーン

## 8方向コマンド配置（仕様書 v0.2.2 準拠）
## 角度: 270=N(↑), 315=NE(↗), 0=E(→), 45=SE(↘), 90=S(↓), 135=SW(↙), 180=W(←), 225=NW(↖)
##
## 共通コマンド（全ユニット）:
## - N(↑): Move - 移動して停止
## - E(→): Attack - 指定目標を攻撃
## - S(↓): Stop - 即座に停止
## - NW(↖): Break Contact - 戦闘離脱
##
## 空きスロット（ユニット固有コマンド用）:
## - NE(↗), SE(↘), SW(↙), W(←)

const DEFAULT_COMMANDS := [
	{"name": "Move", "type": GameEnums.OrderType.MOVE, "angle": 270, "color": Color(0.3, 0.6, 0.9), "enabled": true},
	{"name": "---", "type": GameEnums.OrderType.NONE, "angle": 315, "color": Color(0.4, 0.4, 0.4), "enabled": false},  # NE: 空き
	{"name": "Attack", "type": GameEnums.OrderType.ATTACK, "angle": 0, "color": Color(0.9, 0.3, 0.3), "enabled": true},
	{"name": "---", "type": GameEnums.OrderType.NONE, "angle": 45, "color": Color(0.4, 0.4, 0.4), "enabled": false},   # SE: 空き
	{"name": "Stop", "type": GameEnums.OrderType.HOLD, "angle": 90, "color": Color(0.5, 0.5, 0.6), "enabled": true},
	{"name": "Reverse", "type": GameEnums.OrderType.RETREAT, "angle": 135, "color": Color(0.6, 0.5, 0.4), "enabled": false},  # SW: Reverse（戦車/IFV用）
	{"name": "Smoke", "type": GameEnums.OrderType.SMOKE, "angle": 180, "color": Color(0.6, 0.6, 0.7), "enabled": false},  # W: Smoke（装備時のみ）
	{"name": "Break", "type": GameEnums.OrderType.BREAK_CONTACT, "angle": 225, "color": Color(0.7, 0.4, 0.4), "enabled": true},
]

## ユニットカテゴリ別コマンド設定
const CATEGORY_COMMANDS := {
	"TANK": {
		315: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # NE: 空き（将来: Fire Position）
		45: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},   # SE: 空き
		135: {"name": "Reverse", "type": GameEnums.OrderType.RETREAT, "enabled": true},  # SW: Reverse
		180: {"name": "Smoke", "type": GameEnums.OrderType.SMOKE, "enabled": true},  # W: Smoke
	},
	"IFV": {
		315: {"name": "Unload", "type": GameEnums.OrderType.UNLOAD, "enabled": true},  # NE: Unload
		45: {"name": "Load", "type": GameEnums.OrderType.LOAD, "enabled": true},   # SE: Load
		135: {"name": "Reverse", "type": GameEnums.OrderType.RETREAT, "enabled": true},  # SW: Reverse
		180: {"name": "Smoke", "type": GameEnums.OrderType.SMOKE, "enabled": true},  # W: Smoke
	},
	"ARTILLERY": {
		315: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # NE: 空き（将来: Deploy）
		45: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},   # SE: 空き（将来: Cease Fire）
		135: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # SW: 空き
		180: {"name": "Fire HE", "type": GameEnums.OrderType.FIRE_MISSION, "enabled": true},  # W: Fire Mission
		0: {"name": "Fire HE", "type": GameEnums.OrderType.FIRE_MISSION, "enabled": true},  # E: Fire Mission（Attackの代わり）
	},
	"INFANTRY": {
		315: {"name": "Fast", "type": GameEnums.OrderType.MOVE_FAST, "enabled": true},  # NE: Fast Move
		45: {"name": "Ambush", "type": GameEnums.OrderType.AMBUSH, "enabled": true},   # SE: Ambush
		135: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # SW: 空き（将来: Dig In）
		180: {"name": "Board", "type": GameEnums.OrderType.LOAD, "enabled": true},  # W: Board（乗車）
	},
	"RECON": {
		315: {"name": "Recon", "type": GameEnums.OrderType.RECON, "enabled": true},  # NE: Recon Move
		45: {"name": "Observe", "type": GameEnums.OrderType.OBSERVE, "enabled": true},   # SE: Observe
		135: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # SW: 空き（将来: Hide）
		180: {"name": "Smoke", "type": GameEnums.OrderType.SMOKE, "enabled": false},  # W: Smoke（装備時のみ）
	},
	"SUPPORT": {
		315: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # NE: 空き（将来: Follow）
		45: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},   # SE: 空き
		135: {"name": "---", "type": GameEnums.OrderType.NONE, "enabled": false},  # SW: 空き
		180: {"name": "Resupply", "type": GameEnums.OrderType.SUPPORT, "enabled": true},  # W: Resupply
	},
}

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
var _current_commands: Array = []  # 現在表示中のコマンド
var _current_category: String = ""  # 現在のユニットカテゴリ


# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	# 全画面オーバーレイ
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 非表示時はマウスイベントを通過させる
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# デフォルトコマンドで初期化
	_current_commands = DEFAULT_COMMANDS.duplicate(true)


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
	var segment_angle := TAU / _current_commands.size()

	for i in range(_current_commands.size()):
		var cmd: Dictionary = _current_commands[i]
		var start_angle: float = deg_to_rad(cmd.angle) - segment_angle / 2
		var end_angle: float = start_angle + segment_angle

		var is_hovered := i == _hovered_index
		var is_enabled: bool = cmd.get("enabled", true)
		var color: Color = cmd.color

		if not is_enabled:
			# 無効なコマンドはグレーアウト
			color = Color(0.3, 0.3, 0.35, 0.5)
		elif is_hovered:
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
		var border_color := Color.WHITE if is_hovered and is_enabled else Color(0.4, 0.4, 0.5)
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

	for i in range(_current_commands.size()):
		var cmd: Dictionary = _current_commands[i]
		var angle: float = deg_to_rad(cmd.angle)
		var label_radius: float = (INNER_RADIUS + OUTER_RADIUS) / 2
		var label_pos := _center_pos + Vector2(cos(angle), sin(angle)) * label_radius

		var is_hovered := i == _hovered_index
		var is_enabled: bool = cmd.get("enabled", true)
		var color := Color.WHITE if is_hovered and is_enabled else Color(0.85, 0.85, 0.85)

		if not is_enabled:
			color = Color(0.5, 0.5, 0.5, 0.7)

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
	var segment_angle := TAU / _current_commands.size()

	for i in range(_current_commands.size()):
		var cmd: Dictionary = _current_commands[i]
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
	if _hovered_index >= 0 and _hovered_index < _current_commands.size():
		var cmd: Dictionary = _current_commands[_hovered_index]
		var is_enabled: bool = cmd.get("enabled", true)

		if is_enabled and cmd.type != GameEnums.OrderType.NONE:
			_selected_command = cmd.type
			command_selected.emit(_selected_command, _world_pos)
		else:
			# 無効なコマンドはキャンセル扱い
			menu_cancelled.emit()
	else:
		menu_cancelled.emit()

	hide_menu()

# =============================================================================
# メニュー表示/非表示
# =============================================================================

## メニューを表示（カテゴリ指定なし：デフォルトコマンド）
func show_menu(screen_pos: Vector2, world_pos: Vector2) -> void:
	show_menu_for_category(screen_pos, world_pos, "")


## メニューを表示（カテゴリ指定あり）
func show_menu_for_category(screen_pos: Vector2, world_pos: Vector2, category: String) -> void:
	_center_pos = screen_pos
	_world_pos = world_pos
	_hovered_index = -1
	_current_category = category

	# カテゴリに応じたコマンドを設定
	_setup_commands_for_category(category)

	_is_active = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP  # 表示時はイベントをキャプチャ
	queue_redraw()


## カテゴリに応じたコマンドを設定
func _setup_commands_for_category(category: String) -> void:
	# デフォルトコマンドをコピー
	_current_commands = DEFAULT_COMMANDS.duplicate(true)

	# カテゴリ固有のコマンドで上書き
	if category != "" and CATEGORY_COMMANDS.has(category):
		var category_overrides: Dictionary = CATEGORY_COMMANDS[category]

		for i in range(_current_commands.size()):
			var cmd: Dictionary = _current_commands[i]
			var angle: int = int(cmd.angle)

			if category_overrides.has(angle):
				var override: Dictionary = category_overrides[angle]
				cmd.name = override.name
				cmd.type = override.type
				cmd.enabled = override.enabled
				# 色はデフォルトのまま維持（または上書き）
				if override.has("color"):
					cmd.color = override.color


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


func get_current_category() -> String:
	return _current_category


## アーキタイプからカテゴリを取得
static func get_category_for_archetype(archetype: String) -> String:
	match archetype:
		"TANK_PLT", "LIGHT_TANK":
			return "TANK"
		"IFV_PLT", "APC_PLT":
			return "IFV"
		"SP_ARTILLERY", "SP_MORTAR", "MLRS":
			return "ARTILLERY"
		"INF_LINE", "INF_AT", "INF_MG":
			return "INFANTRY"
		"RECON_VEH", "RECON_TEAM":
			return "RECON"
		"SPAAG", "SAM_VEH":
			return "AIR_DEFENSE"
		"LOG_TRUCK", "COMMAND_VEH", "MEDICAL_VEH":
			return "SUPPORT"
		_:
			return ""
