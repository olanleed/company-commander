class_name VehicleCatalog
extends RefCounted

## 兵器カタログシステム
## 各国の戦車・IFV等のスペックをJSONから読み込み、
## ElementTypeにmodifierを適用する

# =============================================================================
# VehicleConfig（車両設定）
# =============================================================================

class VehicleConfig:
	var id: String = ""
	var display_name: String = ""
	var display_name_en: String = ""
	var base_archetype: String = ""  # TANK_PLT, IFV_PLT等
	var mobility_class: String = ""  # TRACKED, WHEELED（空の場合はアーキタイプのデフォルト）
	var nation: String = ""
	var era: String = ""
	var unit_count: int = 4

	## 性能modifier（基準値1.0）
	var modifiers: Dictionary = {
		"armor_ke_front": 1.0,
		"armor_ke_side": 1.0,
		"armor_ke_rear": 1.0,
		"armor_ce_front": 1.0,
		"armor_ce_side": 1.0,
		"armor_ce_rear": 1.0,
		"spot_range": 1.0,
		"spot_range_moving": 1.0,
		"road_speed": 1.0,
		"cross_speed": 1.0,
	}

	## 主砲設定
	var main_gun: Dictionary = {
		"caliber_mm": 120,
		"pen_ke_modifier": 1.0,
		"pen_ce_modifier": 1.0,
		"rof_modifier": 1.0,
		"accuracy_modifier": 1.0,
	}

	## 防護設定
	var protection: Dictionary = {
		"era_equipped": false,
		"aps_equipped": false,
		"composite_gen": 3,
	}

	var notes: String = ""


	func get_modifier(key: String) -> float:
		if modifiers.has(key):
			return modifiers[key]
		return 1.0


	func get_gun_modifier(key: String) -> float:
		if main_gun.has(key):
			return main_gun[key]
		return 1.0

# =============================================================================
# カタログ管理
# =============================================================================

## 国コード -> 車両ID -> VehicleConfig
var _catalogs: Dictionary = {}

## 全車両のフラットリスト（ID -> VehicleConfig）
var _all_vehicles: Dictionary = {}


## 全カタログをロード
func load_all() -> void:
	var catalog_path := "res://data/catalog/"

	# カタログディレクトリ内の全JSONを読み込み
	var dir := DirAccess.open(catalog_path)
	if not dir:
		push_warning("[VehicleCatalog] Catalog directory not found: " + catalog_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path := catalog_path + file_name
			_load_catalog_file(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("[VehicleCatalog] Loaded %d vehicles from %d nations" % [
		_all_vehicles.size(),
		_catalogs.size()
	])


## 単一カタログファイルをロード
func _load_catalog_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[VehicleCatalog] Failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("[VehicleCatalog] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return

	var data: Dictionary = json.data
	if not data.has("nation") or not data.has("vehicles"):
		push_warning("[VehicleCatalog] Invalid catalog format: " + path)
		return

	var nation: String = data.nation
	if not _catalogs.has(nation):
		_catalogs[nation] = {}

	var vehicles: Array = data.vehicles
	for vehicle_data in vehicles:
		var config := _parse_vehicle_config(vehicle_data, nation)
		if config:
			_catalogs[nation][config.id] = config
			_all_vehicles[config.id] = config


## 車両データをパース
func _parse_vehicle_config(data: Dictionary, nation: String) -> VehicleConfig:
	if not data.has("id"):
		return null

	var config := VehicleConfig.new()
	config.id = data.get("id", "")
	config.display_name = data.get("display_name", config.id)
	config.display_name_en = data.get("display_name_en", config.display_name)
	config.base_archetype = data.get("base_archetype", "TANK_PLT")
	config.mobility_class = data.get("mobility_class", "")  # TRACKED, WHEELED
	config.nation = nation
	config.era = data.get("era", "")
	config.unit_count = data.get("unit_count", 4)
	config.notes = data.get("notes", "")

	# modifiers
	if data.has("modifiers"):
		var mods: Dictionary = data.modifiers
		for key in mods:
			config.modifiers[key] = mods[key]

	# main_gun
	if data.has("main_gun"):
		var gun: Dictionary = data.main_gun
		for key in gun:
			config.main_gun[key] = gun[key]

	# protection
	if data.has("protection"):
		var prot: Dictionary = data.protection
		for key in prot:
			config.protection[key] = prot[key]

	return config

# =============================================================================
# 公開API
# =============================================================================

## 車両IDからVehicleConfigを取得
func get_vehicle(vehicle_id: String) -> VehicleConfig:
	return _all_vehicles.get(vehicle_id, null)


## 国コードから全車両を取得
func get_vehicles_for_nation(nation: String) -> Array[VehicleConfig]:
	var result: Array[VehicleConfig] = []
	if _catalogs.has(nation):
		for vehicle_id in _catalogs[nation]:
			result.append(_catalogs[nation][vehicle_id])
	return result


## 特定アーキタイプの全車両を取得
func get_vehicles_for_archetype(archetype: String) -> Array[VehicleConfig]:
	var result: Array[VehicleConfig] = []
	for vehicle_id in _all_vehicles:
		var config: VehicleConfig = _all_vehicles[vehicle_id]
		if config.base_archetype == archetype:
			result.append(config)
	return result


## 全国コードを取得
func get_all_nations() -> Array[String]:
	var result: Array[String] = []
	for nation in _catalogs:
		result.append(nation)
	return result


## 全車両IDを取得
func get_all_vehicle_ids() -> Array[String]:
	var result: Array[String] = []
	for vehicle_id in _all_vehicles:
		result.append(vehicle_id)
	return result


## カタログがロード済みか
func is_loaded() -> bool:
	return _all_vehicles.size() > 0

# =============================================================================
# ElementType へのmodifier適用
# =============================================================================

## ElementTypeにVehicleConfigのmodifierを適用
## 注意: display_nameは変更しない（"Tank Platoon"等の汎用名を維持）
## 車両名はElementInstance.vehicle_idで参照可能
func apply_to_element_type(
	element_type: ElementData.ElementType,
	vehicle_config: VehicleConfig
) -> void:
	if not element_type or not vehicle_config:
		return

	# 装甲modifier適用
	_apply_armor_modifiers(element_type, vehicle_config)

	# 機動性クラス（TRACKED/WHEELED）を適用
	if vehicle_config.mobility_class != "":
		match vehicle_config.mobility_class:
			"TRACKED":
				element_type.mobility_class = GameEnums.MobilityType.TRACKED
			"WHEELED":
				element_type.mobility_class = GameEnums.MobilityType.WHEELED
			"FOOT":
				element_type.mobility_class = GameEnums.MobilityType.FOOT

	# 機動性modifier適用
	element_type.road_speed *= vehicle_config.get_modifier("road_speed")
	element_type.cross_speed *= vehicle_config.get_modifier("cross_speed")

	# 視界modifier適用
	element_type.spot_range_base *= vehicle_config.get_modifier("spot_range")
	element_type.spot_range_moving *= vehicle_config.get_modifier("spot_range_moving")

	# ユニット数を適用
	element_type.base_strength = vehicle_config.unit_count
	element_type.max_strength = vehicle_config.unit_count


## 装甲modifierを適用
func _apply_armor_modifiers(
	element_type: ElementData.ElementType,
	vehicle_config: VehicleConfig
) -> void:
	# KE装甲
	if element_type.armor_ke.size() > 0:
		if element_type.armor_ke.has(WeaponData.ArmorZone.FRONT):
			element_type.armor_ke[WeaponData.ArmorZone.FRONT] = int(
				element_type.armor_ke[WeaponData.ArmorZone.FRONT] *
				vehicle_config.get_modifier("armor_ke_front")
			)
		if element_type.armor_ke.has(WeaponData.ArmorZone.SIDE):
			element_type.armor_ke[WeaponData.ArmorZone.SIDE] = int(
				element_type.armor_ke[WeaponData.ArmorZone.SIDE] *
				vehicle_config.get_modifier("armor_ke_side")
			)
		if element_type.armor_ke.has(WeaponData.ArmorZone.REAR):
			element_type.armor_ke[WeaponData.ArmorZone.REAR] = int(
				element_type.armor_ke[WeaponData.ArmorZone.REAR] *
				vehicle_config.get_modifier("armor_ke_rear")
			)

	# CE装甲
	if element_type.armor_ce.size() > 0:
		if element_type.armor_ce.has(WeaponData.ArmorZone.FRONT):
			element_type.armor_ce[WeaponData.ArmorZone.FRONT] = int(
				element_type.armor_ce[WeaponData.ArmorZone.FRONT] *
				vehicle_config.get_modifier("armor_ce_front")
			)
		if element_type.armor_ce.has(WeaponData.ArmorZone.SIDE):
			element_type.armor_ce[WeaponData.ArmorZone.SIDE] = int(
				element_type.armor_ce[WeaponData.ArmorZone.SIDE] *
				vehicle_config.get_modifier("armor_ce_side")
			)
		if element_type.armor_ce.has(WeaponData.ArmorZone.REAR):
			element_type.armor_ce[WeaponData.ArmorZone.REAR] = int(
				element_type.armor_ce[WeaponData.ArmorZone.REAR] *
				vehicle_config.get_modifier("armor_ce_rear")
			)

# =============================================================================
# WeaponType へのmodifier適用
# =============================================================================

## WeaponTypeにVehicleConfigのmain_gun modifierを適用
func apply_to_weapon(
	weapon: WeaponData.WeaponType,
	vehicle_config: VehicleConfig
) -> void:
	if not weapon or not vehicle_config:
		return

	var pen_ke_mod := vehicle_config.get_gun_modifier("pen_ke_modifier")
	var pen_ce_mod := vehicle_config.get_gun_modifier("pen_ce_modifier")
	var rof_mod := vehicle_config.get_gun_modifier("rof_modifier")
	var accuracy_mod := vehicle_config.get_gun_modifier("accuracy_modifier")

	# KE貫徹力
	for band in weapon.pen_ke:
		weapon.pen_ke[band] = int(weapon.pen_ke[band] * pen_ke_mod)

	# CE貫徹力
	for band in weapon.pen_ce:
		weapon.pen_ce[band] = int(weapon.pen_ce[band] * pen_ce_mod)

	# 発射レート
	if weapon.rof_rpm > 0:
		weapon.rof_rpm *= rof_mod

	# 命中精度（sigma_hit_mを小さくする = 精度向上）
	if weapon.sigma_hit_m > 0 and accuracy_mod > 0:
		weapon.sigma_hit_m /= accuracy_mod
