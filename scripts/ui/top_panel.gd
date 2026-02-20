class_name TopPanel
extends PanelContainer

## 上部パネル
## チケット、RP、拠点保持状況、時間を表示

# =============================================================================
# UI要素
# =============================================================================

var _hbox: HBoxContainer
var _ticket_label: Label
var _rp_label: Label
var _cp_container: HBoxContainer
var _time_label: Label
var _speed_label: Label

# =============================================================================
# 状態
# =============================================================================

var _map_data: MapData
var _player_faction: GameEnums.Faction

# =============================================================================
# 定数
# =============================================================================

const PANEL_HEIGHT := 40
const FONT_SIZE := 16
const ICON_SIZE := 24

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()
	_setup_style()


func setup(map_data: MapData, player_faction: GameEnums.Faction) -> void:
	_map_data = map_data
	_player_faction = player_faction
	_update_cp_display()


func _setup_layout() -> void:
	# レイアウトはHUDManagerから設定される
	# ここでは最小サイズのみ設定
	custom_minimum_size.y = PANEL_HEIGHT

	# 横並びコンテナ
	_hbox = HBoxContainer.new()
	_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hbox.add_theme_constant_override("separation", 20)
	add_child(_hbox)

	# マージン
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	_hbox.add_child(margin)

	var inner_hbox := HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 30)
	margin.add_child(inner_hbox)

	# チケット
	var ticket_section := _create_section("TICKETS")
	_ticket_label = ticket_section.get_node("Value") as Label
	_ticket_label.text = "1000"
	inner_hbox.add_child(ticket_section)

	# RP（Reinforcement Points）
	var rp_section := _create_section("RP")
	_rp_label = rp_section.get_node("Value") as Label
	_rp_label.text = "500"
	inner_hbox.add_child(rp_section)

	# 拠点状況
	var cp_section := VBoxContainer.new()
	var cp_header := Label.new()
	cp_header.text = "OBJECTIVES"
	cp_header.add_theme_font_size_override("font_size", 10)
	cp_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	cp_section.add_child(cp_header)

	_cp_container = HBoxContainer.new()
	_cp_container.add_theme_constant_override("separation", 8)
	cp_section.add_child(_cp_container)
	inner_hbox.add_child(cp_section)

	# スペーサー
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_hbox.add_child(spacer)

	# 時間
	var time_section := _create_section("TIME")
	_time_label = time_section.get_node("Value") as Label
	_time_label.text = "00:00"
	inner_hbox.add_child(time_section)

	# 速度
	var speed_section := _create_section("SPEED")
	_speed_label = speed_section.get_node("Value") as Label
	_speed_label.text = "1x"
	inner_hbox.add_child(speed_section)


func _create_section(header_text: String) -> VBoxContainer:
	var section := VBoxContainer.new()

	var header := Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	section.add_child(header)

	var value := Label.new()
	value.name = "Value"
	value.add_theme_font_size_override("font_size", FONT_SIZE)
	section.add_child(value)

	return section


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# 更新
# =============================================================================

func update_display(sim_runner: SimRunner) -> void:
	if not sim_runner:
		return

	# 時間表示
	var sim_time := sim_runner.get_sim_time()
	var minutes := int(sim_time) / 60
	var seconds := int(sim_time) % 60
	_time_label.text = "%02d:%02d" % [minutes, seconds]

	# 速度表示
	if sim_runner.is_paused():
		_speed_label.text = "PAUSED"
		_speed_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	else:
		_speed_label.text = "%dx" % int(sim_runner.sim_speed)
		_speed_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


func _update_cp_display() -> void:
	if not _map_data or not _cp_container:
		return

	# 既存のマーカーをクリア
	for child in _cp_container.get_children():
		child.queue_free()

	# 各拠点のマーカーを追加
	for cp in _map_data.capture_points:
		var marker := _create_cp_marker(cp)
		_cp_container.add_child(marker)


func _create_cp_marker(cp: MapData.CapturePoint) -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# 拠点アイコン
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.color = _get_faction_color(cp.initial_owner)
	container.add_child(icon)

	# 拠点名
	var label := Label.new()
	label.text = cp.id
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)

	return container


func _get_faction_color(faction: GameEnums.Faction) -> Color:
	match faction:
		GameEnums.Faction.BLUE:
			return Color(0.2, 0.4, 0.8)
		GameEnums.Faction.RED:
			return Color(0.8, 0.2, 0.2)
		_:
			return Color(0.5, 0.5, 0.5)
