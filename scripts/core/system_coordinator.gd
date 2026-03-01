class_name SystemCoordinator
extends RefCounted

## SystemCoordinator - システム依存の整理
## フェーズ3: システム依存の整理
##
## 責務:
## - システム間の依存を管理
## - 正しい順序でシステムを更新
## - 共有リソース（GameEvents）を提供
##
## 依存関係:
## - MissileSystem: 射手拘束情報を提供（IConstraintChecker）
## - MovementSystem: MissileSystemに依存（制約チェック）
## - CombatSystem: GameEventsを使用（イベント発火）

# =============================================================================
# プリロード
# =============================================================================

const _MissileSystem: GDScript = preload("res://scripts/systems/missile_system.gd")
const _MovementSystem: GDScript = preload("res://scripts/systems/movement_system.gd")
const _CombatSystem: GDScript = preload("res://scripts/systems/combat_system.gd")
const _ResupplySystem: GDScript = preload("res://scripts/systems/resupply_system.gd")
const _GameEvents: GDScript = preload("res://scripts/events/game_events.gd")

# =============================================================================
# システム参照
# =============================================================================

var game_events
var missile_system
var movement_system
var combat_system
var resupply_system

# =============================================================================
# 内部状態
# =============================================================================

var _current_tick: int = 0

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	# GameEventsを作成（共有）
	game_events = _GameEvents.new()

	# システムを初期化
	missile_system = _MissileSystem.new()

	movement_system = _MovementSystem.new()
	movement_system.set_constraint_checker(missile_system)

	combat_system = _CombatSystem.new()
	combat_system.set_game_events(game_events)

	resupply_system = _ResupplySystem.new()


# =============================================================================
# セットアップ（外部依存の注入）
# =============================================================================

## MovementSystemに追加の依存を注入
func setup_movement_system(nav_manager, map_data, world_model = null) -> void:
	movement_system.setup(nav_manager, map_data, world_model, missile_system)


# =============================================================================
# tick管理
# =============================================================================

func set_tick(tick: int) -> void:
	_current_tick = tick
	game_events.set_tick(tick)


func get_tick() -> int:
	return _current_tick


# =============================================================================
# システムアクセス
# =============================================================================

func get_game_events():
	return game_events


func get_missile_system():
	return missile_system


func get_movement_system():
	return movement_system


func get_combat_system():
	return combat_system


func get_resupply_system():
	return resupply_system
