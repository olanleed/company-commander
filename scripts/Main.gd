extends Node2D

const CompanyControllerAIClass = preload("res://scripts/ai/company_controller_ai.gd")
const InputControllerClass = preload("res://scripts/ui/input_controller.gd")
const OrderPreviewClass = preload("res://scripts/ui/order_preview.gd")
const DataLinkSystemClass = preload("res://scripts/systems/data_link_system.gd")

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
var capture_system: CaptureSystem
var projectile_manager: ProjectileManager
var tactical_overlay: TacticalOverlay
var data_link_system  # DataLinkSystemClass

## 中隊AI（陣営別）
var company_ais: Dictionary = {}  # faction -> CompanyControllerAI

var background_sprite: Sprite2D
var _element_views: Dictionary = {}  # element_id -> ElementView
var _selected_elements: Array[ElementData.ElementInstance] = []
var _cp_views: Dictionary = {}  # cp_id -> CapturePointView

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
	tactical_overlay.setup(world_model)
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

	# TacticalOverlay
	tactical_overlay = TacticalOverlay.new()
	tactical_overlay.name = "TacticalOverlay"

	# DataLinkSystem
	data_link_system = DataLinkSystemClass.new()


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

	# === BLUE陣営: 戦車2小隊 ===
	var blue_tank1_pos := Vector2(400, 900)
	var blue_tank1 := ElementFactory.create_element("TANK_PLT", GameEnums.Faction.BLUE, blue_tank1_pos)
	world_model.add_element(blue_tank1)

	var blue_tank2_pos := Vector2(400, 1100)
	var blue_tank2 := ElementFactory.create_element("TANK_PLT", GameEnums.Faction.BLUE, blue_tank2_pos)
	world_model.add_element(blue_tank2)

	# === RED陣営: 戦車2小隊 ===
	var red_tank1_pos := Vector2(1600, 900)
	var red_tank1 := ElementFactory.create_element("TANK_PLT", GameEnums.Faction.RED, red_tank1_pos)
	world_model.add_element(red_tank1)

	var red_tank2_pos := Vector2(1600, 1100)
	var red_tank2 := ElementFactory.create_element("TANK_PLT", GameEnums.Faction.RED, red_tank2_pos)
	world_model.add_element(red_tank2)

	# スポーン後に衝突を解消
	for element in world_model.elements:
		movement_system.resolve_hard_collisions(element)

	print("テストユニット生成完了: ", world_model.elements.size(), " elements")
	print("=== 戦車 2vs2 ===")
	print("  BLUE: 戦車2小隊 @ x=400")
	print("  RED:  戦車2小隊 @ x=1600")
	print("  距離: ~1200m（戦車砲射程: 50-2500m）")
	print("  戦車正面CE装甲: 140 → LAW貫徹確率<1%%")
	print("  期待: 側面攻撃でLAWが戦車を撃破可能")
	print("==========================")
	for element in world_model.elements:
		var weapons_str := ""
		for w in element.weapons:
			weapons_str += w.id + " "
		var armor_str := ""
		if element.element_type and element.element_type.armor_class > 0:
			armor_str = " (ArmorClass=%d)" % element.element_type.armor_class
		print("  %s (%s): Str=%d, Weapons=[%s], primary=%s%s" % [
			element.id,
			element.element_type.display_name if element.element_type else "?",
			element.current_strength,
			weapons_str.strip_edges(),
			element.primary_weapon.id if element.primary_weapon else "NONE",
			armor_str
		])

	# 中隊AIをセットアップ
	_setup_company_ais()


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
	view.setup(element, symbol_manager, player_faction)
	# 初期状態では全ユニットを不透明で表示（FoWは後で適用される）
	view.modulate = Color(1, 1, 1, 1)
	view.visible = true
	units_layer.add_child(view)
	_element_views[element.id] = view


func _on_element_removed(element: ElementData.ElementInstance) -> void:
	if element.id in _element_views:
		var view: ElementView = _element_views[element.id]
		view.queue_free()
		_element_views.erase(element.id)


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
func _handle_debug_input() -> void:
	# デバッグ入力は現在無効
	pass


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

	# データリンク状態を更新（ハブがない場合は全員LINKEDにフォールバック）
	if data_link_system:
		data_link_system.update_comm_states_no_hub_fallback(world_model.elements)

	# ATTACK命令中のユニットの移動制御
	_update_attack_movement()

	# 移動更新（衝突回避含む）
	for element in world_model.elements:
		movement_system.update_element(element, GameConstants.SIM_DT)

	# 静止ユニットの衝突回避
	for element in world_model.elements:
		if not element.is_moving and element.state != GameEnums.UnitState.DESTROYED:
			movement_system.apply_separation(element, GameConstants.SIM_DT)

	# 視界更新
	vision_system.update(tick, GameConstants.SIM_DT)

	# 戦闘更新
	_update_combat(tick, GameConstants.SIM_DT)

	# 拠点制圧更新
	_update_capture(tick)

	# 中隊AI更新
	_update_company_ais(tick)


func _update_combat(tick: int, dt: float) -> void:
	# デバッグ: 接触状態を出力（10秒ごと）
	if tick % 100 == 0:
		for faction_val in [GameEnums.Faction.BLUE, GameEnums.Faction.RED]:
			var contacts := vision_system.get_contacts_for_faction(faction_val)
			var faction_name := "BLUE" if faction_val == GameEnums.Faction.BLUE else "RED"
			if contacts.size() > 0:
				print("[Vision] %s has %d contacts" % [faction_name, contacts.size()])
				for c in contacts:
					print("  - %s: state=%d" % [c.element_id, c.state])

	# 被弾中フラグを追跡
	var elements_under_fire: Dictionary = {}  # element_id -> bool

	# 射撃中のユニットを追跡（射撃終了時にcurrent_target_idをクリアするため）
	var shooters_firing: Dictionary = {}  # element_id -> bool

	# 射撃処理
	for shooter in world_model.elements:
		if shooter.state == GameEnums.UnitState.DESTROYED:
			continue
		if shooter.state == GameEnums.UnitState.BROKEN:
			continue  # Brokenは射撃不可
		if not shooter.primary_weapon:
			continue
		if shooter.sop_mode == GameEnums.SOPMode.HOLD_FIRE:
			continue

		# 射撃対象を選択
		var target := _select_target(shooter, tick)
		if not target:
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

		# DISCRETE武器の発射レート制御
		var can_fire := true
		if selected_weapon.fire_model == WeaponData.FireModel.DISCRETE:
			if shooter.last_fire_tick >= 0 and selected_weapon.rof_rpm > 0:
				# rof_rpm発/分 → 1発あたりの間隔(tick)を計算
				# 10Hz = 10tick/秒 = 600tick/分
				var ticks_per_shot := int(600.0 / selected_weapon.rof_rpm)
				var elapsed := tick - shooter.last_fire_tick
				if elapsed < ticks_per_shot:
					can_fire = false

		if not can_fire:
			# 発射レート制限中は射撃しない（ただし照準は維持）
			shooter.current_target_id = target.id
			continue

		# 装甲目標かどうかで計算方法を分岐
		var d_supp: float = 0.0
		var d_dmg: float = 0.0
		var is_valid: bool = false

		if target.is_vehicle():
			# 装甲目標: ゾーン別装甲・貫徹判定を使用
			var result_armor := combat_system.calculate_direct_fire_vs_armor(
				shooter, target, selected_weapon, distance, dt, t_los, terrain, false
			)
			is_valid = result_armor.is_valid
			d_supp = result_armor.d_supp

			# デバッグ: アスペクトと貫徹確率を取得
			var aspect := combat_system.calculate_aspect_v01r(
				shooter.position, target.position, target.facing
			)
			var p_pen := combat_system.get_penetration_probability(
				shooter, target, selected_weapon, distance, aspect
			)
			var aspect_name: String = str(WeaponData.ArmorZone.keys()[aspect])

			# 離散ヒットモデル: p_hitでダメージ発生を判定
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
				# ヒット時のデバッグログ
				if tick % 10 == 0:
					print("[Combat] %s -> %s [%s] %s: p_pen=%.2f p_hit=%.2f roll=%.2f -> HIT!" % [
						shooter.id, target.id, selected_weapon.id, aspect_name, p_pen, result_armor.p_hit, roll
					])
			else:
				# ミス時のデバッグログ（50tickごと）
				if tick % 50 == 0:
					print("[Combat] %s -> %s [%s] %s: p_pen=%.2f p_hit=%.4f E=%.4f roll=%.2f -> miss" % [
						shooter.id, target.id, selected_weapon.id, aspect_name, p_pen, result_armor.p_hit, result_armor.exposure, roll
					])
		else:
			# 非装甲目標: 従来の計算
			var result := combat_system.calculate_direct_fire_effect(
				shooter, target, selected_weapon, distance, dt, t_los, terrain, false
			)
			is_valid = result.is_valid
			d_supp = result.d_supp
			d_dmg = result.d_dmg

		if is_valid:
			# 抑圧とダメージを適用（threat_classを渡して車両の抑圧上限を適用）
			var threat_class := selected_weapon.threat_class if selected_weapon else WeaponData.ThreatClass.SMALL_ARMS
			combat_system.apply_damage(target, d_supp, d_dmg, tick, threat_class)
			elements_under_fire[target.id] = true
			shooter.last_fire_tick = tick
			shooter.current_target_id = target.id
			shooters_firing[shooter.id] = true

			# 戦闘可視化
			# 有効な射撃は命中扱い（継続的なダメージ/抑圧）
			# 抑圧のみの場合も射線は実線で表示
			var is_hit := (d_dmg > 0.0 or d_supp > 0.0)
			var weapon_mechanism := selected_weapon.mechanism if selected_weapon else WeaponData.Mechanism.SMALL_ARMS
			if combat_visualizer:
				combat_visualizer.add_fire_event(
					shooter.id,
					target.id,
					shooter.position,
					target.position,
					shooter.faction,
					d_dmg,
					d_supp,
					is_hit,
					weapon_mechanism
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

			# デバッグ出力（初回のみ）
			if tick % 50 == 0:
				var armor_str := " (ARMORED)" if target.is_vehicle() else ""
				var weapon_name := selected_weapon.id if selected_weapon else "NONE"
				print("[Combat] %s -> %s%s [%s]: supp=%.2f dmg=%.2f" % [shooter.id, target.id, armor_str, weapon_name, d_supp, d_dmg])

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
## 強制目標が射程内に入ったら停止、射程外なら追跡
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

		var distance := element.position.distance_to(target.position)
		var in_range := false
		if element.primary_weapon:
			in_range = element.primary_weapon.is_in_range(distance)

		if in_range:
			# 射程内：移動停止
			if element.is_moving:
				element.current_path = PackedVector2Array()
				element.is_moving = false
				element.velocity = Vector2.ZERO
		else:
			# 射程外：目標に向かって移動（まだ移動していない場合）
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

	# InputController
	input_controller = InputControllerClass.new()
	input_controller.name = "InputController"
	add_child(input_controller)
	input_controller.setup(camera, hud_manager.pie_menu, hud_manager)

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

	var company_ai = company_ais.get(player_faction)
	hud_manager.update_hud(sim_runner, company_ai)

	# カメラ範囲をミニマップに反映
	if hud_manager.minimap:
		var viewport_size := get_viewport().get_visible_rect().size
		var cam_rect := Rect2(
			camera.position - viewport_size / 2 / camera.zoom,
			viewport_size / camera.zoom
		)
		hud_manager.minimap.set_camera_rect(cam_rect)


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
	# 中隊AI経由で命令を発行
	if _selected_elements.size() == 0:
		return

	var company_ai = company_ais.get(player_faction)
	if not company_ai:
		return

	# 敵ユニットをクリックした場合は攻撃（目標ID指定）
	# TODO: 中隊AIにElement単位の攻撃命令を追加
	var target_element := _get_element_at_position(world_pos)
	if target_element and target_element.faction != player_faction:
		_execute_attack_command(_selected_elements, target_element)
		return

	# 拠点をクリックした場合
	var cp := _get_cp_at_position(world_pos)
	if cp:
		var use_road: bool = input_controller.is_alt_held() if input_controller else false
		if cp.initial_owner == player_faction or cp.initial_owner == GameEnums.Faction.NONE:
			company_ai.order_defend_cp(cp.id)
			print("[CompanyAI] BLUE -> DEFEND_CP %s" % cp.id)
		else:
			company_ai.order_attack_cp(cp.id)
			print("[CompanyAI] BLUE -> ATTACK_CP %s" % cp.id)
		return

	# それ以外は移動（中隊AI経由）
	var use_road: bool = input_controller.is_alt_held() if input_controller else false
	company_ai.order_move(world_pos, use_road)
	print("[CompanyAI] BLUE -> MOVE to %s" % world_pos)


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
				# 移動命令：強制目標をクリア
				element.forced_target_id = ""
				element.current_order_type = GameEnums.OrderType.MOVE
				movement_system.issue_move_order(element, target_pos, use_road)
			GameEnums.OrderType.ATTACK:
				# 攻撃命令（位置指定）：その位置へ移動しつつ交戦
				element.forced_target_id = ""  # 位置指定なので特定目標なし
				element.current_order_type = GameEnums.OrderType.ATTACK
				movement_system.issue_move_order(element, target_pos, use_road)
			GameEnums.OrderType.DEFEND:
				# 防御命令：その位置で防御
				element.forced_target_id = ""
				element.current_order_type = GameEnums.OrderType.DEFEND
				movement_system.issue_move_order(element, target_pos, use_road)
			_:
				# その他のコマンドは移動として処理（暫定）
				element.current_order_type = command_type
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

		# 射程内かチェック
		var distance := element.position.distance_to(target.position)
		var in_range := false
		if element.primary_weapon:
			in_range = element.primary_weapon.is_in_range(distance)

		if in_range:
			# 射程内なら移動停止
			element.current_path = PackedVector2Array()
			element.is_moving = false
		else:
			# 射程外なら目標に向かって移動（射程内に入るまで）
			var use_road: bool = input_controller.is_alt_held() if input_controller else false
			movement_system.issue_move_order(element, target.position, use_road)

		print("[Order] %s -> ATTACK %s (in_range=%s)" % [element.id, target.id, in_range])


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

## 武器を要素に割り当て
## 射撃対象を選択
func _select_target(shooter: ElementData.ElementInstance, _tick: int) -> ElementData.ElementInstance:
	if not vision_system:
		return null

	# 強制交戦目標が設定されている場合は優先
	if shooter.forced_target_id != "":
		var forced_target := world_model.get_element_by_id(shooter.forced_target_id)
		if forced_target and forced_target.state != GameEnums.UnitState.DESTROYED:
			# 視界内にいるか確認
			var contact := vision_system.get_contact(shooter.faction, shooter.forced_target_id)
			if contact and contact.state == GameEnums.ContactState.CONFIRMED:
				# 射程内かチェック
				var distance := shooter.position.distance_to(forced_target.position)
				if shooter.primary_weapon and shooter.primary_weapon.is_in_range(distance):
					return forced_target
			# 射程外または視界外でも、目標が存在する限り他の目標には切り替えない
			# （目標に近づくため移動を続ける）
			return null
		else:
			# 目標が破壊されたら強制目標をクリア
			shooter.forced_target_id = ""
			shooter.order_target_id = ""

	var contacts := vision_system.get_contacts_for_faction(shooter.faction)
	if contacts.size() == 0:
		return null

	var best_target: ElementData.ElementInstance = null
	var best_priority := -1.0

	for contact in contacts:
		# CONFIRMEDのみ射撃可能（RETURN_FIREの場合はSUSも可）
		if shooter.sop_mode == GameEnums.SOPMode.FIRE_AT_WILL:
			if contact.state != GameEnums.ContactState.CONFIRMED:
				continue
		elif shooter.sop_mode == GameEnums.SOPMode.RETURN_FIRE:
			# 被弾時のみ射撃（簡略化：CONFIRMEDのみ）
			if contact.state != GameEnums.ContactState.CONFIRMED:
				continue

		# 実際のElementを取得
		var target := world_model.get_element_by_id(contact.element_id)
		if not target:
			continue
		if target.state == GameEnums.UnitState.DESTROYED:
			continue

		# 射程内かチェック
		var distance := shooter.position.distance_to(target.position)
		if shooter.primary_weapon and not shooter.primary_weapon.is_in_range(distance):
			continue

		# 優先度計算（近い敵を優先）
		var priority := 1000.0 - distance
		if priority > best_priority:
			best_priority = priority
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
