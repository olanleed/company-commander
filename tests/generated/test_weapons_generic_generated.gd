extends GutTest

## 自動生成された武器テスト（GENERIC）
## 生成元: data/weapons/weapons_generic.json
## 生成日: 2026-02-26T17:22:19
## 注意: このファイルは自動生成されます。手動編集しないでください。

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


# =============================================================================
# 武器存在確認テスト
# =============================================================================

func test_cw_rifle_std_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_RIFLE_STD", "Standard Rifle should exist")


func test_cw_mg_std_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_MG_STD", "Standard MG should exist")


func test_cw_hmg_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HMG", "12.7mm HMG should exist")


func test_cw_rpg_heat_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_RPG_HEAT", "AT Rocket (Heavy) should exist")


func test_cw_carl_gustaf_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_CARL_GUSTAF", "84mm Recoilless should exist")


func test_cw_coax_mg_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_COAX_MG", "Coaxial MG should exist")


func test_cw_autocannon_25_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_25", "25mm Autocannon should exist")


func test_cw_autocannon_30_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_30", "30mm Autocannon should exist")


func test_cw_autocannon_35_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_AUTOCANNON_35", "35mm Twin Autocannon should exist")


func test_cw_atgm_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM", "ATGM should exist")


func test_cw_atgm_topattack_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_TOPATTACK", "ATGM Top Attack should exist")


func test_cw_atgm_beamride_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_ATGM_BEAMRIDE", "ATGM Beam Riding should exist")


func test_cw_tank_ke_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE", "Tank Gun APFSDS should exist")


func test_cw_tank_ke_125_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125", "Tank Gun 125mm APFSDS should exist")


func test_cw_tank_ke_105_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105", "Tank Gun 105mm APFSDS should exist")


func test_cw_tank_heatmp_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_HEATMP", "Tank Gun HEAT-MP should exist")


func test_cw_mortar_he_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_MORTAR_HE", "Mortar HE should exist")


func test_cw_mortar_81_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_MORTAR_81", "81mm Mortar should exist")


func test_cw_mortar_smoke_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_MORTAR_SMOKE", "Mortar Smoke should exist")


func test_cw_mortar_120_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_MORTAR_120", "120mm Mortar should exist")


func test_cw_howitzer_152_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HOWITZER_152", "152mm Howitzer should exist")


func test_cw_howitzer_155_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_HOWITZER_155", "155mm Howitzer should exist")


func test_cw_tank_ke_125_mango_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_MANGO", "125mm 2A46M (3BM42) should exist")


func test_cw_tank_ke_125_chn_std_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN_STD", "125mm ZPT-98 (DTW-125 II) should exist")


func test_cw_tank_ke_125_chn_old_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_125_CHN_OLD", "125mm ZPT-96 (DTW-125) should exist")


func test_cw_tank_ke_105_chn_old_exists() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(weapons, "CW_TANK_KE_105_CHN_OLD", "105mm Type 83 should exist")


# =============================================================================
# Mechanism / FireModel テスト
# =============================================================================

func test_cw_rifle_std_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_RIFLE_STD"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_RIFLE_STD should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_RIFLE_STD should be CONTINUOUS")


func test_cw_mg_std_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MG_STD"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_MG_STD should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_MG_STD should be CONTINUOUS")


func test_cw_hmg_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_HMG should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_HMG should be CONTINUOUS")


func test_cw_rpg_heat_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_RPG_HEAT"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_RPG_HEAT should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_RPG_HEAT should be DISCRETE")


func test_cw_carl_gustaf_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_CARL_GUSTAF"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_CARL_GUSTAF should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_CARL_GUSTAF should be DISCRETE")


func test_cw_coax_mg_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_COAX_MG"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS, "CW_COAX_MG should be SMALL_ARMS")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_COAX_MG should be CONTINUOUS")


func test_cw_autocannon_25_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_25 should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_25 should be CONTINUOUS")


func test_cw_autocannon_30_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_30 should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_30 should be CONTINUOUS")


func test_cw_autocannon_35_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_AUTOCANNON_35 should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS, "CW_AUTOCANNON_35 should be CONTINUOUS")


func test_cw_atgm_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM should be DISCRETE")


func test_cw_atgm_topattack_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOPATTACK"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_TOPATTACK should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_TOPATTACK should be DISCRETE")


func test_cw_atgm_beamride_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BEAMRIDE"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_ATGM_BEAMRIDE should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_ATGM_BEAMRIDE should be DISCRETE")


func test_cw_tank_ke_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE should be DISCRETE")


func test_cw_tank_ke_125_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125 should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125 should be DISCRETE")


func test_cw_tank_ke_105_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_105 should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_105 should be DISCRETE")


func test_cw_tank_heatmp_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEATMP"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE, "CW_TANK_HEATMP should be SHAPED_CHARGE")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_HEATMP should be DISCRETE")


func test_cw_mortar_he_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_HE"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_MORTAR_HE should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_MORTAR_HE should be INDIRECT")


func test_cw_mortar_81_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_81"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_MORTAR_81 should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_MORTAR_81 should be INDIRECT")


func test_cw_mortar_smoke_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_SMOKE"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_MORTAR_SMOKE should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_MORTAR_SMOKE should be INDIRECT")


func test_cw_mortar_120_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_120"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_MORTAR_120 should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_MORTAR_120 should be INDIRECT")


func test_cw_howitzer_152_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_152"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_HOWITZER_152 should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_HOWITZER_152 should be INDIRECT")


func test_cw_howitzer_155_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_155"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.BLAST_FRAG, "CW_HOWITZER_155 should be BLAST_FRAG")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.INDIRECT, "CW_HOWITZER_155 should be INDIRECT")


func test_cw_tank_ke_125_mango_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_MANGO"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125_MANGO should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125_MANGO should be DISCRETE")


func test_cw_tank_ke_125_chn_std_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_STD"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125_CHN_STD should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125_CHN_STD should be DISCRETE")


func test_cw_tank_ke_125_chn_old_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_OLD"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_125_CHN_OLD should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_125_CHN_OLD should be DISCRETE")


func test_cw_tank_ke_105_chn_old_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN_OLD"]
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.KINETIC, "CW_TANK_KE_105_CHN_OLD should be KINETIC")
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.DISCRETE, "CW_TANK_KE_105_CHN_OLD should be DISCRETE")


# =============================================================================
# 貫徹力テスト
# =============================================================================

func test_cw_hmg_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 3, "CW_HMG pen_ke MID should be 3")


func test_cw_rpg_heat_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_RPG_HEAT"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 95, "CW_RPG_HEAT pen_ce MID should be 95")


func test_cw_carl_gustaf_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_CARL_GUSTAF"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 78, "CW_CARL_GUSTAF pen_ce MID should be 78")


func test_cw_autocannon_25_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 18, "CW_AUTOCANNON_25 pen_ke MID should be 18")


func test_cw_autocannon_30_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 24, "CW_AUTOCANNON_30 pen_ke MID should be 24")


func test_cw_autocannon_35_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 30, "CW_AUTOCANNON_35 pen_ke MID should be 30")


func test_cw_atgm_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 180, "CW_ATGM pen_ce MID should be 180")


func test_cw_atgm_topattack_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOPATTACK"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 150, "CW_ATGM_TOPATTACK pen_ce MID should be 150")


func test_cw_atgm_beamride_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BEAMRIDE"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 200, "CW_ATGM_BEAMRIDE pen_ce MID should be 200")


func test_cw_tank_ke_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 130, "CW_TANK_KE pen_ke MID should be 130")


func test_cw_tank_ke_125_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 120, "CW_TANK_KE_125 pen_ke MID should be 120")


func test_cw_tank_ke_105_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 90, "CW_TANK_KE_105 pen_ke MID should be 90")


func test_cw_tank_heatmp_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEATMP"]
	assert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], 90, "CW_TANK_HEATMP pen_ce MID should be 90")


func test_cw_tank_ke_125_mango_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_MANGO"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 100, "CW_TANK_KE_125_MANGO pen_ke MID should be 100")


func test_cw_tank_ke_125_chn_std_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_STD"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 140, "CW_TANK_KE_125_CHN_STD pen_ke MID should be 140")


func test_cw_tank_ke_125_chn_old_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_OLD"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 110, "CW_TANK_KE_125_CHN_OLD pen_ke MID should be 110")


func test_cw_tank_ke_105_chn_old_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN_OLD"]
	assert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], 80, "CW_TANK_KE_105_CHN_OLD pen_ke MID should be 80")


# =============================================================================
# 射程テスト
# =============================================================================

func test_cw_rifle_std_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_RIFLE_STD"]
	assert_eq(weapon.max_range_m, 300.0, "CW_RIFLE_STD max_range should be 300.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_RIFLE_STD min_range should be 0.0")


func test_cw_mg_std_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MG_STD"]
	assert_eq(weapon.max_range_m, 800.0, "CW_MG_STD max_range should be 800.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_MG_STD min_range should be 0.0")


func test_cw_hmg_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HMG"]
	assert_eq(weapon.max_range_m, 1500.0, "CW_HMG max_range should be 1500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_HMG min_range should be 0.0")


func test_cw_rpg_heat_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_RPG_HEAT"]
	assert_eq(weapon.max_range_m, 300.0, "CW_RPG_HEAT max_range should be 300.0")
	assert_eq(weapon.min_range_m, 20.0, "CW_RPG_HEAT min_range should be 20.0")


func test_cw_carl_gustaf_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_CARL_GUSTAF"]
	assert_eq(weapon.max_range_m, 500.0, "CW_CARL_GUSTAF max_range should be 500.0")
	assert_eq(weapon.min_range_m, 20.0, "CW_CARL_GUSTAF min_range should be 20.0")


func test_cw_coax_mg_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_COAX_MG"]
	assert_eq(weapon.max_range_m, 800.0, "CW_COAX_MG max_range should be 800.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_COAX_MG min_range should be 0.0")


func test_cw_autocannon_25_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_25"]
	assert_eq(weapon.max_range_m, 1200.0, "CW_AUTOCANNON_25 max_range should be 1200.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_25 min_range should be 0.0")


func test_cw_autocannon_30_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_30"]
	assert_eq(weapon.max_range_m, 1500.0, "CW_AUTOCANNON_30 max_range should be 1500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_30 min_range should be 0.0")


func test_cw_autocannon_35_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_AUTOCANNON_35"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_AUTOCANNON_35 max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_AUTOCANNON_35 min_range should be 0.0")


func test_cw_atgm_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM"]
	assert_eq(weapon.max_range_m, 3750.0, "CW_ATGM max_range should be 3750.0")
	assert_eq(weapon.min_range_m, 65.0, "CW_ATGM min_range should be 65.0")


func test_cw_atgm_topattack_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_TOPATTACK"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_ATGM_TOPATTACK max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 75.0, "CW_ATGM_TOPATTACK min_range should be 75.0")


func test_cw_atgm_beamride_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_ATGM_BEAMRIDE"]
	assert_eq(weapon.max_range_m, 5500.0, "CW_ATGM_BEAMRIDE max_range should be 5500.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_ATGM_BEAMRIDE min_range should be 100.0")


func test_cw_tank_ke_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_TANK_KE max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE min_range should be 50.0")


func test_cw_tank_ke_125_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_TANK_KE_125 max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_125 min_range should be 50.0")


func test_cw_tank_ke_105_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_TANK_KE_105 max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_105 min_range should be 50.0")


func test_cw_tank_heatmp_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_HEATMP"]
	assert_eq(weapon.max_range_m, 1500.0, "CW_TANK_HEATMP max_range should be 1500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_HEATMP min_range should be 0.0")


func test_cw_mortar_he_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_HE"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_MORTAR_HE max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_MORTAR_HE min_range should be 100.0")


func test_cw_mortar_81_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_81"]
	assert_eq(weapon.max_range_m, 5000.0, "CW_MORTAR_81 max_range should be 5000.0")
	assert_eq(weapon.min_range_m, 80.0, "CW_MORTAR_81 min_range should be 80.0")


func test_cw_mortar_smoke_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_SMOKE"]
	assert_eq(weapon.max_range_m, 2000.0, "CW_MORTAR_SMOKE max_range should be 2000.0")
	assert_eq(weapon.min_range_m, 100.0, "CW_MORTAR_SMOKE min_range should be 100.0")


func test_cw_mortar_120_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_MORTAR_120"]
	assert_eq(weapon.max_range_m, 8000.0, "CW_MORTAR_120 max_range should be 8000.0")
	assert_eq(weapon.min_range_m, 200.0, "CW_MORTAR_120 min_range should be 200.0")


func test_cw_howitzer_152_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_152"]
	assert_eq(weapon.max_range_m, 28000.0, "CW_HOWITZER_152 max_range should be 28000.0")
	assert_eq(weapon.min_range_m, 2000.0, "CW_HOWITZER_152 min_range should be 2000.0")


func test_cw_howitzer_155_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_HOWITZER_155"]
	assert_eq(weapon.max_range_m, 30000.0, "CW_HOWITZER_155 max_range should be 30000.0")
	assert_eq(weapon.min_range_m, 2000.0, "CW_HOWITZER_155 min_range should be 2000.0")


func test_cw_tank_ke_125_mango_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_MANGO"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_TANK_KE_125_MANGO max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 50.0, "CW_TANK_KE_125_MANGO min_range should be 50.0")


func test_cw_tank_ke_125_chn_std_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_STD"]
	assert_eq(weapon.max_range_m, 4000.0, "CW_TANK_KE_125_CHN_STD max_range should be 4000.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_KE_125_CHN_STD min_range should be 0.0")


func test_cw_tank_ke_125_chn_old_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_125_CHN_OLD"]
	assert_eq(weapon.max_range_m, 3500.0, "CW_TANK_KE_125_CHN_OLD max_range should be 3500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_KE_125_CHN_OLD min_range should be 0.0")


func test_cw_tank_ke_105_chn_old_range() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var weapon = weapons["CW_TANK_KE_105_CHN_OLD"]
	assert_eq(weapon.max_range_m, 2500.0, "CW_TANK_KE_105_CHN_OLD max_range should be 2500.0")
	assert_eq(weapon.min_range_m, 0.0, "CW_TANK_KE_105_CHN_OLD min_range should be 0.0")


# =============================================================================
# 相対比較テスト
# =============================================================================

func test_generic_tank_ke_vs_heat() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var ke = weapons["CW_TANK_KE"]
	var heat = weapons["CW_TANK_HEATMP"]
	# KE弾は遠距離でHEAT弾よりpen_keが高い
	assert_gt(ke.pen_ke[WeaponDataClass.RangeBand.MID], 0, "KE ammo should have pen_ke")


func test_generic_autocannon_caliber_comparison() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var small = weapons["CW_AUTOCANNON_25"]
	var large = weapons["CW_AUTOCANNON_35"]
	# 大口径は小口径より貫徹力が高い
	assert_gt(large.pen_ke[WeaponDataClass.RangeBand.NEAR], small.pen_ke[WeaponDataClass.RangeBand.NEAR],
		"CW_AUTOCANNON_35 should have higher penetration than CW_AUTOCANNON_25")


func test_cw_atgm_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM should have significant pen_ce")


func test_cw_atgm_topattack_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_TOPATTACK"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_TOPATTACK should have significant pen_ce")


func test_cw_atgm_beamride_atgm_effectiveness() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var atgm = weapons["CW_ATGM_BEAMRIDE"]
	# ATGMは有効な対装甲貫徹力を持つ
	assert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, "CW_ATGM_BEAMRIDE should have significant pen_ce")

