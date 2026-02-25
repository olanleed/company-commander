extends GutTest

## Chinese Army (PLA) Weapons System Tests
## Based on docs/weapons_tree/chinese_army_weapons_2026.md

var WeaponDataClass: GDScript
var VehicleCatalogClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# Chinese Army Tank Gun Tests
# =============================================================================

func test_chn_125mm_dtc10_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN", "125mm ZPT-98 (DTC10-125) should exist")


func test_chn_dtc10_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN"]
	# DTC10-125: 800mm RHA @ 2km -> pen_ke = 160
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 160, "DTC10-125 should have pen_ke 160 at MID (800mm)")


func test_chn_125mm_std_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN_STD", "125mm ZPT-98 (DTW-125 II) should exist")


func test_chn_dtw125ii_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_STD"]
	# DTW-125 Type II: 700mm RHA @ 1km -> pen_ke = 140
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 140, "DTW-125 II should have pen_ke 140 at MID (700mm)")


func test_chn_125mm_old_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN_OLD", "125mm ZPT-96 (DTW-125) should exist")


func test_chn_dtc10_higher_than_dtw125ii() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var dtc10 = weapons["CW_TANK_KE_125_CHN"]
	var dtw125ii = weapons["CW_TANK_KE_125_CHN_STD"]
	# DTC10-125 (800mm) > DTW-125 II (700mm)
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], dtw125ii.pen_ke[WeaponDataClass.RangeBand.MID],
		"DTC10-125 should have higher penetration than DTW-125 II")


func test_chn_dtw125ii_higher_than_dtw125_old() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var dtw125ii = weapons["CW_TANK_KE_125_CHN_STD"]
	var dtw125_old = weapons["CW_TANK_KE_125_CHN_OLD"]
	# DTW-125 II (700mm) > DTW-125 (550mm)
	assert_gt(dtw125ii.pen_ke[WeaponDataClass.RangeBand.MID], dtw125_old.pen_ke[WeaponDataClass.RangeBand.MID],
		"DTW-125 II should have higher penetration than DTW-125 old")


# =============================================================================
# Chinese Army 105mm Gun Tests
# =============================================================================

func test_chn_105mm_zpl151_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_CHN", "105mm ZPL-151 should exist")


func test_chn_105mm_zpl151_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN"]
	# ZPL-151: 500mm RHA @ 2km -> pen_ke = 100
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 100, "ZPL-151 should have pen_ke 100 at MID (500mm)")


func test_chn_105mm_old_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_CHN_OLD", "105mm Type 83 should exist")


func test_chn_105mm_new_higher_than_old() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var zpl151 = weapons["CW_TANK_KE_105_CHN"]
	var type83 = weapons["CW_TANK_KE_105_CHN_OLD"]
	assert_gt(zpl151.pen_ke[WeaponDataClass.RangeBand.MID], type83.pen_ke[WeaponDataClass.RangeBand.MID],
		"ZPL-151 should have higher penetration than Type 83")


# =============================================================================
# Chinese Army Autocannon Tests
# =============================================================================

func test_chn_30mm_zpt99_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30_CHN", "30mm ZPT-99 should exist")


func test_chn_35mm_type90_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_35_CHN", "35mm Type 90 (PG99) should exist")


func test_chn_100mm_gun_launcher_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_100_CHN", "100mm gun-launcher should exist")


func test_chn_100mm_has_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_CHN"]
	# 100mm gun-launcher: 600mm ATGM -> pen_ce = 120
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 120, "100mm gun-launcher should have pen_ce 120 (600mm)")


# =============================================================================
# Chinese Army ATGM Tests
# =============================================================================

func test_chn_hj10_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ10", "HJ-10 (Red Arrow-10) should exist")


func test_chn_hj10_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ10"]
	# HJ-10: 1400mm RHA post-ERA -> pen_ce = 280
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 280, "HJ-10 should have pen_ce 280 (1400mm)")


func test_chn_hj9_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ9", "HJ-9 (Red Arrow-9) should exist")


func test_chn_hj9_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ9"]
	# HJ-9: 1200mm RHA -> pen_ce = 240
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 240, "HJ-9 should have pen_ce 240 (1200mm)")


func test_chn_hj8e_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ8E", "HJ-8E (Red Arrow-8E) should exist")


func test_chn_hj8e_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ8E"]
	# HJ-8E: 1000mm RHA post-ERA -> pen_ce = 200
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 200, "HJ-8E should have pen_ce 200 (1000mm)")


func test_chn_hj73_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ73", "HJ-73 (Red Arrow-73) should exist")


func test_chn_hj73_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ73"]
	# HJ-73: 425mm RHA -> pen_ce = 85
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 85, "HJ-73 should have pen_ce 85 (425mm)")


func test_chn_gp105_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_GP105", "GP105 gun-launched ATGM should exist")


func test_chn_gp105_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_GP105"]
	# GP105: 700mm RHA -> pen_ce = 140
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 140, "GP105 should have pen_ce 140 (700mm)")


func test_chn_atgm_hierarchy() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var hj10 = weapons["CW_ATGM_HJ10"]
	var hj9 = weapons["CW_ATGM_HJ9"]
	var hj8e = weapons["CW_ATGM_HJ8E"]
	var gp105 = weapons["CW_ATGM_GP105"]
	var hj73 = weapons["CW_ATGM_HJ73"]
	# HJ-10 (1400mm) > HJ-9 (1200mm) > HJ-8E (1000mm) > GP105 (700mm) > HJ-73 (425mm)
	assert_gt(hj10.pen_ce[WeaponDataClass.RangeBand.MID], hj9.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-10 should have higher pen than HJ-9")
	assert_gt(hj9.pen_ce[WeaponDataClass.RangeBand.MID], hj8e.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-9 should have higher pen than HJ-8E")
	assert_gt(hj8e.pen_ce[WeaponDataClass.RangeBand.MID], gp105.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-8E should have higher pen than GP105")
	assert_gt(gp105.pen_ce[WeaponDataClass.RangeBand.MID], hj73.pen_ce[WeaponDataClass.RangeBand.MID],
		"GP105 should have higher pen than HJ-73")


# =============================================================================
# Chinese Army Machine Gun Tests
# =============================================================================

func test_chn_qjz89_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_QJZ89_AA", "12.7mm QJZ-89 should exist")


func test_chn_type86_coax_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TYPE86_COAX", "7.62mm Type 86 coaxial should exist")


# =============================================================================
# Chinese Army Weapons Count Test
# =============================================================================

func test_chn_weapons_count() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var chn_weapons: int = 0
	for key in weapons.keys():
		if key.ends_with("_CHN") or key.ends_with("_CHN_STD") or key.ends_with("_CHN_OLD") or \
		   key in ["CW_ATGM_HJ10", "CW_ATGM_HJ9", "CW_ATGM_HJ8E", "CW_ATGM_HJ73", "CW_ATGM_GP105",
				   "CW_QJZ89_AA", "CW_TYPE86_COAX"]:
			chn_weapons += 1
	# 15 Chinese-specific weapons
	assert_eq(chn_weapons, 15, "Should have 15 Chinese-specific weapons")


# =============================================================================
# Chinese Vehicle Catalog Integration Tests
# =============================================================================

func test_type99a_has_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type99A")
	assert_not_null(vehicle, "Type 99A should exist in catalog")
	assert_has(vehicle.main_gun, "weapon_id", "Type 99A should have weapon_id in main_gun")


func test_type99a_main_weapon_is_dtc10() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type99A")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_CHN", "Type 99A should use CW_TANK_KE_125_CHN")


func test_type99a_secondary_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type99A")
	assert_has(vehicle, "secondary_weapons", "Type 99A should have secondary_weapons")
	assert_has(vehicle.secondary_weapons, "CW_TYPE86_COAX", "Type 99A should have Type 86 coax")
	assert_has(vehicle.secondary_weapons, "CW_QJZ89_AA", "Type 99A should have QJZ-89 AA")


func test_type99_uses_dtw125ii() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type99")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_CHN_STD", "Type 99 should use DTW-125 II")


func test_type96a_uses_dtw125ii() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type96A")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_CHN_STD", "Type 96A should use DTW-125 II")


func test_type96_uses_dtw125_old() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type96")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_125_CHN_OLD", "Type 96 should use DTW-125 old")


func test_type15_has_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type15")
	assert_not_null(vehicle, "Type 15 should exist")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_105_CHN", "Type 15 should use 105mm ZPL-151")


func test_type15_has_gp105_atgm() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type15")
	assert_has(vehicle, "atgm", "Type 15 should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_GP105", "Type 15 should have GP105 ATGM")


func test_zbd04a_has_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZBD04A")
	assert_not_null(vehicle, "ZBD-04A should exist")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_30_CHN", "ZBD-04A should use 30mm ZPT-99")


func test_zbd04a_has_hj8e() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZBD04A")
	assert_has(vehicle, "atgm", "ZBD-04A should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_HJ8E", "ZBD-04A should have HJ-8E ATGM")


func test_zbd04_has_100mm() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZBD04")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_100_CHN", "ZBD-04 should use 100mm gun-launcher")


func test_zbd09_has_hj73() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZBD09")
	assert_has(vehicle, "atgm", "ZBD-09 should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_HJ73", "ZBD-09 should have HJ-73 ATGM")


func test_pgz09_has_35mm() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_PGZ09")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_35_CHN", "PGZ-09 should use 35mm Type 90")


func test_ztl11_has_105mm_old() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZTL11")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_105_CHN_OLD", "ZTL-11 should use 105mm Type 83")


func test_ztl11_has_gp105() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_ZTL11")
	assert_has(vehicle, "atgm", "ZTL-11 should have ATGM")
	assert_eq(vehicle.atgm.weapon_id, "CW_ATGM_GP105", "ZTL-11 should have GP105 ATGM")


func test_type63a_has_105mm_old() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type63A")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_105_CHN_OLD", "Type 63A should use 105mm Type 83")


# =============================================================================
# International Comparison Tests
# =============================================================================

func test_dtc10_vs_m829a4() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var dtc10 = weapons["CW_TANK_KE_125_CHN"]
	var m829a4 = weapons["CW_TANK_KE_120_USA"]
	# DTC10-125 (800mm @ 2km) > M829A4 (750mm @ 2km)
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], m829a4.pen_ke[WeaponDataClass.RangeBand.MID],
		"DTC10-125 should have higher penetration than M829A4")


func test_dtc10_vs_3bm60() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var dtc10 = weapons["CW_TANK_KE_125_CHN"]
	var svinets = weapons["CW_TANK_KE_125_RUS"]
	# DTC10-125 (800mm) > 3BM60 (700mm)
	assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID], svinets.pen_ke[WeaponDataClass.RangeBand.MID],
		"DTC10-125 should have higher penetration than 3BM60")


func test_hj10_vs_javelin() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var hj10 = weapons["CW_ATGM_HJ10"]
	var javelin = weapons["CW_ATGM_JAVELIN"]
	# HJ-10 (1400mm) > Javelin (900mm direct)
	assert_gt(hj10.pen_ce[WeaponDataClass.RangeBand.MID], javelin.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-10 should have higher penetration than Javelin")


func test_hj10_vs_kornet() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var hj10 = weapons["CW_ATGM_HJ10"]
	var kornet = weapons["CW_ATGM_KORNET"]
	# HJ-10 (1400mm) > Kornet (1200mm)
	assert_gt(hj10.pen_ce[WeaponDataClass.RangeBand.MID], kornet.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-10 should have higher penetration than Kornet")


func test_hj9_comparable_to_kornet() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var hj9 = weapons["CW_ATGM_HJ9"]
	var kornet = weapons["CW_ATGM_KORNET"]
	# HJ-9 (1200mm) == Kornet (1200mm)
	assert_eq(hj9.pen_ce[WeaponDataClass.RangeBand.MID], kornet.pen_ce[WeaponDataClass.RangeBand.MID],
		"HJ-9 should have same penetration as Kornet")
