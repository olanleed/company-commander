extends GutTest

## カタログ整合性テスト
## docs/root/document_tree_architecture_v0.1.md に基づく品質ゲート

var WeaponDataClass: GDScript
var VehicleCatalogClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")
	VehicleCatalogClass = load("res://scripts/data/vehicle_catalog.gd")


# =============================================================================
# カタログ読み込みテスト
# =============================================================================

func test_catalog_loads_all_nations() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()
	assert_gt(vehicles.size(), 0, "Catalog should load vehicles")


func test_catalog_has_usa_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("USA_M1A2_SEPv3")
	assert_not_null(vehicle, "Should have USA vehicles")


func test_catalog_has_rus_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("RUS_T90M")
	assert_not_null(vehicle, "Should have RUS vehicles")


func test_catalog_has_chn_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("CHN_Type99A")
	assert_not_null(vehicle, "Should have CHN vehicles")


func test_catalog_has_jpn_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicle = catalog.get_vehicle("JPN_Type10")
	assert_not_null(vehicle, "Should have JPN vehicles")


# =============================================================================
# 武器ID整合性テスト（全車両のweapon_idがweapon_data.gdに存在するか）
# =============================================================================

func test_all_main_gun_ids_exist_in_weapon_data() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var vehicles = catalog.get_all_vehicles()

	var missing_weapons: Array = []
	for vehicle in vehicles:
		if vehicle.has("main_gun") and vehicle.main_gun != null:
			if vehicle.main_gun.has("weapon_id"):
				var weapon_id: String = vehicle.main_gun.weapon_id
				if not weapons.has(weapon_id):
					missing_weapons.append("%s: %s" % [vehicle.id, weapon_id])

	assert_eq(missing_weapons.size(), 0,
		"All main_gun weapon_ids should exist. Missing: %s" % str(missing_weapons))


func test_all_atgm_ids_exist_in_weapon_data() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var vehicles = catalog.get_all_vehicles()

	var missing_weapons: Array = []
	for vehicle in vehicles:
		if vehicle.has("atgm") and vehicle.atgm != null:
			if vehicle.atgm.has("weapon_id"):
				var weapon_id: String = vehicle.atgm.weapon_id
				if not weapons.has(weapon_id):
					missing_weapons.append("%s: %s" % [vehicle.id, weapon_id])

	assert_eq(missing_weapons.size(), 0,
		"All atgm weapon_ids should exist. Missing: %s" % str(missing_weapons))


func test_all_secondary_weapon_ids_exist_in_weapon_data() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()
	var vehicles = catalog.get_all_vehicles()

	var missing_weapons: Array = []
	for vehicle in vehicles:
		if vehicle.has("secondary_weapons") and vehicle.secondary_weapons != null:
			for weapon_id in vehicle.secondary_weapons:
				if not weapons.has(weapon_id):
					missing_weapons.append("%s: %s" % [vehicle.id, weapon_id])

	assert_eq(missing_weapons.size(), 0,
		"All secondary weapon_ids should exist. Missing: %s" % str(missing_weapons))


# =============================================================================
# Vehicle ID命名規則テスト
# =============================================================================

func test_all_vehicle_ids_follow_naming_convention() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var invalid_ids: Array = []
	var valid_prefixes = ["USA_", "RUS_", "CHN_", "JPN_", "ROK_", "GER_", "GBR_", "FRA_"]

	for vehicle in vehicles:
		var has_valid_prefix = false
		for prefix in valid_prefixes:
			if vehicle.id.begins_with(prefix):
				has_valid_prefix = true
				break
		if not has_valid_prefix:
			invalid_ids.append(vehicle.id)

	assert_eq(invalid_ids.size(), 0,
		"All vehicle IDs should follow naming convention <NATION>_<Name>. Invalid: %s" % str(invalid_ids))


# =============================================================================
# Weapon ID命名規則テスト
# =============================================================================

func test_all_weapon_ids_follow_naming_convention() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	var invalid_ids: Array = []
	for weapon_id in weapons.keys():
		# 新命名規則: W_{国籍}_{カテゴリ}_{名称} または 旧命名規則: CW_*
		if not weapon_id.begins_with("CW_") and not weapon_id.begins_with("W_"):
			invalid_ids.append(weapon_id)

	assert_eq(invalid_ids.size(), 0,
		"All weapon IDs should start with 'CW_' or 'W_'. Invalid: %s" % str(invalid_ids))


# =============================================================================
# 車両属性完全性テスト
# =============================================================================

func test_all_vehicles_have_required_fields() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var incomplete_vehicles: Array = []
	var required_fields = ["id", "display_name"]

	for vehicle in vehicles:
		for field in required_fields:
			if not vehicle.has(field):
				incomplete_vehicles.append("%s missing %s" % [vehicle.get("id", "unknown"), field])

	assert_eq(incomplete_vehicles.size(), 0,
		"All vehicles should have required fields. Incomplete: %s" % str(incomplete_vehicles))


func test_combat_vehicles_have_main_gun() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var combat_types = ["MBT", "IFV", "AFV", "TANK_DESTROYER", "LIGHT_TANK", "SPAAG", "SPH"]
	var missing_main_gun: Array = []

	for vehicle in vehicles:
		if vehicle.has("type") and vehicle.type in combat_types:
			if not vehicle.has("main_gun") or vehicle.main_gun == null:
				missing_main_gun.append(vehicle.id)
			elif not vehicle.main_gun.has("weapon_id"):
				missing_main_gun.append("%s (no weapon_id)" % vehicle.id)

	assert_eq(missing_main_gun.size(), 0,
		"Combat vehicles should have main_gun. Missing: %s" % str(missing_main_gun))


# =============================================================================
# 武器タイプ整合性テスト
# =============================================================================

func test_all_weapons_have_mechanism() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	var missing_mechanism: Array = []
	for weapon_id in weapons.keys():
		var weapon = weapons[weapon_id]
		# mechanism should be set (not -1 or null equivalent)
		if weapon.mechanism < 0 or weapon.mechanism > 3:
			missing_mechanism.append(weapon_id)

	assert_eq(missing_mechanism.size(), 0,
		"All weapons should have valid mechanism. Invalid: %s" % str(missing_mechanism))


func test_all_weapons_have_fire_model() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	var missing_fire_model: Array = []
	for weapon_id in weapons.keys():
		var weapon = weapons[weapon_id]
		if weapon.fire_model < 0 or weapon.fire_model > 2:
			missing_fire_model.append(weapon_id)

	assert_eq(missing_fire_model.size(), 0,
		"All weapons should have valid fire_model. Invalid: %s" % str(missing_fire_model))


func test_ke_weapons_have_pen_ke() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	var missing_pen: Array = []
	for weapon_id in weapons.keys():
		var weapon = weapons[weapon_id]
		if weapon.mechanism == WeaponDataClass.Mechanism.KINETIC:
			if weapon.pen_ke.is_empty():
				missing_pen.append(weapon_id)

	assert_eq(missing_pen.size(), 0,
		"KINETIC weapons should have pen_ke. Missing: %s" % str(missing_pen))


func test_shaped_charge_weapons_have_pen_ce() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	var missing_pen: Array = []
	for weapon_id in weapons.keys():
		var weapon = weapons[weapon_id]
		if weapon.mechanism == WeaponDataClass.Mechanism.SHAPED_CHARGE:
			if weapon.pen_ce.is_empty():
				missing_pen.append(weapon_id)

	assert_eq(missing_pen.size(), 0,
		"SHAPED_CHARGE weapons should have pen_ce. Missing: %s" % str(missing_pen))


# =============================================================================
# 国別車両数テスト（最低限の存在確認）
# =============================================================================

func test_usa_has_minimum_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var usa_count = 0
	for v in vehicles:
		if v.id.begins_with("USA_"):
			usa_count += 1

	assert_true(usa_count >= 10, "USA should have at least 10 vehicles")


func test_rus_has_minimum_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var rus_count = 0
	for v in vehicles:
		if v.id.begins_with("RUS_"):
			rus_count += 1

	assert_true(rus_count >= 10, "RUS should have at least 10 vehicles")


func test_chn_has_minimum_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var chn_count = 0
	for v in vehicles:
		if v.id.begins_with("CHN_"):
			chn_count += 1

	assert_true(chn_count >= 10, "CHN should have at least 10 vehicles")


func test_jpn_has_minimum_vehicles() -> void:
	var catalog = VehicleCatalogClass.new()
	catalog.load_all()
	var vehicles = catalog.get_all_vehicles()

	var jpn_count = 0
	for v in vehicles:
		if v.id.begins_with("JPN_"):
			jpn_count += 1

	assert_true(jpn_count >= 10, "JPN should have at least 10 vehicles")


# =============================================================================
# 武器間の整合性テスト（新型 > 旧型の関係）
# =============================================================================

func test_penetration_hierarchy_125mm_rus() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# 3BM60 > 3BM42
	if weapons.has("CW_TANK_KE_125_RUS") and weapons.has("CW_TANK_KE_125_MANGO"):
		var svinets = weapons["CW_TANK_KE_125_RUS"]
		var mango = weapons["CW_TANK_KE_125_MANGO"]
		assert_gt(svinets.pen_ke[WeaponDataClass.RangeBand.MID],
			mango.pen_ke[WeaponDataClass.RangeBand.MID],
			"3BM60 should have higher penetration than 3BM42")


func test_penetration_hierarchy_125mm_chn() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# DTC10 > DTW-125 II > DTW-125
	if weapons.has("CW_TANK_KE_125_CHN") and weapons.has("CW_TANK_KE_125_CHN_STD"):
		var dtc10 = weapons["CW_TANK_KE_125_CHN"]
		var dtw125ii = weapons["CW_TANK_KE_125_CHN_STD"]
		assert_gt(dtc10.pen_ke[WeaponDataClass.RangeBand.MID],
			dtw125ii.pen_ke[WeaponDataClass.RangeBand.MID],
			"DTC10 should have higher penetration than DTW-125 II")


func test_larger_caliber_higher_penetration() -> void:
	var weapons: Dictionary = WeaponDataClass.get_all_concrete_weapons()

	# 30mm > 25mm (same nation)
	if weapons.has("CW_AUTOCANNON_30X173_USA") and weapons.has("CW_AUTOCANNON_25_USA"):
		var mm30 = weapons["CW_AUTOCANNON_30X173_USA"]
		var mm25 = weapons["CW_AUTOCANNON_25_USA"]
		assert_gt(mm30.pen_ke[WeaponDataClass.RangeBand.NEAR],
			mm25.pen_ke[WeaponDataClass.RangeBand.NEAR],
			"30mm should have higher penetration than 25mm")
