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

# =============================================================================
# 更新
# =============================================================================

func _process(_delta: float) -> void:
	# 常に再描画（ユニット位置が変わるため）
	queue_redraw()
