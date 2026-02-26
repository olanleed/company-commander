extends GutTest

## 自動生成された武器テスト（USA）
## 生成元: data/weapons/weapons_usa.json
## 生成日: 2026-02-26T17:22:19
## 注意: このファイルは自動生成されます。手動編集しないでください。

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


# =============================================================================
# 武器存在確認テスト
# =============================================================================

func test_cw_tank_ke_120_usa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_120_USA", "120mm M256 (M829A4) should exist")


func test_cw_tank_heat_usa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_HEAT_USA", "120mm M830A1 MPAT should exist")


func test_cw_autocannon_25_usa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_25_USA", "25mm M242 (M919) should exist")


func test_cw_autocannon_30_usa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30_USA", "30mm XM813 should exist")


func test_cw_atgm_tow2b_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_TOW2B", "TOW-2B should exist")


func test_cw_atgm_javelin_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_JAVELIN", "FGM-148 Javelin should exist")


func test_cw_agl_mk19_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AGL_MK19", "MK19 40mm AGL should exist")


func test_cw_m240_coax_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_M240_COAX", "M240C 7.62mm Coax should exist")


func test_cw_m2hb_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_M2HB", "M2HB .50 Cal should exist")


# =============================================================================
# Mechanism / FireModel テスト
# =============================================================================

func test_cw_tank_ke_120_usa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_120_USA should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_120_USA should be DISCRETE")


func test_cw_tank_heat_usa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEAT_USA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_TANK_HEAT_USA should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_HEAT_USA should be DISCRETE")


func test_cw_autocannon_25_usa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_USA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_25_USA should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_25_USA should be CONTINUOUS")


func test_cw_autocannon_30_usa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_USA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_30_USA should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_30_USA should be CONTINUOUS")


func test_cw_atgm_tow2b_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOW2B"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_TOW2B should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_TOW2B should be DISCRETE")


func test_cw_atgm_javelin_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_JAVELIN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_JAVELIN should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_JAVELIN should be DISCRETE")


func test_cw_agl_mk19_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AGL_MK19"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_AGL_MK19 should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AGL_MK19 should be CONTINUOUS")


func test_cw_m240_coax_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M240_COAX"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_M240_COAX should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_M240_COAX should be CONTINUOUS")


func test_cw_m2hb_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M2HB"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_M2HB should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_M2HB should be CONTINUOUS")


# =============================================================================
# 貫徹力テスト
# =============================================================================

func test_cw_tank_ke_120_usa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 150, "CW_TANK_KE_120_USA pen_ke MID should be 150")


func test_cw_tank_heat_usa_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEAT_USA"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 70, "CW_TANK_HEAT_USA pen_ce MID should be 70")


func test_cw_autocannon_25_usa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_USA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 18, "CW_AUTOCANNON_25_USA pen_ke MID should be 18")


func test_cw_autocannon_30_usa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_USA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 18, "CW_AUTOCANNON_30_USA pen_ke MID should be 18")


func test_cw_atgm_tow2b_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOW2B"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 60, "CW_ATGM_TOW2B pen_ce MID should be 60")


func test_cw_atgm_javelin_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_JAVELIN"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 160, "CW_ATGM_JAVELIN pen_ce MID should be 160")


func test_cw_agl_mk19_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AGL_MK19"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 15, "CW_AGL_MK19 pen_ce MID should be 15")


func test_cw_m2hb_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M2HB"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 4, "CW_M2HB pen_ke MID should be 4")


# =============================================================================
# 射程テスト
# =============================================================================

func test_cw_tank_ke_120_usa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_USA"]
	assert_eq(weapon.max_range_m, 3500.0, "CW_TANK_KE_120_USA max_range should be 3500.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_120_USA min_range should be 50.0")


func test_cw_tank_heat_usa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEAT_USA"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_TANK_HEAT_USA max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_HEAT_USA min_range should be 50.0")


func test_cw_autocannon_25_usa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_USA"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_AUTOCANNON_25_USA max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_25_USA min_range should be 0.0")


func test_cw_autocannon_30_usa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_USA"]
	assert_eq(weapon.max_range_m, 3000.0, "CW_AUTOCANNON_30_USA max_range should be 3000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_30_USA min_range should be 0.0")


func test_cw_atgm_tow2b_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOW2B"]
	assert_eq(weapon.max_range_m, 4500.0, "CW_ATGM_TOW2B max_range should be 4500.0")
	assert_eq(weapon.min_range_m, 65.0, "CW_ATGM_TOW2B min_range should be 65.0")


func test_cw_atgm_javelin_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_JAVELIN"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_ATGM_JAVELIN max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 65.0, "CW_ATGM_JAVELIN min_range should be 65.0")


func test_cw_agl_mk19_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AGL_MK19"]
	assert_eq(weapon.max_range_m, 1600.0, "CW_AGL_MK19 max_range should be 1600.0")
	assert_eq(weapon.min_range_m, 75.0, "CW_AGL_MK19 min_range should be 75.0")


func test_cw_m240_coax_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M240_COAX"]
	assert_eq(weapon.max_range_m, 1500.0, "CW_M240_COAX max_range should be 1500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_M240_COAX min_range should be 0.0")


func test_cw_m2hb_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_M2HB"]
	assert_eq(weapon.max_range_m, 1800.0, "CW_M2HB max_range should be 1800.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_M2HB min_range should be 0.0")


# =============================================================================
# 相対比較テスト
# =============================================================================

func test_usa_tank_ke_vs_heat() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var ke = weapons["CW_TANK_KE_120_USA"]
	var heat = weapons["CW_TANK_HEAT_USA"]
	# KE弾は遠距離でHEAT弾よりpen_keが高い
	assert_gt(ke.pen_ke[WeaponDataClass.RangeBand.MID], 0, "KE ammo should have pen_ke")


func test_usa_autocannon_caliber_comparison() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var small = weapons["CW_AUTOCANNON_25_USA"]
	var large = weapons["CW_AUTOCANNON_30_USA"]
	# 大口径は小口径より貫徹力が高い
	assert_gt(large.pen_ke[WeaponDataClass.RangeBand.NEAR], small.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"CW_AUTOCANNON_30_USA should have higher penetration than CW_AUTOCANNON_25_USA")


func test_cw_atgm_tow2b_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_TOW2B"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_TOW2B should have significant pen_ce")


func test_cw_atgm_javelin_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_JAVELIN"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_JAVELIN should have significant pen_ce")

