extends GutTest

## 砲兵ユニット生成テスト
## 各国の自走砲・自走迫撃砲がVehicleCatalogから正しく生成されることを検証

var element_factory_initialized: bool = false


func before_all() -> void:
	# VehicleCatalogを初期化
	ElementFactory.init_vehicle_catalog()
	element_factory_initialized = true


func before_each() -> void:
	ElementFactory.reset_id_counters()


# =============================================================================
# 日本の砲兵ユニットテスト
# =============================================================================

func test_jpn_type99_sph_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type99_SPH",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "JPN_Type99_SPH")
	assert_true(element.weapons.size() > 0, "Should have weapons")

	# 主砲は155mm榴弾砲
	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_155":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 155mm howitzer")


func test_jpn_type19_sph_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type19_SPH",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "JPN_Type19_SPH")

	# 主砲は155mm榴弾砲
	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_155":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 155mm howitzer")


func test_jpn_type24_mortar_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type24_Mortar",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "JPN_Type24_Mortar")

	# 主砲は120mm迫撃砲
	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


# =============================================================================
# 米国の砲兵ユニットテスト
# =============================================================================

func test_usa_m109a7_paladin_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"USA_M109A7_Paladin",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "USA_M109A7_Paladin")

	# 主砲は155mm榴弾砲
	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_155":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 155mm howitzer")


func test_usa_m109a6_paladin_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"USA_M109A6_Paladin",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "USA_M109A6_Paladin")

	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_155":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 155mm howitzer")


func test_usa_m1287_ampv_mc_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"USA_M1287_AMPV_MC",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "USA_M1287_AMPV_MC")

	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


func test_usa_m1129_stryker_mc_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"USA_M1129_Stryker_MC",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "USA_M1129_Stryker_MC")

	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


# =============================================================================
# ロシアの砲兵ユニットテスト
# =============================================================================

func test_rus_2s19_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"RUS_2S19",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "RUS_2S19")

	# 主砲は152mm榴弾砲
	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_152":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 152mm howitzer")


func test_rus_2s35_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"RUS_2S35",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "RUS_2S35")

	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_152":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 152mm howitzer")


func test_rus_2s9_nona_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"RUS_2S9_Nona",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "RUS_2S9_Nona")

	# 120mm迫撃砲
	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


func test_rus_2s23_nona_svk_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"RUS_2S23_Nona_SVK",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "RUS_2S23_Nona_SVK")

	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


func test_rus_2s34_khosta_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"RUS_2S34_Khosta",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "RUS_2S34_Khosta")

	var has_mortar := false
	for weapon in element.weapons:
		if weapon.id == "CW_MORTAR_120":
			has_mortar = true
			break
	assert_true(has_mortar, "Should have 120mm mortar")


# =============================================================================
# 中国の砲兵ユニットテスト
# =============================================================================

func test_chn_plz05_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"CHN_PLZ05",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "CHN_PLZ05")

	# 主砲は155mm榴弾砲
	var has_howitzer := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_155":
			has_howitzer = true
			break
	assert_true(has_howitzer, "Should have 155mm howitzer")


func test_chn_plz07_creation() -> void:
	var element := ElementFactory.create_element_with_vehicle(
		"CHN_PLZ07",
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)

	assert_not_null(element, "Should create element")
	assert_eq(element.vehicle_id, "CHN_PLZ07")

	# 122mm榴弾砲
	var has_weapon := false
	for weapon in element.weapons:
		if weapon.id == "CW_HOWITZER_122_CHN":
			has_weapon = true
			break
	assert_true(has_weapon, "Should have artillery weapon")


# =============================================================================
# 武器特性テスト
# =============================================================================

func test_howitzer_155_is_heavy_he() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.fire_model, WeaponData.FireModel.INDIRECT)
	assert_eq(weapon.caliber_mm, 155.0)


func test_howitzer_152_is_heavy_he() -> void:
	var weapon := WeaponData.create_cw_howitzer_152()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.fire_model, WeaponData.FireModel.INDIRECT)
	assert_eq(weapon.caliber_mm, 152.0)


func test_mortar_120_is_heavy_he() -> void:
	var weapon := WeaponData.create_cw_mortar_120()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.fire_model, WeaponData.FireModel.INDIRECT)
	assert_eq(weapon.caliber_mm, 120.0)


# =============================================================================
# VehicleCatalog砲兵一覧テスト
# =============================================================================

func test_all_artillery_vehicles_have_artillery_archetype() -> void:
	var catalog: VehicleCatalog = ElementFactory.get_vehicle_catalog()
	var artillery_vehicles: Array[VehicleCatalog.VehicleConfig] = catalog.get_vehicles_for_archetype("SP_ARTILLERY")

	assert_gt(artillery_vehicles.size(), 0, "Should have SP_ARTILLERY vehicles")

	for config in artillery_vehicles:
		assert_eq(config.base_archetype, "SP_ARTILLERY",
			"Vehicle %s should have SP_ARTILLERY archetype" % config.id)


func test_all_mortar_vehicles_have_mortar_archetype() -> void:
	var catalog: VehicleCatalog = ElementFactory.get_vehicle_catalog()
	var mortar_vehicles: Array[VehicleCatalog.VehicleConfig] = catalog.get_vehicles_for_archetype("SP_MORTAR")

	assert_gt(mortar_vehicles.size(), 0, "Should have SP_MORTAR vehicles")

	for config in mortar_vehicles:
		assert_eq(config.base_archetype, "SP_MORTAR",
			"Vehicle %s should have SP_MORTAR archetype" % config.id)


# =============================================================================
# 自走迫撃砲展開時間テスト
# =============================================================================

func test_sp_mortar_deploy_time_faster_than_sph() -> void:
	# 履帯式自走迫撃砲（10秒）は履帯式自走砲（15秒）より展開が速いことを確認
	# 注: 装輪式迫撃砲(15秒)と履帯式自走砲(15秒)は同じ展開時間なので履帯式迫撃砲を使用
	var mortar := ElementFactory.create_element_with_vehicle(
		"USA_M1287_AMPV_MC",  # SP_MORTAR + TRACKED = 10秒
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var sph := ElementFactory.create_element_with_vehicle(
		"JPN_Type99_SPH",  # SP_ARTILLERY + TRACKED = 15秒
		GameEnums.Faction.BLUE,
		Vector2(200, 100)
	)

	assert_lt(mortar.artillery_deploy_time_sec, sph.artillery_deploy_time_sec,
		"Tracked mortar (10s) should deploy faster than tracked SPH (15s)")
	print("[Test] Mortar deploy: %.1fs, SPH deploy: %.1fs" % [
		mortar.artillery_deploy_time_sec, sph.artillery_deploy_time_sec
	])


func test_tracked_mortar_faster_than_wheeled() -> void:
	# 履帯式迫撃砲は装輪式より展開が速い
	var rus_tracked := ElementFactory.create_element_with_vehicle(
		"RUS_2S9_Nona",  # 履帯式
		GameEnums.Faction.RED,
		Vector2(100, 100)
	)
	var rus_wheeled := ElementFactory.create_element_with_vehicle(
		"RUS_2S23_Nona_SVK",  # 装輪式
		GameEnums.Faction.RED,
		Vector2(200, 100)
	)

	assert_lt(rus_tracked.artillery_deploy_time_sec, rus_wheeled.artillery_deploy_time_sec,
		"Tracked mortar should deploy faster than wheeled")
	print("[Test] Tracked mortar deploy: %.1fs, Wheeled mortar deploy: %.1fs" % [
		rus_tracked.artillery_deploy_time_sec, rus_wheeled.artillery_deploy_time_sec
	])


func test_sp_mortar_has_indirect_fire_weapon() -> void:
	# すべての自走迫撃砲がINDIRECT射撃武器を持つことを確認
	var catalog: VehicleCatalog = ElementFactory.get_vehicle_catalog()
	var mortar_vehicles: Array[VehicleCatalog.VehicleConfig] = catalog.get_vehicles_for_archetype("SP_MORTAR")

	for config in mortar_vehicles:
		var element := ElementFactory.create_element_with_vehicle(
			config.id,
			GameEnums.Faction.BLUE,
			Vector2(100, 100)
		)
		assert_not_null(element, "Should create element for %s" % config.id)

		var has_indirect := false
		for weapon in element.weapons:
			if weapon.fire_model == WeaponData.FireModel.INDIRECT:
				has_indirect = true
				break
		assert_true(has_indirect, "%s should have INDIRECT fire weapon" % config.id)
