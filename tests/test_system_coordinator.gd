extends GutTest

## SystemCoordinatorテスト
## フェーズ3: システム依存の整理

var SystemCoordinatorClass: GDScript
var WorldModelClass: GDScript
var MapDataClass: GDScript
var GameEventsClass: GDScript


func before_all() -> void:
	SystemCoordinatorClass = load("res://scripts/core/system_coordinator.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	MapDataClass = load("res://scripts/data/map_data.gd")
	GameEventsClass = load("res://scripts/events/game_events.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_system_coordinator_exists() -> void:
	assert_not_null(SystemCoordinatorClass, "SystemCoordinator should exist")


func test_system_coordinator_can_be_instantiated() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator, "SystemCoordinator should be instantiable")


# =============================================================================
# 初期化テスト
# =============================================================================

func test_coordinator_has_game_events() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.game_events, "Should have game_events")


func test_coordinator_has_missile_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.missile_system, "Should have missile_system")


func test_coordinator_has_movement_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.movement_system, "Should have movement_system")


func test_coordinator_has_combat_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.combat_system, "Should have combat_system")


func test_coordinator_has_resupply_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.resupply_system, "Should have resupply_system")


# =============================================================================
# 依存注入テスト
# =============================================================================

func test_movement_system_has_constraint_checker() -> void:
	var coordinator = SystemCoordinatorClass.new()
	var constraint_checker = coordinator.movement_system.get_constraint_checker()
	assert_not_null(constraint_checker, "MovementSystem should have constraint_checker")


func test_movement_system_constraint_checker_is_missile_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	var constraint_checker = coordinator.movement_system.get_constraint_checker()
	assert_eq(constraint_checker, coordinator.missile_system, "Constraint checker should be MissileSystem")


func test_combat_system_has_game_events() -> void:
	var coordinator = SystemCoordinatorClass.new()
	var events = coordinator.combat_system.get_game_events()
	assert_not_null(events, "CombatSystem should have game_events")
	assert_eq(events, coordinator.game_events, "CombatSystem should use shared game_events")


# =============================================================================
# tick更新テスト
# =============================================================================

func test_coordinator_set_tick() -> void:
	var coordinator = SystemCoordinatorClass.new()
	coordinator.set_tick(100)
	assert_eq(coordinator.game_events.get_tick(), 100, "GameEvents tick should be updated")


func test_coordinator_get_tick() -> void:
	var coordinator = SystemCoordinatorClass.new()
	coordinator.set_tick(200)
	assert_eq(coordinator.get_tick(), 200, "get_tick should return current tick")


# =============================================================================
# システムアクセステスト
# =============================================================================

func test_coordinator_get_game_events() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.get_game_events(), "get_game_events should return game_events")


func test_coordinator_get_missile_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.get_missile_system(), "get_missile_system should return missile_system")


func test_coordinator_get_combat_system() -> void:
	var coordinator = SystemCoordinatorClass.new()
	assert_not_null(coordinator.get_combat_system(), "get_combat_system should return combat_system")
