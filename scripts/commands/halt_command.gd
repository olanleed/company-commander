class_name HaltCommand
extends "res://scripts/commands/command.gd"

## HaltCommand - 停止命令
## フェーズ5: コマンドパターン導入
##
## 責務:
## - ユニットを即時停止
## - 移動パスをクリア
## - 前の状態を保存してUndo可能に

# =============================================================================
# 状態
# =============================================================================

var _previous_states: Dictionary = {}  # element_id -> {order_type, order_target, path, is_moving}
var _movement_system: MovementSystem = null  # オプショナル: 移動システム参照

# =============================================================================
# 初期化
# =============================================================================

func _init(element_ids: Array[String], movement_system: MovementSystem = null) -> void:
	_element_ids = element_ids
	_movement_system = movement_system


# =============================================================================
# コマンド実装
# =============================================================================

## 停止命令を実行
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
			"path": element.current_path.duplicate() if element.current_path else PackedVector2Array(),
			"is_moving": element.is_moving
		}

		# 停止命令を設定
		element.current_order_type = GameEnums.OrderType.HOLD
		element.is_moving = false
		element.current_path = PackedVector2Array()

		# MovementSystemがあれば停止を発行
		if _movement_system:
			_movement_system.issue_stop_order(element)

		success = true

	_executed = success
	return success


## 停止命令を取り消し
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
		element.current_path = prev.path
		element.is_moving = prev.is_moving

	return true


## 命令の説明を取得
func get_description() -> String:
	return "Halt"


## デシリアライズ
static func from_dict(data: Dictionary):
	var element_ids: Array[String] = []
	for id in data.get("element_ids", []):
		element_ids.append(id)

	var script = load("res://scripts/commands/halt_command.gd")
	var cmd = script.new(element_ids)
	cmd._timestamp = data.get("timestamp", 0)
	return cmd
