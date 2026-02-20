class_name RightPanel
extends PanelContainer

## 右パネル（選択詳細）
## Strength、Suppression、Order、SOPを表示

# =============================================================================
# UI要素
# =============================================================================

var _vbox: VBoxContainer
var _header: Label
var _unit_name: Label
var _strength_bar: ProgressBar
var _strength_label: Label
var _suppression_bar: ProgressBar
var _suppression_label: Label
var _order_label: Label
var _state_label: Label
var _position_label: Label

# =============================================================================
# 状態
# =============================================================================

var _world_model: WorldModel
var _selected_elements: Array[ElementData.ElementInstance] = []

# =============================================================================
# 定数
# =============================================================================

const PANEL_WIDTH := 220
const HEADER_HEIGHT := 30

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func setup(world_model: WorldModel) -> void:
	_world_model = world_model


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size.x = PANEL_WIDTH

	# メインコンテナ
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(_vbox)

	# ヘッダー
	_header = Label.new()
	_header.text = "SELECTED UNIT"
	_header.add_theme_font_size_override("font_size", 14)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_header)

	# ユニット名
	_unit_name = Label.new()
	_unit_name.text = "---"
	_unit_name.add_theme_font_size_override("font_size", 16)
	_unit_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_unit_name)

	# セパレータ
	var sep1 := HSeparator.new()
	_vbox.add_child(sep1)

	# Strength
	var str_section := _create_stat_section("STRENGTH", Color(0.2, 0.8, 0.2))
	_strength_bar = str_section.get_node("Bar") as ProgressBar
	_strength_label = str_section.get_node("Label") as Label
	_vbox.add_child(str_section)

	# Suppression
	var sup_section := _create_stat_section("SUPPRESSION", Color(0.8, 0.6, 0.2))
	_suppression_bar = sup_section.get_node("Bar") as ProgressBar
	_suppression_label = sup_section.get_node("Label") as Label
	_vbox.add_child(sup_section)

	# セパレータ
	var sep2 := HSeparator.new()
	_vbox.add_child(sep2)

	# Order
	var order_section := VBoxContainer.new()
	var order_header := Label.new()
	order_header.text = "CURRENT ORDER"
	order_header.add_theme_font_size_override("font_size", 10)
	order_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	order_section.add_child(order_header)

	_order_label = Label.new()
	_order_label.text = "NONE"
	_order_label.add_theme_font_size_override("font_size", 14)
	order_section.add_child(_order_label)
	_vbox.add_child(order_section)

	# State
	var state_section := VBoxContainer.new()
	var state_header := Label.new()
	state_header.text = "STATE"
	state_header.add_theme_font_size_override("font_size", 10)
	state_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	state_section.add_child(state_header)

	_state_label = Label.new()
	_state_label.text = "ACTIVE"
	_state_label.add_theme_font_size_override("font_size", 14)
	state_section.add_child(_state_label)
	_vbox.add_child(state_section)

	# Position
	var pos_section := VBoxContainer.new()
	var pos_header := Label.new()
	pos_header.text = "POSITION"
	pos_header.add_theme_font_size_override("font_size", 10)
	pos_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	pos_section.add_child(pos_header)

	_position_label = Label.new()
	_position_label.text = "---"
	_position_label.add_theme_font_size_override("font_size", 12)
	pos_section.add_child(_position_label)
	_vbox.add_child(pos_section)


func _create_stat_section(header_text: String, bar_color: Color) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	section.add_child(header)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size.y = 20
	bar.value = 100
	bar.show_percentage = false

	# スタイル設定
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)

	section.add_child(bar)

	var label := Label.new()
	label.name = "Label"
	label.text = "100%"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 12)
	section.add_child(label)

	return section


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.85)
	style.border_width_left = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# 更新
# =============================================================================

func set_elements(elements: Array[ElementData.ElementInstance]) -> void:
	_selected_elements = elements
	_update_display()


func update_display(elements: Array[ElementData.ElementInstance], _company_ai = null) -> void:
	_selected_elements = elements
	_update_display()


func _update_display() -> void:
	if _selected_elements.size() == 0:
		_show_empty()
		return

	if _selected_elements.size() == 1:
		_show_single(_selected_elements[0])
	else:
		_show_multiple()


func _show_empty() -> void:
	_unit_name.text = "---"
	_strength_bar.value = 0
	_strength_label.text = "---"
	_suppression_bar.value = 0
	_suppression_label.text = "---"
	_order_label.text = "NONE"
	_state_label.text = "---"
	_position_label.text = "---"


func _show_single(element: ElementData.ElementInstance) -> void:
	# ユニット名
	_unit_name.text = element.element_type.display_name if element.element_type else element.id

	# Strength
	var max_str := element.element_type.max_strength if element.element_type else 10
	var str_pct := float(element.current_strength) / float(max_str) * 100.0
	_strength_bar.value = str_pct
	_strength_label.text = "%d/%d (%d%%)" % [element.current_strength, max_str, int(str_pct)]

	# Suppression
	var sup_pct := element.suppression * 100.0
	_suppression_bar.value = sup_pct
	_suppression_label.text = "%d%%" % int(sup_pct)

	# Order
	_order_label.text = _get_order_name(element.current_order_type)

	# State
	_state_label.text = _get_state_name(element.state)

	# Position
	_position_label.text = "(%d, %d)" % [int(element.position.x), int(element.position.y)]


func _show_multiple() -> void:
	_unit_name.text = "%d UNITS SELECTED" % _selected_elements.size()

	# 平均値を計算
	var total_str := 0.0
	var total_max_str := 0.0
	var total_sup := 0.0

	for element in _selected_elements:
		var max_str := element.element_type.max_strength if element.element_type else 10
		total_str += element.current_strength
		total_max_str += max_str
		total_sup += element.suppression

	var avg_str_pct := total_str / total_max_str * 100.0 if total_max_str > 0 else 0.0
	var avg_sup := total_sup / _selected_elements.size() * 100.0

	_strength_bar.value = avg_str_pct
	_strength_label.text = "AVG: %d%%" % int(avg_str_pct)

	_suppression_bar.value = avg_sup
	_suppression_label.text = "AVG: %d%%" % int(avg_sup)

	_order_label.text = "MULTIPLE"
	_state_label.text = "---"
	_position_label.text = "---"


func _get_order_name(order_type: GameEnums.OrderType) -> String:
	match order_type:
		GameEnums.OrderType.NONE:
			return "NONE"
		GameEnums.OrderType.MOVE:
			return "MOVE"
		GameEnums.OrderType.ATTACK:
			return "ATTACK"
		GameEnums.OrderType.DEFEND:
			return "DEFEND"
		GameEnums.OrderType.HOLD:
			return "HOLD"
		GameEnums.OrderType.RECON:
			return "RECON"
		_:
			return "UNKNOWN"


func _get_state_name(state: GameEnums.UnitState) -> String:
	match state:
		GameEnums.UnitState.ACTIVE:
			return "ACTIVE"
		GameEnums.UnitState.SUPPRESSED:
			return "SUPPRESSED"
		GameEnums.UnitState.PINNED:
			return "PINNED"
		GameEnums.UnitState.BROKEN:
			return "BROKEN"
		GameEnums.UnitState.DESTROYED:
			return "DESTROYED"
		_:
			return "UNKNOWN"
