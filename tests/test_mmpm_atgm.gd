extends GutTest

## MMPM（中距離多目的誘導弾）の統合テスト
## - 武器ロード
## - WeaponRole.ATGMの確認
## - 武器選択（重装甲目標への優先度）
## - ミサイル発射

var WeaponDataClass: GDScript
var MissileDataClass: GDScript
var MissileSystemClass: GDScript
var CombatSystemClass: GDScript
var ElementDataClass: GDScript
var GameEnumsClass: GDScript

var missile_system
var combat_system


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	MissileDataClass = load("res://scripts/data/missile_data.gd")
	MissileSystemClass = load("res://scripts/systems/missile_system.gd")
	CombatSystemClass = load("res://scripts/systems/combat_system.gd")
	ElementDataClass = load("res://scripts/data/element_data.gd")
	GameEnumsClass = load("res://scripts/core/game_enums.gd")
	# JSONロード状態をリセット
	MissileDataClass._reset_for_testing()


func before_each() -> void:
	missile_system = MissileSystemClass.new()
	combat_system = CombatSystemClass.new()


func after_each() -> void:
	missile_system.reset()


func after_all() -> void:
	MissileDataClass._reset_for_testing()


# =============================================================================
# 武器データ検証
# =============================================================================

func test_mmpm_weapon_exists() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	assert_has(all_weapons, "W_JPN_ATGM_MMPM", "W_JPN_ATGM_MMPM should exist in weapon data")


func test_mmpm_weapon_role_is_atgm() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")

	assert_not_null(mmpm, "MMPM weapon should be loaded")
	WeaponDataClass.ensure_weapon_role(mmpm)
	assert_eq(mmpm.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"MMPM weapon_role should be ATGM")


func test_mmpm_mechanism_is_shaped_charge() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")

	assert_not_null(mmpm)
	assert_eq(mmpm.mechanism, WeaponDataClass.Mechanism.SHAPED_CHARGE,
		"MMPM should use SHAPED_CHARGE mechanism")


func test_mmpm_has_ce_penetration() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")

	assert_not_null(mmpm)
	assert_gt(mmpm.pen_ce.size(), 0, "MMPM should have CE penetration values")

	var pen_near: int = mmpm.get_pen_ce(500.0)
	assert_gt(pen_near, 100, "MMPM penetration should be > 100mm CE")


func test_mmpm_range() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")

	assert_not_null(mmpm)
	assert_true(mmpm.max_range_m >= 5000.0, "MMPM max range should be >= 5000m")
	assert_true(mmpm.min_range_m >= 300.0, "MMPM min range should be >= 300m")


# =============================================================================
# ミサイルプロファイル検証
# =============================================================================

func test_mmpm_missile_profile_exists() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	assert_not_null(profile, "M_JPN_MMPM profile should exist")


func test_mmpm_missile_linked_to_weapon() -> void:
	var profile = MissileDataClass.get_profile_for_weapon("W_JPN_ATGM_MMPM")
	assert_not_null(profile, "W_JPN_ATGM_MMPM should have linked missile profile")
	assert_eq(profile.id, "M_JPN_MMPM")


func test_mmpm_guidance_is_iir() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	assert_not_null(profile)
	assert_eq(profile.guidance_type, MissileDataClass.GuidanceType.IIR_HOMING,
		"MMPM should use IIR homing guidance")


func test_mmpm_supports_top_attack() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	assert_not_null(profile)
	assert_true(profile.can_use_profile(MissileDataClass.AttackProfile.TOP_ATTACK),
		"MMPM should support TOP_ATTACK")


func test_mmpm_is_fire_and_forget() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	assert_not_null(profile)
	assert_true(profile.is_fire_and_forget(),
		"MMPM should be fire-and-forget (IIR homing)")


# =============================================================================
# 武器選択テスト (統合テスト - 要ElementFactory使用)
# =============================================================================
# 注: ElementInstanceの直接作成はGodot型制約で複雑になるため、
#     武器選択テストはElementFactoryを使用する別テストファイルで実施


# =============================================================================
# ミサイル発射テスト
# =============================================================================

func test_mmpm_launch_success() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)  # 2km

	var missile_id: String = missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.TOP_ATTACK,
		0
	)

	assert_ne(missile_id, "", "MMPM should launch successfully")
	assert_eq(missile_system.get_in_flight_count(), 1)


func test_mmpm_launch_top_attack_mode() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)  # 3km

	var missile_id: String = missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.TOP_ATTACK,
		0
	)

	var missile = missile_system.get_missile(missile_id)
	assert_not_null(missile)
	assert_eq(missile.attack_profile, MissileDataClass.AttackProfile.TOP_ATTACK)


func test_mmpm_launch_direct_mode() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1500, 0)  # 1.5km

	var missile_id: String = missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "MMPM should support DIRECT mode")

	var missile = missile_system.get_missile(missile_id)
	assert_eq(missile.attack_profile, MissileDataClass.AttackProfile.DIRECT)


func test_mmpm_no_shooter_constraint() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.TOP_ATTACK,
		0
	)

	# Fire-and-Forgetなので射手拘束なし
	assert_false(missile_system.is_shooter_constrained("mmpm_001"),
		"MMPM (F&F) should not constrain shooter")


func test_mmpm_shooter_can_move_after_launch() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.TOP_ATTACK,
		0
	)

	assert_true(missile_system.can_shooter_move("mmpm_001"),
		"MMPM shooter should be able to move after launch")


func test_mmpm_min_range_enforced() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(200, 0)  # 200m < min 300m

	var missile_id: String = missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.DIRECT,
		0
	)

	assert_eq(missile_id, "", "MMPM should not launch below min range")


func test_mmpm_max_range_enforced() -> void:
	var profile = MissileDataClass.get_profile("M_JPN_MMPM")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(6000, 0)  # 6km > max 5km

	var missile_id: String = missile_system.launch_missile(
		"mmpm_001",
		shooter_pos,
		"target_001",
		target_pos,
		profile,
		MissileDataClass.AttackProfile.TOP_ATTACK,
		0
	)

	assert_eq(missile_id, "", "MMPM should not launch beyond max range")


# =============================================================================
# JGSDF武器との比較テスト
# =============================================================================

func test_mmpm_pen_higher_than_79mat() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")
	var mat79 = all_weapons.get("W_JPN_ATGM_79MAT")

	assert_not_null(mmpm)
	assert_not_null(mat79)

	var mmpm_pen: int = mmpm.get_pen_ce(1500.0)
	var mat79_pen: int = mat79.get_pen_ce(1500.0)

	assert_gt(mmpm_pen, mat79_pen,
		"MMPM should have higher penetration than 79MAT")


func test_mmpm_range_higher_than_01lmat() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mmpm = all_weapons.get("W_JPN_ATGM_MMPM")
	var lmat = all_weapons.get("W_JPN_ATGM_01LMAT")

	assert_not_null(mmpm)
	assert_not_null(lmat)

	assert_gt(mmpm.max_range_m, lmat.max_range_m,
		"MMPM should have longer range than 01LMAT")


# =============================================================================
# 他のJGSDF ATGM武器ロールテスト
# =============================================================================

func test_79mat_weapon_role_is_atgm() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var mat79 = all_weapons.get("W_JPN_ATGM_79MAT")

	assert_not_null(mat79, "79MAT weapon should be loaded")
	WeaponDataClass.ensure_weapon_role(mat79)
	assert_eq(mat79.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"79MAT weapon_role should be ATGM")


func test_01lmat_weapon_role_is_atgm() -> void:
	var all_weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var lmat = all_weapons.get("W_JPN_ATGM_01LMAT")

	assert_not_null(lmat, "01LMAT weapon should be loaded")
	WeaponDataClass.ensure_weapon_role(lmat)
	assert_eq(lmat.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"01LMAT weapon_role should be ATGM")


# =============================================================================
# 車両カタログ統合テスト（ATGM車両の武装設定）
# =============================================================================

func test_hmv_mmpm_vehicle_has_atgm_weapon() -> void:
	# ElementFactoryでMMPM車両を作成
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var element = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(1000, 1000)
	)

	assert_not_null(element, "MMPM vehicle element should be created")
	assert_gt(element.weapons.size(), 0, "MMPM vehicle should have weapons")

	# ATGMが武器リストに含まれているか確認
	var has_atgm := false
	for weapon in element.weapons:
		if weapon.id == "W_JPN_ATGM_MMPM":
			has_atgm = true
			break
	assert_true(has_atgm, "MMPM vehicle should have W_JPN_ATGM_MMPM weapon")


func test_hmv_mmpm_primary_weapon_is_atgm() -> void:
	# ATGM車両の主武装がATGMであることを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var element = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(1000, 1000)
	)

	assert_not_null(element, "MMPM vehicle element should be created")
	assert_not_null(element.primary_weapon, "MMPM vehicle should have primary_weapon")
	assert_eq(element.primary_weapon.id, "W_JPN_ATGM_MMPM",
		"MMPM vehicle primary_weapon should be W_JPN_ATGM_MMPM")


func test_hmv_mmpm_current_weapon_is_atgm() -> void:
	# ATGM車両のcurrent_weaponがATGMであることを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var element = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(1000, 1000)
	)

	assert_not_null(element, "MMPM vehicle element should be created")
	assert_not_null(element.current_weapon, "MMPM vehicle should have current_weapon")
	assert_eq(element.current_weapon.id, "W_JPN_ATGM_MMPM",
		"MMPM vehicle current_weapon should be W_JPN_ATGM_MMPM")


# =============================================================================
# ATGM移動射撃禁止テスト
# =============================================================================

func test_atgm_not_selected_when_moving() -> void:
	# 移動中はATGMが武器選択されないことを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = true

	var target = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	# 移動中のATGM車両は有効な武器がない（ATGMのみ搭載のため）
	assert_null(selected_weapon, "ATGM should not be selected when shooter is moving")


func test_atgm_selected_when_stationary() -> void:
	# 静止時はATGMが武器選択されることを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = false

	var target = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	assert_not_null(selected_weapon, "ATGM should be selected when shooter is stationary")
	assert_eq(selected_weapon.id, "W_JPN_ATGM_MMPM", "Selected weapon should be MMPM")


func test_ifv_atgm_not_selected_when_moving() -> void:
	# IFVも移動中はATGMが選択されないことを確認（機関砲は選択可能）
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type89",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = true

	# 機関砲の射程内かつ機関砲が有効な軽装甲目標（APC）を使用
	var target = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type96_WAPC",  # 軽装甲APC - 機関砲で有効
		GameEnumsClass.Faction.RED,
		Vector2(1500, 0)  # 1.5km - 機関砲の有効射程内
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	# 移動中でも機関砲は使用可能（ATGMは不可）
	assert_not_null(selected_weapon, "IFV should have a weapon in range for light armor target")
	WeaponDataClass.ensure_weapon_role(selected_weapon)
	assert_ne(selected_weapon.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"ATGM should not be selected when IFV is moving")


# =============================================================================
# Bradley IFV武器選択テスト
# =============================================================================

func test_bradley_has_weapons() -> void:
	# M2A4 Bradleyが正しく武器を持っていることを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)

	assert_not_null(bradley, "Bradley should be created")
	assert_gt(bradley.weapons.size(), 0, "Bradley should have weapons")
	assert_not_null(bradley.primary_weapon, "Bradley should have primary_weapon")


func test_bradley_selects_autocannon_against_light_armor() -> void:
	# Bradleyが軽装甲目標に対して機関砲を選択することを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = false

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M113A3",  # 軽装甲APC
		GameEnumsClass.Faction.RED,
		Vector2(1500, 0)
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	assert_not_null(selected_weapon, "Bradley should select a weapon against light armor")
	# 機関砲またはATGMが選択されるはず
	WeaponDataClass.ensure_weapon_role(selected_weapon)
	var valid_roles := [WeaponDataClass.WeaponRole.AUTOCANNON, WeaponDataClass.WeaponRole.ATGM]
	assert_true(selected_weapon.weapon_role in valid_roles,
		"Bradley should select autocannon or ATGM against light armor")


func test_bradley_selects_weapon_against_mbt() -> void:
	# Bradleyが重装甲目標（MBT）に対して武器を選択することを確認
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = false

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",  # MBT
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)  # ATGM射程内
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	# MBT相手にはATGMが選択されるはず（機関砲は効果薄い）
	assert_not_null(selected_weapon, "Bradley should select ATGM against MBT")
	WeaponDataClass.ensure_weapon_role(selected_weapon)
	assert_eq(selected_weapon.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"Bradley should select ATGM against MBT")


func test_bradley_no_atgm_when_moving_against_mbt() -> void:
	# Bradley移動中はMBT相手でもATGMは使えない
	var ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	ElementFactoryClass.reset_id_counters()

	var shooter = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	shooter.is_moving = true

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",  # MBT
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	var distance_m: float = shooter.position.distance_to(target.position)
	var selected_weapon = combat_system.select_best_weapon(shooter, target, distance_m)

	# 移動中のBradleyはMBT相手に有効な武器がない（ATGMは使えない、機関砲は無効）
	# 武器が選択されないか、選択されてもATGMではないことを確認
	if selected_weapon == null:
		# 武器がnull = MBTに対して有効な武器がない（正しい動作）
		assert_null(selected_weapon, "Bradley has no effective weapon against MBT when moving")
	else:
		WeaponDataClass.ensure_weapon_role(selected_weapon)
		assert_ne(selected_weapon.weapon_role, WeaponDataClass.WeaponRole.ATGM,
			"Bradley should not select ATGM when moving")



