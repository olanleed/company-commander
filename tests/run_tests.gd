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
		element, false, GameEnums.CommState.GOOD, true, 0.1
	)
	assert_gt(recovery, 0.0)
	_pass()

	_current_test = "suppression_no_recovery_under_fire"
	recovery = combat_system.calculate_suppression_recovery(
		element, true, GameEnums.CommState.GOOD, true, 0.1
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
	assert_almost_eq(GameConstants.K_DF_HIT, 0.25, 0.01)
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
	assert_almost_eq(vuln_dmg, 0.0, 0.01)  # Tank immune to small arms damage
	assert_almost_eq(vuln_supp, 0.1, 0.01)  # But can be suppressed slightly
	_pass()

	# Test: Hit probability calculation
	_current_test = "hit_probability_calculation"
	# p_hit = 1 - exp(-K_DF_HIT × E)
	# For E=1.0: p_hit = 1 - exp(-0.25) ≈ 0.221
	var p_hit: float = combat_system.calculate_hit_probability(1.0)
	assert_almost_eq(p_hit, 0.221, 0.01)
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
	element_type.armor_class = 2  # Heavy

	var element: RefCounted = ElementDataClass.ElementInstance.new(element_type)
	element.id = "test_tank_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 1
	element.is_moving = false

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
