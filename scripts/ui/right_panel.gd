class_name RightPanel
extends PanelContainer

## 右パネル（選択詳細）
## Strength、Suppression、Order、SOPを表示

# =============================================================================
# シグナル
# =============================================================================

signal sop_changed(new_sop: GameEnums.SOPMode)

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
var _sop_section: VBoxContainer
var _sop_buttons: HBoxContainer
var _sop_btn_hold: Button
var _sop_btn_return: Button
var _sop_btn_free: Button
var _state_label: Label
var _comm_state_label: Label
var _position_label: Label

# 車両サブシステムHP
var _subsystem_section: VBoxContainer
var _mobility_bar: ProgressBar
var _mobility_label: Label
var _firepower_bar: ProgressBar
var _firepower_label: Label
var _sensors_bar: ProgressBar
var _sensors_label: Label

# 装備情報
var _equipment_section: VBoxContainer
var _vehicle_label: Label
var _weapons_label: Label
var _ammo_label: Label  # 残弾数表示

# 補給ユニット情報
var _supply_section: VBoxContainer
var _supply_remaining_bar: ProgressBar
var _supply_remaining_label: Label
var _supply_range_label: Label
var _supply_rate_label: Label

# AI思考情報
var _ai_section: VBoxContainer
var _ai_template_label: Label
var _ai_phase_label: Label
var _ai_combat_state_label: Label
var _ai_role_label: Label
var _ai_weapon_label: Label

# =============================================================================
# 状態
# =============================================================================

var _world_model: WorldModel
var _selection_manager: SelectionManager
var _selected_elements: Array[ElementData.ElementInstance] = []
var _company_ai = null  # CompanyControllerAI

## 更新タイマー（残弾など動的情報の定期更新用）
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5  # 0.5秒ごとに更新

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
	set_process(true)


func _process(delta: float) -> void:
	# 残弾など動的情報を定期的に更新
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		if _selected_elements.size() > 0:
			_refresh_dynamic_info()


func setup(world_model: WorldModel, selection_manager: SelectionManager = null) -> void:
	_world_model = world_model
	_selection_manager = selection_manager

	# SelectionManagerを購読（リアクティブ更新）
	if _selection_manager:
		_selection_manager.selection_changed.connect(_on_selection_changed)


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

	# サブシステムHP（車両のみ表示）
	_subsystem_section = VBoxContainer.new()
	_subsystem_section.add_theme_constant_override("separation", 4)
	_subsystem_section.visible = false  # デフォルトは非表示

	var subsys_header := Label.new()
	subsys_header.text = "SUBSYSTEMS"
	subsys_header.add_theme_font_size_override("font_size", 10)
	subsys_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_subsystem_section.add_child(subsys_header)

	# Mobility HP
	var mob_section := _create_subsystem_bar("MOB", Color(0.3, 0.7, 0.9))
	_mobility_bar = mob_section.get_node("Bar") as ProgressBar
	_mobility_label = mob_section.get_node("Value") as Label
	_subsystem_section.add_child(mob_section)

	# Firepower HP
	var fire_section := _create_subsystem_bar("FPW", Color(0.9, 0.4, 0.3))
	_firepower_bar = fire_section.get_node("Bar") as ProgressBar
	_firepower_label = fire_section.get_node("Value") as Label
	_subsystem_section.add_child(fire_section)

	# Sensors HP
	var sens_section := _create_subsystem_bar("SEN", Color(0.5, 0.8, 0.4))
	_sensors_bar = sens_section.get_node("Bar") as ProgressBar
	_sensors_label = sens_section.get_node("Value") as Label
	_subsystem_section.add_child(sens_section)

	_vbox.add_child(_subsystem_section)

	# セパレータ（サブシステムの後）
	var sep2b := HSeparator.new()
	_vbox.add_child(sep2b)

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

	# SOP (Standard Operating Procedure) - 3ボタン式
	_sop_section = VBoxContainer.new()
	_sop_section.add_theme_constant_override("separation", 4)

	var sop_header := Label.new()
	sop_header.text = "SOP (FIRE CONTROL)"
	sop_header.add_theme_font_size_override("font_size", 10)
	sop_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_sop_section.add_child(sop_header)

	# 3つのSOPボタンを横並び
	_sop_buttons = HBoxContainer.new()
	_sop_buttons.add_theme_constant_override("separation", 4)

	_sop_btn_hold = _create_sop_button("HOLD", Color(0.9, 0.3, 0.3), GameEnums.SOPMode.HOLD_FIRE)
	_sop_btn_return = _create_sop_button("RET", Color(0.9, 0.8, 0.2), GameEnums.SOPMode.RETURN_FIRE)
	_sop_btn_free = _create_sop_button("FREE", Color(0.3, 0.9, 0.3), GameEnums.SOPMode.FIRE_AT_WILL)

	_sop_buttons.add_child(_sop_btn_hold)
	_sop_buttons.add_child(_sop_btn_return)
	_sop_buttons.add_child(_sop_btn_free)

	_sop_section.add_child(_sop_buttons)
	_vbox.add_child(_sop_section)

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

	# Data Link State
	var comm_section := VBoxContainer.new()
	var comm_header := Label.new()
	comm_header.text = "DATA LINK"
	comm_header.add_theme_font_size_override("font_size", 10)
	comm_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	comm_section.add_child(comm_header)

	_comm_state_label = Label.new()
	_comm_state_label.text = "LINKED"
	_comm_state_label.add_theme_font_size_override("font_size", 14)
	comm_section.add_child(_comm_state_label)
	_vbox.add_child(comm_section)

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

	# セパレータ
	var sep3 := HSeparator.new()
	_vbox.add_child(sep3)

	# 装備情報セクション
	_equipment_section = VBoxContainer.new()
	_equipment_section.add_theme_constant_override("separation", 4)

	var equip_header := Label.new()
	equip_header.text = "EQUIPMENT"
	equip_header.add_theme_font_size_override("font_size", 12)
	equip_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	equip_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equipment_section.add_child(equip_header)

	# 車両名
	_vehicle_label = Label.new()
	_vehicle_label.text = "Vehicle: ---"
	_vehicle_label.add_theme_font_size_override("font_size", 11)
	_vehicle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_equipment_section.add_child(_vehicle_label)

	# 武装リスト
	_weapons_label = Label.new()
	_weapons_label.text = "Weapons: ---"
	_weapons_label.add_theme_font_size_override("font_size", 11)
	_weapons_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_weapons_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipment_section.add_child(_weapons_label)

	# 残弾数
	_ammo_label = Label.new()
	_ammo_label.text = "Ammo: ---"
	_ammo_label.add_theme_font_size_override("font_size", 11)
	_ammo_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_ammo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipment_section.add_child(_ammo_label)

	_vbox.add_child(_equipment_section)

	# 補給ユニット情報セクション
	_supply_section = VBoxContainer.new()
	_supply_section.add_theme_constant_override("separation", 4)
	_supply_section.visible = false  # デフォルトは非表示（補給ユニット選択時のみ表示）

	var supply_header := Label.new()
	supply_header.text = "SUPPLY STATUS"
	supply_header.add_theme_font_size_override("font_size", 12)
	supply_header.add_theme_color_override("font_color", Color(0.4, 0.8, 0.9))
	supply_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_supply_section.add_child(supply_header)

	# 残量バー
	var supply_bar_section := _create_supply_bar("REMAINING", Color(0.3, 0.7, 0.9))
	_supply_remaining_bar = supply_bar_section.get_node("Bar") as ProgressBar
	_supply_remaining_label = supply_bar_section.get_node("Value") as Label
	_supply_section.add_child(supply_bar_section)

	# 補給範囲
	_supply_range_label = Label.new()
	_supply_range_label.text = "Range: ---"
	_supply_range_label.add_theme_font_size_override("font_size", 11)
	_supply_range_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_supply_section.add_child(_supply_range_label)

	# 補給レート
	_supply_rate_label = Label.new()
	_supply_rate_label.text = "Rate: ---"
	_supply_rate_label.add_theme_font_size_override("font_size", 11)
	_supply_rate_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_supply_section.add_child(_supply_rate_label)

	_vbox.add_child(_supply_section)

	# セパレータ
	var sep4 := HSeparator.new()
	_vbox.add_child(sep4)

	# AI思考情報セクション
	_ai_section = VBoxContainer.new()
	_ai_section.add_theme_constant_override("separation", 4)

	var ai_header := Label.new()
	ai_header.text = "AI THOUGHT"
	ai_header.add_theme_font_size_override("font_size", 12)
	ai_header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	ai_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ai_section.add_child(ai_header)

	# テンプレート
	_ai_template_label = _create_ai_info_label("Template")
	_ai_section.add_child(_ai_template_label)

	# フェーズ
	_ai_phase_label = _create_ai_info_label("Phase")
	_ai_section.add_child(_ai_phase_label)

	# 戦闘状態
	_ai_combat_state_label = _create_ai_info_label("Combat State")
	_ai_section.add_child(_ai_combat_state_label)

	# 役割
	_ai_role_label = _create_ai_info_label("Role")
	_ai_section.add_child(_ai_role_label)

	# 選択武器
	_ai_weapon_label = _create_ai_info_label("Weapon")
	_ai_section.add_child(_ai_weapon_label)

	_vbox.add_child(_ai_section)


func _create_ai_info_label(prefix: String) -> Label:
	var label := Label.new()
	label.text = prefix + ": ---"
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label


## SOPボタンを作成
func _create_sop_button(text: String, color: Color, sop_mode: GameEnums.SOPMode) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(55, 28)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 11)

	# スタイル設定
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.6)
	normal_style.border_width_bottom = 2
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 3
	normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_left = 3
	normal_style.corner_radius_bottom_right = 3
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = color.darkened(0.4)
	hover_style.border_width_bottom = 2
	hover_style.border_color = color
	hover_style.corner_radius_top_left = 3
	hover_style.corner_radius_top_right = 3
	hover_style.corner_radius_bottom_left = 3
	hover_style.corner_radius_bottom_right = 3
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = color.darkened(0.2)
	pressed_style.border_width_bottom = 3
	pressed_style.border_color = color.lightened(0.2)
	pressed_style.corner_radius_top_left = 3
	pressed_style.corner_radius_top_right = 3
	pressed_style.corner_radius_bottom_left = 3
	pressed_style.corner_radius_bottom_right = 3
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# クリック時にSOPモードを変更
	btn.pressed.connect(_on_sop_button_pressed.bind(sop_mode))

	return btn


## SOPボタンがクリックされたとき
func _on_sop_button_pressed(sop_mode: GameEnums.SOPMode) -> void:
	sop_changed.emit(sop_mode)
	# ボタンのハイライト状態を更新
	_update_sop_buttons(sop_mode)


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


## サブシステムHP用のコンパクトなバーを作成
func _create_subsystem_bar(label_text: String, bar_color: Color) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# ラベル（短縮名）
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 30
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(label)

	# プログレスバー
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(80, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.value = 100
	bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)

	container.add_child(bar)

	# 値ラベル
	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = "100"
	value_label.custom_minimum_size.x = 28
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 10)
	container.add_child(value_label)

	return container


## 補給ユニット用のバーを作成
func _create_supply_bar(label_text: String, bar_color: Color) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# ラベル
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 70
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(label)

	# プログレスバー
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(80, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.value = 100
	bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)

	container.add_child(bar)

	# 値ラベル
	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = "100%"
	value_label.custom_minimum_size.x = 40
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 10)
	container.add_child(value_label)

	return container


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.85)
	style.border_width_left = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# 更新
# =============================================================================

func set_elements(elements) -> void:
	# Array[ElementInstance]またはArrayを受け付ける
	_selected_elements.clear()
	for e in elements:
		_selected_elements.append(e)
	_update_display()


## SelectionManagerからの選択変更通知
func _on_selection_changed(elements: Array) -> void:
	_selected_elements.clear()
	for e in elements:
		_selected_elements.append(e)
	_update_display()


func update_display(elements: Array[ElementData.ElementInstance], company_ai = null) -> void:
	_selected_elements = elements
	_company_ai = company_ai
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
	_subsystem_section.visible = false
	_order_label.text = "NONE"
	_sop_section.visible = false
	_state_label.text = "---"
	_comm_state_label.text = "---"
	_comm_state_label.remove_theme_color_override("font_color")
	_position_label.text = "---"
	_clear_equipment_info()
	_clear_supply_info()
	_clear_ai_info()


func _show_single(element: ElementData.ElementInstance) -> void:
	# ユニット名（車両名があればそれを優先表示）
	if element.vehicle_id != "":
		var catalog = ElementFactory.get_vehicle_catalog()
		if catalog:
			var vehicle_config = catalog.get_vehicle(element.vehicle_id)
			if vehicle_config:
				_unit_name.text = vehicle_config.display_name
			else:
				_unit_name.text = element.vehicle_id
		else:
			_unit_name.text = element.vehicle_id
	else:
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

	# サブシステムHP（車両のみ）
	_update_subsystem_display(element)

	# Order
	_order_label.text = _get_order_name(element.current_order_type)

	# SOP
	_update_sop_display(element)

	# State
	_state_label.text = _get_state_name(element.state)

	# Data Link State
	_update_comm_state_display(element)

	# Position
	_position_label.text = "(%d, %d)" % [int(element.position.x), int(element.position.y)]

	# 装備情報を更新
	_update_equipment_info(element)

	# 補給ユニット情報を更新
	_update_supply_info(element)

	# AI情報を更新
	_update_ai_info(element)


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

	# サブシステムHP（複数選択時は非表示）
	_subsystem_section.visible = false

	_order_label.text = "MULTIPLE"
	# 複数選択時もSOPボタンを表示（全選択ユニットに適用される）
	_sop_section.visible = true
	# 最初のユニットのSOPを表示
	if _selected_elements.size() > 0:
		_update_sop_buttons(_selected_elements[0].sop_mode)
	_state_label.text = "---"
	_update_comm_state_display_multiple()
	_position_label.text = "---"

	# 装備情報（複数選択時はクリア）
	_clear_equipment_info()

	# 補給情報（複数選択時はクリア）
	_clear_supply_info()

	# 複数選択時はAI全体情報のみ表示
	if _company_ai:
		var ai_info: Dictionary = _company_ai.get_ai_thought_info()
		_ai_template_label.text = "Template: %s" % ai_info.get("template", "NONE")
		_ai_phase_label.text = "Phase: %s" % ai_info.get("phase_name", "NONE")
		_ai_combat_state_label.text = "Combat: %s" % ai_info.get("combat_state", "QUIET")
		_ai_role_label.text = "Role: (multiple)"
		_ai_weapon_label.text = "Weapon: ---"
	else:
		_clear_ai_info()


## サブシステムHP表示を更新（車両のみ）
func _update_subsystem_display(element: ElementData.ElementInstance) -> void:
	# 車両かどうかを判定（armor_class >= 1）
	if element.is_vehicle():
		_subsystem_section.visible = true

		# Mobility HP
		_mobility_bar.value = element.mobility_hp
		_mobility_label.text = "%d" % element.mobility_hp
		_update_subsystem_bar_color(_mobility_bar, element.mobility_hp)

		# Firepower HP
		_firepower_bar.value = element.firepower_hp
		_firepower_label.text = "%d" % element.firepower_hp
		_update_subsystem_bar_color(_firepower_bar, element.firepower_hp)

		# Sensors HP
		_sensors_bar.value = element.sensors_hp
		_sensors_label.text = "%d" % element.sensors_hp
		_update_subsystem_bar_color(_sensors_bar, element.sensors_hp)
	else:
		_subsystem_section.visible = false


## サブシステムバーの色をHP値に応じて変更
func _update_subsystem_bar_color(bar: ProgressBar, hp: int) -> void:
	var fill_style := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		return

	# HP値に応じて色を変更
	if hp >= 70:
		# 緑（健全）
		fill_style.bg_color = Color(0.3, 0.8, 0.3)
	elif hp >= 30:
		# 黄（警告）
		fill_style.bg_color = Color(0.9, 0.8, 0.2)
	else:
		# 赤（危険）
		fill_style.bg_color = Color(0.9, 0.3, 0.2)


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


## SOP状態を表示（ボタンハイライト）
func _update_sop_display(element: ElementData.ElementInstance) -> void:
	var sop := element.sop_mode
	_update_sop_buttons(sop)
	_sop_section.visible = true


## SOPボタンのハイライト状態を更新
func _update_sop_buttons(current_sop: GameEnums.SOPMode) -> void:
	# 全ボタンのスタイルをリセット
	_set_sop_button_active(_sop_btn_hold, current_sop == GameEnums.SOPMode.HOLD_FIRE, Color(0.9, 0.3, 0.3))
	_set_sop_button_active(_sop_btn_return, current_sop == GameEnums.SOPMode.RETURN_FIRE, Color(0.9, 0.8, 0.2))
	_set_sop_button_active(_sop_btn_free, current_sop == GameEnums.SOPMode.FIRE_AT_WILL, Color(0.3, 0.9, 0.3))


## SOPボタンのアクティブ状態を設定
func _set_sop_button_active(btn: Button, is_active: bool, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3

	if is_active:
		# アクティブ: 明るい色 + 太いボーダー
		style.bg_color = color.darkened(0.2)
		style.border_width_bottom = 3
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_color = color.lightened(0.3)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		# 非アクティブ: 暗い色
		style.bg_color = color.darkened(0.7)
		style.border_width_bottom = 2
		style.border_color = color.darkened(0.4)
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	btn.add_theme_stylebox_override("normal", style)


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


func _update_ai_info(element: ElementData.ElementInstance) -> void:
	if not _company_ai:
		_ai_template_label.text = "Template: N/A"
		_ai_phase_label.text = "Phase: N/A"
		_ai_combat_state_label.text = "Combat: N/A"
		_ai_role_label.text = "Role: N/A"
		_ai_weapon_label.text = "Weapon: N/A"
		return

	# 中隊AI全体の情報
	var ai_info: Dictionary = _company_ai.get_ai_thought_info()

	_ai_template_label.text = "Template: %s" % ai_info.get("template", "NONE")
	_ai_phase_label.text = "Phase: %s" % ai_info.get("phase_name", "NONE")

	# 戦闘状態は色分け
	var combat_state: String = ai_info.get("combat_state", "QUIET")
	_ai_combat_state_label.text = "Combat: %s" % combat_state
	_ai_combat_state_label.remove_theme_color_override("font_color")
	match combat_state:
		"ENGAGED":
			_ai_combat_state_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"ALERT":
			_ai_combat_state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		"RECOVERING":
			_ai_combat_state_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
		_:
			_ai_combat_state_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))

	# ユニット個別の情報
	var element_info: Dictionary = _company_ai.get_element_ai_info(element.id)
	_ai_role_label.text = "Role: %s" % element_info.get("role", "---")

	# 選択中の武器（current_weaponを使用）
	if element.current_target_id != "" and element.current_weapon:
		var weapon := element.current_weapon
		var weapon_text := weapon.display_name

		# 戦車砲やATGMなど重要な武器の場合は弾種を強調
		var ammo_type := _get_ammo_type_display(weapon)
		if ammo_type != "":
			_ai_weapon_label.text = "Weapon: %s\n  [%s]" % [weapon_text, ammo_type]
			# 弾種に応じて色を変更
			if weapon.mechanism == WeaponData.Mechanism.KINETIC:
				_ai_weapon_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))  # 白青（AP系）
			elif weapon.mechanism == WeaponData.Mechanism.SHAPED_CHARGE:
				_ai_weapon_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))  # オレンジ（HEAT系）
			else:
				_ai_weapon_label.remove_theme_color_override("font_color")
		else:
			_ai_weapon_label.text = "Weapon: %s" % weapon_text
			_ai_weapon_label.remove_theme_color_override("font_color")
	elif element.current_target_id != "":
		_ai_weapon_label.text = "Weapon: ---"
		_ai_weapon_label.remove_theme_color_override("font_color")
	else:
		_ai_weapon_label.text = "Weapon: (no target)"
		_ai_weapon_label.remove_theme_color_override("font_color")


func _clear_ai_info() -> void:
	_ai_template_label.text = "Template: ---"
	_ai_phase_label.text = "Phase: ---"
	_ai_combat_state_label.text = "Combat: ---"
	_ai_role_label.text = "Role: ---"
	_ai_weapon_label.text = "Weapon: ---"


## 装備情報を更新
func _update_equipment_info(element: ElementData.ElementInstance) -> void:
	# 車両名（vehicle_idがあればカタログから表示名を取得）
	if element.vehicle_id != "":
		var catalog = ElementFactory.get_vehicle_catalog()
		if catalog:
			var vehicle_config = catalog.get_vehicle(element.vehicle_id)
			if vehicle_config:
				_vehicle_label.text = "Vehicle: %s" % vehicle_config.display_name
			else:
				_vehicle_label.text = "Vehicle: %s" % element.vehicle_id
		else:
			_vehicle_label.text = "Vehicle: %s" % element.vehicle_id
	else:
		# vehicle_idがない場合はアーキタイプ名を表示
		if element.element_type:
			_vehicle_label.text = "Type: %s" % element.element_type.display_name
		else:
			_vehicle_label.text = "Type: ---"

	# 武装リスト
	if element.weapons.size() > 0:
		var weapon_names: Array[String] = []
		for weapon in element.weapons:
			weapon_names.append(weapon.display_name)
		_weapons_label.text = "Weapons:\n  " + "\n  ".join(weapon_names)
	else:
		_weapons_label.text = "Weapons: (none)"

	# 残弾数表示
	_update_ammo_display(element)


## ユニットが主砲/機関砲を持っているかチェック
func _element_has_gun_weapon(element: ElementData.ElementInstance) -> bool:
	for weapon in element.weapons:
		# 戦車砲、機関砲、小銃系をチェック
		if weapon.id.contains("TANK") or weapon.id.contains("AUTOCANNON"):
			return true
		if weapon.id.contains("30MM") or weapon.id.contains("35MM") or weapon.id.contains("40MM"):
			return true
		if weapon.id.contains("120MM") or weapon.id.contains("105MM") or weapon.id.contains("125MM"):
			return true
		# 砲兵武器（榴弾砲、迫撃砲）
		if weapon.id.contains("HOWITZER") or weapon.id.contains("MORTAR"):
			return true
	return false


## 残弾数を表示
func _update_ammo_display(element: ElementData.ElementInstance) -> void:
	if not element.ammo_state:
		_ammo_label.text = "Ammo: N/A"
		_ammo_label.remove_theme_color_override("font_color")
		return

	var ammo_lines: Array[String] = []
	var ammo_state = element.ammo_state

	# ユニットが実際に主砲/機関砲を持っているかチェック
	var has_gun := _element_has_gun_weapon(element)

	# 主砲（弾薬容量があり、実際に主砲武器を持っている場合のみ表示）
	if has_gun and ammo_state.main_gun and ammo_state.main_gun.get_max_total() > 0:
		var gun_state = ammo_state.main_gun
		var status := ""
		if gun_state.is_reloading:
			var progress: int = gun_state.reload_progress_ticks
			var duration: int = gun_state.reload_duration_ticks
			status = " [RELOAD %d%%]" % int(float(progress) / float(duration) * 100.0)

		# 複数弾種がある場合は総弾数を表示、単一弾種の場合はスロット詳細を表示
		if gun_state.ammo_slots.size() > 1:
			# 複数弾種: 総残弾数 / 総最大弾数 を表示
			var total_remaining: int = gun_state.get_total_remaining()
			var total_max: int = gun_state.get_max_total()
			# 現在選択中の弾種名も表示
			var current_slot = gun_state.get_current_slot()
			var ammo_name := ""
			if current_slot:
				ammo_name = " [%s]" % _get_short_ammo_name(current_slot.ammo_type_id)
			ammo_lines.append("  Gun: %d/%d%s%s" % [total_remaining, total_max, ammo_name, status])
		else:
			# 単一弾種: 即発弾+予備弾の形式で表示 (例: Gun: 13+22/14+22)
			var slot = gun_state.get_current_slot()
			if slot:
				var ready_count: int = slot.count_ready
				var stowed_count: int = slot.count_stowed
				var max_ready: int = slot.max_ready
				var max_stowed: int = slot.max_stowed
				ammo_lines.append("  Gun: %d+%d/%d+%d%s" % [ready_count, stowed_count, max_ready, max_stowed, status])

	# ATGM（弾薬容量がある場合のみ表示）
	if ammo_state.atgm and ammo_state.atgm.get_max_total() > 0:
		var atgm_state = ammo_state.atgm
		var slot = atgm_state.get_current_slot()
		if slot:
			var ready_count: int = slot.count_ready
			var stowed_count: int = slot.count_stowed
			var status := ""
			if atgm_state.is_reloading:
				status = " [RELOAD]"
			ammo_lines.append("  ATGM: %d+%d%s" % [ready_count, stowed_count, status])

	# 副武装（機関砲など重要なもののみ、弾薬容量がある場合のみ表示）
	for sec in ammo_state.secondary:
		if sec.weapon_id.contains("AUTOCANNON") or sec.weapon_id.contains("30") or sec.weapon_id.contains("35"):
			var sec_max: int = sec.get_max_total()
			if sec_max > 0:
				var sec_total: int = sec.get_total_remaining()
				ammo_lines.append("  AC: %d/%d" % [sec_total, sec_max])
				break  # 最初の機関砲のみ

	if ammo_lines.size() > 0:
		_ammo_label.text = "Ammo:\n" + "\n".join(ammo_lines)
		# 残弾率に応じて色を変更
		var total_ratio: float = ammo_state.get_total_ammo_ratio()
		if total_ratio >= 0.5:
			_ammo_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))  # 緑
		elif total_ratio >= 0.25:
			_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))  # 黄
		else:
			_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))  # 赤
	else:
		_ammo_label.text = "Ammo: (no tracked weapons)"
		_ammo_label.remove_theme_color_override("font_color")


## 弾種名を短縮して表示用に変換
func _get_short_ammo_name(ammo_type_id: String) -> String:
	# 口径プレフィックスを削除 (例: "155mm HE" -> "HE")
	var name := ammo_type_id
	for prefix in ["155mm ", "152mm ", "122mm ", "120mm ", "105mm "]:
		if name.begins_with(prefix):
			name = name.substr(prefix.length())
			break
	# 長すぎる名前を短縮
	if name.length() > 10:
		# M982 Excalibur -> Excalibur
		if "Excalibur" in name:
			return "Excalibur"
		# Guided -> Guided
		if "Guided" in name:
			return "Guided"
		# 先頭10文字
		return name.substr(0, 10)
	return name


## 動的情報（残弾、HP、抑圧など）を定期的にリフレッシュ
func _refresh_dynamic_info() -> void:
	if _selected_elements.size() == 1:
		var element := _selected_elements[0]
		# 残弾表示を更新
		_update_ammo_display(element)
		# 補給ユニットの残量を更新
		_update_supply_info(element)
		# HP・抑圧も更新
		_strength_bar.value = element.current_strength
		_strength_label.text = "%d%%" % element.current_strength
		_suppression_bar.value = element.suppression * 100.0
		_suppression_label.text = "%d%%" % int(element.suppression * 100.0)


## 装備情報をクリア
func _clear_equipment_info() -> void:
	_vehicle_label.text = "Vehicle: ---"
	_weapons_label.text = "Weapons: ---"
	_ammo_label.text = "Ammo: ---"


## 補給ユニット情報を更新
func _update_supply_info(element: ElementData.ElementInstance) -> void:
	# 補給ユニットかどうかを判定（supply_configが設定されているか）
	if element.supply_config.size() == 0:
		_supply_section.visible = false
		return

	_supply_section.visible = true

	# 残量計算
	var capacity: int = element.supply_config.get("capacity", 0)
	var remaining: int = element.supply_remaining

	# unit_countを考慮した最大容量
	var catalog = ElementFactory.get_vehicle_catalog()
	var max_capacity: int = capacity
	if catalog and element.vehicle_id != "":
		var vehicle_config = catalog.get_vehicle(element.vehicle_id)
		if vehicle_config:
			max_capacity = capacity * vehicle_config.unit_count

	# 残量バー更新
	var ratio: float = float(remaining) / float(max_capacity) if max_capacity > 0 else 0.0
	_supply_remaining_bar.value = ratio * 100.0
	_supply_remaining_label.text = "%d/%d" % [remaining, max_capacity]

	# 残量に応じてバーの色を変更
	_update_supply_bar_color(_supply_remaining_bar, ratio)

	# 補給範囲
	var supply_range: float = element.supply_config.get("supply_range_m", 100.0)
	_supply_range_label.text = "Range: %.0fm" % supply_range

	# 補給レート
	var ammo_rate: float = element.supply_config.get("ammo_resupply_rate", 1.0)
	_supply_rate_label.text = "Rate: x%.1f" % ammo_rate


## 補給バーの色を残量比に応じて変更
func _update_supply_bar_color(bar: ProgressBar, ratio: float) -> void:
	var fill_style := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		return

	if ratio >= 0.5:
		# 青緑（十分）
		fill_style.bg_color = Color(0.3, 0.7, 0.9)
	elif ratio >= 0.25:
		# 黄（警告）
		fill_style.bg_color = Color(0.9, 0.8, 0.2)
	else:
		# 赤（危険）
		fill_style.bg_color = Color(0.9, 0.3, 0.2)


## 補給ユニット情報をクリア
func _clear_supply_info() -> void:
	_supply_section.visible = false


## データリンク状態を表示（単一ユニット）
func _update_comm_state_display(element: ElementData.ElementInstance) -> void:
	var comm_state := element.comm_state
	_comm_state_label.text = _get_comm_state_name(comm_state)

	# 色分け
	_comm_state_label.remove_theme_color_override("font_color")
	match comm_state:
		GameEnums.CommState.LINKED:
			_comm_state_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		GameEnums.CommState.DEGRADED:
			_comm_state_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		GameEnums.CommState.ISOLATED:
			_comm_state_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	# ハブ接続先を表示（あれば）
	if element.comm_hub_id != "" and element.comm_hub_id != element.id:
		_comm_state_label.text += " -> %s" % element.comm_hub_id


## データリンク状態を表示（複数ユニット）
func _update_comm_state_display_multiple() -> void:
	var linked_count := 0
	var isolated_count := 0

	for element in _selected_elements:
		if element.comm_state == GameEnums.CommState.LINKED:
			linked_count += 1
		elif element.comm_state == GameEnums.CommState.ISOLATED:
			isolated_count += 1

	if isolated_count == 0:
		_comm_state_label.text = "ALL LINKED"
		_comm_state_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif linked_count == 0:
		_comm_state_label.text = "ALL ISOLATED"
		_comm_state_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		_comm_state_label.text = "MIXED (%d/%d)" % [linked_count, _selected_elements.size()]
		_comm_state_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))


func _get_comm_state_name(state: GameEnums.CommState) -> String:
	match state:
		GameEnums.CommState.LINKED:
			return "LINKED"
		GameEnums.CommState.DEGRADED:
			return "DEGRADED"
		GameEnums.CommState.ISOLATED:
			return "ISOLATED"
		_:
			return "UNKNOWN"


## 武器から弾種表示名を取得（戦車砲やATGMなど重要な武器のみ）
func _get_ammo_type_display(weapon: WeaponData.WeaponType) -> String:
	if not weapon:
		return ""

	# 戦車砲（DISCRETE + KINETIC）= APFSDS系
	if weapon.fire_model == WeaponData.FireModel.DISCRETE:
		match weapon.mechanism:
			WeaponData.Mechanism.KINETIC:
				# 武器IDから弾種を判定
				if weapon.id.contains("APFSDS") or weapon.id.contains("TANK_KE"):
					return "APFSDS"
				elif weapon.id.contains("AP"):
					return "AP"
				else:
					return "KE"
			WeaponData.Mechanism.SHAPED_CHARGE:
				if weapon.id.contains("ATGM") or weapon.id.contains("MAT"):
					return "ATGM"
				elif weapon.id.contains("HEAT"):
					return "HEAT"
				elif weapon.id.contains("RPG"):
					return "RPG"
				else:
					return "CE"
			WeaponData.Mechanism.BLAST_FRAG:
				if weapon.id.contains("HE"):
					return "HE"
				elif weapon.id.contains("MORTAR"):
					return "HE-FRAG"
				else:
					return "FRAG"

	# CONTINUOUS武器（機関砲など）は弾種表示なし
	return ""
