class_name HUDManager
extends Control

## HUD管理クラス
## 仕様書: docs/ui_design_v0.1.md
##
## 画面レイアウト:
## - 上部: チケット、RP、拠点状況、時間
## - 左: OB部隊一覧
## - 右: 選択詳細（Str/Sup/Order）
## - 下部: コマンドバー（8コマンド）+ ミニマップ + アラート

# =============================================================================
# シグナル
# =============================================================================

signal command_selected(command_type: GameEnums.OrderType, world_pos: Vector2)
signal unit_selected_from_list(element_id: String)
signal minimap_clicked(world_pos: Vector2)
signal pie_command_selected(command_type: GameEnums.OrderType, world_pos: Vector2)

# =============================================================================
# ノード参照
# =============================================================================

var top_panel: TopPanel
var left_panel: LeftPanel
var right_panel: RightPanel
var bottom_bar: BottomBar
var minimap: Minimap
var alert_log: AlertLog
var pie_menu: PieMenu

# =============================================================================
# 状態
# =============================================================================

var _world_model: WorldModel
var _map_data: MapData
var _selected_elements: Array[ElementData.ElementInstance] = []
var _player_faction: GameEnums.Faction = GameEnums.Faction.BLUE

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	_setup_layout()


func setup(world_model: WorldModel, map_data: MapData, player_faction: GameEnums.Faction) -> void:
	_world_model = world_model
	_map_data = map_data
	_player_faction = player_faction

	if top_panel:
		top_panel.setup(map_data, player_faction)
	if left_panel:
		left_panel.setup(world_model, player_faction)
	if right_panel:
		right_panel.setup(world_model)
	if minimap:
		minimap.setup(map_data, world_model, player_faction)
	if bottom_bar:
		bottom_bar.setup()


func _setup_layout() -> void:
	# 全画面に広げる
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 上部パネル
	top_panel = TopPanel.new()
	top_panel.name = "TopPanel"
	add_child(top_panel)
	_apply_top_panel_layout()

	# 左パネル
	left_panel = LeftPanel.new()
	left_panel.name = "LeftPanel"
	add_child(left_panel)
	left_panel.element_selected.connect(_on_left_panel_element_selected)
	_apply_left_panel_layout()

	# 右パネル
	right_panel = RightPanel.new()
	right_panel.name = "RightPanel"
	add_child(right_panel)
	_apply_right_panel_layout()

	# 下部バー
	bottom_bar = BottomBar.new()
	bottom_bar.name = "BottomBar"
	add_child(bottom_bar)
	bottom_bar.command_pressed.connect(_on_command_pressed)
	_apply_bottom_bar_layout()

	# ミニマップ
	minimap = Minimap.new()
	minimap.name = "Minimap"
	add_child(minimap)
	minimap.clicked.connect(_on_minimap_clicked)
	_apply_minimap_layout()

	# アラートログ
	alert_log = AlertLog.new()
	alert_log.name = "AlertLog"
	add_child(alert_log)
	_apply_alert_log_layout()

	# 放射状メニュー（非表示で待機）
	pie_menu = PieMenu.new()
	pie_menu.name = "PieMenu"
	pie_menu.visible = false
	add_child(pie_menu)
	pie_menu.command_selected.connect(_on_pie_command_selected)


# =============================================================================
# レイアウト適用（アンカーを明示的に設定）
# =============================================================================

func _apply_top_panel_layout() -> void:
	# 上部に固定（横幅100%、高さ40px）
	top_panel.anchor_left = 0.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 0
	top_panel.offset_top = 0
	top_panel.offset_right = 0
	top_panel.offset_bottom = 40


func _apply_left_panel_layout() -> void:
	# 左側に固定（TopPanelの下〜BottomBarの上）
	left_panel.anchor_left = 0.0
	left_panel.anchor_top = 0.0
	left_panel.anchor_right = 0.0
	left_panel.anchor_bottom = 1.0
	left_panel.offset_left = 0
	left_panel.offset_top = 45  # TopPanelの下
	left_panel.offset_right = 200  # 幅200px
	left_panel.offset_bottom = -90  # BottomBarの上


func _apply_right_panel_layout() -> void:
	# 右側に固定（TopPanelの下〜BottomBarの上）
	right_panel.anchor_left = 1.0
	right_panel.anchor_top = 0.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = -220  # 幅220px
	right_panel.offset_top = 45  # TopPanelの下
	right_panel.offset_right = 0
	right_panel.offset_bottom = -90  # BottomBarの上


func _apply_bottom_bar_layout() -> void:
	# 下部に固定（横幅は左右パネルの間）
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 210  # LeftPanelの右
	bottom_bar.offset_top = -80  # 高さ80px
	bottom_bar.offset_right = -230  # RightPanelとMinimapの左
	bottom_bar.offset_bottom = 0


func _apply_minimap_layout() -> void:
	# 右下に固定
	minimap.anchor_left = 1.0
	minimap.anchor_top = 1.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = -210  # 幅200px + マージン
	minimap.offset_top = -160  # 高さ150px + マージン
	minimap.offset_right = -10
	minimap.offset_bottom = -10


func _apply_alert_log_layout() -> void:
	# ミニマップの上に配置
	alert_log.anchor_left = 1.0
	alert_log.anchor_top = 1.0
	alert_log.anchor_right = 1.0
	alert_log.anchor_bottom = 1.0
	alert_log.offset_left = -310  # 幅300px + マージン
	alert_log.offset_top = -290  # ミニマップの上
	alert_log.offset_right = -10
	alert_log.offset_bottom = -170  # ミニマップの高さ分上

# =============================================================================
# 更新
# =============================================================================

func update_hud(sim_runner: SimRunner, company_ai = null) -> void:
	if top_panel:
		top_panel.update_display(sim_runner)

	if left_panel:
		left_panel.update_list()

	if right_panel and _selected_elements.size() > 0:
		right_panel.update_display(_selected_elements, company_ai)

	if minimap:
		minimap.queue_redraw()


func set_selected_elements(elements: Array[ElementData.ElementInstance]) -> void:
	_selected_elements = elements

	if right_panel:
		right_panel.set_elements(elements)

	if left_panel:
		left_panel.highlight_elements(elements)

# =============================================================================
# 放射状メニュー
# =============================================================================

func show_pie_menu(screen_pos: Vector2, world_pos: Vector2) -> void:
	if pie_menu:
		pie_menu.show_menu(screen_pos, world_pos)


func hide_pie_menu() -> void:
	if pie_menu:
		pie_menu.hide_menu()


func is_pie_menu_visible() -> bool:
	return pie_menu and pie_menu.visible

# =============================================================================
# アラート
# =============================================================================

func add_alert(
	alert_type: AlertLog.AlertType,
	message: String,
	priority: AlertLog.AlertPriority = AlertLog.AlertPriority.MEDIUM,
	element_id: String = "",
	world_pos: Vector2 = Vector2.ZERO
) -> void:
	if alert_log:
		alert_log.add_alert(alert_type, message, priority, element_id, world_pos)

# =============================================================================
# シグナルハンドラ
# =============================================================================

func _on_command_pressed(command_type: GameEnums.OrderType) -> void:
	command_selected.emit(command_type, Vector2.ZERO)


func _on_left_panel_element_selected(element_id: String) -> void:
	unit_selected_from_list.emit(element_id)


func _on_minimap_clicked(world_pos: Vector2) -> void:
	minimap_clicked.emit(world_pos)


func _on_pie_command_selected(command_type: GameEnums.OrderType, world_pos: Vector2) -> void:
	pie_command_selected.emit(command_type, world_pos)
	hide_pie_menu()
