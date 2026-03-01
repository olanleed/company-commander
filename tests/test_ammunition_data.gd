extends RefCounted

## 弾種システムテスト
## TDD: 先にテストを書いて、Red→Green→Refactor

class_name TestAmmunitionData

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""

func run_all_tests() -> Dictionary:
	_tests_passed = 0
	_tests_failed = 0

	print("\n[AmmunitionData Tests]")

	test_ammo_type_enum()
	test_guidance_type_enum()
	test_fuze_type_enum()
	test_ammo_profile_creation()
	test_tank_gun_ammo_profiles()
	test_autocannon_ammo_profiles()
	test_mortar_ammo_profiles()
	test_howitzer_ammo_profiles()
	test_atgm_ammo_profiles()
	test_ammo_selection_logic()

	return {"passed": _tests_passed, "failed": _tests_failed}


# =============================================================================
# AmmoType enum Tests
# =============================================================================

func test_ammo_type_enum() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: Tank gun ammo types exist
	_current_test = "tank_gun_ammo_types_exist"
	assert_true(AmmoDataClass.AmmoType.has("APFSDS_120MM"))
	assert_true(AmmoDataClass.AmmoType.has("APFSDS_125MM"))
	assert_true(AmmoDataClass.AmmoType.has("APFSDS_105MM"))
	assert_true(AmmoDataClass.AmmoType.has("HEAT_120MM"))
	assert_true(AmmoDataClass.AmmoType.has("HEAT_125MM"))
	assert_true(AmmoDataClass.AmmoType.has("HE_MP_120MM"))
	assert_true(AmmoDataClass.AmmoType.has("HE_MP_125MM"))
	_pass()

	# Test: Autocannon ammo types exist
	_current_test = "autocannon_ammo_types_exist"
	assert_true(AmmoDataClass.AmmoType.has("APDS_30MM"))
	assert_true(AmmoDataClass.AmmoType.has("APDS_25MM"))
	assert_true(AmmoDataClass.AmmoType.has("HEI_30MM"))
	assert_true(AmmoDataClass.AmmoType.has("HEI_25MM"))
	_pass()

	# Test: Mortar ammo types exist
	_current_test = "mortar_ammo_types_exist"
	assert_true(AmmoDataClass.AmmoType.has("HE_120MM_MORTAR"))
	assert_true(AmmoDataClass.AmmoType.has("HE_81MM_MORTAR"))
	assert_true(AmmoDataClass.AmmoType.has("SMOKE_81MM"))
	assert_true(AmmoDataClass.AmmoType.has("ILLUM_81MM"))
	_pass()

	# Test: Howitzer ammo types exist
	_current_test = "howitzer_ammo_types_exist"
	assert_true(AmmoDataClass.AmmoType.has("HE_155MM"))
	assert_true(AmmoDataClass.AmmoType.has("HE_152MM"))
	assert_true(AmmoDataClass.AmmoType.has("GUIDED_155MM"))
	assert_true(AmmoDataClass.AmmoType.has("GUIDED_152MM"))
	_pass()

	# Test: ATGM types exist
	_current_test = "atgm_types_exist"
	assert_true(AmmoDataClass.AmmoType.has("ATGM_TANDEM"))
	assert_true(AmmoDataClass.AmmoType.has("ATGM_TOPATTACK"))
	assert_true(AmmoDataClass.AmmoType.has("ATGM_SACLOS"))
	_pass()


# =============================================================================
# GuidanceType enum Tests
# =============================================================================

func test_guidance_type_enum() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	_current_test = "guidance_types_exist"
	assert_true(AmmoDataClass.GuidanceType.has("NONE"))
	assert_true(AmmoDataClass.GuidanceType.has("SACLOS"))
	assert_true(AmmoDataClass.GuidanceType.has("BEAM_RIDING"))
	assert_true(AmmoDataClass.GuidanceType.has("IR_HOMING"))
	assert_true(AmmoDataClass.GuidanceType.has("LASER_GUIDED"))
	assert_true(AmmoDataClass.GuidanceType.has("GPS_INS"))
	_pass()


# =============================================================================
# FuzeType enum Tests
# =============================================================================

func test_fuze_type_enum() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	_current_test = "fuze_types_exist"
	assert_true(AmmoDataClass.FuzeType.has("IMPACT"))
	assert_true(AmmoDataClass.FuzeType.has("DELAY"))
	assert_true(AmmoDataClass.FuzeType.has("PROXIMITY"))
	assert_true(AmmoDataClass.FuzeType.has("TIME"))
	_pass()


# =============================================================================
# AmmoProfile Tests
# =============================================================================

func test_ammo_profile_creation() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	_current_test = "ammo_profile_basic_creation"
	var profile: RefCounted = AmmoDataClass.AmmoProfile.new()
	profile.ammo_type = AmmoDataClass.AmmoType.APFSDS_120MM
	profile.pen_ke = 140
	profile.pen_ce = 0
	profile.lethality = 100.0
	profile.guidance = AmmoDataClass.GuidanceType.NONE
	profile.fuze = AmmoDataClass.FuzeType.IMPACT

	assert_eq(profile.ammo_type, AmmoDataClass.AmmoType.APFSDS_120MM)
	assert_eq(profile.pen_ke, 140)
	assert_eq(profile.pen_ce, 0)
	assert_almost_eq(profile.lethality, 100.0, 0.01)
	assert_eq(profile.guidance, AmmoDataClass.GuidanceType.NONE)
	assert_eq(profile.fuze, AmmoDataClass.FuzeType.IMPACT)
	_pass()

	# Test: Is KE ammo check
	_current_test = "ammo_is_ke_check"
	assert_true(profile.is_ke_round())
	assert_false(profile.is_ce_round())
	_pass()


# =============================================================================
# Tank Gun Ammo Profiles
# =============================================================================

func test_tank_gun_ammo_profiles() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: 120mm APFSDS profile
	_current_test = "apfsds_120mm_profile"
	var apfsds_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APFSDS_120MM)
	assert_eq(apfsds_120.pen_ke, 140)  # 700mm RHA @ scale 100=500mm
	assert_eq(apfsds_120.pen_ce, 0)
	assert_true(apfsds_120.is_ke_round())
	_pass()

	# Test: 125mm APFSDS profile (Russian, slightly less penetration)
	_current_test = "apfsds_125mm_profile"
	var apfsds_125: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APFSDS_125MM)
	assert_eq(apfsds_125.pen_ke, 130)  # 650mm RHA
	assert_true(apfsds_125.is_ke_round())
	_pass()

	# Test: 105mm APFSDS profile (Light tank/older systems)
	_current_test = "apfsds_105mm_profile"
	var apfsds_105: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APFSDS_105MM)
	assert_eq(apfsds_105.pen_ke, 100)  # 500mm RHA
	assert_true(apfsds_105.is_ke_round())
	_pass()

	# Test: 120mm HEAT profile
	_current_test = "heat_120mm_profile"
	var heat_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HEAT_120MM)
	assert_eq(heat_120.pen_ke, 0)
	assert_eq(heat_120.pen_ce, 90)  # 450mm RHA CE
	assert_true(heat_120.is_ce_round())
	_pass()

	# Test: HE-MP profile
	_current_test = "he_mp_120mm_profile"
	var he_mp: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_MP_120MM)
	assert_eq(he_mp.pen_ke, 0)
	assert_gt(he_mp.blast_radius, 0.0)
	_pass()


# =============================================================================
# Autocannon Ammo Profiles
# =============================================================================

func test_autocannon_ammo_profiles() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: 30mm APDS
	_current_test = "apds_30mm_profile"
	var apds_30: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APDS_30MM)
	assert_eq(apds_30.pen_ke, 32)  # 160mm RHA
	assert_true(apds_30.is_ke_round())
	_pass()

	# Test: 25mm APDS
	_current_test = "apds_25mm_profile"
	var apds_25: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.APDS_25MM)
	assert_eq(apds_25.pen_ke, 25)  # 125mm RHA
	assert_true(apds_25.is_ke_round())
	_pass()

	# Test: 30mm HEI
	_current_test = "hei_30mm_profile"
	var hei_30: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HEI_30MM)
	assert_eq(hei_30.pen_ke, 0)
	assert_gt(hei_30.lethality, 0.0)
	_pass()


# =============================================================================
# Mortar Ammo Profiles
# =============================================================================

func test_mortar_ammo_profiles() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: 120mm HE
	_current_test = "mortar_120mm_he_profile"
	var he_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_120MM_MORTAR)
	assert_gt(he_120.blast_radius, 0.0)
	assert_eq(he_120.guidance, AmmoDataClass.GuidanceType.NONE)
	_pass()

	# Test: Guided 120mm (like XM395)
	_current_test = "mortar_guided_120mm_profile"
	var guided_120: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.GUIDED_120MM_MORTAR)
	assert_eq(guided_120.guidance, AmmoDataClass.GuidanceType.GPS_INS)
	_pass()

	# Test: Smoke round
	_current_test = "mortar_smoke_profile"
	var smoke: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.SMOKE_81MM)
	assert_almost_eq(smoke.lethality, 0.0, 0.01)
	assert_gt(smoke.smoke_radius, 0.0)
	_pass()


# =============================================================================
# Howitzer Ammo Profiles
# =============================================================================

func test_howitzer_ammo_profiles() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: 155mm HE
	_current_test = "howitzer_155mm_he_profile"
	var he_155: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_155MM)
	assert_gt(he_155.blast_radius, 30.0)  # Large blast
	assert_eq(he_155.guidance, AmmoDataClass.GuidanceType.NONE)
	_pass()

	# Test: Guided 155mm (Excalibur)
	_current_test = "howitzer_guided_155mm_profile"
	var guided_155: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.GUIDED_155MM)
	assert_eq(guided_155.guidance, AmmoDataClass.GuidanceType.GPS_INS)
	_pass()

	# Test: 152mm HE (Russian)
	_current_test = "howitzer_152mm_he_profile"
	var he_152: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.HE_152MM)
	assert_gt(he_152.blast_radius, 30.0)
	_pass()


# =============================================================================
# ATGM Ammo Profiles
# =============================================================================

func test_atgm_ammo_profiles() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: Tandem HEAT ATGM (TOW, Kornet)
	_current_test = "atgm_tandem_profile"
	var tandem: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.ATGM_TANDEM)
	assert_eq(tandem.pen_ce, 180)  # 900mm RHA
	assert_true(tandem.defeats_era)  # Tandem defeats ERA
	_pass()

	# Test: Top attack ATGM (Javelin)
	_current_test = "atgm_topattack_profile"
	var topattack: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.ATGM_TOPATTACK)
	assert_eq(topattack.guidance, AmmoDataClass.GuidanceType.IR_HOMING)
	assert_true(topattack.is_top_attack)
	_pass()

	# Test: SACLOS ATGM
	_current_test = "atgm_saclos_profile"
	var saclos: RefCounted = AmmoDataClass.get_ammo_profile(AmmoDataClass.AmmoType.ATGM_SACLOS)
	assert_eq(saclos.guidance, AmmoDataClass.GuidanceType.SACLOS)
	_pass()


# =============================================================================
# Ammo Selection Logic Tests
# =============================================================================

func test_ammo_selection_logic() -> void:
	var AmmoDataClass: GDScript = load("res://scripts/data/ammunition_data.gd")

	# Test: Select best ammo for heavy armor
	_current_test = "select_ammo_vs_heavy_armor"
	var available_ammo: Array = [
		AmmoDataClass.AmmoType.APFSDS_120MM,
		AmmoDataClass.AmmoType.HEAT_120MM,
		AmmoDataClass.AmmoType.HE_MP_120MM
	]
	var best: int = AmmoDataClass.select_best_ammo_for_armor(available_ammo, 100, false)
	assert_eq(best, AmmoDataClass.AmmoType.APFSDS_120MM)  # KE vs heavy armor
	_pass()

	# Test: Select best ammo for soft target
	_current_test = "select_ammo_vs_soft"
	best = AmmoDataClass.select_best_ammo_for_soft(available_ammo)
	assert_eq(best, AmmoDataClass.AmmoType.HE_MP_120MM)  # HE-MP vs soft
	_pass()

	# Test: Select HEAT vs ERA-equipped target when tandem available
	_current_test = "select_tandem_vs_era"
	var atgm_ammo: Array = [
		AmmoDataClass.AmmoType.ATGM_TANDEM,
		AmmoDataClass.AmmoType.ATGM_SACLOS
	]
	best = AmmoDataClass.select_best_ammo_for_armor(atgm_ammo, 100, true)  # ERA equipped
	assert_eq(best, AmmoDataClass.AmmoType.ATGM_TANDEM)  # Tandem defeats ERA
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

func assert_almost_eq(actual: float, expected: float, tolerance: float) -> void:
	if abs(actual - expected) > tolerance:
		_fail("Expected ~%s (+--%s) but got %s" % [expected, tolerance, actual])

func _pass() -> void:
	print("  OK %s" % _current_test)
	_tests_passed += 1

func _fail(message: String) -> void:
	print("  NG %s: %s" % [_current_test, message])
	_tests_failed += 1
