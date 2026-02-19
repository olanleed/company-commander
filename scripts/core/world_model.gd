class_name WorldModel
extends RefCounted

## ゲーム世界の状態を保持するモデル
## 仕様書: docs/game_loop_v0.1.md
##
## 全ユニット、拠点状態、FoWなどの純データを管理

# =============================================================================
# シグナル
# =============================================================================

signal element_added(element: ElementData.ElementInstance)
signal element_removed(element: ElementData.ElementInstance)
signal element_destroyed(element: ElementData.ElementInstance)

# =============================================================================
# データ
# =============================================================================

## 全Element
var elements: Array[ElementData.ElementInstance] = []

## 陣営別Element (型付き配列で初期化)
var elements_by_faction: Dictionary = {}


func _init() -> void:
	# 型付き配列で初期化
	var blue_elements: Array[ElementData.ElementInstance] = []
	var red_elements: Array[ElementData.ElementInstance] = []
	elements_by_faction[GameEnums.Faction.BLUE] = blue_elements
	elements_by_faction[GameEnums.Faction.RED] = red_elements

## ID -> Element マップ
var _element_map: Dictionary = {}

## 次のElement ID
var _next_element_id: int = 1

# =============================================================================
# Element管理
# =============================================================================

## Elementを追加
func add_element(element: ElementData.ElementInstance) -> void:
	if element.id.is_empty():
		element.id = "element_%d" % _next_element_id
		_next_element_id += 1

	elements.append(element)
	_element_map[element.id] = element

	if element.faction in elements_by_faction:
		elements_by_faction[element.faction].append(element)

	element_added.emit(element)


## Elementを削除
func remove_element(element: ElementData.ElementInstance) -> void:
	elements.erase(element)
	_element_map.erase(element.id)

	if element.faction in elements_by_faction:
		elements_by_faction[element.faction].erase(element)

	element_removed.emit(element)


## IDでElementを取得
func get_element_by_id(id: String) -> ElementData.ElementInstance:
	return _element_map.get(id)


## 陣営のElementを取得
func get_elements_for_faction(faction: GameEnums.Faction) -> Array[ElementData.ElementInstance]:
	if faction in elements_by_faction:
		return elements_by_faction[faction]
	var empty: Array[ElementData.ElementInstance] = []
	return empty


## 位置の近くのElementを取得
func get_elements_near(position: Vector2, radius: float) -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []
	var radius_sq := radius * radius

	for element in elements:
		if element.position.distance_squared_to(position) <= radius_sq:
			result.append(element)

	return result


## 矩形内のElementを取得
func get_elements_in_rect(rect: Rect2) -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []

	for element in elements:
		if rect.has_point(element.position):
			result.append(element)

	return result

# =============================================================================
# Tick処理
# =============================================================================

## 全Elementの状態を保存 (補間用)
func save_prev_states() -> void:
	for element in elements:
		element.save_prev_state()

# =============================================================================
# ファクトリ
# =============================================================================

## テスト用Elementを生成
func create_test_element(
	element_type: ElementData.ElementType,
	faction: GameEnums.Faction,
	position: Vector2
) -> ElementData.ElementInstance:
	var instance := ElementData.ElementInstance.new(element_type)
	instance.faction = faction
	instance.position = position
	instance.prev_position = position
	instance.contact_state = GameEnums.ContactState.CONFIRMED

	add_element(instance)
	return instance

# =============================================================================
# デバッグ
# =============================================================================

func debug_print_elements() -> void:
	print("=== WorldModel Elements ===")
	print("Total: ", elements.size())
	for faction in elements_by_faction:
		print("  ", GameEnums.Faction.keys()[faction], ": ", elements_by_faction[faction].size())
