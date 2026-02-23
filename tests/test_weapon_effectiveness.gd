extends GutTest

## Comprehensive Weapon Effectiveness Tests
## Tests all weapon-target combinations for penetration probability
##
## Penetration formula: p_pen = sigmoid((P - A) / 15)
## Where P = weapon penetration, A = target armor
## Scale: 100 = 500mm RHA
##
## Penetration probability thresholds:
## - diff >= +30: ~88% (effective)
## - diff = 0: 50%
## - diff <= -30: ~12% (ineffective)

var WeaponDataClass: GDScript
var ElementDataClass: GDScript
var CombatSystemClass: GDScript
var ElementFactoryClass: GDScript
var VehicleCatalogClass: GDScript

# Constants for test thresholds
const PENETRATE_THRESHOLD := 0.75  # 75%+ = "can penetrate"
const NO_PENETRATE_THRESHOLD := 0.25  # 25%- = "cannot penetrate"


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	ElementDataClass = load("res://scripts/data/element_data.gd")
	CombatSystemClass = load("res://scripts/systems/combat_system.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")
	ElementFactoryClass.init_vehicle_catalog()


# =============================================================================
# Helper Functions
# =============================================================================

## Calculate penetration probability using sigmoid formula
func calc_pen_prob(penetration: int, armor: int) -> float:
	var diff := float(penetration - armor)
	var x := diff / 15.0  # PENETRATION_SIGMOID_SCALE
	return 1.0 / (1.0 + exp(-x))


## Get weapon from all weapons
func get_weapon(weapon_id: String) -> RefCounted:
	var weapons := WeaponDataClass.get_all_concrete_weapons()
	return weapons.get(weapon_id)


## Create target element with given archetype
func create_target(archetype: String, vehicle_id: String = "") -> RefCounted:
	if vehicle_id != "":
		return ElementFactoryClass.create_element_with_vehicle(
			vehicle_id, 1, Vector2.ZERO, 0.0
		)
	else:
		var arch = ElementDataClass.get_archetype(archetype)
		if arch:
			return ElementFactoryClass.create_element_from_archetype(arch, 1, Vector2.ZERO, 0.0)
		return null


# =============================================================================
# Test: MBT vs All Weapons (Front Armor = 140 KE, 140 CE)
# =============================================================================

func test_mbt_front_vs_tank_125mm_apfsds() -> void:
	# T-90M front (140 KE) vs DTC10-125 (160 KE at MID)
	# diff = 160 - 140 = +20 -> ~79% penetration
	var prob := calc_pen_prob(160, 140)
	assert_gt(prob, PENETRATE_THRESHOLD, "DTC10-125 should penetrate MBT front")


func test_mbt_front_vs_tank_120mm_apfsds() -> void:
	# MBT front (140 KE) vs M829A4 (150 KE at MID)
	# diff = 150 - 140 = +10 -> ~66% penetration
	var prob := calc_pen_prob(150, 140)
	assert_gt(prob, 0.5, "M829A4 should have >50% chance vs MBT front")


func test_mbt_front_vs_russian_125mm() -> void:
	# MBT front (140 KE) vs 3BM60 (140 KE at MID)
	# diff = 0 -> 50% penetration
	var prob := calc_pen_prob(140, 140)
	assert_almost_eq(prob, 0.5, 0.05, "3BM60 should have ~50% vs MBT front")


func test_mbt_front_vs_mango() -> void:
	# MBT front (140 KE) vs 3BM42 Mango (100 KE at MID)
	# diff = -40 -> ~7% penetration
	var prob := calc_pen_prob(100, 140)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "3BM42 Mango should NOT penetrate MBT front")


func test_mbt_front_vs_105mm_apfsds() -> void:
	# MBT front (140 KE) vs 105mm ZPL-151 (100 KE at MID)
	# diff = -40 -> ~7% penetration
	var prob := calc_pen_prob(100, 140)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "105mm should NOT penetrate MBT front")


func test_mbt_front_vs_30mm_autocannon() -> void:
	# MBT front (140 KE) vs 30mm (12 KE at MID)
	# diff = -128 -> ~0% penetration
	var prob := calc_pen_prob(12, 140)
	assert_lt(prob, 0.01, "30mm should NEVER penetrate MBT front")


func test_mbt_front_vs_small_arms() -> void:
	# MBT front vs 7.62mm/12.7mm - should be 0%
	# Small arms cannot penetrate armor_class >= 1
	var prob := calc_pen_prob(0, 140)
	assert_lt(prob, 0.01, "Small arms should NEVER penetrate MBT")


func test_mbt_front_vs_kornet_atgm() -> void:
	# MBT front (140 CE) vs Kornet (240 CE)
	# diff = +100 -> ~99.9% penetration
	var prob := calc_pen_prob(240, 140)
	assert_gt(prob, 0.99, "Kornet should always penetrate MBT front")


func test_mbt_front_vs_hj10_atgm() -> void:
	# MBT front (140 CE) vs HJ-10 (280 CE)
	# diff = +140 -> ~99.99% penetration
	var prob := calc_pen_prob(280, 140)
	assert_gt(prob, 0.99, "HJ-10 should always penetrate MBT front")


func test_mbt_front_vs_javelin() -> void:
	# MBT front (140 CE) vs Javelin (180 CE direct hit)
	# diff = +40 -> ~93% penetration
	var prob := calc_pen_prob(180, 140)
	assert_gt(prob, 0.9, "Javelin should penetrate MBT front")


func test_mbt_front_vs_rpg_heat() -> void:
	# MBT front (140 CE) vs RPG-7 (60 CE)
	# diff = -80 -> ~0.5% penetration
	var prob := calc_pen_prob(60, 140)
	assert_lt(prob, 0.01, "RPG should NOT penetrate MBT front")


# =============================================================================
# Test: MBT Side Armor (40 KE, 24 CE)
# =============================================================================

func test_mbt_side_vs_30mm_autocannon() -> void:
	# MBT side (40 KE) vs 30mm (12 KE at MID)
	# diff = -28 -> ~13% penetration
	var prob := calc_pen_prob(12, 40)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "30mm should struggle vs MBT side")


func test_mbt_side_vs_30mm_apfsds_near() -> void:
	# MBT side (40 KE) vs 30mm APFSDS at NEAR (14 KE)
	# diff = -26 -> ~15% penetration
	var prob := calc_pen_prob(14, 40)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "30mm APFSDS should still struggle vs MBT side at NEAR")


func test_mbt_side_vs_100mm_gun_launcher() -> void:
	# MBT side (24 CE) vs 100mm (120 CE)
	# diff = +96 -> ~99.8% penetration
	var prob := calc_pen_prob(120, 24)
	assert_gt(prob, 0.99, "100mm gun-launcher should penetrate MBT side")


func test_mbt_side_vs_rpg_heat() -> void:
	# MBT side (24 CE) vs RPG (60 CE)
	# diff = +36 -> ~92% penetration
	var prob := calc_pen_prob(60, 24)
	assert_gt(prob, 0.9, "RPG should penetrate MBT side")


func test_mbt_side_vs_hj73_legacy() -> void:
	# MBT side (24 CE) vs HJ-73 (85 CE)
	# diff = +61 -> ~98% penetration
	var prob := calc_pen_prob(85, 24)
	assert_gt(prob, 0.95, "HJ-73 should penetrate MBT side")


# =============================================================================
# Test: MBT Rear Armor (16 KE, 8 CE)
# =============================================================================

func test_mbt_rear_vs_30mm_autocannon() -> void:
	# MBT rear (16 KE) vs 30mm (12 KE at MID)
	# diff = -4 -> ~43% penetration
	var prob := calc_pen_prob(12, 16)
	assert_gt(prob, 0.3, "30mm should have chance vs MBT rear")
	assert_lt(prob, 0.6, "30mm should not reliably penetrate MBT rear")


func test_mbt_rear_vs_hmg_127mm() -> void:
	# MBT rear (16 KE) vs 12.7mm HMG (4 KE at MID)
	# diff = -12 -> ~31% penetration
	var prob := calc_pen_prob(4, 16)
	assert_lt(prob, 0.4, "12.7mm should struggle vs MBT rear")


func test_mbt_rear_vs_rpg_heat() -> void:
	# MBT rear (8 CE) vs RPG (60 CE)
	# diff = +52 -> ~97% penetration
	var prob := calc_pen_prob(60, 8)
	assert_gt(prob, 0.95, "RPG should always penetrate MBT rear")


# =============================================================================
# Test: IFV vs All Weapons (Front: 30 KE, 40 CE)
# =============================================================================

func test_ifv_front_vs_30mm_autocannon() -> void:
	# IFV front (30 KE) vs 30mm (12 KE at MID)
	# diff = -18 -> ~23% penetration
	var prob := calc_pen_prob(12, 30)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "30mm should struggle vs IFV front at range")


func test_ifv_front_vs_30mm_near() -> void:
	# IFV front (30 KE) vs 30mm at NEAR (14 KE)
	# diff = -16 -> ~26% penetration
	var prob := calc_pen_prob(14, 30)
	assert_gt(prob, 0.2, "30mm should have some chance vs IFV front at NEAR")


func test_ifv_front_vs_125mm_apfsds() -> void:
	# IFV front (30 KE) vs 125mm (140-160 KE)
	# diff = +110-130 -> ~99.9% penetration
	var prob := calc_pen_prob(140, 30)
	assert_gt(prob, 0.99, "125mm should always penetrate IFV")


func test_ifv_front_vs_hmg_145mm() -> void:
	# IFV front (30 KE) vs 14.5mm KPVT (8 KE at NEAR)
	# diff = -22 -> ~19% penetration
	var prob := calc_pen_prob(8, 30)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "14.5mm should NOT penetrate IFV front")


func test_ifv_front_vs_hmg_127mm() -> void:
	# IFV front (30 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = -25 -> ~16% penetration
	var prob := calc_pen_prob(5, 30)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "12.7mm should NOT penetrate IFV front")


func test_ifv_front_vs_rpg_heat() -> void:
	# IFV front (40 CE) vs RPG (60 CE)
	# diff = +20 -> ~79% penetration
	var prob := calc_pen_prob(60, 40)
	assert_gt(prob, PENETRATE_THRESHOLD, "RPG should penetrate IFV front")


func test_ifv_front_vs_atgm() -> void:
	# IFV front (40 CE) vs any ATGM (85+ CE)
	# diff = +45+ -> ~95%+ penetration
	var prob := calc_pen_prob(85, 40)
	assert_gt(prob, 0.9, "ATGM should always penetrate IFV")


# =============================================================================
# Test: IFV Side Armor (10 KE, 12 CE)
# =============================================================================

func test_ifv_side_vs_30mm_autocannon() -> void:
	# IFV side (10 KE) vs 30mm (12 KE at MID)
	# diff = +2 -> ~53% penetration
	var prob := calc_pen_prob(12, 10)
	assert_gt(prob, 0.5, "30mm should penetrate IFV side")


func test_ifv_side_vs_hmg_145mm() -> void:
	# IFV side (10 KE) vs 14.5mm KPVT (8 KE at NEAR)
	# diff = -2 -> ~47% penetration
	var prob := calc_pen_prob(8, 10)
	assert_gt(prob, 0.4, "14.5mm should have good chance vs IFV side")


func test_ifv_side_vs_hmg_127mm() -> void:
	# IFV side (10 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = -5 -> ~42% penetration
	var prob := calc_pen_prob(5, 10)
	assert_gt(prob, 0.35, "12.7mm should have chance vs IFV side")


func test_ifv_side_vs_rpg_heat() -> void:
	# IFV side (12 CE) vs RPG (60 CE)
	# diff = +48 -> ~96% penetration
	var prob := calc_pen_prob(60, 12)
	assert_gt(prob, 0.95, "RPG should always penetrate IFV side")


# =============================================================================
# Test: APC/Recon (Light Armor) vs Weapons (Front: 6 KE, 5 CE)
# =============================================================================

func test_apc_front_vs_hmg_127mm() -> void:
	# APC front (6 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = -1 -> ~48% penetration
	var prob := calc_pen_prob(5, 6)
	assert_gt(prob, 0.4, "12.7mm should have chance vs APC front")


func test_apc_front_vs_hmg_127mm_mid() -> void:
	# APC front (6 KE) vs 12.7mm HMG (4 KE at MID)
	# diff = -2 -> ~47% penetration
	var prob := calc_pen_prob(4, 6)
	assert_gt(prob, 0.4, "12.7mm should still threaten APC at MID range")


func test_apc_front_vs_30mm_autocannon() -> void:
	# APC front (6 KE) vs 30mm (12 KE at MID)
	# diff = +6 -> ~60% penetration
	var prob := calc_pen_prob(12, 6)
	assert_gt(prob, 0.55, "30mm should penetrate APC front")


func test_apc_front_vs_small_arms_762mm() -> void:
	# APC front (6 KE) should resist small arms
	# 7.62mm has no pen_ke value (treated as 0)
	var prob := calc_pen_prob(0, 6)
	assert_lt(prob, 0.4, "7.62mm should NOT penetrate APC front")


func test_apc_front_vs_rpg_heat() -> void:
	# APC front (5 CE) vs RPG (60 CE)
	# diff = +55 -> ~98% penetration
	var prob := calc_pen_prob(60, 5)
	assert_gt(prob, 0.95, "RPG should always penetrate APC")


func test_apc_side_vs_hmg_127mm() -> void:
	# APC side (3 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = +2 -> ~53% penetration
	var prob := calc_pen_prob(5, 3)
	assert_gt(prob, 0.5, "12.7mm should penetrate APC side")


# =============================================================================
# Test: Light Tank vs Weapons (Front: 60 KE, 70 CE)
# =============================================================================

func test_light_tank_front_vs_30mm_autocannon() -> void:
	# Light tank front (60 KE) vs 30mm (12 KE at MID)
	# diff = -48 -> ~4% penetration
	var prob := calc_pen_prob(12, 60)
	assert_lt(prob, 0.1, "30mm should NOT penetrate light tank front")


func test_light_tank_front_vs_105mm_apfsds() -> void:
	# Light tank front (60 KE) vs 105mm (100 KE at MID)
	# diff = +40 -> ~93% penetration
	var prob := calc_pen_prob(100, 60)
	assert_gt(prob, 0.9, "105mm should penetrate light tank front")


func test_light_tank_front_vs_125mm_apfsds() -> void:
	# Light tank front (60 KE) vs 125mm (140-160 KE)
	# diff = +80-100 -> ~99.5%+ penetration
	var prob := calc_pen_prob(140, 60)
	assert_gt(prob, 0.99, "125mm should always penetrate light tank front")


func test_light_tank_front_vs_rpg_heat() -> void:
	# Light tank front (70 CE) vs RPG (60 CE)
	# diff = -10 -> ~34% penetration
	var prob := calc_pen_prob(60, 70)
	assert_lt(prob, 0.5, "RPG should struggle vs light tank front")


func test_light_tank_front_vs_atgm_kornet() -> void:
	# Light tank front (70 CE) vs Kornet (240 CE)
	# diff = +170 -> ~99.99% penetration
	var prob := calc_pen_prob(240, 70)
	assert_gt(prob, 0.99, "Kornet should always penetrate light tank")


func test_light_tank_side_vs_30mm_autocannon() -> void:
	# Light tank side (20 KE) vs 30mm (12 KE at MID)
	# diff = -8 -> ~37% penetration
	var prob := calc_pen_prob(12, 20)
	assert_gt(prob, 0.3, "30mm should have chance vs light tank side")


# =============================================================================
# Test: SP Artillery (Front: 12 KE, 10 CE)
# =============================================================================

func test_sp_arty_front_vs_30mm_autocannon() -> void:
	# SP Arty front (12 KE) vs 30mm (12 KE at MID)
	# diff = 0 -> 50% penetration
	var prob := calc_pen_prob(12, 12)
	assert_almost_eq(prob, 0.5, 0.05, "30mm should have 50% vs SP Arty front")


func test_sp_arty_front_vs_hmg_127mm() -> void:
	# SP Arty front (12 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = -7 -> ~38% penetration
	var prob := calc_pen_prob(5, 12)
	assert_lt(prob, 0.45, "12.7mm should struggle vs SP Arty front")


func test_sp_arty_front_vs_rpg_heat() -> void:
	# SP Arty front (10 CE) vs RPG (60 CE)
	# diff = +50 -> ~96% penetration
	var prob := calc_pen_prob(60, 10)
	assert_gt(prob, 0.95, "RPG should penetrate SP Arty")


# =============================================================================
# Test: AA Systems (Front: 14 KE, 12 CE)
# =============================================================================

func test_aa_front_vs_30mm_autocannon() -> void:
	# SPAAG front (14 KE) vs 30mm (12 KE at MID)
	# diff = -2 -> ~47% penetration
	var prob := calc_pen_prob(12, 14)
	assert_gt(prob, 0.4, "30mm should have chance vs AA front")


func test_aa_front_vs_hmg_127mm() -> void:
	# SPAAG front (14 KE) vs 12.7mm HMG (5 KE at NEAR)
	# diff = -9 -> ~35% penetration
	var prob := calc_pen_prob(5, 14)
	assert_lt(prob, 0.4, "12.7mm should struggle vs AA front")


# =============================================================================
# Test: Specific Vehicle Combat Scenarios
# =============================================================================

func test_type99a_vs_m1a2sepv3_front() -> void:
	# Type 99A DTC10 (160 KE) vs M1A2 front (assume 140 KE base + ERA)
	# Even with ERA bonus, DTC10 should have good penetration chance
	var prob := calc_pen_prob(160, 155)  # Assume ERA adds ~15
	assert_gt(prob, 0.5, "Type 99A should contest M1A2 front")


func test_t90m_vs_type99a_front() -> void:
	# T-90M 3BM60 (140 KE) vs Type 99A front (assume 145 KE with ERA)
	var prob := calc_pen_prob(140, 145)
	assert_gt(prob, 0.4, "T-90M should have chance vs Type 99A front")


func test_m1a2_vs_t90m_front() -> void:
	# M1A2 M829A4 (150 KE) vs T-90M front (assume 150 KE with Relikt ERA)
	var prob := calc_pen_prob(150, 150)
	assert_almost_eq(prob, 0.5, 0.05, "M1A2 vs T-90M should be 50/50 front")


func test_bradley_vs_bmp3_front() -> void:
	# M2A4 25mm Bushmaster (10 KE at MID) vs BMP-3 front (30 KE)
	# diff = -20 -> ~21% penetration
	var prob := calc_pen_prob(10, 30)
	assert_lt(prob, NO_PENETRATE_THRESHOLD, "25mm should NOT penetrate BMP-3 front")


func test_bmp3_vs_bradley_side() -> void:
	# BMP-3 30mm 2A72 (12 KE at MID) vs Bradley side (10 KE)
	# diff = +2 -> ~53% penetration
	var prob := calc_pen_prob(12, 10)
	assert_gt(prob, 0.5, "30mm should penetrate Bradley side")


func test_zbd04a_vs_btr82a_front() -> void:
	# ZBD-04A 30mm ZPT-99 (12 KE at MID) vs BTR-82A front (8 KE)
	# diff = +4 -> ~57% penetration
	var prob := calc_pen_prob(12, 8)
	assert_gt(prob, 0.55, "ZPT-99 should penetrate BTR-82A front")


# =============================================================================
# Test: ATGM Effectiveness Matrix
# =============================================================================

func test_atgm_effectiveness_vs_mbt_front() -> void:
	# Test all ATGMs vs MBT front (140 CE)
	var mbt_front_ce := 140

	# HJ-10 (280 CE) - should always penetrate
	assert_gt(calc_pen_prob(280, mbt_front_ce), 0.99, "HJ-10 vs MBT front")

	# Kornet (240 CE) - should always penetrate
	assert_gt(calc_pen_prob(240, mbt_front_ce), 0.99, "Kornet vs MBT front")

	# HJ-9 (240 CE) - should always penetrate
	assert_gt(calc_pen_prob(240, mbt_front_ce), 0.99, "HJ-9 vs MBT front")

	# HJ-8E (200 CE) - should penetrate
	assert_gt(calc_pen_prob(200, mbt_front_ce), 0.95, "HJ-8E vs MBT front")

	# Javelin (180 CE) - should penetrate
	assert_gt(calc_pen_prob(180, mbt_front_ce), 0.9, "Javelin vs MBT front")

	# Refleks (180 CE) - should penetrate
	assert_gt(calc_pen_prob(180, mbt_front_ce), 0.9, "Refleks vs MBT front")

	# GP105 (140 CE) - 50/50
	assert_almost_eq(calc_pen_prob(140, mbt_front_ce), 0.5, 0.05, "GP105 vs MBT front")

	# HJ-73 (85 CE) - should struggle
	assert_lt(calc_pen_prob(85, mbt_front_ce), 0.05, "HJ-73 vs MBT front")


func test_atgm_effectiveness_vs_ifv_front() -> void:
	# Test all ATGMs vs IFV front (40 CE)
	var ifv_front_ce := 40

	# All ATGMs should penetrate IFV
	assert_gt(calc_pen_prob(85, ifv_front_ce), 0.9, "HJ-73 vs IFV front")
	assert_gt(calc_pen_prob(140, ifv_front_ce), 0.99, "GP105 vs IFV front")
	assert_gt(calc_pen_prob(180, ifv_front_ce), 0.99, "Javelin vs IFV front")
	assert_gt(calc_pen_prob(240, ifv_front_ce), 0.99, "Kornet vs IFV front")
	assert_gt(calc_pen_prob(280, ifv_front_ce), 0.99, "HJ-10 vs IFV front")


# =============================================================================
# Test: Tank Gun Hierarchy
# =============================================================================

func test_tank_gun_hierarchy_vs_mbt() -> void:
	# Test penetration hierarchy: DTC10 > M829A4 > 3BM60 > DTW-125 II > Mango > 105mm
	var mbt_front_ke := 140

	var dtc10_prob := calc_pen_prob(160, mbt_front_ke)
	var m829a4_prob := calc_pen_prob(150, mbt_front_ke)
	var bm60_prob := calc_pen_prob(140, mbt_front_ke)
	var dtw125ii_prob := calc_pen_prob(140, mbt_front_ke)
	var mango_prob := calc_pen_prob(100, mbt_front_ke)
	var mm105_prob := calc_pen_prob(100, mbt_front_ke)

	assert_gt(dtc10_prob, m829a4_prob, "DTC10 > M829A4")
	assert_gt(m829a4_prob, bm60_prob, "M829A4 > 3BM60")
	assert_gt(bm60_prob, mango_prob, "3BM60 > Mango")
	assert_almost_eq(mango_prob, mm105_prob, 0.01, "Mango ≈ 105mm")


# =============================================================================
# Test: Autocannon Effectiveness by Range
# =============================================================================

func test_30mm_effectiveness_by_range() -> void:
	# 30mm vs IFV front (30 KE)
	var ifv_front_ke := 30

	# NEAR (14 KE): diff = -16 -> ~26%
	var near_prob := calc_pen_prob(14, ifv_front_ke)
	# MID (12 KE): diff = -18 -> ~23%
	var mid_prob := calc_pen_prob(12, ifv_front_ke)
	# FAR (8 KE): diff = -22 -> ~19%
	var far_prob := calc_pen_prob(8, ifv_front_ke)

	assert_gt(near_prob, mid_prob, "30mm better at NEAR")
	assert_gt(mid_prob, far_prob, "30mm worse at FAR")


func test_35mm_effectiveness() -> void:
	# 35mm vs IFV front (30 KE) at NEAR (18 KE)
	# diff = -12 -> ~31%
	var prob := calc_pen_prob(18, 30)
	assert_gt(prob, 0.25, "35mm should threaten IFV front at close range")


# =============================================================================
# Test: Machine Gun Effectiveness
# =============================================================================

func test_hmg_127mm_vs_targets() -> void:
	# 12.7mm HMG (5 KE at NEAR, 4 KE at MID)

	# vs APC (6 KE) - marginal
	assert_gt(calc_pen_prob(5, 6), 0.4, "12.7mm vs APC front")
	assert_gt(calc_pen_prob(5, 3), 0.5, "12.7mm vs APC side")

	# vs IFV (30 KE) - no chance
	assert_lt(calc_pen_prob(5, 30), 0.2, "12.7mm vs IFV front")

	# vs MBT (140 KE) - impossible
	assert_lt(calc_pen_prob(5, 140), 0.01, "12.7mm vs MBT")


func test_hmg_145mm_kpvt_vs_targets() -> void:
	# 14.5mm KPVT (8 KE at NEAR, 6 KE at MID)

	# vs APC (6 KE) - good
	assert_gt(calc_pen_prob(8, 6), 0.5, "14.5mm vs APC front")

	# vs IFV side (10 KE) - marginal
	assert_gt(calc_pen_prob(8, 10), 0.4, "14.5mm vs IFV side")

	# vs IFV front (30 KE) - no
	assert_lt(calc_pen_prob(8, 30), 0.2, "14.5mm vs IFV front")


# =============================================================================
# Test: Summary - What Can/Cannot Penetrate MBT Front
# =============================================================================

func test_summary_can_penetrate_mbt_front() -> void:
	var mbt_front := 140

	# These SHOULD penetrate MBT front (>75%)
	assert_gt(calc_pen_prob(280, mbt_front), 0.75, "HJ-10 can pen MBT front")
	assert_gt(calc_pen_prob(240, mbt_front), 0.75, "Kornet can pen MBT front")
	assert_gt(calc_pen_prob(200, mbt_front), 0.75, "HJ-8E can pen MBT front")
	assert_gt(calc_pen_prob(180, mbt_front), 0.75, "Javelin can pen MBT front")
	assert_gt(calc_pen_prob(160, mbt_front), 0.75, "DTC10-125 can pen MBT front")


func test_summary_cannot_penetrate_mbt_front() -> void:
	var mbt_front := 140

	# These CANNOT penetrate MBT front (<25%)
	assert_lt(calc_pen_prob(100, mbt_front), 0.25, "Mango cannot pen MBT front")
	assert_lt(calc_pen_prob(85, mbt_front), 0.25, "HJ-73 cannot pen MBT front")
	assert_lt(calc_pen_prob(60, mbt_front), 0.25, "RPG cannot pen MBT front")
	assert_lt(calc_pen_prob(12, mbt_front), 0.01, "30mm cannot pen MBT front")
	assert_lt(calc_pen_prob(5, mbt_front), 0.01, "12.7mm cannot pen MBT front")


# =============================================================================
# Test: What Threatens Each Target Class
# =============================================================================

func test_what_threatens_mbt() -> void:
	# MBT front (140 KE/CE)
	# Effective threats: Modern ATGMs, Top-tier tank guns

	# Front: Only best weapons
	assert_gt(calc_pen_prob(160, 140), 0.5, "DTC10 threatens MBT front")
	assert_gt(calc_pen_prob(150, 140), 0.5, "M829A4 threatens MBT front")

	# Side: More options
	assert_gt(calc_pen_prob(60, 24), 0.9, "RPG threatens MBT side")
	assert_gt(calc_pen_prob(85, 24), 0.9, "Even HJ-73 threatens MBT side")

	# Rear: Even autocannons
	assert_gt(calc_pen_prob(12, 16), 0.4, "30mm threatens MBT rear")


func test_what_threatens_ifv() -> void:
	# IFV front (30 KE, 40 CE)

	# AT weapons
	assert_gt(calc_pen_prob(60, 40), 0.75, "RPG threatens IFV front")
	assert_gt(calc_pen_prob(85, 40), 0.9, "ATGM threatens IFV front")

	# Tank guns
	assert_gt(calc_pen_prob(100, 30), 0.99, "105mm threatens IFV")
	assert_gt(calc_pen_prob(140, 30), 0.99, "125mm overkill vs IFV")

	# Autocannons on side
	assert_gt(calc_pen_prob(12, 10), 0.5, "30mm threatens IFV side")


func test_what_threatens_apc() -> void:
	# APC front (6 KE, 5 CE)

	# Nearly everything threatens APC
	assert_gt(calc_pen_prob(5, 6), 0.4, "12.7mm threatens APC")
	assert_gt(calc_pen_prob(12, 6), 0.6, "30mm easily penetrates APC")
	assert_gt(calc_pen_prob(60, 5), 0.98, "RPG always penetrates APC")
