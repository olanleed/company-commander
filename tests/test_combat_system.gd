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
		element, false, GameEnums.CommState.LINKED, true, 0.1
	)

	assert_gt(recovery, 0.0, "Should recover suppression")


func test_suppression_no_recovery_under_fire() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50

	# 被弾中は回復なし
	var recovery: float = combat_system.calculate_suppression_recovery(
		element, true, GameEnums.CommState.LINKED, true, 0.1
	)

	assert_eq(recovery, 0.0, "No recovery under fire")


func test_suppression_recovery_reduced_comm_lost() -> void:
	var element: ElementData.ElementInstance = _create_test_element()
	element.suppression = 0.50

	# 通信Goodでの回復
	var recovery_good: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.LINKED, true, 0.1
	)

	# 通信Lostでの回復
	var recovery_lost: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.ISOLATED, true, 0.1
	)

	# 通信断は回復が遅い
	assert_lt(recovery_lost, recovery_good)


# =============================================================================
# v0.2 戦車戦モデルテスト
# =============================================================================

func test_get_range_band_near() -> void:
	var range_band = combat_system.get_range_band(300.0)
	assert_eq(range_band, GameEnums.RangeBand.NEAR, "300m is NEAR range")


func test_get_range_band_mid() -> void:
	var range_band = combat_system.get_range_band(800.0)
	assert_eq(range_band, GameEnums.RangeBand.MID, "800m is MID range")


func test_get_range_band_far() -> void:
	var range_band = combat_system.get_range_band(2000.0)
	assert_eq(range_band, GameEnums.RangeBand.FAR, "2000m is FAR range")


func test_get_range_band_boundary_near_mid() -> void:
	# 500m is boundary, should be NEAR
	var range_band = combat_system.get_range_band(500.0)
	assert_eq(range_band, GameEnums.RangeBand.NEAR, "500m is NEAR (boundary)")

	# 501m should be MID
	range_band = combat_system.get_range_band(501.0)
	assert_eq(range_band, GameEnums.RangeBand.MID, "501m is MID")


func test_get_range_band_boundary_mid_far() -> void:
	# 1500m is boundary, should be MID
	var range_band = combat_system.get_range_band(1500.0)
	assert_eq(range_band, GameEnums.RangeBand.MID, "1500m is MID (boundary)")

	# 1501m should be FAR
	range_band = combat_system.get_range_band(1501.0)
	assert_eq(range_band, GameEnums.RangeBand.FAR, "1501m is FAR")


func test_calculate_armor_aspect_front() -> void:
	# Shooter at (0,0), target at (100,0) = shooter is to the LEFT of target
	# Target facing LEFT (PI) = facing towards shooter = FRONT armor exposed
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(100, 0)
	var target_facing := PI  # Facing left (towards shooter)

	var aspect = combat_system.calculate_armor_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, GameEnums.ArmorAspect.FRONT, "Target facing shooter = FRONT")


func test_calculate_armor_aspect_rear() -> void:
	# Shooter at (0,0), target at (100,0) = shooter is to the LEFT of target
	# Target facing RIGHT (0) = facing away from shooter = REAR armor exposed
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(100, 0)
	var target_facing := 0.0  # Facing right (away from shooter)

	var aspect = combat_system.calculate_armor_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, GameEnums.ArmorAspect.REAR, "Target facing away = REAR")


func test_calculate_armor_aspect_side() -> void:
	# Shooter to the side of target
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(100, 0)
	var target_facing := PI / 2  # Facing up (perpendicular to shooter)

	var aspect = combat_system.calculate_armor_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, GameEnums.ArmorAspect.SIDE, "Target facing perpendicular = SIDE")


func test_tank_hit_probability_stationary_vs_stationary() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_tank()
	shooter.is_moving = false
	target.is_moving = false

	var p_hit := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.NEAR)
	assert_almost_eq(p_hit, GameConstants.TANK_HIT_SS_NEAR, 0.01, "SS NEAR hit prob")

	p_hit = combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)
	assert_almost_eq(p_hit, GameConstants.TANK_HIT_SS_MID, 0.01, "SS MID hit prob")

	p_hit = combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.FAR)
	assert_almost_eq(p_hit, GameConstants.TANK_HIT_SS_FAR, 0.01, "SS FAR hit prob")


func test_tank_hit_probability_moving_shooter_reduces_accuracy() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_tank()

	# Stationary shooter
	shooter.is_moving = false
	target.is_moving = false
	var p_hit_stationary := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	# Moving shooter
	shooter.is_moving = true
	var p_hit_moving := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	assert_lt(p_hit_moving, p_hit_stationary, "Moving shooter has lower hit prob")


func test_tank_hit_probability_moving_target_reduces_accuracy() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_tank()

	# Stationary target
	shooter.is_moving = false
	target.is_moving = false
	var p_hit_stationary := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	# Moving target
	target.is_moving = true
	var p_hit_moving := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	assert_lt(p_hit_moving, p_hit_stationary, "Moving target is harder to hit")


func test_tank_hit_probability_suppressed_shooter() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_tank()
	shooter.is_moving = false
	target.is_moving = false

	# Normal shooter
	shooter.suppression = 0.0
	var p_hit_normal := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	# Suppressed shooter
	shooter.suppression = 0.50
	var p_hit_suppressed := combat_system.get_tank_hit_probability(shooter, target, GameEnums.RangeBand.MID)

	assert_lt(p_hit_suppressed, p_hit_normal, "Suppressed shooter has lower hit prob")


func test_apfsds_kill_probability_front() -> void:
	var result := combat_system.get_apfsds_kill_probability(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)
	assert_almost_eq(result.kill, GameConstants.APFSDS_KILL_FRONT_NEAR, 0.01)
	assert_almost_eq(result.mission_kill, GameConstants.APFSDS_MKILL_FRONT_NEAR, 0.01)


func test_apfsds_kill_probability_side_higher_than_front() -> void:
	var result_front := combat_system.get_apfsds_kill_probability(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)
	var result_side := combat_system.get_apfsds_kill_probability(GameEnums.ArmorAspect.SIDE, GameEnums.RangeBand.NEAR)

	assert_gt(result_side.kill, result_front.kill, "Side kill prob > front kill prob")


func test_apfsds_kill_probability_rear_highest() -> void:
	var result_front := combat_system.get_apfsds_kill_probability(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)
	var result_rear := combat_system.get_apfsds_kill_probability(GameEnums.ArmorAspect.REAR, GameEnums.RangeBand.NEAR)

	assert_gt(result_rear.kill, result_front.kill, "Rear kill prob > front kill prob")


func test_heat_kill_probability_front_very_low() -> void:
	var result := combat_system.get_heat_kill_probability(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)

	# HEAT is very ineffective against front armor
	assert_lt(result.kill, 0.10, "HEAT vs front armor has very low kill prob")


func test_heat_kill_probability_side_effective() -> void:
	var result := combat_system.get_heat_kill_probability(GameEnums.ArmorAspect.SIDE, GameEnums.RangeBand.NEAR)

	# HEAT is effective against side armor
	assert_gt(result.kill, 0.50, "HEAT vs side armor is effective")


func test_is_heavy_armor() -> void:
	var tank := _create_test_tank()
	assert_true(combat_system.is_heavy_armor(tank), "Tank is heavy armor")

	var infantry := _create_test_element()
	assert_false(combat_system.is_heavy_armor(infantry), "Infantry is not heavy armor")


func test_should_use_tank_combat_heavy_vs_heavy() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_tank()
	var tank_gun := _create_test_tank_gun()

	var should_use := combat_system.should_use_tank_combat(shooter, target, tank_gun)
	assert_true(should_use, "Tank vs tank should use tank combat model")


func test_should_use_tank_combat_infantry_target() -> void:
	var shooter := _create_test_tank()
	var target := _create_test_element()  # Infantry
	var tank_gun := _create_test_tank_gun()

	var should_use := combat_system.should_use_tank_combat(shooter, target, tank_gun)
	assert_false(should_use, "Tank vs infantry should NOT use tank combat model")


func test_should_use_tank_combat_rifle_weapon() -> void:
	var shooter := _create_test_element()
	var target := _create_test_tank()
	var rifle := WeaponData.create_rifle()

	var should_use := combat_system.should_use_tank_combat(shooter, target, rifle)
	assert_false(should_use, "Rifle vs tank should NOT use tank combat model")


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


func _create_test_tank() -> ElementData.ElementInstance:
	var element_type: ElementData.ElementType = ElementData.ElementType.new()
	element_type.id = "test_tank"
	element_type.max_strength = 4  # 4両編成
	element_type.armor_class = 4  # Heavy armor (>= 3 is heavy)
	element_type.category = ElementData.Category.VEH

	var element: ElementData.ElementInstance = ElementData.ElementInstance.new(element_type)
	element.id = "test_tank_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 4
	element.is_moving = false
	element.facing = 0.0
	element.mobility_hp = 100
	element.firepower_hp = 100
	element.sensors_hp = 100

	return element


func _create_test_tank_gun() -> WeaponData.WeaponType:
	var weapon := WeaponData.WeaponType.new()
	weapon.id = "test_tank_gun"
	weapon.display_name = "120mm APFSDS"
	weapon.mechanism = WeaponData.Mechanism.KINETIC
	weapon.threat_class = WeaponData.ThreatClass.AT
	weapon.max_range_m = 2500.0
	return weapon
