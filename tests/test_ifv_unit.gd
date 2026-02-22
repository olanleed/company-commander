extends Node

## IFVユニットのテスト
## IFV_PLTアーキタイプ、武装、車両カタログの統合テスト

var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== IFV Unit Tests ===")
	_run_all_tests()
	_print_summary()


func _run_all_tests() -> void:
	_test_ifv_archetype_exists()
	_test_ifv_archetype_properties()
	_test_ifv_weapons_exist()
	_test_ifv_weapon_properties()
	_test_ifv_element_creation()
	_test_ifv_vehicle_catalog()
	_test_ifv_create_with_vehicle()
	_test_ifv_armor_values()


# =============================================================================
# テストケース
# =============================================================================

func _test_ifv_archetype_exists() -> void:
	var test_name := "ifv_archetype_exists"

	var archetypes := ElementData.ElementArchetypes.get_all_archetypes()
	_assert_true(archetypes.has("IFV_PLT"), name)


func _test_ifv_archetype_properties() -> void:
	var test_name := "ifv_archetype_properties"

	var ifv_type := ElementData.ElementArchetypes.get_archetype("IFV_PLT")

	_assert_eq(ifv_type.id, "IFV_PLT", test_name + ": id")
	_assert_eq(ifv_type.display_name, "IFV Platoon", test_name + ": display_name")
	_assert_eq(ifv_type.category, ElementData.Category.VEH, test_name + ": category")
	_assert_eq(ifv_type.symbol_type, ElementData.SymbolType.ARMOR_IFV, test_name + ": symbol_type")
	_assert_eq(ifv_type.armor_class, 2, test_name + ": armor_class (Medium)")
	_assert_eq(ifv_type.mobility_class, GameEnums.MobilityType.TRACKED, test_name + ": mobility_class")
	_assert_eq(ifv_type.base_strength, 4, test_name + ": base_strength")
	_assert_eq(ifv_type.max_strength, 4, test_name + ": max_strength")
	_assert_approx(ifv_type.spot_range_base, 700.0, 1.0, test_name + ": spot_range_base")
	_assert_approx(ifv_type.road_speed, 14.0, 0.1, test_name + ": road_speed")
	_assert_approx(ifv_type.cross_speed, 9.0, 0.1, test_name + ": cross_speed")


func _test_ifv_weapons_exist() -> void:
	var test_name := "ifv_weapons_exist"

	var all_weapons := WeaponData.get_all_concrete_weapons()
	_assert_true(all_weapons.has("CW_AUTOCANNON_30"), test_name + ": CW_AUTOCANNON_30")
	_assert_true(all_weapons.has("CW_ATGM"), test_name + ": CW_ATGM")


func _test_ifv_weapon_properties() -> void:
	var test_name := "ifv_weapon_properties"

	# 30mm機関砲のテスト
	var autocannon := WeaponData.create_cw_autocannon_30()
	_assert_eq(autocannon.id, "CW_AUTOCANNON_30", test_name + ": autocannon id")
	_assert_eq(autocannon.mechanism, WeaponData.Mechanism.KINETIC, test_name + ": autocannon mechanism")
	_assert_eq(autocannon.fire_model, WeaponData.FireModel.CONTINUOUS, test_name + ": autocannon fire_model")
	_assert_approx(autocannon.max_range_m, 1500.0, 1.0, test_name + ": autocannon max_range")
	_assert_eq(autocannon.threat_class, WeaponData.ThreatClass.AUTOCANNON, test_name + ": autocannon threat_class")

	# 貫徹力のテスト（Near band = 160mm RHA = 32）
	var pen_ke_near := autocannon.get_pen_ke(100.0)  # Near band
	_assert_eq(pen_ke_near, 32, test_name + ": autocannon pen_ke_near")

	# ATGMのテスト
	var atgm := WeaponData.create_cw_atgm()
	_assert_eq(atgm.id, "CW_ATGM", test_name + ": atgm id")
	_assert_eq(atgm.mechanism, WeaponData.Mechanism.SHAPED_CHARGE, test_name + ": atgm mechanism")
	_assert_eq(atgm.fire_model, WeaponData.FireModel.DISCRETE, test_name + ": atgm fire_model")
	_assert_approx(atgm.max_range_m, 3750.0, 1.0, test_name + ": atgm max_range")
	_assert_approx(atgm.min_range_m, 65.0, 1.0, test_name + ": atgm min_range")

	# ATGM貫徹力のテスト（距離による減衰なし）
	var pen_ce_near := atgm.get_pen_ce(100.0)
	var pen_ce_far := atgm.get_pen_ce(3000.0)
	_assert_eq(pen_ce_near, 180, test_name + ": atgm pen_ce_near")
	_assert_eq(pen_ce_far, 180, test_name + ": atgm pen_ce_far")


func _test_ifv_element_creation() -> void:
	var test_name := "ifv_element_creation"

	ElementFactory.reset_id_counters()
	var ifv := ElementFactory.create_element("IFV_PLT", GameEnums.Faction.BLUE, Vector2(100, 100))

	_assert_true(ifv != null, test_name + ": element created")
	_assert_eq(ifv.element_type.id, "IFV_PLT", test_name + ": element_type.id")
	_assert_eq(ifv.faction, GameEnums.Faction.BLUE, test_name + ": faction")
	_assert_eq(ifv.current_strength, 4, test_name + ": current_strength")

	# 武装が装備されているか
	_assert_true(ifv.weapons.size() >= 2, test_name + ": has weapons")

	# 武装IDを確認
	var weapon_ids: Array[String] = []
	for w in ifv.weapons:
		weapon_ids.append(w.id)

	_assert_true("CW_AUTOCANNON_30" in weapon_ids, test_name + ": has autocannon")
	_assert_true("CW_ATGM" in weapon_ids, test_name + ": has atgm")


func _test_ifv_vehicle_catalog() -> void:
	var test_name := "ifv_vehicle_catalog"

	# VehicleCatalogを初期化
	ElementFactory.init_vehicle_catalog()
	var catalog = ElementFactory.get_vehicle_catalog()

	_assert_true(catalog != null, test_name + ": catalog loaded")
	if catalog == null:
		return
	_assert_true(catalog.is_loaded(), test_name + ": catalog is_loaded")

	# 日本のIFVが存在するか
	var jpn_type89 = catalog.get_vehicle("JPN_Type89")
	_assert_true(jpn_type89 != null, test_name + ": JPN_Type89 exists")
	if jpn_type89:
		_assert_eq(jpn_type89.base_archetype, "IFV_PLT", test_name + ": JPN_Type89 archetype")
		_assert_eq(jpn_type89.mobility_class, "TRACKED", test_name + ": JPN_Type89 mobility")

	# ロシアのIFVが存在するか
	var rus_bmp3 = catalog.get_vehicle("RUS_BMP3")
	_assert_true(rus_bmp3 != null, test_name + ": RUS_BMP3 exists")
	if rus_bmp3:
		_assert_eq(rus_bmp3.base_archetype, "IFV_PLT", test_name + ": RUS_BMP3 archetype")


func _test_ifv_create_with_vehicle() -> void:
	var test_name := "ifv_create_with_vehicle"

	ElementFactory.reset_id_counters()
	ElementFactory.init_vehicle_catalog()

	# 日本の89式を作成
	var jpn_ifv := ElementFactory.create_element_with_vehicle("JPN_Type89", GameEnums.Faction.BLUE, Vector2(200, 200))

	_assert_true(jpn_ifv != null, test_name + ": JPN IFV created")
	_assert_eq(jpn_ifv.vehicle_id, "JPN_Type89", test_name + ": vehicle_id")
	_assert_eq(jpn_ifv.element_type.id, "IFV_PLT", test_name + ": element_type is IFV_PLT")

	# ロシアのBMP-3を作成
	var rus_ifv := ElementFactory.create_element_with_vehicle("RUS_BMP3", GameEnums.Faction.RED, Vector2(300, 300))

	_assert_true(rus_ifv != null, test_name + ": RUS IFV created")
	_assert_eq(rus_ifv.vehicle_id, "RUS_BMP3", test_name + ": vehicle_id")
	_assert_eq(rus_ifv.element_type.id, "IFV_PLT", test_name + ": element_type is IFV_PLT")


func _test_ifv_armor_values() -> void:
	var test_name := "ifv_armor_values"

	var ifv_type := ElementData.ElementArchetypes.get_archetype("IFV_PLT")

	# KE装甲値
	_assert_true(ifv_type.armor_ke.has(WeaponData.ArmorZone.FRONT), test_name + ": has armor_ke FRONT")
	_assert_true(ifv_type.armor_ke.has(WeaponData.ArmorZone.SIDE), test_name + ": has armor_ke SIDE")
	_assert_true(ifv_type.armor_ke.has(WeaponData.ArmorZone.REAR), test_name + ": has armor_ke REAR")
	_assert_true(ifv_type.armor_ke.has(WeaponData.ArmorZone.TOP), test_name + ": has armor_ke TOP")

	# IFVは戦車より装甲が薄い
	var tank_type := ElementData.ElementArchetypes.get_archetype("TANK_PLT")
	_assert_true(ifv_type.armor_ke[WeaponData.ArmorZone.FRONT] < tank_type.armor_ke[WeaponData.ArmorZone.FRONT],
		test_name + ": IFV front armor < TANK front armor")

	# CE装甲値
	_assert_true(ifv_type.armor_ce.has(WeaponData.ArmorZone.FRONT), test_name + ": has armor_ce FRONT")

	# 具体的な値を確認
	_assert_eq(ifv_type.armor_ke[WeaponData.ArmorZone.FRONT], 30, test_name + ": armor_ke_front = 30")
	_assert_eq(ifv_type.armor_ce[WeaponData.ArmorZone.FRONT], 40, test_name + ": armor_ce_front = 40")


# =============================================================================
# アサーション
# =============================================================================

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) <= tolerance:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _print_summary() -> void:
	print("")
	for result in _test_results:
		print(result)
	print("")
	print("=== Summary: " + str(_passed) + " passed, " + str(_failed) + " failed ===")

	if _failed > 0:
		print("TESTS FAILED")
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
