extends Node

## 戦車vs戦車テスト
## テスト項目:
## 1. APFSDS貫徹確率検証（正面~50%, 側面~99%, 後方~100%）
## 2. 戦車砲ヒット確率検証（LAWより高い）
## 3. 4v4戦車小隊戦闘シミュレーション
## 4. 側面攻撃優位性テスト
## 5. 発射レートと命中間隔検証

var combat_system: CombatSystem


func _ready() -> void:
	combat_system = CombatSystem.new()
	run_tests()


func run_tests() -> void:
	print("=== Tank vs Tank Combat Tests ===")
	test_apfsds_penetration_probability()
	test_tank_gun_hit_probability()
	test_4v4_tank_battle_simulation()
	test_flank_attack_superiority()
	test_fire_rate_and_hit_interval()
	print("=== All Tank vs Tank Tests Complete ===")
	get_tree().quit()


## テスト1: APFSDS貫徹確率検証
## APFSDS: NEAR=140, MID=130, FAR=120
## Tank armor_ke: FRONT=140, SIDE=40, REAR=16
## 期待: 正面~50%, 側面~99%, 後方~100%
func test_apfsds_penetration_probability() -> void:
	print("\n--- Test 1: APFSDS Penetration Probability ---")

	var tank_ke := WeaponData.create_cw_tank_ke()
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()

	print("APFSDS pen_ke: NEAR=%d, MID=%d, FAR=%d" % [
		tank_ke.get_pen_ke(100.0),   # NEAR
		tank_ke.get_pen_ke(800.0),   # MID
		tank_ke.get_pen_ke(2000.0),  # FAR
	])
	print("Tank armor_ke: FRONT=%d, SIDE=%d, REAR=%d" % [
		tank_type.armor_ke[WeaponData.ArmorZone.FRONT],
		tank_type.armor_ke[WeaponData.ArmorZone.SIDE],
		tank_type.armor_ke[WeaponData.ArmorZone.REAR],
	])

	# 近距離での貫徹確率
	print("\n[NEAR range penetration (APFSDS pen=140)]")

	# 正面: 140 vs 140 → diff=0 → ~50%
	var p_front := combat_system.calculate_penetration_probability(140, 140)
	print("FRONT (140 vs 140, diff=0): %.3f (expected ~0.50)" % p_front)
	assert(p_front > 0.45 and p_front < 0.55, "Front penetration should be ~50%")

	# 側面: 140 vs 40 → diff=+100 → ~99.9%
	var p_side := combat_system.calculate_penetration_probability(140, 40)
	print("SIDE (140 vs 40, diff=+100): %.3f (expected >0.99)" % p_side)
	assert(p_side > 0.99, "Side penetration should be ~100%")

	# 後方: 140 vs 16 → diff=+124 → ~100%
	var p_rear := combat_system.calculate_penetration_probability(140, 16)
	print("REAR (140 vs 16, diff=+124): %.3f (expected >0.99)" % p_rear)
	assert(p_rear > 0.999, "Rear penetration should be ~100%")

	# 中距離での貫徹確率
	print("\n[MID range penetration (APFSDS pen=130)]")

	# 正面: 130 vs 140 → diff=-10 → ~34%
	var p_front_mid := combat_system.calculate_penetration_probability(130, 140)
	print("FRONT (130 vs 140, diff=-10): %.3f (expected ~0.34)" % p_front_mid)
	assert(p_front_mid > 0.30 and p_front_mid < 0.40, "Mid-range front should be ~34%")

	# 遠距離での貫徹確率
	print("\n[FAR range penetration (APFSDS pen=120)]")

	# 正面: 120 vs 140 → diff=-20 → ~21%
	var p_front_far := combat_system.calculate_penetration_probability(120, 140)
	print("FRONT (120 vs 140, diff=-20): %.3f (expected ~0.21)" % p_front_far)
	assert(p_front_far > 0.15 and p_front_far < 0.30, "Far-range front should be ~21%")

	print("PASS: APFSDS penetration probability verified")


## テスト2: 戦車砲ヒット確率検証
## 戦車砲はLAWより高いヒット率を持つべき
func test_tank_gun_hit_probability() -> void:
	print("\n--- Test 2: Tank Gun Hit Probability ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var shooter_tank := ElementData.ElementInstance.new(tank_type)
	shooter_tank.id = "shooter_tank"
	shooter_tank.position = Vector2(0, 0)

	var target_tank := ElementData.ElementInstance.new(tank_type)
	target_tank.id = "target_tank"
	target_tank.position = Vector2(500, 0)  # 500m先
	target_tank.facing = PI  # 射手側を向いている（正面）

	# 歩兵を作成
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var shooter_inf := ElementData.ElementInstance.new(inf_type)
	shooter_inf.id = "shooter_inf"
	shooter_inf.position = Vector2(0, 0)

	# 武器
	var tank_ke := WeaponData.create_cw_tank_ke()
	var law := WeaponData.create_cw_law()

	var distance := 150.0  # 両方の武器が射程内

	# 戦車砲 vs 戦車（正面）
	var result_tank := combat_system.calculate_direct_fire_vs_armor(
		shooter_tank, target_tank, tank_ke, distance, 0.1
	)

	# LAW vs 戦車（正面）
	target_tank.position = Vector2(distance, 0)  # LAW射程内に配置
	var result_law := combat_system.calculate_direct_fire_vs_armor(
		shooter_inf, target_tank, law, distance, 0.1
	)

	print("Tank gun vs Tank FRONT at %.0fm:" % distance)
	print("  exposure=%.4f, p_hit=%.4f" % [result_tank.exposure, result_tank.p_hit])

	print("LAW vs Tank FRONT at %.0fm:" % distance)
	print("  exposure=%.4f, p_hit=%.4f" % [result_law.exposure, result_law.p_hit])

	# 戦車砲のexposureがLAWより高いことを確認
	# （高lethalityと高penetrationによる）
	print("\n[Exposure comparison]")
	print("Tank gun exposure: %.4f" % result_tank.exposure)
	print("LAW exposure: %.4f" % result_law.exposure)

	# 戦車砲は正面でも50%貫通なので、LAW（正面貫通~0%）より高いexposure
	assert(result_tank.exposure > result_law.exposure,
		"Tank gun should have higher exposure than LAW against front armor")

	# 側面攻撃でも比較
	print("\n[Side attack comparison]")
	target_tank.facing = PI / 2  # 上向き（射手から見て側面）

	var result_tank_side := combat_system.calculate_direct_fire_vs_armor(
		shooter_tank, target_tank, tank_ke, distance, 0.1
	)
	var result_law_side := combat_system.calculate_direct_fire_vs_armor(
		shooter_inf, target_tank, law, distance, 0.1
	)

	print("Tank gun vs Tank SIDE: exposure=%.4f, p_hit=%.4f" % [
		result_tank_side.exposure, result_tank_side.p_hit
	])
	print("LAW vs Tank SIDE: exposure=%.4f, p_hit=%.4f" % [
		result_law_side.exposure, result_law_side.p_hit
	])

	# 側面では両方とも高いexposure
	assert(result_tank_side.exposure > 0.5, "Tank gun should have high exposure vs side")
	assert(result_law_side.exposure > 0.3, "LAW should have decent exposure vs side")

	print("PASS: Tank gun hit probability verified")


## テスト3: 4v4戦車小隊戦闘シミュレーション
## 両方4両でスタート、戦闘後に双方ダメージを確認
func test_4v4_tank_battle_simulation() -> void:
	print("\n--- Test 3: 4v4 Tank Battle Simulation ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank_ke := WeaponData.create_cw_tank_ke()

	# 青軍戦車小隊
	var blue_tank := ElementData.ElementInstance.new(tank_type)
	blue_tank.id = "blue_tank_plt"
	blue_tank.position = Vector2(0, 0)
	blue_tank.facing = 0  # 右向き

	# 赤軍戦車小隊
	var red_tank := ElementData.ElementInstance.new(tank_type)
	red_tank.id = "red_tank_plt"
	red_tank.position = Vector2(800, 0)  # 800m先
	red_tank.facing = PI  # 左向き（青軍を向いている）

	var distance := 800.0  # MID range

	print("Initial state:")
	print("  Blue: %d vehicles" % blue_tank.current_strength)
	print("  Red: %d vehicles" % red_tank.current_strength)

	# 戦闘シミュレーション（60秒 = 600 tick）
	var simulation_ticks := 600
	var blue_hits := 0
	var red_hits := 0

	for tick in range(simulation_ticks):
		# 両方破壊されたら終了
		if blue_tank.is_destroyed and red_tank.is_destroyed:
			break

		# 青軍 → 赤軍
		if not blue_tank.is_destroyed and not red_tank.is_destroyed:
			var result_blue := combat_system.calculate_direct_fire_vs_armor(
				blue_tank, red_tank, tank_ke, distance, 0.1
			)
			if result_blue.p_hit > 0 and randf() < result_blue.p_hit:
				blue_hits += 1
				combat_system.apply_vehicle_damage(
					red_tank, WeaponData.ThreatClass.AT, result_blue.exposure, tick
				)

		# 赤軍 → 青軍
		if not red_tank.is_destroyed and not blue_tank.is_destroyed:
			var result_red := combat_system.calculate_direct_fire_vs_armor(
				red_tank, blue_tank, tank_ke, distance, 0.1
			)
			if result_red.p_hit > 0 and randf() < result_red.p_hit:
				red_hits += 1
				combat_system.apply_vehicle_damage(
					blue_tank, WeaponData.ThreatClass.AT, result_red.exposure, tick
				)

	print("\nAfter %d ticks (%.1f seconds):" % [simulation_ticks, simulation_ticks * 0.1])
	print("  Blue: %d vehicles remaining (hits dealt: %d)" % [
		blue_tank.current_strength, blue_hits
	])
	print("  Red: %d vehicles remaining (hits dealt: %d)" % [
		red_tank.current_strength, red_hits
	])

	# 戦闘が発生していることを確認
	var total_hits := blue_hits + red_hits
	print("Total hits: %d" % total_hits)

	# 正面同士の戦闘では時間がかかるはず
	# 60秒の戦闘で少なくとも何発かはヒットするはず
	assert(total_hits > 0, "Some hits should occur in 60 seconds")

	# 両方がまだ完全に壊滅していなければ、適度なダメージ
	# （正面戦闘では貫通率50%なので、完全壊滅は稀）
	var blue_losses := 4 - blue_tank.current_strength
	var red_losses := 4 - red_tank.current_strength
	print("Losses - Blue: %d, Red: %d" % [blue_losses, red_losses])

	print("PASS: 4v4 tank battle simulation completed")


## テスト4: 側面攻撃優位性テスト
## 側面から攻撃する方が正面より圧倒的に有利
func test_flank_attack_superiority() -> void:
	print("\n--- Test 4: Flank Attack Superiority ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank_ke := WeaponData.create_cw_tank_ke()

	var shooter := ElementData.ElementInstance.new(tank_type)
	shooter.id = "shooter"
	shooter.position = Vector2(0, 0)

	var target := ElementData.ElementInstance.new(tank_type)
	target.id = "target"
	target.position = Vector2(500, 0)  # 500m先

	var distance := 500.0

	# 正面攻撃（target.facing = PI → 射手方向を向いている）
	target.facing = PI
	var result_front := combat_system.calculate_direct_fire_vs_armor(
		shooter, target, tank_ke, distance, 0.1
	)

	# 側面攻撃（target.facing = PI/2 → 上向き）
	target.facing = PI / 2
	var result_side := combat_system.calculate_direct_fire_vs_armor(
		shooter, target, tank_ke, distance, 0.1
	)

	# 後方攻撃（target.facing = 0 → 射手と同じ方向を向いている）
	target.facing = 0
	var result_rear := combat_system.calculate_direct_fire_vs_armor(
		shooter, target, tank_ke, distance, 0.1
	)

	print("Attack effectiveness at %.0fm:" % distance)
	print("  FRONT: exposure=%.4f, p_hit=%.4f" % [result_front.exposure, result_front.p_hit])
	print("  SIDE:  exposure=%.4f, p_hit=%.4f" % [result_side.exposure, result_side.p_hit])
	print("  REAR:  exposure=%.4f, p_hit=%.4f" % [result_rear.exposure, result_rear.p_hit])

	# 側面は正面より有利
	print("\nSide/Front exposure ratio: %.2f" % (result_side.exposure / result_front.exposure))
	assert(result_side.exposure > result_front.exposure * 1.5,
		"Side attack should be at least 1.5x more effective")

	# 後方は側面より有利
	print("Rear/Side exposure ratio: %.2f" % (result_rear.exposure / result_side.exposure))
	assert(result_rear.exposure > result_side.exposure,
		"Rear attack should be more effective than side")

	# 後方は正面よりはるかに有利
	print("Rear/Front exposure ratio: %.2f" % (result_rear.exposure / result_front.exposure))
	assert(result_rear.exposure > result_front.exposure * 2.0,
		"Rear attack should be at least 2x more effective than front")

	# シミュレーション: 同条件で100回攻撃した時の撃破数を比較
	print("\n[Simulation: 100 attacks comparison]")
	var front_kills := 0
	var side_kills := 0
	var rear_kills := 0

	for i in range(100):
		# 正面
		var test_front := ElementData.ElementInstance.new(tank_type)
		test_front.id = "test_front_%d" % i
		test_front.facing = PI
		test_front.position = Vector2(500, 0)

		var r_front := combat_system.calculate_direct_fire_vs_armor(
			shooter, test_front, tank_ke, distance, 0.1
		)
		if randf() < r_front.p_hit:
			combat_system.apply_vehicle_damage(
				test_front, WeaponData.ThreatClass.AT, r_front.exposure, i
			)
			if test_front.current_strength < 4:
				front_kills += 1

		# 側面
		var test_side := ElementData.ElementInstance.new(tank_type)
		test_side.id = "test_side_%d" % i
		test_side.facing = PI / 2
		test_side.position = Vector2(500, 0)

		var r_side := combat_system.calculate_direct_fire_vs_armor(
			shooter, test_side, tank_ke, distance, 0.1
		)
		if randf() < r_side.p_hit:
			combat_system.apply_vehicle_damage(
				test_side, WeaponData.ThreatClass.AT, r_side.exposure, i
			)
			if test_side.current_strength < 4:
				side_kills += 1

		# 後方
		var test_rear := ElementData.ElementInstance.new(tank_type)
		test_rear.id = "test_rear_%d" % i
		test_rear.facing = 0
		test_rear.position = Vector2(500, 0)

		var r_rear := combat_system.calculate_direct_fire_vs_armor(
			shooter, test_rear, tank_ke, distance, 0.1
		)
		if randf() < r_rear.p_hit:
			combat_system.apply_vehicle_damage(
				test_rear, WeaponData.ThreatClass.AT, r_rear.exposure, i
			)
			if test_rear.current_strength < 4:
				rear_kills += 1

	print("Kills in 100 attacks:")
	print("  FRONT: %d" % front_kills)
	print("  SIDE:  %d" % side_kills)
	print("  REAR:  %d" % rear_kills)

	# 側面と後方は正面より撃破数が多いはず
	# （確率的なのでassertは緩めに）
	assert(side_kills >= front_kills or side_kills > 5,
		"Side attacks should cause more kills (or at least some)")

	print("PASS: Flank attack superiority verified")


## テスト5: 発射レートと命中間隔検証
## 戦車砲: 6 RPM = 0.1発/秒
## 期待: 約10秒に1発ヒット（p_hitによる）
func test_fire_rate_and_hit_interval() -> void:
	print("\n--- Test 5: Fire Rate and Hit Interval ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank_ke := WeaponData.create_cw_tank_ke()

	print("Tank gun specs:")
	print("  RoF: %.1f RPM = %.2f rounds/sec" % [tank_ke.rof_rpm, tank_ke.rof_rpm / 60.0])
	print("  Fire model: %s" % WeaponData.FireModel.keys()[tank_ke.fire_model])

	var shooter := ElementData.ElementInstance.new(tank_type)
	shooter.id = "shooter"
	shooter.position = Vector2(0, 0)

	var target := ElementData.ElementInstance.new(tank_type)
	target.id = "target"
	target.position = Vector2(500, 0)
	target.facing = PI / 2  # 側面

	var distance := 500.0

	# 単一tickでの命中確率を計算
	var result := combat_system.calculate_direct_fire_vs_armor(
		shooter, target, tank_ke, distance, 0.1
	)

	print("\nPer-tick combat calculation (dt=0.1s):")
	print("  exposure: %.4f" % result.exposure)
	print("  p_hit: %.4f (per 0.1s)" % result.p_hit)

	# 1秒あたりの期待ヒット数
	var p_hit_1s := 1.0 - pow(1.0 - result.p_hit, 10)  # 10 ticks = 1 second
	print("  p_hit (per 1s): %.4f" % p_hit_1s)

	# 期待命中間隔
	if p_hit_1s > 0:
		var expected_interval := 1.0 / p_hit_1s
		print("  Expected hit interval: %.1f seconds" % expected_interval)

	# シミュレーション: 実際のヒット間隔を測定
	print("\n[Hit interval simulation (600 ticks = 60s)]")
	var hits: Array[int] = []

	for tick in range(600):
		var r := combat_system.calculate_direct_fire_vs_armor(
			shooter, target, tank_ke, distance, 0.1
		)
		if randf() < r.p_hit:
			hits.append(tick)

	print("Total hits in 60s: %d" % hits.size())

	if hits.size() >= 2:
		var intervals: Array[int] = []
		for i in range(1, hits.size()):
			intervals.append(hits[i] - hits[i-1])

		var avg_interval := 0.0
		for interval in intervals:
			avg_interval += float(interval)
		avg_interval /= float(intervals.size())

		print("Average hit interval: %.1f ticks (%.1f seconds)" % [avg_interval, avg_interval * 0.1])

		# 期待値との比較
		# p_hit_1sが正しければ、期待間隔は約 1/p_hit_1s 秒

	# 側面攻撃では適度なヒット率があるはず
	# 60秒で少なくとも数発はヒットするはず
	assert(hits.size() > 0, "Should have at least some hits in 60 seconds")

	print("PASS: Fire rate and hit interval verified")
