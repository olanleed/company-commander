extends MainLoop

## アーキタイプデータをJSONにエクスポートするスクリプト
## 使用方法: godot --headless --script tools/export_archetypes_to_json.gd

const OUTPUT_PATH := "res://data/archetypes/element_archetypes.json"

var ElementDataScript: GDScript
var WeaponDataScript: GDScript
var GameEnumsScript: GDScript

var _iteration := 0


func _initialize() -> void:
	print("=== Archetype Exporter ===")

	ElementDataScript = load("res://scripts/data/element_data.gd")
	WeaponDataScript = load("res://scripts/data/weapon_data.gd")
	GameEnumsScript = load("res://scripts/core/game_enums.gd")

	# 出力ディレクトリ確認
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("data/archetypes"):
		dir.make_dir_recursive("data/archetypes")

	# 全アーキタイプをエクスポート
	var archetypes: Dictionary = ElementDataScript.ElementArchetypes.get_all_archetypes()
	var archetypes_array := []

	print("Total archetypes: %d" % archetypes.size())

	for archetype_id in archetypes:
		var archetype = archetypes[archetype_id]
		var archetype_dict := archetype_to_dict(archetype)
		archetypes_array.append(archetype_dict)
		print("  Exported: %s (%s)" % [archetype_id, archetype.display_name])

	# JSON出力
	var json_string := JSON.stringify(archetypes_array, "\t")
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("\nExported %d archetypes to %s" % [archetypes_array.size(), OUTPUT_PATH])
	else:
		push_error("Failed to write: %s" % OUTPUT_PATH)

	print("=== Export Complete ===")


func _process(_delta: float) -> bool:
	_iteration += 1
	return _iteration > 1


## ElementTypeをDictionaryに変換
func archetype_to_dict(archetype) -> Dictionary:
	var result := {
		"id": archetype.id,
		"display_name": archetype.display_name,
		"category": _category_to_string(archetype.category),
		"symbol_type": _symbol_type_to_string(archetype.symbol_type),
		"mobility_class": _mobility_to_string(archetype.mobility_class),
		"armor_class": archetype.armor_class,
		"road_speed": archetype.road_speed,
		"cross_speed": archetype.cross_speed,
		"base_strength": archetype.base_strength,
		"max_strength": archetype.max_strength,
		"spot_range_base": archetype.spot_range_base,
		"spot_range_moving": archetype.spot_range_moving,
	}

	# 通信ハブ設定（デフォルトと異なる場合のみ）
	if archetype.is_comm_hub:
		result["is_comm_hub"] = true
		result["comm_range"] = archetype.comm_range

	# 輸送能力（デフォルトと異なる場合のみ）
	if archetype.can_transport_infantry:
		result["can_transport_infantry"] = true
		result["transport_capacity"] = archetype.transport_capacity

	# 装甲データ（存在する場合のみ）
	if not archetype.armor_ke.is_empty():
		result["armor_ke"] = _armor_to_dict(archetype.armor_ke)
	if not archetype.armor_ce.is_empty():
		result["armor_ce"] = _armor_to_dict(archetype.armor_ce)

	return result


## 装甲DictionaryをJSON用に変換
func _armor_to_dict(armor: Dictionary) -> Dictionary:
	var result := {}
	for zone in armor:
		var zone_str := _armor_zone_to_string(zone)
		result[zone_str] = armor[zone]
	return result


## Category enumを文字列に変換
func _category_to_string(category: int) -> String:
	match category:
		ElementDataScript.Category.INF: return "INF"
		ElementDataScript.Category.VEH: return "VEH"
		ElementDataScript.Category.REC: return "REC"
		ElementDataScript.Category.WEAP: return "WEAP"
		ElementDataScript.Category.ENG: return "ENG"
		ElementDataScript.Category.LOG: return "LOG"
		ElementDataScript.Category.HQ: return "HQ"
		_: return "INF"


## SymbolType enumを文字列に変換
func _symbol_type_to_string(symbol_type: int) -> String:
	match symbol_type:
		ElementDataScript.SymbolType.INF_RIFLE: return "INF_RIFLE"
		ElementDataScript.SymbolType.INF_MECH: return "INF_MECH"
		ElementDataScript.SymbolType.INF_RECON: return "INF_RECON"
		ElementDataScript.SymbolType.INF_ENGINEER: return "INF_ENGINEER"
		ElementDataScript.SymbolType.ARMOR_TANK: return "ARMOR_TANK"
		ElementDataScript.SymbolType.ARMOR_IFV: return "ARMOR_IFV"
		ElementDataScript.SymbolType.ARMOR_APC: return "ARMOR_APC"
		ElementDataScript.SymbolType.FS_MORTAR: return "FS_MORTAR"
		ElementDataScript.SymbolType.FS_ATGM: return "FS_ATGM"
		ElementDataScript.SymbolType.FS_ARTILLERY: return "FS_ARTILLERY"
		ElementDataScript.SymbolType.RECON_UAV: return "RECON_UAV"
		ElementDataScript.SymbolType.SUP_LOGISTICS: return "SUP_LOGISTICS"
		ElementDataScript.SymbolType.SUP_MEDEVAC: return "SUP_MEDEVAC"
		ElementDataScript.SymbolType.CMD_HQ: return "CMD_HQ"
		_: return "INF_RIFLE"


## MobilityType enumを文字列に変換
func _mobility_to_string(mobility: int) -> String:
	match mobility:
		GameEnumsScript.MobilityType.FOOT: return "FOOT"
		GameEnumsScript.MobilityType.WHEELED: return "WHEELED"
		GameEnumsScript.MobilityType.TRACKED: return "TRACKED"
		_: return "FOOT"


## ArmorZone enumを文字列に変換
func _armor_zone_to_string(zone: int) -> String:
	match zone:
		WeaponDataScript.ArmorZone.FRONT: return "FRONT"
		WeaponDataScript.ArmorZone.SIDE: return "SIDE"
		WeaponDataScript.ArmorZone.REAR: return "REAR"
		WeaponDataScript.ArmorZone.TOP: return "TOP"
		_: return "FRONT"
