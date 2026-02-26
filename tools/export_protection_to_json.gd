extends MainLoop

## 防護プロファイルデータをJSONにエクスポートするスクリプト
## 使用方法: godot --headless --script tools/export_protection_to_json.gd

const OUTPUT_PATH := "res://data/protection/protection_profiles.json"

var ProtectionDataScript: GDScript

var _iteration := 0


func _initialize() -> void:
	print("=== Protection Data Export Tool ===")

	# スクリプトを動的にロード
	ProtectionDataScript = load("res://scripts/data/protection_data.gd")

	# 出力ディレクトリ確認
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("data/protection"):
		dir.make_dir_recursive("data/protection")

	# 全プリセットをエクスポート
	var profiles_array := []

	# プリセット定義
	var presets := {
		"MBT_FRONT_NATO": ProtectionDataScript.create_mbt_front_nato(),
		"MBT_FRONT_RUS": ProtectionDataScript.create_mbt_front_rus(),
		"MBT_FRONT_ARMATA": ProtectionDataScript.create_mbt_front_armata(),
		"IFV_FRONT_NATO": ProtectionDataScript.create_ifv_front_nato(),
		"IFV_FRONT_RUS": ProtectionDataScript.create_ifv_front_rus(),
		"LIGHT_ARMOR": ProtectionDataScript.create_light_armor(),
		"SOFT_SKIN": ProtectionDataScript.create_soft_skin(),
	}

	print("Total protection profiles: %d" % presets.size())

	for preset_id in presets.keys():
		var profile = presets[preset_id]
		var profile_dict := profile_to_dict(profile, preset_id)
		profiles_array.append(profile_dict)

	# JSONファイルを保存
	save_json(OUTPUT_PATH, profiles_array)
	print("Exported: %s (%d profiles)" % [OUTPUT_PATH, profiles_array.size()])

	print("=== Export Complete ===")


func _process(_delta: float) -> bool:
	_iteration += 1
	return _iteration > 1


## ProtectionProfile を Dictionary に変換
func profile_to_dict(profile, preset_id: String) -> Dictionary:
	return {
		"id": preset_id,
		"base_armor_ke": profile.base_armor_ke,
		"base_armor_ce": profile.base_armor_ce,
		"era_type": era_type_to_string(profile.era_type),
		"aps_type": aps_type_to_string(profile.aps_type),
		"composite_gen": composite_gen_to_string(profile.composite_gen),
	}


## ERAType enum を文字列に変換
func era_type_to_string(e: int) -> String:
	match e:
		ProtectionDataScript.ERAType.NONE:
			return "NONE"
		ProtectionDataScript.ERAType.KONTAKT_1:
			return "KONTAKT_1"
		ProtectionDataScript.ERAType.KONTAKT_5:
			return "KONTAKT_5"
		ProtectionDataScript.ERAType.RELIKT:
			return "RELIKT"
		ProtectionDataScript.ERAType.MALACHIT:
			return "MALACHIT"
		ProtectionDataScript.ERAType.BLAZER:
			return "BLAZER"
		ProtectionDataScript.ERAType.NXRA:
			return "NXRA"
		_:
			return "NONE"


## APSType enum を文字列に変換
func aps_type_to_string(a: int) -> String:
	match a:
		ProtectionDataScript.APSType.NONE:
			return "NONE"
		ProtectionDataScript.APSType.SOFT_KILL:
			return "SOFT_KILL"
		ProtectionDataScript.APSType.HARD_KILL_ARENA:
			return "HARD_KILL_ARENA"
		ProtectionDataScript.APSType.HARD_KILL_TROPHY:
			return "HARD_KILL_TROPHY"
		ProtectionDataScript.APSType.HARD_KILL_AFGHANIT:
			return "HARD_KILL_AFGHANIT"
		ProtectionDataScript.APSType.HARD_KILL_IRON_FIST:
			return "HARD_KILL_IRON_FIST"
		_:
			return "NONE"


## CompositeGen enum を文字列に変換
func composite_gen_to_string(c: int) -> String:
	match c:
		ProtectionDataScript.CompositeGen.NONE:
			return "NONE"
		ProtectionDataScript.CompositeGen.GEN_1:
			return "GEN_1"
		ProtectionDataScript.CompositeGen.GEN_2:
			return "GEN_2"
		ProtectionDataScript.CompositeGen.GEN_3:
			return "GEN_3"
		ProtectionDataScript.CompositeGen.GEN_4:
			return "GEN_4"
		_:
			return "NONE"


## JSONファイルを保存
func save_json(path: String, data: Array) -> void:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to write: %s" % path)
