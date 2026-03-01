class_name SelectionManager
extends RefCounted

## SelectionManager - 選択状態の一元管理
## フェーズ4: UIリアクティブ化
##
## 責務:
## - ユニット選択状態の管理
## - 選択変更をシグナルで通知
## - WorldModelと連携して破壊ユニットを自動除外
##
## シグナル:
## - selection_changed: 選択が変更された
## - selection_cleared: 選択がクリアされた
## - primary_selection_changed: プライマリ選択が変更された

# =============================================================================
# シグナル
# =============================================================================

## 選択が変更された（要素リストを渡す）
signal selection_changed(elements: Array)

## 選択がクリアされた
signal selection_cleared()

## プライマリ選択が変更された
signal primary_selection_changed(element: ElementData.ElementInstance)

# =============================================================================
# 内部状態
# =============================================================================

var _selected_elements: Array[ElementData.ElementInstance] = []
var _primary_selection: ElementData.ElementInstance = null
var _world_model: WorldModel = null

# =============================================================================
# セットアップ
# =============================================================================

## WorldModelを設定（ユニット削除時の自動除外用）
func set_world_model(world_model: WorldModel) -> void:
	# 前のWorldModelの接続を解除
	if _world_model:
		if _world_model.is_connected("element_removed", _on_element_removed):
			_world_model.disconnect("element_removed", _on_element_removed)

	_world_model = world_model

	# 新しいWorldModelに接続
	if _world_model and _world_model.has_signal("element_removed"):
		_world_model.element_removed.connect(_on_element_removed)

# =============================================================================
# 選択操作
# =============================================================================

## 複数ユニットを選択
func select(elements: Array[ElementData.ElementInstance]) -> void:
	# 破壊されたユニットを除外
	_selected_elements.clear()
	for element in elements:
		if element and not element.is_destroyed:
			_selected_elements.append(element)

	if _selected_elements.size() > 0:
		_primary_selection = _selected_elements[0]
	else:
		_primary_selection = null

	selection_changed.emit(_selected_elements)


## 単一ユニットを選択
func select_single(element: ElementData.ElementInstance) -> void:
	# 破壊されたユニットは選択しない
	if element and element.is_destroyed:
		_selected_elements.clear()
		_primary_selection = null
		selection_changed.emit(_selected_elements)
		return

	_selected_elements.clear()
	if element:
		_selected_elements.append(element)
	_primary_selection = element
	selection_changed.emit(_selected_elements)
	if element:
		primary_selection_changed.emit(element)


## 選択に追加
func add_to_selection(element: ElementData.ElementInstance) -> void:
	if not element:
		return
	if element.is_destroyed:
		return
	if element in _selected_elements:
		return

	_selected_elements.append(element)
	selection_changed.emit(_selected_elements)


## 選択から除外
func remove_from_selection(element: ElementData.ElementInstance) -> void:
	var idx := _selected_elements.find(element)
	if idx < 0:
		return

	_selected_elements.remove_at(idx)

	# プライマリが削除された場合は次の要素に切り替え
	if _primary_selection == element:
		if _selected_elements.size() > 0:
			_primary_selection = _selected_elements[0]
		else:
			_primary_selection = null

	selection_changed.emit(_selected_elements)


## 選択をクリア
func clear_selection() -> void:
	_selected_elements.clear()
	_primary_selection = null
	selection_changed.emit(_selected_elements)  # 空の配列で通知
	selection_cleared.emit()

# =============================================================================
# 取得
# =============================================================================

## 選択中のユニットを取得
func get_selected() -> Array[ElementData.ElementInstance]:
	return _selected_elements


## プライマリ選択を取得
func get_primary() -> ElementData.ElementInstance:
	return _primary_selection


## ユニットが選択されているか
func is_selected(element: ElementData.ElementInstance) -> bool:
	return element in _selected_elements


## 選択数を取得
func get_count() -> int:
	return _selected_elements.size()


## 選択があるか
func has_selection() -> bool:
	return _selected_elements.size() > 0

# =============================================================================
# WorldModelイベントハンドラ
# =============================================================================

## ユニットが削除されたときに選択から除外
func _on_element_removed(element: ElementData.ElementInstance) -> void:
	var element_id: String = element.id if element else ""
	if element_id == "":
		return

	var original_size := _selected_elements.size()
	var filtered: Array[ElementData.ElementInstance] = []
	for e in _selected_elements:
		if e.id != element_id:
			filtered.append(e)

	if filtered.size() != original_size:
		_selected_elements = filtered
		if _primary_selection and _primary_selection.id == element_id:
			_primary_selection = filtered[0] if filtered.size() > 0 else null
		selection_changed.emit(_selected_elements)
