class_name CapturePointView
extends Node2D

## 拠点ビュー
## 仕様書: docs/capture_v0.1.md
##
## 拠点の制圧状態を視覚化する。
## - 外側に大きな占領ゾーン表示
## - 中央に進行リング
## - 制圧率のテキスト表示
## - CONTESTEDは警告表示

# =============================================================================
# 定数
# =============================================================================

## 基本サイズ（マップ上の実サイズに合わせる）
const ZONE_RADIUS: float = 40.0  ## CP_RADIUS_Mと同じ
const RING_RADIUS: float = 25.0
const RING_WIDTH: float = 8.0
const CENTER_RADIUS: float = 12.0

## 色定義
const COLOR_BLUE := Color(0.2, 0.5, 1.0, 1.0)
const COLOR_BLUE_LIGHT := Color(0.4, 0.6, 1.0, 0.4)
const COLOR_RED := Color(1.0, 0.3, 0.3, 1.0)
const COLOR_RED_LIGHT := Color(1.0, 0.4, 0.4, 0.4)
const COLOR_NEUTRAL := Color(0.6, 0.6, 0.6, 1.0)
const COLOR_NEUTRAL_LIGHT := Color(0.5, 0.5, 0.5, 0.25)
const COLOR_CONTESTED := Color(1.0, 0.8, 0.0, 1.0)
const COLOR_BG := Color(0.15, 0.15, 0.15, 0.85)
const COLOR_OUTLINE := Color(1.0, 1.0, 1.0, 0.5)

## アニメーション
const PULSE_SPEED: float = 4.0
const CONTESTED_BLINK_SPEED: float = 6.0

# =============================================================================
# 状態
# =============================================================================

var cp: MapData.CapturePoint
var _time: float = 0.0
var _label: Label  ## CP ID表示用

# =============================================================================
# ライフサイクル
# =============================================================================

func _init(p_cp: MapData.CapturePoint) -> void:
	cp = p_cp
	position = cp.position


func _ready() -> void:
	# ユニットより下、背景より上に表示
	z_index = 1

	# CP IDラベルを作成
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	_update_label()
	queue_redraw()


func _update_label() -> void:
	if not cp or not _label:
		return

	# 制圧率をパーセントで表示
	var ratio := cp.get_control_ratio()
	var percent := int(absf(ratio) * 100)

	# 状態によって表示を変更
	var state_text := ""
	match cp.state:
		GameEnums.CPState.CONTROLLED_BLUE:
			state_text = "BLUE"
			_label.add_theme_color_override("font_color", COLOR_BLUE)
		GameEnums.CPState.CONTROLLED_RED:
			state_text = "RED"
			_label.add_theme_color_override("font_color", COLOR_RED)
		GameEnums.CPState.CONTESTED:
			state_text = "!"
			_label.add_theme_color_override("font_color", COLOR_CONTESTED)
		GameEnums.CPState.NEUTRAL:
			state_text = "-"
			_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
		_:
			# 占領中/中和中は進行率を表示
			state_text = "%d%%" % percent
			if ratio > 0:
				_label.add_theme_color_override("font_color", COLOR_BLUE)
			else:
				_label.add_theme_color_override("font_color", COLOR_RED)

	_label.text = "%s\n%s" % [cp.id, state_text]
	_label.position = Vector2(-30, -20)
	_label.size = Vector2(60, 40)


func _draw() -> void:
	if not cp:
		return

	# 1. 占領ゾーン（大きな半透明の円）
	_draw_zone_circle()

	# 2. 進行リング
	_draw_progress_ring()

	# 3. 中央の状態表示
	_draw_center_indicator()

	# 4. CONTESTED警告
	if cp.state == GameEnums.CPState.CONTESTED:
		_draw_contested_indicator()


# =============================================================================
# 描画メソッド
# =============================================================================

## 占領ゾーンを描画
func _draw_zone_circle() -> void:
	var zone_color := _get_zone_color()

	# ゾーン塗りつぶし
	draw_circle(Vector2.ZERO, ZONE_RADIUS, zone_color)

	# ゾーンアウトライン（点線風）
	var outline_color := _get_owner_color()
	outline_color.a = 0.8
	_draw_dashed_circle(Vector2.ZERO, ZONE_RADIUS, outline_color, 2.0)


## 点線の円を描画
func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
	var segments := 24
	var dash_ratio := 0.6

	for i in range(segments):
		var start_angle := float(i) / float(segments) * TAU
		var end_angle := start_angle + (TAU / float(segments)) * dash_ratio

		var start_pt := center + Vector2(cos(start_angle), sin(start_angle)) * radius
		var end_pt := center + Vector2(cos(end_angle), sin(end_angle)) * radius
		draw_line(start_pt, end_pt, color, width)


## 進行リングを描画
func _draw_progress_ring() -> void:
	var ratio := cp.get_control_ratio()  # -1.0 ~ +1.0
	var abs_ratio := absf(ratio)

	# 背景リング（常に表示）
	_draw_arc_ring(Vector2.ZERO, RING_RADIUS, RING_WIDTH, Color(0.2, 0.2, 0.2, 0.7), 0.0, TAU)

	# 進行リングの色を決定
	var ring_color: Color
	if ratio > 0:
		ring_color = COLOR_BLUE
	elif ratio < 0:
		ring_color = COLOR_RED
	else:
		ring_color = COLOR_NEUTRAL

	# 進行中の場合はパルス
	var is_progressing := cp.state in [
		GameEnums.CPState.CAPTURING_BLUE, GameEnums.CPState.CAPTURING_RED,
		GameEnums.CPState.NEUTRALIZING_BLUE, GameEnums.CPState.NEUTRALIZING_RED
	]

	if is_progressing:
		var pulse := (sin(_time * PULSE_SPEED) + 1.0) / 2.0 * 0.4 + 0.6
		ring_color.a = pulse

	# 進行リング（上から時計回り）
	if abs_ratio > 0.001:
		var start_angle := -PI / 2.0
		var end_angle := start_angle + abs_ratio * TAU
		_draw_arc_ring(Vector2.ZERO, RING_RADIUS, RING_WIDTH, ring_color, start_angle, end_angle)

	# 完全支配時は光沢効果
	if cp.state == GameEnums.CPState.CONTROLLED_BLUE or cp.state == GameEnums.CPState.CONTROLLED_RED:
		var glow_color := ring_color
		glow_color.a = 0.3
		draw_circle(Vector2.ZERO, RING_RADIUS + RING_WIDTH, glow_color)


## 弧形のリングを描画
func _draw_arc_ring(center: Vector2, radius: float, width: float, color: Color, start: float, end: float) -> void:
	var points := 48
	var outer_radius := radius + width / 2.0
	var inner_radius := radius - width / 2.0

	var outer_points := PackedVector2Array()
	var inner_points := PackedVector2Array()

	for i in range(points + 1):
		var t := float(i) / float(points)
		var angle := lerpf(start, end, t)
		outer_points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
		inner_points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)

	# ポリゴンを構築
	var polygon := PackedVector2Array()
	for p in outer_points:
		polygon.append(p)
	for i in range(inner_points.size() - 1, -1, -1):
		polygon.append(inner_points[i])

	if polygon.size() >= 3:
		draw_colored_polygon(polygon, color)


## 中央の状態インジケーター
func _draw_center_indicator() -> void:
	var owner_color := _get_owner_color()

	# 背景
	draw_circle(Vector2.ZERO, CENTER_RADIUS, COLOR_BG)

	# アウトライン
	_draw_arc_ring(Vector2.ZERO, CENTER_RADIUS, 2.0, owner_color, 0.0, TAU)


## CONTESTED警告を描画
func _draw_contested_indicator() -> void:
	var blink := (sin(_time * CONTESTED_BLINK_SPEED) + 1.0) / 2.0
	var color := Color(COLOR_CONTESTED.r, COLOR_CONTESTED.g, COLOR_CONTESTED.b, blink * 0.9)

	# 外側に警告リング（太め）
	_draw_arc_ring(Vector2.ZERO, ZONE_RADIUS + 5.0, 4.0, color, 0.0, TAU)

	# 三角警告マーク（上部）
	var warn_pos := Vector2(0, -ZONE_RADIUS - 15.0)
	var tri_size := 12.0
	var triangle := PackedVector2Array([
		warn_pos + Vector2(0, -tri_size),
		warn_pos + Vector2(-tri_size * 0.8, tri_size * 0.6),
		warn_pos + Vector2(tri_size * 0.8, tri_size * 0.6),
	])
	draw_colored_polygon(triangle, color)

	# 三角形の中の「!」
	draw_line(warn_pos + Vector2(0, -tri_size * 0.4), warn_pos + Vector2(0, tri_size * 0.1), COLOR_BG, 3.0)
	draw_circle(warn_pos + Vector2(0, tri_size * 0.35), 2.0, COLOR_BG)


## ゾーンの色を取得（半透明）
func _get_zone_color() -> Color:
	match cp.state:
		GameEnums.CPState.CONTROLLED_BLUE, GameEnums.CPState.CAPTURING_BLUE:
			return COLOR_BLUE_LIGHT
		GameEnums.CPState.CONTROLLED_RED, GameEnums.CPState.CAPTURING_RED:
			return COLOR_RED_LIGHT
		GameEnums.CPState.NEUTRALIZING_BLUE:
			return COLOR_BLUE_LIGHT.lerp(COLOR_NEUTRAL_LIGHT, 0.5)
		GameEnums.CPState.NEUTRALIZING_RED:
			return COLOR_RED_LIGHT.lerp(COLOR_NEUTRAL_LIGHT, 0.5)
		GameEnums.CPState.CONTESTED:
			var blink := (sin(_time * CONTESTED_BLINK_SPEED) + 1.0) / 2.0 * 0.3 + 0.2
			return Color(COLOR_CONTESTED.r, COLOR_CONTESTED.g, COLOR_CONTESTED.b, blink)
		_:
			return COLOR_NEUTRAL_LIGHT


## 支配陣営の色を取得
func _get_owner_color() -> Color:
	match cp.state:
		GameEnums.CPState.CONTROLLED_BLUE, GameEnums.CPState.CAPTURING_BLUE:
			return COLOR_BLUE
		GameEnums.CPState.CONTROLLED_RED, GameEnums.CPState.CAPTURING_RED:
			return COLOR_RED
		GameEnums.CPState.NEUTRALIZING_BLUE:
			return COLOR_BLUE.lerp(COLOR_NEUTRAL, 0.4)
		GameEnums.CPState.NEUTRALIZING_RED:
			return COLOR_RED.lerp(COLOR_NEUTRAL, 0.4)
		GameEnums.CPState.CONTESTED:
			return COLOR_CONTESTED
		_:
			return COLOR_NEUTRAL


# =============================================================================
# 公開メソッド
# =============================================================================

## CPデータを更新
func update_cp(p_cp: MapData.CapturePoint) -> void:
	cp = p_cp
