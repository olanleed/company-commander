class_name AlertLog
extends PanelContainer

## アラートログ
## 戦闘イベント、発見、損耗などの通知をスクロールリストで表示

# =============================================================================
# 定数
# =============================================================================

const MAX_ALERTS := 50
const ALERT_DISPLAY_TIME := 5.0  # 秒
const PANEL_HEIGHT := 120
const PANEL_WIDTH := 300

## アラート重要度
enum AlertPriority {
	LOW,       # 情報
	MEDIUM,    # 注意
	HIGH,      # 警告
	CRITICAL   # 緊急
}

## アラート種類
enum AlertType {
	CONTACT_NEW,       # 新規接触
	CONTACT_LOST,      # 接触喪失
	UNDER_FIRE,        # 被射撃
	CASUALTY,          # 損耗発生
	CP_CAPTURED,       # 拠点制圧
	CP_LOST,           # 拠点喪失
	ORDER_COMPLETE,    # 命令完了
	LOW_AMMO,          # 弾薬不足
	SUPPRESSED,        # 制圧状態
	UNIT_DESTROYED     # 部隊壊滅
}

# =============================================================================
# シグナル
# =============================================================================

signal alert_clicked(alert_data: Dictionary)

# =============================================================================
# UI要素
# =============================================================================

var _scroll_container: ScrollContainer
var _alert_container: VBoxContainer
var _alerts: Array[Dictionary] = []

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	# スクロールコンテナ
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	# アラートコンテナ
	_alert_container = VBoxContainer.new()
	_alert_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alert_container.add_theme_constant_override("separation", 2)
	_scroll_container.add_child(_alert_container)


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.25, 0.35)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

# =============================================================================
# アラート追加
# =============================================================================

## 新しいアラートを追加
func add_alert(
	alert_type: AlertType,
	message: String,
	priority: AlertPriority = AlertPriority.MEDIUM,
	element_id: String = "",
	position: Vector2 = Vector2.ZERO
) -> void:
	var alert_data := {
		"type": alert_type,
		"message": message,
		"priority": priority,
		"element_id": element_id,
		"position": position,
		"timestamp": Time.get_ticks_msec() / 1000.0
	}

	_alerts.push_front(alert_data)

	# 最大数を超えたら古いものを削除
	while _alerts.size() > MAX_ALERTS:
		_alerts.pop_back()

	# UI更新
	_add_alert_ui(alert_data)

	# 一番上にスクロール
	await get_tree().process_frame
	_scroll_container.scroll_vertical = 0


func _add_alert_ui(alert_data: Dictionary) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _get_priority_bg_color(alert_data.priority)
	style.border_width_left = 3
	style.border_color = _get_priority_color(alert_data.priority)
	style.corner_radius_top_left = 2
	style.corner_radius_bottom_left = 2
	style.content_margin_left = 6
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	panel.add_child(hbox)

	# アイコン
	var icon := Label.new()
	icon.text = _get_alert_icon(alert_data.type)
	icon.add_theme_font_size_override("font_size", 12)
	hbox.add_child(icon)

	# メッセージ
	var label := Label.new()
	label.text = alert_data.message
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", _get_priority_color(alert_data.priority))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(label)

	# クリック処理
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
				alert_clicked.emit(alert_data)
	)

	# 先頭に追加
	_alert_container.add_child(panel)
	_alert_container.move_child(panel, 0)

	# 古いUI要素を削除
	while _alert_container.get_child_count() > MAX_ALERTS:
		var old_child := _alert_container.get_child(_alert_container.get_child_count() - 1)
		old_child.queue_free()


func _get_priority_color(priority: AlertPriority) -> Color:
	match priority:
		AlertPriority.LOW:
			return Color(0.6, 0.6, 0.7)
		AlertPriority.MEDIUM:
			return Color(0.9, 0.8, 0.3)
		AlertPriority.HIGH:
			return Color(0.9, 0.5, 0.2)
		AlertPriority.CRITICAL:
			return Color(1.0, 0.3, 0.3)
		_:
			return Color.WHITE


func _get_priority_bg_color(priority: AlertPriority) -> Color:
	match priority:
		AlertPriority.LOW:
			return Color(0.15, 0.15, 0.2, 0.9)
		AlertPriority.MEDIUM:
			return Color(0.2, 0.18, 0.1, 0.9)
		AlertPriority.HIGH:
			return Color(0.25, 0.15, 0.1, 0.9)
		AlertPriority.CRITICAL:
			return Color(0.3, 0.1, 0.1, 0.9)
		_:
			return Color(0.15, 0.15, 0.15, 0.9)


func _get_alert_icon(alert_type: AlertType) -> String:
	match alert_type:
		AlertType.CONTACT_NEW:
			return "!"
		AlertType.CONTACT_LOST:
			return "?"
		AlertType.UNDER_FIRE:
			return "*"
		AlertType.CASUALTY:
			return "X"
		AlertType.CP_CAPTURED:
			return "+"
		AlertType.CP_LOST:
			return "-"
		AlertType.ORDER_COMPLETE:
			return ">"
		AlertType.LOW_AMMO:
			return "A"
		AlertType.SUPPRESSED:
			return "S"
		AlertType.UNIT_DESTROYED:
			return "#"
		_:
			return "i"

# =============================================================================
# イベントバス連携
# =============================================================================

## CombatEventBusからのイベントを処理
func handle_combat_event(event: CombatEventBus.CombatEvent) -> void:
	var message := ""
	var priority := AlertPriority.MEDIUM
	var alert_type := AlertType.CONTACT_NEW

	match event.type:
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED:
			alert_type = AlertType.CONTACT_NEW
			message = "敵発見: %s" % event.data.get("target_id", "不明")
			priority = AlertPriority.HIGH

		GameEnums.CombatEventType.EV_CONTACT_LOST:
			alert_type = AlertType.CONTACT_LOST
			message = "接触喪失: %s" % event.data.get("target_id", "不明")
			priority = AlertPriority.LOW

		GameEnums.CombatEventType.EV_UNDER_FIRE:
			alert_type = AlertType.UNDER_FIRE
			message = "%s が被射撃" % event.data.get("element_id", "部隊")
			priority = AlertPriority.HIGH

		GameEnums.CombatEventType.EV_CASUALTY_TAKEN:
			alert_type = AlertType.CASUALTY
			message = "%s に損耗発生" % event.data.get("element_id", "部隊")
			priority = AlertPriority.CRITICAL

		GameEnums.CombatEventType.EV_CP_CAPTURED:
			alert_type = AlertType.CP_CAPTURED
			message = "拠点制圧: %s" % event.data.get("cp_id", "")
			priority = AlertPriority.HIGH

		GameEnums.CombatEventType.EV_CP_LOST:
			alert_type = AlertType.CP_LOST
			message = "拠点喪失: %s" % event.data.get("cp_id", "")
			priority = AlertPriority.CRITICAL

		_:
			return  # 他のイベントは無視

	add_alert(
		alert_type,
		message,
		priority,
		event.data.get("element_id", ""),
		event.data.get("position", Vector2.ZERO)
	)

# =============================================================================
# クリア
# =============================================================================

func clear_alerts() -> void:
	_alerts.clear()
	for child in _alert_container.get_children():
		child.queue_free()
