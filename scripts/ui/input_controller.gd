class_name InputController
extends Node

## 入力コントローラ
## マウス操作、ホットキー、修飾キーを統合管理
## 仕様: docs/ui_input_v0.1.md

# =============================================================================
# 定数
# =============================================================================

## 右クリック長押し判定時間（秒）
const PIE_MENU_DELAY := 0.2

## ダブルクリック判定時間（秒）
const DOUBLE_CLICK_TIME := 0.3

## ホットキーマッピング
const HOTKEYS := {
	KEY_Q: GameEnums.OrderType.MOVE,
	KEY_W: GameEnums.OrderType.DEFEND,
	KEY_E: GameEnums.OrderType.ATTACK,
	KEY_R: GameEnums.OrderType.RECON,
	KEY_A: GameEnums.OrderType.SUPPRESS,
	KEY_D: GameEnums.OrderType.SMOKE,
	KEY_F: GameEnums.OrderType.SUPPORT,
	KEY_X: GameEnums.OrderType.BREAK_CONTACT,
}

## ゲームスピードホットキー
const SPEED_KEYS := {
	KEY_1: 0,   # 一時停止
	KEY_2: 1,   # 1x
	KEY_3: 2,   # 2x
	KEY_4: 4,   # 4x
}

# =============================================================================
# シグナル
# =============================================================================

## 選択
signal left_click(world_pos: Vector2, screen_pos: Vector2)
signal left_double_click(world_pos: Vector2, screen_pos: Vector2)
signal box_selection_started(screen_pos: Vector2)
signal box_selection_ended(start_pos: Vector2, end_pos: Vector2)

## コマンド
signal right_click(world_pos: Vector2, screen_pos: Vector2)  # スマートコマンド
signal pie_menu_requested(screen_pos: Vector2, world_pos: Vector2)
signal command_hotkey_pressed(command_type: GameEnums.OrderType)

## モディファイア
signal modifier_changed(shift: bool, ctrl: bool, alt: bool)

## ゲーム操作
signal speed_change_requested(speed: int)
signal camera_center_requested()  # Spaceで選択ユニットにカメラを向ける
signal escape_pressed()

# =============================================================================
# 状態
# =============================================================================

var _is_right_pressed := false
var _right_press_time := 0.0
var _right_press_screen_pos := Vector2.ZERO
var _right_press_world_pos := Vector2.ZERO

var _is_left_pressed := false
var _left_press_time := 0.0
var _left_press_screen_pos := Vector2.ZERO
var _last_left_click_time := 0.0

var _is_box_selecting := false
var _box_start_pos := Vector2.ZERO

var _is_shift_held := false
var _is_ctrl_held := false
var _is_alt_held := false

var _pending_command: GameEnums.OrderType = GameEnums.OrderType.NONE
var _pie_menu_shown := false

# =============================================================================
# 依存
# =============================================================================

var _camera: Camera2D
var _pie_menu: PieMenu
var _hud_manager: Control  # HUDManager参照（UI領域判定用）

# =============================================================================
# 初期化
# =============================================================================

func setup(camera: Camera2D, pie_menu: PieMenu = null, hud_manager: Control = null) -> void:
	_camera = camera
	_pie_menu = pie_menu
	_hud_manager = hud_manager

	if _pie_menu:
		_pie_menu.command_selected.connect(_on_pie_menu_command_selected)
		_pie_menu.menu_cancelled.connect(_on_pie_menu_cancelled)


func _process(delta: float) -> void:
	# 右クリック長押し検出
	if _is_right_pressed and not _pie_menu_shown:
		_right_press_time += delta
		if _right_press_time >= PIE_MENU_DELAY:
			_show_pie_menu()

# =============================================================================
# 入力処理
# =============================================================================

func _input(event: InputEvent) -> void:
	# Pie Menuがアクティブまたは表示中なら、その入力を優先
	if _pie_menu_shown or (_pie_menu and _pie_menu.is_active()):
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		# UI上のクリックは無視（UIが処理する）
		if _is_mouse_over_ui(mouse_event.position):
			return
		_handle_mouse_button(mouse_event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var world_pos := _screen_to_world(event.position)

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_left_press(event.position, world_pos)
			else:
				_on_left_release(event.position, world_pos)

		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_on_right_press(event.position, world_pos)
			else:
				_on_right_release(event.position, world_pos)

		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			# カメラズームは別途処理
			pass


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	# ボックス選択中のドラッグ
	if _is_box_selecting:
		# UI側で描画を更新するためのシグナルは不要
		# box_selection_endedで最終的な範囲を渡す
		pass


func _handle_key(event: InputEventKey) -> void:
	# モディファイアキーの状態を追跡
	var old_shift := _is_shift_held
	var old_ctrl := _is_ctrl_held
	var old_alt := _is_alt_held

	_is_shift_held = event.shift_pressed
	_is_ctrl_held = event.ctrl_pressed
	_is_alt_held = event.alt_pressed

	if old_shift != _is_shift_held or old_ctrl != _is_ctrl_held or old_alt != _is_alt_held:
		modifier_changed.emit(_is_shift_held, _is_ctrl_held, _is_alt_held)

	if not event.pressed:
		return

	# Escapeキー
	if event.keycode == KEY_ESCAPE:
		escape_pressed.emit()
		return

	# Spaceキー（カメラセンタリング）
	if event.keycode == KEY_SPACE:
		camera_center_requested.emit()
		return

	# コマンドホットキー
	if event.keycode in HOTKEYS:
		var cmd_type: GameEnums.OrderType = HOTKEYS[event.keycode]
		_pending_command = cmd_type
		command_hotkey_pressed.emit(cmd_type)
		return

	# スピードホットキー
	if event.keycode in SPEED_KEYS:
		var speed: int = SPEED_KEYS[event.keycode]
		speed_change_requested.emit(speed)
		return

# =============================================================================
# マウスイベント処理
# =============================================================================

func _on_left_press(screen_pos: Vector2, world_pos: Vector2) -> void:
	_is_left_pressed = true
	_left_press_screen_pos = screen_pos
	_left_press_time = Time.get_ticks_msec() / 1000.0

	# ダブルクリック判定
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_left_click_time < DOUBLE_CLICK_TIME:
		left_double_click.emit(world_pos, screen_pos)
		_last_left_click_time = 0.0
		return

	# ボックス選択開始
	_is_box_selecting = true
	_box_start_pos = screen_pos
	box_selection_started.emit(screen_pos)


func _on_left_release(screen_pos: Vector2, world_pos: Vector2) -> void:
	_is_left_pressed = false

	if _is_box_selecting:
		_is_box_selecting = false

		# 小さいドラッグならシングルクリック扱い
		var drag_dist := screen_pos.distance_to(_box_start_pos)
		if drag_dist < 5:
			left_click.emit(world_pos, screen_pos)
			_last_left_click_time = Time.get_ticks_msec() / 1000.0
		else:
			box_selection_ended.emit(_box_start_pos, screen_pos)


func _on_right_press(screen_pos: Vector2, world_pos: Vector2) -> void:
	_is_right_pressed = true
	_right_press_time = 0.0
	_right_press_screen_pos = screen_pos
	_right_press_world_pos = world_pos


func _on_right_release(screen_pos: Vector2, world_pos: Vector2) -> void:
	if not _is_right_pressed:
		return

	_is_right_pressed = false

	# Pie Menuが表示されていれば、選択処理はPieMenuで行う
	# フラグはPieMenuのシグナルコールバックでリセットされる
	if _pie_menu_shown:
		return

	# 短いクリックならスマートコマンド
	if _right_press_time < PIE_MENU_DELAY:
		right_click.emit(world_pos, screen_pos)


func _show_pie_menu() -> void:
	if not _pie_menu:
		return

	_pie_menu_shown = true
	_right_press_time = 0.0  # タイマーをリセットして再表示を防ぐ
	_pie_menu.show_menu(_right_press_screen_pos, _right_press_world_pos)
	pie_menu_requested.emit(_right_press_screen_pos, _right_press_world_pos)

# =============================================================================
# Pie Menuコールバック
# =============================================================================

func _on_pie_menu_command_selected(command_type: GameEnums.OrderType, _world_pos: Vector2) -> void:
	_pie_menu_shown = false
	_is_right_pressed = false  # PieMenuが閉じたら右クリック状態もリセット
	_pending_command = command_type
	# 外部でこのシグナルを処理


func _on_pie_menu_cancelled() -> void:
	_pie_menu_shown = false
	_is_right_pressed = false  # PieMenuが閉じたら右クリック状態もリセット

# =============================================================================
# ヘルパー
# =============================================================================

func _is_mouse_over_ui(screen_pos: Vector2) -> bool:
	if not _hud_manager:
		return false

	# HUDManagerの子コントロールをチェック
	for child in _hud_manager.get_children():
		if child is Control and child.visible:
			var control := child as Control
			# PieMenuは別途処理するのでスキップ
			if control is PieMenu:
				continue
			# コントロールの矩形内にマウスがあるかチェック
			var rect := control.get_global_rect()
			if rect.has_point(screen_pos):
				return true

	return false


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if not _camera:
		return screen_pos

	# カメラの変換を考慮してスクリーン座標をワールド座標に変換
	var viewport := _camera.get_viewport()
	if not viewport:
		return screen_pos

	var canvas_transform := viewport.get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos

# =============================================================================
# クエリ
# =============================================================================

## 現在のモディファイア状態を取得
func get_modifiers() -> Dictionary:
	return {
		"shift": _is_shift_held,
		"ctrl": _is_ctrl_held,
		"alt": _is_alt_held
	}


## Shiftが押されているか（キュー追加）
func is_shift_held() -> bool:
	return _is_shift_held


## Ctrlが押されているか（強制実行）
func is_ctrl_held() -> bool:
	return _is_ctrl_held


## Altが押されているか（道路優先）
func is_alt_held() -> bool:
	return _is_alt_held


## ペンディングコマンドを取得してクリア
func consume_pending_command() -> GameEnums.OrderType:
	var cmd := _pending_command
	_pending_command = GameEnums.OrderType.NONE
	return cmd


## ボックス選択中か
func is_box_selecting() -> bool:
	return _is_box_selecting


## 現在のボックス選択範囲を取得
func get_box_selection_rect() -> Rect2:
	if not _is_box_selecting:
		return Rect2()

	var current_pos := get_viewport().get_mouse_position()
	var min_pos := Vector2(
		min(_box_start_pos.x, current_pos.x),
		min(_box_start_pos.y, current_pos.y)
	)
	var max_pos := Vector2(
		max(_box_start_pos.x, current_pos.x),
		max(_box_start_pos.y, current_pos.y)
	)
	return Rect2(min_pos, max_pos - min_pos)
