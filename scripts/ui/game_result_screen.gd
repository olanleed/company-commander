class_name GameResultScreen
extends CanvasLayer

## ゲーム結果画面
## 勝利/敗北を表示し、Rキーでリスタート

# =============================================================================
# シグナル
# =============================================================================

signal restart_requested

# =============================================================================
# 状態
# =============================================================================

var _result_label: Label
var _reason_label: Label
var _stats_label: Label
var _restart_label: Label
var _background: ColorRect

var _is_visible: bool = false

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	layer = 100  # 最前面に表示
	_setup_ui()
	hide_screen()


func _setup_ui() -> void:
	# 半透明背景
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.8)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# 結果ラベル（VICTORY / DEFEAT）
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.set_anchors_preset(Control.PRESET_CENTER)
	_result_label.add_theme_font_size_override("font_size", 96)
	_result_label.position = Vector2(-200, -100)
	_result_label.size = Vector2(400, 120)
	add_child(_result_label)

	# 勝利理由
	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.set_anchors_preset(Control.PRESET_CENTER)
	_reason_label.add_theme_font_size_override("font_size", 32)
	_reason_label.position = Vector2(-200, 30)
	_reason_label.size = Vector2(400, 50)
	add_child(_reason_label)

	# 統計情報
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.set_anchors_preset(Control.PRESET_CENTER)
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.position = Vector2(-200, 90)
	_stats_label.size = Vector2(400, 80)
	add_child(_stats_label)

	# リスタート案内
	_restart_label = Label.new()
	_restart_label.text = "Press R to Restart"
	_restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restart_label.set_anchors_preset(Control.PRESET_CENTER)
	_restart_label.add_theme_font_size_override("font_size", 24)
	_restart_label.position = Vector2(-200, 180)
	_restart_label.size = Vector2(400, 40)
	_restart_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(_restart_label)


func _input(event: InputEvent) -> void:
	if not _is_visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			restart_requested.emit()

# =============================================================================
# 表示制御
# =============================================================================

func show_victory(reason: String, stats: Dictionary = {}) -> void:
	_result_label.text = "VICTORY"
	_result_label.modulate = Color(0.3, 1.0, 0.3)  # 緑
	_show_result(reason, stats)


func show_defeat(reason: String, stats: Dictionary = {}) -> void:
	_result_label.text = "DEFEAT"
	_result_label.modulate = Color(1.0, 0.3, 0.3)  # 赤
	_show_result(reason, stats)


func show_draw(reason: String, stats: Dictionary = {}) -> void:
	_result_label.text = "DRAW"
	_result_label.modulate = Color(0.7, 0.7, 0.7)  # グレー
	_show_result(reason, stats)


func _show_result(reason: String, stats: Dictionary) -> void:
	_reason_label.text = reason

	# 統計情報を表示
	var stats_text := ""
	if stats.has("blue_points"):
		stats_text += "BLUE Points: %d\n" % stats.blue_points
	if stats.has("red_points"):
		stats_text += "RED Points: %d\n" % stats.red_points
	if stats.has("match_time"):
		var minutes := int(stats.match_time) / 60
		var seconds := int(stats.match_time) % 60
		stats_text += "Match Time: %02d:%02d" % [minutes, seconds]

	_stats_label.text = stats_text

	_is_visible = true
	visible = true


func hide_screen() -> void:
	_is_visible = false
	visible = false
