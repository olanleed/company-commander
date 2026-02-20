extends GutTest

## CombatSystemのユニットテスト

const CombatSystem := preload("res://scripts/systems/combat_system.gd")
const WeaponData := preload("res://scripts/data/weapon_data.gd")
const ElementData := preload("res://scripts/data/element_data.gd")

var combat_system: CombatSystem


func before_each() -> void:
	combat_system = CombatSystem.new()


# =============================================================================
# 射手状態係数テスト
# =============================================================================

func test_shooter_coefficient_normal() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	shooter.suppression = 0.0
	var m_shooter: float = combat_system.calculate_shooter_coefficient(shooter)
	assert_almost_eq(m_shooter, 1.0, 0.01)


func test_shooter_coefficient_suppressed() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	shooter.suppression = 0.50  # Suppressed状態
	var m_shooter: float = combat_system.calculate_shooter_coefficient(shooter)
	# M_SHOOTER_SUPPRESSED = 0.70
	assert_almost_eq(m_shooter, 0.70, 0.01)


func test_shooter_coefficient_pinned() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	shooter.suppression = 0.75  # Pinned状態
	var m_shooter: float = combat_system.calculate_shooter_coefficient(shooter)
	# M_SHOOTER_PINNED = 0.35
	assert_almost_eq(m_shooter, 0.35, 0.01)


func test_shooter_coefficient_broken() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	shooter.suppression = 0.95  # Broken状態
	var m_shooter: float = combat_system.calculate_shooter_coefficient(shooter)
	# M_SHOOTER_BROKEN = 0.15
	assert_almost_eq(m_shooter, 0.15, 0.01)


# =============================================================================
# 遮蔽係数テスト
# =============================================================================

func test_cover_coefficient_open() -> void:
	var m_cover: float = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.OPEN)
	assert_almost_eq(m_cover, 1.0, 0.01)


func test_cover_coefficient_forest() -> void:
	var m_cover: float = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.FOREST)
	assert_almost_eq(m_cover, 0.50, 0.01)


func test_cover_coefficient_urban() -> void:
	var m_cover: float = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.URBAN)
	assert_almost_eq(m_cover, 0.35, 0.01)


# =============================================================================
# 直射ダメージ計算テスト
# =============================================================================

func test_direct_fire_damage_calculation() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	shooter.suppression = 0.0

	var target: ElementData.ElementInstance = _create_test_element()
	target.suppression = 0.0

	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0  # Mid範囲

	# 直射効果を計算（1tick分、dt=0.1）
	var result = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# 抑圧増加が正の値であること
	assert_gt(result.d_supp, 0.0, "Suppression should increase")

	# ダメージ（Strength減少）が正の値であること
	assert_gt(result.d_dmg, 0.0, "Damage should be positive")


func test_direct_fire_out_of_range() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	var target: ElementData.ElementInstance = _create_test_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 600.0  # 射程外（max_range=500）

	var result = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# 射程外なのでダメージなし
	assert_eq(result.d_supp, 0.0, "No suppression out of range")
	assert_eq(result.d_dmg, 0.0, "No damage out of range")


func test_direct_fire_suppressed_shooter_reduced() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	var target: ElementData.ElementInstance = _create_test_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0

	# 通常状態での効果
	shooter.suppression = 0.0
	var result_normal = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# Suppressed状態での効果
	shooter.suppression = 0.50
	var result_suppressed = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# Suppressed時は効果が減少
	assert_lt(result_suppressed.d_supp, result_normal.d_supp)
	assert_lt(result_suppressed.d_dmg, result_normal.d_dmg)


func test_direct_fire_moving_target_evasion() -> void:
	var shooter: ElementData.ElementInstance = _create_test_element()
	var target: ElementData.ElementInstance = _create_test_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0

	# 静止目標
	target.is_moving = false
	var result_stationary = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# 移動目標
	target.is_moving = true
	var result_moving = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, distance, 0.1
	)

	# 移動目標は当たりにくい
	assert_lt(result_moving.d_dmg, result_stationary.d_dmg)


# =============================================================================
# 抑圧状態遷移テスト
# =============================================================================

func test_suppression_state_normal() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.30
	var state: GameEnums.UnitState = combat_system.get_suppression_state(element)
	assert_eq(state, GameEnums.UnitState.ACTIVE)


func test_suppression_state_suppressed() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50
	var state: GameEnums.UnitState = combat_system.get_suppression_state(element)
	assert_eq(state, GameEnums.UnitState.SUPPRESSED)


func test_suppression_state_pinned() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.75
	var state: GameEnums.UnitState = combat_system.get_suppression_state(element)
	assert_eq(state, GameEnums.UnitState.PINNED)


func test_suppression_state_broken() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.95
	var state: GameEnums.UnitState = combat_system.get_suppression_state(element)
	assert_eq(state, GameEnums.UnitState.BROKEN)


# =============================================================================
# 抑圧回復テスト
# =============================================================================

func test_suppression_recovery() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50

	# 回復（被弾なし、通信Good、Defend姿勢）
	var recovery: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.GOOD, true, 0.1
	)

	assert_gt(recovery, 0.0, "Should recover suppression")


func test_suppression_no_recovery_under_fire() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50

	# 被弾中は回復なし
	var recovery: float = combat_system.calculate_suppression_recovery(
		element, true, GameEnums.CommState.GOOD, true, 0.1
	)

	assert_eq(recovery, 0.0, "No recovery under fire")


func test_suppression_recovery_reduced_comm_lost() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50

	# 通信Goodでの回復
	var recovery_good: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.GOOD, true, 0.1
	)

	# 通信Lostでの回復
	var recovery_lost: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.LOST, true, 0.1
	)

	# 通信断は回復が遅い
	assert_lt(recovery_lost, recovery_good)


# =============================================================================
# ヘルパー
# =============================================================================

func _create_test_element() -> ElementData.ElementInstance:
	var element_type: ElementData.ElementType = ElementData.ElementType.new()
	element_type.id = "test_infantry"
	element_type.max_strength = 10
	element_type.armor_class = 0  # Soft

	var element: ElementData.ElementInstance = ElementData.ElementInstance.new(element_type)
	element.id = "test_element_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 10
	element.is_moving = false

	return element
