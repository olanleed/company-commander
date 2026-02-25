class_name TacticalOverlay
extends Node2D

## 戦術オーバーレイ
## 選択ユニットの視界範囲と交戦目標（ロックオン）を描画

# =============================================================================
# 参照
# =============================================================================

var world_model: WorldModel
var vision_system: VisionSystem
var _selected_elements: Array[ElementData.ElementInstance] = []

# =============================================================================
# 色設定
# =============================================================================

## 視界範囲（選択ユニットのみ表示）
const COLOR_VIEW_RANGE_FRIENDLY: Color = Color(0.2, 0.6, 1.0, 0.15)  # 青系、薄い塗り
const COLOR_VIEW_RANGE_BORDER: Color = Color(0.3, 0.7, 1.0, 0.4)     # 境界線

## ロックオンターゲットマーカー
const COLOR_TARGET_MARKER: Color = Color(1.0, 0.5, 0.0, 0.9)         # オレンジ

## 間接射撃目標（砲兵用）
const COLOR_FIRE_MISSION_TARGET: Color = Color(1.0, 0.3, 0.1, 0.8)   # 赤オレンジ
const COLOR_FIRE_MISSION_CEP: Color = Color(1.0, 0.5, 0.2, 0.3)      # CEP範囲（半透明）

## 砲兵展開ゲージ
const COLOR_DEPLOY_BAR_BG: Color = Color(0.2, 0.2, 0.2, 0.7)         # 背景（暗いグレー）
const COLOR_DEPLOY_BAR_DEPLOYING: Color = Color(1.0, 0.8, 0.2, 0.9)  # 展開中（黄色）
const COLOR_DEPLOY_BAR_PACKING: Color = Color(0.8, 0.4, 0.1, 0.9)    # 撤収中（オレンジ）
const COLOR_DEPLOY_BAR_DEPLOYED: Color = Color(0.2, 0.8, 0.3, 0.9)   # 展開完了（緑）
const DEPLOY_BAR_WIDTH: float = 40.0
const DEPLOY_BAR_HEIGHT: float = 6.0
const DEPLOY_BAR_OFFSET_Y: float = -35.0  # ユニットの上に表示

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	# ユニットより上に描画されるようにz_indexを設定
	z_index = 100


func setup(p_world_model: WorldModel, p_vision_system: VisionSystem = null) -> void:
	world_model = p_world_model
	vision_system = p_vision_system


func set_selected_elements(elements: Array[ElementData.ElementInstance]) -> void:
	_selected_elements = elements
	queue_redraw()

# =============================================================================
# 描画
# =============================================================================

func _draw() -> void:
	if not world_model:
		return

	# 1. 選択ユニットの視界範囲を描画
	_draw_view_ranges()

	# 2. 全ユニットの交戦線を描画
	_draw_engagement_lines()

	# 3. 選択中の砲兵ユニットの射撃地点とCEPを描画
	_draw_fire_mission_targets()

	# 4. 選択中の砲兵ユニットの展開ゲージを描画
	_draw_artillery_deploy_bars()


## 選択ユニットの視界範囲を描画
func _draw_view_ranges() -> void:
	for element in _selected_elements:
		if not element or element.state == GameEnums.UnitState.DESTROYED:
			continue
		if not element.element_type:
			continue

		# VisionSystemを使用して実効視界範囲を取得
		# 実効視界 = r_base × m_observer（抑圧係数）
		# これが「静止している敵が見える最大距離」
		var effective_range: float
		if vision_system:
			effective_range = vision_system.get_effective_view_range(element)
		else:
			# フォールバック（VisionSystemがない場合）
			effective_range = element.element_type.spot_range_base

		# 実効視界範囲円を描画（静止敵を発見できる範囲）
		_draw_view_circle(element.position, effective_range)

		# 移動中の敵目標に対する拡張視界範囲（+25%）を破線で表示
		# VisionSystemでは移動中の車両は+25%、歩兵は+15%で発見される
		var extended_range: float = effective_range * 1.25
		_draw_extended_view_circle(element.position, extended_range)


## 視界範囲円を描画
func _draw_view_circle(center: Vector2, radius: float) -> void:
	# 塗りつぶし（半透明）
	draw_circle(center, radius, COLOR_VIEW_RANGE_FRIENDLY)

	# 境界線
	draw_arc(center, radius, 0, TAU, 64, COLOR_VIEW_RANGE_BORDER, 2.0)


## 拡張視界範囲円を描画（移動中の敵目標に対する範囲、破線）
func _draw_extended_view_circle(center: Vector2, radius: float) -> void:
	# 破線スタイルで境界線のみ（塗りつぶしなし）
	var dash_color := Color(0.5, 0.7, 1.0, 0.25)  # より薄い色
	var segments := 32
	var arc_length := TAU / float(segments)

	# 交互に描画して破線を表現
	for i in range(segments):
		if i % 2 == 0:
			var start_angle := arc_length * float(i)
			var end_angle := arc_length * float(i + 1)
			draw_arc(center, radius, start_angle, end_angle, 8, dash_color, 1.5)


## 選択ユニットのロックオンターゲットを描画
func _draw_engagement_lines() -> void:
	if not world_model:
		return

	# 選択ユニットのロックオンのみ表示
	for element in _selected_elements:
		if not element or element.state == GameEnums.UnitState.DESTROYED:
			continue

		# 交戦目標がある場合のみ描画
		if element.current_target_id == "":
			continue

		var target := world_model.get_element_by_id(element.current_target_id)
		if not target:
			continue

		# 破壊されたターゲットへの交戦線は描画しない
		if target.state == GameEnums.UnitState.DESTROYED:
			continue

		# ターゲットマーカーのみ描画（射撃線と被らないよう線は描画しない）
		_draw_target_marker(target.position)


## ターゲットマーカーを描画（菱形）
func _draw_target_marker(center: Vector2) -> void:
	var size := 15.0
	var color := COLOR_TARGET_MARKER  # オレンジ色

	# 菱形の4頂点
	var points := PackedVector2Array([
		center + Vector2(0, -size),    # 上
		center + Vector2(size, 0),     # 右
		center + Vector2(0, size),     # 下
		center + Vector2(-size, 0),    # 左
	])

	# 塗りつぶし（半透明）
	var fill_color := Color(color.r, color.g, color.b, 0.3)
	draw_colored_polygon(points, fill_color)

	# 輪郭
	for i in range(4):
		draw_line(points[i], points[(i + 1) % 4], color, 2.0)


## 選択中の砲兵ユニットの射撃地点とCEPを描画
## 展開中でも射撃目標が設定されていれば表示する
func _draw_fire_mission_targets() -> void:
	for element in _selected_elements:
		if not element or element.state == GameEnums.UnitState.DESTROYED:
			continue

		# 射撃目標が設定されているユニットのみ（展開中でも表示）
		var target_pos: Vector2 = element.fire_mission_target
		if target_pos == Vector2.ZERO:
			continue

		# 間接射撃武器からCEPを取得
		var sigma_hit: float = 50.0  # デフォルト値
		for weapon in element.weapons:
			if weapon.fire_model == WeaponData.FireModel.INDIRECT:
				sigma_hit = weapon.sigma_hit_m
				# 距離による精度低下を考慮
				var distance := element.position.distance_to(target_pos)
				var range_factor := clampf(distance / weapon.max_range_m, 0.5, 1.5)
				sigma_hit *= range_factor
				break

		# 射撃地点からユニットへの線を描画
		_draw_fire_mission_line(element.position, target_pos)

		# CEP範囲を描画（1σ = 68%、2σ = 95%）
		_draw_cep_circle(target_pos, sigma_hit)

		# 射撃地点マーカーを描画
		_draw_fire_mission_marker(target_pos)


## 射撃地点への線を描画（破線）
func _draw_fire_mission_line(from: Vector2, to: Vector2) -> void:
	var color := COLOR_FIRE_MISSION_TARGET
	var direction := (to - from).normalized()
	var distance := from.distance_to(to)
	var dash_length := 20.0
	var gap_length := 10.0
	var pos := 0.0

	while pos < distance:
		var start := from + direction * pos
		var end_pos := minf(pos + dash_length, distance)
		var end := from + direction * end_pos
		draw_line(start, end, color, 2.0)
		pos += dash_length + gap_length


## CEP範囲を描画
func _draw_cep_circle(center: Vector2, sigma: float) -> void:
	# 1σ範囲（68%の弾が落ちる範囲）- 実線
	draw_arc(center, sigma, 0, TAU, 32, COLOR_FIRE_MISSION_TARGET, 2.0)

	# 2σ範囲（95%の弾が落ちる範囲）- 破線
	var sigma_2 := sigma * 2.0
	var segments := 24
	var arc_length := TAU / float(segments)
	var dash_color := Color(COLOR_FIRE_MISSION_TARGET.r, COLOR_FIRE_MISSION_TARGET.g, COLOR_FIRE_MISSION_TARGET.b, 0.5)

	for i in range(segments):
		if i % 2 == 0:
			var start_angle := arc_length * float(i)
			var end_angle := arc_length * float(i + 1)
			draw_arc(center, sigma_2, start_angle, end_angle, 4, dash_color, 1.5)

	# CEP範囲の塗りつぶし（半透明）
	draw_circle(center, sigma, COLOR_FIRE_MISSION_CEP)


## 射撃地点マーカーを描画（十字）
func _draw_fire_mission_marker(center: Vector2) -> void:
	var size := 12.0
	var color := COLOR_FIRE_MISSION_TARGET

	# 十字を描画
	draw_line(center + Vector2(-size, 0), center + Vector2(size, 0), color, 3.0)
	draw_line(center + Vector2(0, -size), center + Vector2(0, size), color, 3.0)

	# 中心の小さな円
	draw_circle(center, 4.0, color)


## 砲兵ユニットの展開ゲージを描画
func _draw_artillery_deploy_bars() -> void:
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	for element in _selected_elements:
		if not element or element.state == GameEnums.UnitState.DESTROYED:
			continue

		# 砲兵ユニットのみ
		var archetype := element.element_type.id if element.element_type else ""
		if archetype != "SP_ARTILLERY" and archetype != "SP_MORTAR":
			continue

		# 展開中または撤収中のみゲージを表示
		var show_bar := false
		var bar_color := COLOR_DEPLOY_BAR_DEPLOYING
		var progress := 0.0

		match element.artillery_deploy_state:
			ADS.DEPLOYING:
				show_bar = true
				bar_color = COLOR_DEPLOY_BAR_DEPLOYING
				progress = element.artillery_deploy_progress
			ADS.PACKING:
				show_bar = true
				bar_color = COLOR_DEPLOY_BAR_PACKING
				progress = element.artillery_deploy_progress
			ADS.DEPLOYED:
				# 展開完了時は短く緑のバーを表示（射撃任務がある場合のみ）
				if element.fire_mission_target != Vector2.ZERO:
					show_bar = true
					bar_color = COLOR_DEPLOY_BAR_DEPLOYED
					progress = 1.0

		if not show_bar:
			continue

		# ゲージの位置を計算（ユニットの上）
		var bar_pos := element.position + Vector2(-DEPLOY_BAR_WIDTH / 2, DEPLOY_BAR_OFFSET_Y)

		# 背景バー
		var bg_rect := Rect2(bar_pos, Vector2(DEPLOY_BAR_WIDTH, DEPLOY_BAR_HEIGHT))
		draw_rect(bg_rect, COLOR_DEPLOY_BAR_BG)

		# 進捗バー
		var progress_width := DEPLOY_BAR_WIDTH * clampf(progress, 0.0, 1.0)
		var progress_rect := Rect2(bar_pos, Vector2(progress_width, DEPLOY_BAR_HEIGHT))
		draw_rect(progress_rect, bar_color)

		# 枠線
		draw_rect(bg_rect, Color(1.0, 1.0, 1.0, 0.5), false, 1.0)

		# ラベル（小さいフォントで表示）
		# Note: draw_stringはデフォルトフォントを使用
		# フォントサイズは小さく、バーの上に表示


# =============================================================================
# 更新
# =============================================================================

func _process(_delta: float) -> void:
	# 常に再描画（ユニット位置が変わるため）
	queue_redraw()
