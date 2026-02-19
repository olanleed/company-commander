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
	# _ready() がまだ呼ばれていない場合はスプライトを先に作成
	if not _sprite:
		_setup_sprite()
		_setup_selection_indicator()
	update_symbol()
	update_position_immediate()


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
		rotation = element.facing


## 補間位置更新
func update_position_interpolated(alpha: float) -> void:
	if element:
		position = element.get_interpolated_position(alpha)
		rotation = element.get_interpolated_facing(alpha)

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

	# 選択時のハイライト
	if _is_selected:
		draw_arc(Vector2.ZERO, 40, 0, TAU, 32, Color.YELLOW, 3.0)

	# 移動パス表示 (選択時)
	if _is_selected and element.current_path.size() > 0:
		_draw_path()

	# HP/状態バー
	_draw_status_bar()


func _draw_path() -> void:
	if element.current_path.size() < 2:
		return

	var path_color := Color(0.2, 0.8, 0.2, 0.5)
	var start_index := element.path_index

	# ローカル座標に変換して描画
	for i in range(start_index, element.current_path.size() - 1):
		var from := element.current_path[i] - position
		var to := element.current_path[i + 1] - position
		draw_line(from, to, path_color, 2.0)

	# 目標地点マーカー
	if element.current_path.size() > 0:
		var target := element.current_path[-1] - position
		draw_circle(target, 8, Color(0.2, 0.8, 0.2, 0.7))


func _draw_status_bar() -> void:
	if not element or not element.element_type:
		return

	var bar_width := 50.0
	var bar_height := 6.0
	var bar_y := 35.0

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

## クリック判定用の矩形を取得
func get_click_rect() -> Rect2:
	var half_size := Vector2(32, 32) * symbol_scale
	return Rect2(position - half_size, half_size * 2)


## ポイントがこのElementの上にあるか
func contains_point(point: Vector2) -> bool:
	return get_click_rect().has_point(point)
