extends Node2D

const CompanyControllerAIClass = preload("res://scripts/ai/company_controller_ai.gd")
const CommanderAIClass = preload("res://scripts/ai/commander_ai.gd")
const InputControllerClass = preload("res://scripts/ui/input_controller.gd")
const OrderPreviewClass = preload("res://scripts/ui/order_preview.gd")
const DataLinkSystemClass = preload("res://scripts/systems/data_link_system.gd")
const TransportSystemClass = preload("res://scripts/systems/transport_system.gd")

## Company Commander - メインシーン
## 2D現代戦リアルタイムストラテジー
##
## Phase 1: GameLoop + マップ読み込み
## Phase 2: Element表示 + ナビゲーション + 移動
## Phase 3: 視界・索敵システム（FoW）
## Phase 4: 中隊AIシステム

# =============================================================================
# ノード参照
# =============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var map_layer: Node2D = $MapLayer
@onready var units_layer: Node2D = $UnitsLayer
@onready var ui_layer: CanvasLayer = $UILayer

## HUD関連
var hud_manager: HUDManager
var input_controller  # InputControllerClass
var order_preview  # OrderPreviewClass

# =============================================================================
# コンポーネント
# =============================================================================

var sim_runner: SimRunner
var map_data: MapData
var world_model: WorldModel
var nav_manager: NavigationManager
var movement_system: MovementSystem
var symbol_manager: SymbolManager
var vision_system: VisionSystem
var combat_system: CombatSystem
var event_bus: CombatEventBus
var combat_visualizer: CombatVisualizer
var capture_system: CaptureSystem  # コンクエストモード用（現在未使用）
var projectile_manager: ProjectileManager
var tactical_overlay: TacticalOverlay
var data_link_system  # DataLinkSystemClass
var transport_system  # TransportSystemClass

## 中隊AI（陣営別）
var company_ais: Dictionary = {}  # faction -> CompanyControllerAI

## コマンダーAI（陣営別）- 簡易版
var commander_ais: Dictionary = {}  # faction -> CommanderAI

var background_sprite: Sprite2D
var _element_views: Dictionary = {}  # element_id -> ElementView
var _selected_elements: Array[ElementData.ElementInstance] = []
var _cp_views: Dictionary = {}  # cp_id -> CapturePointView

## 飛翔中の間接射撃（着弾待ち）
## 各要素: {shooter_id, impact_pos, weapon, faction, arrival_time}
var _pending_indirect_impacts: Array[Dictionary] = []

# =============================================================================
# プレイヤー設定
# =============================================================================

var player_faction: GameEnums.Faction = GameEnums.Faction.BLUE

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	print("Company Commander 起動")

	_setup_systems()
	_connect_signals()

	# マップ読み込みとナビゲーション構築を待機
	await _load_test_map_async()

	_setup_camera()
	_spawn_test_units()

	# CombatVisualizerをユニットレイヤーに追加
	units_layer.add_child(combat_visualizer)

	# ProjectileManagerをユニットレイヤーに追加
	units_layer.add_child(projectile_manager)

	# TacticalOverlayをユニットレイヤーに追加（ユニットの上、UIの下に描画）
	tactical_overlay.setup(world_model, vision_system)
	units_layer.add_child(tactical_overlay)

	# HUDセットアップ
	_setup_hud()

	# シミュレーション開始
	sim_runner.start()

	_update_hud()


func _process(delta: float) -> void:
	_handle_input()
	_update_element_views()
	_update_hud()

	# 砲弾の更新
	if projectile_manager:
		projectile_manager.update_projectiles(delta)


func _setup_systems() -> void:
	# SimRunner
	sim_runner = SimRunner.new()
	sim_runner.name = "SimRunner"
	add_child(sim_runner)

	# WorldModel
	world_model = WorldModel.new()

	# SymbolManager
	symbol_manager = SymbolManager.new()
	symbol_manager.preload_all_symbols()

	# NavigationManager
	nav_manager = NavigationManager.new()
	nav_manager.name = "NavigationManager"
	add_child(nav_manager)

	# MovementSystem
	movement_system = MovementSystem.new()

	# VisionSystem
	vision_system = VisionSystem.new()

	# CombatSystem
	combat_system = CombatSystem.new()

	# CombatEventBus
	event_bus = CombatEventBus.new()

	# CombatVisualizer
	combat_visualizer = CombatVisualizer.new()
	combat_visualizer.name = "CombatVisualizer"

	# CaptureSystem
	capture_system = CaptureSystem.new()

	# ProjectileManager
	projectile_manager = ProjectileManager.new()
	projectile_manager.name = "ProjectileManager"
	projectile_manager.projectile_impact.connect(_on_projectile_impact)

	# TacticalOverlay
	tactical_overlay = TacticalOverlay.new()
	tactical_overlay.name = "TacticalOverlay"

	# DataLinkSystem
	data_link_system = DataLinkSystemClass.new()

	# TransportSystem
	transport_system = TransportSystemClass.new()
	transport_system.setup(world_model)


func _load_test_map_async() -> void:
	var map_path := "res://maps/MVP_01_CROSSROADS/"
	map_data = MapLoader.load_map(map_path)

	if map_data:
		print("マップ読み込み完了: " + map_data.map_id)
		print("  拠点数: " + str(map_data.capture_points.size()))
		print("  地形ゾーン数: " + str(map_data.terrain_zones.size()))

		# 拠点の初期状態を設定
		for cp in map_data.capture_points:
			cp.initialize_control()
			print("  CP %s: owner=%d" % [cp.id, cp.initial_owner])

		_setup_map_visuals()
		_setup_capture_point_views()

		# MovementSystem をセットアップ (nav_managerへの参照を先に設定)
		movement_system.setup(nav_manager, map_data, world_model)

		# VisionSystem をセットアップ（DataLinkSystemと連携）
		vision_system.setup(world_model, map_data, data_link_system)

		# ナビゲーション構築 (完了を待機)
		await nav_manager.build_from_map_data(map_data)
		print("ナビゲーション構築完了")
	else:
		push_error("マップ読み込み失敗")


func _setup_map_visuals() -> void:
	# 背景画像があれば読み込む
	var bg_path := "res://maps/MVP_01_CROSSROADS/" + map_data.background_file
	if ResourceLoader.exists(bg_path):
		var texture := load(bg_path) as Texture2D
		if texture:
			background_sprite = Sprite2D.new()
			background_sprite.texture = texture
			background_sprite.centered = false
			background_sprite.scale = Vector2(
				map_data.size_m.x / texture.get_width(),
				map_data.size_m.y / texture.get_height()
			)
			map_layer.add_child(background_sprite)
	else:
		_draw_placeholder_background()

	_draw_debug_markers()


func _draw_placeholder_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.3, 0.2)
	bg.size = map_data.size_m
	map_layer.add_child(bg)


func _draw_debug_markers() -> void:
	# 地形ゾーンのアウトライン
	for zone in map_data.terrain_zones:
		var outline := _create_zone_outline(zone)
		map_layer.add_child(outline)


func _setup_capture_point_views() -> void:
	# 拠点ビューを作成
	for cp in map_data.capture_points:
		var cp_view := CapturePointView.new(cp)
		cp_view.name = "CP_" + cp.id
		units_layer.add_child(cp_view)
		_cp_views[cp.id] = cp_view


func _setup_camera() -> void:
	camera.position = map_data.size_m / 2 if map_data else Vector2(1000, 1000)
	camera.zoom = Vector2(0.5, 0.5)


func _connect_signals() -> void:
	sim_runner.tick_advanced.connect(_on_tick_advanced)
	sim_runner.speed_changed.connect(_on_speed_changed)
	world_model.element_added.connect(_on_element_added)
	world_model.element_removed.connect(_on_element_removed)

# =============================================================================
# テストユニット生成
# =============================================================================

func _spawn_test_units() -> void:
	# ElementFactoryを使用してユニットを生成
	ElementFactory.reset_id_counters()

	# VehicleCatalogを初期化
	ElementFactory.init_vehicle_catalog()
	var catalog = ElementFactory.get_vehicle_catalog()
	if catalog and catalog.is_loaded():
		print("[VehicleCatalog] Loaded %d vehicles" % catalog.get_all_vehicle_ids().size())

	# === BLUE陣営 (自衛隊) - 全ユニット配置テスト ===
	# 全ユニットHOLD FIRE

	# --- 歩兵 ---
	var blue_inf := ElementFactory.create_element("INF_LINE", GameEnums.Faction.BLUE, Vector2(200, 500))
	blue_inf.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_inf)

	var blue_inf_at := ElementFactory.create_element("INF_AT", GameEnums.Faction.BLUE, Vector2(250, 500))
	blue_inf_at.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_inf_at)

	var blue_inf_mg := ElementFactory.create_element("INF_MG", GameEnums.Faction.BLUE, Vector2(300, 500))
	blue_inf_mg.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_inf_mg)

	# --- 戦車 ---
	var blue_type10 := ElementFactory.create_element_with_vehicle("JPN_Type10", GameEnums.Faction.BLUE, Vector2(100, 400))
	blue_type10.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type10)

	var blue_type90 := ElementFactory.create_element_with_vehicle("JPN_Type90", GameEnums.Faction.BLUE, Vector2(150, 400))
	blue_type90.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type90)

	# --- IFV/装甲車 ---
	var blue_type89 := ElementFactory.create_element_with_vehicle("JPN_Type89", GameEnums.Faction.BLUE, Vector2(200, 400))
	blue_type89.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type89)

	var blue_type24_ifv := ElementFactory.create_element_with_vehicle("JPN_Type24_IFV", GameEnums.Faction.BLUE, Vector2(250, 400))
	blue_type24_ifv.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type24_ifv)

	# --- 機動戦闘車 ---
	var blue_type16 := ElementFactory.create_element_with_vehicle("JPN_Type16", GameEnums.Faction.BLUE, Vector2(300, 400))
	blue_type16.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type16)

	# --- 偵察車 ---
	var blue_type87_rcv := ElementFactory.create_element_with_vehicle("JPN_Type87_RCV", GameEnums.Faction.BLUE, Vector2(350, 400))
	blue_type87_rcv.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type87_rcv)

	var blue_type25_rcv := ElementFactory.create_element_with_vehicle("JPN_Type25_RCV", GameEnums.Faction.BLUE, Vector2(400, 400))
	blue_type25_rcv.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type25_rcv)

	# --- APC ---
	var blue_type96 := ElementFactory.create_element_with_vehicle("JPN_Type96_WAPC", GameEnums.Faction.BLUE, Vector2(100, 300))
	blue_type96.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type96)

	var blue_type73 := ElementFactory.create_element_with_vehicle("JPN_Type73_APC", GameEnums.Faction.BLUE, Vector2(150, 300))
	blue_type73.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type73)

	var blue_patria := ElementFactory.create_element_with_vehicle("JPN_Patria_AMV", GameEnums.Faction.BLUE, Vector2(200, 300))
	blue_patria.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_patria)

	var blue_lav := ElementFactory.create_element_with_vehicle("JPN_LAV", GameEnums.Faction.BLUE, Vector2(250, 300))
	blue_lav.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_lav)

	var blue_aav7 := ElementFactory.create_element_with_vehicle("JPN_AAV7", GameEnums.Faction.BLUE, Vector2(300, 300))
	blue_aav7.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_aav7)

	# --- 指揮通信車 ---
	var blue_type82 := ElementFactory.create_element_with_vehicle("JPN_Type82_CCV", GameEnums.Faction.BLUE, Vector2(200, 950))
	blue_type82.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type82)

	# --- 砲兵 ---
	var blue_type99_sph := ElementFactory.create_element_with_vehicle("JPN_Type99_SPH", GameEnums.Faction.BLUE, Vector2(100, 900))
	blue_type99_sph.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type99_sph)

	var blue_type19_sph := ElementFactory.create_element_with_vehicle("JPN_Type19_SPH", GameEnums.Faction.BLUE, Vector2(150, 900))
	blue_type19_sph.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type19_sph)

	var blue_type24_mortar := ElementFactory.create_element_with_vehicle("JPN_Type24_Mortar", GameEnums.Faction.BLUE, Vector2(200, 900))
	blue_type24_mortar.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type24_mortar)

	# --- 防空 ---
	var blue_type87_spaag := ElementFactory.create_element_with_vehicle("JPN_Type87_SPAAG", GameEnums.Faction.BLUE, Vector2(100, 850))
	blue_type87_spaag.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type87_spaag)

	var blue_type93_sam := ElementFactory.create_element_with_vehicle("JPN_Type93_SAM", GameEnums.Faction.BLUE, Vector2(150, 850))
	blue_type93_sam.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type93_sam)

	var blue_type11_sam := ElementFactory.create_element_with_vehicle("JPN_Type11_SAM", GameEnums.Faction.BLUE, Vector2(200, 850))
	blue_type11_sam.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(blue_type11_sam)

	# === RED陣営 (ロシア) - 全てHOLD FIRE ===
	# 歩兵小隊×1
	var red_inf := ElementFactory.create_element("INF_LINE", GameEnums.Faction.RED, Vector2(750, 250))
	red_inf.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(red_inf)

	# BMP-3×1（IFV）
	var red_ifv := ElementFactory.create_element_with_vehicle("RUS_BMP3", GameEnums.Faction.RED, Vector2(850, 200))
	red_ifv.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(red_ifv)

	# T-90M戦車×1
	var red_tank := ElementFactory.create_element_with_vehicle("RUS_T90M", GameEnums.Faction.RED, Vector2(800, 150))
	red_tank.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	world_model.add_element(red_tank)

	# スポーン後に衝突を解消
	for element in world_model.elements:
		movement_system.resolve_hard_collisions(element)

	print("テストユニット生成完了: ", world_model.elements.size(), " elements")
	print("=== BLUE陣営 (自衛隊) - 全ユニット配置テスト ===")
	print("  歩兵: INF_LINE, INF_AT, INF_MG")
	print("  戦車: 10式, 90式")
	print("  IFV: 89式, 24式IFV")
	print("  機動戦闘車: 16式")
	print("  偵察: 87式RCV, 25式RCV")
	print("  APC: 96式, 73式, パトリア, LAV, AAV7")
	print("  指揮: 82式CCV")
	print("  砲兵: 99式SPH, 19式SPH, 24式迫撃砲")
	print("  防空: 87式SPAAG, 93式SAM, 11式SAM")
	print("  ※全ユニットHOLD FIRE")
	print("=== RED陣営 (ロシア) - 全てHOLD FIRE ===")
	print("  歩兵 + BMP-3 + T-90M")
	print("==========================================")
	for element in world_model.elements:
		var weapons_str := ""
		for w in element.weapons:
			weapons_str += w.id + " "
		var extra_info := ""
		if element.element_type and element.element_type.armor_class > 0:
			extra_info = " (ArmorClass=%d)" % element.element_type.armor_class
		if element.element_type and element.element_type.is_comm_hub:
			extra_info += " [COMM_HUB: range=%dm]" % int(element.element_type.comm_range)
		if element.vehicle_id != "":
			extra_info += " [Vehicle: %s]" % element.vehicle_id
		print("  %s (%s): Str=%d, Weapons=[%s], primary=%s%s" % [
			element.id,
			element.element_type.display_name if element.element_type else "?",
			element.current_strength,
			weapons_str.strip_edges(),
			element.primary_weapon.id if element.primary_weapon else "NONE",
			extra_info
		])

	# コマンダーAIをセットアップ（簡易版）
	_setup_commander_ais()
	print("[AI Mode] コマンダーAI（簡易版）")


func _setup_commander_ais() -> void:
	# RED陣営のコマンダーAIを作成（AGGRESSIVEモード）
	var red_ai = CommanderAIClass.new()
	red_ai.faction = GameEnums.Faction.RED
	red_ai.setup(world_model, vision_system, movement_system)
	red_ai.set_mode(CommanderAIClass.AIMode.AGGRESSIVE)

	# BLUE陣営の中心に向かって前進
	var blue_elements := world_model.get_elements_for_faction(GameEnums.Faction.BLUE)
	if blue_elements.size() > 0:
		var blue_center := Vector2.ZERO
		for element in blue_elements:
			blue_center += element.position
		blue_center /= blue_elements.size()
		red_ai.set_advance_target(blue_center)

	commander_ais[GameEnums.Faction.RED] = red_ai
	print("[CommanderAI] RED -> AGGRESSIVE mode")

	# BLUE陣営もCommanderAIを作成（PASSIVEモード = プレイヤー操作サポート）
	# AIは自動行動せず、RightPanelでの状態表示用
	var blue_ai = CommanderAIClass.new()
	blue_ai.faction = GameEnums.Faction.BLUE
	blue_ai.setup(world_model, vision_system, movement_system)
	blue_ai.set_mode(CommanderAIClass.AIMode.PASSIVE)
	commander_ais[GameEnums.Faction.BLUE] = blue_ai
	print("[CommanderAI] BLUE -> PASSIVE mode (player control)")


func _setup_company_ais() -> void:
	# 各陣営の中隊AIを作成
	for faction_value in [GameEnums.Faction.BLUE, GameEnums.Faction.RED]:
		var company_ai = CompanyControllerAIClass.new()
		company_ai.faction = faction_value
		company_ai.setup(world_model, map_data, vision_system, movement_system, event_bus)

		# 陣営のElementを登録
		var faction_elements := world_model.get_elements_for_faction(faction_value)
		var element_ids: Array[String] = []
		for element in faction_elements:
			element_ids.append(element.id)
		company_ai.set_elements(element_ids)

		company_ais[faction_value] = company_ai

		print("中隊AI作成: ", "BLUE" if faction_value == GameEnums.Faction.BLUE else "RED",
			" (", element_ids.size(), " elements)")

	# 敵AI（RED）に初期命令を出す
	_issue_initial_ai_orders()


## 敵AIに初期命令を発行
func _issue_initial_ai_orders() -> void:
	var red_ai = company_ais.get(GameEnums.Faction.RED)
	if not red_ai:
		return

	# RED陣営のCPを探す（防御対象）
	# または中立/BLUE CPを探す（攻撃対象）
	var red_cp: MapData.CapturePoint = null
	var attack_target_cp: MapData.CapturePoint = null

	for cp in map_data.capture_points:
		if cp.initial_owner == GameEnums.Faction.RED:
			red_cp = cp
		elif cp.initial_owner == GameEnums.Faction.NONE or cp.initial_owner == GameEnums.Faction.BLUE:
			if not attack_target_cp:
				attack_target_cp = cp

	# REDの初期行動：中立CPを攻撃、なければ自CPを防御
	if attack_target_cp:
		red_ai.order_attack_cp(attack_target_cp.id)
		print("[CompanyAI] RED -> ATTACK_CP %s (初期命令)" % attack_target_cp.id)
	elif red_cp:
		red_ai.order_defend_cp(red_cp.id)
		print("[CompanyAI] RED -> DEFEND_CP %s (初期命令)" % red_cp.id)

# =============================================================================
# Element表示
# =============================================================================

func _on_element_added(element: ElementData.ElementInstance) -> void:
	var view := ElementView.new()
	# setupで味方はCONFIRMED（表示）、敵はUNKNOWN（非表示）に設定される
	view.setup(element, symbol_manager, player_faction)
	# 搭乗中の歩兵は非表示
	if element.is_embarked:
		view.visible = false
	units_layer.add_child(view)
	_element_views[element.id] = view


func _on_element_removed(element: ElementData.ElementInstance) -> void:
	if element.id in _element_views:
		var view: ElementView = _element_views[element.id]
		view.queue_free()
		_element_views.erase(element.id)


## 砲弾着弾時のダメージ適用（遅延ダメージモデル）
func _on_projectile_impact(target_id: String, damage_info: Dictionary) -> void:
	var target := world_model.get_element_by_id(target_id)
	if not target:
		print("[Main] WARNING: Target %s not found for projectile impact" % target_id)
		return

	var current_tick: int = sim_runner.tick_index if sim_runner else 0
	combat_system.apply_tank_damage_result(target, damage_info, current_tick)


## プレイヤー陣営に生存中のユニットがいるか確認
func _has_alive_friendly_unit() -> bool:
	for element in world_model.elements:
		if element.faction == player_faction and not element.is_destroyed:
			return true
	return false


func _update_element_views() -> void:
	var alpha := sim_runner.alpha if sim_runner else 0.0
	var current_tick: int = sim_runner.tick_index if sim_runner else 0

	var elements_to_remove: Array[String] = []

	for element_id in _element_views:
		var view: ElementView = _element_views[element_id]
		var element := view.element

		if not element:
			continue

		# 破壊済みユニットのフェードアウト処理
		if element.is_destroyed:
			# フェード開始
			if not view.is_fading():
				view.start_fade_out(element.destroy_tick)

			# フェード更新（完全に消えたら削除リストに追加）
			if view.update_fade(current_tick):
				elements_to_remove.append(element_id)
			view.queue_redraw()
			continue

		# FoW状態を更新（VisionSystemベース）
		# プレイヤー側のユニットは常に表示
		# 敵ユニットはVisionSystemのContact状態に基づく
		if element.faction == player_faction:
			view.update_contact_state(GameEnums.ContactState.CONFIRMED)
		else:
			# VisionSystemからContact状態を取得
			var contact := vision_system.get_contact(player_faction, element_id)
			if contact:
				# Contact状態と推定位置を反映
				view.update_contact_state(contact.state, contact.pos_est_m, contact.pos_error_m)
			else:
				# 接触なし = UNKNOWN（非表示）
				view.update_contact_state(GameEnums.ContactState.UNKNOWN)

		# 位置更新（FoW考慮）
		view.update_position_with_fow(alpha)
		view.queue_redraw()

	# 完全消滅したElementを削除
	for element_id in elements_to_remove:
		var element := world_model.get_element_by_id(element_id)
		if element:
			# 選択中なら選択解除
			if element in _selected_elements:
				_selected_elements.erase(element)
				_update_selection_ui()
			world_model.remove_element(element)

# =============================================================================
# 入力処理
# =============================================================================

func _handle_input() -> void:
	_handle_camera_input()
	_handle_debug_input()


## デバッグ入力処理
var _reset_pending: bool = false

func _handle_debug_input() -> void:
	# Rキーでリセット（1回だけ実行）
	if Input.is_physical_key_pressed(KEY_R) and not _reset_pending:
		_reset_pending = true
		call_deferred("_reset_scene")


func _handle_camera_input() -> void:
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1
	if Input.is_action_pressed("ui_up"):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_dir.y += 1

	if move_dir != Vector2.ZERO:
		camera.position += move_dir.normalized() * 500 * get_process_delta_time() / camera.zoom.x

	if Input.is_action_just_pressed("ui_page_up"):
		camera.zoom *= 1.2
	if Input.is_action_just_pressed("ui_page_down"):
		camera.zoom /= 1.2
	camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))


func _get_world_mouse_position() -> Vector2:
	var viewport_mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var canvas_xform_inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	return canvas_xform_inv * viewport_mouse_pos


func _get_element_at_position(pos: Vector2) -> ElementData.ElementInstance:
	for element_id in _element_views:
		var view: ElementView = _element_views[element_id]
		if view.contains_point(pos):
			return view.element
	return null


func _clear_selection() -> void:
	for element in _selected_elements:
		if element.id in _element_views:
			_element_views[element.id].set_selected(false)
	_selected_elements.clear()
	_update_selection_ui()


func _add_to_selection(element: ElementData.ElementInstance) -> void:
	if element not in _selected_elements:
		_selected_elements.append(element)
		if element.id in _element_views:
			_element_views[element.id].set_selected(true)
		_update_selection_ui()


func _update_selection_ui() -> void:
	if hud_manager:
		hud_manager.set_selected_elements(_selected_elements)
	if tactical_overlay:
		tactical_overlay.set_selected_elements(_selected_elements)

# =============================================================================
# Tick処理
# =============================================================================

func _on_tick_advanced(tick: int) -> void:
	# デバッグ（10秒ごと）
	if tick % 100 == 0:
		print("[Tick] %d" % tick)

	# 全Elementの状態を保存
	world_model.save_prev_states()

	# データリンク状態を更新（HQの通信範囲内はLINKED、範囲外はISOLATED）
	if data_link_system:
		data_link_system.update_comm_states(world_model.elements)

	# ATTACK命令中のユニットの移動制御
	_update_attack_movement()

	# 移動更新（衝突回避含む）
	for element in world_model.elements:
		movement_system.update_element(element, GameConstants.SIM_DT)

	# 搭乗中の歩兵の位置を輸送車両に同期
	if transport_system:
		transport_system.sync_embarked_positions()

	# 乗車移動中の歩兵が車両に到達したら乗車完了
	_update_boarding()

	# 下車移動完了チェック
	_update_unloading()

	# 静止ユニットの衝突回避
	for element in world_model.elements:
		if not element.is_moving and element.state != GameEnums.UnitState.DESTROYED:
			movement_system.apply_separation(element, GameConstants.SIM_DT)

	# 視界更新
	vision_system.update(tick, GameConstants.SIM_DT)

	# 戦闘更新
	_update_combat(tick, GameConstants.SIM_DT)

	# 拠点制圧更新（コンクエストモード用）
	# _update_capture(tick)

	# コマンダーAI更新
	_update_commander_ais(tick)

	# 中隊AI更新（現在無効）
	# _update_company_ais(tick)


## 乗車移動中の歩兵が車両に到達したら乗車を完了する
func _update_boarding() -> void:
	if not transport_system:
		return

	for element in world_model.elements:
		# 乗車移動中の歩兵をチェック
		if element.boarding_target_id.is_empty():
			continue
		if element.is_embarked:
			continue

		# 目標車両を取得
		var transport := world_model.get_element_by_id(element.boarding_target_id)
		if not transport:
			# 車両が存在しない場合はキャンセル
			element.boarding_target_id = ""
			continue

		# 車両が破壊されている場合はキャンセル
		if transport.state == GameEnums.UnitState.DESTROYED:
			element.boarding_target_id = ""
			transport.awaiting_boarding_id = ""
			movement_system.issue_stop_order(element)
			print("[Board] %s: target %s destroyed, boarding cancelled" % [element.id, transport.id])
			continue

		# 車両に既に歩兵が乗っている場合はキャンセル
		if not transport.embarked_infantry_id.is_empty():
			element.boarding_target_id = ""
			transport.awaiting_boarding_id = ""
			movement_system.issue_stop_order(element)
			print("[Board] %s: target %s already has infantry, boarding cancelled" % [element.id, transport.id])
			continue

		# 距離をチェック（乗車距離に到達したら乗車完了）
		var distance := element.position.distance_to(transport.position)
		if distance <= TransportSystemClass.BOARD_RANGE * 0.5:  # 乗車距離の半分で乗車
			# 乗車実行
			if transport_system.board_infantry(element, transport):
				element.boarding_target_id = ""
				transport.awaiting_boarding_id = ""
				# 歩兵を非表示に
				if element.id in _element_views:
					var view: ElementView = _element_views[element.id]
					view.visible = false
				# 乗車完了後、選択を歩兵から車両に切り替え
				if element in _selected_elements:
					_selected_elements.erase(element)
					_add_to_selection(transport)
				print("[Board] %s boarded %s" % [element.id, transport.id])
			else:
				# 乗車失敗（車両が移動したなど）
				element.boarding_target_id = ""
				transport.awaiting_boarding_id = ""
				movement_system.issue_stop_order(element)
				print("[Board] %s: boarding %s failed" % [element.id, transport.id])


## 下車移動中の歩兵が目標位置に到達したらフラグをクリア
func _update_unloading() -> void:
	for element in world_model.elements:
		# 下車移動中の歩兵をチェック
		if element.unloading_target_pos == Vector2.ZERO:
			continue

		# 移動が完了したか、目標位置に十分近づいたらクリア
		if not element.is_moving:
			element.unloading_target_pos = Vector2.ZERO
			print("[Unload] %s reached unload position" % element.id)
			continue

		# 目標位置との距離をチェック
		var distance := element.position.distance_to(element.unloading_target_pos)
		if distance < 5.0:  # 5m以内なら到着とみなす
			element.unloading_target_pos = Vector2.ZERO
			print("[Unload] %s reached unload position (%.1fm)" % [element.id, distance])


func _update_combat(tick: int, dt: float) -> void:

	# 被弾中フラグを追跡
	var elements_under_fire: Dictionary = {}  # element_id -> bool

	# 射撃中のユニットを追跡（射撃終了時にcurrent_target_idをクリアするため）
	var shooters_firing: Dictionary = {}  # element_id -> bool

	# === 間接射撃の着弾処理 ===
	_process_pending_indirect_impacts(tick)

	# === 砲兵展開・撤収処理 ===
	_process_artillery_deployment(dt)

	# === 間接射撃処理（砲兵ユニット） ===
	_process_indirect_fire(tick, elements_under_fire, shooters_firing)

	# === 直接射撃処理 ===
	for shooter in world_model.elements:
		if shooter.state == GameEnums.UnitState.DESTROYED:
			continue
		if shooter.state == GameEnums.UnitState.BROKEN:
			continue  # Brokenは射撃不可
		if not shooter.primary_weapon:
			continue
		if shooter.sop_mode == GameEnums.SOPMode.HOLD_FIRE:
			continue
		# RETURN_FIRE: 被弾後一定時間のみ射撃許可
		if shooter.sop_mode == GameEnums.SOPMode.RETURN_FIRE:
			const RETURN_FIRE_TIMEOUT := 300  # 30秒 = 300tick
			if shooter.last_hit_tick <= 0:
				continue  # 攻撃されていない
			var ticks_since_hit := tick - shooter.last_hit_tick
			if ticks_since_hit > RETURN_FIRE_TIMEOUT:
				continue  # タイムアウト

		# 射撃対象を選択
		var target := _select_target(shooter, tick)
		if not target:
			# デバッグ: 100tickごとにターゲットが見つからないユニットを報告
			if tick % 100 == 0:
				var contacts := vision_system.get_contacts_for_faction(shooter.faction)
				var fireable := vision_system.get_fireable_targets(shooter)
				var confirmed_count := 0
				for c in contacts:
					if c.state == GameEnums.ContactState.CONFIRMED:
						confirmed_count += 1
				print("[NoTarget] %s (faction=%d): contacts=%d (conf=%d), fireable=%d, supp=%.2f" % [
					shooter.id, shooter.faction, contacts.size(), confirmed_count, fireable.size(),
					shooter.suppression
				])
				# 詳細デバッグ: 敵ユニットとの距離と視界
				var enemy_faction := GameEnums.Faction.BLUE if shooter.faction == GameEnums.Faction.RED else GameEnums.Faction.RED
				var enemies := world_model.get_elements_for_faction(enemy_faction)
				for enemy in enemies:
					if enemy.state == GameEnums.UnitState.DESTROYED:
						continue
					var dist := shooter.position.distance_to(enemy.position)
					# 実効視界を取得（VisionSystemの計算を使用）
					var r_eff := vision_system.get_effective_range_for_target(shooter, enemy) if vision_system else 0.0
					var r_base := shooter.element_type.spot_range_base if shooter.element_type else 0.0
					var can_fire := vision_system.can_fire_at(shooter, enemy.id) if vision_system else false
					print("    -> %s: dist=%.0fm, r_eff=%.0fm (base=%.0f), can_fire=%s" % [
						enemy.id, dist, r_eff, r_base, can_fire
					])
			continue

		# 射撃実行
		var distance := shooter.position.distance_to(target.position)
		var terrain := map_data.get_terrain_at(target.position) if map_data else GameEnums.TerrainType.OPEN

		# LoS取得（簡易版：距離と地形から推定）
		var t_los := _estimate_los(shooter, target)

		# 最適武器を選択
		var selected_weapon := combat_system.select_best_weapon(shooter, target, distance, false)
		if not selected_weapon:
			continue

		# 現在使用中の武器を記録（HUD表示用）
		shooter.current_weapon = selected_weapon

		# ターゲットを選択した時点でロックオン表示用にIDをセット
		shooter.current_target_id = target.id
		shooters_firing[shooter.id] = true

		# 装甲目標かどうかで計算方法を分岐
		var d_supp: float = 0.0
		var d_dmg: float = 0.0
		var is_valid: bool = false

		# v0.2: 戦車戦モデルを使用するか判定
		if combat_system.should_use_tank_combat(shooter, target, selected_weapon):
			# 戦車対重装甲: v0.2離散発砲モデル
			var tank_result := combat_system.process_tank_engagement(
				shooter, target, selected_weapon, distance, tick
			)

			# 射撃中フラグを維持（リロード中でも照準は維持）
			shooter.current_target_id = target.id
			shooters_firing[shooter.id] = true

			if tank_result.fired:
				# 砲弾発射エフェクト（遅延ダメージ付き）
				if projectile_manager and selected_weapon.projectile_speed_mps > 0:
					# ダメージ情報を構築（着弾時に適用される）
					var damage_info := {
						"hit": tank_result.hit,
						"kill": tank_result.kill,
						"mission_kill": tank_result.mission_kill,
						"catastrophic": tank_result.catastrophic,
						"aspect": tank_result.aspect,
						"shooter_id": shooter.id,
						"p_kill": tank_result.p_kill,
						"threat_class": selected_weapon.threat_class
					}
					projectile_manager.fire_projectile_with_damage(
						shooter.position,
						target.position,
						selected_weapon,
						shooter.faction,
						target.id,
						damage_info
					)

				if tank_result.hit:
					elements_under_fire[target.id] = true
					is_valid = true
					# 戦車戦では抑圧もヒット時に適用（抑圧は即時、ダメージは着弾時）
					d_supp = GameConstants.K_DF_SUPP
					combat_system.apply_damage(target, d_supp, 0.0, tick, selected_weapon.threat_class)

					# 戦闘可視化（ヒット）
					if combat_visualizer:
						combat_visualizer.add_fire_event(
							shooter.id,
							target.id,
							shooter.position,
							target.position,
							shooter.faction,
							1.0 if tank_result.kill else 0.5,  # ダメージ表示用
							d_supp,
							true,
							selected_weapon.mechanism,
							selected_weapon.fire_model
						)
				else:
					# ミス時も射線は表示
					if combat_visualizer:
						combat_visualizer.add_fire_event(
							shooter.id,
							target.id,
							shooter.position,
							target.position,
							shooter.faction,
							0.0,
							0.0,
							false,
							selected_weapon.mechanism,
							selected_weapon.fire_model
						)
			# リロード中は射線を表示しない（照準維持のみ）
			continue  # 戦車戦は専用処理で完結

		else:
			# 非戦車戦v0.2: DISCRETE武器の発射レート制御
			var can_fire := true
			if selected_weapon.fire_model == WeaponData.FireModel.DISCRETE:
				if shooter.last_fire_tick >= 0 and selected_weapon.rof_rpm > 0:
					var ticks_per_shot := int(600.0 / selected_weapon.rof_rpm)
					var elapsed := tick - shooter.last_fire_tick
					if elapsed < ticks_per_shot:
						can_fire = false

			if not can_fire:
				shooter.current_target_id = target.id
				continue

			if target.is_armored_vehicle():
				# 装甲目標: v0.1R ゾーン別装甲・貫徹判定を使用
				var result_armor := combat_system.calculate_direct_fire_vs_armor(
					shooter, target, selected_weapon, distance, dt, t_los, terrain, false
				)
				is_valid = result_armor.is_valid
				d_supp = result_armor.d_supp
				# 可視化用にd_dmgを保持（装甲ダメージはapply_vehicle_damageで処理）
				d_dmg = result_armor.d_dmg

				# CONTINUOUS武器（機関砲等）: 累積ダメージモデル
				if result_armor.is_continuous:
					# 累積ダメージを蓄積し、閾値を超えたら車両ダメージを適用
					target.accumulated_armor_damage += result_armor.d_dmg
					if target.accumulated_armor_damage >= 1.0:
						# 閾値を超えたらダメージ適用
						combat_system.apply_vehicle_damage(
							target,
							selected_weapon.threat_class,
							result_armor.exposure,
							tick
						)
						target.accumulated_armor_damage -= 1.0
				else:
					# DISCRETE武器: 離散ヒットモデル（p_hitでダメージ発生を判定）
					var roll := randf()
					var did_hit := result_armor.p_hit > 0 and roll < result_armor.p_hit
					if did_hit:
						# ヒット時は車両ダメージ処理
						combat_system.apply_vehicle_damage(
							target,
							selected_weapon.threat_class,
							result_armor.exposure,
							tick
						)
				# 装甲ダメージはapply_vehicle_damageで処理済み
				# apply_damageでは抑圧のみ適用（d_dmgは可視化用に保持、apply_d_dmgで0にする）

			else:
				# 非装甲目標: 従来の計算
				var result := combat_system.calculate_direct_fire_effect(
					shooter, target, selected_weapon, distance, dt, t_los, terrain, false
				)
				is_valid = result.is_valid
				d_supp = result.d_supp
				d_dmg = result.d_dmg

		if is_valid:
			# 可視化用の値を保存（apply_damageで使う値とは別）
			var visual_d_dmg := d_dmg
			var visual_d_supp := d_supp

			# 装甲目標の場合、d_dmgはapply_vehicle_damageで処理済みなので0にする
			# （二重適用を防ぐ）
			var apply_d_dmg := d_dmg
			if target.is_armored_vehicle():
				apply_d_dmg = 0.0  # 装甲ダメージはapply_vehicle_damageで処理済み

			# 抑圧とダメージを適用（threat_classを渡して車両の抑圧上限を適用）
			var threat_class := selected_weapon.threat_class if selected_weapon else WeaponData.ThreatClass.SMALL_ARMS
			combat_system.apply_damage(target, d_supp, apply_d_dmg, tick, threat_class)

			elements_under_fire[target.id] = true
			shooter.last_fire_tick = tick
			shooter.current_target_id = target.id
			shooters_firing[shooter.id] = true

			# 戦闘可視化
			# 有効な射撃は命中扱い（継続的なダメージ/抑圧）
			# 抑圧のみの場合も射線は実線で表示
			var is_hit := (visual_d_dmg > 0.0 or visual_d_supp > 0.0)
			var weapon_mechanism := selected_weapon.mechanism if selected_weapon else WeaponData.Mechanism.SMALL_ARMS
			var weapon_fire_model := selected_weapon.fire_model if selected_weapon else WeaponData.FireModel.CONTINUOUS
			if combat_visualizer:
				combat_visualizer.add_fire_event(
					shooter.id,
					target.id,
					shooter.position,
					target.position,
					shooter.faction,
					visual_d_dmg,
					visual_d_supp,
					is_hit,
					weapon_mechanism,
					weapon_fire_model
				)

			# DISCRETE武器の砲弾発射
			if selected_weapon.fire_model == WeaponData.FireModel.DISCRETE:
				if projectile_manager and selected_weapon.projectile_speed_mps > 0:
					projectile_manager.fire_projectile(
						shooter.position,
						target.position,
						selected_weapon,
						shooter.faction,
						is_hit
					)

			# デバッグ出力（100tickごと）
			if tick % 100 == 0:
				var armor_str := " (ARMORED)" if target.is_armored_vehicle() else ""
				var weapon_name := selected_weapon.id if selected_weapon else "NONE"
				var accum_str := ""
				if target.is_armored_vehicle() and selected_weapon and selected_weapon.fire_model == WeaponData.FireModel.CONTINUOUS:
					accum_str = " accum=%.3f" % target.accumulated_armor_damage
				print("[Combat] %s -> %s%s [%s]: supp=%.2f dmg=%.2f%s" % [shooter.id, target.id, armor_str, weapon_name, d_supp, d_dmg, accum_str])

	# 射撃していないユニットの current_target_id をクリア
	for element in world_model.elements:
		if not shooters_firing.has(element.id):
			element.current_target_id = ""

	# 抑圧回復を適用
	for element in world_model.elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		var is_under_fire: bool = elements_under_fire.get(element.id, false)
		var is_defending := element.current_order_type == GameEnums.OrderType.DEFEND
		var comm_state := element.comm_state

		combat_system.apply_suppression_recovery(
			element, is_under_fire, comm_state, is_defending, dt
		)


## ATTACK命令中のユニットの移動を制御
## 強制目標が射撃可能になったら停止、射撃不可なら追跡
func _update_attack_movement() -> void:
	for element in world_model.elements:
		# ATTACK命令で強制目標がある場合のみ
		if element.current_order_type != GameEnums.OrderType.ATTACK:
			continue
		if element.forced_target_id == "":
			continue

		var target := world_model.get_element_by_id(element.forced_target_id)
		if not target or target.state == GameEnums.UnitState.DESTROYED:
			# 目標が無効になったら強制目標をクリア
			element.forced_target_id = ""
			element.order_target_id = ""
			continue

		# VisionSystemで射撃可能か判定（視界範囲 + DataLink考慮）
		var can_fire := vision_system.can_fire_at(element, element.forced_target_id) if vision_system else false

		if can_fire:
			# 射撃可能：移動停止
			if element.is_moving:
				element.current_path = PackedVector2Array()
				element.is_moving = false
				element.velocity = Vector2.ZERO
		else:
			# 射撃不可：目標に向かって移動（まだ移動していない場合）
			if not element.is_moving:
				movement_system.issue_move_order(element, target.position, false)
			else:
				# 既に移動中なら、目標位置を更新（追跡）
				# 現在の目標と差が大きい場合のみ再計算
				var current_goal := element.order_target_position
				if current_goal.distance_to(target.position) > 50.0:
					movement_system.issue_move_order(element, target.position, false)


func _update_company_ais(tick: int) -> void:
	for faction in company_ais:
		var ai = company_ais[faction]

		# 毎tick更新（10Hz）
		ai.update_micro(tick, GameConstants.SIM_DT)

		# 接触評価（2Hz）
		ai.update_contact_eval(tick)

		# 戦術評価（1Hz）
		ai.update_tactical(tick)

		# 大局評価（0.2Hz）
		ai.update_operational(tick)


func _update_capture(tick: int) -> void:
	if not capture_system or not map_data:
		return

	# 拠点制圧を更新
	capture_system.update(world_model, map_data)

	# 10秒ごとにデバッグ出力
	if tick % 100 == 0:
		var cp_count := capture_system.get_controlled_count(map_data)
		print("[Capture] Blue=%d Red=%d" % [cp_count.blue, cp_count.red])
		for cp in map_data.capture_points:
			print("  %s" % capture_system.get_cp_state_string(cp))
			# CP内のユニット数を表示
			var power := capture_system.get_cp_effective_power(cp, world_model, map_data.cp_radius_m)
			if power.blue_contest > 0 or power.red_contest > 0:
				print("    Power: B_cap=%.2f B_neut=%.2f B_cont=%.2f | R_cap=%.2f R_neut=%.2f R_cont=%.2f" % [
					power.blue_capture, power.blue_neutralize, power.blue_contest,
					power.red_capture, power.red_neutralize, power.red_contest
				])


func _on_speed_changed(_new_speed: float) -> void:
	_update_hud()


func _update_commander_ais(tick: int) -> void:
	for faction in commander_ais:
		var ai = commander_ais[faction]
		ai.update(tick)

	# デバッグ出力（10秒ごと）
	if tick % 100 == 0:
		for faction in commander_ais:
			var ai = commander_ais[faction]
			print(ai.get_debug_info())


# =============================================================================
# HUD セットアップと更新
# =============================================================================

func _setup_hud() -> void:
	# HUDManager
	hud_manager = HUDManager.new()
	hud_manager.name = "HUDManager"
	ui_layer.add_child(hud_manager)
	hud_manager.setup(world_model, map_data, player_faction)

	# シグナル接続
	hud_manager.command_selected.connect(_on_hud_command_selected)
	hud_manager.pie_command_selected.connect(_on_pie_command_selected)
	hud_manager.unit_selected_from_list.connect(_on_unit_selected_from_list)
	hud_manager.minimap_clicked.connect(_on_minimap_clicked)
	hud_manager.sop_changed.connect(_on_sop_changed)

	# InputController
	input_controller = InputControllerClass.new()
	input_controller.name = "InputController"
	add_child(input_controller)
	input_controller.setup(camera, hud_manager.pie_menu, hud_manager)
	input_controller.set_selected_category_callback(_get_selected_unit_category)

	# シグナル接続
	input_controller.left_click.connect(_on_input_left_click)
	input_controller.right_click.connect(_on_input_right_click)
	input_controller.box_selection_ended.connect(_on_box_selection_ended)
	input_controller.command_hotkey_pressed.connect(_on_command_hotkey_pressed)
	input_controller.speed_change_requested.connect(_on_speed_change_requested)
	input_controller.camera_center_requested.connect(_on_camera_center_requested)
	input_controller.escape_pressed.connect(_on_escape_pressed)

	# OrderPreview
	order_preview = OrderPreviewClass.new()
	order_preview.name = "OrderPreview"
	units_layer.add_child(order_preview)


func _update_hud() -> void:
	if not sim_runner or not hud_manager:
		return

	# CommanderAI（簡易版）を渡す（CompanyControllerAIがない場合）
	var ai = commander_ais.get(player_faction)
	if not ai:
		ai = company_ais.get(player_faction)
	hud_manager.update_hud(sim_runner, ai)

	# カメラ範囲をミニマップに反映
	if hud_manager.minimap and get_viewport():
		var viewport_size := get_viewport().get_visible_rect().size
		var cam_rect := Rect2(
			camera.position - viewport_size / 2 / camera.zoom,
			viewport_size / camera.zoom
		)
		hud_manager.minimap.set_camera_rect(cam_rect)


# =============================================================================
# 選択ユニットヘルパー
# =============================================================================

## 選択中ユニットのカテゴリを取得（パイメニュー表示用）
func _get_selected_unit_category() -> String:
	if _selected_elements.is_empty():
		return ""

	# 最初の選択ユニットからカテゴリを取得
	var first_element := _selected_elements[0]
	if not first_element or not first_element.element_type:
		return ""

	var archetype := first_element.element_type.id
	return PieMenu.get_category_for_archetype(archetype)


# =============================================================================
# HUDシグナルハンドラ
# =============================================================================

func _on_hud_command_selected(command_type: GameEnums.OrderType, _world_pos: Vector2) -> void:
	# コマンドバーからのコマンド選択
	_execute_command_for_selected(command_type, _get_world_mouse_position())


func _on_pie_command_selected(command_type: GameEnums.OrderType, world_pos: Vector2) -> void:
	# Pie Menuからのコマンド選択
	# ATTACKコマンドの場合、その位置に敵がいれば目標指定
	if command_type == GameEnums.OrderType.ATTACK:
		var target_element := _get_element_at_position(world_pos)
		if target_element and target_element.faction != player_faction:
			_execute_attack_command(_selected_elements, target_element)
			return
	_execute_command_for_selected(command_type, world_pos)


func _on_sop_changed(new_sop: GameEnums.SOPMode) -> void:
	# 右パネルのSOPボタンからのSOP変更
	for element in _selected_elements:
		if element.faction != player_faction:
			continue
		_execute_sop_command(element, new_sop)

	# 右パネルの表示を更新
	if hud_manager and hud_manager.right_panel:
		hud_manager.right_panel.update_display(_selected_elements, company_ais.get(player_faction))


func _on_unit_selected_from_list(element_id: String) -> void:
	var element := world_model.get_element_by_id(element_id)
	if element:
		_clear_selection()
		_add_to_selection(element)


func _on_minimap_clicked(world_pos: Vector2) -> void:
	# カメラをその位置に移動
	camera.position = world_pos


# =============================================================================
# 入力シグナルハンドラ
# =============================================================================

func _on_input_left_click(world_pos: Vector2, _screen_pos: Vector2) -> void:
	var clicked_element := _get_element_at_position(world_pos)

	if clicked_element:
		if not input_controller.is_shift_held():
			_clear_selection()
		_add_to_selection(clicked_element)
	else:
		if not input_controller.is_shift_held():
			_clear_selection()


func _on_input_right_click(world_pos: Vector2, _screen_pos: Vector2) -> void:
	# スマートコマンド: 右クリック先に応じて自動判定
	if _selected_elements.size() == 0:
		return

	# 敵ユニットをクリックした場合は攻撃（目標ID指定）
	var target_element := _get_element_at_position(world_pos)
	if target_element and target_element.faction != player_faction:
		_execute_attack_command(_selected_elements, target_element)
		return

	# 拠点をクリックした場合（company_aiがある場合のみ）
	var cp := _get_cp_at_position(world_pos)
	if cp:
		var company_ai = company_ais.get(player_faction)
		if company_ai:
			if cp.initial_owner == player_faction or cp.initial_owner == GameEnums.Faction.NONE:
				company_ai.order_defend_cp(cp.id)
				print("[CompanyAI] BLUE -> DEFEND_CP %s" % cp.id)
			else:
				company_ai.order_attack_cp(cp.id)
				print("[CompanyAI] BLUE -> ATTACK_CP %s" % cp.id)
			return
		else:
			# company_aiがない場合は直接移動命令
			_execute_command_for_selected(GameEnums.OrderType.MOVE, cp.position)
			return

	# それ以外は移動（選択ユニットのみに直接命令）
	_execute_command_for_selected(GameEnums.OrderType.MOVE, world_pos)


func _on_box_selection_ended(start_pos: Vector2, end_pos: Vector2) -> void:
	if not input_controller.is_shift_held():
		_clear_selection()

	# スクリーン座標をワールド座標に変換
	var canvas_xform_inv := get_viewport().get_canvas_transform().affine_inverse()
	var world_start: Vector2 = canvas_xform_inv * start_pos
	var world_end: Vector2 = canvas_xform_inv * end_pos

	var rect := Rect2(
		Vector2(min(world_start.x, world_end.x), min(world_start.y, world_end.y)),
		Vector2(abs(world_end.x - world_start.x), abs(world_end.y - world_start.y))
	)

	# 範囲内の味方ユニットを選択
	for element in world_model.get_elements_for_faction(player_faction):
		if rect.has_point(element.position):
			_add_to_selection(element)


func _on_command_hotkey_pressed(command_type: GameEnums.OrderType) -> void:
	# ホットキーでコマンドモードに入る（次のクリックで実行）
	# TODO: コマンドモード実装
	print("Hotkey command: ", command_type)


func _on_speed_change_requested(speed: int) -> void:
	if speed == 0:
		sim_runner.pause()
	else:
		sim_runner.resume()
		sim_runner.set_speed(speed)


func _on_camera_center_requested() -> void:
	if _selected_elements.size() > 0:
		var center := Vector2.ZERO
		for element in _selected_elements:
			center += element.position
		center /= _selected_elements.size()
		camera.position = center


func _on_escape_pressed() -> void:
	_clear_selection()
	order_preview.hide_preview()


# =============================================================================
# コマンド実行
# =============================================================================

func _execute_command_for_selected(command_type: GameEnums.OrderType, target_pos: Vector2) -> void:
	if _selected_elements.size() == 0:
		return

	var use_road: bool = input_controller.is_alt_held()

	for element in _selected_elements:
		if element.faction != player_faction:
			continue

		match command_type:
			GameEnums.OrderType.MOVE:
				# 移動命令：強制目標をクリア、射撃任務も解除
				element.forced_target_id = ""
				element.current_order_type = GameEnums.OrderType.MOVE
				_cancel_fire_mission(element)
				movement_system.issue_move_order(element, target_pos, use_road)

			GameEnums.OrderType.ATTACK:
				# 攻撃命令（位置指定）：その位置へ移動しつつ交戦
				element.forced_target_id = ""  # 位置指定なので特定目標なし
				element.current_order_type = GameEnums.OrderType.ATTACK
				_cancel_fire_mission(element)
				movement_system.issue_move_order(element, target_pos, use_road)

			GameEnums.OrderType.HOLD:
				# 停止命令：即座に移動を停止
				movement_system.issue_stop_order(element)

			GameEnums.OrderType.RETREAT:
				# 後退命令：正面を維持したまま後退
				# target_posへ向かって後退（クリック位置が後退先）
				_cancel_fire_mission(element)
				movement_system.issue_reverse_order(element, element.position.distance_to(target_pos))

			GameEnums.OrderType.BREAK_CONTACT:
				# 離脱命令：煙幕＋後退で戦闘離脱
				_cancel_fire_mission(element)
				movement_system.issue_break_contact_order(element, target_pos)

			GameEnums.OrderType.SMOKE:
				# 煙幕命令：発煙弾を発射
				_execute_smoke_command(element, target_pos)

			GameEnums.OrderType.UNLOAD:
				# 下車命令：搭乗歩兵を下車させる
				_execute_unload_command(element, target_pos)

			GameEnums.OrderType.LOAD:
				# 乗車命令（歩兵用）：カーソル位置の車両に乗車
				_execute_board_command(element, target_pos)

			GameEnums.OrderType.MOVE_FAST:
				# 急速移動：遮蔽無視で高速移動（発見されやすい）
				_execute_fast_move_command(element, target_pos, use_road)

			GameEnums.OrderType.AMBUSH:
				# 待ち伏せ：その場で待機、SOP Hold Fireで近距離の敵を射撃
				_execute_ambush_command(element)

			GameEnums.OrderType.DIG_IN:
				# 塹壕構築：その場で防御力向上（将来実装）
				_execute_dig_in_command(element)

			GameEnums.OrderType.WEAPONS_FREE:
				# 射撃許可：SOP を FIRE_AT_WILL に設定
				_execute_sop_command(element, GameEnums.SOPMode.FIRE_AT_WILL)

			GameEnums.OrderType.WEAPONS_HOLD:
				# 射撃禁止：SOP を HOLD_FIRE に設定
				_execute_sop_command(element, GameEnums.SOPMode.HOLD_FIRE)

			GameEnums.OrderType.DEFEND:
				# 防御命令：その位置で防御（廃止だが後方互換）
				element.forced_target_id = ""
				element.current_order_type = GameEnums.OrderType.DEFEND
				_cancel_fire_mission(element)
				movement_system.issue_move_order(element, target_pos, use_road)

			GameEnums.OrderType.FIRE_MISSION:
				# 間接射撃（砲兵用）：指定位置にHE射撃
				_execute_fire_mission_command(element, target_pos)

			_:
				# その他のコマンドは移動として処理（暫定）
				element.current_order_type = command_type
				_cancel_fire_mission(element)
				movement_system.issue_move_order(element, target_pos, use_road)


## 特定の敵ユニットへの攻撃命令を発行
func _execute_attack_command(attackers: Array[ElementData.ElementInstance], target: ElementData.ElementInstance) -> void:
	if not target:
		return

	for element in attackers:
		if element.faction != player_faction:
			continue

		# 強制交戦目標を設定
		element.forced_target_id = target.id
		element.order_target_id = target.id
		element.current_order_type = GameEnums.OrderType.ATTACK

		# VisionSystemで射撃可能か判定（視界範囲 + DataLink考慮）
		var can_fire := vision_system.can_fire_at(element, target.id) if vision_system else false

		# 砲兵の射撃任務を解除（直接攻撃命令）
		_cancel_fire_mission(element)

		if can_fire:
			# 射撃可能なら移動停止
			element.current_path = PackedVector2Array()
			element.is_moving = false
		else:
			# 射撃不可なら目標に向かって移動
			var use_road: bool = input_controller.is_alt_held() if input_controller else false
			movement_system.issue_move_order(element, target.position, use_road)

		print("[Order] %s -> ATTACK %s (can_fire=%s)" % [element.id, target.id, can_fire])


## 煙幕コマンドを実行（発煙弾発射）
func _execute_smoke_command(element: ElementData.ElementInstance, _target_pos: Vector2) -> void:
	if not element:
		return

	# TODO: 煙幕システムの実装
	# 現在は停止して煙幕モードに設定するだけ
	element.current_order_type = GameEnums.OrderType.SMOKE
	element.forced_target_id = ""

	# 煙幕発射をリクエスト（将来: SmokeSystemで処理）
	print("[Order] %s -> SMOKE (not yet implemented)" % element.id)


## 下車コマンドを実行（搭乗歩兵を下車させる）
func _execute_unload_command(element: ElementData.ElementInstance, target_pos: Vector2) -> void:
	if not element:
		return

	if not transport_system:
		print("[Order] %s -> UNLOAD failed: transport_system not available" % element.id)
		return

	# IFVを停止させる（下車中は移動不可）
	movement_system.issue_stop_order(element)

	# 下車開始（歩兵が車両から歩いて出る）
	var infantry: ElementData.ElementInstance = transport_system.start_unload_infantry(element, target_pos)
	if infantry:
		# 下車した歩兵のElementViewを表示
		_ensure_element_view(infantry)
		# 歩兵に移動命令を出す（車両位置から下車目標位置へ）
		movement_system.issue_move_order(infantry, infantry.unloading_target_pos, false)
		# IFVは下車完了状態に設定
		element.current_order_type = GameEnums.OrderType.UNLOAD
		print("[Order] %s -> UNLOAD %s (walking to %s)" % [element.id, infantry.id, infantry.unloading_target_pos])
	else:
		print("[Order] %s -> UNLOAD failed: no embarked infantry" % element.id)


## ElementViewが存在することを確認（なければ作成、あれば表示状態を更新）
func _ensure_element_view(element: ElementData.ElementInstance) -> void:
	if element.id in _element_views:
		# 既存のViewがある場合は表示状態を更新
		var existing_view: ElementView = _element_views[element.id]
		existing_view.visible = not element.is_embarked
		return

	# Viewがない場合は作成（_on_element_addedと同じ処理）
	var new_view := ElementView.new()
	new_view.setup(element, symbol_manager, player_faction)
	units_layer.add_child(new_view)
	_element_views[element.id] = new_view


## 乗車コマンドを実行（歩兵がカーソル位置の車両まで移動して乗車）
## element: 乗車する歩兵
## target_pos: カーソル位置（乗車先車両を指定）
func _execute_board_command(element: ElementData.ElementInstance, target_pos: Vector2) -> void:
	if not element:
		print("[Order] BOARD failed: element is null")
		return

	if not transport_system:
		print("[Order] %s -> BOARD failed: transport_system not available" % element.id)
		return

	# 歩兵かどうかチェック
	if element.element_type and element.element_type.category != ElementData.Category.INF:
		print("[Order] %s -> BOARD failed: not infantry" % element.id)
		return

	# カーソル位置の車両を検索（検出半径50m）
	const BOARD_DETECTION_RADIUS: float = 50.0
	var transport: ElementData.ElementInstance = transport_system.get_transport_at_position(
		element, target_pos, BOARD_DETECTION_RADIUS
	)
	if not transport:
		print("[Order] %s -> BOARD failed: no transport vehicle at cursor position" % element.id)
		return

	# 距離を計算（ログ用）
	var distance := element.position.distance_to(transport.position)

	# 車両に向かって移動を開始
	element.boarding_target_id = transport.id
	element.current_order_type = GameEnums.OrderType.LOAD
	_cancel_fire_mission(element)
	# 車両を乗車待機状態に設定（衝突回避で逃げないようにする）
	transport.awaiting_boarding_id = element.id
	movement_system.issue_stop_order(transport)  # 車両を停止
	movement_system.issue_move_order(element, transport.position, false)
	print("[Order] %s -> BOARD %s (distance=%.0fm, moving to vehicle)" % [element.id, transport.id, distance])


## 急速移動コマンドを実行（遮蔽無視で高速移動）
func _execute_fast_move_command(element: ElementData.ElementInstance, target_pos: Vector2, use_road: bool) -> void:
	if not element:
		return

	# 通常移動と同じだが、速度ボーナスとステルスペナルティを設定
	element.forced_target_id = ""
	element.current_order_type = GameEnums.OrderType.MOVE_FAST
	_cancel_fire_mission(element)
	movement_system.issue_move_order(element, target_pos, use_road)

	# TODO: 速度ボーナスとステルスペナルティの実装
	# 現在は通常移動と同じ
	print("[Order] %s -> FAST MOVE to %s" % [element.id, target_pos])


## 待ち伏せコマンドを実行（その場で待機、Hold Fireで近距離射撃）
func _execute_ambush_command(element: ElementData.ElementInstance) -> void:
	if not element:
		return

	# 移動を停止
	movement_system.issue_stop_order(element)

	# 待ち伏せモードを設定
	element.current_order_type = GameEnums.OrderType.AMBUSH
	element.sop_mode = GameEnums.SOPMode.HOLD_FIRE  # 待ち伏せ中は射撃禁止
	element.forced_target_id = ""

	# TODO: 近距離の敵が来たら自動射撃する処理
	print("[Order] %s -> AMBUSH (SOP: Hold Fire)" % element.id)


## 塹壕構築コマンドを実行（将来実装）
func _execute_dig_in_command(element: ElementData.ElementInstance) -> void:
	if not element:
		return

	# 移動を停止
	movement_system.issue_stop_order(element)

	# 塹壕構築モードを設定
	element.current_order_type = GameEnums.OrderType.DIG_IN
	element.forced_target_id = ""

	# TODO: 時間経過で防御力向上の実装
	print("[Order] %s -> DIG IN (not yet implemented)" % element.id)


## 間接射撃コマンドを実行（砲兵用：指定位置にHE射撃）
func _execute_fire_mission_command(element: ElementData.ElementInstance, target_pos: Vector2) -> void:
	if not element:
		return

	# 砲兵かどうかチェック（SP_ARTILLERYまたはSP_MORTARアーキタイプ）
	var archetype := element.element_type.id if element.element_type else ""
	if archetype != "SP_ARTILLERY" and archetype != "SP_MORTAR":
		print("[Order] %s -> FIRE MISSION failed: not artillery unit" % element.id)
		return

	# 間接射撃武器を持っているかチェック
	var has_indirect_weapon := false
	for weapon in element.weapons:
		if weapon.fire_model == WeaponData.FireModel.INDIRECT:
			has_indirect_weapon = true
			break

	if not has_indirect_weapon:
		print("[Order] %s -> FIRE MISSION failed: no indirect fire weapon" % element.id)
		return

	# 移動を停止
	movement_system.issue_stop_order(element)

	# 間接射撃任務を設定
	element.current_order_type = GameEnums.OrderType.FIRE_MISSION
	element.fire_mission_target = target_pos
	element.forced_target_id = ""  # 直接射撃目標をクリア

	# 展開状態に応じて処理を分岐
	var ADS := ElementData.ElementInstance.ArtilleryDeployState
	match element.artillery_deploy_state:
		ADS.DEPLOYED:
			# 既に展開完了：即座に射撃可能
			element.fire_mission_active = true
			print("[Order] %s -> FIRE MISSION HE at %s (already deployed)" % [element.id, target_pos])

		ADS.DEPLOYING:
			# 展開中：展開完了を待ってから射撃開始
			element.fire_mission_active = false  # 展開完了まで射撃不可
			print("[Order] %s -> FIRE MISSION HE at %s (deploying... %.0f%%)" % [
				element.id, target_pos, element.artillery_deploy_progress * 100
			])

		ADS.STOWED, ADS.PACKING:
			# 収納状態または撤収中：展開を開始
			element.artillery_deploy_state = ADS.DEPLOYING
			element.artillery_deploy_progress = 0.0
			element.fire_mission_active = false  # 展開完了まで射撃不可
			print("[Order] %s -> FIRE MISSION HE at %s (deploying... 0%%)" % [element.id, target_pos])


## 間接射撃任務を解除（移動命令時に呼び出す）
## 砲兵は走行間射撃ができないため、移動命令を受けると射撃を中止し撤収を開始
func _cancel_fire_mission(element: ElementData.ElementInstance) -> void:
	var archetype := element.element_type.id if element.element_type else ""
	if archetype != "SP_ARTILLERY" and archetype != "SP_MORTAR":
		return  # 砲兵以外は処理不要

	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# 射撃任務を解除
	if element.fire_mission_active or element.fire_mission_target != Vector2.ZERO:
		element.fire_mission_active = false
		element.fire_mission_target = Vector2.ZERO
		print("[Order] %s -> FIRE MISSION cancelled (movement ordered)" % element.id)

	# 展開中または展開完了の場合は撤収を開始
	match element.artillery_deploy_state:
		ADS.DEPLOYED, ADS.DEPLOYING:
			element.artillery_deploy_state = ADS.PACKING
			element.artillery_deploy_progress = 0.0
			print("[Order] %s -> Packing up (0%%)" % element.id)


## SOPモード切り替えコマンドを実行
func _execute_sop_command(element: ElementData.ElementInstance, new_sop: GameEnums.SOPMode) -> void:
	if not element:
		return

	var old_sop := element.sop_mode
	element.sop_mode = new_sop

	# RETURN_FIREに切り替えた場合、過去の被弾履歴をリセット
	# （「今から攻撃を受けたら反撃」という意味にするため）
	if new_sop == GameEnums.SOPMode.RETURN_FIRE:
		element.last_hit_tick = 0

	# SOPモード名を取得
	var sop_names := {
		GameEnums.SOPMode.HOLD_FIRE: "HOLD FIRE",
		GameEnums.SOPMode.RETURN_FIRE: "RETURN FIRE",
		GameEnums.SOPMode.FIRE_AT_WILL: "FIRE AT WILL",
	}

	var old_name: String = sop_names.get(old_sop, "UNKNOWN")
	var new_name: String = sop_names.get(new_sop, "UNKNOWN")

	print("[SOP] %s: %s -> %s" % [element.id, old_name, new_name])


func _get_cp_at_position(pos: Vector2) -> MapData.CapturePoint:
	if not map_data:
		return null

	for cp in map_data.capture_points:
		if pos.distance_to(cp.position) <= map_data.cp_radius_m:
			return cp

	return null


func _get_template_name(tpl: GameEnums.TacticalTemplate) -> String:
	match tpl:
		GameEnums.TacticalTemplate.TPL_NONE:
			return "NONE"
		GameEnums.TacticalTemplate.TPL_MOVE:
			return "MOVE"
		GameEnums.TacticalTemplate.TPL_ATTACK_CP:
			return "ATK_CP"
		GameEnums.TacticalTemplate.TPL_DEFEND_CP:
			return "DEF_CP"
		GameEnums.TacticalTemplate.TPL_RECON:
			return "RECON"
		GameEnums.TacticalTemplate.TPL_ATTACK_AREA:
			return "ATK_AREA"
		GameEnums.TacticalTemplate.TPL_BREAK_CONTACT:
			return "BREAK"
		GameEnums.TacticalTemplate.TPL_RESUPPLY:
			return "RESUP"
		_:
			return "UNK"


func _get_combat_state_name(state: GameEnums.CombatState) -> String:
	match state:
		GameEnums.CombatState.QUIET:
			return "Quiet"
		GameEnums.CombatState.ALERT:
			return "Alert"
		GameEnums.CombatState.ENGAGED:
			return "Engaged"
		GameEnums.CombatState.DISENGAGING:
			return "Diseng"
		GameEnums.CombatState.RECOVERING:
			return "Recov"
		_:
			return "?"

# =============================================================================
# 戦闘ヘルパー
# =============================================================================

## 飛翔中の間接射撃の着弾処理
func _process_pending_indirect_impacts(tick: int) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var to_remove: Array[int] = []

	for i in range(_pending_indirect_impacts.size()):
		var impact_data: Dictionary = _pending_indirect_impacts[i]
		if current_time >= impact_data.arrival_time:
			# 着弾！ダメージを適用
			_apply_indirect_damage(
				impact_data.shooter_id,
				impact_data.impact_pos,
				impact_data.weapon,
				impact_data.faction,
				tick
			)
			to_remove.append(i)

	# 着弾済みを削除（逆順）
	for i in range(to_remove.size() - 1, -1, -1):
		_pending_indirect_impacts.remove_at(to_remove[i])


## 間接射撃のダメージを適用
func _apply_indirect_damage(shooter_id: String, impact_pos: Vector2, weapon: WeaponData.WeaponType, faction: GameEnums.Faction, tick: int) -> void:
	var blast_radius: float = weapon.blast_radius_m
	var direct_hit_radius: float = weapon.direct_hit_radius_m

	for target in world_model.elements:
		if target.faction == faction:
			continue  # 味方には当たらない
		if target.state == GameEnums.UnitState.DESTROYED:
			continue

		var target_distance := target.position.distance_to(impact_pos)

		if target_distance > blast_radius:
			continue  # 爆風範囲外

		# ダメージ計算
		var is_direct_hit := target_distance <= direct_hit_radius
		var terrain := map_data.get_terrain_at(target.position) if map_data else GameEnums.TerrainType.OPEN
		var effect_result := combat_system.calculate_indirect_impact_effect(
			target, weapon, target_distance, terrain, false, 1
		)

		if effect_result.d_supp > 0 or effect_result.d_dmg > 0:
			# ダメージと抑圧を適用
			combat_system.apply_damage(
				target,
				effect_result.d_supp,
				effect_result.d_dmg,
				tick,
				weapon.threat_class
			)

			# デバッグ出力
			var hit_type := "DIRECT HIT" if is_direct_hit else "BLAST"
			print("[IndirectFire] %s -> %s (%s, dist=%.1fm): supp=%.2f dmg=%.2f" % [
				shooter_id, target.id, hit_type, target_distance,
				effect_result.d_supp, effect_result.d_dmg
			])


## 砲兵展開・撤収処理
## 展開: STOWED -> DEPLOYING -> DEPLOYED（射撃可能）
## 撤収: DEPLOYED -> PACKING -> STOWED（移動可能）
func _process_artillery_deployment(delta: float) -> void:
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	for element in world_model.elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		# 砲兵ユニットのみ処理
		var archetype := element.element_type.id if element.element_type else ""
		if archetype != "SP_ARTILLERY" and archetype != "SP_MORTAR":
			continue

		match element.artillery_deploy_state:
			ADS.DEPLOYING:
				# 展開中：進捗を更新
				var prev_progress := element.artillery_deploy_progress
				if element.artillery_deploy_time_sec > 0:
					element.artillery_deploy_progress += delta / element.artillery_deploy_time_sec
				else:
					element.artillery_deploy_progress = 1.0

				# 進捗を10%ごとにログ出力
				var prev_pct := int(prev_progress * 10)
				var curr_pct := int(element.artillery_deploy_progress * 10)
				if curr_pct > prev_pct and curr_pct < 10:
					print("[Artillery] %s -> Deploying... %d%%" % [element.id, curr_pct * 10])

				if element.artillery_deploy_progress >= 1.0:
					# 展開完了
					element.artillery_deploy_progress = 1.0
					element.artillery_deploy_state = ADS.DEPLOYED

					# 射撃任務が設定されていれば射撃開始
					if element.fire_mission_target != Vector2.ZERO:
						element.fire_mission_active = true
						print("[Artillery] %s -> Deployed! Ready to fire at %s" % [
							element.id, element.fire_mission_target
						])
					else:
						print("[Artillery] %s -> Deployed!" % element.id)

			ADS.PACKING:
				# 撤収中：進捗を更新
				if element.artillery_pack_time_sec > 0:
					element.artillery_deploy_progress += delta / element.artillery_pack_time_sec
				else:
					element.artillery_deploy_progress = 1.0

				if element.artillery_deploy_progress >= 1.0:
					# 撤収完了：移動可能
					element.artillery_deploy_progress = 0.0
					element.artillery_deploy_state = ADS.STOWED
					print("[Artillery] %s -> Packed! Ready to move" % element.id)


## 間接射撃処理（砲兵ユニット）
## 仕様書: docs/indirect_fire_v0.2.md
func _process_indirect_fire(tick: int, _elements_under_fire: Dictionary, shooters_firing: Dictionary) -> void:
	for shooter in world_model.elements:
		# 間接射撃任務が有効なユニットのみ処理
		if not shooter.fire_mission_active:
			continue
		if shooter.state == GameEnums.UnitState.DESTROYED:
			continue
		if shooter.state == GameEnums.UnitState.BROKEN:
			continue

		# 間接射撃武器を取得
		var indirect_weapon: WeaponData.WeaponType = null
		for weapon in shooter.weapons:
			if weapon.fire_model == WeaponData.FireModel.INDIRECT:
				indirect_weapon = weapon
				break

		if not indirect_weapon:
			continue

		# 発射レート制御（DISCRETE武器）
		if shooter.last_fire_tick >= 0 and indirect_weapon.rof_rpm > 0:
			var ticks_per_shot := int(600.0 / indirect_weapon.rof_rpm)
			var elapsed := tick - shooter.last_fire_tick
			if elapsed < ticks_per_shot:
				continue  # リロード中

		# 射撃実行
		var target_pos: Vector2 = shooter.fire_mission_target
		var distance := shooter.position.distance_to(target_pos)

		# 射程チェック
		if distance > indirect_weapon.max_range_m:
			if tick % 100 == 0:
				print("[IndirectFire] %s: target out of range (%.0fm > %.0fm)" % [
					shooter.id, distance, indirect_weapon.max_range_m
				])
			continue

		# CEP（円形誤差半数）を計算
		var sigma_hit: float = indirect_weapon.sigma_hit_m
		# 距離による精度低下（遠いほどCEPが大きくなる）
		var range_factor := clampf(distance / indirect_weapon.max_range_m, 0.5, 1.5)
		sigma_hit *= range_factor

		# 着弾位置を計算（ガウス分布）
		var impact_offset := Vector2(
			randfn(0, sigma_hit),
			randfn(0, sigma_hit)
		)
		var impact_pos := target_pos + impact_offset

		# 発射タイミングを記録
		shooter.last_fire_tick = tick
		shooter.current_weapon = indirect_weapon
		shooters_firing[shooter.id] = true

		# 飛翔時間を計算（弾速に基づく）
		var flight_time_sec := distance / indirect_weapon.projectile_speed_mps
		var current_time := Time.get_ticks_msec() / 1000.0
		var arrival_time := current_time + flight_time_sec

		# 着弾待ちリストに追加
		_pending_indirect_impacts.append({
			"shooter_id": shooter.id,
			"impact_pos": impact_pos,
			"weapon": indirect_weapon,
			"faction": shooter.faction,
			"arrival_time": arrival_time
		})

		# 戦闘可視化（トレーサー表示 - 陣営色で表示）
		if combat_visualizer:
			combat_visualizer.add_fire_event(
				shooter.id,
				"",  # 位置目標なのでtarget_idは空
				shooter.position,
				impact_pos,
				shooter.faction,
				1.0,  # ダメージ表示用
				0.5,  # 抑圧表示用
				true,
				indirect_weapon.mechanism,
				indirect_weapon.fire_model,
				flight_time_sec  # トレーサー表示時間を飛翔時間に合わせる
			)


## 射撃対象を選択（VisionSystem統合API使用）
## VisionSystemが「見えている敵だけを撃てる」という原則を保証
func _select_target(shooter: ElementData.ElementInstance, _tick: int) -> ElementData.ElementInstance:
	if not vision_system:
		return null

	# 強制交戦目標が設定されている場合は優先
	if shooter.forced_target_id != "":
		var forced_target := world_model.get_element_by_id(shooter.forced_target_id)
		if forced_target and forced_target.state != GameEnums.UnitState.DESTROYED:
			# VisionSystemで射撃可能か判定（DataLink + 視界範囲を一元管理）
			if vision_system.can_fire_at(shooter, shooter.forced_target_id):
				return forced_target
			# 射程外または視界外でも、目標が存在する限り他の目標には切り替えない
			# （目標に近づくため移動を続ける）
			return null
		else:
			# 目標が破壊されたら強制目標をクリア
			shooter.forced_target_id = ""
			shooter.order_target_id = ""

	# VisionSystemから射撃可能な全目標を取得（DataLink + 視界範囲考慮済み）
	var fireable_targets := vision_system.get_fireable_targets(shooter)
	if fireable_targets.size() == 0:
		return null

	# SOPモードによるフィルタリングは _update_combat() で一元管理
	# （この関数が呼ばれる時点でSOPチェックは完了済み）

	# 最も近い敵を選択（距離ベースの比較）
	var best_target: ElementData.ElementInstance = null
	var best_distance := INF

	for target in fireable_targets:
		if not target:
			continue
		var distance := shooter.position.distance_to(target.position)
		if distance < best_distance:
			best_distance = distance
			best_target = target

	return best_target


## LoSを推定（簡易版）
func _estimate_los(shooter: ElementData.ElementInstance, target: ElementData.ElementInstance) -> float:
	if not map_data:
		return 1.0

	var t_los := 1.0
	var sample_count := 5
	var shooter_pos := shooter.position
	var target_pos := target.position

	for i in range(1, sample_count):
		var t := float(i) / float(sample_count)
		var sample_pos := shooter_pos.lerp(target_pos, t)
		var terrain := map_data.get_terrain_at(sample_pos)

		match terrain:
			GameEnums.TerrainType.FOREST:
				t_los *= 0.7
			GameEnums.TerrainType.URBAN:
				t_los *= 0.5

	return maxf(t_los, 0.1)


# =============================================================================
# マーカー作成ヘルパー
# =============================================================================

func _create_cp_marker(cp: MapData.CapturePoint) -> Node2D:
	var container := Node2D.new()
	container.position = cp.position

	var circle := _create_circle(map_data.cp_radius_m, _get_faction_color(cp.initial_owner, 0.3))
	container.add_child(circle)

	var label := Label.new()
	label.text = cp.id
	label.position = Vector2(-10, -30)
	label.add_theme_font_size_override("font_size", 24)
	container.add_child(label)

	return container


func _create_zone_outline(zone: MapData.TerrainZone) -> Line2D:
	var line := Line2D.new()
	line.points = zone.polygon
	if zone.polygon.size() > 0:
		line.add_point(zone.polygon[0])
	line.width = 2.0
	line.default_color = _get_terrain_color(zone.terrain_type)
	return line


func _create_circle(radius: float, color: Color) -> Node2D:
	var circle := Node2D.new()
	circle.set_script(preload("res://scripts/debug/circle_drawer.gd"))
	circle.set("radius", radius)
	circle.set("color", color)
	return circle


func _get_faction_color(faction: GameEnums.Faction, alpha: float = 1.0) -> Color:
	match faction:
		GameEnums.Faction.BLUE:
			return Color(0.2, 0.4, 0.8, alpha)
		GameEnums.Faction.RED:
			return Color(0.8, 0.2, 0.2, alpha)
		_:
			return Color(0.5, 0.5, 0.5, alpha)


func _get_terrain_color(terrain: GameEnums.TerrainType) -> Color:
	match terrain:
		GameEnums.TerrainType.ROAD:
			return Color(0.4, 0.3, 0.2)
		GameEnums.TerrainType.FOREST:
			return Color(0.1, 0.5, 0.1)
		GameEnums.TerrainType.URBAN:
			return Color(0.5, 0.5, 0.5)
		GameEnums.TerrainType.WATER:
			return Color(0.2, 0.3, 0.7)
		_:
			return Color(0.3, 0.4, 0.3)

# =============================================================================
# デバッグ機能
# =============================================================================

## Rキーでシーンをリセット
func _reset_scene() -> void:
	print("[Debug] シーンをリセット")
	get_tree().reload_current_scene()
