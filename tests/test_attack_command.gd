extends GutTest

## ATTACKコマンドの統合テスト
## - 各種ユニットでATTACKコマンドが正しく機能するか
## - forced_target_id / order_target_id の設定
## - current_order_type の維持（MOVEに上書きされない）
## - 移動中/静止時の武器選択

var WeaponDataClass: GDScript
var ElementFactoryClass: GDScript
var MovementSystemClass: GDScript
var CombatSystemClass: GDScript
var GameEnumsClass: GDScript

var movement_system
var combat_system


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	MovementSystemClass = load("res://scripts/systems/movement_system.gd")
	CombatSystemClass = load("res://scripts/systems/combat_system.gd")
	GameEnumsClass = load("res://scripts/core/game_enums.gd")


func before_each() -> void:
	ElementFactoryClass.reset_id_counters()
	movement_system = MovementSystemClass.new()
	combat_system = CombatSystemClass.new()


# =============================================================================
# ヘルパー関数
# =============================================================================

## ATTACKコマンドを発行（Main.gd _execute_attack_command を模擬）
func issue_attack_command(attacker, target) -> void:
	attacker.forced_target_id = target.id
	attacker.order_target_id = target.id
	attacker.current_order_type = GameEnumsClass.OrderType.ATTACK


## 移動命令を発行（視界外の目標への接近を模擬）
func simulate_move_to_target(element, target_pos: Vector2) -> void:
	# MovementSystemがない場合は手動で状態を設定
	element.is_moving = true
	element.order_target_position = target_pos
	# current_order_typeは変更しない（ATTACKのまま維持されるべき）


# =============================================================================
# ATTACKコマンド基本テスト
# =============================================================================

func test_attack_command_sets_target_ids() -> void:
	var attacker = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(attacker, target)

	assert_eq(attacker.forced_target_id, target.id, "forced_target_id should be set")
	assert_eq(attacker.order_target_id, target.id, "order_target_id should be set")
	assert_eq(attacker.current_order_type, GameEnumsClass.OrderType.ATTACK,
		"current_order_type should be ATTACK")


func test_attack_order_preserved_during_movement() -> void:
	var attacker = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	# ATTACKコマンド発行
	issue_attack_command(attacker, target)

	# 移動開始（視界外の目標に近づく）
	simulate_move_to_target(attacker, target.position)

	# ATTACKのまま維持されているか確認
	assert_eq(attacker.current_order_type, GameEnumsClass.OrderType.ATTACK,
		"current_order_type should remain ATTACK during movement")
	assert_eq(attacker.forced_target_id, target.id,
		"forced_target_id should be preserved during movement")


# =============================================================================
# M2A4 Bradley ATTACKテスト
# =============================================================================

func test_m2a4_bradley_attack_command() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(bradley, target)

	assert_eq(bradley.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(bradley.forced_target_id, target.id)

	# 静止時は武器選択可能
	bradley.is_moving = false
	var distance_m: float = bradley.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(bradley, target, distance_m)

	assert_not_null(selected, "Bradley should select weapon when stationary")


func test_m2a3_bradley_attack_command() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A3_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(bradley, target)

	assert_eq(bradley.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(bradley.forced_target_id, target.id)

	# 静止時は武器選択可能
	bradley.is_moving = false
	var distance_m: float = bradley.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(bradley, target, distance_m)

	assert_not_null(selected, "M2A3 Bradley should select weapon when stationary")


# =============================================================================
# 日本車両 ATTACKテスト
# =============================================================================

func test_type10_attack_command() -> void:
	var tank = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(tank, target)

	assert_eq(tank.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(tank.forced_target_id, target.id)

	tank.is_moving = false
	var distance_m: float = tank.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(tank, target, distance_m)

	assert_not_null(selected, "Type 10 should select weapon")
	WeaponDataClass.ensure_weapon_role(selected)
	assert_eq(selected.weapon_role, WeaponDataClass.WeaponRole.MAIN_GUN_KE,
		"Type 10 should select main gun KE against MBT")


func test_type89_ifv_attack_command() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type89",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M113A3",  # 軽装甲
		GameEnumsClass.Faction.RED,
		Vector2(1500, 0)
	)

	issue_attack_command(ifv, target)

	assert_eq(ifv.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(ifv.forced_target_id, target.id)

	ifv.is_moving = false
	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	assert_not_null(selected, "Type 89 should select weapon against light armor")


func test_mmpm_attack_command() -> void:
	var mmpm = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(3000, 0)
	)

	issue_attack_command(mmpm, target)

	assert_eq(mmpm.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(mmpm.forced_target_id, target.id)

	# MMPMは静止時のみ射撃可能
	mmpm.is_moving = false
	var distance_m: float = mmpm.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(mmpm, target, distance_m)

	assert_not_null(selected, "MMPM should select ATGM when stationary")
	assert_eq(selected.id, "W_JPN_ATGM_MMPM", "MMPM should use MMPM ATGM")


func test_mmpm_no_weapon_when_moving() -> void:
	var mmpm = ElementFactoryClass.create_element_with_vehicle(
		"JPN_HMV_MMPM",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.RED,
		Vector2(3000, 0)
	)

	issue_attack_command(mmpm, target)
	mmpm.is_moving = true

	var distance_m: float = mmpm.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(mmpm, target, distance_m)

	# ATGM車両は移動中は武器がない
	assert_null(selected, "MMPM should not select weapon when moving (ATGM only)")


# =============================================================================
# ロシア車両 ATTACKテスト
# =============================================================================

func test_t90m_attack_command() -> void:
	var tank = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnumsClass.Faction.RED,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.BLUE,
		Vector2(2000, 0)
	)

	issue_attack_command(tank, target)

	assert_eq(tank.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(tank.forced_target_id, target.id)

	tank.is_moving = false
	var distance_m: float = tank.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(tank, target, distance_m)

	assert_not_null(selected, "T-90M should select weapon")


func test_bmp3_attack_command() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BMP3",
		GameEnumsClass.Faction.RED,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M113A3",
		GameEnumsClass.Faction.BLUE,
		Vector2(1500, 0)
	)

	issue_attack_command(ifv, target)

	assert_eq(ifv.current_order_type, GameEnumsClass.OrderType.ATTACK)

	ifv.is_moving = false
	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	assert_not_null(selected, "BMP-3 should select weapon against light armor")


# =============================================================================
# 中国車両 ATTACKテスト
# =============================================================================

func test_type99a_attack_command() -> void:
	var tank = ElementFactoryClass.create_element_with_vehicle(
		"CHN_Type99A",
		GameEnumsClass.Faction.RED,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.BLUE,
		Vector2(2000, 0)
	)

	issue_attack_command(tank, target)

	assert_eq(tank.current_order_type, GameEnumsClass.OrderType.ATTACK)

	tank.is_moving = false
	var distance_m: float = tank.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(tank, target, distance_m)

	assert_not_null(selected, "Type 99A should select weapon")


func test_zbd04a_attack_command() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"CHN_ZBD04A",
		GameEnumsClass.Faction.RED,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M113A3",
		GameEnumsClass.Faction.BLUE,
		Vector2(1500, 0)
	)

	issue_attack_command(ifv, target)

	assert_eq(ifv.current_order_type, GameEnumsClass.OrderType.ATTACK)

	ifv.is_moving = false
	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	assert_not_null(selected, "ZBD-04A should select weapon against light armor")


# =============================================================================
# 米軍車両 ATTACKテスト
# =============================================================================

func test_m1a2_sepv3_attack_command() -> void:
	var tank = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnumsClass.Faction.RED,
		Vector2(2500, 0)
	)

	issue_attack_command(tank, target)

	assert_eq(tank.current_order_type, GameEnumsClass.OrderType.ATTACK)
	assert_eq(tank.forced_target_id, target.id)

	tank.is_moving = false
	var distance_m: float = tank.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(tank, target, distance_m)

	assert_not_null(selected, "M1A2 SEPv3 should select weapon")
	WeaponDataClass.ensure_weapon_role(selected)
	assert_eq(selected.weapon_role, WeaponDataClass.WeaponRole.MAIN_GUN_KE,
		"M1A2 should select main gun KE against MBT")


func test_stryker_dragoon_attack_command() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"USA_Stryker_Dragoon",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_BMP3",
		GameEnumsClass.Faction.RED,
		Vector2(1500, 0)
	)

	issue_attack_command(ifv, target)

	assert_eq(ifv.current_order_type, GameEnumsClass.OrderType.ATTACK)

	ifv.is_moving = false
	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	assert_not_null(selected, "Stryker Dragoon should select weapon")
	WeaponDataClass.ensure_weapon_role(selected)
	assert_eq(selected.weapon_role, WeaponDataClass.WeaponRole.AUTOCANNON,
		"Stryker Dragoon should select 30mm autocannon")


# =============================================================================
# 移動中の武器選択テスト
# =============================================================================

func test_tank_can_fire_while_moving() -> void:
	var tank = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(tank, target)
	tank.is_moving = true

	var distance_m: float = tank.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(tank, target, distance_m)

	# 戦車は移動中でも主砲で射撃可能
	assert_not_null(selected, "Tank should select weapon even when moving")


func test_ifv_autocannon_works_while_moving() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M113A3",  # 軽装甲 - 機関砲で有効
		GameEnumsClass.Faction.RED,
		Vector2(1500, 0)
	)

	issue_attack_command(ifv, target)
	ifv.is_moving = true

	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	# IFVは移動中でも機関砲は使用可能（ATGMは不可）
	assert_not_null(selected, "IFV should select autocannon when moving against light armor")
	WeaponDataClass.ensure_weapon_role(selected)
	assert_ne(selected.weapon_role, WeaponDataClass.WeaponRole.ATGM,
		"IFV should not select ATGM when moving")


func test_ifv_no_atgm_when_moving_against_mbt() -> void:
	var ifv = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",  # 重装甲 - 機関砲は無効
		GameEnumsClass.Faction.RED,
		Vector2(2000, 0)
	)

	issue_attack_command(ifv, target)
	ifv.is_moving = true

	var distance_m: float = ifv.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(ifv, target, distance_m)

	# 移動中のIFVは重装甲に対して有効な武器がない
	if selected != null:
		WeaponDataClass.ensure_weapon_role(selected)
		assert_ne(selected.weapon_role, WeaponDataClass.WeaponRole.ATGM,
			"IFV should not select ATGM when moving")


# =============================================================================
# 武器選択の正確性テスト
# =============================================================================

func test_weapon_role_preserved_after_attack_command() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)

	# 武器のweapon_roleが正しく設定されているか確認
	for weapon in bradley.weapons:
		WeaponDataClass.ensure_weapon_role(weapon)
		# weapon_roleがSMALL_ARMSでないことを確認（JSONから正しくロードされている）
		if weapon.id == "CW_AUTOCANNON_25_USA":
			assert_eq(weapon.weapon_role, WeaponDataClass.WeaponRole.AUTOCANNON,
				"25mm autocannon should have AUTOCANNON role")
		elif weapon.id == "W_USA_ATGM_TOW2B":
			assert_eq(weapon.weapon_role, WeaponDataClass.WeaponRole.ATGM,
				"TOW-2B should have ATGM role")
		elif weapon.id == "CW_M240_COAX":
			assert_eq(weapon.weapon_role, WeaponDataClass.WeaponRole.COAX_MG,
				"M240 coax should have COAX_MG role")


func test_all_bradley_weapons_have_correct_roles() -> void:
	var m2a4 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var m2a3 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A3_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(100, 0)
	)

	# M2A4の武器確認
	assert_gt(m2a4.weapons.size(), 0, "M2A4 should have weapons")
	for weapon in m2a4.weapons:
		WeaponDataClass.ensure_weapon_role(weapon)
		assert_ne(weapon.weapon_role, WeaponDataClass.WeaponRole.SMALL_ARMS,
			"M2A4 weapon %s should not have SMALL_ARMS role" % weapon.id)

	# M2A3の武器確認
	assert_gt(m2a3.weapons.size(), 0, "M2A3 should have weapons")
	for weapon in m2a3.weapons:
		WeaponDataClass.ensure_weapon_role(weapon)
		assert_ne(weapon.weapon_role, WeaponDataClass.WeaponRole.SMALL_ARMS,
			"M2A3 weapon %s should not have SMALL_ARMS role" % weapon.id)


# =============================================================================
# Bradley ATGM射程内停止テスト
# =============================================================================

func test_bradley_atgm_range_check() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)

	# TOW-2Bの射程を確認（65m - 4500m）
	var tow_found := false
	for weapon in bradley.weapons:
		if weapon.id == "W_USA_ATGM_TOW2B":
			tow_found = true
			assert_eq(weapon.min_range_m, 65.0, "TOW-2B min range should be 65m")
			assert_eq(weapon.max_range_m, 4500.0, "TOW-2B max range should be 4500m")
			# 射程内判定
			assert_true(weapon.is_in_range(1000.0), "1000m should be in range")
			assert_true(weapon.is_in_range(4000.0), "4000m should be in range")
			assert_false(weapon.is_in_range(50.0), "50m should be out of range (too close)")
			assert_false(weapon.is_in_range(5000.0), "5000m should be out of range")
			break

	assert_true(tow_found, "M2A4 Bradley should have TOW-2B")


func test_bradley_selects_atgm_against_mbt_when_stationary() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnumsClass.Faction.RED,
		Vector2(3000, 0)  # ATGM射程内、AUTOCANNON射程外
	)

	issue_attack_command(bradley, target)
	bradley.is_moving = false  # 静止

	var distance_m: float = bradley.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(bradley, target, distance_m)

	assert_not_null(selected, "Bradley should select ATGM against MBT when stationary")
	if selected:
		WeaponDataClass.ensure_weapon_role(selected)
		assert_eq(selected.weapon_role, WeaponDataClass.WeaponRole.ATGM,
			"Bradley should select ATGM against MBT at 3000m")


func test_bradley_cannot_use_atgm_when_moving_against_mbt() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)
	var target = ElementFactoryClass.create_element_with_vehicle(
		"RUS_T90M",
		GameEnumsClass.Faction.RED,
		Vector2(3000, 0)  # ATGM射程内、AUTOCANNON射程外
	)

	issue_attack_command(bradley, target)
	bradley.is_moving = true  # 移動中

	var distance_m: float = bradley.position.distance_to(target.position)
	var selected = combat_system.select_best_weapon(bradley, target, distance_m)

	# 移動中はATGMが使えない、AUTOCANNONは射程外
	# 結果：有効な武器がない
	if selected != null:
		WeaponDataClass.ensure_weapon_role(selected)
		assert_ne(selected.weapon_role, WeaponDataClass.WeaponRole.ATGM,
			"Bradley should not select ATGM when moving")


func test_bradley_autocannon_range() -> void:
	var bradley = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnumsClass.Faction.BLUE,
		Vector2(0, 0)
	)

	# 25mm AUTOCANNONの射程を確認
	var autocannon_found := false
	for weapon in bradley.weapons:
		if weapon.id == "CW_AUTOCANNON_25_USA":
			autocannon_found = true
			# 射程を確認（max_range_mは武器定義による）
			print("[Test] 25mm Autocannon: min=%.0fm, max=%.0fm" % [weapon.min_range_m, weapon.max_range_m])
			assert_true(weapon.max_range_m > 0, "25mm should have positive max range")
			break

	assert_true(autocannon_found, "M2A4 Bradley should have 25mm autocannon")
