extends GutTest

## 自動生成された武器テスト（JPN）
## 生成元: data/weapons/weapons_jpn.json
## 生成日: 2026-02-26T17:22:19
## 注意: このファイルは自動生成されます。手動編集しないでください。

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


# =============================================================================
# 武器存在確認テスト
# =============================================================================

func test_cw_tank_ke_120_jgsdf_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_120_JGSDF", "120mm Tank Gun (JGSDF) should exist")


func test_cw_tank_ke_105_jgsdf_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_JGSDF", "105mm Tank Gun (Type 16) should exist")


func test_cw_autocannon_35_jgsdf_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_35_JGSDF", "35mm Autocannon (Type 89) should exist")


func test_cw_autocannon_25_jgsdf_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_25_JGSDF", "25mm Autocannon (Type 87) should exist")


func test_cw_atgm_79mat_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_79MAT", "Type 79 Heavy MAT should exist")


func test_cw_atgm_mmpm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_MMPM", "MMPM should exist")


func test_cw_atgm_01lmat_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_01LMAT", "Type 01 LMAT should exist")


# =============================================================================
# Mechanism / FireModel テスト
# =============================================================================

func test_cw_tank_ke_120_jgsdf_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_JGSDF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_120_JGSDF should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_120_JGSDF should be DISCRETE")


func test_cw_tank_ke_105_jgsdf_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_JGSDF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_105_JGSDF should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_105_JGSDF should be DISCRETE")


func test_cw_autocannon_35_jgsdf_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_JGSDF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_35_JGSDF should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_35_JGSDF should be CONTINUOUS")


func test_cw_autocannon_25_jgsdf_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_JGSDF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_25_JGSDF should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_25_JGSDF should be CONTINUOUS")


func test_cw_atgm_79mat_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_79MAT"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_79MAT should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_79MAT should be DISCRETE")


func test_cw_atgm_mmpm_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_MMPM"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_MMPM should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_MMPM should be DISCRETE")


func test_cw_atgm_01lmat_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_01LMAT"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_01LMAT should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_01LMAT should be DISCRETE")


# =============================================================================
# 貫徹力テスト
# =============================================================================

func test_cw_tank_ke_120_jgsdf_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_JGSDF"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 115, "CW_TANK_KE_120_JGSDF pen_ke MID should be 115")


func test_cw_tank_ke_105_jgsdf_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_JGSDF"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 70, "CW_TANK_KE_105_JGSDF pen_ke MID should be 70")


func test_cw_autocannon_35_jgsdf_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_JGSDF"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 19, "CW_AUTOCANNON_35_JGSDF pen_ke MID should be 19")


func test_cw_autocannon_25_jgsdf_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_JGSDF"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 11, "CW_AUTOCANNON_25_JGSDF pen_ke MID should be 11")


func test_cw_atgm_79mat_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_79MAT"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 110, "CW_ATGM_79MAT pen_ce MID should be 110")


func test_cw_atgm_mmpm_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_MMPM"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 150, "CW_ATGM_MMPM pen_ce MID should be 150")


func test_cw_atgm_01lmat_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_01LMAT"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 130, "CW_ATGM_01LMAT pen_ce MID should be 130")


# =============================================================================
# 射程テスト
# =============================================================================

func test_cw_tank_ke_120_jgsdf_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_120_JGSDF"]
	assert_eq(weapon.max_range_m, 3000.0, "CW_TANK_KE_120_JGSDF max_range should be 3000.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_120_JGSDF min_range should be 50.0")


func test_cw_tank_ke_105_jgsdf_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_JGSDF"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_TANK_KE_105_JGSDF max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_105_JGSDF min_range should be 50.0")


func test_cw_autocannon_35_jgsdf_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35_JGSDF"]
	assert_eq(weapon.max_range_m, 3000.0, "CW_AUTOCANNON_35_JGSDF max_range should be 3000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_35_JGSDF min_range should be 0.0")


func test_cw_autocannon_25_jgsdf_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25_JGSDF"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_AUTOCANNON_25_JGSDF max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_25_JGSDF min_range should be 0.0")


func test_cw_atgm_79mat_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_79MAT"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_ATGM_79MAT max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 200.0, "CW_ATGM_79MAT min_range should be 200.0")


func test_cw_atgm_mmpm_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_MMPM"]
	assert_eq(weapon.max_range_m, 5000.0, "CW_ATGM_MMPM max_range should be 5000.0")
	assert_eq(weapon.min_range_m, 300.0, "CW_ATGM_MMPM min_range should be 300.0")


func test_cw_atgm_01lmat_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_01LMAT"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_ATGM_01LMAT max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_01LMAT min_range should be 100.0")


# =============================================================================
# 相対比較テスト
# =============================================================================

func test_jpn_autocannon_caliber_comparison() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var small = weapons["CW_AUTOCANNON_25_JGSDF"]
	var large = weapons["CW_AUTOCANNON_35_JGSDF"]
	# 大口径は小口径より貫徹力が高い
	assert_gt(large.pen_ke[WeaponDataClass.RangeBand.NEAR], small.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"CW_AUTOCANNON_35_JGSDF should have higher penetration than CW_AUTOCANNON_25_JGSDF")


func test_cw_atgm_79mat_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_79MAT"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_79MAT should have significant pen_ce")


func test_cw_atgm_mmpm_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_MMPM"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_MMPM should have significant pen_ce")


func test_cw_atgm_01lmat_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_01LMAT"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_01LMAT should have significant pen_ce")

