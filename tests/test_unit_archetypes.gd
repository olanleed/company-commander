extends SceneTree

## ユニットアーキタイプテスト
## godot --headless -s tests/test_unit_archetypes.gd
##
## 新規追加アーキタイプ（APC_PLT, LIGHT_VEH, COMMAND_VEH, SP_MORTAR, SP_ARTILLERY, SPAAG, SAM_VEH）
## および武装（CW_HMG, CW_AUTOCANNON_35, CW_MORTAR_120, CW_HOWITZER_155）のテスト

func _init() -> void:
	print("=== Unit Archetypes Test ===")

	# テスト: 全アーキタイプが取得できるか
	_test_all_archetypes_exist()

	# テスト: 新規アーキタイプの装甲設定
	_test_new_archetype_armor()

	# テスト: 新規武装が取得できるか
	_test_new_weapons_exist()

	# テスト: ElementFactoryでの生成
	_test_element_factory_creation()

	# テスト: VehicleCatalogとの連携
	_test_vehicle_catalog_integration()

	# テスト: 武装マッピング
	_test_archetype_weapons_mapping()

	print("\n=== Tests Complete ===")
	quit()


func _test_all_archetypes_exist() -> void:
	print("\n--- Test: All Archetypes Exist ---")

	var expected_archetypes := [
		"INF_LINE", "INF_AT", "INF_MG",
		"TANK_PLT", "IFV_PLT",
		"APC_PLT", "LIGHT_VEH", "COMMAND_VEH",
		"RECON_VEH", "RECON_TEAM",
		"MORTAR_SEC", "SP_MORTAR", "SP_ARTILLERY",
		"SPAAG", "SAM_VEH",
		"LOG_TRUCK", "CMD_HQ"
	]

	var all_archetypes := ElementData.ElementArchetypes.get_all_archetypes()
	var all_pass := true

	for archetype_id in expected_archetypes:
		var exists: bool = archetype_id in all_archetypes
		var status: String = "PASS" if exists else "FAIL"
		if not exists:
			all_pass = false
		print("  %s: %s" % [archetype_id, status])

	print("All archetypes exist: %s" % ("PASS" if all_pass else "FAIL"))


func _test_new_archetype_armor() -> void:
	print("\n--- Test: New Archetype Armor Settings ---")

	var test_cases := [
		["APC_PLT", 1, 8, 4],        # Light armor, front=8, side=4
		["LIGHT_VEH", 1, 3, 2],      # Light armor, front=3, side=2
		["COMMAND_VEH", 1, 6, 4],    # Light armor, front=6, side=4
		["SP_MORTAR", 1, 6, 4],      # Light armor
		["SP_ARTILLERY", 2, 12, 8],  # Medium armor, front=12, side=8
		["SPAAG", 2, 14, 8],         # Medium armor, front=14, side=8
		["SAM_VEH", 0, 0, 0],        # Soft (no armor)
	]

	var all_pass := true
	print("Archetype       | ArmorClass | KE_Front | KE_Side | Result")
	print("------------------------------------------------------------")

	for test in test_cases:
		var archetype_id: String = test[0]
		var expected_armor_class: int = test[1]
		var expected_ke_front: int = test[2]
		var expected_ke_side: int = test[3]

		var element_type := ElementData.ElementArchetypes.get_archetype(archetype_id)

		var armor_class_ok := element_type.armor_class == expected_armor_class

		var ke_front := 0
		var ke_side := 0
		if element_type.armor_ke.size() > 0:
			ke_front = element_type.armor_ke.get(WeaponData.ArmorZone.FRONT, 0)
			ke_side = element_type.armor_ke.get(WeaponData.ArmorZone.SIDE, 0)

		var ke_front_ok := ke_front == expected_ke_front
		var ke_side_ok := ke_side == expected_ke_side

		var pass_all := armor_class_ok and ke_front_ok and ke_side_ok
		if not pass_all:
			all_pass = false

		var status := "PASS" if pass_all else "FAIL"
		print("%-15s | %10d | %8d | %7d | %s" % [
			archetype_id, element_type.armor_class, ke_front, ke_side, status
		])

	print("All armor settings correct: %s" % ("PASS" if all_pass else "FAIL"))


func _test_new_weapons_exist() -> void:
	print("\n--- Test: New Weapons Exist ---")

	var expected_weapons := [
		"CW_HMG",           # 12.7mm重機関銃
		"CW_AUTOCANNON_35", # 35mm連装機関砲
		"CW_MORTAR_120",    # 120mm自走迫撃砲
		"CW_HOWITZER_155",  # 155mm榴弾砲
	]

	var all_weapons := WeaponData.get_all_concrete_weapons()
	var all_pass := true

	print("Weapon           | MaxRange | ThreatClass | FireModel | Result")
	print("----------------------------------------------------------------")

	for weapon_id in expected_weapons:
		var exists: bool = weapon_id in all_weapons
		if not exists:
			all_pass = false
			print("%-16s | N/A      | N/A         | N/A       | FAIL (not found)" % weapon_id)
			continue

		var weapon: WeaponData.WeaponType = all_weapons[weapon_id]
		var threat_class_name := _threat_class_name(weapon.threat_class)
		var fire_model_name := _fire_model_name(weapon.fire_model)

		print("%-16s | %8dm | %-11s | %-9s | PASS" % [
			weapon_id, int(weapon.max_range_m), threat_class_name, fire_model_name
		])

	print("All weapons exist: %s" % ("PASS" if all_pass else "FAIL"))


func _test_element_factory_creation() -> void:
	print("\n--- Test: ElementFactory Creation ---")

	ElementFactory.reset_id_counters()

	var test_archetypes := [
		"APC_PLT", "LIGHT_VEH", "COMMAND_VEH",
		"SP_MORTAR", "SP_ARTILLERY", "SPAAG", "SAM_VEH"
	]

	var all_pass := true
	print("Archetype       | ID             | Weapons             | Result")
	print("-----------------------------------------------------------------")

	for archetype_id in test_archetypes:
		var element := ElementFactory.create_element(
			archetype_id,
			GameEnums.Faction.BLUE,
			Vector2(100, 100)
		)

		var id_ok := element.id.begins_with(archetype_id)
		var type_ok := element.element_type != null
		var faction_ok := element.faction == GameEnums.Faction.BLUE

		var weapon_list := ""
		for w in element.weapons:
			weapon_list += w.id + " "
		weapon_list = weapon_list.strip_edges()
		if weapon_list == "":
			weapon_list = "(none)"

		var pass_all := id_ok and type_ok and faction_ok
		if not pass_all:
			all_pass = false

		var status := "PASS" if pass_all else "FAIL"
		print("%-15s | %-14s | %-19s | %s" % [
			archetype_id, element.id, weapon_list, status
		])

	print("All factory creations successful: %s" % ("PASS" if all_pass else "FAIL"))


func _test_vehicle_catalog_integration() -> void:
	print("\n--- Test: VehicleCatalog Integration ---")

	ElementFactory.reset_id_counters()
	ElementFactory.init_vehicle_catalog()
	var catalog = ElementFactory.get_vehicle_catalog()

	if not catalog or not catalog.is_loaded():
		print("FAIL: VehicleCatalog not loaded")
		return

	# テスト用車両（各国から1つずつ）
	var test_vehicles := [
		["JPN_Type96_WAPC", "APC_PLT"],   # 日本 96式装輪装甲車
		["JPN_Type82_CCV", "COMMAND_VEH"], # 日本 82式指揮通信車
		["JPN_Type16", "RECON_VEH"],       # 日本 16式機動戦闘車
		["RUS_BTR82A", "RECON_VEH"],        # ロシア BTR-82A（30mm機関砲搭載で偵察車両扱い）
	]

	var all_pass := true
	print("Vehicle          | BaseArchetype  | Created ID      | Result")
	print("--------------------------------------------------------------")

	for test in test_vehicles:
		var vehicle_id: String = test[0]
		var expected_archetype: String = test[1]

		var vehicle_config = catalog.get_vehicle(vehicle_id)
		if not vehicle_config:
			print("%-16s | N/A            | N/A             | FAIL (not in catalog)" % vehicle_id)
			all_pass = false
			continue

		var archetype_ok: bool = vehicle_config.base_archetype == expected_archetype

		var element := ElementFactory.create_element_with_vehicle(
			vehicle_id,
			GameEnums.Faction.BLUE,
			Vector2(200, 200)
		)

		var element_ok: bool = element != null
		var vehicle_id_ok: bool = element.vehicle_id == vehicle_id

		var pass_all: bool = archetype_ok and element_ok and vehicle_id_ok
		if not pass_all:
			all_pass = false

		var status: String = "PASS" if pass_all else "FAIL"
		print("%-16s | %-14s | %-15s | %s" % [
			vehicle_id, vehicle_config.base_archetype, element.id, status
		])

	print("All vehicle catalog integrations successful: %s" % ("PASS" if all_pass else "FAIL"))


func _test_archetype_weapons_mapping() -> void:
	print("\n--- Test: Archetype Weapons Mapping ---")

	var expected_mappings := {
		"APC_PLT": ["CW_HMG"],
		"COMMAND_VEH": ["CW_HMG"],
		"SP_MORTAR": ["CW_MORTAR_120"],
		"SP_ARTILLERY": ["CW_HOWITZER_155"],
		"SPAAG": ["CW_AUTOCANNON_35"],
		"SAM_VEH": [],
		"LIGHT_VEH": ["CW_RIFLE_STD"],
	}

	var all_weapons := WeaponData.get_all_concrete_weapons()
	var all_pass := true

	print("Archetype       | Expected Weapons        | Actual Weapons          | Result")
	print("-------------------------------------------------------------------------------")

	for archetype_id in expected_mappings:
		var expected: Array = expected_mappings[archetype_id]
		var actual: Array = ElementFactory.ARCHETYPE_WEAPONS.get(archetype_id, [])

		var match_ok := true
		if expected.size() != actual.size():
			match_ok = false
		else:
			for i in range(expected.size()):
				if expected[i] != actual[i]:
					match_ok = false
					break

		# 武装が存在するか確認
		var weapons_exist := true
		for weapon_id in actual:
			if weapon_id not in all_weapons:
				weapons_exist = false
				break

		var pass_all := match_ok and weapons_exist
		if not pass_all:
			all_pass = false

		var expected_str := str(expected) if expected.size() > 0 else "[]"
		var actual_str := str(actual) if actual.size() > 0 else "[]"
		var status := "PASS" if pass_all else "FAIL"

		print("%-15s | %-23s | %-23s | %s" % [
			archetype_id, expected_str, actual_str, status
		])

	print("All weapon mappings correct: %s" % ("PASS" if all_pass else "FAIL"))


# === ヘルパー関数 ===

func _threat_class_name(threat_class: WeaponData.ThreatClass) -> String:
	match threat_class:
		WeaponData.ThreatClass.SMALL_ARMS: return "SMALL_ARMS"
		WeaponData.ThreatClass.AUTOCANNON: return "AUTOCANNON"
		WeaponData.ThreatClass.HE_FRAG: return "HE_FRAG"
		WeaponData.ThreatClass.AT: return "AT"
		_: return "UNKNOWN"


func _fire_model_name(fire_model: WeaponData.FireModel) -> String:
	match fire_model:
		WeaponData.FireModel.CONTINUOUS: return "CONTINUOUS"
		WeaponData.FireModel.DISCRETE: return "DISCRETE"
		WeaponData.FireModel.INDIRECT: return "INDIRECT"
		_: return "UNKNOWN"
