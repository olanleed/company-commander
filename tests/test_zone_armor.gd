extends Node

## 車両ゾーン別装甲と貫徹判定のテスト
## テスト項目:
## 1. ゾーン判定（FRONT/SIDE/REAR）が正しく動作
## 2. 貫徹確率（sigmoid関数）が正しく計算
## 3. 小火器 vs 装甲の無効化
## 4. 車両への小火器抑圧上限

var combat_system: CombatSystem


func _ready() -> void:
	combat_system = CombatSystem.new()
	run_tests()


func run_tests() -> void:
	print("=== Zone Armor Tests ===")
	test_penetration_probability()
	test_zone_determination()
	test_small_arms_vs_armor()
	test_vehicle_suppression_cap()
	test_tank_armor_values()
	print("=== All Tests Complete ===")


## 貫徹確率のsigmoid計算テスト
func test_penetration_probability() -> void:
	print("\n--- Test: Penetration Probability ---")

	# P = A: 50%
	var p_equal := combat_system.calculate_penetration_probability(50, 50)
	print("P=A (50 vs 50): %.3f (expected ~0.50)" % p_equal)
	assert(p_equal > 0.49 and p_equal < 0.51, "P=A should be ~0.50")

	# P > A: 高い貫徹確率
	var p_high := combat_system.calculate_penetration_probability(80, 50)
	print("P>A (80 vs 50): %.3f (expected >0.80)" % p_high)
	assert(p_high > 0.80, "P>A should be high")

	# P < A: 低い貫徹確率
	var p_low := combat_system.calculate_penetration_probability(30, 70)
	print("P<A (30 vs 70): %.3f (expected <0.10)" % p_low)
	assert(p_low < 0.10, "P<A should be low")

	# 極端に高い貫徹力
	var p_extreme := combat_system.calculate_penetration_probability(100, 20)
	print("P>>A (100 vs 20): %.3f (expected ~1.0)" % p_extreme)
	assert(p_extreme > 0.99, "P>>A should be ~1.0")

	print("PASS: Penetration probability calculations correct")


## ゾーン判定テスト
func test_zone_determination() -> void:
	print("\n--- Test: Zone Determination ---")

	# 目標は(100,0)にいて、右(facing=0)を向いている
	# facing=0 → 目標は+X方向を向いている
	# 「目標から見て射手がどの方向にいるか」で判定
	# 射手が目標の正面(目標が向いている方向)にいる → FRONT
	var target_pos := Vector2(100, 0)
	var target_facing := 0.0

	# 射手が目標の正面(+X方向)にいる → FRONT
	# 射手は目標より+X方向にいる = (200, 0)
	var zone_front := combat_system.calculate_aspect_v01r(
		Vector2(200, 0), target_pos, target_facing
	)
	print("Shooter in +X (target facing +X): %s (expected FRONT)" % WeaponData.ArmorZone.keys()[zone_front])
	assert(zone_front == WeaponData.ArmorZone.FRONT, "Should be FRONT")

	# 射手が目標の後ろ(-X方向)にいる → REAR
	var zone_rear := combat_system.calculate_aspect_v01r(
		Vector2(-100, 0), target_pos, target_facing
	)
	print("Shooter in -X (target facing +X): %s (expected REAR)" % WeaponData.ArmorZone.keys()[zone_rear])
	assert(zone_rear == WeaponData.ArmorZone.REAR, "Should be REAR")

	# 射手が目標の側面(+Y/-Y方向)にいる → SIDE
	var zone_side := combat_system.calculate_aspect_v01r(
		Vector2(100, 100), target_pos, target_facing
	)
	print("Shooter in +Y (target facing +X): %s (expected SIDE)" % WeaponData.ArmorZone.keys()[zone_side])
	assert(zone_side == WeaponData.ArmorZone.SIDE, "Should be SIDE")

	print("PASS: Zone determination correct")


## 小火器 vs 装甲テスト
func test_small_arms_vs_armor() -> void:
	print("\n--- Test: Small Arms vs Armor ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank"
	tank.position = Vector2(100, 0)
	tank.facing = 0.0

	# 歩兵を作成
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var inf := ElementData.ElementInstance.new(inf_type)
	inf.id = "test_inf"
	inf.position = Vector2(0, 0)

	# 小銃を作成
	var rifle := WeaponData.create_cw_rifle_std()

	# 貫徹確率を計算
	var aspect := combat_system.calculate_aspect_v01r(inf.position, tank.position, tank.facing)
	var p_pen := combat_system.get_penetration_probability(
		inf, tank, rifle, 200.0, aspect
	)

	print("Rifle vs Tank penetration: %.3f (expected 0.0)" % p_pen)
	assert(p_pen == 0.0, "Small arms should not penetrate armor")

	# ダメージ脆弱性も確認
	var vuln_dmg := combat_system.get_vulnerability_dmg(tank, rifle.threat_class)
	print("Rifle vs Tank damage vulnerability: %.3f (expected 0.0)" % vuln_dmg)
	assert(vuln_dmg == 0.0, "Small arms should do no damage to heavy armor")

	print("PASS: Small arms correctly ineffective against armor")


## 車両への小火器抑圧上限テスト
func test_vehicle_suppression_cap() -> void:
	print("\n--- Test: Vehicle Small Arms Suppression Cap ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank_supp"
	tank.suppression = 0.0

	# 大量の抑圧を与えようとする
	combat_system.apply_damage(tank, 0.50, 0.0, 0, WeaponData.ThreatClass.SMALL_ARMS)
	print("After 50%% small arms suppression: %.1f%% (expected <=20%%)" % (tank.suppression * 100))
	assert(tank.suppression <= GameConstants.VEHICLE_SMALLARMS_SUPP_CAP, "Should be capped at 20%")

	# さらに追加しても上限を超えない
	combat_system.apply_damage(tank, 0.50, 0.0, 0, WeaponData.ThreatClass.SMALL_ARMS)
	print("After additional 50%% attempt: %.1f%% (expected <=20%%)" % (tank.suppression * 100))
	assert(tank.suppression <= GameConstants.VEHICLE_SMALLARMS_SUPP_CAP, "Should still be capped")

	# AT火器なら上限なし
	var tank2_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank2 := ElementData.ElementInstance.new(tank2_type)
	tank2.id = "test_tank_at"
	tank2.suppression = 0.0

	combat_system.apply_damage(tank2, 0.50, 0.0, 0, WeaponData.ThreatClass.AT)
	print("After 50%% AT suppression: %.1f%% (expected 50%%)" % (tank2.suppression * 100))
	assert(tank2.suppression > 0.45, "AT suppression should not be capped")

	print("PASS: Vehicle suppression cap working correctly")


## 戦車の装甲値テスト
func test_tank_armor_values() -> void:
	print("\n--- Test: Tank Armor Values ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()

	print("Tank armor_ke[FRONT]: %d" % tank_type.armor_ke[WeaponData.ArmorZone.FRONT])
	print("Tank armor_ke[SIDE]: %d" % tank_type.armor_ke[WeaponData.ArmorZone.SIDE])
	print("Tank armor_ke[REAR]: %d" % tank_type.armor_ke[WeaponData.ArmorZone.REAR])
	print("Tank armor_ce[FRONT]: %d" % tank_type.armor_ce[WeaponData.ArmorZone.FRONT])

	assert(tank_type.armor_ke[WeaponData.ArmorZone.FRONT] == 95, "Front KE should be 95")
	assert(tank_type.armor_ke[WeaponData.ArmorZone.SIDE] == 55, "Side KE should be 55")
	assert(tank_type.armor_ke[WeaponData.ArmorZone.REAR] == 25, "Rear KE should be 25")

	# RPG vs Tank（正面）
	var rpg := WeaponData.create_cw_rpg_heat()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.position = Vector2(100, 0)
	tank.facing = PI  # 左を向いている（正面が射手側）

	var shooter_type := ElementData.ElementArchetypes.create_inf_at()
	var shooter := ElementData.ElementInstance.new(shooter_type)
	shooter.position = Vector2(0, 0)

	# 正面からの攻撃
	var aspect_front := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_front := combat_system.get_penetration_probability(
		shooter, tank, rpg, 100.0, aspect_front
	)
	print("RPG vs Tank FRONT (pen=75 vs armor=90): %.3f" % p_pen_front)

	# 側面からの攻撃
	tank.facing = PI / 2  # 上を向いている
	var aspect_side := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_side := combat_system.get_penetration_probability(
		shooter, tank, rpg, 100.0, aspect_side
	)
	print("RPG vs Tank SIDE (pen=75 vs armor=50): %.3f" % p_pen_side)

	# 後方からの攻撃
	tank.facing = 0  # 右を向いている（後方が射手側）
	var aspect_rear := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_rear := combat_system.get_penetration_probability(
		shooter, tank, rpg, 100.0, aspect_rear
	)
	print("RPG vs Tank REAR (pen=75 vs armor=20): %.3f" % p_pen_rear)

	# 正面<側面<後方の順で貫徹しやすい
	assert(p_pen_front < p_pen_side, "Side should be easier to penetrate than front")
	assert(p_pen_side < p_pen_rear, "Rear should be easier to penetrate than side")

	print("PASS: Tank armor values and penetration working correctly")
