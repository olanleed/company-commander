extends GutTest

## 陸上自衛隊武器システムのテスト
## docs/weapons_tree/jgsdf_weapons_2026.md 準拠

var WeaponDataClass: GDScript
var VehicleCatalogClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")


# =============================================================================
# 陸自戦車砲テスト
# =============================================================================

func test_jgsdf_120mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_120_JGSDF", "120mm L44 (JM33) should exist")


func test_jgsdf_120mm_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_JGSDF"]
	# JM33: 600mm RHA @ 2km → pen_ke = 120
	assert_gt(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 100, "JM33 should have pen_ke > 100 at MID")


func test_jgsdf_120mm_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_JGSDF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "120mm should be KINETIC mechanism")


func test_jgsdf_105mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_JGSDF", "105mm L7 should exist")


func test_jgsdf_105mm_lower_than_120mm() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mm105 = weapons["CW_TANK_KE_105_JGSDF"]
	var mm120 = weapons["CW_TANK_KE_120_JGSDF"]
	# 105mm < 120mm penetration
	assert_lt(mm105.pen_ke[WeaponDataClass.RangeBand.MID], mm120.pen_ke[WeaponDataClass.RangeBand.MID],
		"105mm should have lower penetration than 120mm")


# =============================================================================
# 陸自機関砲テスト
# =============================================================================

func test_jgsdf_35mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_35_JGSDF", "35mm Oerlikon KDE should exist")


func test_jgsdf_25mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_25_JGSDF", "25mm M242 (JGSDF) should exist")


func test_jgsdf_35mm_higher_than_25mm() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mm25 = weapons["CW_AUTOCANNON_25_JGSDF"]
	var mm35 = weapons["CW_AUTOCANNON_35_JGSDF"]
	# 35mm > 25mm penetration
	assert_gt(mm35.pen_ke[WeaponDataClass.RangeBand.NEAR], mm25.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"35mm should have higher penetration than 25mm")


# =============================================================================
# 陸自ATGM テスト
# =============================================================================

func test_jgsdf_01lmat_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_01LMAT", "Type 01 LMAT should exist")


func test_jgsdf_01lmat_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_01LMAT"]
	# 01式LMAT: Top attack capable, ~700mm RHA → pen_ce = 140
	assert_gt(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 100, "01LMAT should have pen_ce > 100")


func test_jgsdf_01lmat_is_shaped_charge() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_01LMAT"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "01LMAT should be SHAPED_CHARGE")


# =============================================================================
# 陸自機銃テスト（汎用機銃を使用）
# =============================================================================

func test_generic_coax_mg_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_COAX_MG", "Coaxial MG should exist")


func test_jgsdf_m2hb_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	# JGSDF uses M2HB (same as USA)
	assert_has(weapons, "CW_M2HB", "M2HB .50 cal should exist (shared with USA)")


# =============================================================================
# 陸自榴弾砲テスト（汎用155mmを使用）
# =============================================================================

func test_generic_155mm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HOWITZER_155", "155mm howitzer should exist")


func test_generic_155mm_fire_model() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_155"]
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "Howitzer should be INDIRECT fire model")


# =============================================================================
# 陸自車両カタログ統合テスト
# =============================================================================

func test_type10_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type10")
	assert_not_null(vehicle, "10式戦車 should exist in catalog")


func test_type10_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type10")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_120_JGSDF", "10式 should use 120mm JM33")


func test_type10_has_secondary_weapons() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type10")
	assert_not_null(vehicle.secondary_weapons, "10式 should have secondary weapons")


func test_type90_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type90")
	assert_not_null(vehicle, "90式戦車 should exist")


func test_type90_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type90")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_120_JGSDF", "90式 should use 120mm")


func test_type89_ifv_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type89")
	assert_not_null(vehicle, "89式装甲戦闘車 should exist")


func test_type89_ifv_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type89")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_35_JGSDF", "89式 should use 35mm")


func test_type89_ifv_has_atgm() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type89")
	assert_not_null(vehicle.atgm, "89式 should have ATGM")


func test_type16_mcv_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type16")
	assert_not_null(vehicle, "16式機動戦闘車 should exist")


func test_type16_mcv_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type16")
	assert_eq(vehicle.main_gun.weapon_id, "CW_TANK_KE_105_JGSDF", "16式 should use 105mm")


func test_type87_rcv_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type87_RCV")
	assert_not_null(vehicle, "87式偵察警戒車 should exist")


func test_type87_rcv_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type87_RCV")
	assert_eq(vehicle.main_gun.weapon_id, "CW_AUTOCANNON_25_JGSDF", "87式RCV should use 25mm")


func test_type99_sph_exists() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type99_SPH")
	assert_not_null(vehicle, "99式自走155mm榴弾砲 should exist")


func test_type99_sph_main_weapon() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type99_SPH")
	# 現在の実装ではCW_HOWITZER_155（汎用）を使用
	assert_eq(vehicle.main_gun.weapon_id, "CW_HOWITZER_155", "99式SPH should use 155mm")


# =============================================================================
# 武器数カウントテスト
# =============================================================================

func test_jgsdf_weapons_count() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var jgsdf_weapons = 0
	for key in weapons.keys():
		if key.ends_with("_JGSDF") or key in ["CW_ATGM_01LMAT", "CW_ATGM_79MAT", "CW_ATGM_MMPM"]:
			jgsdf_weapons += 1
	# At least 6 JGSDF-specific weapons
	assert_true(jgsdf_weapons >= 6, "Should have at least 6 JGSDF-specific weapons")


# =============================================================================
# 比較テスト
# =============================================================================

func test_jm33_vs_m829a4() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var jm33 = weapons["CW_TANK_KE_120_JGSDF"]
	var m829a4 = weapons["CW_TANK_KE_120_USA"]
	# M829A4 (750mm) > JM33 (600mm)
	assert_lt(jm33.pen_ke[WeaponDataClass.RangeBand.MID], m829a4.pen_ke[WeaponDataClass.RangeBand.MID],
		"JM33 should have lower penetration than M829A4")


func test_01lmat_vs_javelin() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var lmat = weapons["CW_ATGM_01LMAT"]
	var javelin = weapons["CW_ATGM_JAVELIN"]
	# Both are top-attack capable, Javelin slightly higher
	var lmat_pen: int = lmat.pen_ce[WeaponDataClass.RangeBand.MID]
	var javelin_pen: int = javelin.pen_ce[WeaponDataClass.RangeBand.MID]
	# Javelin >= 01LMAT
	assert_true(lmat_pen <= javelin_pen, "01LMAT should have <= penetration compared to Javelin")
