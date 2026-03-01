class_name DefendCommand
extends "res://scripts/commands/command.gd"

## DefendCommand - 防御命令
## フェーズ5: コマンドパターン導入
##
## 責務:
## - 指定位置での防御態勢を設定
## - ユニットを停止
## - 前の状態を保存してUndo可能に

# =============================================================================
# 状態
# =============================================================================

var _position: Vector2
var _previous_states: Dictionary = {}  # element_id -> {order_type, order_target, is_moving}
var _movement_system: MovementSystem = null  # オプショナル: 移動システム参照

# =============================================================================
# 初期化
# =============================================================================

func _init(element_ids: Array[String], position: Vector2 = Vector2.ZERO, movement_system: MovementSystem = null) -> void:
	_element_ids = element_ids
	_position = position
	_movement_system = movement_system


# =============================================================================
# コマンド実装
# =============================================================================

## 防御命令を実行
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
			"is_moving": element.is_moving,
			"path": element.current_path.duplicate() if element.current_path else PackedVector2Array()
		}

		# 防御命令を設定
		element.current_order_type = GameEnums.OrderType.DEFEND
		# 位置が指定されていない場合は現在位置を使用
		element.order_target_position = _position if _position != Vector2.ZERO else element.position
		element.is_moving = false
		element.current_path = PackedVector2Array()
		element.forced_target_id = ""  # 強制目標をクリア

		# MovementSystemがあれば停止を発行
		if _movement_system:
			_movement_system.issue_stop_order(element)

		success = true

	_executed = success
	return success


## 防御命令を取り消し
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
		element.is_moving = prev.is_moving
		element.current_path = prev.path

	return true


## 命令の説明を取得
func get_description() -> String:
	if _position != Vector2.ZERO:
		return "Defend at (%d, %d)" % [int(_position.x), int(_position.y)]
	return "Defend"


## シリアライズ
func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["position"] = {"x": _position.x, "y": _position.y}
	return base


## デシリアライズ
static func from_dict(data: Dictionary):
	var element_ids: Array[String] = []
	for id in data.get("element_ids", []):
		element_ids.append(id)

	var pos_data = data.get("position", {})
	var position := Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

	var script = load("res://scripts/commands/defend_command.gd")
	var cmd = script.new(element_ids, position)
	cmd._timestamp = data.get("timestamp", 0)
	return cmd
