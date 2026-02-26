extends GutTest

## 自動生成された武器テスト（RUS）
## 生成元: data/weapons/weapons_rus.json
## 生成日: 2026-02-26T17:22:19
## 注意: このファイルは自動生成されます。手動編集しないでください。

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


# =============================================================================
# 武器存在確認テスト
# =============================================================================

func test_cw_tank_ke_125_rus_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_RUS", "125mm 2A46M-5 (3BM60) should exist")


func test_cw_autocannon_30_rus_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30_RUS", "30mm 2A42/2A72 should exist")


func test_cw_autocannon_100_rus_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_100_RUS", "100mm 2A70 低圧砲 should exist")


func test_cw_hmg_kpvt_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HMG_KPVT", "14.5mm KPVT should exist")


func test_cw_pkt_coax_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_PKT_COAX", "7.62mm PKT 同軸機銃 should exist")


func test_cw_kord_aa_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_KORD_AA", "12.7mm Kord should exist")


func test_cw_atgm_kornet_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_KORNET", "9M133 Kornet should exist")


func test_cw_atgm_refleks_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_REFLEKS", "9M119M Refleks should exist")


func test_cw_atgm_konkurs_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_KONKURS", "9M113M Konkurs-M should exist")


func test_cw_atgm_bastion_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_BASTION", "9M117 Bastion should exist")


# =============================================================================
# Mechanism / FireModel テスト
# =============================================================================

func test_cw_tank_ke_125_rus_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_RUS"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125_RUS should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125_RUS should be DISCRETE")


func test_cw_autocannon_30_rus_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_RUS"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_30_RUS should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_30_RUS should be CONTINUOUS")


func test_cw_autocannon_100_rus_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_RUS"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_AUTOCANNON_100_RUS should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_AUTOCANNON_100_RUS should be DISCRETE")


func test_cw_hmg_kpvt_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG_KPVT"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_HMG_KPVT should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_HMG_KPVT should be CONTINUOUS")


func test_cw_pkt_coax_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_PKT_COAX"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_PKT_COAX should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_PKT_COAX should be CONTINUOUS")


func test_cw_kord_aa_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_KORD_AA"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_KORD_AA should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_KORD_AA should be CONTINUOUS")


func test_cw_atgm_kornet_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KORNET"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_KORNET should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_KORNET should be DISCRETE")


func test_cw_atgm_refleks_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_REFLEKS"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_REFLEKS should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_REFLEKS should be DISCRETE")


func test_cw_atgm_konkurs_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KONKURS"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_KONKURS should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_KONKURS should be DISCRETE")


func test_cw_atgm_bastion_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BASTION"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_BASTION should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_BASTION should be DISCRETE")


# =============================================================================
# 貫徹力テスト
# =============================================================================

func test_cw_tank_ke_125_rus_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_RUS"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 140, "CW_TANK_KE_125_RUS pen_ke MID should be 140")


func test_cw_autocannon_30_rus_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_RUS"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 12, "CW_AUTOCANNON_30_RUS pen_ke MID should be 12")


func test_cw_autocannon_100_rus_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_RUS"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 100, "CW_AUTOCANNON_100_RUS pen_ce MID should be 100")


func test_cw_hmg_kpvt_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG_KPVT"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 6, "CW_HMG_KPVT pen_ke MID should be 6")


func test_cw_kord_aa_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_KORD_AA"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 4, "CW_KORD_AA pen_ke MID should be 4")


func test_cw_atgm_kornet_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KORNET"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 240, "CW_ATGM_KORNET pen_ce MID should be 240")


func test_cw_atgm_refleks_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_REFLEKS"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 180, "CW_ATGM_REFLEKS pen_ce MID should be 180")


func test_cw_atgm_konkurs_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KONKURS"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 160, "CW_ATGM_KONKURS pen_ce MID should be 160")


func test_cw_atgm_bastion_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BASTION"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 110, "CW_ATGM_BASTION pen_ce MID should be 110")


# =============================================================================
# 射程テスト
# =============================================================================

func test_cw_tank_ke_125_rus_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_RUS"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_TANK_KE_125_RUS max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_125_RUS min_range should be 50.0")


func test_cw_autocannon_30_rus_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30_RUS"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_AUTOCANNON_30_RUS max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_30_RUS min_range should be 0.0")


func test_cw_autocannon_100_rus_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_100_RUS"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_AUTOCANNON_100_RUS max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_AUTOCANNON_100_RUS min_range should be 50.0")


func test_cw_hmg_kpvt_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG_KPVT"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_HMG_KPVT max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_HMG_KPVT min_range should be 0.0")


func test_cw_pkt_coax_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_PKT_COAX"]
	assert_eq(weapon.max_range_m, 1000.0, "CW_PKT_COAX max_range should be 1000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_PKT_COAX min_range should be 0.0")


func test_cw_kord_aa_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_KORD_AA"]
	assert_eq(weapon.max_range_m, 1500.0, "CW_KORD_AA max_range should be 1500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_KORD_AA min_range should be 0.0")


func test_cw_atgm_kornet_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KORNET"]
	assert_eq(weapon.max_range_m, 5500.0, "CW_ATGM_KORNET max_range should be 5500.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_KORNET min_range should be 100.0")


func test_cw_atgm_refleks_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_REFLEKS"]
	assert_eq(weapon.max_range_m, 5000.0, "CW_ATGM_REFLEKS max_range should be 5000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_REFLEKS min_range should be 100.0")


func test_cw_atgm_konkurs_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_KONKURS"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_ATGM_KONKURS max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 75.0, "CW_ATGM_KONKURS min_range should be 75.0")


func test_cw_atgm_bastion_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BASTION"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_ATGM_BASTION max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_BASTION min_range should be 100.0")


# =============================================================================
# 相対比較テスト
# =============================================================================

func test_cw_atgm_kornet_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_KORNET"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_KORNET should have significant pen_ce")


func test_cw_atgm_refleks_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_REFLEKS"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_REFLEKS should have significant pen_ce")


func test_cw_atgm_konkurs_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_KONKURS"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_KONKURS should have significant pen_ce")


func test_cw_atgm_bastion_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_BASTION"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_BASTION should have significant pen_ce")

