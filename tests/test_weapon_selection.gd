extends SceneTree

## 武器選択テスト
## godot --headless -s tests/test_weapon_selection.gd
## v0.3: 現実的な弾種選択ロジックのテスト

func _init() -> void:
	print("=== Weapon Selection Test v0.3 ===")

	# テスト: 武器のprojectile_speed_mpsが設定されているか
	_test_projectile_speed_mps()

	# テスト: 歩兵 vs 戦車（複数距離）
	_test_infantry_vs_tank_at_distances()

	# テスト: 戦車 vs 歩兵（複数距離）
	_test_tank_vs_infantry_at_distances()

	# テスト: 戦車 vs 戦車（弾種選択）
	_test_tank_vs_tank()

	# テスト: IFV vs 各種目標
	_test_ifv_weapon_selection()

	# テスト: should_use_tank_combat
	_test_should_use_tank_combat()

	# テスト: 累積装甲ダメージ
	_test_accumulated_armor_damage()

	print("\n=== Tests Complete ===")
	quit()


func _test_infantry_vs_tank_at_distances() -> void:
	print("\n--- Test: Infantry vs Tank at various distances ---")

	# 歩兵を作成
	var infantry_type := ElementData.ElementArchetypes.create_inf_line()
	var infantry := ElementData.ElementInstance.new(infantry_type)
	infantry.id = "TEST_INF"
	infantry.faction = GameEnums.Faction.BLUE
	infantry.position = Vector2(0, 0)

	# 武装を装備
	var all_weapons := WeaponData.get_all_concrete_weapons()
	infantry.weapons.append(all_weapons["CW_RIFLE_STD"])
	infantry.weapons.append(all_weapons["CW_CARL_GUSTAF"])
	infantry.primary_weapon = infantry.weapons[0]

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "TEST_TANK"
	tank.faction = GameEnums.Faction.RED

	print("Infantry weapons: %s" % _get_weapon_ids(infantry.weapons))
	print("Tank armor_class: %d" % tank_type.armor_class)
	print("")
	print("CW_RIFLE_STD: max_range=%dm, preferred=%d" % [
		int(all_weapons["CW_RIFLE_STD"].max_range_m),
		all_weapons["CW_RIFLE_STD"].preferred_target
	])
	print("CW_CARL_GUSTAF: max_range=%dm, preferred=%d" % [
		int(all_weapons["CW_CARL_GUSTAF"].max_range_m),
		all_weapons["CW_CARL_GUSTAF"].preferred_target
	])
	print("")

	# 武器選択テスト（複数距離）
	var combat := CombatSystem.new()

	print("Distance | Selected Weapon | Expected | Result")
	print("--------------------------------------------------")

	var all_pass := true
	# Carl Gustaf射程: 20-500m
	var test_cases: Array = [
		[100, "CW_CARL_GUSTAF"],
		[200, "CW_CARL_GUSTAF"],
		[300, "CW_CARL_GUSTAF"],
		[400, "CW_CARL_GUSTAF"],
		[500, "CW_CARL_GUSTAF"],
		[510, ""],  # Carl Gustaf射程外、RIFLEは装甲に効果なし
	]

	for test_data in test_cases:
		var dist: int = test_data[0]
		var expected: String = test_data[1]

		tank.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(infantry, tank, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		var passed: bool = (selected_id == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %15s | %8s | %s" % [dist, selected_id if selected_id != "" else "(none)", expected if expected != "" else "(none)", result])

	print("")
	if all_pass:
		print("All Infantry vs Tank tests PASSED")
	else:
		print("Some Infantry vs Tank tests FAILED")


func _test_tank_vs_infantry_at_distances() -> void:
	print("\n--- Test: Tank vs Infantry at various distances ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "TEST_TANK"
	tank.faction = GameEnums.Faction.RED
	tank.position = Vector2(0, 0)

	# 武装を装備
	var all_weapons := WeaponData.get_all_concrete_weapons()
	tank.weapons.append(all_weapons["CW_TANK_KE"])
	tank.weapons.append(all_weapons["CW_TANK_HEATMP"])
	tank.weapons.append(all_weapons["CW_COAX_MG"])
	tank.primary_weapon = tank.weapons[0]

	# 歩兵を作成
	var infantry_type := ElementData.ElementArchetypes.create_inf_line()
	var infantry := ElementData.ElementInstance.new(infantry_type)
	infantry.id = "TEST_INF"
	infantry.faction = GameEnums.Faction.BLUE

	print("Tank weapons: %s" % _get_weapon_ids(tank.weapons))
	print("Infantry armor_class: %d" % infantry_type.armor_class)
	print("")
	print("CW_TANK_KE: max_range=%dm, preferred=%d (ARMOR)" % [
		int(all_weapons["CW_TANK_KE"].max_range_m),
		all_weapons["CW_TANK_KE"].preferred_target
	])
	print("CW_TANK_HEATMP: max_range=%dm, preferred=%d (ANY)" % [
		int(all_weapons["CW_TANK_HEATMP"].max_range_m),
		all_weapons["CW_TANK_HEATMP"].preferred_target
	])
	print("CW_COAX_MG: max_range=%dm, preferred=%d (SOFT)" % [
		int(all_weapons["CW_COAX_MG"].max_range_m),
		all_weapons["CW_COAX_MG"].preferred_target
	])
	print("")

	# 武器選択テスト（複数距離）
	var combat := CombatSystem.new()

	print("Distance | Selected Weapon | Expected | Result")
	print("--------------------------------------------------")

	var all_pass := true
	var test_cases: Array = [
		[100, "CW_COAX_MG"],   # COAX_MG射程内
		[200, "CW_COAX_MG"],   # COAX_MG射程内
		[500, "CW_COAX_MG"],   # COAX_MG射程内（500m）
		[800, "CW_COAX_MG"],   # COAX_MG射程限界（800m）
		[1000, "CW_TANK_HEATMP"],  # COAX_MG射程外、HEATMP使用
	]

	for test_data in test_cases:
		var dist: int = test_data[0]
		var expected: String = test_data[1]

		infantry.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(tank, infantry, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		var passed: bool = (selected_id == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %15s | %8s | %s" % [dist, selected_id if selected_id != "" else "(none)", expected, result])

	print("")
	if all_pass:
		print("All Tank vs Infantry tests PASSED")
	else:
		print("Some Tank vs Infantry tests FAILED")


func _get_weapon_ids(weapons: Array[WeaponData.WeaponType]) -> String:
	var ids: Array[String] = []
	for w in weapons:
		ids.append(w.id)
	return ", ".join(ids)


func _test_projectile_speed_mps() -> void:
	print("\n--- Test: Projectile Speed (projectile_speed_mps) ---")

	var all_weapons := WeaponData.get_all_concrete_weapons()
	var all_pass := true

	# AT武器には projectile_speed_mps が設定されている必要がある
	# 設定がないと弾道シミュレーションがスキップされ、ダメージが適用されない
	var at_weapons: Array = [
		["CW_TANK_KE", 1700.0, "APFSDS ~1700m/s"],
		["CW_TANK_HEATMP", 1000.0, "HEAT ~1000m/s"],
		["CW_AUTOCANNON_30", 1100.0, "30mm APDS ~1100m/s"],
		["CW_ATGM", 300.0, "ATGM ~300m/s"],
		["CW_RPG_HEAT", 300.0, "RPG ~300m/s"],
		["CW_CARL_GUSTAF", 255.0, "Carl Gustaf ~255m/s"],
	]

	print("Weapon ID          | Speed (m/s) | Expected    | Result")
	print("-----------------------------------------------------------")

	for weapon_info in at_weapons:
		var weapon_id: String = weapon_info[0]
		var expected_speed: float = weapon_info[1]
		var _desc: String = weapon_info[2]  # 参考情報（未使用）

		var weapon: WeaponData.WeaponType = all_weapons[weapon_id]
		var actual_speed: float = weapon.projectile_speed_mps

		# 速度が設定されているか（0より大きい）
		var has_speed: bool = actual_speed > 0.0
		# 期待値に近いか（±10%の許容）
		var speed_ok: bool = abs(actual_speed - expected_speed) < expected_speed * 0.1
		var passed: bool = has_speed and speed_ok

		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%-18s | %11.1f | %11.1f | %s" % [weapon_id, actual_speed, expected_speed, result])

	print("")

	# 戦車砲はDISCRETEであるべき
	print("Tank Gun fire_model check (should be DISCRETE):")
	var tank_guns := ["CW_TANK_KE", "CW_TANK_HEATMP"]
	for weapon_id in tank_guns:
		var weapon: WeaponData.WeaponType = all_weapons[weapon_id]
		var is_discrete: bool = weapon.fire_model == WeaponData.FireModel.DISCRETE
		var has_rof: bool = weapon.rof_rpm > 0.0
		var result: String = "OK" if (is_discrete and has_rof) else "NG"
		all_pass = all_pass and is_discrete and has_rof
		print("  %s: fire_model=%s, rof_rpm=%.1f - %s" % [
			weapon_id,
			"DISCRETE" if is_discrete else "CONTINUOUS",
			weapon.rof_rpm,
			result
		])

	print("")
	if all_pass:
		print("All Projectile Speed tests PASSED")
	else:
		print("Some Projectile Speed tests FAILED")


func _test_tank_vs_tank() -> void:
	print("\n--- Test: Tank vs Tank (Ammo Selection) ---")

	# 戦車を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "TEST_TANK_BLUE"
	tank.faction = GameEnums.Faction.BLUE
	tank.position = Vector2(0, 0)

	# 武装を装備
	var all_weapons := WeaponData.get_all_concrete_weapons()
	tank.weapons.append(all_weapons["CW_TANK_KE"])
	tank.weapons.append(all_weapons["CW_TANK_HEATMP"])
	tank.weapons.append(all_weapons["CW_COAX_MG"])
	tank.primary_weapon = tank.weapons[0]

	# 敵戦車を作成
	var enemy_tank := ElementData.ElementInstance.new(tank_type)
	enemy_tank.id = "TEST_TANK_RED"
	enemy_tank.faction = GameEnums.Faction.RED

	print("Blue Tank weapons: %s" % _get_weapon_ids(tank.weapons))
	print("Red Tank armor_class: %d (Heavy)" % tank_type.armor_class)
	print("")

	# 武器選択テスト
	var combat := CombatSystem.new()

	print("Distance | Selected Weapon | Expected     | Result")
	print("-----------------------------------------------------")

	var all_pass := true
	# 重装甲にはAPFSDSが最優先
	var test_cases: Array = [
		[500, "CW_TANK_KE"],    # Near range
		[1000, "CW_TANK_KE"],   # Mid range
		[2000, "CW_TANK_KE"],   # Far range
	]

	for test_data in test_cases:
		var dist: int = test_data[0]
		var expected: String = test_data[1]

		enemy_tank.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(tank, enemy_tank, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		var passed: bool = (selected_id == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %15s | %12s | %s" % [dist, selected_id, expected, result])

	print("")
	if all_pass:
		print("All Tank vs Tank tests PASSED")
	else:
		print("Some Tank vs Tank tests FAILED")


func _test_ifv_weapon_selection() -> void:
	print("\n--- Test: IFV Weapon Selection ---")

	# IFVを作成
	var ifv_type := ElementData.ElementArchetypes.get_archetype("IFV_PLT")
	if not ifv_type:
		print("ERROR: IFV_PLT archetype not found!")
		return

	var ifv := ElementData.ElementInstance.new(ifv_type)
	ifv.id = "TEST_IFV"
	ifv.faction = GameEnums.Faction.BLUE
	ifv.position = Vector2(0, 0)

	# 武装を装備
	var all_weapons := WeaponData.get_all_concrete_weapons()
	ifv.weapons.append(all_weapons["CW_AUTOCANNON_30"])
	ifv.weapons.append(all_weapons["CW_ATGM"])
	ifv.weapons.append(all_weapons["CW_COAX_MG"])
	ifv.primary_weapon = ifv.weapons[0]

	print("IFV weapons: %s" % _get_weapon_ids(ifv.weapons))
	print("")

	var combat := CombatSystem.new()
	var all_pass := true

	# Test 0: IFV vs IFV（中装甲）- ATGMかオートキャノンか
	print("Test 0: IFV vs IFV (Medium Armor)")
	var enemy_ifv := ElementData.ElementInstance.new(ifv_type)
	enemy_ifv.id = "TEST_IFV_RED"
	enemy_ifv.faction = GameEnums.Faction.RED

	print("Distance | Selected Weapon | Expected  | Result")
	print("--------------------------------------------------")

	var ifv_test_cases: Array = [
		[500, "CW_AUTOCANNON_30"],   # 500mではオートキャノンが効率的
		[1000, "CW_ATGM"],  # 1000mではATGMの殺傷力が優先される
	]

	for test_data in ifv_test_cases:
		var dist: int = test_data[0]
		var expected: String = test_data[1]

		enemy_ifv.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(ifv, enemy_ifv, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		var passed: bool = (selected_id == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %15s | %9s | %s" % [dist, selected_id if selected_id != "" else "(none)", expected, result])

	print("")

	# Test 1: IFV vs 戦車（重装甲）
	print("Test 1: IFV vs Tank (Heavy Armor)")
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var enemy_tank := ElementData.ElementInstance.new(tank_type)
	enemy_tank.id = "TEST_TANK_RED"
	enemy_tank.faction = GameEnums.Faction.RED

	print("Distance | Selected Weapon | Expected | Result")
	print("--------------------------------------------------")

	var tank_test_cases: Array = [
		[500, "CW_ATGM"],    # ATGM最優先
		[1500, "CW_ATGM"],   # 長距離もATGM
		[3000, "CW_ATGM"],   # 最大射程でもATGM
	]

	for test_data in tank_test_cases:
		var dist: int = test_data[0]
		var expected: String = test_data[1]

		enemy_tank.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(ifv, enemy_tank, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		var passed: bool = (selected_id == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %15s | %8s | %s" % [dist, selected_id if selected_id != "" else "(none)", expected, result])

	# Test 2: IFV vs 歩兵（ソフト）
	print("\nTest 2: IFV vs Infantry (Soft Target)")
	var infantry_type := ElementData.ElementArchetypes.create_inf_line()
	var infantry := ElementData.ElementInstance.new(infantry_type)
	infantry.id = "TEST_INF_RED"
	infantry.faction = GameEnums.Faction.RED

	print("Distance | Selected Weapon  | NOT Expected | Result")
	print("-----------------------------------------------------")

	var infantry_test_cases: Array = [
		[300, "CW_ATGM"],   # ATGMは歩兵に使わない
		[600, "CW_ATGM"],
		[1000, "CW_ATGM"],
	]

	for test_data in infantry_test_cases:
		var dist: int = test_data[0]
		var not_expected: String = test_data[1]

		infantry.position = Vector2(float(dist), 0)
		var selected := combat.select_best_weapon(ifv, infantry, float(dist), false)
		var selected_id: String = selected.id if selected else ""

		# ATGMが選ばれていなければOK
		var passed: bool = (selected_id != not_expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		print("%7dm | %16s | not %7s | %s" % [dist, selected_id if selected_id != "" else "(none)", not_expected, result])

	print("")
	if all_pass:
		print("All IFV Weapon Selection tests PASSED")
	else:
		print("Some IFV Weapon Selection tests FAILED")


func _test_should_use_tank_combat() -> void:
	print("\n--- Test: should_use_tank_combat ---")

	var combat := CombatSystem.new()
	var all_weapons := WeaponData.get_all_concrete_weapons()
	var all_pass := true

	# 戦車
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "TEST_TANK"
	tank.faction = GameEnums.Faction.BLUE

	# IFV
	var ifv_type := ElementData.ElementArchetypes.get_archetype("IFV_PLT")
	var ifv: ElementData.ElementInstance = null
	if ifv_type:
		ifv = ElementData.ElementInstance.new(ifv_type)
		ifv.id = "TEST_IFV"
		ifv.faction = GameEnums.Faction.RED

	# 歩兵
	var infantry_type := ElementData.ElementArchetypes.create_inf_line()
	var infantry := ElementData.ElementInstance.new(infantry_type)
	infantry.id = "TEST_INF"
	infantry.faction = GameEnums.Faction.RED

	print("Target         | Weapon        | armor_class | Expected | Result")
	print("------------------------------------------------------------------")

	# Test cases: [shooter, target, weapon, expected_result]
	var test_cases: Array = []

	# 戦車 vs 戦車 with APFSDS → true
	test_cases.append([tank, tank, all_weapons["CW_TANK_KE"], true, "Tank vs Tank (KE)"])

	# 戦車 vs 戦車 with HEAT → true
	test_cases.append([tank, tank, all_weapons["CW_TANK_HEATMP"], true, "Tank vs Tank (HEAT)"])

	# IFV vs IFV with ATGM → true (armor_class = 2)
	if ifv:
		test_cases.append([ifv, ifv, all_weapons["CW_ATGM"], true, "IFV vs IFV (ATGM)"])

	# Tank vs IFV with APFSDS → true (armor_class = 2)
	if ifv:
		test_cases.append([tank, ifv, all_weapons["CW_TANK_KE"], true, "Tank vs IFV (KE)"])

	# Tank vs Infantry with APFSDS → false (armor_class = 0)
	test_cases.append([tank, infantry, all_weapons["CW_TANK_KE"], false, "Tank vs Inf (KE)"])

	# IFV vs Infantry with ATGM → false
	if ifv:
		test_cases.append([ifv, infantry, all_weapons["CW_ATGM"], false, "IFV vs Inf (ATGM)"])

	# Tank vs Tank with Coax MG → false (not AT weapon)
	test_cases.append([tank, tank, all_weapons["CW_COAX_MG"], false, "Tank vs Tank (MG)"])

	for test_data in test_cases:
		var shooter: ElementData.ElementInstance = test_data[0]
		var target: ElementData.ElementInstance = test_data[1]
		var weapon: WeaponData.WeaponType = test_data[2]
		var expected: bool = test_data[3]
		var desc: String = test_data[4]

		var result_val := combat.should_use_tank_combat(shooter, target, weapon)
		var passed: bool = (result_val == expected)
		var result: String = "OK" if passed else "NG"
		all_pass = all_pass and passed

		var target_armor: int = target.element_type.armor_class if target.element_type else 0
		print("%-14s | %-13s | %11d | %8s | %s" % [
			desc, weapon.id, target_armor,
			"true" if expected else "false", result
		])

	print("")
	if all_pass:
		print("All should_use_tank_combat tests PASSED")
	else:
		print("Some should_use_tank_combat tests FAILED")


func _test_accumulated_armor_damage() -> void:
	print("\n--- Test: Accumulated Armor Damage (CONTINUOUS weapons) ---")

	var combat := CombatSystem.new()
	var all_weapons := WeaponData.get_all_concrete_weapons()
	var all_pass := true

	# IFV作成（射手）
	var ifv_type := ElementData.ElementArchetypes.get_archetype("IFV_PLT")
	if not ifv_type:
		print("ERROR: IFV_PLT archetype not found!")
		return

	var shooter := ElementData.ElementInstance.new(ifv_type)
	shooter.id = "SHOOTER_IFV"
	shooter.faction = GameEnums.Faction.BLUE
	shooter.position = Vector2(0, 0)
	shooter.weapons.append(all_weapons["CW_AUTOCANNON_30"])
	shooter.primary_weapon = shooter.weapons[0]

	# 別のIFV作成（目標）
	var target := ElementData.ElementInstance.new(ifv_type)
	target.id = "TARGET_IFV"
	target.faction = GameEnums.Faction.RED
	target.position = Vector2(500, 0)  # 500m離れた位置
	target.facing = PI  # 射手の方を向いている（正面から射撃される）

	print("Shooter: %s with %s" % [shooter.id, shooter.weapons[0].id])
	print("Target: %s (armor_class=%d)" % [target.id, ifv_type.armor_class])
	print("Distance: 500m")
	print("")

	# Test 1: accumulated_armor_damage フィールドが存在する
	var has_field := "accumulated_armor_damage" in target
	var result := "OK" if has_field else "NG"
	all_pass = all_pass and has_field
	print("Test 1: accumulated_armor_damage field exists: %s" % result)

	# Test 2: 初期値は0.0
	var initial_value: bool = target.accumulated_armor_damage == 0.0
	result = "OK" if initial_value else "NG"
	all_pass = all_pass and initial_value
	print("Test 2: Initial value is 0.0: %s (actual: %.4f)" % [result, target.accumulated_armor_damage])

	# Test 3: AUTOCANNON は CONTINUOUS 武器
	var weapon: WeaponData.WeaponType = all_weapons["CW_AUTOCANNON_30"]
	var is_continuous: bool = weapon.fire_model == WeaponData.FireModel.CONTINUOUS
	result = "OK" if is_continuous else "NG"
	all_pass = all_pass and is_continuous
	print("Test 3: AUTOCANNON is CONTINUOUS: %s" % result)

	# Test 4: calculate_direct_fire_vs_armor で is_continuous がセットされる
	var distance := 500.0
	var dt := 0.1
	var t_los := 1.0
	var terrain := GameEnums.TerrainType.OPEN
	var fire_result := combat.calculate_direct_fire_vs_armor(
		shooter, target, weapon, distance, dt, t_los, terrain, false
	)
	var result_is_continuous := fire_result.is_continuous
	result = "OK" if result_is_continuous else "NG"
	all_pass = all_pass and result_is_continuous
	print("Test 4: Result is_continuous flag: %s" % result)

	# Test 5: d_dmg が計算されている
	var has_d_dmg := fire_result.d_dmg > 0.0
	result = "OK" if has_d_dmg else "NG"
	all_pass = all_pass and has_d_dmg
	print("Test 5: d_dmg calculated: %s (value: %.6f)" % [result, fire_result.d_dmg])

	# Test 6: exposure が計算されている
	print("Test 6: exposure value: %.6f" % fire_result.exposure)

	# Test 6b: 貫徹確率を確認
	var aspect := WeaponData.ArmorZone.FRONT  # 正面想定
	var p_pen_front := combat.get_penetration_probability(shooter, target, weapon, distance, aspect)
	print("Test 6b: p_pen FRONT (pen=20 vs armor=30): %.4f" % p_pen_front)

	var p_pen_side := combat.get_penetration_probability(shooter, target, weapon, distance, WeaponData.ArmorZone.SIDE)
	print("Test 6c: p_pen SIDE (pen=20 vs armor=10): %.4f" % p_pen_side)

	# Test 7: 累積ダメージシミュレーション（正面 vs 側面）
	print("")
	print("--- Simulation: Time to Kill comparison ---")

	# 正面射撃（IFVが射手に向いている）
	print("\n[FRONT attack] Target facing shooter (hardest)")
	var sim_target_front := ElementData.ElementInstance.new(ifv_type)
	sim_target_front.id = "SIM_TARGET_FRONT"
	sim_target_front.faction = GameEnums.Faction.RED
	sim_target_front.position = Vector2(500, 0)
	sim_target_front.facing = PI  # 射手の方を向いている

	var ttk_front := _simulate_ttk(combat, shooter, sim_target_front, weapon, distance, dt, t_los, terrain)
	print("  TTK (first damage): %.1f seconds" % ttk_front.time_to_first_damage)
	print("  d_dmg per tick: %.5f" % ttk_front.d_dmg_per_tick)
	print("  p_pen: %.2f%%" % (ttk_front.p_pen * 100.0))

	# 側面射撃（IFVが横を向いている）
	print("\n[SIDE attack] Target perpendicular (typical)")
	var sim_target_side := ElementData.ElementInstance.new(ifv_type)
	sim_target_side.id = "SIM_TARGET_SIDE"
	sim_target_side.faction = GameEnums.Faction.RED
	sim_target_side.position = Vector2(500, 0)
	sim_target_side.facing = PI / 2  # 横を向いている（側面を晒す）

	var ttk_side := _simulate_ttk(combat, shooter, sim_target_side, weapon, distance, dt, t_los, terrain)
	print("  TTK (first damage): %.1f seconds" % ttk_side.time_to_first_damage)
	print("  d_dmg per tick: %.5f" % ttk_side.d_dmg_per_tick)
	print("  p_pen: %.2f%%" % (ttk_side.p_pen * 100.0))

	# 後方射撃（IFVの背中を撃つ）
	print("\n[REAR attack] Target facing away (easiest)")
	var sim_target_rear := ElementData.ElementInstance.new(ifv_type)
	sim_target_rear.id = "SIM_TARGET_REAR"
	sim_target_rear.faction = GameEnums.Faction.RED
	sim_target_rear.position = Vector2(500, 0)
	sim_target_rear.facing = 0.0  # 射手と同じ方向を向いている（背中を晒す）

	var ttk_rear := _simulate_ttk(combat, shooter, sim_target_rear, weapon, distance, dt, t_los, terrain)
	print("  TTK (first damage): %.1f seconds" % ttk_rear.time_to_first_damage)
	print("  d_dmg per tick: %.5f" % ttk_rear.d_dmg_per_tick)
	print("  p_pen: %.2f%%" % (ttk_rear.p_pen * 100.0))

	# 結果サマリー
	print("\n--- TTK Summary (30mm vs IFV @ 500m) ---")
	print("  FRONT: %.1fs | SIDE: %.1fs | REAR: %.1fs" % [
		ttk_front.time_to_first_damage,
		ttk_side.time_to_first_damage,
		ttk_rear.time_to_first_damage
	])

	# 側面/後方射撃は30秒以内であるべき（現実的なTTK）
	var side_ok: bool = ttk_side.time_to_first_damage <= 30.0 and ttk_side.time_to_first_damage > 0
	var rear_ok: bool = ttk_rear.time_to_first_damage <= 20.0 and ttk_rear.time_to_first_damage > 0

	result = "OK" if side_ok else "NG (too slow, expected <= 30s)"
	all_pass = all_pass and side_ok
	print("Test 7a: SIDE attack TTK <= 30s: %s" % result)

	result = "OK" if rear_ok else "NG (too slow, expected <= 20s)"
	all_pass = all_pass and rear_ok
	print("Test 7b: REAR attack TTK <= 20s: %s" % result)

	print("")
	if all_pass:
		print("All Accumulated Armor Damage tests PASSED")
	else:
		print("Some Accumulated Armor Damage tests FAILED")


## TTKシミュレーション用のヘルパー関数
func _simulate_ttk(
	combat: CombatSystem,
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance: float,
	dt: float,
	t_los: float,
	terrain: GameEnums.TerrainType
) -> Dictionary:
	var accumulated := 0.0
	var first_d_dmg := 0.0
	var first_p_pen := 0.0
	var ticks_to_damage := 0

	for tick_num in range(2000):  # 最大200秒
		var sim_result := combat.calculate_direct_fire_vs_armor(
			shooter, target, weapon, distance, dt, t_los, terrain, false
		)
		if tick_num == 0:
			first_d_dmg = sim_result.d_dmg
			# p_penを取得するには再計算が必要
			var aspect := combat.calculate_aspect_v01r(
				shooter.position, target.position, target.facing
			)
			first_p_pen = combat.get_penetration_probability(
				shooter, target, weapon, distance, aspect
			)
		accumulated += sim_result.d_dmg
		if accumulated >= 1.0:
			ticks_to_damage = tick_num + 1
			break

	var time_to_first := float(ticks_to_damage) * dt if ticks_to_damage > 0 else 999.0

	return {
		"time_to_first_damage": time_to_first,
		"d_dmg_per_tick": first_d_dmg,
		"p_pen": first_p_pen,
		"ticks": ticks_to_damage
	}
