class_name AttackCommand
extends "res://scripts/commands/command.gd"

## AttackCommand - 攻撃命令
## フェーズ5: コマンドパターン導入
##
## 責務:
## - 指定目標への攻撃命令を実行
## - 前の状態を保存してUndo可能に
## - 複数ユニットへの一括命令をサポート

# =============================================================================
# 状態
# =============================================================================

var _target_id: String
var _previous_states: Dictionary = {}  # element_id -> {forced_target_id, order_type, order_target}

# =============================================================================
# 初期化
# =============================================================================

func _init(element_ids: Array[String], target_id: String) -> void:
	_element_ids = element_ids
	_target_id = target_id


# =============================================================================
# コマンド実装
# =============================================================================

## 攻撃命令を実行
func execute(world_model: WorldModel) -> bool:
	var target := world_model.get_element_by_id(_target_id)
	if not target:
		return false

	var success := false

	for element_id in _element_ids:
		var element := world_model.get_element_by_id(element_id)
		if not element:
			continue

		# 前の状態を保存（Undo用）
		_previous_states[element_id] = {
			"forced_target_id": element.forced_target_id,
			"order_type": element.current_order_type,
			"order_target": element.order_target_position,
			"order_target_id": element.order_target_id
		}

		# 攻撃命令を設定
		element.forced_target_id = _target_id
		element.order_target_id = _target_id
		element.current_order_type = GameEnums.OrderType.ATTACK
		element.order_target_position = target.position

		success = true

	_executed = success
	return success


## 攻撃命令を取り消し
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
		element.forced_target_id = prev.forced_target_id
		element.order_target_id = prev.get("order_target_id", "")
		element.current_order_type = prev.order_type
		element.order_target_position = prev.order_target

	return true


## 命令の説明を取得
func get_description() -> String:
	return "Attack target %s" % _target_id


## シリアライズ
func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["target_id"] = _target_id
	return base


## デシリアライズ
static func from_dict(data: Dictionary):
	var element_ids: Array[String] = []
	for id in data.get("element_ids", []):
		element_ids.append(id)

	var target_id: String = data.get("target_id", "")

	var script = load("res://scripts/commands/attack_command.gd")
	var cmd = script.new(element_ids, target_id)
	cmd._timestamp = data.get("timestamp", 0)
	return cmd
