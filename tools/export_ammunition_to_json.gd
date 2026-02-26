extends MainLoop

## 弾薬データをJSONにエクスポートするスクリプト
## 使用方法: godot --headless --script tools/export_ammunition_to_json.gd

const OUTPUT_PATH := "res://data/ammunition/ammunition_profiles.json"

var AmmunitionDataScript: GDScript

var _iteration := 0


func _initialize() -> void:
	print("=== Ammunition Data Export Tool ===")

	# スクリプトを動的にロード
	AmmunitionDataScript = load("res://scripts/data/ammunition_data.gd")

	# 出力ディレクトリ確認
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("data/ammunition"):
		dir.make_dir_recursive("data/ammunition")

	# 全弾薬プロファイルを取得してエクスポート
	var profiles_array := []

	# AmmoType enumの全値を取得
	var ammo_types: Array = AmmunitionDataScript.AmmoType.keys()
	print("Total ammo types: %d" % ammo_types.size())

	for type_name in ammo_types:
		var type_value: int = AmmunitionDataScript.AmmoType[type_name]
		var profile = AmmunitionDataScript.get_ammo_profile(type_value)
		var profile_dict := profile_to_dict(profile, type_name)
		profiles_array.append(profile_dict)

	# JSONファイルを保存
	save_json(OUTPUT_PATH, profiles_array)
	print("Exported: %s (%d profiles)" % [OUTPUT_PATH, profiles_array.size()])

	print("=== Export Complete ===")


func _process(_delta: float) -> bool:
	_iteration += 1
	return _iteration > 1


## AmmoProfile を Dictionary に変換
func profile_to_dict(profile, type_name: String) -> Dictionary:
	return {
		"ammo_type": type_name,
		"display_name": profile.display_name,
		"pen_ke": profile.pen_ke,
		"pen_ce": profile.pen_ce,
		"lethality": profile.lethality,
		"blast_radius": profile.blast_radius,
		"smoke_radius": profile.smoke_radius,
		"guidance": guidance_to_string(profile.guidance),
		"fuze": fuze_to_string(profile.fuze),
		"defeats_era": profile.defeats_era,
		"is_top_attack": profile.is_top_attack,
	}


## GuidanceType enum を文字列に変換
func guidance_to_string(g: int) -> String:
	match g:
		AmmunitionDataScript.GuidanceType.NONE:
			return "NONE"
		AmmunitionDataScript.GuidanceType.SACLOS:
			return "SACLOS"
		AmmunitionDataScript.GuidanceType.BEAM_RIDING:
			return "BEAM_RIDING"
		AmmunitionDataScript.GuidanceType.IR_HOMING:
			return "IR_HOMING"
		AmmunitionDataScript.GuidanceType.LASER_GUIDED:
			return "LASER_GUIDED"
		AmmunitionDataScript.GuidanceType.GPS_INS:
			return "GPS_INS"
		AmmunitionDataScript.GuidanceType.MMW_RADAR:
			return "MMW_RADAR"
		_:
			return "NONE"


## FuzeType enum を文字列に変換
func fuze_to_string(f: int) -> String:
	match f:
		AmmunitionDataScript.FuzeType.IMPACT:
			return "IMPACT"
		AmmunitionDataScript.FuzeType.DELAY:
			return "DELAY"
		AmmunitionDataScript.FuzeType.PROXIMITY:
			return "PROXIMITY"
		AmmunitionDataScript.FuzeType.TIME:
			return "TIME"
		AmmunitionDataScript.FuzeType.AIRBURST:
			return "AIRBURST"
		_:
			return "IMPACT"


## JSONファイルを保存
func save_json(path: String, data: Array) -> void:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to write: %s" % path)
