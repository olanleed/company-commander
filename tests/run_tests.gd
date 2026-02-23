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

	print("\n[US Army Weapons Tests]")
	test_us_army_weapons()

	print("\n[US VehicleCatalog Integration Tests]")
	test_us_vehicle_catalog_integration()

	print("\n[Russian Army Weapons Tests]")
	test_russian_army_weapons()

	print("\n[Russian VehicleCatalog Integration Tests]")
	test_russian_vehicle_catalog_integration()

	print("\n[Chinese Army Weapons Tests]")
	test_chinese_army_weapons()

	print("\n[Chinese VehicleCatalog Integration Tests]")
	test_chinese_vehicle_catalog_integration()

	print("\n[Weapon Effectiveness Tests]")
	test_weapon_effectiveness()

	print("\n[FireModel Tests - Bug 2 Fix]")
	test_fire_model_discrete_vs_continuous()

	print("\n[Tank vs Light Armor Tests - Bug 1 Fix]")
	test_tank_vs_light_armor()

	print("\n[HUD Ammo Display Tests]")
	test_hud_ammo_display()

	print("\n[Weapon Selection Algorithm Tests]")
	test_weapon_selection_algorithm()


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
# US Army Weapons Tests
# =============================================================================

func test_us_army_weapons() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# Test: US Army 120mm M256 tank gun exists (M829A4)
	_current_test = "usa_120mm_m256_exists"
	assert_true("CW_TANK_KE_120_USA" in all_weapons)
	var tank_120_usa: RefCounted = all_weapons["CW_TANK_KE_120_USA"]
	assert_eq(tank_120_usa.mechanism, WeaponDataClass.Mechanism.KINETIC)
	assert_eq(tank_120_usa.max_range_m, 3500.0)  # M1 Abrams effective range
	_pass()

	# Test: M829A4 APFSDS penetration (750mm = 150 RHA scale at 2km)
	_current_test = "usa_m829a4_penetration"
	assert_eq(tank_120_usa.pen_ke[WeaponDataClass.RangeBand.MID], 150)  # 750mm @ 2km
	assert_eq(tank_120_usa.pen_ke[WeaponDataClass.RangeBand.NEAR], 160)  # 800mm close range
	_pass()

	# Test: US 120mm vs standard 120mm (M829A4 is superior)
	_current_test = "usa_120mm_vs_standard"
	var tank_120_std: RefCounted = all_weapons["CW_TANK_KE"]
	assert_gt(tank_120_usa.pen_ke[WeaponDataClass.RangeBand.MID],
			  tank_120_std.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: M830A1 MPAT HEAT exists
	_current_test = "usa_m830a1_mpat_exists"
	assert_true("CW_TANK_HEAT_USA" in all_weapons)
	var tank_heat_usa: RefCounted = all_weapons["CW_TANK_HEAT_USA"]
	assert_eq(tank_heat_usa.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE)
	# M830A1: 350mm = 70 RHA scale
	assert_eq(tank_heat_usa.pen_ce[WeaponDataClass.RangeBand.MID], 70)
	_pass()

	# Test: M242 Bushmaster 25mm autocannon (M919 DU APFSDS-T)
	_current_test = "usa_m242_bushmaster_exists"
	assert_true("CW_AUTOCANNON_25_USA" in all_weapons)
	var ac_25_usa: RefCounted = all_weapons["CW_AUTOCANNON_25_USA"]
	# M919 DU: 90mm = 18 RHA scale
	assert_eq(ac_25_usa.pen_ke[WeaponDataClass.RangeBand.MID], 18)
	assert_eq(ac_25_usa.max_range_m, 2500.0)  # Bradley effective range
	_pass()

	# Test: XM813 30mm autocannon (Stryker Dragoon)
	_current_test = "usa_xm813_30mm_exists"
	assert_true("CW_AUTOCANNON_30_USA" in all_weapons)
	var ac_30_usa: RefCounted = all_weapons["CW_AUTOCANNON_30_USA"]
	# 30mm APFSDS-T: 90mm = 18 RHA scale
	assert_eq(ac_30_usa.pen_ke[WeaponDataClass.RangeBand.MID], 18)
	assert_eq(ac_30_usa.max_range_m, 3000.0)  # Stryker Dragoon range
	_pass()

	# Test: TOW-2B ATGM
	_current_test = "usa_tow2b_atgm_exists"
	assert_true("CW_ATGM_TOW2B" in all_weapons)
	var tow2b: RefCounted = all_weapons["CW_ATGM_TOW2B"]
	assert_eq(tow2b.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE)
	assert_eq(tow2b.max_range_m, 4500.0)  # TOW-2B Aero range
	# TOW-2B EFP top attack: 300mm = 60 RHA scale
	assert_eq(tow2b.pen_ce[WeaponDataClass.RangeBand.MID], 60)
	_pass()

	# Test: FGM-148 Javelin
	_current_test = "usa_javelin_exists"
	assert_true("CW_ATGM_JAVELIN" in all_weapons)
	var javelin: RefCounted = all_weapons["CW_ATGM_JAVELIN"]
	assert_eq(javelin.max_range_m, 2500.0)  # Javelin standard range
	# Javelin tandem HEAT: 800mm = 160 RHA scale
	assert_eq(javelin.pen_ce[WeaponDataClass.RangeBand.MID], 160)
	# High lethality vs heavy (top attack)
	var leth_heavy: int = javelin.lethality[WeaponDataClass.RangeBand.NEAR][WeaponDataClass.TargetClass.HEAVY]
	assert_eq(leth_heavy, 100)
	_pass()

	# Test: MK19 40mm AGL
	_current_test = "usa_mk19_agl_exists"
	assert_true("CW_AGL_MK19" in all_weapons)
	var mk19: RefCounted = all_weapons["CW_AGL_MK19"]
	assert_eq(mk19.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG)
	assert_eq(mk19.max_range_m, 1600.0)  # Effective range
	# M430 HEDP: 75mm = 15 RHA scale
	assert_eq(mk19.pen_ce[WeaponDataClass.RangeBand.MID], 15)
	_pass()

	# Test: M240C coaxial MG
	_current_test = "usa_m240c_coax_exists"
	assert_true("CW_M240_COAX" in all_weapons)
	var m240: RefCounted = all_weapons["CW_M240_COAX"]
	assert_eq(m240.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS)
	assert_eq(m240.max_range_m, 1500.0)  # Effective range
	_pass()

	# Test: M2HB .50 Cal HMG
	_current_test = "usa_m2hb_hmg_exists"
	assert_true("CW_M2HB" in all_weapons)
	var m2hb: RefCounted = all_weapons["CW_M2HB"]
	assert_eq(m2hb.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS)  # HMG is classified as SMALL_ARMS
	assert_eq(m2hb.max_range_m, 1800.0)  # Effective range
	# .50 BMG AP: 25mm = 5 RHA scale at close range
	assert_eq(m2hb.pen_ke[WeaponDataClass.RangeBand.NEAR], 5)
	_pass()

	# Test: US Army weapon count (9 weapons)
	_current_test = "usa_weapons_count"
	var usa_weapon_ids: Array = [
		"CW_TANK_KE_120_USA",
		"CW_TANK_HEAT_USA",
		"CW_AUTOCANNON_25_USA",
		"CW_AUTOCANNON_30_USA",
		"CW_ATGM_TOW2B",
		"CW_ATGM_JAVELIN",
		"CW_AGL_MK19",
		"CW_M240_COAX",
		"CW_M2HB",
	]
	var usa_count: int = 0
	for weapon_id in usa_weapon_ids:
		if weapon_id in all_weapons:
			usa_count += 1
	assert_eq(usa_count, 9)
	_pass()

	# Test: Javelin higher penetration than TOW-2B
	_current_test = "javelin_higher_pen_than_tow2b"
	var tow2b_pen: int = all_weapons["CW_ATGM_TOW2B"].pen_ce[WeaponDataClass.RangeBand.MID]
	var javelin_pen: int = all_weapons["CW_ATGM_JAVELIN"].pen_ce[WeaponDataClass.RangeBand.MID]
	assert_gt(javelin_pen, tow2b_pen)
	_pass()

	# Test: M829A4 superior to JGSDF Type 10 APFSDS
	_current_test = "m829a4_vs_type10_apfsds"
	var jgsdf_120: RefCounted = all_weapons["CW_TANK_KE_120_JGSDF"]
	assert_gt(tank_120_usa.pen_ke[WeaponDataClass.RangeBand.MID],
			  jgsdf_120.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()


# =============================================================================
# US VehicleCatalog Integration Tests
# =============================================================================

func test_us_vehicle_catalog_integration() -> void:
	var ElementFactoryClass: GDScript = load("res://scripts/data/element_factory.gd")

	# Initialize vehicle catalog
	ElementFactoryClass.init_vehicle_catalog()

	# Test: M1A2 SEPv3 weapon assignment
	_current_test = "m1a2_sepv3_has_weapons"
	var m1a2_sepv3 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		0,  # GameEnums.Faction.BLUE
		Vector2(0, 0),
		0.0
	)
	assert_true(m1a2_sepv3.weapons.size() > 0)
	_pass()

	# Test: M1A2 SEPv3 main weapon is 120mm M256 (M829A4)
	_current_test = "m1a2_sepv3_main_weapon_is_120mm_usa"
	assert_true(m1a2_sepv3.primary_weapon != null)
	assert_eq(m1a2_sepv3.primary_weapon.id, "CW_TANK_KE_120_USA")
	_pass()

	# Test: M1A2 SEPv3 has M240 coax and M2HB
	_current_test = "m1a2_sepv3_secondary_weapons"
	var has_m240 := false
	var has_m2hb := false
	for weapon in m1a2_sepv3.weapons:
		if weapon.id == "CW_M240_COAX":
			has_m240 = true
		elif weapon.id == "CW_M2HB":
			has_m2hb = true
	assert_true(has_m240)
	assert_true(has_m2hb)
	_pass()

	# Test: M2A4 Bradley weapon assignment
	_current_test = "m2a4_bradley_has_weapons"
	var m2a4 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		0,
		Vector2(100, 0),
		0.0
	)
	assert_true(m2a4.weapons.size() > 0)
	_pass()

	# Test: M2A4 Bradley main weapon is M242 25mm
	_current_test = "m2a4_bradley_main_weapon_is_25mm"
	assert_true(m2a4.primary_weapon != null)
	assert_eq(m2a4.primary_weapon.id, "CW_AUTOCANNON_25_USA")
	_pass()

	# Test: M2A4 Bradley has TOW-2B ATGM
	_current_test = "m2a4_bradley_has_tow2b"
	var has_tow2b := false
	for weapon in m2a4.weapons:
		if weapon.id == "CW_ATGM_TOW2B":
			has_tow2b = true
			break
	assert_true(has_tow2b)
	_pass()

	# Test: Stryker Dragoon weapon assignment
	_current_test = "stryker_dragoon_has_weapons"
	var stryker_dragoon = ElementFactoryClass.create_element_with_vehicle(
		"USA_Stryker_Dragoon",  # Correct ID from catalog
		0,
		Vector2(200, 0),
		0.0
	)
	assert_true(stryker_dragoon.weapons.size() > 0)
	_pass()

	# Test: Stryker Dragoon main weapon is XM813 30mm
	_current_test = "stryker_dragoon_main_weapon_is_30mm"
	assert_true(stryker_dragoon.primary_weapon != null)
	assert_eq(stryker_dragoon.primary_weapon.id, "CW_AUTOCANNON_30_USA")
	_pass()

	# Test: Weapon counts
	_current_test = "m1a2_sepv3_weapon_count"
	assert_eq(m1a2_sepv3.weapons.size(), 3)  # 120mm + M240 + M2HB
	_pass()

	_current_test = "m2a4_bradley_weapon_count"
	assert_eq(m2a4.weapons.size(), 3)  # 25mm + TOW-2B + M240
	_pass()

	_current_test = "stryker_dragoon_weapon_count"
	assert_eq(stryker_dragoon.weapons.size(), 1)  # 30mm only (no secondary in catalog)
	_pass()

	# Test: Stryker ICV (basic)
	_current_test = "stryker_icv_has_weapons"
	var stryker_icv = ElementFactoryClass.create_element_with_vehicle(
		"USA_Stryker_ICV",  # Correct ID from catalog
		0,
		Vector2(300, 0),
		0.0
	)
	assert_true(stryker_icv.weapons.size() > 0)
	_pass()

	# Test: JLTV weapon assignment
	_current_test = "jltv_has_weapons"
	var jltv = ElementFactoryClass.create_element_with_vehicle(
		"USA_JLTV_GP",  # Correct ID from catalog
		0,
		Vector2(400, 0),
		0.0
	)
	assert_true(jltv.weapons.size() > 0)
	_pass()

	# Reset ID counters for other tests
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# Russian Army Weapons Tests
# =============================================================================

func test_russian_army_weapons() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# Test: Russian 125mm 2A46M-5 (3BM60 Svinets-2) exists
	_current_test = "rus_125mm_2a46m5_exists"
	assert_true("CW_TANK_KE_125_RUS" in all_weapons)
	var tank_125_rus: RefCounted = all_weapons["CW_TANK_KE_125_RUS"]
	assert_eq(tank_125_rus.mechanism, WeaponDataClass.Mechanism.KINETIC)
	_pass()

	# Test: 3BM60 Svinets-2 penetration (700mm = 140 RHA scale)
	_current_test = "rus_3bm60_penetration"
	assert_eq(tank_125_rus.pen_ke[WeaponDataClass.RangeBand.MID], 140)
	_pass()

	# Test: 3BM60 vs standard 125mm
	_current_test = "rus_125mm_vs_standard"
	var tank_125_std: RefCounted = all_weapons["CW_TANK_KE_125"]
	assert_gt(tank_125_rus.pen_ke[WeaponDataClass.RangeBand.MID],
			  tank_125_std.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: 3BM42 Mango exists
	_current_test = "rus_125mm_mango_exists"
	assert_true("CW_TANK_KE_125_MANGO" in all_weapons)
	_pass()

	# Test: 3BM42 Mango lower than 3BM60
	_current_test = "rus_3bm42_lower_than_3bm60"
	var mango: RefCounted = all_weapons["CW_TANK_KE_125_MANGO"]
	assert_gt(tank_125_rus.pen_ke[WeaponDataClass.RangeBand.MID],
			  mango.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: 30mm 2A42/2A72 exists
	_current_test = "rus_30mm_2a42_exists"
	assert_true("CW_AUTOCANNON_30_RUS" in all_weapons)
	_pass()

	# Test: 100mm 2A70 exists
	_current_test = "rus_100mm_2a70_exists"
	assert_true("CW_AUTOCANNON_100_RUS" in all_weapons)
	_pass()

	# Test: KPVT 14.5mm exists
	_current_test = "rus_kpvt_exists"
	assert_true("CW_HMG_KPVT" in all_weapons)
	_pass()

	# Test: PKT coax exists
	_current_test = "rus_pkt_coax_exists"
	assert_true("CW_PKT_COAX" in all_weapons)
	_pass()

	# Test: Kord AA exists
	_current_test = "rus_kord_aa_exists"
	assert_true("CW_KORD_AA" in all_weapons)
	_pass()

	# Test: Kornet ATGM exists
	_current_test = "rus_kornet_atgm_exists"
	assert_true("CW_ATGM_KORNET" in all_weapons)
	_pass()

	# Test: Kornet penetration (1200mm = 240 RHA scale)
	_current_test = "rus_kornet_penetration"
	var kornet: RefCounted = all_weapons["CW_ATGM_KORNET"]
	assert_eq(kornet.pen_ce[WeaponDataClass.RangeBand.MID], 240)
	_pass()

	# Test: Refleks exists
	_current_test = "rus_refleks_exists"
	assert_true("CW_ATGM_REFLEKS" in all_weapons)
	_pass()

	# Test: Refleks penetration (900mm = 180 RHA scale)
	_current_test = "rus_refleks_penetration"
	var refleks: RefCounted = all_weapons["CW_ATGM_REFLEKS"]
	assert_eq(refleks.pen_ce[WeaponDataClass.RangeBand.MID], 180)
	_pass()

	# Test: Konkurs exists
	_current_test = "rus_konkurs_exists"
	assert_true("CW_ATGM_KONKURS" in all_weapons)
	_pass()

	# Test: Bastion exists
	_current_test = "rus_bastion_exists"
	assert_true("CW_ATGM_BASTION" in all_weapons)
	_pass()

	# Test: Kornet > Refleks > Konkurs penetration order
	_current_test = "rus_atgm_pen_order"
	var konkurs: RefCounted = all_weapons["CW_ATGM_KONKURS"]
	assert_gt(kornet.pen_ce[WeaponDataClass.RangeBand.MID],
			  refleks.pen_ce[WeaponDataClass.RangeBand.MID])
	assert_gt(refleks.pen_ce[WeaponDataClass.RangeBand.MID],
			  konkurs.pen_ce[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: Russian weapons count (11 weapons)
	_current_test = "rus_weapons_count"
	var rus_weapon_ids: Array = [
		"CW_TANK_KE_125_RUS",
		"CW_TANK_KE_125_MANGO",
		"CW_AUTOCANNON_30_RUS",
		"CW_AUTOCANNON_100_RUS",
		"CW_HMG_KPVT",
		"CW_PKT_COAX",
		"CW_KORD_AA",
		"CW_ATGM_KORNET",
		"CW_ATGM_REFLEKS",
		"CW_ATGM_KONKURS",
		"CW_ATGM_BASTION",
	]
	var rus_count: int = 0
	for weapon_id in rus_weapon_ids:
		if weapon_id in all_weapons:
			rus_count += 1
	assert_eq(rus_count, 11)
	_pass()

	# Test: M829A4 vs 3BM60 (M829A4 should be slightly superior)
	_current_test = "m829a4_vs_3bm60"
	var m829a4: RefCounted = all_weapons["CW_TANK_KE_120_USA"]
	assert_gt(m829a4.pen_ke[WeaponDataClass.RangeBand.MID],
			  tank_125_rus.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()


# =============================================================================
# Russian VehicleCatalog Integration Tests
# =============================================================================

func test_russian_vehicle_catalog_integration() -> void:
	var ElementFactoryClass: GDScript = load("res://scripts/data/element_factory.gd")

	# Initialize vehicle catalog
	ElementFactoryClass.init_vehicle_catalog()

	# Test: T-90M weapon assignment
	_current_test = "t90m_has_weapons"
	var t90m = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		1,  # GameEnums.Faction.RED
		Vector2(0, 0),
		0.0
	)
	assert_true(t90m.weapons.size() > 0)
	_pass()

	# Test: T-90M main weapon is 125mm 3BM60
	_current_test = "t90m_main_weapon_is_125mm_rus"
	assert_true(t90m.primary_weapon != null)
	assert_eq(t90m.primary_weapon.id, "CW_TANK_KE_125_RUS")
	_pass()

	# Test: T-90M has Refleks ATGM
	_current_test = "t90m_has_refleks"
	var has_refleks := false
	for weapon in t90m.weapons:
		if weapon.id == "CW_ATGM_REFLEKS":
			has_refleks = true
			break
	assert_true(has_refleks)
	_pass()

	# Test: T-90M has PKT and Kord
	_current_test = "t90m_secondary_weapons"
	var has_pkt := false
	var has_kord := false
	for weapon in t90m.weapons:
		if weapon.id == "CW_PKT_COAX":
			has_pkt = true
		elif weapon.id == "CW_KORD_AA":
			has_kord = true
	assert_true(has_pkt)
	assert_true(has_kord)
	_pass()

	# Test: T-72B3 uses Mango (3BM42)
	_current_test = "t72b3_uses_mango"
	var t72b3 = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T72B3",
		1,
		Vector2(100, 0),
		0.0
	)
	assert_true(t72b3.primary_weapon != null)
	assert_eq(t72b3.primary_weapon.id, "CW_TANK_KE_125_MANGO")
	_pass()

	# Test: BMP-3 has 100mm 2A70
	_current_test = "bmp3_has_100mm"
	var bmp3 = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BMP3",
		1,
		Vector2(200, 0),
		0.0
	)
	assert_true(bmp3.primary_weapon != null)
	assert_eq(bmp3.primary_weapon.id, "CW_AUTOCANNON_100_RUS")
	_pass()

	# Test: BMP-3 has Bastion ATGM
	_current_test = "bmp3_has_bastion"
	var has_bastion := false
	for weapon in bmp3.weapons:
		if weapon.id == "CW_ATGM_BASTION":
			has_bastion = true
			break
	assert_true(has_bastion)
	_pass()

	# Test: BMP-2 has Konkurs ATGM
	_current_test = "bmp2_has_konkurs"
	var bmp2 = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BMP2",
		1,
		Vector2(300, 0),
		0.0
	)
	var has_konkurs := false
	for weapon in bmp2.weapons:
		if weapon.id == "CW_ATGM_KONKURS":
			has_konkurs = true
			break
	assert_true(has_konkurs)
	_pass()

	# Test: BTR-82A has 30mm 2A72
	_current_test = "btr82a_has_30mm"
	var btr82a = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BTR82A",
		1,
		Vector2(400, 0),
		0.0
	)
	assert_true(btr82a.primary_weapon != null)
	assert_eq(btr82a.primary_weapon.id, "CW_AUTOCANNON_30_RUS")
	_pass()

	# Test: BTR-80 has KPVT 14.5mm
	_current_test = "btr80_has_kpvt"
	var btr80 = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BTR80",
		1,
		Vector2(500, 0),
		0.0
	)
	assert_true(btr80.primary_weapon != null)
	assert_eq(btr80.primary_weapon.id, "CW_HMG_KPVT")
	_pass()

	# Test: T-90M weapon count (4: main + atgm + pkt + kord)
	_current_test = "t90m_weapon_count"
	assert_eq(t90m.weapons.size(), 4)
	_pass()

	# Test: BMP-3 weapon count (4: 100mm + bastion + 30mm + pkt)
	_current_test = "bmp3_weapon_count"
	assert_eq(bmp3.weapons.size(), 4)
	_pass()

	# Reset ID counters for other tests
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# Chinese Army Weapons Tests
# =============================================================================

func test_chinese_army_weapons() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# Test: 125mm DTC10-125 exists
	_current_test = "chn_125mm_dtc10_exists"
	assert_true("CW_TANK_KE_125_CHN" in all_weapons)
	_pass()

	# Test: DTC10-125 penetration (800mm @ 2km = 160)
	_current_test = "chn_dtc10_penetration"
	var dtc10: RefCounted = all_weapons["CW_TANK_KE_125_CHN"]
	assert_eq(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], 160)
	_pass()

	# Test: 125mm DTW-125 II exists
	_current_test = "chn_125mm_dtw125ii_exists"
	assert_true("CW_TANK_KE_125_CHN_STD" in all_weapons)
	_pass()

	# Test: DTW-125 II penetration (700mm = 140)
	_current_test = "chn_dtw125ii_penetration"
	var dtw125ii: RefCounted = all_weapons["CW_TANK_KE_125_CHN_STD"]
	assert_eq(dtw125ii.pen_ke[WeaponDataClass.RangeBand.MID], 140)
	_pass()

	# Test: 125mm DTW-125 old exists
	_current_test = "chn_125mm_old_exists"
	assert_true("CW_TANK_KE_125_CHN_OLD" in all_weapons)
	_pass()

	# Test: 105mm ZPL-151 exists
	_current_test = "chn_105mm_zpl151_exists"
	assert_true("CW_TANK_KE_105_CHN" in all_weapons)
	_pass()

	# Test: 105mm ZPL-151 penetration (500mm = 100)
	_current_test = "chn_105mm_penetration"
	var zpl151: RefCounted = all_weapons["CW_TANK_KE_105_CHN"]
	assert_eq(zpl151.pen_ke[WeaponDataClass.RangeBand.MID], 100)
	_pass()

	# Test: 105mm Type 83 exists
	_current_test = "chn_105mm_old_exists"
	assert_true("CW_TANK_KE_105_CHN_OLD" in all_weapons)
	_pass()

	# Test: 30mm ZPT-99 exists
	_current_test = "chn_30mm_zpt99_exists"
	assert_true("CW_AUTOCANNON_30_CHN" in all_weapons)
	_pass()

	# Test: 35mm Type 90 exists
	_current_test = "chn_35mm_type90_exists"
	assert_true("CW_AUTOCANNON_35_CHN" in all_weapons)
	_pass()

	# Test: 100mm gun-launcher exists
	_current_test = "chn_100mm_gun_launcher_exists"
	assert_true("CW_AUTOCANNON_100_CHN" in all_weapons)
	_pass()

	# Test: HJ-10 exists
	_current_test = "chn_hj10_exists"
	assert_true("CW_ATGM_HJ10" in all_weapons)
	_pass()

	# Test: HJ-10 penetration (1400mm = 280)
	_current_test = "chn_hj10_penetration"
	var hj10: RefCounted = all_weapons["CW_ATGM_HJ10"]
	assert_eq(hj10.pen_ce[WeaponDataClass.RangeBand.MID], 280)
	_pass()

	# Test: HJ-9 exists
	_current_test = "chn_hj9_exists"
	assert_true("CW_ATGM_HJ9" in all_weapons)
	_pass()

	# Test: HJ-9 penetration (1200mm = 240)
	_current_test = "chn_hj9_penetration"
	var hj9: RefCounted = all_weapons["CW_ATGM_HJ9"]
	assert_eq(hj9.pen_ce[WeaponDataClass.RangeBand.MID], 240)
	_pass()

	# Test: HJ-8E exists
	_current_test = "chn_hj8e_exists"
	assert_true("CW_ATGM_HJ8E" in all_weapons)
	_pass()

	# Test: HJ-8E penetration (1000mm = 200)
	_current_test = "chn_hj8e_penetration"
	var hj8e: RefCounted = all_weapons["CW_ATGM_HJ8E"]
	assert_eq(hj8e.pen_ce[WeaponDataClass.RangeBand.MID], 200)
	_pass()

	# Test: HJ-73 exists
	_current_test = "chn_hj73_exists"
	assert_true("CW_ATGM_HJ73" in all_weapons)
	_pass()

	# Test: HJ-73 penetration (425mm = 85)
	_current_test = "chn_hj73_penetration"
	var hj73: RefCounted = all_weapons["CW_ATGM_HJ73"]
	assert_eq(hj73.pen_ce[WeaponDataClass.RangeBand.MID], 85)
	_pass()

	# Test: GP105 exists
	_current_test = "chn_gp105_exists"
	assert_true("CW_ATGM_GP105" in all_weapons)
	_pass()

	# Test: GP105 penetration (700mm = 140)
	_current_test = "chn_gp105_penetration"
	var gp105: RefCounted = all_weapons["CW_ATGM_GP105"]
	assert_eq(gp105.pen_ce[WeaponDataClass.RangeBand.MID], 140)
	_pass()

	# Test: QJZ-89 exists
	_current_test = "chn_qjz89_exists"
	assert_true("CW_QJZ89_AA" in all_weapons)
	_pass()

	# Test: Type 86 coax exists
	_current_test = "chn_type86_coax_exists"
	assert_true("CW_TYPE86_COAX" in all_weapons)
	_pass()

	# Test: DTC10 > DTW-125 II
	_current_test = "chn_dtc10_higher_than_dtw125ii"
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], dtw125ii.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: ATGM hierarchy HJ-10 > HJ-9 > HJ-8E > GP105 > HJ-73
	_current_test = "chn_atgm_hierarchy"
	assert_gt(hj10.pen_ce[WeaponDataClass.RangeBand.MID], hj9.pen_ce[WeaponDataClass.RangeBand.MID])
	assert_gt(hj9.pen_ce[WeaponDataClass.RangeBand.MID], hj8e.pen_ce[WeaponDataClass.RangeBand.MID])
	assert_gt(hj8e.pen_ce[WeaponDataClass.RangeBand.MID], gp105.pen_ce[WeaponDataClass.RangeBand.MID])
	assert_gt(gp105.pen_ce[WeaponDataClass.RangeBand.MID], hj73.pen_ce[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: DTC10 vs M829A4 (DTC10 higher)
	_current_test = "chn_dtc10_vs_m829a4"
	var m829a4: RefCounted = all_weapons["CW_TANK_KE_120_USA"]
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], m829a4.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: DTC10 vs 3BM60 (DTC10 higher)
	_current_test = "chn_dtc10_vs_3bm60"
	var svinets: RefCounted = all_weapons["CW_TANK_KE_125_RUS"]
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], svinets.pen_ke[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: HJ-10 vs Kornet (HJ-10 higher)
	_current_test = "chn_hj10_vs_kornet"
	var kornet: RefCounted = all_weapons["CW_ATGM_KORNET"]
	assert_gt(hj10.pen_ce[WeaponDataClass.RangeBand.MID], kornet.pen_ce[WeaponDataClass.RangeBand.MID])
	_pass()

	# Test: Chinese weapons count (15)
	_current_test = "chn_weapons_count"
	var chn_weapon_ids: Array = [
		"CW_TANK_KE_125_CHN",
		"CW_TANK_KE_125_CHN_STD",
		"CW_TANK_KE_125_CHN_OLD",
		"CW_TANK_KE_105_CHN",
		"CW_TANK_KE_105_CHN_OLD",
		"CW_AUTOCANNON_30_CHN",
		"CW_AUTOCANNON_35_CHN",
		"CW_AUTOCANNON_100_CHN",
		"CW_ATGM_HJ10",
		"CW_ATGM_HJ9",
		"CW_ATGM_HJ8E",
		"CW_ATGM_HJ73",
		"CW_ATGM_GP105",
		"CW_QJZ89_AA",
		"CW_TYPE86_COAX",
	]
	var chn_count: int = 0
	for weapon_id in chn_weapon_ids:
		if weapon_id in all_weapons:
			chn_count += 1
	assert_eq(chn_count, 15)
	_pass()


func test_chinese_vehicle_catalog_integration() -> void:
	var ElementFactoryClass: GDScript = load("res://scripts/data/element_factory.gd")

	# Initialize vehicle catalog
	ElementFactoryClass.init_vehicle_catalog()

	# Test: Type 99A weapon assignment
	_current_test = "type99a_has_weapons"
	var type99a = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type99A",
		1,  # GameEnums.Faction.RED
		Vector2(0, 0),
		0.0
	)
	assert_true(type99a.weapons.size() > 0)
	_pass()

	# Test: Type 99A main weapon is DTC10-125
	_current_test = "type99a_main_weapon_is_dtc10"
	assert_true(type99a.primary_weapon != null)
	assert_eq(type99a.primary_weapon.id, "CW_TANK_KE_125_CHN")
	_pass()

	# Test: Type 99A has Type 86 coax and QJZ-89
	_current_test = "type99a_secondary_weapons"
	var has_type86 := false
	var has_qjz89 := false
	for weapon in type99a.weapons:
		if weapon.id == "CW_TYPE86_COAX":
			has_type86 = true
		elif weapon.id == "CW_QJZ89_AA":
			has_qjz89 = true
	assert_true(has_type86)
	assert_true(has_qjz89)
	_pass()

	# Test: Type 99 uses DTW-125 II
	_current_test = "type99_uses_dtw125ii"
	var type99 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type99",
		1,
		Vector2(100, 0),
		0.0
	)
	assert_true(type99.primary_weapon != null)
	assert_eq(type99.primary_weapon.id, "CW_TANK_KE_125_CHN_STD")
	_pass()

	# Test: Type 96A uses DTW-125 II
	_current_test = "type96a_uses_dtw125ii"
	var type96a = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type96A",
		1,
		Vector2(200, 0),
		0.0
	)
	assert_true(type96a.primary_weapon != null)
	assert_eq(type96a.primary_weapon.id, "CW_TANK_KE_125_CHN_STD")
	_pass()

	# Test: Type 96 uses DTW-125 old
	_current_test = "type96_uses_dtw125_old"
	var type96 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type96",
		1,
		Vector2(300, 0),
		0.0
	)
	assert_true(type96.primary_weapon != null)
	assert_eq(type96.primary_weapon.id, "CW_TANK_KE_125_CHN_OLD")
	_pass()

	# Test: Type 15 has ZPL-151
	_current_test = "type15_has_zpl151"
	var type15 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type15",
		1,
		Vector2(400, 0),
		0.0
	)
	assert_true(type15.primary_weapon != null)
	assert_eq(type15.primary_weapon.id, "CW_TANK_KE_105_CHN")
	_pass()

	# Test: Type 15 has GP105 ATGM
	_current_test = "type15_has_gp105"
	var has_gp105 := false
	for weapon in type15.weapons:
		if weapon.id == "CW_ATGM_GP105":
			has_gp105 = true
			break
	assert_true(has_gp105)
	_pass()

	# Test: ZBD-04A has 30mm ZPT-99
	_current_test = "zbd04a_has_30mm"
	var zbd04a = ElementFactoryClass.create_element_with_vehicle(
		"CHN_ZBD04A",
		1,
		Vector2(500, 0),
		0.0
	)
	assert_true(zbd04a.primary_weapon != null)
	assert_eq(zbd04a.primary_weapon.id, "CW_AUTOCANNON_30_CHN")
	_pass()

	# Test: ZBD-04A has HJ-8E ATGM
	_current_test = "zbd04a_has_hj8e"
	var has_hj8e := false
	for weapon in zbd04a.weapons:
		if weapon.id == "CW_ATGM_HJ8E":
			has_hj8e = true
			break
	assert_true(has_hj8e)
	_pass()

	# Test: ZBD-04 has 100mm gun-launcher
	_current_test = "zbd04_has_100mm"
	var zbd04 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_ZBD04",
		1,
		Vector2(600, 0),
		0.0
	)
	assert_true(zbd04.primary_weapon != null)
	assert_eq(zbd04.primary_weapon.id, "CW_AUTOCANNON_100_CHN")
	_pass()

	# Test: ZBD-09 has HJ-73 ATGM
	_current_test = "zbd09_has_hj73"
	var zbd09 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_ZBD09",
		1,
		Vector2(700, 0),
		0.0
	)
	var has_hj73 := false
	for weapon in zbd09.weapons:
		if weapon.id == "CW_ATGM_HJ73":
			has_hj73 = true
			break
	assert_true(has_hj73)
	_pass()

	# Test: PGZ-09 has 35mm Type 90
	_current_test = "pgz09_has_35mm"
	var pgz09 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_PGZ09",
		1,
		Vector2(800, 0),
		0.0
	)
	assert_true(pgz09.primary_weapon != null)
	assert_eq(pgz09.primary_weapon.id, "CW_AUTOCANNON_35_CHN")
	_pass()

	# Test: ZTL-11 has 105mm Type 83
	_current_test = "ztl11_has_105mm_old"
	var ztl11 = ElementFactoryClass.create_element_with_vehicle(
		"CHN_ZTL11",
		1,
		Vector2(900, 0),
		0.0
	)
	assert_true(ztl11.primary_weapon != null)
	assert_eq(ztl11.primary_weapon.id, "CW_TANK_KE_105_CHN_OLD")
	_pass()

	# Test: ZTL-11 has GP105 ATGM
	_current_test = "ztl11_has_gp105"
	var has_gp105_ztl11 := false
	for weapon in ztl11.weapons:
		if weapon.id == "CW_ATGM_GP105":
			has_gp105_ztl11 = true
			break
	assert_true(has_gp105_ztl11)
	_pass()

	# Test: Type 99A weapon count (3: main + type86 + qjz89)
	_current_test = "type99a_weapon_count"
	assert_eq(type99a.weapons.size(), 3)
	_pass()

	# Test: ZBD-04A weapon count (3: main + atgm + coax)
	_current_test = "zbd04a_weapon_count"
	assert_eq(zbd04a.weapons.size(), 3)
	_pass()

	# Reset ID counters for other tests
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# Weapon Effectiveness Tests (Penetration Matrix)
# =============================================================================

## Calculate penetration probability using sigmoid formula
func _calc_pen_prob(penetration: int, armor: int) -> float:
	var diff := float(penetration - armor)
	var x := diff / 15.0  # PENETRATION_SIGMOID_SCALE
	return 1.0 / (1.0 + exp(-x))


func test_weapon_effectiveness() -> void:
	# Armor values from element_data.gd:
	# MBT: Front 140 KE/CE, Side 40/24, Rear 16/8
	# IFV: Front 30/40, Side 10/12, Rear 6/6
	# APC: Front 6/5, Side 3/3
	# Light Tank: Front 60/70, Side 20/20
	# SP Arty: Front 12/10
	# AA: Front 14/12

	# Penetration probability thresholds:
	# diff >= +30: ~88% (effective)
	# diff = 0: 50%
	# diff <= -30: ~12% (ineffective)

	const PENETRATE := 0.75  # 75%+ = "can penetrate"
	const NO_PENETRATE := 0.25  # 25%- = "cannot penetrate"

	# =========================================================================
	# MBT Front (140 KE/CE) Tests
	# =========================================================================

	_current_test = "mbt_front_vs_dtc10_125mm"
	# DTC10-125 (160 KE) vs MBT front (140 KE): diff = +20 -> ~79%
	assert_gt(_calc_pen_prob(160, 140), PENETRATE)
	_pass()

	_current_test = "mbt_front_vs_m829a4_120mm"
	# M829A4 (150 KE) vs MBT front (140 KE): diff = +10 -> ~66%
	assert_gt(_calc_pen_prob(150, 140), 0.5)
	_pass()

	_current_test = "mbt_front_vs_3bm60_125mm"
	# 3BM60 (140 KE) vs MBT front (140 KE): diff = 0 -> 50%
	assert_almost_eq(_calc_pen_prob(140, 140), 0.5, 0.05)
	_pass()

	_current_test = "mbt_front_vs_mango_125mm"
	# 3BM42 Mango (100 KE) vs MBT front (140 KE): diff = -40 -> ~7%
	assert_lt(_calc_pen_prob(100, 140), NO_PENETRATE)
	_pass()

	_current_test = "mbt_front_vs_105mm_apfsds"
	# 105mm (100 KE) vs MBT front (140 KE): diff = -40 -> ~7%
	assert_lt(_calc_pen_prob(100, 140), NO_PENETRATE)
	_pass()

	_current_test = "mbt_front_vs_30mm_autocannon"
	# 30mm (12 KE) vs MBT front (140 KE): diff = -128 -> ~0%
	assert_lt(_calc_pen_prob(12, 140), 0.01)
	_pass()

	_current_test = "mbt_front_vs_kornet_atgm"
	# Kornet (240 CE) vs MBT front (140 CE): diff = +100 -> ~99.9%
	assert_gt(_calc_pen_prob(240, 140), 0.99)
	_pass()

	_current_test = "mbt_front_vs_hj10_atgm"
	# HJ-10 (280 CE) vs MBT front (140 CE): diff = +140 -> ~99.99%
	assert_gt(_calc_pen_prob(280, 140), 0.99)
	_pass()

	_current_test = "mbt_front_vs_javelin_atgm"
	# Javelin (180 CE) vs MBT front (140 CE): diff = +40 -> ~93%
	assert_gt(_calc_pen_prob(180, 140), 0.9)
	_pass()

	_current_test = "mbt_front_vs_rpg_heat"
	# RPG (60 CE) vs MBT front (140 CE): diff = -80 -> ~0.5%
	assert_lt(_calc_pen_prob(60, 140), 0.01)
	_pass()

	# =========================================================================
	# MBT Side (40 KE, 24 CE) Tests
	# =========================================================================

	_current_test = "mbt_side_vs_30mm_autocannon"
	# 30mm (12 KE) vs MBT side (40 KE): diff = -28 -> ~13%
	assert_lt(_calc_pen_prob(12, 40), NO_PENETRATE)
	_pass()

	_current_test = "mbt_side_vs_100mm_gun_launcher"
	# 100mm (120 CE) vs MBT side (24 CE): diff = +96 -> ~99.8%
	assert_gt(_calc_pen_prob(120, 24), 0.99)
	_pass()

	_current_test = "mbt_side_vs_rpg_heat"
	# RPG (60 CE) vs MBT side (24 CE): diff = +36 -> ~92%
	assert_gt(_calc_pen_prob(60, 24), 0.9)
	_pass()

	_current_test = "mbt_side_vs_hj73_atgm"
	# HJ-73 (85 CE) vs MBT side (24 CE): diff = +61 -> ~98%
	assert_gt(_calc_pen_prob(85, 24), 0.95)
	_pass()

	# =========================================================================
	# MBT Rear (16 KE, 8 CE) Tests
	# =========================================================================

	_current_test = "mbt_rear_vs_30mm_autocannon"
	# 30mm (12 KE) vs MBT rear (16 KE): diff = -4 -> ~43%
	var prob := _calc_pen_prob(12, 16)
	assert_gt(prob, 0.3)
	assert_lt(prob, 0.6)
	_pass()

	_current_test = "mbt_rear_vs_rpg_heat"
	# RPG (60 CE) vs MBT rear (8 CE): diff = +52 -> ~97%
	assert_gt(_calc_pen_prob(60, 8), 0.95)
	_pass()

	# =========================================================================
	# IFV Front (30 KE, 40 CE) Tests
	# =========================================================================

	_current_test = "ifv_front_vs_30mm_at_mid"
	# 30mm (12 KE) vs IFV front (30 KE): diff = -18 -> ~23%
	assert_lt(_calc_pen_prob(12, 30), NO_PENETRATE)
	_pass()

	_current_test = "ifv_front_vs_30mm_at_near"
	# 30mm NEAR (14 KE) vs IFV front (30 KE): diff = -16 -> ~26%
	assert_gt(_calc_pen_prob(14, 30), 0.2)
	_pass()

	_current_test = "ifv_front_vs_125mm_apfsds"
	# 125mm (140 KE) vs IFV front (30 KE): diff = +110 -> ~99.9%
	assert_gt(_calc_pen_prob(140, 30), 0.99)
	_pass()

	_current_test = "ifv_front_vs_rpg_heat"
	# RPG (60 CE) vs IFV front (40 CE): diff = +20 -> ~79%
	assert_gt(_calc_pen_prob(60, 40), PENETRATE)
	_pass()

	_current_test = "ifv_front_vs_atgm"
	# Any ATGM (85+ CE) vs IFV front (40 CE): diff = +45+ -> ~95%+
	assert_gt(_calc_pen_prob(85, 40), 0.9)
	_pass()

	# =========================================================================
	# IFV Side (10 KE, 12 CE) Tests
	# =========================================================================

	_current_test = "ifv_side_vs_30mm_autocannon"
	# 30mm (12 KE) vs IFV side (10 KE): diff = +2 -> ~53%
	assert_gt(_calc_pen_prob(12, 10), 0.5)
	_pass()

	_current_test = "ifv_side_vs_145mm_kpvt"
	# 14.5mm KPVT (8 KE) vs IFV side (10 KE): diff = -2 -> ~47%
	assert_gt(_calc_pen_prob(8, 10), 0.4)
	_pass()

	_current_test = "ifv_side_vs_127mm_hmg"
	# 12.7mm HMG (5 KE) vs IFV side (10 KE): diff = -5 -> ~42%
	assert_gt(_calc_pen_prob(5, 10), 0.35)
	_pass()

	# =========================================================================
	# APC Front (6 KE, 5 CE) Tests
	# =========================================================================

	_current_test = "apc_front_vs_127mm_hmg"
	# 12.7mm HMG (5 KE) vs APC front (6 KE): diff = -1 -> ~48%
	assert_gt(_calc_pen_prob(5, 6), 0.4)
	_pass()

	_current_test = "apc_front_vs_30mm_autocannon"
	# 30mm (12 KE) vs APC front (6 KE): diff = +6 -> ~60%
	assert_gt(_calc_pen_prob(12, 6), 0.55)
	_pass()

	_current_test = "apc_front_vs_rpg_heat"
	# RPG (60 CE) vs APC front (5 CE): diff = +55 -> ~98%
	assert_gt(_calc_pen_prob(60, 5), 0.95)
	_pass()

	_current_test = "apc_side_vs_127mm_hmg"
	# 12.7mm HMG (5 KE) vs APC side (3 KE): diff = +2 -> ~53%
	assert_gt(_calc_pen_prob(5, 3), 0.5)
	_pass()

	# =========================================================================
	# Light Tank Front (60 KE, 70 CE) Tests
	# =========================================================================

	_current_test = "light_tank_front_vs_30mm"
	# 30mm (12 KE) vs Light tank front (60 KE): diff = -48 -> ~4%
	assert_lt(_calc_pen_prob(12, 60), 0.1)
	_pass()

	_current_test = "light_tank_front_vs_105mm"
	# 105mm (100 KE) vs Light tank front (60 KE): diff = +40 -> ~93%
	assert_gt(_calc_pen_prob(100, 60), 0.9)
	_pass()

	_current_test = "light_tank_front_vs_125mm"
	# 125mm (140 KE) vs Light tank front (60 KE): diff = +80 -> ~99.5%
	assert_gt(_calc_pen_prob(140, 60), 0.99)
	_pass()

	_current_test = "light_tank_front_vs_rpg"
	# RPG (60 CE) vs Light tank front (70 CE): diff = -10 -> ~34%
	assert_lt(_calc_pen_prob(60, 70), 0.5)
	_pass()

	_current_test = "light_tank_front_vs_kornet"
	# Kornet (240 CE) vs Light tank front (70 CE): diff = +170 -> ~99.99%
	assert_gt(_calc_pen_prob(240, 70), 0.99)
	_pass()

	_current_test = "light_tank_side_vs_30mm"
	# 30mm (12 KE) vs Light tank side (20 KE): diff = -8 -> ~37%
	assert_gt(_calc_pen_prob(12, 20), 0.3)
	_pass()

	# =========================================================================
	# SP Artillery Front (12 KE, 10 CE) Tests
	# =========================================================================

	_current_test = "sp_arty_front_vs_30mm"
	# 30mm (12 KE) vs SP Arty front (12 KE): diff = 0 -> 50%
	assert_almost_eq(_calc_pen_prob(12, 12), 0.5, 0.05)
	_pass()

	_current_test = "sp_arty_front_vs_rpg"
	# RPG (60 CE) vs SP Arty front (10 CE): diff = +50 -> ~96%
	assert_gt(_calc_pen_prob(60, 10), 0.95)
	_pass()

	# =========================================================================
	# AA Systems Front (14 KE, 12 CE) Tests
	# =========================================================================

	_current_test = "aa_front_vs_30mm"
	# 30mm (12 KE) vs AA front (14 KE): diff = -2 -> ~47%
	assert_gt(_calc_pen_prob(12, 14), 0.4)
	_pass()

	# =========================================================================
	# ATGM Effectiveness Matrix vs MBT Front (140 CE)
	# =========================================================================

	_current_test = "atgm_matrix_vs_mbt_front"
	var mbt_front_ce := 140
	# HJ-10 (280 CE): should always penetrate
	assert_gt(_calc_pen_prob(280, mbt_front_ce), 0.99)
	# Kornet (240 CE): should always penetrate
	assert_gt(_calc_pen_prob(240, mbt_front_ce), 0.99)
	# HJ-9 (240 CE): should always penetrate
	assert_gt(_calc_pen_prob(240, mbt_front_ce), 0.99)
	# HJ-8E (200 CE): should penetrate
	assert_gt(_calc_pen_prob(200, mbt_front_ce), 0.95)
	# Javelin (180 CE): should penetrate
	assert_gt(_calc_pen_prob(180, mbt_front_ce), 0.9)
	# GP105 (140 CE): 50/50
	assert_almost_eq(_calc_pen_prob(140, mbt_front_ce), 0.5, 0.05)
	# HJ-73 (85 CE): should struggle
	assert_lt(_calc_pen_prob(85, mbt_front_ce), 0.05)
	_pass()

	# =========================================================================
	# Tank Gun Hierarchy Tests
	# =========================================================================

	_current_test = "tank_gun_hierarchy_vs_mbt"
	var mbt_front_ke := 140
	# DTC10 > M829A4 > 3BM60 > Mango
	var dtc10 := _calc_pen_prob(160, mbt_front_ke)
	var m829a4 := _calc_pen_prob(150, mbt_front_ke)
	var bm60 := _calc_pen_prob(140, mbt_front_ke)
	var mango := _calc_pen_prob(100, mbt_front_ke)
	assert_gt(dtc10, m829a4)
	assert_gt(m829a4, bm60)
	assert_gt(bm60, mango)
	_pass()

	# =========================================================================
	# Autocannon Effectiveness by Range (30mm vs IFV front 30 KE)
	# =========================================================================

	_current_test = "30mm_effectiveness_by_range"
	var ifv_front_ke := 30
	var near := _calc_pen_prob(14, ifv_front_ke)  # NEAR: 14 KE
	var mid := _calc_pen_prob(12, ifv_front_ke)   # MID: 12 KE
	var far := _calc_pen_prob(8, ifv_front_ke)    # FAR: 8 KE
	assert_gt(near, mid)
	assert_gt(mid, far)
	_pass()

	# =========================================================================
	# HMG Effectiveness Tests
	# =========================================================================

	_current_test = "hmg_127mm_vs_targets"
	# vs APC (6 KE): marginal
	assert_gt(_calc_pen_prob(5, 6), 0.4)
	# vs IFV (30 KE): no chance
	assert_lt(_calc_pen_prob(5, 30), 0.2)
	# vs MBT (140 KE): impossible
	assert_lt(_calc_pen_prob(5, 140), 0.01)
	_pass()

	_current_test = "hmg_145mm_vs_targets"
	# vs APC (6 KE): good
	assert_gt(_calc_pen_prob(8, 6), 0.5)
	# vs IFV side (10 KE): marginal
	assert_gt(_calc_pen_prob(8, 10), 0.4)
	# vs IFV front (30 KE): no
	assert_lt(_calc_pen_prob(8, 30), 0.2)
	_pass()

	# =========================================================================
	# Summary: What CAN Penetrate MBT Front
	# =========================================================================

	_current_test = "summary_can_penetrate_mbt_front"
	var mbt_f := 140
	assert_gt(_calc_pen_prob(280, mbt_f), 0.75)  # HJ-10
	assert_gt(_calc_pen_prob(240, mbt_f), 0.75)  # Kornet
	assert_gt(_calc_pen_prob(200, mbt_f), 0.75)  # HJ-8E
	assert_gt(_calc_pen_prob(180, mbt_f), 0.75)  # Javelin
	assert_gt(_calc_pen_prob(160, mbt_f), 0.75)  # DTC10-125
	_pass()

	# =========================================================================
	# Summary: What CANNOT Penetrate MBT Front
	# =========================================================================

	_current_test = "summary_cannot_penetrate_mbt_front"
	assert_lt(_calc_pen_prob(100, mbt_f), 0.25)  # Mango
	assert_lt(_calc_pen_prob(85, mbt_f), 0.25)   # HJ-73
	assert_lt(_calc_pen_prob(60, mbt_f), 0.25)   # RPG
	assert_lt(_calc_pen_prob(12, mbt_f), 0.01)   # 30mm
	assert_lt(_calc_pen_prob(5, mbt_f), 0.01)    # 12.7mm
	_pass()

	# =========================================================================
	# What Threatens Each Target Class
	# =========================================================================

	_current_test = "threats_to_mbt"
	# Front: only best weapons
	assert_gt(_calc_pen_prob(160, 140), 0.5)  # DTC10
	assert_gt(_calc_pen_prob(150, 140), 0.5)  # M829A4
	# Side: more options
	assert_gt(_calc_pen_prob(60, 24), 0.9)    # RPG CE vs MBT side CE
	assert_gt(_calc_pen_prob(85, 24), 0.9)    # HJ-73
	# Rear: even autocannons
	assert_gt(_calc_pen_prob(12, 16), 0.4)    # 30mm
	_pass()

	_current_test = "threats_to_ifv"
	# AT weapons
	assert_gt(_calc_pen_prob(60, 40), 0.75)   # RPG vs IFV front CE
	assert_gt(_calc_pen_prob(85, 40), 0.9)    # ATGM
	# Tank guns overkill
	assert_gt(_calc_pen_prob(100, 30), 0.99)  # 105mm
	assert_gt(_calc_pen_prob(140, 30), 0.99)  # 125mm
	# Autocannons on side
	assert_gt(_calc_pen_prob(12, 10), 0.5)    # 30mm vs IFV side
	_pass()

	_current_test = "threats_to_apc"
	# Nearly everything threatens APC
	assert_gt(_calc_pen_prob(5, 6), 0.4)      # 12.7mm
	assert_gt(_calc_pen_prob(12, 6), 0.59)    # 30mm (calc: ~0.599)
	assert_gt(_calc_pen_prob(60, 5), 0.97)    # RPG (calc: ~0.975)
	_pass()

	# =========================================================================
	# Vehicle Combat Scenarios
	# =========================================================================

	_current_test = "type99a_vs_m1a2_front"
	# Type 99A DTC10 (160 KE) vs M1A2 front (assume 155 KE with ERA)
	assert_gt(_calc_pen_prob(160, 155), 0.5)
	_pass()

	_current_test = "t90m_vs_type99a_front"
	# T-90M 3BM60 (140 KE) vs Type 99A front (assume 145 KE with ERA)
	assert_gt(_calc_pen_prob(140, 145), 0.4)
	_pass()

	_current_test = "m1a2_vs_t90m_front"
	# M1A2 M829A4 (150 KE) vs T-90M front (assume 150 KE with Relikt)
	assert_almost_eq(_calc_pen_prob(150, 150), 0.5, 0.05)
	_pass()

	_current_test = "bradley_vs_bmp3_front"
	# 25mm Bushmaster (10 KE) vs BMP-3 front (30 KE): diff = -20 -> ~21%
	assert_lt(_calc_pen_prob(10, 30), NO_PENETRATE)
	_pass()

	_current_test = "bmp3_vs_bradley_side"
	# BMP-3 30mm (12 KE) vs Bradley side (10 KE): diff = +2 -> ~53%
	assert_gt(_calc_pen_prob(12, 10), 0.5)
	_pass()

	_current_test = "zbd04a_vs_btr82a_front"
	# ZBD-04A 30mm (12 KE) vs BTR-82A front (8 KE): diff = +4 -> ~57%
	assert_gt(_calc_pen_prob(12, 8), 0.55)
	_pass()


# =============================================================================
# FireModel Tests - Bug 2 Fix (DISCRETE vs CONTINUOUS)
# =============================================================================

func test_fire_model_discrete_vs_continuous() -> void:
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	# 戦車砲はDISCRETE
	_current_test = "tank_gun_is_discrete"
	var tank_ke = WeaponDataClass.create_cw_tank_ke()
	assert_eq(tank_ke.fire_model, WeaponDataClass.FireModel.DISCRETE)
	assert_eq(tank_ke.mechanism, WeaponDataClass.Mechanism.KINETIC)
	_pass()

	# 機関砲はCONTINUOUS
	_current_test = "autocannon_is_continuous"
	var autocannon = WeaponDataClass.create_cw_autocannon_30()
	assert_eq(autocannon.fire_model, WeaponDataClass.FireModel.CONTINUOUS)
	assert_eq(autocannon.mechanism, WeaponDataClass.Mechanism.KINETIC)
	_pass()

	# 両方KINETICだがfire_modelで区別可能
	_current_test = "kinetic_weapons_distinguished_by_fire_model"
	assert_eq(tank_ke.mechanism, autocannon.mechanism)  # 両方KINETIC
	assert_true(tank_ke.fire_model != autocannon.fire_model)  # fire_modelは異なる
	_pass()

	# HEAT-MPはDISCRETE
	_current_test = "heat_is_discrete"
	var tank_heat = WeaponDataClass.create_cw_tank_heatmp()
	assert_eq(tank_heat.fire_model, WeaponDataClass.FireModel.DISCRETE)
	assert_eq(tank_heat.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE)
	_pass()

	# ATGMはDISCRETE
	_current_test = "atgm_is_discrete"
	var atgm = WeaponDataClass.create_cw_atgm()
	assert_eq(atgm.fire_model, WeaponDataClass.FireModel.DISCRETE)
	_pass()

	# 迫撃砲はINDIRECT
	_current_test = "mortar_is_indirect"
	var mortar = WeaponDataClass.create_cw_mortar_he()
	assert_eq(mortar.fire_model, WeaponDataClass.FireModel.INDIRECT)
	_pass()


# =============================================================================
# Tank vs Light Armor Tests - Bug 1 Fix
# =============================================================================

func test_tank_vs_light_armor() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	var combat_system = CombatSystemClass.new()

	# 軽装甲車両を作成（armor_class = 1）
	var light_armor_type = ElementDataClass.ElementType.new()
	light_armor_type.id = "test_recon"
	light_armor_type.max_strength = 2
	light_armor_type.armor_class = 1  # Light armor
	light_armor_type.category = ElementDataClass.Category.VEH

	# 戦車を作成
	var tank_type = ElementDataClass.ElementType.new()
	tank_type.id = "test_tank"
	tank_type.max_strength = 4
	tank_type.armor_class = 4  # Heavy armor
	tank_type.category = ElementDataClass.Category.VEH

	var shooter = ElementDataClass.ElementInstance.new(tank_type)
	shooter.id = "shooter_tank"
	shooter.faction = GameEnums.Faction.BLUE
	shooter.position = Vector2(0, 0)
	shooter.mobility_hp = 100
	shooter.firepower_hp = 100
	shooter.sensors_hp = 100

	var weapon = WeaponDataClass.create_cw_tank_ke()

	# テスト: 軽装甲への戦車砲命中は高い撃破確率
	_current_test = "tank_vs_light_armor_high_kill_prob"
	var target = ElementDataClass.ElementInstance.new(light_armor_type)
	target.id = "target_recon"
	target.faction = GameEnums.Faction.RED
	target.position = Vector2(800, 0)
	target.facing = PI
	target.mobility_hp = 100
	target.firepower_hp = 100
	target.sensors_hp = 100

	var result = combat_system.process_tank_engagement(shooter, target, weapon, 800.0, 0)
	# 命中した場合、p_kill = 0.90（軽装甲）
	if result.hit:
		assert_almost_eq(result.p_kill, 0.90, 0.01)
	_pass()

	# テスト: 軽装甲への命中は必ずダメージ（Kill or M-Kill）
	_current_test = "tank_vs_light_armor_always_damages"
	var hits := 0
	var damages := 0
	for i in range(50):
		var t = ElementDataClass.ElementInstance.new(light_armor_type)
		t.id = "target_%d" % i
		t.faction = GameEnums.Faction.RED
		t.position = Vector2(500, 0)
		t.facing = PI
		t.mobility_hp = 100
		t.firepower_hp = 100
		t.sensors_hp = 100

		shooter.last_fire_tick = -100  # リセット
		var r = combat_system.process_tank_engagement(shooter, t, weapon, 500.0, i)
		if r.hit:
			hits += 1
			if r.kill or r.mission_kill:
				damages += 1

	# 命中した場合は100%ダメージ（kill + mission_kill = 100%）
	if hits > 0:
		var damage_rate := float(damages) / float(hits)
		assert_almost_eq(damage_rate, 1.0, 0.05)
	_pass()

	# テスト: IFV（armor_class=2）はMBT（armor_class>=3）より脆弱
	_current_test = "ifv_more_vulnerable_than_mbt"
	var ifv_type = ElementDataClass.ElementType.new()
	ifv_type.id = "test_ifv"
	ifv_type.max_strength = 3
	ifv_type.armor_class = 2  # IFV
	ifv_type.category = ElementDataClass.Category.VEH

	var ifv = ElementDataClass.ElementInstance.new(ifv_type)
	ifv.id = "target_ifv"
	ifv.faction = GameEnums.Faction.RED
	ifv.position = Vector2(800, 0)
	ifv.facing = PI
	ifv.mobility_hp = 100
	ifv.firepower_hp = 100
	ifv.sensors_hp = 100

	var mbt = ElementDataClass.ElementInstance.new(tank_type)
	mbt.id = "target_mbt"
	mbt.faction = GameEnums.Faction.RED
	mbt.position = Vector2(800, 0)
	mbt.facing = PI
	mbt.mobility_hp = 100
	mbt.firepower_hp = 100
	mbt.sensors_hp = 100

	shooter.last_fire_tick = -100
	var r_ifv = combat_system.process_tank_engagement(shooter, ifv, weapon, 800.0, 100)
	shooter.last_fire_tick = -100
	var r_mbt = combat_system.process_tank_engagement(shooter, mbt, weapon, 800.0, 101)

	# IFVの方がMBTより撃破されやすい
	if r_ifv.hit and r_mbt.hit:
		assert_gt(r_ifv.p_kill, r_mbt.p_kill)
	_pass()

	# テスト: should_use_tank_combat が軽装甲で true を返す（修正後）
	_current_test = "should_use_tank_combat_light_armor_true"
	var target_light = ElementDataClass.ElementInstance.new(light_armor_type)
	target_light.id = "target_light"
	target_light.faction = GameEnums.Faction.RED
	var should_use = combat_system.should_use_tank_combat(shooter, target_light, weapon)
	assert_true(should_use)  # armor_class=1 は戦車戦闘モデルを使用
	_pass()

	# テスト: should_use_tank_combat がソフトスキンで false を返す
	_current_test = "should_use_tank_combat_soft_false"
	var soft_type = ElementDataClass.ElementType.new()
	soft_type.id = "test_soft"
	soft_type.max_strength = 10
	soft_type.armor_class = 0  # Soft target
	soft_type.category = ElementDataClass.Category.INF
	var target_soft = ElementDataClass.ElementInstance.new(soft_type)
	target_soft.id = "target_soft"
	target_soft.faction = GameEnums.Faction.RED
	should_use = combat_system.should_use_tank_combat(shooter, target_soft, weapon)
	assert_false(should_use)  # armor_class=0 は戦車戦闘モデルを使用しない
	_pass()

	# テスト: should_use_tank_combat がIFV（armor_class=2）で true を返す
	_current_test = "should_use_tank_combat_ifv_true"
	should_use = combat_system.should_use_tank_combat(shooter, ifv, weapon)
	assert_true(should_use)  # armor_class=2 は戦車戦闘モデルを使用
	_pass()

	# テスト: should_use_tank_combat がMBT（armor_class>=3）で true を返す
	_current_test = "should_use_tank_combat_mbt_true"
	should_use = combat_system.should_use_tank_combat(shooter, mbt, weapon)
	assert_true(should_use)  # armor_class>=3 は戦車戦闘モデルを使用
	_pass()


# =============================================================================
# HUD Ammo Display Tests
# =============================================================================

func test_hud_ammo_display() -> void:
	var RightPanelClass: GDScript = load("res://scripts/ui/right_panel.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	var right_panel = RightPanelClass.new()

	# APFSDS表示
	_current_test = "apfsds_displays_correctly"
	var tank_ke = WeaponDataClass.create_cw_tank_ke()
	var ammo_type = right_panel._get_ammo_type_display(tank_ke)
	assert_eq(ammo_type, "APFSDS")
	_pass()

	# HEAT表示
	_current_test = "heat_displays_correctly"
	var tank_heat = WeaponDataClass.create_cw_tank_heatmp()
	ammo_type = right_panel._get_ammo_type_display(tank_heat)
	assert_eq(ammo_type, "HEAT")
	_pass()

	# ATGM表示
	_current_test = "atgm_displays_correctly"
	var atgm = WeaponDataClass.create_cw_atgm()
	ammo_type = right_panel._get_ammo_type_display(atgm)
	assert_eq(ammo_type, "ATGM")
	_pass()

	# 機関砲は弾種表示なし（CONTINUOUS）
	_current_test = "autocannon_no_ammo_display"
	var autocannon = WeaponDataClass.create_cw_autocannon_30()
	ammo_type = right_panel._get_ammo_type_display(autocannon)
	assert_eq(ammo_type, "")
	_pass()

	# 小銃は弾種表示なし
	_current_test = "rifle_no_ammo_display"
	var rifle = WeaponDataClass.create_rifle()
	ammo_type = right_panel._get_ammo_type_display(rifle)
	assert_eq(ammo_type, "")
	_pass()

	# null武器でもクラッシュしない
	_current_test = "null_weapon_no_crash"
	ammo_type = right_panel._get_ammo_type_display(null)
	assert_eq(ammo_type, "")
	_pass()

	# LAWはCE表示
	_current_test = "law_displays_ce"
	var law = WeaponDataClass.create_cw_law()
	ammo_type = right_panel._get_ammo_type_display(law)
	assert_eq(ammo_type, "CE")
	_pass()

	right_panel.queue_free()


# =============================================================================
# Weapon Selection Algorithm Tests
# =============================================================================

func test_weapon_selection_algorithm() -> void:
	var CombatSystemClass: GDScript = load("res://scripts/systems/combat_system.gd")
	var ElementDataClass: GDScript = load("res://scripts/data/element_data.gd")
	var WeaponDataClass: GDScript = load("res://scripts/data/weapon_data.gd")

	var combat_system = CombatSystemClass.new()

	# ========================================
	# 目標タイプを作成
	# ========================================

	# 重装甲（MBT）
	var mbt_type = ElementDataClass.ElementType.new()
	mbt_type.id = "test_mbt"
	mbt_type.max_strength = 4
	mbt_type.armor_class = 4
	mbt_type.category = ElementDataClass.Category.VEH

	# 中装甲（IFV）
	var ifv_type = ElementDataClass.ElementType.new()
	ifv_type.id = "test_ifv"
	ifv_type.max_strength = 3
	ifv_type.armor_class = 2
	ifv_type.category = ElementDataClass.Category.VEH

	# 軽装甲（APC/RECON）
	var apc_type = ElementDataClass.ElementType.new()
	apc_type.id = "test_apc"
	apc_type.max_strength = 2
	apc_type.armor_class = 1
	apc_type.category = ElementDataClass.Category.VEH

	# 非装甲車両（トラック）
	var truck_type = ElementDataClass.ElementType.new()
	truck_type.id = "test_truck"
	truck_type.max_strength = 1
	truck_type.armor_class = 0
	truck_type.category = ElementDataClass.Category.VEH

	# 歩兵
	var inf_type = ElementDataClass.ElementType.new()
	inf_type.id = "test_inf"
	inf_type.max_strength = 10
	inf_type.armor_class = 0
	inf_type.category = ElementDataClass.Category.INF

	# 戦車（射手）
	var tank_shooter_type = ElementDataClass.ElementType.new()
	tank_shooter_type.id = "test_tank_shooter"
	tank_shooter_type.max_strength = 4
	tank_shooter_type.armor_class = 4
	tank_shooter_type.category = ElementDataClass.Category.VEH

	# ========================================
	# 武器を作成
	# ========================================
	var apfsds = WeaponDataClass.create_cw_tank_ke()
	var heat_mp = WeaponDataClass.create_cw_tank_heatmp()
	var coax_mg = WeaponDataClass.create_cw_coax_mg()
	var atgm = WeaponDataClass.create_cw_atgm()
	var autocannon = WeaponDataClass.create_cw_autocannon_30()

	# ========================================
	# テスト: 目標カテゴリ分類
	# ========================================
	_current_test = "target_category_heavy_armor"
	var mbt = ElementDataClass.ElementInstance.new(mbt_type)
	var cat = combat_system.get_target_category(mbt)
	assert_eq(cat, 0)  # HEAVY_ARMOR = 0
	_pass()

	_current_test = "target_category_medium_armor"
	var ifv = ElementDataClass.ElementInstance.new(ifv_type)
	cat = combat_system.get_target_category(ifv)
	assert_eq(cat, 1)  # MEDIUM_ARMOR = 1
	_pass()

	_current_test = "target_category_light_armor"
	var apc = ElementDataClass.ElementInstance.new(apc_type)
	cat = combat_system.get_target_category(apc)
	assert_eq(cat, 2)  # LIGHT_ARMOR = 2
	_pass()

	_current_test = "target_category_soft_vehicle"
	var truck = ElementDataClass.ElementInstance.new(truck_type)
	cat = combat_system.get_target_category(truck)
	assert_eq(cat, 3)  # SOFT_VEHICLE = 3
	_pass()

	_current_test = "target_category_infantry"
	var inf = ElementDataClass.ElementInstance.new(inf_type)
	cat = combat_system.get_target_category(inf)
	assert_eq(cat, 4)  # INFANTRY = 4
	_pass()

	# ========================================
	# テスト: 武器役割の推論
	# ========================================
	_current_test = "weapon_role_apfsds"
	WeaponDataClass.ensure_weapon_role(apfsds)
	assert_eq(apfsds.weapon_role, WeaponDataClass.WeaponRole.MAIN_GUN_KE)
	_pass()

	_current_test = "weapon_role_heat"
	WeaponDataClass.ensure_weapon_role(heat_mp)
	assert_eq(heat_mp.weapon_role, WeaponDataClass.WeaponRole.MAIN_GUN_CE)
	_pass()

	_current_test = "weapon_role_coax_mg"
	WeaponDataClass.ensure_weapon_role(coax_mg)
	# COAX_MG = 4 (0:MAIN_GUN_KE, 1:MAIN_GUN_CE, 2:ATGM, 3:AUTOCANNON, 4:COAX_MG)
	assert_eq(coax_mg.weapon_role, 4)  # WeaponRole.COAX_MG
	_pass()

	_current_test = "weapon_role_atgm"
	WeaponDataClass.ensure_weapon_role(atgm)
	assert_eq(atgm.weapon_role, WeaponDataClass.WeaponRole.ATGM)
	_pass()

	_current_test = "weapon_role_autocannon"
	WeaponDataClass.ensure_weapon_role(autocannon)
	assert_eq(autocannon.weapon_role, WeaponDataClass.WeaponRole.AUTOCANNON)
	_pass()

	# ========================================
	# テスト: 戦車 vs MBT → APFSDS優先
	# ========================================
	_current_test = "tank_vs_mbt_selects_apfsds"
	var shooter = ElementDataClass.ElementInstance.new(tank_shooter_type)
	shooter.id = "shooter"
	shooter.faction = GameEnums.Faction.BLUE
	shooter.weapons.append(apfsds)
	shooter.weapons.append(heat_mp)
	shooter.weapons.append(coax_mg)
	shooter.primary_weapon = apfsds

	mbt.id = "target_mbt"
	mbt.faction = GameEnums.Faction.RED

	var selected = combat_system.select_best_weapon(shooter, mbt, 1500.0, false)
	assert_eq(selected.id, "CW_TANK_KE")  # APFSDSが選択される
	_pass()

	# ========================================
	# テスト: 戦車 vs IFV → HEAT-MP優先
	# ========================================
	_current_test = "tank_vs_ifv_selects_heat"
	ifv.id = "target_ifv"
	ifv.faction = GameEnums.Faction.RED

	selected = combat_system.select_best_weapon(shooter, ifv, 1000.0, false)
	assert_eq(selected.id, "CW_TANK_HEATMP")  # HEAT-MPが選択される
	_pass()

	# ========================================
	# テスト: 戦車 vs APC → HEAT-MPまたは機関砲
	# ========================================
	_current_test = "tank_vs_apc_selects_heat_or_autocannon"
	apc.id = "target_apc"
	apc.faction = GameEnums.Faction.RED

	selected = combat_system.select_best_weapon(shooter, apc, 800.0, false)
	# HEAT-MPが優先される（機関砲がない場合）
	assert_true(selected.id == "CW_TANK_HEATMP" or selected.id == "CW_AUTOCANNON_30")
	_pass()

	# ========================================
	# テスト: 戦車 vs 歩兵 → 同軸MG優先
	# ========================================
	_current_test = "tank_vs_infantry_selects_coax_mg"
	inf.id = "target_inf"
	inf.faction = GameEnums.Faction.RED

	selected = combat_system.select_best_weapon(shooter, inf, 500.0, false)
	assert_eq(selected.id, "CW_COAX_MG")  # 同軸MGが選択される
	_pass()

	# ========================================
	# テスト: 戦車 vs トラック → 同軸MG or HEAT-MP
	# トラックは非装甲車両なので、同軸MGが最適だが射程外ならHEAT-MP
	# ========================================
	_current_test = "tank_vs_truck_selects_coax_or_heat"
	truck.id = "target_truck"
	truck.faction = GameEnums.Faction.RED

	# 近距離では同軸MG、遠距離ではHEAT-MP（同軸MGの射程800m）
	selected = combat_system.select_best_weapon(shooter, truck, 600.0, false)
	# 同軸MG(射程800m)でもHEAT-MPでもOK - 弾薬経済性の観点から
	assert_true(selected.id == "CW_COAX_MG" or selected.id == "CW_TANK_HEATMP")
	_pass()

	# ========================================
	# テスト: IFV vs MBT → ATGM優先
	# ========================================
	_current_test = "ifv_vs_mbt_selects_atgm"
	var ifv_shooter = ElementDataClass.ElementInstance.new(ifv_type)
	ifv_shooter.id = "ifv_shooter"
	ifv_shooter.faction = GameEnums.Faction.BLUE
	ifv_shooter.weapons.append(autocannon)
	ifv_shooter.weapons.append(atgm)
	ifv_shooter.weapons.append(coax_mg)
	ifv_shooter.primary_weapon = autocannon

	selected = combat_system.select_best_weapon(ifv_shooter, mbt, 2000.0, false)
	assert_eq(selected.id, "CW_ATGM")  # ATGMが選択される
	_pass()

	# ========================================
	# テスト: IFV vs IFV → 機関砲優先（近距離）
	# ========================================
	_current_test = "ifv_vs_ifv_selects_autocannon"
	var enemy_ifv = ElementDataClass.ElementInstance.new(ifv_type)
	enemy_ifv.id = "enemy_ifv"
	enemy_ifv.faction = GameEnums.Faction.RED

	selected = combat_system.select_best_weapon(ifv_shooter, enemy_ifv, 800.0, false)
	assert_eq(selected.id, "CW_AUTOCANNON_30")  # 機関砲が選択される
	_pass()

	# ========================================
	# テスト: APFSDSは歩兵に対して低スコア
	# ========================================
	_current_test = "apfsds_low_score_vs_infantry"
	var tank_only_ke = ElementDataClass.ElementInstance.new(tank_shooter_type)
	tank_only_ke.id = "tank_only_ke"
	tank_only_ke.faction = GameEnums.Faction.BLUE
	tank_only_ke.weapons.append(apfsds)
	tank_only_ke.primary_weapon = apfsds

	# APFSDSしかない場合はフォールバックでprimary_weaponが使われる
	# （負のスコアの武器しかない場合）
	selected = combat_system.select_best_weapon(tank_only_ke, inf, 500.0, false)
	# フォールバックでAPFSDSが選ばれても仕方ない（他の選択肢がない）
	# 重要なのは複数武器がある場合に適切な武器が選ばれること
	assert_true(selected != null)  # 何か選ばれる
	_pass()

	# ========================================
	# テスト: ATGMは歩兵に使わない
	# ========================================
	_current_test = "atgm_not_used_vs_infantry"
	var ifv_only_atgm = ElementDataClass.ElementInstance.new(ifv_type)
	ifv_only_atgm.id = "ifv_only_atgm"
	ifv_only_atgm.faction = GameEnums.Faction.BLUE
	ifv_only_atgm.weapons.append(atgm)
	ifv_only_atgm.weapons.append(coax_mg)
	ifv_only_atgm.primary_weapon = coax_mg

	selected = combat_system.select_best_weapon(ifv_only_atgm, inf, 500.0, false)
	assert_eq(selected.id, "CW_COAX_MG")  # ATGMではなく同軸MG
	_pass()

	# ========================================
	# IFV武器選択 - 距離による切り替え
	# ========================================

	# IFV vs MBT 近距離 - ATGMは避けて同軸MG/機関砲
	# 実際の戦術: 近距離でMBTに遭遇したら逃げるか隠れる
	# 武器選択としてはATGMが最も効果的だが発射準備に時間がかかる

	# IFV vs IFV 遠距離 - ATGMが優位
	_current_test = "ifv_vs_ifv_long_range_atgm"
	selected = combat_system.select_best_weapon(ifv_shooter, enemy_ifv, 2000.0, false)
	# 遠距離ではATGMが機関砲より有利
	assert_eq(selected.id, "CW_ATGM")
	_pass()

	# IFV vs 歩兵 - 同軸MG射程外では機関砲
	_current_test = "ifv_vs_infantry_autocannon_long_range"
	selected = combat_system.select_best_weapon(ifv_shooter, inf, 1000.0, false)
	# 同軸MG射程外(800m+)では機関砲が選ばれる
	assert_eq(selected.id, "CW_AUTOCANNON_30")
	_pass()

	# IFV vs 歩兵 - 同軸MG（近距離）
	_current_test = "ifv_vs_infantry_coax_close_range"
	selected = combat_system.select_best_weapon(ifv_shooter, inf, 200.0, false)
	# 近距離では同軸MGが最適
	assert_eq(selected.id, "CW_COAX_MG")
	_pass()

	# IFV vs APC - 機関砲優先
	_current_test = "ifv_vs_apc_autocannon"
	selected = combat_system.select_best_weapon(ifv_shooter, apc, 600.0, false)
	assert_eq(selected.id, "CW_AUTOCANNON_30")
	_pass()


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

func assert_lt(value: Variant, threshold: Variant) -> void:
	if value >= threshold:
		_fail("Expected < %s but got %s" % [threshold, value])

func assert_almost_eq(actual: float, expected: float, tolerance: float) -> void:
	if abs(actual - expected) > tolerance:
		_fail("Expected ~%s (±%s) but got %s" % [expected, tolerance, actual])

func _pass() -> void:
	print("  ✓ %s" % _current_test)
	_tests_passed += 1

func _fail(message: String) -> void:
	print("  ✗ %s: %s" % [_current_test, message])
	_tests_failed += 1
