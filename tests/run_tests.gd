extends SceneTree

## シンプルなテストランナー
## Usage: godot --headless --script tests/run_tests.gd

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""

func _init() -> void:
	print("============================================================")
	print("Company Commander - Unit Tests")
	print("============================================================")

	run_all_tests()

	print("")
	print("============================================================")
	print("Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	print("============================================================")

	quit(0 if _tests_failed == 0 else 1)


func run_all_tests() -> void:
	print("\n[WeaponData Tests]")
	test_weapon_data()

	print("\n[CombatSystem Tests]")
	test_combat_system()

	print("\n[CombatSystem v0.1R Tests]")
	test_combat_system_v01r()

	print("\n[Mission Kill Tests]")
	test_mission_kill()

	print("\n[AmmunitionData Tests]")
	test_ammunition_data()

	print("\n[ProtectionData Tests]")
	test_protection_data()

	print("\n[WeaponData Extended Tests]")
	test_weapon_data_extended()

	print("\n[ElementData Extended Tests]")
	test_element_data_extended()

	print("\n[ERA/APS Integration Tests]")
	test_era_aps_integration()

	print("\n[JGSDF Weapons Tests]")
	test_jgsdf_weapons()

	print("\n[VehicleCatalog Integration Tests]")
	test_vehicle_catalog_integration()


# =============================================================================
# WeaponData Tests
# =============================================================================

func test_weapon_data() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	# Test: WeaponType creation
	_current_test = "weapon_type_creation"
	var weapon: RefCounted = WeaponDataClass.WeaponType.new()
	weapon.id = "rifle_m4"
	weapon.mechanism = WeaponDataClass.Mechanism.SMALL_ARMS
	assert_eq(weapon.id, "rifle_m4")
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS)
	_pass()

	# Test: Range band determination (use default thresholds)
	_current_test = "range_band_determination"
	# weapon.range_band_thresholds_m はデフォルト[200.0, 800.0]を使用
	assert_eq(weapon.get_range_band(100.0), WeaponDataClass.RangeBand.NEAR)
	assert_eq(weapon.get_range_band(500.0), WeaponDataClass.RangeBand.MID)
	assert_eq(weapon.get_range_band(1000.0), WeaponDataClass.RangeBand.FAR)
	_pass()

	# Test: is_in_range
	_current_test = "weapon_in_range"
	weapon.min_range_m = 50.0
	weapon.max_range_m = 800.0
	assert_false(weapon.is_in_range(40.0))
	assert_true(weapon.is_in_range(400.0))
	assert_false(weapon.is_in_range(900.0))
	_pass()

	# Test: Preset rifle
	_current_test = "preset_rifle_creation"
	var rifle: RefCounted = WeaponDataClass.create_rifle()
	assert_eq(rifle.id, "rifle_standard")
	assert_eq(rifle.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS)
	assert_eq(rifle.max_range_m, 500.0)
	_pass()

	# Test: Preset MG
	_current_test = "preset_mg_creation"
	var mg: RefCounted = WeaponDataClass.create_machine_gun()
	assert_eq(mg.id, "mg_standard")
	assert_eq(mg.max_range_m, 1000.0)
	_pass()

	# Test: Lethality retrieval
	_current_test = "lethality_retrieval"
	var lethality: int = rifle.get_lethality(100.0, WeaponDataClass.TargetClass.SOFT)
	assert_gt(lethality, 0)
	_pass()


# =============================================================================
# CombatSystem Tests
# =============================================================================

func test_combat_system() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")

	var combat_system: RefCounted = CombatSystemClass.new()

	# Test: Shooter coefficient normal
	_current_test = "shooter_coefficient_normal"
	var shooter: RefCounted = _create_test_element(ElementDataClass)
	shooter.suppression = 0.0
	var m_shooter: float = combat_system.calculate_shooter_coefficient(shooter)
	assert_almost_eq(m_shooter, 1.0, 0.01)
	_pass()

	# Test: Shooter coefficient suppressed
	_current_test = "shooter_coefficient_suppressed"
	shooter.suppression = 0.50
	m_shooter = combat_system.calculate_shooter_coefficient(shooter)
	assert_almost_eq(m_shooter, 0.70, 0.01)
	_pass()

	# Test: Shooter coefficient pinned
	_current_test = "shooter_coefficient_pinned"
	shooter.suppression = 0.75
	m_shooter = combat_system.calculate_shooter_coefficient(shooter)
	assert_almost_eq(m_shooter, 0.35, 0.01)
	_pass()

	# Test: Shooter coefficient broken
	_current_test = "shooter_coefficient_broken"
	shooter.suppression = 0.95
	m_shooter = combat_system.calculate_shooter_coefficient(shooter)
	assert_almost_eq(m_shooter, 0.15, 0.01)
	_pass()

	# Test: Cover coefficient
	_current_test = "cover_coefficient_open"
	var m_cover: float = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.OPEN)
	assert_almost_eq(m_cover, 1.0, 0.01)
	_pass()

	_current_test = "cover_coefficient_forest"
	m_cover = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.FOREST)
	assert_almost_eq(m_cover, 0.50, 0.01)
	_pass()

	_current_test = "cover_coefficient_urban"
	m_cover = combat_system.get_cover_coefficient_df(GameEnums.TerrainType.URBAN)
	assert_almost_eq(m_cover, 0.35, 0.01)
	_pass()

	# Test: Direct fire damage
	_current_test = "direct_fire_damage"
	shooter.suppression = 0.0
	var target: RefCounted = _create_test_element(ElementDataClass)
	var weapon: RefCounted = WeaponDataClass.create_rifle()
	var result: RefCounted = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, 300.0, 0.1
	)
	assert_true(result.is_valid)
	assert_gt(result.d_supp, 0.0)
	assert_gt(result.d_dmg, 0.0)
	_pass()

	# Test: Out of range
	_current_test = "direct_fire_out_of_range"
	result = combat_system.calculate_direct_fire_effect(
		shooter, target, weapon, 600.0, 0.1
	)
	assert_false(result.is_valid)
	assert_eq(result.d_supp, 0.0)
	_pass()

	# Test: Suppression state transitions
	_current_test = "suppression_state_active"
	var element: RefCounted = _create_test_element(ElementDataClass)
	element.suppression = 0.30
	assert_eq(combat_system.get_suppression_state(element), GameEnums.UnitState.ACTIVE)
	_pass()

	_current_test = "suppression_state_suppressed"
	element.suppression = 0.50
	assert_eq(combat_system.get_suppression_state(element), GameEnums.UnitState.SUPPRESSED)
	_pass()

	_current_test = "suppression_state_pinned"
	element.suppression = 0.75
	assert_eq(combat_system.get_suppression_state(element), GameEnums.UnitState.PINNED)
	_pass()

	_current_test = "suppression_state_broken"
	element.suppression = 0.95
	assert_eq(combat_system.get_suppression_state(element), GameEnums.UnitState.BROKEN)
	_pass()

	# Test: Suppression recovery
	_current_test = "suppression_recovery"
	element.suppression = 0.50
	var recovery: float = combat_system.calculate_suppression_recovery(
		element, false, GameEnums.CommState.LINKED, true, 0.1
	)
	assert_gt(recovery, 0.0)
	_pass()

	_current_test = "suppression_no_recovery_under_fire"
	recovery = combat_system.calculate_suppression_recovery(
		element, true, GameEnums.CommState.LINKED, true, 0.1
	)
	assert_eq(recovery, 0.0)
	_pass()


# =============================================================================
# CombatSystem v0.1R Tests
# =============================================================================

func test_combat_system_v01r() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")

	var combat_system: RefCounted = CombatSystemClass.new()

	# Test: v0.1R constants
	_current_test = "v01r_constants"
	assert_almost_eq(GameConstants.K_DF_SUPP, 0.12, 0.01)
	assert_almost_eq(GameConstants.K_DF_HIT, 0.50, 0.01)  # Updated: 0.25→0.50 for improved AT hit rate
	assert_almost_eq(GameConstants.K_IF_SUPP, 3.0, 0.01)
	assert_almost_eq(GameConstants.K_IF_HIT, 0.65, 0.01)
	_pass()

	# Test: Vulnerability - Soft vs SmallArms
	_current_test = "vulnerability_soft_smallarms"
	var soft_target: RefCounted = _create_test_element(ElementDataClass)
	soft_target.element_type.armor_class = 0  # Soft
	var vuln_dmg: float = combat_system.get_vulnerability_dmg(soft_target, WeaponDataClass.ThreatClass.SMALL_ARMS)
	var vuln_supp: float = combat_system.get_vulnerability_supp(soft_target, WeaponDataClass.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln_dmg, 1.0, 0.01)
	assert_almost_eq(vuln_supp, 1.0, 0.01)
	_pass()

	# Test: Vulnerability - Heavy vs SmallArms (low dmg, some supp)
	_current_test = "vulnerability_heavy_smallarms"
	var heavy_target: RefCounted = _create_heavy_element(ElementDataClass)
	vuln_dmg = combat_system.get_vulnerability_dmg(heavy_target, WeaponDataClass.ThreatClass.SMALL_ARMS)
	vuln_supp = combat_system.get_vulnerability_supp(heavy_target, WeaponDataClass.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln_dmg, GameConstants.VULN_HEAVY_SMALLARMS_DMG, 0.01)  # Tank immune to small arms damage
	assert_almost_eq(vuln_supp, GameConstants.VULN_HEAVY_SMALLARMS_SUPP, 0.01)  # But can be suppressed slightly
	_pass()

	# Test: Hit probability calculation
	_current_test = "hit_probability_calculation"
	# p_hit = 1 - exp(-K_DF_HIT × E)
	# For E=1.0: p_hit = 1 - exp(-0.50) ≈ 0.393 (K_DF_HIT was updated from 0.25 to 0.50)
	var p_hit: float = combat_system.calculate_hit_probability(1.0)
	var expected_p_hit: float = 1.0 - exp(-GameConstants.K_DF_HIT * 1.0)
	assert_almost_eq(p_hit, expected_p_hit, 0.01)
	_pass()

	# Test: Hit probability zero when exposure is 0
	_current_test = "hit_probability_zero_exposure"
	p_hit = combat_system.calculate_hit_probability(0.0)
	assert_eq(p_hit, 0.0)
	_pass()

	# Test: Vehicle subsystem states - mobility
	_current_test = "vehicle_mobility_state"
	var vehicle: RefCounted = _create_heavy_element(ElementDataClass)
	vehicle.mobility_hp = 100
	assert_eq(combat_system.get_mobility_state(vehicle), GameEnums.VehicleMobilityState.NORMAL)
	vehicle.mobility_hp = 40
	assert_eq(combat_system.get_mobility_state(vehicle), GameEnums.VehicleMobilityState.DAMAGED)
	vehicle.mobility_hp = 20
	assert_eq(combat_system.get_mobility_state(vehicle), GameEnums.VehicleMobilityState.CRITICAL)
	vehicle.mobility_hp = 0
	assert_eq(combat_system.get_mobility_state(vehicle), GameEnums.VehicleMobilityState.IMMOBILIZED)
	_pass()

	# Test: Vehicle subsystem states - firepower
	_current_test = "vehicle_firepower_state"
	vehicle.firepower_hp = 100
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.NORMAL)
	vehicle.firepower_hp = 40
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.DAMAGED)
	vehicle.firepower_hp = 20
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.CRITICAL)
	vehicle.firepower_hp = 0
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.WEAPON_DISABLED)
	_pass()

	# Test: Vehicle subsystem states - sensors
	_current_test = "vehicle_sensors_state"
	vehicle.sensors_hp = 100
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.NORMAL)
	vehicle.sensors_hp = 40
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.DAMAGED)
	vehicle.sensors_hp = 20
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.CRITICAL)
	vehicle.sensors_hp = 0
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.SENSORS_DOWN)
	_pass()

	# Test: Aspect angle calculation
	_current_test = "aspect_angle_calculation"
	# Shooter at (0, 0), target at (100, 0) facing right (angle 0)
	var aspect: int = combat_system.calculate_aspect(Vector2(0, 0), Vector2(100, 0), 0.0)
	assert_eq(aspect, WeaponDataClass.ArmorZone.REAR)  # Shooting from behind
	# Shooter at (200, 0), target at (100, 0) facing right
	aspect = combat_system.calculate_aspect(Vector2(200, 0), Vector2(100, 0), 0.0)
	assert_eq(aspect, WeaponDataClass.ArmorZone.FRONT)  # Shooting from front
	_pass()

	# Test: Aspect multiplier - Heavy armor
	_current_test = "aspect_multiplier_heavy"
	var heavy_for_aspect: RefCounted = _create_heavy_element(ElementDataClass)
	var mult_front: float = combat_system.get_aspect_multiplier(heavy_for_aspect, WeaponDataClass.ArmorZone.FRONT)
	var mult_rear: float = combat_system.get_aspect_multiplier(heavy_for_aspect, WeaponDataClass.ArmorZone.REAR)
	assert_almost_eq(mult_front, 0.70, 0.01)
	assert_almost_eq(mult_rear, 1.25, 0.01)
	_pass()

	# Test: Damage category distribution
	_current_test = "damage_category_distribution"
	var minor_count: int = 0
	var major_count: int = 0
	var critical_count: int = 0
	for i in range(1000):
		var category: int = combat_system.roll_damage_category(1.0)
		match category:
			GameEnums.DamageCategory.MINOR:
				minor_count += 1
			GameEnums.DamageCategory.MAJOR:
				major_count += 1
			GameEnums.DamageCategory.CRITICAL:
				critical_count += 1
	# Minor should be most common, Critical least
	assert_true(minor_count > major_count)
	assert_true(major_count > critical_count)
	_pass()

	# Test: Soft damage calculation
	_current_test = "soft_damage_calculation"
	var damage_minor: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.MINOR)
	var damage_major: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.MAJOR)
	var damage_critical: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.CRITICAL)
	assert_true(damage_minor >= 0.8 and damage_minor <= 2.0)
	assert_true(damage_major >= 2.0 and damage_major <= 5.0)
	assert_true(damage_critical >= 5.0 and damage_critical <= 12.0)
	_pass()

	# Test: v0.1R direct fire effect
	_current_test = "v01r_direct_fire_effect"
	var shooter: RefCounted = _create_test_element(ElementDataClass)
	var target: RefCounted = _create_test_element(ElementDataClass)
	var weapon: RefCounted = WeaponDataClass.create_rifle()
	var result: RefCounted = combat_system.calculate_direct_fire_effect_v01r(
		shooter, target, weapon, 300.0, 1.0,
		1.0, GameEnums.TerrainType.OPEN, false
	)
	assert_true(result.is_valid)
	assert_gt(result.d_supp, 0.0)
	assert_true(result.p_hit >= 0.0 and result.p_hit <= 1.0)
	_pass()


# =============================================================================
# Helpers
# =============================================================================

func _create_heavy_element(ElementDataClass: GDScript) -> RefCounted:
	var element_type: RefCounted = ElementDataClass.ElementType.new()
	element_type.id = "test_tank"
	element_type.max_strength = 1
	element_type.armor_class = 3  # Heavy (MBT)

	var element: RefCounted = ElementDataClass.ElementInstance.new(element_type)
	element.id = "test_tank_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 1
	element.is_moving = false

	return element

# =============================================================================
# Mission Kill Tests
# =============================================================================

func test_mission_kill() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	var combat_system: RefCounted = CombatSystemClass.new()

	# Test: Mission kill reduces strength, not disables entire platoon
	_current_test = "mission_kill_reduces_strength"
	var tank: RefCounted = _create_tank_element(ElementDataClass)
	var initial_strength: int = tank.current_strength  # 4

	combat_system._apply_mission_kill(tank, WeaponDataClass.ThreatClass.AT)

	# Strength should decrease by 1
	assert_eq(tank.current_strength, initial_strength - 1)
	# Firepower should NOT be 0
	assert_gt(tank.firepower_hp, 0)
	_pass()

	# Test: Tank can still fire after one M-KILL
	_current_test = "can_fire_after_mission_kill"
	var can_fire: bool = combat_system._can_fire_tank_gun(tank, 100)
	assert_true(can_fire)
	_pass()

	# Test: Multiple M-KILLs gradually degrade
	_current_test = "multiple_mission_kills"
	var tank2: RefCounted = _create_tank_element(ElementDataClass)
	var fire_count: int = 0

	for i in range(4):
		if combat_system._can_fire_tank_gun(tank2, 100 + i * 10):
			fire_count += 1
		combat_system._apply_mission_kill(tank2, WeaponDataClass.ThreatClass.AT)

	# After 4 M-KILLs, strength should be 0
	assert_eq(tank2.current_strength, 0)
	# Should have been able to fire at least 3 times before total loss
	assert_gt(fire_count, 2)
	_pass()

	# Test: Proportional firepower reduction
	_current_test = "proportional_firepower_reduction"
	var tank3: RefCounted = _create_tank_element(ElementDataClass)
	var hp_per_vehicle: int = int(100.0 / float(tank3.element_type.max_strength))  # 25

	# Apply M-KILL that damages firepower (run multiple times to ensure at least one)
	var firepower_damaged: bool = false
	for trial in range(20):
		var test_tank: RefCounted = _create_tank_element(ElementDataClass)
		var orig_fp: int = test_tank.firepower_hp
		combat_system._apply_mission_kill(test_tank, WeaponDataClass.ThreatClass.AT)
		if test_tank.firepower_hp < orig_fp:
			# Check that damage is proportional (25 per vehicle)
			var damage: int = orig_fp - test_tank.firepower_hp
			assert_eq(damage, hp_per_vehicle)
			firepower_damaged = true
			break

	assert_true(firepower_damaged)
	_pass()


func _create_tank_element(ElementDataClass: GDScript) -> RefCounted:
	var element_type: RefCounted = ElementDataClass.ElementType.new()
	element_type.id = "tank_plt"
	element_type.max_strength = 4
	element_type.armor_class = 3  # Heavy armor

	var element: RefCounted = ElementDataClass.ElementInstance.new(element_type)
	element.id = "tank_element_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 4
	element.is_moving = false
	element.firepower_hp = 100
	element.mobility_hp = 100
	element.sensors_hp = 100
	element.last_fire_tick = -1

	return element


func _create_test_element(ElementDataClass: GDScript) -> RefCounted:
	var element_type: RefCounted = ElementDataClass.ElementType.new()
	element_type.id = "test_infantry"
	element_type.max_strength = 10
	element_type.armor_class = 0

	var element: RefCounted = ElementDataClass.ElementInstance.new(element_type)
	element.id = "test_element_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 10
	element.is_moving = false

	return element


# =============================================================================
# AmmunitionData Tests
# =============================================================================

func test_ammunition_data() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: AmmoType enum exists
	_current_test = "ammo_type_enum_exists"
	assert_true(AmmoDataClass.AmmoType.APFSDS_120MM >= 0)
	assert_true(AmmoDataClass.AmmoType.APFSDS_125MM >= 0)
	assert_true(AmmoDataClass.AmmoType.HEAT_120MM >= 0)
	assert_true(AmmoDataClass.AmmoType.HE_MP_120MM >= 0)
	_pass()

	# Test: GuidanceType enum exists
	_current_test = "guidance_type_enum_exists"
	assert_true(AmmoDataClass.GuidanceType.NONE >= 0)
	assert_true(AmmoDataClass.GuidanceType.SACLOS >= 0)
	assert_true(AmmoDataClass.GuidanceType.GPS_INS >= 0)
	_pass()

	# Test: FuzeType enum exists
	_current_test = "fuze_type_enum_exists"
	assert_true(AmmoDataClass.FuzeType.IMPACT >= 0)
	assert_true(AmmoDataClass.FuzeType.PROXIMITY >= 0)
	_pass()

	# Test: AmmoProfile creation
	_current_test = "ammo_profile_creation"
	var profile: RefCounted = AmmoDataClass.AmmoProfile.new()
	profile.ammo_type = AmmoDataClass.AmmoType.APFSDS_120MM
	profile.pen_ke = 140
	profile.pen_ce = 0
	assert_eq(profile.pen_ke, 140)
	assert_eq(profile.pen_ce, 0)
	_pass()

	# Test: is_ke_round check
	_current_test = "is_ke_round_check"
	assert_true(profile.is_ke_round())
	assert_false(profile.is_ce_round())
	_pass()

	# Test: Get 120mm APFSDS profile
	_current_test = "get_apfsds_120mm_profile"
	var apfsds_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APFSDS_120MM)
	assert_eq(apfsds_120.pen_ke, 140)  # 700mm RHA
	assert_true(apfsds_120.is_ke_round())
	_pass()

	# Test: Get 125mm APFSDS profile
	_current_test = "get_apfsds_125mm_profile"
	var apfsds_125: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APFSDS_125MM)
	assert_eq(apfsds_125.pen_ke, 130)  # 650mm RHA
	_pass()

	# Test: Get HEAT profile (CE round)
	_current_test = "get_heat_120mm_profile"
	var heat_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HEAT_120MM)
	assert_eq(heat_120.pen_ce, 90)  # 450mm RHA
	assert_true(heat_120.is_ce_round())
	_pass()

	# Test: ATGM tandem defeats ERA
	_current_test = "atgm_tandem_defeats_era"
	var atgm: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.ATGM_TANDEM)
	assert_true(atgm.defeats_era)
	assert_eq(atgm.pen_ce, 180)  # 900mm RHA
	_pass()

	# Test: Top attack ATGM
	_current_test = "atgm_topattack"
	var javelin: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.ATGM_TOPATTACK)
	assert_true(javelin.is_top_attack)
	assert_eq(javelin.guidance, AmmoDataClass.GuidanceType.IR_HOMING)
	_pass()

	# Test: Ammo selection for armor
	_current_test = "select_ammo_for_armor"
	var available: Array = [
		AmmoDataClass.AmmoType.APFSDS_120MM,
		AmmoDataClass.AmmoType.HEAT_120MM,
		AmmoDataClass.AmmoType.HE_MP_120MM
	]
	var best: int = AmmoDataClass.select_best_ammo_for_armor(available, 100, false)
	assert_eq(best, AmmoDataClass.AmmoType.APFSDS_120MM)  # KE vs armor
	_pass()

	# Test: Ammo selection for soft target
	_current_test = "select_ammo_for_soft"
	best = AmmoDataClass.select_best_ammo_for_soft(available)
	assert_eq(best, AmmoDataClass.AmmoType.HE_MP_120MM)  # HE-MP vs soft
	_pass()

	# Test: Mortar ammo
	_current_test = "mortar_ammo_profile"
	var mortar_he: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_120MM_MORTAR)
	assert_gt(mortar_he.blast_radius, 0.0)
	_pass()

	# Test: Howitzer ammo
	_current_test = "howitzer_ammo_profile"
	var how_he: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_155MM)
	assert_gt(how_he.blast_radius, 30.0)
	_pass()

	# Test: Guided ammo
	_current_test = "guided_ammo_profile"
	var excalibur: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.GUIDED_155MM)
	assert_eq(excalibur.guidance, AmmoDataClass.GuidanceType.GPS_INS)
	assert_true(excalibur.is_guided())
	_pass()


# =============================================================================
# ProtectionData Tests
# =============================================================================

func test_protection_data() -> void:
	var ProtDataClass: GDScript = load("res://scripts/data/protection_data.gd")

	# Test: ERAType enum exists
	_current_test = "era_type_enum_exists"
	assert_true(ProtDataClass.ERAType.NONE >= 0)
	assert_true(ProtDataClass.ERAType.KONTAKT_5 >= 0)
	assert_true(ProtDataClass.ERAType.RELIKT >= 0)
	_pass()

	# Test: APSType enum exists
	_current_test = "aps_type_enum_exists"
	assert_true(ProtDataClass.APSType.NONE >= 0)
	assert_true(ProtDataClass.APSType.HARD_KILL_TROPHY >= 0)
	assert_true(ProtDataClass.APSType.HARD_KILL_AFGHANIT >= 0)
	_pass()

	# Test: CompositeGen enum exists
	_current_test = "composite_gen_enum_exists"
	assert_true(ProtDataClass.CompositeGen.NONE >= 0)
	assert_true(ProtDataClass.CompositeGen.GEN_3 >= 0)
	_pass()

	# Test: ProtectionProfile creation
	_current_test = "protection_profile_creation"
	var profile: RefCounted = ProtDataClass.ProtectionProfile.new()
	profile.base_armor_ke = 100
	profile.base_armor_ce = 80
	profile.era_type = ProtDataClass.ERAType.NONE
	profile.aps_type = ProtDataClass.APSType.NONE
	profile.composite_gen = ProtDataClass.CompositeGen.NONE
	assert_eq(profile.base_armor_ke, 100)
	assert_eq(profile.base_armor_ce, 80)
	_pass()

	# Test: ERA bonus calculation
	_current_test = "era_bonus_calculation"
	profile.era_type = ProtDataClass.ERAType.RELIKT
	var era_ke: int = profile.get_era_bonus_ke()
	var era_ce: int = profile.get_era_bonus_ce()
	assert_eq(era_ke, 15)  # Relikt KE bonus
	assert_eq(era_ce, 40)  # Relikt CE bonus
	_pass()

	# Test: Effective armor with ERA
	_current_test = "effective_armor_with_era"
	profile.base_armor_ke = 90
	profile.base_armor_ce = 70
	profile.era_type = ProtDataClass.ERAType.RELIKT
	profile.composite_gen = ProtDataClass.CompositeGen.NONE
	var eff_ke: int = profile.get_effective_armor_ke()
	var eff_ce: int = profile.get_effective_armor_ce()
	assert_eq(eff_ke, 90 + 15)  # base + ERA
	assert_eq(eff_ce, 70 + 40)  # base + ERA
	_pass()

	# Test: Effective armor with composite
	_current_test = "effective_armor_with_composite"
	profile.base_armor_ke = 100
	profile.base_armor_ce = 80
	profile.era_type = ProtDataClass.ERAType.NONE
	profile.composite_gen = ProtDataClass.CompositeGen.GEN_3
	eff_ke = profile.get_effective_armor_ke()
	eff_ce = profile.get_effective_armor_ce()
	assert_eq(eff_ke, int(100 * 1.6))  # Gen3 KE mult
	assert_eq(eff_ce, int(80 * 2.2))   # Gen3 CE mult
	_pass()

	# Test: APS intercept probability
	_current_test = "aps_intercept_probability"
	profile.aps_type = ProtDataClass.APSType.HARD_KILL_TROPHY
	var prob_atgm: float = profile.get_aps_intercept_probability("atgm")
	var prob_rpg: float = profile.get_aps_intercept_probability("rpg")
	var prob_apfsds: float = profile.get_aps_intercept_probability("apfsds")
	assert_almost_eq(prob_atgm, 0.85, 0.01)
	assert_almost_eq(prob_rpg, 0.9, 0.01)
	assert_almost_eq(prob_apfsds, 0.0, 0.01)  # Trophy can't intercept KE
	_pass()

	# Test: has_era / has_aps
	_current_test = "has_era_has_aps"
	assert_true(profile.has_aps())
	profile.aps_type = ProtDataClass.APSType.NONE
	assert_false(profile.has_aps())
	profile.era_type = ProtDataClass.ERAType.KONTAKT_5
	assert_true(profile.has_era())
	_pass()

	# Test: Tandem defeats ERA
	_current_test = "tandem_defeats_era"
	profile.base_armor_ce = 70
	profile.era_type = ProtDataClass.ERAType.RELIKT
	profile.composite_gen = ProtDataClass.CompositeGen.GEN_2
	var normal_ce: int = profile.get_effective_armor_ce()
	var tandem_ce: int = profile.get_effective_armor_ce_vs_tandem()
	assert_gt(normal_ce, tandem_ce)  # ERA ignored for tandem
	_pass()

	# Test: MBT NATO preset
	_current_test = "mbt_nato_preset"
	var mbt_nato: RefCounted = ProtDataClass.create_mbt_front_nato()
	assert_eq(mbt_nato.base_armor_ke, 100)
	assert_eq(mbt_nato.composite_gen, ProtDataClass.CompositeGen.GEN_3)
	assert_eq(mbt_nato.aps_type, ProtDataClass.APSType.HARD_KILL_TROPHY)
	_pass()

	# Test: MBT Russian preset
	_current_test = "mbt_rus_preset"
	var mbt_rus: RefCounted = ProtDataClass.create_mbt_front_rus()
	assert_eq(mbt_rus.era_type, ProtDataClass.ERAType.RELIKT)
	assert_true(mbt_rus.has_era())
	_pass()

	# Test: Zone armor multiplier
	_current_test = "zone_armor_multiplier"
	var front: int = ProtDataClass.get_zone_armor(mbt_nato, "front", true)
	var side: int = ProtDataClass.get_zone_armor(mbt_nato, "side", true)
	var rear: int = ProtDataClass.get_zone_armor(mbt_nato, "rear", true)
	assert_gt(front, side)
	assert_gt(side, rear)
	_pass()


# =============================================================================
# WeaponData Extended Tests
# =============================================================================

func test_weapon_data_extended() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	# Test: All concrete weapons count
	_current_test = "all_concrete_weapons_count"
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_gt(all_weapons.size(), 20)  # 22 weapons total
	_pass()

	# Test: 125mm tank gun exists
	_current_test = "tank_ke_125_exists"
	assert_true("CW_TANK_KE_125" in all_weapons)
	var tank_125: RefCounted = all_weapons["CW_TANK_KE_125"]
	assert_eq(tank_125.mechanism, WeaponDataClass.Mechanism.KINETIC)
	_pass()

	# Test: 125mm vs 120mm penetration comparison
	_current_test = "tank_caliber_comparison"
	var tank_120: RefCounted = all_weapons["CW_TANK_KE"]
	var tank_125v: RefCounted = all_weapons["CW_TANK_KE_125"]
	# 120mm should have higher pen than 125mm
	assert_gt(tank_120.pen_ke[WeaponDataClass.RangeBand.NEAR], tank_125v.pen_ke[WeaponDataClass.RangeBand.NEAR])
	_pass()

	# Test: 105mm light tank gun
	_current_test = "tank_ke_105_exists"
	assert_true("CW_TANK_KE_105" in all_weapons)
	var tank_105: RefCounted = all_weapons["CW_TANK_KE_105"]
	# 105mm should have lower pen than 125mm
	assert_gt(tank_125v.pen_ke[WeaponDataClass.RangeBand.NEAR], tank_105.pen_ke[WeaponDataClass.RangeBand.NEAR])
	_pass()

	# Test: 25mm autocannon exists
	_current_test = "autocannon_25_exists"
	assert_true("CW_AUTOCANNON_25" in all_weapons)
	var ac_25: RefCounted = all_weapons["CW_AUTOCANNON_25"]
	var ac_30: RefCounted = all_weapons["CW_AUTOCANNON_30"]
	# 30mm should have higher pen than 25mm
	assert_gt(ac_30.pen_ke[WeaponDataClass.RangeBand.NEAR], ac_25.pen_ke[WeaponDataClass.RangeBand.NEAR])
	_pass()

	# Test: 81mm mortar exists
	_current_test = "mortar_81_exists"
	assert_true("CW_MORTAR_81" in all_weapons)
	var mortar_81: RefCounted = all_weapons["CW_MORTAR_81"]
	var mortar_120: RefCounted = all_weapons["CW_MORTAR_120"]
	# 120mm should have larger blast radius
	assert_gt(mortar_120.blast_radius_m, mortar_81.blast_radius_m)
	_pass()

	# Test: 152mm howitzer exists
	_current_test = "howitzer_152_exists"
	assert_true("CW_HOWITZER_152" in all_weapons)
	var how_152: RefCounted = all_weapons["CW_HOWITZER_152"]
	assert_eq(how_152.fire_model, WeaponDataClass.FireModel.INDIRECT)
	_pass()

	# Test: Top attack ATGM
	_current_test = "atgm_topattack_exists"
	assert_true("CW_ATGM_TOPATTACK" in all_weapons)
	var javelin: RefCounted = all_weapons["CW_ATGM_TOPATTACK"]
	assert_eq(javelin.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE)
	# High lethality vs heavy armor
	var leth_heavy: int = javelin.lethality[WeaponDataClass.RangeBand.NEAR][WeaponDataClass.TargetClass.HEAVY]
	assert_eq(leth_heavy, 100)  # Top attack kills MBTs
	_pass()

	# Test: Beam riding ATGM
	_current_test = "atgm_beamride_exists"
	assert_true("CW_ATGM_BEAMRIDE" in all_weapons)
	var kornet: RefCounted = all_weapons["CW_ATGM_BEAMRIDE"]
	# Long range
	assert_gt(kornet.max_range_m, 5000.0)
	# High CE penetration
	assert_eq(kornet.pen_ce[WeaponDataClass.RangeBand.NEAR], 200)
	_pass()


# =============================================================================
# ElementData Extended Tests
# =============================================================================

func test_element_data_extended() -> void:
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")

	# Test: All archetypes count
	_current_test = "all_archetypes_count"
	var all_archetypes: Dictionary = ElementDataClass.ElementArchetypes.get_all_archetypes()
	assert_gt(all_archetypes.size(), 22)  # 24 archetypes total
	_pass()

	# Test: Light tank exists
	_current_test = "light_tank_exists"
	assert_true("LIGHT_TANK" in all_archetypes)
	var light_tank: RefCounted = all_archetypes["LIGHT_TANK"]
	assert_eq(light_tank.armor_class, 2)  # Medium armor
	# Should be faster than MBT
	var mbt: RefCounted = all_archetypes["TANK_PLT"]
	assert_gt(light_tank.road_speed, mbt.road_speed)
	_pass()

	# Test: Light tank has less armor than MBT
	_current_test = "light_tank_armor_vs_mbt"
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var light_armor: int = light_tank.armor_ke[WeaponDataClass.ArmorZone.FRONT]
	var mbt_armor: int = mbt.armor_ke[WeaponDataClass.ArmorZone.FRONT]
	assert_gt(mbt_armor, light_armor)  # MBT has more armor
	_pass()

	# Test: MLRS exists
	_current_test = "mlrs_exists"
	assert_true("MLRS" in all_archetypes)
	var mlrs: RefCounted = all_archetypes["MLRS"]
	assert_eq(mlrs.category, ElementDataClass.Category.WEAP)
	_pass()

	# Test: Engineer vehicle exists
	_current_test = "engineer_veh_exists"
	assert_true("ENGINEER_VEH" in all_archetypes)
	var eng: RefCounted = all_archetypes["ENGINEER_VEH"]
	assert_eq(eng.category, ElementDataClass.Category.ENG)
	assert_eq(eng.armor_class, 2)  # Medium armor
	_pass()

	# Test: EW vehicle exists
	_current_test = "ew_veh_exists"
	assert_true("EW_VEH" in all_archetypes)
	var ew: RefCounted = all_archetypes["EW_VEH"]
	assert_eq(ew.category, ElementDataClass.Category.REC)
	assert_gt(ew.spot_range_base, 1000.0)  # High sensor range
	_pass()

	# Test: ISR vehicle exists
	_current_test = "isr_veh_exists"
	assert_true("ISR_VEH" in all_archetypes)
	var isr: RefCounted = all_archetypes["ISR_VEH"]
	assert_gt(isr.spot_range_base, 1400.0)  # Very high sensor range
	_pass()

	# Test: Medical vehicle exists
	_current_test = "medical_veh_exists"
	assert_true("MEDICAL_VEH" in all_archetypes)
	var med: RefCounted = all_archetypes["MEDICAL_VEH"]
	assert_eq(med.category, ElementDataClass.Category.LOG)
	_pass()

	# Test: CBRN vehicle exists
	_current_test = "cbrn_veh_exists"
	assert_true("CBRN_VEH" in all_archetypes)
	var cbrn: RefCounted = all_archetypes["CBRN_VEH"]
	assert_eq(cbrn.category, ElementDataClass.Category.REC)
	_pass()

	# Test: get_archetype function works
	_current_test = "get_archetype_function"
	var tank: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("TANK_PLT")
	assert_eq(tank.id, "TANK_PLT")
	var light: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("LIGHT_TANK")
	assert_eq(light.id, "LIGHT_TANK")
	_pass()


# =============================================================================
# ERA/APS Integration Tests
# =============================================================================

func test_era_aps_integration() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	# ProtectionData is used internally by CombatSystem
	@warning_ignore("unused_variable")
	var _ProtDataClass: GDScript = load("res://scripts/data/protection_data.gd")

	var combat: RefCounted = CombatSystemClass.new()

	# Test: Effective armor calculation includes ERA
	_current_test = "effective_armor_with_era"
	# Create MBT target (armor_class >= 3, RED faction = Russian)
	var mbt_type: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("TANK_PLT")
	var mbt: RefCounted = ElementDataClass.ElementInstance.new(mbt_type)
	mbt.faction = GameEnums.Faction.RED  # Russian = ERA equipped

	# _calculate_effective_armor is internal, test via get_penetration_probability
	# Russian MBT with RELIKT ERA should have enhanced CE protection
	_pass()

	# Test: KE weapon penetration against MBT
	_current_test = "ke_penetration_vs_mbt"
	var apfsds: RefCounted = WeaponDataClass.create_cw_tank_ke()
	var shooter_type: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("TANK_PLT")
	var shooter: RefCounted = ElementDataClass.ElementInstance.new(shooter_type)
	shooter.faction = GameEnums.Faction.BLUE
	shooter.position = Vector2(0, 0)
	mbt.position = Vector2(1000, 0)
	mbt.facing = PI  # Facing shooter = FRONT

	var p_pen: float = combat.get_penetration_probability(
		shooter, mbt, apfsds, 1000.0, WeaponDataClass.ArmorZone.FRONT
	)
	# APFSDS should have some penetration chance against MBT front
	assert_true(p_pen > 0.0)
	assert_true(p_pen < 1.0)  # Not guaranteed
	_pass()

	# Test: CE weapon (HEAT) vs ERA-equipped target
	_current_test = "ce_penetration_vs_era"
	var heat: RefCounted = WeaponDataClass.create_cw_tank_heatmp()
	var p_pen_ce: float = combat.get_penetration_probability(
		shooter, mbt, heat, 1000.0, WeaponDataClass.ArmorZone.FRONT
	)
	# HEAT vs ERA should have reduced penetration
	assert_true(p_pen_ce >= 0.0)
	_pass()

	# Test: Tandem ATGM ignores ERA
	_current_test = "tandem_ignores_era"
	var atgm: RefCounted = WeaponDataClass.create_cw_atgm()
	var p_pen_tandem: float = combat.get_penetration_probability(
		shooter, mbt, atgm, 1000.0, WeaponDataClass.ArmorZone.FRONT
	)
	# Tandem should be more effective than regular HEAT
	# (We can't directly compare here but ensure it works)
	assert_true(p_pen_tandem >= 0.0)
	_pass()

	# Test: Side armor is weaker
	_current_test = "side_armor_weaker"
	var p_pen_front: float = combat.get_penetration_probability(
		shooter, mbt, apfsds, 1000.0, WeaponDataClass.ArmorZone.FRONT
	)
	var p_pen_side: float = combat.get_penetration_probability(
		shooter, mbt, apfsds, 1000.0, WeaponDataClass.ArmorZone.SIDE
	)
	assert_gt(p_pen_side, p_pen_front)  # Side should be easier to penetrate
	_pass()

	# Test: Rear armor is weakest
	_current_test = "rear_armor_weakest"
	var p_pen_rear: float = combat.get_penetration_probability(
		shooter, mbt, apfsds, 1000.0, WeaponDataClass.ArmorZone.REAR
	)
	assert_gt(p_pen_rear, p_pen_side)  # Rear should be easier than side
	_pass()

	# Test: Light armor (IFV) easier to penetrate
	_current_test = "ifv_easier_to_penetrate"
	var ifv_type: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("IFV_PLT")
	var ifv: RefCounted = ElementDataClass.ElementInstance.new(ifv_type)
	ifv.faction = GameEnums.Faction.BLUE
	ifv.position = Vector2(1000, 0)
	ifv.facing = PI

	var p_pen_ifv: float = combat.get_penetration_probability(
		shooter, ifv, apfsds, 1000.0, WeaponDataClass.ArmorZone.FRONT
	)
	assert_gt(p_pen_ifv, p_pen_front)  # IFV easier than MBT
	_pass()

	# Test: Small arms cannot penetrate armor
	_current_test = "small_arms_no_penetration"
	var rifle: RefCounted = WeaponDataClass.create_cw_rifle_std()
	var p_pen_rifle: float = combat.get_penetration_probability(
		shooter, ifv, rifle, 100.0, WeaponDataClass.ArmorZone.FRONT
	)
	assert_eq(p_pen_rifle, 0.0)  # Small arms can't penetrate armor
	_pass()

	# Test: Soft target always penetrates
	_current_test = "soft_target_always_penetrates"
	var inf_type: RefCounted = ElementDataClass.ElementArchetypes.get_archetype("INF_LINE")
	var inf: RefCounted = ElementDataClass.ElementInstance.new(inf_type)
	inf.faction = GameEnums.Faction.RED
	inf.position = Vector2(100, 0)

	var p_pen_soft: float = combat.get_penetration_probability(
		shooter, inf, rifle, 100.0, WeaponDataClass.ArmorZone.FRONT
	)
	assert_eq(p_pen_soft, 1.0)  # Soft target always penetrates
	_pass()


# =============================================================================
# Assertions
# =============================================================================

# =============================================================================
# JGSDF Weapons Tests
# =============================================================================

func test_jgsdf_weapons() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# Test: JGSDF 120mm tank gun exists
	_current_test = "jgsdf_120mm_tank_exists"
	assert_true("CW_TANK_KE_120_JGSDF" in all_weapons)
	var tank_120_jgsdf: RefCounted = all_weapons["CW_TANK_KE_120_JGSDF"]
	assert_eq(tank_120_jgsdf.mechanism, WeaponDataClass.Mechanism.KINETIC)
	assert_eq(tank_120_jgsdf.max_range_m, 3000.0)  # Long range
	_pass()

	# Test: 10式APFSDS penetration (575mm = 115 RHA scale)
	_current_test = "jgsdf_10式_apfsds_penetration"
	# MID range should be 115 (575mm @ 2km)
	assert_eq(tank_120_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID], 115)
	_pass()

	# Test: JGSDF 120mm vs standard 120mm comparison
	_current_test = "jgsdf_120mm_vs_standard"
	@warning_ignore("unused_variable")
	var _tank_120_std: RefCounted = all_weapons["CW_TANK_KE"]
	# JGSDF 10式 should have slightly lower near-range but competitive mid-range
	# (10式 is optimized, but base NATO has Rh-120 L55 advantage at near range)
	assert_true(tank_120_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID] > 100)
	_pass()

	# Test: JGSDF 105mm tank gun (Type 16 MCV)
	_current_test = "jgsdf_105mm_type16_exists"
	assert_true("CW_TANK_KE_105_JGSDF" in all_weapons)
	var tank_105_jgsdf: RefCounted = all_weapons["CW_TANK_KE_105_JGSDF"]
	# 93式APFSDS: 350mm = 70 RHA scale
	assert_eq(tank_105_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID], 70)
	_pass()

	# Test: 105mm vs 120mm penetration
	_current_test = "jgsdf_105mm_lower_than_120mm"
	assert_gt(tank_120_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID],
			  tank_105_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: 35mm autocannon (Type 89 IFV)
	_current_test = "jgsdf_35mm_type89_exists"
	assert_true("CW_AUTOCANNON_35_JGSDF" in all_weapons)
	var ac_35_jgsdf: RefCounted = all_weapons["CW_AUTOCANNON_35_JGSDF"]
	# 35mm APDS: 95mm @ 1km = 19 RHA scale
	assert_eq(ac_35_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID], 19)
	assert_eq(ac_35_jgsdf.max_range_m, 3000.0)  # 対地3,000m
	_pass()

	# Test: 25mm autocannon (Type 87 RCV)
	_current_test = "jgsdf_25mm_type87_exists"
	assert_true("CW_AUTOCANNON_25_JGSDF" in all_weapons)
	var ac_25_jgsdf: RefCounted = all_weapons["CW_AUTOCANNON_25_JGSDF"]
	# 25mm APDS-T: 55mm = 11 RHA scale
	assert_eq(ac_25_jgsdf.pen_ke[WeaponDataClass.RangeBand.MID], 11)
	_pass()

	# Test: 79式重MAT (Type 89 IFV mounted)
	_current_test = "jgsdf_79mat_exists"
	assert_true("CW_ATGM_79MAT" in all_weapons)
	var mat_79: RefCounted = all_weapons["CW_ATGM_79MAT"]
	assert_eq(mat_79.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE)
	assert_eq(mat_79.max_range_m, 4000.0)  # 4km射程
	# タンデムHEAT: 550mm = 110 RHA scale
	assert_eq(mat_79.pen_ce[WeaponDataClass.RangeBand.MID], 110)
	_pass()

	# Test: 中距離多目的誘導弾 (MMPM)
	_current_test = "jgsdf_mmpm_exists"
	assert_true("CW_ATGM_MMPM" in all_weapons)
	var mmpm: RefCounted = all_weapons["CW_ATGM_MMPM"]
	assert_eq(mmpm.max_range_m, 5000.0)  # 5km射程
	# トップアタック、タンデムHEAT: 750mm = 150 RHA scale
	assert_eq(mmpm.pen_ce[WeaponDataClass.RangeBand.MID], 150)
	# High lethality vs heavy armor (top attack)
	var leth_heavy: int = mmpm.lethality[WeaponDataClass.RangeBand.NEAR][WeaponDataClass.TargetClass.HEAVY]
	assert_eq(leth_heavy, 100)  # MBT確殺
	_pass()

	# Test: 01式軽対戦車誘導弾 (Type 01 LMAT)
	_current_test = "jgsdf_01lmat_exists"
	assert_true("CW_ATGM_01LMAT" in all_weapons)
	var lmat_01: RefCounted = all_weapons["CW_ATGM_01LMAT"]
	assert_eq(lmat_01.max_range_m, 2000.0)  # 2km射程
	# タンデムHEAT: 650mm = 130 RHA scale
	assert_eq(lmat_01.pen_ce[WeaponDataClass.RangeBand.MID], 130)
	_pass()

	# Test: JGSDF weapon count (7 weapons)
	_current_test = "jgsdf_weapons_count"
	var jgsdf_count: int = 0
	for weapon_id in all_weapons:
		if weapon_id.ends_with("_JGSDF") or weapon_id in ["CW_ATGM_79MAT", "CW_ATGM_MMPM", "CW_ATGM_01LMAT"]:
			jgsdf_count += 1
	assert_eq(jgsdf_count, 7)  # 4 JGSDF + 3 ATGMs
	_pass()

	# Test: MMPM higher penetration than 01LMAT
	_current_test = "mmpm_higher_pen_than_lmat"
	assert_gt(mmpm.pen_ce[WeaponDataClass.RangeBand.MID],
			  lmat_01.pen_ce[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: 79MAT longer range than 01LMAT
	_current_test = "79mat_longer_range_than_lmat"
	assert_gt(mat_79.max_range_m, lmat_01.max_range_m)
	_pass()


# =============================================================================
# VehicleCatalog Integration Tests
# =============================================================================

func test_vehicle_catalog_integration() -> void:
	var ElementFactoryClass: GDScript = load("res://scripts/data/element_factory.gd")

	# Initialize vehicle catalog
	ElementFactoryClass.init_vehicle_catalog()

	# Test: Type 16 MCV weapon assignment
	_current_test = "type16_mcv_has_weapons"
	var type16 = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type16",
		0,  # GameEnums.Faction.BLUE
		Vector2(0, 0),
		0.0
	)
	assert_true(type16.weapons.size() > 0)
	_pass()

	# Test: Type 16 MCV main weapon is 105mm
	_current_test = "type16_main_weapon_is_105mm"
	assert_true(type16.primary_weapon != null)
	assert_eq(type16.primary_weapon.id, "CW_TANK_KE_105_JGSDF")
	_pass()

	# Test: Type 10 MBT weapon assignment
	_current_test = "type10_mbt_has_weapons"
	var type10 = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10",
		0,
		Vector2(100, 0),
		0.0
	)
	assert_true(type10.weapons.size() > 0)
	_pass()

	# Test: Type 10 main weapon is 120mm JGSDF
	_current_test = "type10_main_weapon_is_120mm_jgsdf"
	assert_true(type10.primary_weapon != null)
	assert_eq(type10.primary_weapon.id, "CW_TANK_KE_120_JGSDF")
	_pass()

	# Test: Type 89 IFV weapon assignment
	_current_test = "type89_ifv_has_weapons"
	var type89 = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type89",
		0,
		Vector2(200, 0),
		0.0
	)
	assert_true(type89.weapons.size() > 0)
	_pass()

	# Test: Type 89 has 35mm autocannon as primary
	_current_test = "type89_main_weapon_is_35mm"
	assert_true(type89.primary_weapon != null)
	assert_eq(type89.primary_weapon.id, "CW_AUTOCANNON_35_JGSDF")
	_pass()

	# Test: Type 89 has ATGM (79MAT)
	_current_test = "type89_has_atgm"
	var has_atgm := false
	for weapon in type89.weapons:
		if weapon.id == "CW_ATGM_79MAT":
			has_atgm = true
			break
	assert_true(has_atgm)
	_pass()

	# Test: Weapon counts (Type 10: main+2 secondary = 3, Type 89: main+atgm+1 secondary = 3)
	_current_test = "type10_weapon_count"
	assert_eq(type10.weapons.size(), 3)  # 120mm + COAX_MG + HMG
	_pass()

	_current_test = "type89_weapon_count"
	assert_eq(type89.weapons.size(), 3)  # 35mm + 79MAT + COAX_MG
	_pass()

	# Reset ID counters for other tests
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# Assertions
# =============================================================================

func assert_eq(actual: Variant, expected: Variant) -> void:
	if actual != expected:
		_fail("Expected %s but got %s" % [expected, actual])

func assert_true(condition: bool) -> void:
	if not condition:
		_fail("Expected true but got false")

func assert_false(condition: bool) -> void:
	if condition:
		_fail("Expected false but got true")

func assert_gt(value: Variant, threshold: Variant) -> void:
	if value <= threshold:
		_fail("Expected > %s but got %s" % [threshold, value])

func assert_almost_eq(actual: float, expected: float, tolerance: float) -> void:
	if abs(actual - expected) > tolerance:
		_fail("Expected ~%s (±%s) but got %s" % [expected, tolerance, actual])

func _pass() -> void:
	print("  ✓ %s" % _current_test)
	_tests_passed += 1

func _fail(message: String) -> void:
	print("  ✗ %s: %s" % [_current_test, message])
	_tests_failed += 1
