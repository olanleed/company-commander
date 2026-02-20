class_name OrderPreview
extends Node2D

## 命令プレビュー表示
## 移動経路、防御半径、攻撃扇形などを描画
## 仕様: docs/ui_design_v0.1.md

# =============================================================================
# 定数
# =============================================================================

const PATH_COLOR := Color(0.3, 0.6, 0.9, 0.8)
const PATH_WIDTH := 3.0
const WAYPOINT_RADIUS := 8.0

const DEFEND_RADIUS_COLOR := Color(0.3, 0.8, 0.3, 0.3)
const DEFEND_BORDER_COLOR := Color(0.3, 0.8, 0.3, 0.8)

const ATTACK_ARC_COLOR := Color(0.9, 0.3, 0.3, 0.3)
const ATTACK_BORDER_COLOR := Color(0.9, 0.3, 0.3, 0.8)

const RECON_COLOR := Color(0.7, 0.7, 0.3, 0.5)

# =============================================================================
# 状態
# =============================================================================

var _preview_type: GameEnums.OrderType = GameEnums.OrderType.NONE
var _start_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _path: PackedVector2Array = PackedVector2Array()
var _radius := 100.0  # 防御半径や射程

var _is_visible := false

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	# 最前面に描画
	z_index = 100


func _draw() -> void:
	if not _is_visible:
		return

	match _preview_type:
		GameEnums.OrderType.MOVE:
			_draw_move_preview()
		GameEnums.OrderType.DEFEND:
			_draw_defend_preview()
		GameEnums.OrderType.ATTACK:
			_draw_attack_preview()
		GameEnums.OrderType.RECON:
			_draw_recon_preview()
		GameEnums.OrderType.BREAK_CONTACT:
			_draw_break_contact_preview()
		GameEnums.OrderType.SUPPORT:
			_draw_support_preview()
		_:
			_draw_generic_preview()

# =============================================================================
# プレビュー設定
# =============================================================================

## 移動プレビューを表示
func show_move_preview(start: Vector2, target: Vector2, path: PackedVector2Array = PackedVector2Array()) -> void:
	_preview_type = GameEnums.OrderType.MOVE
	_start_pos = start
	_target_pos = target
	_path = path if path.size() > 0 else PackedVector2Array([start, target])
	_is_visible = true
	queue_redraw()


## 防御プレビューを表示
func show_defend_preview(center: Vector2, radius: float = 100.0) -> void:
	_preview_type = GameEnums.OrderType.DEFEND
	_target_pos = center
	_radius = radius
	_is_visible = true
	queue_redraw()


## 攻撃プレビューを表示
func show_attack_preview(start: Vector2, target: Vector2) -> void:
	_preview_type = GameEnums.OrderType.ATTACK
	_start_pos = start
	_target_pos = target
	_is_visible = true
	queue_redraw()


## 偵察プレビューを表示
func show_recon_preview(start: Vector2, target: Vector2) -> void:
	_preview_type = GameEnums.OrderType.RECON
	_start_pos = start
	_target_pos = target
	_is_visible = true
	queue_redraw()


## 離脱プレビューを表示
func show_break_contact_preview(start: Vector2, rally_point: Vector2) -> void:
	_preview_type = GameEnums.OrderType.BREAK_CONTACT
	_start_pos = start
	_target_pos = rally_point
	_is_visible = true
	queue_redraw()


## 支援プレビューを表示
func show_support_preview(start: Vector2, target: Vector2) -> void:
	_preview_type = GameEnums.OrderType.SUPPORT
	_start_pos = start
	_target_pos = target
	_is_visible = true
	queue_redraw()


## 汎用プレビューを表示
func show_generic_preview(order_type: GameEnums.OrderType, start: Vector2, target: Vector2) -> void:
	_preview_type = order_type
	_start_pos = start
	_target_pos = target
	_is_visible = true
	queue_redraw()


## プレビューを非表示
func hide_preview() -> void:
	_is_visible = false
	_preview_type = GameEnums.OrderType.NONE
	queue_redraw()


## ターゲット位置を更新（マウス追従用）
func update_target(target: Vector2) -> void:
	_target_pos = target
	if _path.size() > 0:
		_path[_path.size() - 1] = target
	queue_redraw()

# =============================================================================
# 描画
# =============================================================================

func _draw_move_preview() -> void:
	# 経路線を描画
	if _path.size() < 2:
		# パスがなければ直線
		draw_line(_start_pos, _target_pos, PATH_COLOR, PATH_WIDTH)
		_draw_waypoint(_target_pos, PATH_COLOR)
		return

	# パスを描画
	for i in range(_path.size() - 1):
		draw_line(_path[i], _path[i + 1], PATH_COLOR, PATH_WIDTH)

	# ウェイポイントを描画
	for i in range(1, _path.size()):
		var is_final := i == _path.size() - 1
		_draw_waypoint(_path[i], PATH_COLOR, is_final)

	# 矢印を描画
	if _path.size() >= 2:
		var last := _path[_path.size() - 1]
		var prev := _path[_path.size() - 2]
		_draw_arrow(prev, last, PATH_COLOR)


func _draw_defend_preview() -> void:
	# 防御半径を描画
	draw_circle(_target_pos, _radius, DEFEND_RADIUS_COLOR)
	draw_arc(_target_pos, _radius, 0, TAU, 64, DEFEND_BORDER_COLOR, 2.0)

	# 中心マーカー
	draw_circle(_target_pos, 10, DEFEND_BORDER_COLOR)

	# 十字
	draw_line(_target_pos + Vector2(-15, 0), _target_pos + Vector2(15, 0), DEFEND_BORDER_COLOR, 2.0)
	draw_line(_target_pos + Vector2(0, -15), _target_pos + Vector2(0, 15), DEFEND_BORDER_COLOR, 2.0)


func _draw_attack_preview() -> void:
	# 攻撃方向の矢印
	draw_line(_start_pos, _target_pos, ATTACK_BORDER_COLOR, PATH_WIDTH)
	_draw_arrow(_start_pos, _target_pos, ATTACK_BORDER_COLOR, 15)

	# 攻撃扇形（射程範囲）
	var direction := (_target_pos - _start_pos).normalized()
	var angle := direction.angle()
	var arc_radius := 150.0
	var arc_half_angle := deg_to_rad(30)  # 60度の扇形

	# 扇形を描画
	var points := PackedVector2Array()
	points.append(_target_pos)

	var steps := 16
	for i in range(steps + 1):
		var a := angle - arc_half_angle + (arc_half_angle * 2) * i / steps
		points.append(_target_pos + Vector2(cos(a), sin(a)) * arc_radius)

	draw_polygon(points, [ATTACK_ARC_COLOR])

	# 扇形の境界
	draw_line(_target_pos, _target_pos + Vector2(cos(angle - arc_half_angle), sin(angle - arc_half_angle)) * arc_radius, ATTACK_BORDER_COLOR, 1.5)
	draw_line(_target_pos, _target_pos + Vector2(cos(angle + arc_half_angle), sin(angle + arc_half_angle)) * arc_radius, ATTACK_BORDER_COLOR, 1.5)
	draw_arc(_target_pos, arc_radius, angle - arc_half_angle, angle + arc_half_angle, 16, ATTACK_BORDER_COLOR, 1.5)


func _draw_recon_preview() -> void:
	# 偵察経路（点線風）
	var total_dist := _start_pos.distance_to(_target_pos)
	var direction := (_target_pos - _start_pos).normalized()
	var dash_length := 20.0
	var gap_length := 10.0

	var current := _start_pos
	var drawn := 0.0

	while drawn < total_dist:
		var dash_end: Vector2 = current + direction * minf(dash_length, total_dist - drawn)
		draw_line(current, dash_end, RECON_COLOR, PATH_WIDTH)
		drawn += dash_length + gap_length
		current = _start_pos + direction * drawn

	# 目標地点の円
	draw_circle(_target_pos, 30, Color(RECON_COLOR.r, RECON_COLOR.g, RECON_COLOR.b, 0.2))
	draw_arc(_target_pos, 30, 0, TAU, 32, RECON_COLOR, 2.0)

	# 視界範囲を示す円（大きめ）
	draw_arc(_target_pos, 100, 0, TAU, 64, Color(RECON_COLOR.r, RECON_COLOR.g, RECON_COLOR.b, 0.3), 1.0, true)


func _draw_break_contact_preview() -> void:
	# 離脱方向（点線）
	var direction := (_target_pos - _start_pos).normalized()

	# 波線風の描画
	var total_dist := _start_pos.distance_to(_target_pos)
	var wave_amplitude := 10.0
	var wave_length := 30.0
	var steps := int(total_dist / 5)

	var prev := _start_pos
	for i in range(1, steps + 1):
		var t: float = float(i) / steps
		var base_pos: Vector2 = _start_pos.lerp(_target_pos, t)
		var perp := Vector2(-direction.y, direction.x)
		var offset := sin(t * total_dist / wave_length * TAU) * wave_amplitude * (1.0 - t)
		var pos := base_pos + perp * offset

		draw_line(prev, pos, Color(0.5, 0.5, 0.5, 0.7), 2.0)
		prev = pos

	# 集結点
	draw_circle(_target_pos, 15, Color(0.5, 0.5, 0.5, 0.5))
	draw_arc(_target_pos, 15, 0, TAU, 16, Color(0.5, 0.5, 0.5), 2.0)


func _draw_support_preview() -> void:
	# 支援ライン
	draw_line(_start_pos, _target_pos, Color(0.4, 0.7, 0.4, 0.8), PATH_WIDTH)

	# 支援範囲の円
	draw_circle(_target_pos, 80, Color(0.4, 0.7, 0.4, 0.2))
	draw_arc(_target_pos, 80, 0, TAU, 32, Color(0.4, 0.7, 0.4, 0.6), 1.5)

	# 十字（支援マーカー）
	draw_line(_target_pos + Vector2(-20, 0), _target_pos + Vector2(20, 0), Color(0.4, 0.7, 0.4), 3.0)
	draw_line(_target_pos + Vector2(0, -20), _target_pos + Vector2(0, 20), Color(0.4, 0.7, 0.4), 3.0)


func _draw_generic_preview() -> void:
	# 汎用の線と目標マーカー
	draw_line(_start_pos, _target_pos, Color(0.7, 0.7, 0.7, 0.7), PATH_WIDTH)
	_draw_waypoint(_target_pos, Color(0.7, 0.7, 0.7))

# =============================================================================
# ヘルパー描画
# =============================================================================

func _draw_waypoint(pos: Vector2, color: Color, is_final: bool = true) -> void:
	if is_final:
		# 最終目標は塗りつぶし
		draw_circle(pos, WAYPOINT_RADIUS, color)
	else:
		# 中間点は枠のみ
		draw_arc(pos, WAYPOINT_RADIUS, 0, TAU, 16, color, 2.0)


func _draw_arrow(from: Vector2, to: Vector2, color: Color, size: float = 12.0) -> void:
	var direction := (to - from).normalized()
	var perp := Vector2(-direction.y, direction.x)

	var arrow_base := to - direction * size
	var arrow_left := arrow_base + perp * (size * 0.5)
	var arrow_right := arrow_base - perp * (size * 0.5)

	var points := PackedVector2Array([to, arrow_left, arrow_right])
	draw_polygon(points, [color])

# =============================================================================
# クエリ
# =============================================================================

func is_showing() -> bool:
	return _is_visible


func get_preview_type() -> GameEnums.OrderType:
	return _preview_type
