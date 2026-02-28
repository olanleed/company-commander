extends GutTest

## トップアタックミサイルのテスト
## 仕様:
## - Javelin, 01LMAT, MMPM等のトップアタックミサイルは装甲上面を攻撃
## - 装甲上面（TOP）は非常に薄いため、貫通確率が高い
## - DIRECT攻撃の場合は通常のアスペクト計算を使用

const CombatSystem := preload("res://scripts/systems/combat_system.gd")
const ElementData := preload("res://scripts/data/element_data.gd")
const WeaponData := preload("res://scripts/data/weapon_data.gd")
const MissileData := preload("res://scripts/data/missile_data.gd")
const GameEnums := preload("res://scripts/core/game_enums.gd")

var combat_system: CombatSystem


func before_each() -> void:
	combat_system = CombatSystem.new()


func after_each() -> void:
	combat_system = null


# =============================================================================
# ヘルパー
# =============================================================================

func _create_mock_tank() -> ElementData.ElementInstance:
	# 装甲データ（MBT相当）
	var element_type := ElementData.ElementType.new()
	element_type.id = "TANK_PLT"
	element_type.display_name = "Tank Platoon"
	element_type.category = ElementData.Category.VEH
	element_type.max_strength = 4
	element_type.armor_class = 3
	element_type.armor_ke = {
		WeaponData.ArmorZone.FRONT: 140,
		WeaponData.ArmorZone.SIDE: 40,
		WeaponData.ArmorZone.REAR: 16,
		WeaponData.ArmorZone.TOP: 6  # トップアタックに弱い
	}
	element_type.armor_ce = {
		WeaponData.ArmorZone.FRONT: 140,
		WeaponData.ArmorZone.SIDE: 24,
		WeaponData.ArmorZone.REAR: 8,
		WeaponData.ArmorZone.TOP: 4  # HEAT対策なし
	}

	var tank := ElementData.ElementInstance.new(element_type)
	tank.id = "TANK_001"
	tank.position = Vector2(1000, 1000)
	tank.facing = 0.0
	tank.faction = GameEnums.Faction.RED
	tank.state = GameEnums.UnitState.ACTIVE
	tank.current_strength = 4
	tank.suppression = 0.0
	tank.is_destroyed = false
	tank.mobility_hp = 100.0
	tank.firepower_hp = 100.0

	return tank


func _create_mock_shooter() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "IFV_PLT"
	element_type.category = ElementData.Category.VEH
	element_type.max_strength = 4

	var shooter := ElementData.ElementInstance.new(element_type)
	shooter.id = "IFV_001"
	shooter.position = Vector2(0, 1000)  # 1000m離れた位置
	shooter.facing = 0.0
	shooter.faction = GameEnums.Faction.BLUE
	shooter.state = GameEnums.UnitState.ACTIVE
	shooter.current_strength = 4
	shooter.suppression = 0.0
	shooter.is_destroyed = false
	shooter.is_moving = false

	return shooter


func _create_javelin_profile() -> MissileData.MissileProfile:
	var profile := MissileData.MissileProfile.new()
	profile.id = "MSL_JAVELIN"
	profile.display_name = "FGM-148 Javelin"
	profile.guidance_type = MissileData.GuidanceType.IIR_HOMING
	profile.lock_mode = MissileData.LockMode.LOBL
	profile.speed_mps = 140.0
	profile.max_range_m = 2500.0
	profile.min_range_m = 65.0
	profile.default_attack_profile = MissileData.AttackProfile.TOP_ATTACK
	profile.available_profiles = [
		MissileData.AttackProfile.DIRECT,
		MissileData.AttackProfile.TOP_ATTACK
	]
	profile.penetration_ce = 160  # タンデム弾頭
	profile.shooter_constrained = false
	return profile


# =============================================================================
# テスト: 装甲アスペクト取得
# =============================================================================

func test_get_armor_at_aspect_top() -> void:
	## TOP面の装甲値を正しく取得
	var tank := _create_mock_tank()

	var armor_ke := combat_system.get_armor_at_aspect(tank, WeaponData.ArmorZone.TOP, true)
	var armor_ce := combat_system.get_armor_at_aspect(tank, WeaponData.ArmorZone.TOP, false)

	assert_eq(armor_ke, 6, "TOP KE armor should be 6")
	assert_eq(armor_ce, 4, "TOP CE armor should be 4")


func test_get_armor_front_vs_top() -> void:
	## FRONT装甲とTOP装甲の差を確認（TOP << FRONT）
	var tank := _create_mock_tank()

	var front_ce := combat_system.get_armor_at_aspect(tank, WeaponData.ArmorZone.FRONT, false)
	var top_ce := combat_system.get_armor_at_aspect(tank, WeaponData.ArmorZone.TOP, false)

	assert_true(top_ce < front_ce, "TOP armor should be much thinner than FRONT")
	assert_true(float(top_ce) / float(front_ce) < 0.1, "TOP should be less than 10% of FRONT")


# =============================================================================
# テスト: 貫通確率
# =============================================================================

func test_penetration_probability_top_attack() -> void:
	## トップアタックは貫通確率が高い
	var tank := _create_mock_tank()
	var shooter := _create_mock_shooter()

	# Javelin相当のCE貫通力
	var ce_penetration: int = 160
	var top_armor: int = tank.element_type.armor_ce[WeaponData.ArmorZone.TOP]  # 4

	# CE貫通 >> TOP装甲 なので確実に貫通
	var p_pen := combat_system.calculate_penetration_probability(ce_penetration, top_armor)

	assert_almost_eq(p_pen, 1.0, 0.01, "TOP attack with 160mm CE vs 4mm armor should penetrate 100%")


func test_penetration_probability_direct_vs_front() -> void:
	## DIRECT攻撃は正面装甲に阻まれる可能性
	var tank := _create_mock_tank()

	var ce_penetration: int = 160
	var front_armor: int = tank.element_type.armor_ce[WeaponData.ArmorZone.FRONT]  # 140

	# CE貫通 > FRONT装甲だが、差は小さい
	var p_pen := combat_system.calculate_penetration_probability(ce_penetration, front_armor)

	# 160 vs 140 = 貫通可能だが確実ではない
	assert_true(p_pen > 0.5, "Should have reasonable penetration chance")
	assert_true(p_pen < 1.0, "Should not be guaranteed penetration against front")


# =============================================================================
# テスト: アスペクト強制指定付きダメージ計算
# =============================================================================

func test_calculate_damage_with_forced_aspect_top() -> void:
	## トップアタックの貫通確率を直接テスト
	## NOTE: CombatSystem.calculate_direct_fire_vs_armor_with_aspectは
	## 完全なシミュレーション環境が必要なため、ここでは貫通確率のみテスト

	var tank := _create_mock_tank()

	# TOP面のCE装甲: 4mm
	# Javelin貫通力: 160mm
	# 160 >> 4 なので確実に貫通
	var top_armor: int = tank.element_type.armor_ce[WeaponData.ArmorZone.TOP]
	var p_pen := combat_system.calculate_penetration_probability(160, top_armor)

	assert_almost_eq(p_pen, 1.0, 0.01, "TOP attack should have ~100% penetration")


func test_top_attack_vs_direct_attack_penetration() -> void:
	## トップアタックはDIRECT攻撃より貫通確率が高い
	var tank := _create_mock_tank()

	# Javelin貫通力: 160mm CE
	var ce_penetration := 160

	# FRONT装甲: 140mm → 貫通可能だが確実ではない
	var front_armor: int = tank.element_type.armor_ce[WeaponData.ArmorZone.FRONT]
	var p_pen_front := combat_system.calculate_penetration_probability(ce_penetration, front_armor)

	# TOP装甲: 4mm → 確実に貫通
	var top_armor: int = tank.element_type.armor_ce[WeaponData.ArmorZone.TOP]
	var p_pen_top := combat_system.calculate_penetration_probability(ce_penetration, top_armor)

	print("FRONT p_pen: %.4f, TOP p_pen: %.4f" % [p_pen_front, p_pen_top])

	assert_true(p_pen_top > p_pen_front, "TOP attack should have higher penetration probability")
	assert_almost_eq(p_pen_top, 1.0, 0.01, "TOP attack should have ~100% penetration")


# =============================================================================
# テスト: ミサイルプロファイル
# =============================================================================

func test_javelin_default_is_top_attack() -> void:
	## Javelinのデフォルトはトップアタック
	var profile := MissileData.get_profile_for_weapon("CW_ATGM_JAVELIN")
	if profile:
		assert_eq(profile.default_attack_profile, MissileData.AttackProfile.TOP_ATTACK,
			"Javelin default should be TOP_ATTACK")
	else:
		pending("Javelin profile not found in MissileData")


func test_01lmat_default_is_top_attack() -> void:
	## 01LMATのデフォルトはトップアタック
	var profile := MissileData.get_profile_for_weapon("CW_ATGM_01LMAT")
	if profile:
		assert_eq(profile.default_attack_profile, MissileData.AttackProfile.TOP_ATTACK,
			"01LMAT default should be TOP_ATTACK")
	else:
		pending("01LMAT profile not found in MissileData")


func test_mmpm_default_is_top_attack() -> void:
	## MMPMのデフォルトはトップアタック
	var profile := MissileData.get_profile_for_weapon("CW_ATGM_MMPM")
	if profile:
		assert_eq(profile.default_attack_profile, MissileData.AttackProfile.TOP_ATTACK,
			"MMPM default should be TOP_ATTACK")
	else:
		pending("MMPM profile not found in MissileData")


func test_tow_default_is_direct() -> void:
	## TOWのデフォルトはDIRECT
	var profile := MissileData.get_profile_for_weapon("CW_ATGM_TOW2B")
	if profile:
		assert_eq(profile.default_attack_profile, MissileData.AttackProfile.DIRECT,
			"TOW-2B default should be DIRECT")
	else:
		pending("TOW-2B profile not found in MissileData")
