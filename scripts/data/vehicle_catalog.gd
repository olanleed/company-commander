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

	## ATGM設定（対戦車ミサイル）
	var atgm: Dictionary = {}

	## 副武装リスト（weapon_idの配列）
	var secondary_weapons: Array = []

	## 防護設定
	var protection: Dictionary = {
		"era_equipped": false,
		"aps_equipped": false,
		"composite_gen": 3,
	}

	## 砲兵展開設定（SP_ARTILLERY/SP_MORTARのみ有効）
	## 履帯自走砲: 展開15秒、撤収20秒
	## 装輪自走砲: 展開30秒、撤収45秒
	## 牽引砲: 展開120秒、撤収180秒
	var artillery_deploy_time_sec: float = 30.0   ## 展開にかかる時間（秒）
	var artillery_pack_time_sec: float = 45.0     ## 撤収にかかる時間（秒）

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

	# atgm
	if data.has("atgm"):
		var atgm_data: Dictionary = data.atgm
		for key in atgm_data:
			config.atgm[key] = atgm_data[key]

	# secondary_weapons
	if data.has("secondary_weapons"):
		config.secondary_weapons = data.secondary_weapons

	# 砲兵展開時間（JSONで指定があればそれを使用、なければアーキタイプとmobility_classに基づくデフォルト）
	if data.has("artillery_deploy_time_sec"):
		config.artillery_deploy_time_sec = data.artillery_deploy_time_sec
	else:
		# デフォルト値をアーキタイプとmobility_classから計算
		config.artillery_deploy_time_sec = _get_default_deploy_time(config.base_archetype, config.mobility_class)

	if data.has("artillery_pack_time_sec"):
		config.artillery_pack_time_sec = data.artillery_pack_time_sec
	else:
		config.artillery_pack_time_sec = _get_default_pack_time(config.base_archetype, config.mobility_class)

	return config


## 砲兵展開時間のデフォルト値を取得
## 履帯自走砲: 展開15秒（停止→即射撃準備完了に近い）
## 装輪自走砲: 展開30秒（アウトリガー展開等）
## 迫撃砲（自走）: 展開10秒（軽量で展開が速い）
func _get_default_deploy_time(archetype: String, mobility_class: String) -> float:
	if archetype == "SP_MORTAR":
		# 自走迫撃砲は軽量で展開が速い
		return 10.0 if mobility_class == "TRACKED" else 15.0
	elif archetype == "SP_ARTILLERY":
		# 自走砲は履帯式が速い、装輪式はアウトリガー展開が必要
		return 15.0 if mobility_class == "TRACKED" else 30.0
	elif archetype == "TOWED_ARTILLERY":
		# 牽引砲は展開に時間がかかる（将来拡張用）
		return 120.0
	return 0.0  # 砲兵以外


## 砲兵撤収時間のデフォルト値を取得
func _get_default_pack_time(archetype: String, mobility_class: String) -> float:
	if archetype == "SP_MORTAR":
		return 15.0 if mobility_class == "TRACKED" else 20.0
	elif archetype == "SP_ARTILLERY":
		return 20.0 if mobility_class == "TRACKED" else 45.0
	elif archetype == "TOWED_ARTILLERY":
		return 180.0
	return 0.0

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


## 全車両を取得（テスト用）
func get_all_vehicles() -> Array:
	var result: Array = []
	for vehicle_id in _all_vehicles:
		result.append(_all_vehicles[vehicle_id])
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
# ElementInstance への武器適用
# =============================================================================

## ElementInstanceにVehicleConfigの武器を適用
## これによりJSONカタログのweapon_idが実際の武器オブジェクトに変換される
func apply_weapons_to_element(
	element: ElementData.ElementInstance,
	vehicle_config: VehicleConfig
) -> void:
	if not element or not vehicle_config:
		return

	# 武器リストをクリア
	element.weapons.clear()
	element.primary_weapon = null
	element.current_weapon = null

	# 全武器を取得
	var all_weapons: Dictionary = WeaponData.get_all_concrete_weapons()

	# 主砲（main_gun）
	if vehicle_config.main_gun.has("weapon_id"):
		var weapon_id: String = vehicle_config.main_gun["weapon_id"]
		if weapon_id in all_weapons:
			# 武器の複製を作成（modifier適用のため）
			var main_weapon: WeaponData.WeaponType = _duplicate_weapon(all_weapons[weapon_id])
			# modifier適用
			apply_to_weapon(main_weapon, vehicle_config)
			element.weapons.append(main_weapon)
			element.primary_weapon = main_weapon
			element.current_weapon = main_weapon

	# ATGM（対戦車ミサイル）
	if vehicle_config.atgm.has("weapon_id"):
		var atgm_id: String = vehicle_config.atgm["weapon_id"]
		if atgm_id in all_weapons:
			var atgm_weapon: WeaponData.WeaponType = _duplicate_weapon(all_weapons[atgm_id])
			element.weapons.append(atgm_weapon)

	# 副武装（secondary_weapons）
	for weapon_entry in vehicle_config.secondary_weapons:
		var weapon_id: String = ""
		if weapon_entry is String:
			weapon_id = weapon_entry
		elif weapon_entry is Dictionary and weapon_entry.has("weapon_id"):
			weapon_id = weapon_entry["weapon_id"]

		if weapon_id != "" and weapon_id in all_weapons:
			var secondary_weapon: WeaponData.WeaponType = _duplicate_weapon(all_weapons[weapon_id])
			element.weapons.append(secondary_weapon)


## 武器を複製（modifier適用用）
func _duplicate_weapon(original: WeaponData.WeaponType) -> WeaponData.WeaponType:
	var dup := WeaponData.WeaponType.new()
	dup.id = original.id
	dup.display_name = original.display_name
	dup.mechanism = original.mechanism
	dup.fire_model = original.fire_model
	dup.min_range_m = original.min_range_m
	dup.max_range_m = original.max_range_m
	dup.range_band_thresholds_m = original.range_band_thresholds_m.duplicate()
	dup.threat_class = original.threat_class
	dup.preferred_target = original.preferred_target
	dup.ammo_endurance_min = original.ammo_endurance_min
	dup.rof_rpm = original.rof_rpm
	dup.sigma_hit_m = original.sigma_hit_m
	dup.direct_hit_radius_m = original.direct_hit_radius_m
	dup.shock_radius_m = original.shock_radius_m
	dup.setup_time_sec = original.setup_time_sec
	dup.displace_time_sec = original.displace_time_sec
	dup.requires_observer = original.requires_observer
	dup.blast_radius_m = original.blast_radius_m
	dup.projectile_speed_mps = original.projectile_speed_mps
	dup.projectile_size = original.projectile_size

	# Dictionaryの複製
	dup.lethality = original.lethality.duplicate(true)
	dup.suppression_power = original.suppression_power.duplicate(true)
	dup.pen_ke = original.pen_ke.duplicate(true)
	dup.pen_ce = original.pen_ce.duplicate(true)

	return dup


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
