extends MainLoop

## 武器データをJSONにエクスポートするスクリプト
## 使用方法: godot --headless --script tools/export_weapons_to_json.gd

const OUTPUT_DIR := "res://data/weapons/"

var WeaponDataScript: GDScript

# 武器を国別に分類
var nation_mapping := {
	"generic": [],
	"usa": [],
	"rus": [],
	"chn": [],
	"jpn": [],
}

var _iteration := 0


func _initialize() -> void:
	print("=== Weapon Data Export Tool ===")

	# スクリプトを動的にロード
	WeaponDataScript = load("res://scripts/data/weapon_data.gd")

	# 出力ディレクトリ確認
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("data/weapons"):
		dir.make_dir_recursive("data/weapons")

	# 全武器を取得
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()
	print("Total weapons: %d" % weapons.size())

	# 武器を国別に分類
	for weapon_id in weapons.keys():
		var weapon = weapons[weapon_id]
		var nation := classify_weapon_nation(weapon_id)
		nation_mapping[nation].append(weapon)

	# 国別にエクスポート
	for nation in nation_mapping.keys():
		var weapon_list: Array = nation_mapping[nation]
		if weapon_list.is_empty():
			continue

		var json_array: Array = []
		for weapon in weapon_list:
			json_array.append(weapon_to_dict(weapon))

		var filename := OUTPUT_DIR + "weapons_%s.json" % nation
		save_json(filename, json_array)
		print("Exported %s: %d weapons" % [filename, weapon_list.size()])

	print("=== Export Complete ===")


func _process(_delta: float) -> bool:
	_iteration += 1
	return _iteration > 1  # 1回処理後に終了


## 武器IDから国を判定
func classify_weapon_nation(weapon_id: String) -> String:
	if weapon_id.ends_with("_USA"):
		return "usa"
	elif weapon_id.ends_with("_RUS"):
		return "rus"
	elif weapon_id.ends_with("_CHN"):
		return "chn"
	elif weapon_id.ends_with("_JGSDF") or weapon_id.ends_with("_JPN"):
		return "jpn"
	# 特定の武器IDを国別に分類
	elif weapon_id in ["CW_ATGM_JAVELIN", "CW_ATGM_TOW2B", "CW_M240_COAX", "CW_M2HB", "CW_AGL_MK19"]:
		return "usa"
	elif weapon_id in ["CW_ATGM_KORNET", "CW_ATGM_REFLEKS", "CW_ATGM_KONKURS", "CW_ATGM_BASTION",
					   "CW_HMG_KPVT", "CW_PKT_COAX", "CW_KORD_AA"]:
		return "rus"
	elif weapon_id in ["CW_ATGM_HJ10", "CW_ATGM_HJ9", "CW_ATGM_HJ8E", "CW_ATGM_HJ73", "CW_ATGM_GP105",
					   "CW_QJC88_AA", "CW_QJZ89_AA", "CW_TYPE86_COAX"]:
		return "chn"
	elif weapon_id in ["CW_ATGM_01LMAT", "CW_ATGM_79MAT", "CW_ATGM_MMPM"]:
		return "jpn"
	else:
		return "generic"


## WeaponType を Dictionary に変換
func weapon_to_dict(weapon) -> Dictionary:
	return {
		"id": weapon.id,
		"display_name": weapon.display_name,
		"mechanism": mechanism_to_string(weapon.mechanism),
		"heavy_he_class": heavy_he_class_to_string(weapon.heavy_he_class),
		"caliber_mm": weapon.caliber_mm,
		"fire_model": fire_model_to_string(weapon.fire_model),
		"range": {
			"min_m": weapon.min_range_m,
			"max_m": weapon.max_range_m,
			"band_thresholds_m": Array(weapon.range_band_thresholds_m),
		},
		"threat_class": threat_class_to_string(weapon.threat_class),
		"preferred_target": preferred_target_to_string(weapon.preferred_target),
		"weapon_role": weapon_role_to_string(weapon.weapon_role),
		"ammo_endurance_min": weapon.ammo_endurance_min,
		"lethality": lethality_to_dict(weapon.lethality),
		"suppression_power": suppression_to_dict(weapon.suppression_power),
		"pen_ke": penetration_to_dict(weapon.pen_ke),
		"pen_ce": penetration_to_dict(weapon.pen_ce),
		"discrete_params": {
			"rof_rpm": weapon.rof_rpm,
			"sigma_hit_m": weapon.sigma_hit_m,
			"direct_hit_radius_m": weapon.direct_hit_radius_m,
			"shock_radius_m": weapon.shock_radius_m,
		},
		"indirect_params": {
			"setup_time_sec": weapon.setup_time_sec,
			"displace_time_sec": weapon.displace_time_sec,
			"requires_observer": weapon.requires_observer,
		},
		"blast_radius_m": weapon.blast_radius_m,
		"projectile": {
			"speed_mps": weapon.projectile_speed_mps,
			"size": weapon.projectile_size,
		},
	}


## Mechanism enum を文字列に変換
func mechanism_to_string(m: int) -> String:
	match m:
		WeaponDataScript.Mechanism.SMALL_ARMS:
			return "SMALL_ARMS"
		WeaponDataScript.Mechanism.KINETIC:
			return "KINETIC"
		WeaponDataScript.Mechanism.SHAPED_CHARGE:
			return "SHAPED_CHARGE"
		WeaponDataScript.Mechanism.BLAST_FRAG:
			return "BLAST_FRAG"
		_:
			return "UNKNOWN"


## HeavyHEClass enum を文字列に変換
func heavy_he_class_to_string(h: int) -> String:
	match h:
		WeaponDataScript.HeavyHEClass.NONE:
			return "NONE"
		WeaponDataScript.HeavyHEClass.HEAVY_HE:
			return "HEAVY_HE"
		_:
			return "NONE"


## FireModel enum を文字列に変換
func fire_model_to_string(f: int) -> String:
	match f:
		WeaponDataScript.FireModel.CONTINUOUS:
			return "CONTINUOUS"
		WeaponDataScript.FireModel.DISCRETE:
			return "DISCRETE"
		WeaponDataScript.FireModel.INDIRECT:
			return "INDIRECT"
		_:
			return "UNKNOWN"


## ThreatClass enum を文字列に変換
func threat_class_to_string(t: int) -> String:
	match t:
		WeaponDataScript.ThreatClass.SMALL_ARMS:
			return "SMALL_ARMS"
		WeaponDataScript.ThreatClass.AUTOCANNON:
			return "AUTOCANNON"
		WeaponDataScript.ThreatClass.HE_FRAG:
			return "HE_FRAG"
		WeaponDataScript.ThreatClass.AT:
			return "AT"
		_:
			return "UNKNOWN"


## PreferredTarget enum を文字列に変換
func preferred_target_to_string(p: int) -> String:
	match p:
		WeaponDataScript.PreferredTarget.SOFT:
			return "SOFT"
		WeaponDataScript.PreferredTarget.ARMOR:
			return "ARMOR"
		WeaponDataScript.PreferredTarget.ANY:
			return "ANY"
		_:
			return "ANY"


## WeaponRole enum を文字列に変換
func weapon_role_to_string(r: int) -> String:
	match r:
		WeaponDataScript.WeaponRole.MAIN_GUN_KE:
			return "MAIN_GUN_KE"
		WeaponDataScript.WeaponRole.MAIN_GUN_CE:
			return "MAIN_GUN_CE"
		WeaponDataScript.WeaponRole.ATGM:
			return "ATGM"
		WeaponDataScript.WeaponRole.AUTOCANNON:
			return "AUTOCANNON"
		WeaponDataScript.WeaponRole.COAX_MG:
			return "COAX_MG"
		WeaponDataScript.WeaponRole.HMG:
			return "HMG"
		WeaponDataScript.WeaponRole.AGL:
			return "AGL"
		WeaponDataScript.WeaponRole.SMALL_ARMS:
			return "SMALL_ARMS"
		WeaponDataScript.WeaponRole.RPG:
			return "RPG"
		WeaponDataScript.WeaponRole.MORTAR:
			return "MORTAR"
		WeaponDataScript.WeaponRole.HOWITZER:
			return "HOWITZER"
		WeaponDataScript.WeaponRole.GUN_LAUNCHER:
			return "GUN_LAUNCHER"
		_:
			return "UNKNOWN"


## RangeBand キーを文字列に変換した lethality 辞書
func lethality_to_dict(leth: Dictionary) -> Dictionary:
	var result := {}
	for band in leth.keys():
		var band_str := range_band_to_string(band)
		result[band_str] = {}
		for target in leth[band].keys():
			var target_str := target_class_to_string(target)
			result[band_str][target_str] = leth[band][target]
	return result


## RangeBand キーを文字列に変換した suppression 辞書
func suppression_to_dict(supp: Dictionary) -> Dictionary:
	var result := {}
	for band in supp.keys():
		var band_str := range_band_to_string(band)
		result[band_str] = supp[band]
	return result


## RangeBand キーを文字列に変換した penetration 辞書
func penetration_to_dict(pen: Dictionary) -> Dictionary:
	var result := {}
	for band in pen.keys():
		var band_str := range_band_to_string(band)
		result[band_str] = pen[band]
	return result


## RangeBand enum を文字列に変換
func range_band_to_string(band: int) -> String:
	match band:
		WeaponDataScript.RangeBand.NEAR:
			return "NEAR"
		WeaponDataScript.RangeBand.MID:
			return "MID"
		WeaponDataScript.RangeBand.FAR:
			return "FAR"
		_:
			return "UNKNOWN"


## TargetClass enum を文字列に変換
func target_class_to_string(tc: int) -> String:
	match tc:
		WeaponDataScript.TargetClass.SOFT:
			return "SOFT"
		WeaponDataScript.TargetClass.LIGHT:
			return "LIGHT"
		WeaponDataScript.TargetClass.HEAVY:
			return "HEAVY"
		WeaponDataScript.TargetClass.FORTIFIED:
			return "FORTIFIED"
		_:
			return "UNKNOWN"


## JSONファイルを保存
func save_json(path: String, data: Array) -> void:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to write: %s" % path)
