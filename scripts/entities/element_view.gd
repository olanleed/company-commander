class_name ElementView
extends Node2D

## Elementの視覚表現
## 仕様書: docs/units_v0.1.md
##
## ElementInstanceを参照し、兵科記号と状態を描画する

# =============================================================================
# エクスポート
# =============================================================================

@export var symbol_scale: float = 1.0

# =============================================================================
# 内部参照
# =============================================================================

var element: ElementData.ElementInstance
var symbol_manager: SymbolManager
var viewer_faction: GameEnums.Faction = GameEnums.Faction.BLUE

var _sprite: Sprite2D
var _selection_indicator: Node2D
var _is_selected: bool = false

## FoW関連
var _contact_state: GameEnums.ContactState = GameEnums.ContactState.CONFIRMED
var _estimated_position: Vector2 = Vector2.ZERO
var _position_error: float = 0.0
var _is_friendly: bool = true

## フェードアウト関連
var _is_fading: bool = false
var _fade_start_tick: int = -1

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	# setup() が先に呼ばれた場合は既に作成済み
	if not _sprite:
		_setup_sprite()
		_setup_selection_indicator()
	# setup() が _ready() より前に呼ばれた場合、ここでシンボルを更新
	if element and symbol_manager:
		update_symbol()


func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Symbol"
	_sprite.scale = Vector2(symbol_scale, symbol_scale)
	add_child(_sprite)


func _setup_selection_indicator() -> void:
	_selection_indicator = Node2D.new()
	_selection_indicator.name = "SelectionIndicator"
	_selection_indicator.visible = false
	add_child(_selection_indicator)

# =============================================================================
# 初期化
# =============================================================================

## Elementを設定
func setup(p_element: ElementData.ElementInstance, p_symbol_manager: SymbolManager, p_viewer: GameEnums.Faction) -> void:
	element = p_element
	symbol_manager = p_symbol_manager
	viewer_faction = p_viewer
	_is_friendly = (element.faction == viewer_faction)
	# _ready() がまだ呼ばれていない場合はスプライトを先に作成
	if not _sprite:
		_setup_sprite()
		_setup_selection_indicator()
	update_symbol()
	update_position_immediate()
	# 初期状態で視認性を設定（味方は不透明、敵はFoW次第）
	_update_visibility()


## シンボルを更新
func update_symbol() -> void:
	if not element or not symbol_manager or not _sprite:
		return

	var texture := symbol_manager.get_symbol_for_element(element, viewer_faction)
	if texture:
		_sprite.texture = texture

# =============================================================================
# 位置更新
# =============================================================================

## 即時位置更新 (補間なし)
func update_position_immediate() -> void:
	if element:
		position = element.position
		_apply_rotation(element.facing)


## 補間位置更新
func update_position_interpolated(alpha: float) -> void:
	if element:
		position = element.get_interpolated_position(alpha)
		_apply_rotation(element.get_interpolated_facing(alpha))


## 回転を適用（スプライトは逆回転で補正）
func _apply_rotation(facing: float) -> void:
	rotation = facing
	# スプライトは常に上向きを維持（親の回転を打ち消す）
	if _sprite:
		_sprite.rotation = -facing

# =============================================================================
# FoW（視界）更新
# =============================================================================

## 敵ユニットの視界状態を更新
func update_contact_state(state: GameEnums.ContactState, est_pos: Vector2 = Vector2.ZERO, error: float = 0.0) -> void:
	_contact_state = state
	_estimated_position = est_pos
	_position_error = error
	_update_visibility()


## 視界状態に応じた表示更新
func _update_visibility() -> void:
	if _is_friendly:
		# 味方は常に表示
		visible = true
		modulate = Color(1, 1, 1, 1)
		if _sprite:
			_sprite.modulate = Color(1, 1, 1, 1)
		return

	# 敵の表示は視界状態に依存
	match _contact_state:
		GameEnums.ContactState.CONFIRMED:
			visible = true
			modulate = Color(1, 1, 1, 1)
			if _sprite:
				_sprite.modulate = Color(1, 1, 1, 1)
		GameEnums.ContactState.SUSPECTED:
			visible = true
			modulate = Color(1, 1, 1, 0.5)  # 半透明
			# SUS時は推定位置を使用
			position = _estimated_position
		GameEnums.ContactState.LOST:
			visible = true
			modulate = Color(1, 1, 1, 0.25)  # さらに薄く
			position = _estimated_position
		GameEnums.ContactState.UNKNOWN:
			visible = false


## 敵ユニットの位置更新（FoW考慮）
func update_position_with_fow(alpha: float) -> void:
	if _is_friendly:
		# 味方は実際の位置
		update_position_interpolated(alpha)
	else:
		# 敵はContact状態に応じた位置
		match _contact_state:
			GameEnums.ContactState.CONFIRMED:
				# CONFなら実際の位置
				update_position_interpolated(alpha)
			GameEnums.ContactState.SUSPECTED, GameEnums.ContactState.LOST:
				# SUS/LOSTなら推定位置（既にupdate_contact_stateで設定済み）
				pass
			_:
				pass

# =============================================================================
# 選択
# =============================================================================

## 選択状態を設定
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_selection_indicator.visible = selected
	queue_redraw()


func is_selected() -> bool:
	return _is_selected

# =============================================================================
# 描画
# =============================================================================

func _draw() -> void:
	if not element:
		return

	# 破壊済みユニットは爆発マークのみ描画
	if element.is_destroyed:
		if element.catastrophic_kill:
			_draw_explosion_mark()
		else:
			_draw_destroyed_mark()
		return

	# 敵のSUS/LOST時は位置誤差円を描画
	if not _is_friendly and _contact_state == GameEnums.ContactState.SUSPECTED and _position_error > 0:
		_draw_error_ellipse()

	# 選択時のハイライト（円なので回転の影響を受けない）
	if _is_selected:
		draw_arc(Vector2.ZERO, 40, 0, TAU, 32, Color.YELLOW, 3.0)

	# 移動パス表示 (選択時、味方のみ)
	if _is_selected and _is_friendly and element.current_path.size() > 0:
		_draw_path()

	# HP/状態バー（味方のみ、または敵CONF時）
	if _is_friendly or _contact_state == GameEnums.ContactState.CONFIRMED:
		_draw_status_bar()


## ワールド座標をローカル座標に変換（回転を考慮）
func _world_to_local_point(world_pos: Vector2) -> Vector2:
	var offset := world_pos - position
	# 回転の逆変換を適用
	return offset.rotated(-rotation)


## 位置誤差楕円の描画
func _draw_error_ellipse() -> void:
	if _position_error <= 0:
		return

	# 回転を打ち消して描画
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)

	# 誤差円（破線風に複数の弧で描画）
	var error_color := Color(1.0, 0.5, 0.0, 0.4)
	var segments := 8
	var gap := PI / 16.0

	for i in range(segments):
		var start_angle := (TAU / segments) * i + gap
		var end_angle := (TAU / segments) * (i + 1) - gap
		draw_arc(Vector2.ZERO, _position_error, start_angle, end_angle, 8, error_color, 2.0)

	# 変換をリセット
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_path() -> void:
	if element.current_path.size() < 2:
		return

	var path_color := Color(0.2, 0.8, 0.2, 0.5)
	var start_index := element.path_index

	# ローカル座標に変換して描画（回転を考慮）
	for i in range(start_index, element.current_path.size() - 1):
		var from := _world_to_local_point(element.current_path[i])
		var to := _world_to_local_point(element.current_path[i + 1])
		draw_line(from, to, path_color, 2.0)

	# 目標地点マーカー
	if element.current_path.size() > 0:
		var target := _world_to_local_point(element.current_path[-1])
		draw_circle(target, 8, Color(0.2, 0.8, 0.2, 0.7))


func _draw_status_bar() -> void:
	if not element or not element.element_type:
		return

	var bar_width := 50.0
	var bar_height := 6.0
	var bar_y := 35.0

	# 回転を打ち消すためにdraw_set_transformを使用
	# ローカル座標系を回転前の状態に戻す
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)

	# 背景
	var bg_rect := Rect2(-bar_width / 2, bar_y, bar_width, bar_height)
	draw_rect(bg_rect, Color(0.2, 0.2, 0.2, 0.8))

	# HP
	var hp_ratio := float(element.current_strength) / float(element.element_type.max_strength)
	var hp_color := _get_hp_color(hp_ratio)
	var hp_rect := Rect2(-bar_width / 2, bar_y, bar_width * hp_ratio, bar_height)
	draw_rect(hp_rect, hp_color)

	# 抑圧バー (HPバーの上)
	if element.suppression > 0.01:
		var sup_y := bar_y - bar_height - 2
		var sup_rect := Rect2(-bar_width / 2, sup_y, bar_width * element.suppression, bar_height)
		draw_rect(sup_rect, Color(1.0, 0.5, 0.0, 0.8))

	# 射撃中アイコン（ユニットの右上）
	if element.current_target_id != "":
		_draw_firing_indicator()

	# 変換をリセット
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 射撃中インジケータを描画
func _draw_firing_indicator() -> void:
	var icon_pos := Vector2(30, -30)
	var icon_size := 8.0

	# マズルフラッシュ風のアイコン（三角形＋円）
	var flash_color := Color(1.0, 0.8, 0.2, 0.9)

	# 中心の円
	draw_circle(icon_pos, icon_size * 0.5, flash_color)

	# 放射状の線（4方向）
	for i in range(4):
		var angle := (PI / 4.0) + (PI / 2.0) * i
		var dir := Vector2.from_angle(angle)
		draw_line(icon_pos + dir * icon_size * 0.6, icon_pos + dir * icon_size * 1.2, flash_color, 2.0)


## 爆発マーク描画（catastrophic kill用）
func _draw_explosion_mark() -> void:
	var center := Vector2.ZERO
	var size := 25.0

	# オレンジ〜赤のグラデーション円
	draw_circle(center, size, Color(1.0, 0.3, 0.0, 0.8))
	draw_circle(center, size * 0.6, Color(1.0, 0.6, 0.0, 0.9))
	draw_circle(center, size * 0.3, Color(1.0, 0.9, 0.3, 1.0))

	# 爆発の放射線
	var explosion_color := Color(1.0, 0.5, 0.0, 0.7)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var dir := Vector2.from_angle(angle)
		draw_line(center + dir * size * 0.8, center + dir * size * 1.4, explosion_color, 3.0)


## 破壊マーク描画（通常破壊用）
func _draw_destroyed_mark() -> void:
	var center := Vector2.ZERO
	var size := 20.0

	# 暗いグレーの円
	draw_circle(center, size, Color(0.3, 0.3, 0.3, 0.7))

	# Xマーク
	var x_color := Color(0.8, 0.2, 0.2, 0.9)
	var offset := size * 0.7
	draw_line(center + Vector2(-offset, -offset), center + Vector2(offset, offset), x_color, 4.0)
	draw_line(center + Vector2(offset, -offset), center + Vector2(-offset, offset), x_color, 4.0)


func _get_hp_color(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0.2, 0.8, 0.2)
	elif ratio > 0.3:
		return Color(0.8, 0.8, 0.2)
	else:
		return Color(0.8, 0.2, 0.2)

# =============================================================================
# ユーティリティ
# =============================================================================

## クリック判定用の半径
const CLICK_RADIUS: float = 32.0


## クリック判定用の矩形を取得（後方互換性のため維持）
func get_click_rect() -> Rect2:
	var half_size := Vector2(CLICK_RADIUS, CLICK_RADIUS) * symbol_scale
	return Rect2(position - half_size, half_size * 2)


## ポイントがこのElementの上にあるか（円形判定で回転に依存しない）
func contains_point(point: Vector2) -> bool:
	var distance := position.distance_to(point)
	return distance <= CLICK_RADIUS * symbol_scale

# =============================================================================
# フェードアウト処理
# =============================================================================

## フェードアウトを開始
func start_fade_out(start_tick: int) -> void:
	_is_fading = true
	_fade_start_tick = start_tick


## フェードを更新（完全に消えたらtrueを返す）
func update_fade(current_tick: int) -> bool:
	if not _is_fading:
		return false

	var elapsed := current_tick - _fade_start_tick
	var progress := clampf(
		float(elapsed) / float(GameConstants.DESTROY_FADE_DURATION_TICKS),
		0.0, 1.0
	)
	modulate.a = 1.0 - progress

	return progress >= 1.0  # 完全に消えたらtrue


## フェード中かどうか
func is_fading() -> bool:
	return _is_fading
