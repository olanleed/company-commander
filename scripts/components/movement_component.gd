class_name MovementComponent
extends RefCounted

## MovementComponent - 移動パス・状態・命令の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 移動パスの管理
## - 移動状態（is_moving, is_reversing等）の管理
## - 命令（OrderType）の管理
## - 待機移動命令の管理

# =============================================================================
# シグナル
# =============================================================================

signal movement_started(element_id: String, destination: Vector2)
signal movement_completed(element_id: String)
signal path_changed(element_id: String, new_path: PackedVector2Array)
signal order_changed(element_id: String, order_type: GameEnums.OrderType)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## パス状態
var _current_path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _is_moving: bool = false
var _use_road_only: bool = false
var _is_reversing: bool = false
var _break_contact_smoke_requested: bool = false

## 命令
var _current_order_type: GameEnums.OrderType = GameEnums.OrderType.HOLD
var _order_target_position: Vector2 = Vector2.ZERO
var _order_target_id: String = ""
var _pending_move_order: Dictionary = {}

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var is_moving: bool:
	get: return _is_moving

var current_path: PackedVector2Array:
	get: return _current_path

var path_index: int:
	get: return _path_index

var current_order_type: GameEnums.OrderType:
	get: return _current_order_type

var order_target_position: Vector2:
	get: return _order_target_position

var order_target_id: String:
	get: return _order_target_id

var use_road_only: bool:
	get: return _use_road_only

var is_reversing: bool:
	get: return _is_reversing

var break_contact_smoke_requested: bool:
	get: return _break_contact_smoke_requested

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String) -> void:
	_element_id = element_id
	_current_path = PackedVector2Array()


# =============================================================================
# 移動開始・停止
# =============================================================================

## 移動開始
## @param path: 移動パス（ウェイポイント配列）
## @param use_road: 道路のみを使用するか
func start_movement(path: PackedVector2Array, use_road: bool = false) -> void:
	_current_path = path
	_path_index = 0
	_is_moving = true
	_use_road_only = use_road

	path_changed.emit(_element_id, path)
	if path.size() > 0:
		movement_started.emit(_element_id, path[path.size() - 1])


## 移動停止
func stop_movement() -> void:
	if _is_moving:
		_is_moving = false
		_current_path = PackedVector2Array()
		_path_index = 0
		_is_reversing = false
		movement_completed.emit(_element_id)


# =============================================================================
# ウェイポイント管理
# =============================================================================

## 次のウェイポイントを取得
## @return: 次のウェイポイント位置（パスが空ならZERO）
func get_next_waypoint() -> Vector2:
	if _path_index < _current_path.size():
		return _current_path[_path_index]
	return Vector2.ZERO


## ウェイポイントを進める
## @return: まだウェイポイントが残っているか
func advance_waypoint() -> bool:
	_path_index += 1
	return _path_index < _current_path.size()


## 残りのウェイポイント数を取得
func get_remaining_waypoints() -> int:
	return maxi(0, _current_path.size() - _path_index)


# =============================================================================
# 命令管理
# =============================================================================

## 命令を設定
## @param order_type: 命令タイプ
## @param target_pos: 目標位置（オプション）
## @param target_id: 目標ID（オプション、ATTACKコマンド等）
func set_order(order_type: GameEnums.OrderType, target_pos: Vector2 = Vector2.ZERO, target_id: String = "") -> void:
	_current_order_type = order_type
	_order_target_position = target_pos
	_order_target_id = target_id
	order_changed.emit(_element_id, order_type)


# =============================================================================
# 後退・離脱フラグ
# =============================================================================

## 後退フラグを設定
func set_reversing(value: bool) -> void:
	_is_reversing = value


## 離脱時の煙幕を要請
func request_break_contact_smoke() -> void:
	_break_contact_smoke_requested = true


## 煙幕要請をクリア
func clear_break_contact_smoke() -> void:
	_break_contact_smoke_requested = false


# =============================================================================
# 待機移動命令
# =============================================================================

## 待機移動命令を設定
## @param order: 命令データ {target: Vector2, use_route: bool, ...}
func set_pending_move_order(order: Dictionary) -> void:
	_pending_move_order = order


## 待機移動命令があるか
func has_pending_order() -> bool:
	return not _pending_move_order.is_empty()


## 待機移動命令を取得してクリア
## @return: 待機命令データ（なければ空辞書）
func get_and_clear_pending_order() -> Dictionary:
	var order = _pending_move_order
	_pending_move_order = {}
	return order


# =============================================================================
# パス直接設定（後方互換用）
# =============================================================================

## パスを直接設定（システムからの更新用）
func set_path(path: PackedVector2Array) -> void:
	_current_path = path
	path_changed.emit(_element_id, path)


## パスインデックスを設定
func set_path_index(index: int) -> void:
	_path_index = index


## 移動状態を直接設定（後方互換用）
func set_is_moving(value: bool) -> void:
	_is_moving = value


## 道路専用フラグを設定
func set_use_road_only(value: bool) -> void:
	_use_road_only = value


## order_target_idを直接設定（後方互換用）
func set_order_target_id(value: String) -> void:
	_order_target_id = value


## order_target_positionを直接設定（後方互換用）
func set_order_target_position(value: Vector2) -> void:
	_order_target_position = value
