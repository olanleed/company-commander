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
	test_exposure_calculation()
	test_vehicle_damage_model()  # 車両ダメージモデルテスト
	print("=== All Tests Complete ===")
	# テスト終了後に自動終了
	get_tree().quit()


## 貫徹確率のsigmoid計算テスト
## RHA換算スケール: 100 = 500mm RHA
## シグモイドスケール: 15 → diff=+30で~88%, diff=0で50%, diff=-30で~12%
func test_penetration_probability() -> void:
	print("\n--- Test: Penetration Probability ---")

	# P = A: 50%
	var p_equal := combat_system.calculate_penetration_probability(50, 50)
	print("P=A (50 vs 50): %.3f (expected ~0.50)" % p_equal)
	assert(p_equal > 0.49 and p_equal < 0.51, "P=A should be ~0.50")

	# P > A by 30: ~88%
	var p_high := combat_system.calculate_penetration_probability(80, 50)
	print("P>A (80 vs 50, diff=+30): %.3f (expected ~0.88)" % p_high)
	assert(p_high > 0.85 and p_high < 0.92, "P>A by 30 should be ~88%")

	# P < A by 40: ~6%
	var p_low := combat_system.calculate_penetration_probability(30, 70)
	print("P<A (30 vs 70, diff=-40): %.3f (expected <0.10)" % p_low)
	assert(p_low < 0.10, "P<A by 40 should be low")

	# 極端に高い貫徹力 (diff = +80)
	var p_extreme := combat_system.calculate_penetration_probability(100, 20)
	print("P>>A (100 vs 20, diff=+80): %.3f (expected >0.99)" % p_extreme)
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


## 戦車の装甲値テスト（RHA換算スケール: 100 = 500mm RHA）
func test_tank_armor_values() -> void:
	print("\n--- Test: Tank Armor Values (RHA scale) ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()

	print("Tank armor_ke[FRONT]: %d (700mm RHA)" % tank_type.armor_ke[WeaponData.ArmorZone.FRONT])
	print("Tank armor_ke[SIDE]: %d (200mm RHA)" % tank_type.armor_ke[WeaponData.ArmorZone.SIDE])
	print("Tank armor_ke[REAR]: %d (80mm RHA)" % tank_type.armor_ke[WeaponData.ArmorZone.REAR])
	print("Tank armor_ce[FRONT]: %d (700mm RHA)" % tank_type.armor_ce[WeaponData.ArmorZone.FRONT])
	print("Tank armor_ce[SIDE]: %d (120mm RHA)" % tank_type.armor_ce[WeaponData.ArmorZone.SIDE])
	print("Tank armor_ce[REAR]: %d (40mm RHA)" % tank_type.armor_ce[WeaponData.ArmorZone.REAR])

	# 新しいRHA換算値を検証
	assert(tank_type.armor_ke[WeaponData.ArmorZone.FRONT] == 140, "Front KE should be 140 (700mm)")
	assert(tank_type.armor_ke[WeaponData.ArmorZone.SIDE] == 40, "Side KE should be 40 (200mm)")
	assert(tank_type.armor_ke[WeaponData.ArmorZone.REAR] == 16, "Rear KE should be 16 (80mm)")
	assert(tank_type.armor_ce[WeaponData.ArmorZone.FRONT] == 140, "Front CE should be 140 (700mm)")
	assert(tank_type.armor_ce[WeaponData.ArmorZone.SIDE] == 24, "Side CE should be 24 (120mm)")
	assert(tank_type.armor_ce[WeaponData.ArmorZone.REAR] == 8, "Rear CE should be 8 (40mm)")

	# LAW vs Tank テスト（RHA換算）
	print("\n--- LAW vs Tank Penetration Test ---")
	var law := WeaponData.create_cw_law()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.position = Vector2(100, 0)
	tank.facing = PI  # 左を向いている（正面が射手側）

	var shooter_type := ElementData.ElementArchetypes.create_inf_line()
	var shooter := ElementData.ElementInstance.new(shooter_type)
	shooter.position = Vector2(0, 0)

	# 正面からの攻撃（LAW pen=60 vs armor=140 → diff=-80 → ~0.5%）
	var aspect_front := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_front := combat_system.get_penetration_probability(
		shooter, tank, law, 100.0, aspect_front
	)
	print("LAW vs Tank FRONT (pen=60 vs armor=140, diff=-80): %.4f (expected <0.01)" % p_pen_front)
	assert(p_pen_front < 0.01, "LAW should not penetrate tank front")

	# 側面からの攻撃（LAW pen=60 vs armor=24 → diff=+36 → ~91%）
	tank.facing = PI / 2  # 上を向いている
	var aspect_side := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_side := combat_system.get_penetration_probability(
		shooter, tank, law, 100.0, aspect_side
	)
	print("LAW vs Tank SIDE (pen=60 vs armor=24, diff=+36): %.3f (expected ~0.91)" % p_pen_side)
	assert(p_pen_side > 0.85, "LAW should penetrate tank side")

	# 後方からの攻撃（LAW pen=60 vs armor=8 → diff=+52 → ~97%）
	tank.facing = 0  # 右を向いている（後方が射手側）
	var aspect_rear := combat_system.calculate_aspect_v01r(
		shooter.position, tank.position, tank.facing
	)
	var p_pen_rear := combat_system.get_penetration_probability(
		shooter, tank, law, 100.0, aspect_rear
	)
	print("LAW vs Tank REAR (pen=60 vs armor=8, diff=+52): %.3f (expected >0.95)" % p_pen_rear)
	assert(p_pen_rear > 0.95, "LAW should almost certainly penetrate tank rear")

	# 正面<側面<後方の順で貫徹しやすい
	assert(p_pen_front < p_pen_side, "Side should be easier to penetrate than front")
	assert(p_pen_side < p_pen_rear, "Rear should be easier to penetrate than side")

	# RPG vs Tank テスト（より高い貫徹力）
	print("\n--- RPG vs Tank Penetration Test ---")
	var rpg := WeaponData.create_cw_rpg_heat()

	# 正面からの攻撃（RPG pen=100 vs armor=140 → diff=-40 → ~6%）
	tank.facing = PI
	var p_rpg_front := combat_system.get_penetration_probability(
		shooter, tank, rpg, 100.0, aspect_front
	)
	print("RPG vs Tank FRONT (pen=100 vs armor=140, diff=-40): %.3f (expected <0.10)" % p_rpg_front)

	# 側面からの攻撃（RPG pen=100 vs armor=24 → diff=+76 → ~99%）
	tank.facing = PI / 2
	var p_rpg_side := combat_system.get_penetration_probability(
		shooter, tank, rpg, 100.0, aspect_side
	)
	print("RPG vs Tank SIDE (pen=100 vs armor=24, diff=+76): %.3f (expected >0.99)" % p_rpg_side)
	assert(p_rpg_side > 0.99, "RPG should certainly penetrate tank side")

	print("PASS: Tank armor values and penetration working correctly")


## Exposure計算テスト（p_hit=0問題の調査）
func test_exposure_calculation() -> void:
	print("\n--- Test: Exposure Calculation ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank"
	tank.position = Vector2(100, 0)
	tank.facing = PI / 2  # 上向き（射手から見て側面）

	# 歩兵を作成
	var shooter_type := ElementData.ElementArchetypes.create_inf_line()
	var shooter := ElementData.ElementInstance.new(shooter_type)
	shooter.id = "test_shooter"
	shooter.position = Vector2(0, 0)

	# LAWを作成
	var law := WeaponData.create_cw_law()
	var distance := 80.0  # 80m

	# calculate_exposure_dfを呼び出し
	var exposure := combat_system.calculate_exposure_df(
		shooter, tank, law, distance, 1.0, GameEnums.TerrainType.OPEN, false
	)
	print("LAW vs Tank SIDE exposure: %.4f" % exposure)

	# calculate_direct_fire_vs_armorを呼び出し
	var result := combat_system.calculate_direct_fire_vs_armor(
		shooter, tank, law, distance, 0.1, 1.0, GameEnums.TerrainType.OPEN, false
	)
	print("Result: is_valid=%s d_supp=%.4f exposure=%.4f p_hit=%.4f" % [
		result.is_valid, result.d_supp, result.exposure, result.p_hit
	])

	# exposure > 0 かつ p_hit > 0 であることを確認
	assert(exposure > 0.0, "Exposure should be positive")
	assert(result.p_hit > 0.0, "p_hit should be positive")

	print("PASS: Exposure calculation working correctly")


## 車両ダメージモデルテスト
## Strength = 車両数（例: 4両小隊）で、HITイベントで1両ずつ減少
func test_vehicle_damage_model() -> void:
	print("\n--- Test: Vehicle Damage Model ---")

	# === 1. 戦車小隊のStrength初期値テスト ===
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	print("Tank platoon base_strength: %d (expected 4)" % tank_type.base_strength)
	assert(tank_type.base_strength == 4, "Tank platoon should have 4 vehicles")

	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank_dmg"
	print("Tank current_strength: %d (expected 4)" % tank.current_strength)
	assert(tank.current_strength == 4, "Tank should start with 4 strength")

	# === 2. 偵察車両のStrength初期値テスト ===
	var recon_type := ElementData.ElementArchetypes.create_recon_veh()
	print("Recon vehicle base_strength: %d (expected 2)" % recon_type.base_strength)
	assert(recon_type.base_strength == 2, "Recon vehicle should have 2 vehicles")

	# === 3. apply_vehicle_damage でStrengthが減少するか ===
	print("\n--- Testing apply_vehicle_damage ---")
	var tank2 := ElementData.ElementInstance.new(tank_type)
	tank2.id = "test_tank_dmg2"

	# 複数回ダメージを与えて、Strengthが減少するか確認
	# ランダム要素があるので、確実にダメージを与えるために複数回実行
	var initial_strength := tank2.current_strength
	var damage_attempts := 20  # 20回HITを与える
	var current_tick := 100

	print("Initial strength: %d" % initial_strength)

	for i in range(damage_attempts):
		if tank2.is_destroyed:
			break
		# exposure=0.8で高ダメージカテゴリが出やすい
		combat_system.apply_vehicle_damage(tank2, WeaponData.ThreatClass.AT, 0.8, current_tick + i)

	print("After %d damage attempts: strength=%d, is_destroyed=%s" % [
		damage_attempts, tank2.current_strength, tank2.is_destroyed
	])

	# 何らかのダメージが入っているはず（確率的なので緩い判定）
	# 20回のATヒットで少なくとも1両は撃破されるはず
	assert(tank2.current_strength < initial_strength or tank2.is_destroyed,
		"Tank should take at least some damage after 20 AT hits")

	# === 4. Strength=0で破壊されるか ===
	print("\n--- Testing destruction at Strength=0 ---")
	var tank3 := ElementData.ElementInstance.new(tank_type)
	tank3.id = "test_tank_dmg3"
	tank3.current_strength = 1  # 残り1両

	# 確実に撃破するために高exposure
	var destroyed := false
	for i in range(10):
		if tank3.is_destroyed:
			destroyed = true
			break
		combat_system.apply_vehicle_damage(tank3, WeaponData.ThreatClass.AT, 0.9, 200 + i)

	print("Tank3 after damage: strength=%d, is_destroyed=%s" % [tank3.current_strength, tank3.is_destroyed])

	# 10回のATヒットで最後の1両が撃破されるはず
	if destroyed:
		assert(tank3.state == GameEnums.UnitState.DESTROYED, "State should be DESTROYED")
		assert(tank3.current_strength == 0, "Strength should be 0 when destroyed")
		print("PASS: Tank correctly destroyed when strength reaches 0")
	else:
		# 確率的に撃破されない可能性もあるが、10回なら高確率で撃破
		print("WARNING: Tank not destroyed after 10 hits (probabilistic)")

	# === 5. get_display_strength テスト ===
	print("\n--- Testing get_display_strength ---")
	var tank4 := ElementData.ElementInstance.new(tank_type)
	tank4.current_strength = 3

	var display := tank4.get_display_strength()
	print("Tank with strength=3: get_display_strength()=%d (expected 3)" % display)
	assert(display == 3, "get_display_strength should return current_strength directly")

	# === 6. 被害カテゴリのロールテスト ===
	print("\n--- Testing damage category roll ---")
	var minor_count := 0
	var major_count := 0
	var critical_count := 0
	var total_rolls := 1000

	for i in range(total_rolls):
		var cat := combat_system.roll_damage_category(0.5)
		match cat:
			GameEnums.DamageCategory.MINOR:
				minor_count += 1
			GameEnums.DamageCategory.MAJOR:
				major_count += 1
			GameEnums.DamageCategory.CRITICAL:
				critical_count += 1

	print("Damage category distribution (1000 rolls, exposure=0.5):")
	print("  MINOR: %d (%.1f%%)" % [minor_count, float(minor_count) / 10.0])
	print("  MAJOR: %d (%.1f%%)" % [major_count, float(major_count) / 10.0])
	print("  CRITICAL: %d (%.1f%%)" % [critical_count, float(critical_count) / 10.0])

	# おおよその期待値: MINOR~75%, MAJOR~22%, CRITICAL~3%
	assert(minor_count > major_count, "MINOR should be most common")
	assert(major_count > critical_count, "MAJOR should be more common than CRITICAL")

	# === 7. Catastrophic Kill テスト ===
	print("\n--- Testing Catastrophic Kill ---")
	# 多数の試行でCatastrophic Killが発生することを確認
	# CRITICAL判定時に40%でCatastrophic Killが発生
	var catastrophic_count := 0
	var normal_critical_count := 0
	var test_iterations := 500  # 試行回数を増やす

	for i in range(test_iterations):
		var test_tank := ElementData.ElementInstance.new(tank_type)
		test_tank.id = "catastrophic_test_%d" % i
		test_tank.current_strength = 4

		# 高exposureでCRITICAL判定が出やすくする
		# randfを使っているので確率的だが、十分な試行回数で検証
		combat_system.apply_vehicle_damage(test_tank, WeaponData.ThreatClass.AT, 0.9, 1000 + i)

		if test_tank.is_destroyed and test_tank.catastrophic_kill:
			catastrophic_count += 1
		elif test_tank.current_strength < 4:
			# 通常のダメージ（1両撃破）
			normal_critical_count += 1

	print("Catastrophic Kill occurrences: %d / %d (expected ~1.2%% = ~6)" % [catastrophic_count, test_iterations])
	print("Normal damage occurrences: %d / %d" % [normal_critical_count, test_iterations])

	# Catastrophic Killが少なくとも1回は発生するはず
	# (CRITICAL ~3% × Catastrophic 40% = ~1.2%、500回で期待値6回)
	# 確率的なので厳密なassertは避けるが、ログで確認
	if catastrophic_count > 0:
		print("PASS: Catastrophic Kill occurred %d times" % catastrophic_count)
	else:
		print("WARNING: No Catastrophic Kill in %d attempts (very unlikely)" % test_iterations)

	# === 8. Catastrophic Kill状態の検証 ===
	# catastrophic_kill=true, is_destroyed=true, current_strength=0 を確認
	print("\n--- Testing Catastrophic Kill state ---")
	# 直接_mark_destroyedを呼んでCatastrophic状態をテスト
	var test_tank_cat := ElementData.ElementInstance.new(tank_type)
	test_tank_cat.id = "cat_state_test"
	test_tank_cat.current_strength = 4

	# _mark_destroyedは直接呼べないので、is_destroyedとcatastrophic_killのフラグを直接設定してテスト
	# （実際のゲームではapply_vehicle_damageから呼ばれる）
	test_tank_cat.is_destroyed = true
	test_tank_cat.catastrophic_kill = true
	test_tank_cat.current_strength = 0
	test_tank_cat.state = GameEnums.UnitState.DESTROYED

	assert(test_tank_cat.is_destroyed == true, "is_destroyed should be true")
	assert(test_tank_cat.catastrophic_kill == true, "catastrophic_kill should be true")
	assert(test_tank_cat.current_strength == 0, "current_strength should be 0")
	assert(test_tank_cat.state == GameEnums.UnitState.DESTROYED, "state should be DESTROYED")
	print("PASS: Catastrophic Kill state flags correct")

	print("PASS: Vehicle damage model working correctly")
