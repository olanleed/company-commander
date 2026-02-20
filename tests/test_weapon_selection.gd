extends SceneTree

## 武器選択テスト
## godot --headless -s tests/test_weapon_selection.gd

func _init() -> void:
	print("=== Weapon Selection Test ===")

	# テスト: 歩兵 vs 戦車（複数距離）
	_test_infantry_vs_tank_at_distances()

	# テスト: 戦車 vs 歩兵（複数距離）
	_test_tank_vs_infantry_at_distances()

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
	infantry.weapons.append(all_weapons["CW_LAW"])
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
	print("CW_LAW: max_range=%dm, preferred=%d" % [
		int(all_weapons["CW_LAW"].max_range_m),
		all_weapons["CW_LAW"].preferred_target
	])
	print("")

	# 武器選択テスト（複数距離）
	var combat := CombatSystem.new()

	print("Distance | Selected Weapon | Expected | Result")
	print("--------------------------------------------------")

	var all_pass := true
	var test_cases: Array = [
		[100, "CW_LAW"],
		[150, "CW_LAW"],
		[200, "CW_LAW"],
		[250, "CW_LAW"],
		[260, ""],  # LAW射程外、RIFLEは装甲に効果なし
		[300, ""],  # 同上
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
