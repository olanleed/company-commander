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

# 車両サブシステムHP
var _subsystem_section: VBoxContainer
var _mobility_bar: ProgressBar
var _mobility_label: Label
var _firepower_bar: ProgressBar
var _firepower_label: Label
var _sensors_bar: ProgressBar
var _sensors_label: Label

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
var _selected_elements: Array[ElementData.ElementInstance] = []
var _company_ai = null  # CompanyControllerAI

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

	# セパレータ
	var sep3 := HSeparator.new()
	_vbox.add_child(sep3)

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
	_state_label.text = "---"
	_position_label.text = "---"
	_clear_ai_info()


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

	# サブシステムHP（車両のみ）
	_update_subsystem_display(element)

	# Order
	_order_label.text = _get_order_name(element.current_order_type)

	# State
	_state_label.text = _get_state_name(element.state)

	# Position
	_position_label.text = "(%d, %d)" % [int(element.position.x), int(element.position.y)]

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
	_state_label.text = "---"
	_position_label.text = "---"

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
		_ai_weapon_label.text = "Weapon: %s" % element.current_weapon.display_name
	elif element.current_target_id != "":
		_ai_weapon_label.text = "Weapon: ---"
	else:
		_ai_weapon_label.text = "Weapon: (no target)"


func _clear_ai_info() -> void:
	_ai_template_label.text = "Template: ---"
	_ai_phase_label.text = "Phase: ---"
	_ai_combat_state_label.text = "Combat: ---"
	_ai_role_label.text = "Role: ---"
	_ai_weapon_label.text = "Weapon: ---"
