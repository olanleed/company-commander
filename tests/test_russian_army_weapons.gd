extends GutTest

## ロシア軍武器システムのテスト
## docs/weapons_tree/russian_army_weapons_2026.md 準拠

var WeaponDataClass: GDScript
var VehicleCatalogClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# ロシア軍武器存在テスト
# =============================================================================

func test_rus_125mm_2a46m5_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_RUS", "125mm 2A46M-5 (3BM60) should exist")


func test_rus_3bm60_penetration() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var weapon: WeaponDataClass.WeaponType = weapons["CW_TANK_KE_125_RUS"]
	# 3BM60 Svinets-2: 700mm RHA @ 2km → pen_ke = 140
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 140, "3BM60 should have pen_ke 140 at MID (700mm)")


func test_rus_125mm_vs_standard() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var rus_125 = weapons["CW_TANK_KE_125_RUS"]
	var std_125 = weapons["CW_TANK_KE_125"]
	# ロシア軍3BM60は汎用125mmより貫徹力が高い
	assert_gt(rus_125.pen_ke[WeaponDataClass.RangeBand.MID], std_125.pen_ke[WeaponDataClass.RangeBand.MID],
		"3BM60 should have higher penetration than generic 125mm")


func test_rus_125mm_mango_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_MANGO", "125mm 2A46M (3BM42 Mango) should exist")


func test_rus_3bm42_lower_than_3bm60() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var mango = weapons["CW_TANK_KE_125_MANGO"]
	var svinets = weapons["CW_TANK_KE_125_RUS"]
	# 3BM42 Mango: 500mm vs 3BM60 Svinets-2: 700mm
	assert_lt(mango.pen_ke[WeaponDataClass.RangeBand.MID], svinets.pen_ke[WeaponDataClass.RangeBand.MID],
		"3BM42 Mango should have lower penetration than 3BM60")


func test_rus_30mm_2a42_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30_RUS", "30mm 2A42/2A72 should exist")


func test_rus_100mm_2a70_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_100_RUS", "100mm 2A70 gun-launcher should exist")


func test_rus_kpvt_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HMG_KPVT", "14.5mm KPVT should exist")


func test_rus_pkt_coax_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_PKT_COAX", "7.62mm PKT coaxial should exist")


func test_rus_kord_aa_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_KORD_AA", "12.7mm Kord AA should exist")


# =============================================================================
# ロシア軍ATGM テスト
# =============================================================================

func test_rus_kornet_atgm_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_KORNET", "9M133 Kornet ATGM should exist")


func test_rus_kornet_penetration() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var weapon: WeaponDataClass.WeaponType = weapons["CW_ATGM_KORNET"]
	# Kornet: 1200mm RHA → pen_ce = 240
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 240, "Kornet should have pen_ce 240 (1200mm)")


func test_rus_refleks_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_REFLEKS", "9M119M Refleks should exist")


func test_rus_refleks_penetration() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var weapon: WeaponDataClass.WeaponType = weapons["CW_ATGM_REFLEKS"]
	# Refleks: 900mm RHA → pen_ce = 180
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 180, "Refleks should have pen_ce 180 (900mm)")


func test_rus_konkurs_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_KONKURS", "9M113M Konkurs-M should exist")


func test_rus_bastion_exists() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_BASTION", "9M117 Bastion should exist")


func test_kornet_higher_pen_than_refleks() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var kornet = weapons["CW_ATGM_KORNET"]
	var refleks = weapons["CW_ATGM_REFLEKS"]
	# Kornet (1200mm) > Refleks (900mm)
	assert_gt(kornet.pen_ce[WeaponDataClass.RangeBand.MID], refleks.pen_ce[WeaponDataClass.RangeBand.MID],
		"Kornet should have higher pen than Refleks")


func test_refleks_higher_pen_than_konkurs() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var refleks = weapons["CW_ATGM_REFLEKS"]
	var konkurs = weapons["CW_ATGM_KONKURS"]
	# Refleks (900mm) > Konkurs-M (800mm)
	assert_gt(refleks.pen_ce[WeaponDataClass.RangeBand.MID], konkurs.pen_ce[WeaponDataClass.RangeBand.MID],
		"Refleks should have higher pen than Konkurs")


func test_rus_weapons_count() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var rus_weapons := 0
	for key in weapons.keys():
		if key.ends_with("_RUS") or key in ["CW_TANK_KE_125_MANGO", "CW_HMG_KPVT", "CW_PKT_COAX", "CW_KORD_AA",
			"CW_ATGM_KORNET", "CW_ATGM_REFLEKS", "CW_ATGM_KONKURS", "CW_ATGM_BASTION"]:
			rus_weapons += 1
	# 11 Russian-specific weapons
	assert_eq(rus_weapons, 11, "Should have 11 Russian-specific weapons")


# =============================================================================
# ロシア車両カタログ統合テスト
# =============================================================================

func test_t90m_has_weapons() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	assert_not_null(vehicle, "T-90M should exist in catalog")
	assert_has(vehicle.main_gun, "weapon_id", "T-90M should have weapon_id in main_gun")


func test_t90m_main_weapon_is_125mm_rus() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_RUS", "T-90M should use CW_TANK_KE_125_RUS")


func test_t90m_has_refleks() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	assert_has(vehicle, "atgm", "T-90M should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_REFLEKS", "T-90M should have Refleks ATGM")


func test_t90m_secondary_weapons() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	assert_has(vehicle, "secondary_weapons", "T-90M should have secondary_weapons")
	assert_has(vehicle.secondary_weapons, "CW_PKT_COAX", "T-90M should have PKT coax")
	assert_has(vehicle.secondary_weapons, "CW_KORD_AA", "T-90M should have Kord AA")


func test_t72b3_uses_mango() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T72B3")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_MANGO", "T-72B3 should use Mango (3BM42)")


func test_bmp3_has_weapons() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BMP3")
	assert_not_null(vehicle, "BMP-3 should exist")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_100_RUS", "BMP-3 should use 100mm 2A70")


func test_bmp3_has_bastion() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BMP3")
	assert_has(vehicle, "atgm", "BMP-3 should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_BASTION", "BMP-3 should have Bastion ATGM")


func test_bmp2_has_konkurs() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BMP2")
	assert_has(vehicle, "atgm", "BMP-2 should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_KONKURS", "BMP-2 should have Konkurs-M ATGM")


func test_btr82a_has_30mm() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BTR82A")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_30_RUS", "BTR-82A should use 30mm 2A72")


func test_btr80_has_kpvt() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BTR80")
	assert_eq(vehicle.main_gun.weapon_id, "CW_HMG_KPVT", "BTR-80 should use KPVT 14.5mm")


func test_t90m_weapon_count() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	# main_gun + atgm + 2 secondary = 4
	var weapon_count := 1  # main_gun
	if vehicle.has("atgm") and vehicle.atgm.has("weapon_id"):
		weapon_count += 1
	if vehicle.has("secondary_weapons"):
		weapon_count += vehicle.secondary_weapons.size()
	assert_eq(weapon_count, 4, "T-90M should have 4 weapons total")


func test_bmp3_weapon_count() -> void:
	var catalog := VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_BMP3")
	# main_gun (100mm) + atgm + 2 secondary (30mm, PKT) = 4
	var weapon_count := 1
	if vehicle.has("atgm") and vehicle.atgm.has("weapon_id"):
		weapon_count += 1
	if vehicle.has("secondary_weapons"):
		weapon_count += vehicle.secondary_weapons.size()
	assert_eq(weapon_count, 4, "BMP-3 should have 4 weapons total")


# =============================================================================
# 比較テスト（米軍 vs ロシア軍）
# =============================================================================

func test_m829a4_vs_3bm60() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var m829a4 = weapons["CW_TANK_KE_120_USA"]
	var svinets = weapons["CW_TANK_KE_125_RUS"]
	# M829A4: 750mm vs 3BM60: 700mm → M829A4が若干上
	assert_gt(m829a4.pen_ke[WeaponDataClass.RangeBand.MID], svinets.pen_ke[WeaponDataClass.RangeBand.MID],
		"M829A4 (750mm) should have higher penetration than 3BM60 (700mm)")


func test_javelin_vs_kornet() -> void:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	var javelin = weapons["CW_ATGM_JAVELIN"]
	var kornet = weapons["CW_ATGM_KORNET"]
	# Kornet (1200mm) > Javelin (900mm direct)
	assert_gt(kornet.pen_ce[WeaponDataClass.RangeBand.MID], javelin.pen_ce[WeaponDataClass.RangeBand.MID],
		"Kornet should have higher direct-hit penetration than Javelin")
