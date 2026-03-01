extends RefCounted
class_name CommanderAI

## 簡易コマンダーAI
## 各陣営のユニットに基本的な行動命令を出す軽量AI
##
## 機能:
## - 敵発見時: 攻撃命令
## - 敵未発見時: 前進または待機
## - 被害時: 後退判断（オプション）

# =============================================================================
# 設定
# =============================================================================

var faction: GameEnums.Faction = GameEnums.Faction.RED
var world_model: WorldModel
var vision_system: VisionSystem
var movement_system: MovementSystem

## AI行動モード
enum AIMode {
	PASSIVE,     # 待機（敵が来たら交戦）
	AGGRESSIVE,  # 積極攻撃（敵に向かって前進）
	DEFENSIVE,   # 防御（位置を維持、反撃のみ）
}

var ai_mode: AIMode = AIMode.AGGRESSIVE

## 更新間隔（tick）
const UPDATE_INTERVAL: int = 50  # 5秒ごと

## 前進目標（AGGRESSIVE時）
var advance_target: Vector2 = Vector2.ZERO

## 後退閾値（残存戦力比）
var retreat_threshold: float = 0.3

# =============================================================================
# セットアップ
# =============================================================================

func setup(p_world_model: WorldModel, p_vision_system: VisionSystem, p_movement_system: MovementSystem) -> void:
	world_model = p_world_model
	vision_system = p_vision_system
	movement_system = p_movement_system


func set_advance_target(target: Vector2) -> void:
	advance_target = target


func set_mode(mode: AIMode) -> void:
	ai_mode = mode

# =============================================================================
# 更新
# =============================================================================

func update(tick: int) -> void:
	if not world_model or not vision_system:
		return

	# 一定間隔で更新
	if tick % UPDATE_INTERVAL != 0:
		return

	var my_elements := world_model.get_elements_for_faction(faction)
	if my_elements.size() == 0:
		return

	# 戦闘ユニットのみ抽出（HQは除く）
	var combat_units: Array[ElementData.ElementInstance] = []
	for element in my_elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue
		if element.element_type and element.element_type.is_comm_hub:
			continue  # HQは命令対象外
		combat_units.append(element)

	if combat_units.size() == 0:
		return

	# モードに応じた行動
	match ai_mode:
		AIMode.PASSIVE:
			_update_passive(combat_units, tick)
		AIMode.AGGRESSIVE:
			_update_aggressive(combat_units, tick)
		AIMode.DEFENSIVE:
			_update_defensive(combat_units, tick)


## PASSIVEモード: 敵が視界内に入ったら交戦、それ以外は待機
func _update_passive(units: Array[ElementData.ElementInstance], _tick: int) -> void:
	for unit in units:
		# 射撃可能な敵がいれば何もしない（自動交戦に任せる）
		var fireable := vision_system.get_fireable_targets(unit)
		if fireable.size() > 0:
			continue

		# 移動中でなければ待機状態を維持
		if unit.is_moving:
			# 目的地が設定されているなら継続
			pass


## AGGRESSIVEモード: 敵に向かって前進、視界内の敵と交戦
func _update_aggressive(units: Array[ElementData.ElementInstance], _tick: int) -> void:
	# 敵陣営を特定
	var enemy_faction := GameEnums.Faction.BLUE if faction == GameEnums.Faction.RED else GameEnums.Faction.RED
	var enemy_elements := world_model.get_elements_for_faction(enemy_faction)

	# 生存中の敵を抽出
	var alive_enemies: Array[ElementData.ElementInstance] = []
	for enemy in enemy_elements:
		if enemy.state != GameEnums.UnitState.DESTROYED:
			alive_enemies.append(enemy)

	if alive_enemies.size() == 0:
		return

	# 敵の重心を計算
	var enemy_center := Vector2.ZERO
	for enemy in alive_enemies:
		enemy_center += enemy.position
	enemy_center /= alive_enemies.size()

	for unit in units:
		# 射撃可能な敵がいれば停止して交戦
		var fireable := vision_system.get_fireable_targets(unit)
		if fireable.size() > 0:
			# 交戦中は移動停止
			if unit.is_moving:
				unit.current_path = PackedVector2Array()
				unit.is_moving = false
				unit.velocity = Vector2.ZERO
			continue

		# 敵が視界外なら前進
		if not unit.is_moving:
			# 敵の重心に向かって移動
			var target_pos := enemy_center
			if advance_target != Vector2.ZERO:
				target_pos = advance_target

			movement_system.issue_move_order(unit, target_pos, false)
			print("[CommanderAI] %s -> ADVANCE to (%.0f, %.0f)" % [unit.id, target_pos.x, target_pos.y])


## DEFENSIVEモード: 現在位置を維持、敵が来たら交戦
func _update_defensive(units: Array[ElementData.ElementInstance], _tick: int) -> void:
	for unit in units:
		# 射撃可能な敵がいれば何もしない（自動交戦に任せる）
		var fireable := vision_system.get_fireable_targets(unit)
		if fireable.size() > 0:
			# 交戦中は移動停止
			if unit.is_moving:
				unit.current_path = PackedVector2Array()
				unit.is_moving = false
				unit.velocity = Vector2.ZERO
			continue

		# 移動中なら停止（防御位置を維持）
		if unit.is_moving:
			unit.current_path = PackedVector2Array()
			unit.is_moving = false
			unit.velocity = Vector2.ZERO

# =============================================================================
# ユーティリティ
# =============================================================================

## 残存戦力比を計算
func get_force_ratio() -> float:
	var my_strength := 0
	var enemy_strength := 0

	var enemy_faction := GameEnums.Faction.BLUE if faction == GameEnums.Faction.RED else GameEnums.Faction.RED

	for element in world_model.elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue
		if element.faction == faction:
			my_strength += element.current_strength
		elif element.faction == enemy_faction:
			enemy_strength += element.current_strength

	if enemy_strength == 0:
		return 999.0  # 敵なし

	return float(my_strength) / float(enemy_strength)


## デバッグ情報を取得
func get_debug_info() -> String:
	var mode_str := _get_mode_string()

	var force_ratio := get_force_ratio()
	return "[%s] Mode=%s, ForceRatio=%.2f" % [
		"BLUE" if faction == GameEnums.Faction.BLUE else "RED",
		mode_str,
		force_ratio
	]


## モード文字列を取得
func _get_mode_string() -> String:
	match ai_mode:
		AIMode.AGGRESSIVE:
			return "AGGRESSIVE"
		AIMode.DEFENSIVE:
			return "DEFENSIVE"
		_:
			return "PASSIVE"


## AI思考情報を取得（RightPanel互換）
func get_ai_thought_info() -> Dictionary:
	var mode_str := _get_mode_string()
	var force_ratio := get_force_ratio()

	# 戦闘状態を判定
	var combat_state := "QUIET"
	var my_elements := world_model.get_elements_for_faction(faction) if world_model else []
	for element in my_elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue
		if vision_system and vision_system.get_fireable_targets(element).size() > 0:
			combat_state = "ENGAGED"
			break

	return {
		"template": "CommanderAI",
		"phase_name": mode_str,
		"combat_state": combat_state,
		"force_ratio": force_ratio,
	}


## ユニット別のAI情報を取得（RightPanel互換）
func get_element_ai_info(element_id: String) -> Dictionary:
	if not world_model:
		return {}

	var element := world_model.get_element_by_id(element_id)
	if not element:
		return {}

	# ユニットの現在状態を判定
	var state := "IDLE"
	if element.is_moving:
		state = "MOVING"
	elif vision_system and vision_system.get_fireable_targets(element).size() > 0:
		state = "ENGAGING"

	# 現在の武器
	var weapon_name := "NONE"
	if element.current_weapon:
		weapon_name = element.current_weapon.display_name

	return {
		"role": _get_mode_string(),
		"state": state,
		"weapon": weapon_name,
		"target": element.current_target_id if element.current_target_id != "" else "NONE",
	}
