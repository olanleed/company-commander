class_name LeftPanel
extends PanelContainer

## 左パネル（OB: 部隊一覧）
## フィルタ: 未命令、抑圧高、補給不足、通信断

# =============================================================================
# シグナル
# =============================================================================

signal element_selected(element_id: String)

# =============================================================================
# UI要素
# =============================================================================

var _vbox: VBoxContainer
var _header: Label
var _filter_container: HBoxContainer
var _unit_list: VBoxContainer
var _scroll: ScrollContainer

# =============================================================================
# 状態
# =============================================================================

var _world_model: WorldModel
var _player_faction: GameEnums.Faction
var _highlighted_ids: Array[String] = []
var _current_filter: String = "all"

# =============================================================================
# 定数
# =============================================================================

const PANEL_WIDTH := 200
const HEADER_HEIGHT := 30
const ITEM_HEIGHT := 50

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func setup(world_model: WorldModel, player_faction: GameEnums.Faction) -> void:
	_world_model = world_model
	_player_faction = player_faction
	update_list()


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size.x = PANEL_WIDTH

	# メインコンテナ
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_vbox)

	# ヘッダー
	_header = Label.new()
	_header.text = "UNITS"
	_header.add_theme_font_size_override("font_size", 14)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.custom_minimum_size.y = HEADER_HEIGHT
	_vbox.add_child(_header)

	# フィルタボタン
	_filter_container = HBoxContainer.new()
	_filter_container.add_theme_constant_override("separation", 2)
	_vbox.add_child(_filter_container)

	_add_filter_button("All", "all")
	_add_filter_button("!", "no_order")
	_add_filter_button("S", "suppressed")
	_add_filter_button("A", "low_ammo")

	# スクロールコンテナ
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vbox.add_child(_scroll)

	# ユニットリスト
	_unit_list = VBoxContainer.new()
	_unit_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unit_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_unit_list)


func _add_filter_button(text: String, filter_id: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(40, 25)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_filter_pressed.bind(filter_id))
	_filter_container.add_child(btn)


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.85)
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# 更新
# =============================================================================

func update_list() -> void:
	if not _world_model or not _unit_list:
		return

	# 既存アイテムをクリア
	for child in _unit_list.get_children():
		child.queue_free()

	# ユニットを追加
	var elements := _world_model.get_elements_for_faction(_player_faction)
	for element in elements:
		if _passes_filter(element):
			var item := _create_unit_item(element)
			_unit_list.add_child(item)


func _passes_filter(element: ElementData.ElementInstance) -> bool:
	match _current_filter:
		"all":
			return true
		"no_order":
			return element.current_order_type == GameEnums.OrderType.NONE
		"suppressed":
			return element.suppression >= 0.5
		"low_ammo":
			return false  # TODO: 弾薬システム実装後
		_:
			return true


func _create_unit_item(element: ElementData.ElementInstance) -> Control:
	var item := PanelContainer.new()
	item.custom_minimum_size.y = ITEM_HEIGHT

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	item.add_theme_stylebox_override("panel", style)

	# ハイライト表示
	if element.id in _highlighted_ids:
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.4, 0.6, 1.0)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	item.add_child(hbox)

	# マージン
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	hbox.add_child(margin)

	var content := VBoxContainer.new()
	margin.add_child(content)

	# ユニット名
	var name_label := Label.new()
	name_label.text = element.element_type.display_name if element.element_type else element.id
	name_label.add_theme_font_size_override("font_size", 12)
	content.add_child(name_label)

	# ステータスバー
	var status_hbox := HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 4)
	content.add_child(status_hbox)

	# Strength
	var str_bar := _create_mini_bar(
		float(element.current_strength) / float(element.element_type.max_strength if element.element_type else 10),
		Color(0.2, 0.8, 0.2)
	)
	status_hbox.add_child(str_bar)

	# Suppression
	var sup_bar := _create_mini_bar(
		element.suppression,
		Color(0.8, 0.6, 0.2)
	)
	status_hbox.add_child(sup_bar)

	# クリックイベント
	item.gui_input.connect(_on_item_gui_input.bind(element.id))

	return item


func _create_mini_bar(value: float, color: Color) -> Control:
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(30, 6)
	bar.color = Color(0.2, 0.2, 0.2)

	var fill := ColorRect.new()
	fill.size = Vector2(30 * clampf(value, 0, 1), 6)
	fill.color = color
	bar.add_child(fill)

	return bar


func highlight_elements(elements: Array[ElementData.ElementInstance]) -> void:
	_highlighted_ids.clear()
	for element in elements:
		_highlighted_ids.append(element.id)
	update_list()

# =============================================================================
# イベントハンドラ
# =============================================================================

func _on_filter_pressed(filter_id: String) -> void:
	_current_filter = filter_id
	update_list()


func _on_item_gui_input(event: InputEvent, element_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			element_selected.emit(element_id)
			get_viewport().set_input_as_handled()  # InputControllerへの伝播を防ぐ
