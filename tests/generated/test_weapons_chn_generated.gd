extends GutTest

## 自動生成された武器テスト（CHN）
## 生成元: data/weapons/weapons_chn.json
## 生成日: 2026-02-26T17:22:19
## 注意: このファイルは自動生成されます。手動編集しないでください。

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


# =============================================================================
# 武器存在確認テスト
# =============================================================================

func test_cw_tank_ke_125_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN", "125mm ZPT-98 (DTC10-125) should exist")


func test_cw_tank_ke_105_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_CHN", "105mm ZPL-151 should exist")


func test_cw_autocannon_30_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30_CHN", "30mm ZPT-99 should exist")


func test_cw_autocannon_35_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_35_CHN", "35mm Type 90 (PG99) should exist")


func test_cw_autocannon_100_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_100_CHN", "100mm Gun-Launcher should exist")


func test_cw_atgm_hj10_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ10", "HJ-10 (Red Arrow-10) should exist")


func test_cw_atgm_hj9_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ9", "HJ-9 (Red Arrow-9) should exist")


func test_cw_atgm_hj8e_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ8E", "HJ-8E (Red Arrow-8E) should exist")


func test_cw_atgm_hj73_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_HJ73", "HJ-73 (Red Arrow-73) should exist")


func test_cw_atgm_gp105_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_GP105", "GP105 Gun-Launched ATGM should exist")


func test_cw_qjc88_aa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_QJC88_AA", "12.7mm QJC-88 should exist")


func test_cw_qjz89_aa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_QJZ89_AA", "12.7mm QJZ-89 should exist")


func test_cw_type86_coax_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TYPE86_COAX", "7.62mm Type 86 should exist")


func test_cw_howitzer_122_chn_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HOWITZER_122_CHN", "122mm PLZ-07 should exist")


# =============================================================================
# Mechanism / FireModel テスト
# =============================================================================

func test_cw_tank_ke_125_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125_CHN should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125_CHN should be DISCRETE")


func test_cw_tank_ke_105_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_105_CHN should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_105_CHN should be DISCRETE")


func test_cw_autocannon_30_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_30_CHN should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_30_CHN should be CONTINUOUS")


func test_cw_autocannon_35_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_35_CHN should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_35_CHN should be CONTINUOUS")


func test_cw_autocannon_100_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_AUTOCANNON_100_CHN should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_AUTOCANNON_100_CHN should be DISCRETE")


func test_cw_atgm_hj10_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ10"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_HJ10 should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_HJ10 should be DISCRETE")


func test_cw_atgm_hj9_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ9"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_HJ9 should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_HJ9 should be DISCRETE")


func test_cw_atgm_hj8e_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ8E"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_HJ8E should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_HJ8E should be DISCRETE")


func test_cw_atgm_hj73_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ73"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_HJ73 should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_HJ73 should be DISCRETE")


func test_cw_atgm_gp105_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_GP105"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_GP105 should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_GP105 should be DISCRETE")


func test_cw_qjc88_aa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJC88_AA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_QJC88_AA should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_QJC88_AA should be CONTINUOUS")


func test_cw_qjz89_aa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJZ89_AA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_QJZ89_AA should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_QJZ89_AA should be CONTINUOUS")


func test_cw_type86_coax_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TYPE86_COAX"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_TYPE86_COAX should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_TYPE86_COAX should be CONTINUOUS")


func test_cw_howitzer_122_chn_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_122_CHN"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_HOWITZER_122_CHN should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_HOWITZER_122_CHN should be INDIRECT")


# =============================================================================
# 貫徹力テスト
# =============================================================================

func test_cw_tank_ke_125_chn_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 160, "CW_TANK_KE_125_CHN pen_ke MID should be 160")


func test_cw_tank_ke_105_chn_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 100, "CW_TANK_KE_105_CHN pen_ke MID should be 100")


func test_cw_autocannon_30_chn_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_CHN"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 12, "CW_AUTOCANNON_30_CHN pen_ke MID should be 12")


func test_cw_autocannon_35_chn_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_CHN"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 14, "CW_AUTOCANNON_35_CHN pen_ke MID should be 14")


func test_cw_autocannon_100_chn_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_CHN"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 120, "CW_AUTOCANNON_100_CHN pen_ce MID should be 120")


func test_cw_atgm_hj10_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ10"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 280, "CW_ATGM_HJ10 pen_ce MID should be 280")


func test_cw_atgm_hj9_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ9"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 240, "CW_ATGM_HJ9 pen_ce MID should be 240")


func test_cw_atgm_hj8e_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ8E"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 200, "CW_ATGM_HJ8E pen_ce MID should be 200")


func test_cw_atgm_hj73_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ73"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 85, "CW_ATGM_HJ73 pen_ce MID should be 85")


func test_cw_atgm_gp105_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_GP105"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 140, "CW_ATGM_GP105 pen_ce MID should be 140")


func test_cw_qjc88_aa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJC88_AA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 4, "CW_QJC88_AA pen_ke MID should be 4")


func test_cw_qjz89_aa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJZ89_AA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 4, "CW_QJZ89_AA pen_ke MID should be 4")


# =============================================================================
# 射程テスト
# =============================================================================

func test_cw_tank_ke_125_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_TANK_KE_125_CHN max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_KE_125_CHN min_range should be 0.0")


func test_cw_tank_ke_105_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN"]
	assert_eq(weapon.max_range_m, 3000.0, "CW_TANK_KE_105_CHN max_range should be 3000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_KE_105_CHN min_range should be 0.0")


func test_cw_autocannon_30_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_CHN"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_AUTOCANNON_30_CHN max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_30_CHN min_range should be 0.0")


func test_cw_autocannon_35_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_CHN"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_AUTOCANNON_35_CHN max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_35_CHN min_range should be 0.0")


func test_cw_autocannon_100_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_CHN"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_AUTOCANNON_100_CHN max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_AUTOCANNON_100_CHN min_range should be 100.0")


func test_cw_atgm_hj10_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ10"]
	assert_eq(weapon.max_range_m, 10000.0, "CW_ATGM_HJ10 max_range should be 10000.0")
	assert_eq(weapon.min_range_m, 3000.0, "CW_ATGM_HJ10 min_range should be 3000.0")


func test_cw_atgm_hj9_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ9"]
	assert_eq(weapon.max_range_m, 5500.0, "CW_ATGM_HJ9 max_range should be 5500.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_HJ9 min_range should be 100.0")


func test_cw_atgm_hj8e_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ8E"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_ATGM_HJ8E max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_HJ8E min_range should be 100.0")


func test_cw_atgm_hj73_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_HJ73"]
	assert_eq(weapon.max_range_m, 3000.0, "CW_ATGM_HJ73 max_range should be 3000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_HJ73 min_range should be 100.0")


func test_cw_atgm_gp105_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_GP105"]
	assert_eq(weapon.max_range_m, 5200.0, "CW_ATGM_GP105 max_range should be 5200.0")
	assert_eq(weapon.min_range_m, 500.0, "CW_ATGM_GP105 min_range should be 500.0")


func test_cw_qjc88_aa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJC88_AA"]
	assert_eq(weapon.max_range_m, 1800.0, "CW_QJC88_AA max_range should be 1800.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_QJC88_AA min_range should be 0.0")


func test_cw_qjz89_aa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_QJZ89_AA"]
	assert_eq(weapon.max_range_m, 1800.0, "CW_QJZ89_AA max_range should be 1800.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_QJZ89_AA min_range should be 0.0")


func test_cw_type86_coax_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TYPE86_COAX"]
	assert_eq(weapon.max_range_m, 1000.0, "CW_TYPE86_COAX max_range should be 1000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TYPE86_COAX min_range should be 0.0")


func test_cw_howitzer_122_chn_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_122_CHN"]
	assert_eq(weapon.max_range_m, 18000.0, "CW_HOWITZER_122_CHN max_range should be 18000.0")
	assert_eq(weapon.min_range_m, 1500.0, "CW_HOWITZER_122_CHN min_range should be 1500.0")


# =============================================================================
# 相対比較テスト
# =============================================================================

func test_chn_autocannon_caliber_comparison() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var small = weapons["CW_AUTOCANNON_30_CHN"]
	var large = weapons["CW_AUTOCANNON_35_CHN"]
	# 大口径は小口径より貫徹力が高い
	assert_gt(large.pen_ke[WeaponDataClass.RangeBand.NEAR], small.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"CW_AUTOCANNON_35_CHN should have higher penetration than CW_AUTOCANNON_30_CHN")


func test_cw_atgm_hj10_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_HJ10"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_HJ10 should have significant pen_ce")


func test_cw_atgm_hj9_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_HJ9"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_HJ9 should have significant pen_ce")


func test_cw_atgm_hj8e_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_HJ8E"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_HJ8E should have significant pen_ce")


func test_cw_atgm_hj73_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_HJ73"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_HJ73 should have significant pen_ce")


func test_cw_atgm_gp105_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_GP105"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_GP105 should have significant pen_ce")

