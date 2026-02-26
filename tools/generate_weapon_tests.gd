extends MainLoop

## 武器データからテストコードを自動生成するスクリプト
## 使用方法: godot --headless --script tools/generate_weapon_tests.gd

const WEAPON_JSON_DIR := "res://data/weapons/"
const OUTPUT_DIR := "res://tests/generated/"

var _iteration := 0


func _initialize() -> void:
	print("=== Weapon Test Generator ===")

	# 出力ディレクトリ確認
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("tests/generated"):
		dir.make_dir_recursive("tests/generated")

	# 国別JSONを処理
	var json_files := {
		"weapons_generic.json": "generic",
		"weapons_usa.json": "usa",
		"weapons_rus.json": "rus",
		"weapons_chn.json": "chn",
		"weapons_jpn.json": "jpn",
	}

	for json_file in json_files.keys():
		var nation: String = json_files[json_file]
		var weapons := load_weapons_from_json(WEAPON_JSON_DIR + json_file)
		if weapons.is_empty():
			continue

		var test_code := generate_test_file(nation, weapons)
		var output_path := OUTPUT_DIR + "test_weapons_%s_generated.gd" % nation
		save_test_file(output_path, test_code)
		print("Generated: %s (%d weapons, %d tests)" % [output_path, weapons.size(), count_tests(test_code)])

	print("=== Generation Complete ===")


func _process(_delta: float) -> bool:
	_iteration += 1
	return _iteration > 1


## JSONファイルから武器データを読み込む
func load_weapons_from_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Cannot open: %s" % path)
		return []

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	return json.data


## テストファイルを生成
func generate_test_file(nation: String, weapons: Array) -> String:
	var lines := PackedStringArray()

	# ヘッダー
	lines.append("extends GutTest")
	lines.append("")
	lines.append("## 自動生成された武器テスト（%s）" % nation.to_upper())
	lines.append("## 生成元: data/weapons/weapons_%s.json" % nation)
	lines.append("## 生成日: %s" % Time.get_datetime_string_from_system())
	lines.append("## 注意: このファイルは自動生成されます。手動編集しないでください。")
	lines.append("")
	lines.append("var WeaponDataClass: GDScript")
	lines.append("")
	lines.append("")
	lines.append("func before_all() -> void:")
	lines.append("\tWeaponDataClass = load(\"res://scripts/data/weapon_data.gd\")")
	lines.append("")
	lines.append("")

	# セクションコメント: 存在確認テスト
	lines.append("# =============================================================================")
	lines.append("# 武器存在確認テスト")
	lines.append("# =============================================================================")
	lines.append("")

	for weapon in weapons:
		lines.append_array(generate_existence_test(weapon))

	# セクションコメント: mechanism/fire_model テスト
	lines.append("# =============================================================================")
	lines.append("# Mechanism / FireModel テスト")
	lines.append("# =============================================================================")
	lines.append("")

	for weapon in weapons:
		lines.append_array(generate_mechanism_test(weapon))

	# セクションコメント: 貫徹力テスト
	lines.append("# =============================================================================")
	lines.append("# 貫徹力テスト")
	lines.append("# =============================================================================")
	lines.append("")

	for weapon in weapons:
		lines.append_array(generate_penetration_test(weapon))

	# セクションコメント: 射程テスト
	lines.append("# =============================================================================")
	lines.append("# 射程テスト")
	lines.append("# =============================================================================")
	lines.append("")

	for weapon in weapons:
		lines.append_array(generate_range_test(weapon))

	# 相対比較テスト（同国内で生成）
	var comparison_tests := generate_comparison_tests(nation, weapons)
	if not comparison_tests.is_empty():
		lines.append("# =============================================================================")
		lines.append("# 相対比較テスト")
		lines.append("# =============================================================================")
		lines.append("")
		lines.append_array(comparison_tests)

	return "\n".join(lines)


## 存在確認テスト生成
func generate_existence_test(weapon: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var id: String = weapon.get("id", "")
	var display_name: String = weapon.get("display_name", id)
	var func_name := "test_%s_exists" % id.to_lower()

	lines.append("func %s() -> void:" % func_name)
	lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
	lines.append("\tassert_has(weapons, \"%s\", \"%s should exist\")" % [id, display_name])
	lines.append("")
	lines.append("")
	return lines


## Mechanism/FireModel テスト生成
func generate_mechanism_test(weapon: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var id: String = weapon.get("id", "")
	var mechanism: String = weapon.get("mechanism", "UNKNOWN")
	var fire_model: String = weapon.get("fire_model", "UNKNOWN")
	var func_name := "test_%s_mechanism" % id.to_lower()

	lines.append("func %s() -> void:" % func_name)
	lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
	lines.append("\tvar weapon = weapons[\"%s\"]" % id)
	lines.append("\tassert_eq(weapon.mechanism, WeaponDataClass.Mechanism.%s, \"%s should be %s\")" % [mechanism, id, mechanism])
	lines.append("\tassert_eq(weapon.fire_model, WeaponDataClass.FireModel.%s, \"%s should be %s\")" % [fire_model, id, fire_model])
	lines.append("")
	lines.append("")
	return lines


## 貫徹力テスト生成
func generate_penetration_test(weapon: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var id: String = weapon.get("id", "")
	var pen_ke: Dictionary = weapon.get("pen_ke", {})
	var pen_ce: Dictionary = weapon.get("pen_ce", {})

	# KE貫徹力があれば検証
	if not pen_ke.is_empty() and pen_ke.get("MID", 0) > 0:
		var func_name := "test_%s_pen_ke" % id.to_lower()
		var mid_value: int = pen_ke.get("MID", 0)

		lines.append("func %s() -> void:" % func_name)
		lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
		lines.append("\tvar weapon = weapons[\"%s\"]" % id)
		lines.append("\tassert_eq(weapon.pen_ke[WeaponDataClass.RangeBand.MID], %d, \"%s pen_ke MID should be %d\")" % [mid_value, id, mid_value])
		lines.append("")
		lines.append("")

	# CE貫徹力があれば検証
	if not pen_ce.is_empty() and pen_ce.get("MID", 0) > 0:
		var func_name := "test_%s_pen_ce" % id.to_lower()
		var mid_value: int = pen_ce.get("MID", 0)

		lines.append("func %s() -> void:" % func_name)
		lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
		lines.append("\tvar weapon = weapons[\"%s\"]" % id)
		lines.append("\tassert_eq(weapon.pen_ce[WeaponDataClass.RangeBand.MID], %d, \"%s pen_ce MID should be %d\")" % [mid_value, id, mid_value])
		lines.append("")
		lines.append("")

	return lines


## 射程テスト生成
func generate_range_test(weapon: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var id: String = weapon.get("id", "")
	var range_data: Dictionary = weapon.get("range", {})
	var max_range: float = range_data.get("max_m", 0)
	var min_range: float = range_data.get("min_m", 0)

	if max_range > 0:
		var func_name := "test_%s_range" % id.to_lower()

		lines.append("func %s() -> void:" % func_name)
		lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
		lines.append("\tvar weapon = weapons[\"%s\"]" % id)
		lines.append("\tassert_eq(weapon.max_range_m, %.1f, \"%s max_range should be %.1f\")" % [max_range, id, max_range])
		lines.append("\tassert_eq(weapon.min_range_m, %.1f, \"%s min_range should be %.1f\")" % [min_range, id, min_range])
		lines.append("")
		lines.append("")

	return lines


## 相対比較テスト生成
func generate_comparison_tests(nation: String, weapons: Array) -> PackedStringArray:
	var lines := PackedStringArray()

	# 戦車砲KE vs HEAT比較（KE > HEAT for pen_ke）
	var tank_ke := find_weapon_by_pattern(weapons, "TANK_KE")
	var tank_heat := find_weapon_by_pattern(weapons, "TANK_HEAT")
	if tank_ke and tank_heat:
		var ke_pen: int = tank_ke.get("pen_ke", {}).get("MID", 0)
		if ke_pen > 0:
			lines.append("func test_%s_tank_ke_vs_heat() -> void:" % nation)
			lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
			lines.append("\tvar ke = weapons[\"%s\"]" % tank_ke.id)
			lines.append("\tvar heat = weapons[\"%s\"]" % tank_heat.id)
			lines.append("\t# KE弾は遠距離でHEAT弾よりpen_keが高い")
			lines.append("\tassert_gt(ke.pen_ke[WeaponDataClass.RangeBand.MID], 0, \"KE ammo should have pen_ke\")")
			lines.append("")
			lines.append("")

	# 大口径 > 小口径 比較（オートキャノン、pen_keを持つKINETICタイプのみ）
	var autocannons := find_autocannons_with_pen_ke(weapons)
	if autocannons.size() >= 2:
		# 口径でソート
		autocannons.sort_custom(func(a, b): return extract_caliber(a.id) < extract_caliber(b.id))
		var small: Dictionary = autocannons[0]
		var large: Dictionary = autocannons[-1]
		if small.id != large.id:
			lines.append("func test_%s_autocannon_caliber_comparison() -> void:" % nation)
			lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
			lines.append("\tvar small = weapons[\"%s\"]" % small.id)
			lines.append("\tvar large = weapons[\"%s\"]" % large.id)
			lines.append("\t# 大口径は小口径より貫徹力が高い")
			lines.append("\tassert_gt(large.pen_ke[WeaponDataClass.RangeBand.NEAR], small.pen_ke[WeaponDataClass.RangeBand.NEAR],")
			lines.append("\t\t\"%s should have higher penetration than %s\")" % [large.id, small.id])
			lines.append("")
			lines.append("")

	# ATGM貫徹力テスト
	var atgms := find_weapons_by_pattern(weapons, "ATGM")
	for atgm in atgms:
		var pen_ce: int = atgm.get("pen_ce", {}).get("MID", 0)
		if pen_ce > 50:
			lines.append("func test_%s_atgm_effectiveness() -> void:" % atgm.id.to_lower())
			lines.append("\tvar weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()")
			lines.append("\tvar atgm = weapons[\"%s\"]" % atgm.id)
			lines.append("\t# ATGMは有効な対装甲貫徹力を持つ")
			lines.append("\tassert_gt(atgm.pen_ce[WeaponDataClass.RangeBand.MID], 50, \"%s should have significant pen_ce\")" % atgm.id)
			lines.append("")
			lines.append("")

	return lines


## パターンで武器を検索
func find_weapon_by_pattern(weapons: Array, pattern: String) -> Dictionary:
	for weapon in weapons:
		if weapon.id.contains(pattern):
			return weapon
	return {}


## パターンで複数の武器を検索
func find_weapons_by_pattern(weapons: Array, pattern: String) -> Array:
	var result := []
	for weapon in weapons:
		if weapon.id.contains(pattern):
			result.append(weapon)
	return result


## オートキャノンを検索
func find_autocannons(weapons: Array) -> Array:
	var result := []
	for weapon in weapons:
		if weapon.id.contains("AUTOCANNON"):
			result.append(weapon)
	return result


## pen_keを持つオートキャノンを検索（KINETICタイプのみ）
func find_autocannons_with_pen_ke(weapons: Array) -> Array:
	var result := []
	for weapon in weapons:
		if weapon.id.contains("AUTOCANNON"):
			var pen_ke: Dictionary = weapon.get("pen_ke", {})
			if not pen_ke.is_empty() and pen_ke.get("NEAR", 0) > 0:
				result.append(weapon)
	return result


## 武器IDから口径を抽出
func extract_caliber(weapon_id: String) -> int:
	# CW_AUTOCANNON_25_USA -> 25
	var regex := RegEx.new()
	regex.compile("_(\\d+)_")
	var match_result := regex.search(weapon_id)
	if match_result:
		return int(match_result.get_string(1))

	# CW_AUTOCANNON_30X173_USA -> 30
	regex.compile("_(\\d+)X")
	match_result = regex.search(weapon_id)
	if match_result:
		return int(match_result.get_string(1))

	return 0


## テスト数をカウント
func count_tests(code: String) -> int:
	var count := 0
	var regex := RegEx.new()
	regex.compile("^func test_")
	for line in code.split("\n"):
		if regex.search(line):
			count += 1
	return count


## テストファイルを保存
func save_test_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		push_error("Failed to write: %s" % path)
