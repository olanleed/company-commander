class_name MoveCommand
extends "res://scripts/commands/command.gd"

## MoveCommand - 移動命令
## フェーズ5: コマンドパターン導入
##
## 責務:
## - 指定位置への移動命令を実行
## - 前の状態を保存してUndo可能に
## - 複数ユニットへの一括命令をサポート

# =============================================================================
# 状態
# =============================================================================

var _destination: Vector2
var _use_road: bool
var _previous_states: Dictionary = {}  # element_id -> {order_type, order_target, position}
var _movement_system: MovementSystem = null  # オプショナル: 移動システム参照

# =============================================================================
# 初期化
# =============================================================================

func _init(element_ids: Array[String], destination: Vector2, use_road: bool = false, movement_system: MovementSystem = null) -> void:
	_element_ids = element_ids
	_destination = destination
	_use_road = use_road
	_movement_system = movement_system


# =============================================================================
# コマンド実装
# =============================================================================

## 移動命令を実行
func execute(world_model: WorldModel) -> bool:
	var success := false

	for element_id in _element_ids:
		var element := world_model.get_element_by_id(element_id)
		if not element:
			continue

		# 前の状態を保存（Undo用）
		_previous_states[element_id] = {
			"order_type": element.current_order_type,
			"order_target": element.order_target_position,
			"position": element.position
		}

		# 移動命令を設定
		element.current_order_type = GameEnums.OrderType.MOVE
		element.order_target_position = _destination
		element.use_road_only = _use_road
		element.forced_target_id = ""  # 強制目標をクリア

		# MovementSystemがあれば移動を開始
		if _movement_system:
			_movement_system.issue_move_order(element, _destination, _use_road)

		success = true

	_executed = success
	return success


## 移動命令を取り消し
func undo(world_model: WorldModel) -> bool:
	if not _executed:
		return false

	for element_id in _element_ids:
		var element := world_model.get_element_by_id(element_id)
		if not element:
			continue

		var prev = _previous_states.get(element_id, {})
		if prev.is_empty():
			continue

		# 前の状態を復元
		element.current_order_type = prev.order_type
		element.order_target_position = prev.order_target
		# 移動中なら停止
		element.is_moving = false
		element.current_path = PackedVector2Array()

	return true


## 命令の説明を取得
func get_description() -> String:
	var road_str := " (road)" if _use_road else ""
	return "Move to (%d, %d)%s" % [int(_destination.x), int(_destination.y), road_str]


## シリアライズ
func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["destination"] = {"x": _destination.x, "y": _destination.y}
	base["use_road"] = _use_road
	return base


## デシリアライズ
static func from_dict(data: Dictionary):
	var element_ids: Array[String] = []
	for id in data.get("element_ids", []):
		element_ids.append(id)

	var dest_data = data.get("destination", {})
	var destination := Vector2(dest_data.get("x", 0), dest_data.get("y", 0))
	var use_road: bool = data.get("use_road", false)

	var script = load("res://scripts/commands/move_command.gd")
	var cmd = script.new(element_ids, destination, use_road)
	cmd._timestamp = data.get("timestamp", 0)
	return cmd
