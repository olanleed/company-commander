extends GutTest

## 米陸軍武器システムのテスト
## docs/weapons_tree/us_army_weapons_2026.md 準拠

var WeaponDataClass: GDScript
var VehicleCatalogClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")


# =============================================================================
# 米軍戦車砲テスト
# =============================================================================

func test_usa_120mm_m256_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_120_USA", "120mm M256 (M829A4) should exist")


func test_usa_m829a4_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	# M829A4: 750mm RHA @ 2km → pen_ke = 150
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 150, "M829A4 should have pen_ke 150 at MID (750mm)")


func test_usa_120mm_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "M829A4 should be KINETIC mechanism")


func test_usa_120mm_fire_model() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "Tank gun should be DISCRETE fire model")


# =============================================================================
# 米軍機関砲テスト
# =============================================================================

func test_usa_25mm_m242_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_25_USA", "25mm M242 Bushmaster should exist")


func test_usa_25mm_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_USA"]
	# M242: 約60mm RHA → pen_ke = 12
	assert_gt(weapon.pen_ke[WeaponDataClass.RangeBand.NEAR], 0, "25mm should have KE penetration")


func test_usa_30mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	# CW_AUTOCANNON_30_USA または CW_AUTOCANNON_30X173_USA のいずれかが存在することを確認
	var has_30mm = weapons.has("CW_AUTOCANNON_30_USA") or weapons.has("CW_AUTOCANNON_30X173_USA")
	assert_true(has_30mm, "30mm autocannon should exist")


func test_usa_30mm_higher_than_25mm() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var m242 = weapons["CW_AUTOCANNON_25_USA"]
	# 利用可能な30mm武器を使用
	var m30_key = "CW_AUTOCANNON_30X173_USA" if weapons.has("CW_AUTOCANNON_30X173_USA") else "CW_AUTOCANNON_30_USA"
	var m30 = weapons[m30_key]
	# 30mm > 25mm penetration
	assert_gt(m30.pen_ke[WeaponDataClass.RangeBand.NEAR], m242.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"30mm should have higher penetration than 25mm")


# =============================================================================
# 米軍ATGM テスト
# =============================================================================

func test_usa_javelin_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "W_USA_ATGM_JAVELIN", "FGM-148 Javelin should exist")


func test_usa_javelin_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["W_USA_ATGM_JAVELIN"]
	# Javelin: 750mm RHA direct hit (top attack 600mm effective) → pen_ce = 150
	assert_gt(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 100, "Javelin should have significant pen_ce")


func test_usa_javelin_is_shaped_charge() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["W_USA_ATGM_JAVELIN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "Javelin should be SHAPED_CHARGE")


func test_usa_tow2b_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "W_USA_ATGM_TOW2B", "BGM-71F TOW-2B should exist")


func test_usa_tow2b_is_shaped_charge() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["W_USA_ATGM_TOW2B"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "TOW-2B should be SHAPED_CHARGE")


# =============================================================================
# 米軍機銃テスト
# =============================================================================

func test_usa_m240_coax_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_M240_COAX", "M240C coaxial should exist")


func test_usa_m2hb_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_M2HB", "M2HB .50 cal should exist")


func test_usa_m2hb_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M2HB"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "M2HB should be SMALL_ARMS mechanism")


# =============================================================================
# 米軍榴弾砲テスト（汎用155mmを使用）
# =============================================================================

func test_generic_155mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HOWITZER_155", "155mm howitzer should exist")


func test_generic_155mm_fire_model() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_155"]
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "Howitzer should be INDIRECT fire model")


# =============================================================================
# 米軍車両カタログ統合テスト
# =============================================================================

func test_m1a2sepv3_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M1A2_SEPv3")
	assert_not_null(vehicle, "M1A2 SEPv3 should exist in catalog")


func test_m1a2sepv3_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M1A2_SEPv3")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_120_USA", "M1A2 SEPv3 should use M829A4")


func test_m1a2sepv3_secondary_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M1A2_SEPv3")
	assert_not_null(vehicle.secondary_weapons, "M1A2 SEPv3 should have secondary weapons")
	assert_true(vehicle.secondary_weapons.has("CW_M240_COAX"), "M1A2 SEPv3 should have M240 coax")
	assert_true(vehicle.secondary_weapons.has("CW_M2HB"), "M1A2 SEPv3 should have M2HB")


func test_m2a4_bradley_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M2A4_Bradley")
	assert_not_null(vehicle, "M2A4 Bradley should exist")


func test_m2a4_bradley_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M2A4_Bradley")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_25_USA", "M2A4 Bradley should use M242")


func test_m2a4_bradley_has_tow() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M2A4_Bradley")
	assert_not_null(vehicle.atgm, "M2A4 Bradley should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "W_USA_ATGM_TOW2B", "M2A4 Bradley should have TOW-2B")


func test_stryker_dragoon_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_Stryker_Dragoon")
	assert_not_null(vehicle, "Stryker Dragoon should exist")


func test_stryker_dragoon_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_Stryker_Dragoon")
	# カタログでは30x173mm（XM813/MK44 Bushmaster II相当）を使用
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_30_USA", "Stryker Dragoon should use 30mm autocannon")


func test_m109a7_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M109A7_Paladin")
	assert_not_null(vehicle, "M109A7 Paladin should exist")


func test_m109a7_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M109A7_Paladin")
	# 現在の実装ではCW_HOWITZER_155（汎用）を使用
	assert_eq(vehicle.main_gun.weapon_id, "CW_HOWITZER_155", "M109A7 should use 155mm")


# =============================================================================
# 武器数カウントテスト
# =============================================================================

func test_usa_weapons_count() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var usa_weapons = 0
	for key in weapons.keys():
		if key.ends_with("_USA") or key in ["CW_M240_COAX", "CW_M2HB", "W_USA_ATGM_JAVELIN", "W_USA_ATGM_TOW2B"]:
			usa_weapons += 1
	# At least 7 US-specific weapons
	assert_true(usa_weapons >= 7, "Should have at least 7 US-specific weapons")


# =============================================================================
# 比較テスト
# =============================================================================

func test_m829a4_highest_western_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var m829a4 = weapons["CW_TANK_KE_120_USA"]
	# M829A4 should be competitive with best 125mm rounds
	assert_true(m829a4.pen_ke[WeaponDataClass.RangeBand.MID] >= 140, "M829A4 should have pen_ke >= 140 at MID")


func test_javelin_higher_penetration_than_generic_atgm() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var javelin = weapons["W_USA_ATGM_JAVELIN"]
	var generic_atgm = weapons["W_GEN_ATGM_TOPATTACK"]
	# Javelin should have good pen_ce
	var javelin_pen: int = javelin.pen_ce[WeaponDataClass.RangeBand.MID]
	var generic_pen: int = generic_atgm.pen_ce[WeaponDataClass.RangeBand.MID]
	assert_gt(javelin_pen, generic_pen, "Javelin should have higher penetration than generic ATGM")
