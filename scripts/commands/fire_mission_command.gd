class_name FireMissionCommand
extends "res://scripts/commands/command.gd"

## FireMissionCommand - 間接射撃命令
## フェーズ5: コマンドパターン導入
##
## 責務:
## - 砲兵ユニットに間接射撃任務を設定
## - 展開状態の管理
## - 前の状態を保存してUndo可能に

# =============================================================================
# 状態
# =============================================================================

var _target_position: Vector2
var _previous_states: Dictionary = {}  # element_id -> {order_type, fire_mission_target, fire_mission_active, deploy_state, deploy_progress, forced_target_id}
var _movement_system: MovementSystem = null

# =============================================================================
# 初期化
# =============================================================================

func _init(element_ids: Array[String], target_position: Vector2, movement_system: MovementSystem = null) -> void:
	_element_ids = element_ids
	_target_position = target_position
	_movement_system = movement_system


# =============================================================================
# コマンド実装
# =============================================================================

## 間接射撃命令を実行
func execute(world_model: WorldModel) -> bool:
	var success := false

	for element_id in _element_ids:
		var element := world_model.get_element_by_id(element_id)
		if not element:
			continue

		# 砲兵かどうかチェック
		var archetype: String = element.element_type.id if element.element_type else ""
		if archetype != "SP_ARTILLERY" and archetype != "SP_MORTAR":
			continue

		# 間接射撃武器を持っているかチェック
		var has_indirect_weapon := false
		for weapon in element.weapons:
			if weapon.fire_model == WeaponData.FireModel.INDIRECT:
				has_indirect_weapon = true
				break

		if not has_indirect_weapon:
			continue

		# 前の状態を保存（Undo用）
		_previous_states[element_id] = {
			"order_type": element.current_order_type,
			"fire_mission_target": element.fire_mission_target,
			"fire_mission_active": element.fire_mission_active,
			"deploy_state": element.artillery_deploy_state,
			"deploy_progress": element.artillery_deploy_progress,
			"forced_target_id": element.forced_target_id,
			"is_moving": element.is_moving,
			"current_path": element.current_path.duplicate() if element.current_path else PackedVector2Array()
		}

		# 移動を停止
		if _movement_system:
			_movement_system.issue_stop_order(element)
		element.is_moving = false
		element.current_path = PackedVector2Array()

		# 間接射撃任務を設定
		element.current_order_type = GameEnums.OrderType.FIRE_MISSION
		element.fire_mission_target = _target_position
		element.forced_target_id = ""

		# 展開状態に応じて処理
		var ADS := ElementData.ElementInstance.ArtilleryDeployState
		match element.artillery_deploy_state:
			ADS.DEPLOYED:
				element.fire_mission_active = true
			ADS.DEPLOYING:
				element.fire_mission_active = false
			ADS.STOWED, ADS.PACKING:
				element.artillery_deploy_state = ADS.DEPLOYING
				element.artillery_deploy_progress = 0.0
				element.fire_mission_active = false

		success = true

	_executed = success
	return success


## 間接射撃命令を取り消し
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
		element.fire_mission_target = prev.fire_mission_target
		element.fire_mission_active = prev.fire_mission_active
		element.artillery_deploy_state = prev.deploy_state
		element.artillery_deploy_progress = prev.deploy_progress
		element.forced_target_id = prev.forced_target_id
		element.is_moving = prev.is_moving
		element.current_path = prev.current_path

	return true


## 命令の説明を取得
func get_description() -> String:
	return "Fire Mission at (%d, %d)" % [int(_target_position.x), int(_target_position.y)]


## シリアライズ
func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["target_position"] = {"x": _target_position.x, "y": _target_position.y}
	return base


## デシリアライズ
static func from_dict(data: Dictionary):
	var element_ids: Array[String] = []
	for id in data.get("element_ids", []):
		element_ids.append(id)

	var pos_data = data.get("target_position", {})
	var target_position := Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

	var script = load("res://scripts/commands/fire_mission_command.gd")
	var cmd = script.new(element_ids, target_position)
	cmd._timestamp = data.get("timestamp", 0)
	return cmd
