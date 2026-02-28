extends GutTest

## 補給ユニット統合テスト
## 補給トラックの生成と補給システムとの連携を検証

const ElementFactoryClass := preload("res://scripts/data/element_factory.gd")
const ResupplySystemClass := preload("res://scripts/systems/resupply_system.gd")
const AmmoStateClass := preload("res://scripts/data/ammo_state.gd")


func before_all() -> void:
	# VehicleCatalogを初期化
	ElementFactoryClass.init_vehicle_catalog()


func after_each() -> void:
	# IDカウンターをリセット
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# 補給トラック生成テスト
# =============================================================================

func test_type73_medium_truck_creation() -> void:
	## 73式中型トラックが正しく生成される
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_not_null(truck, "Truck should be created")
	assert_eq(truck.vehicle_id, "JPN_Type73_MediumTruck", "Vehicle ID should match")
	assert_eq(truck.element_type.id, "LOG_TRUCK", "Archetype should be LOG_TRUCK")


func test_type73_medium_truck_has_supply_config() -> void:
	## 73式中型トラックは補給設定を持つ
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_true(truck.supply_config.size() > 0, "Should have supply config")
	assert_eq(truck.supply_config.get("capacity"), 60, "Capacity should be 60")
	assert_eq(truck.supply_config.get("supply_range_m"), 150.0, "Supply range should be 150m")
	assert_eq(truck.supply_config.get("ammo_resupply_rate"), 0.8, "Ammo rate should be 0.8")


func test_type73_large_truck_has_supply_config() -> void:
	## 73式大型トラックは補給設定を持つ
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_true(truck.supply_config.size() > 0, "Should have supply config")
	assert_eq(truck.supply_config.get("capacity"), 100, "Capacity should be 100")
	assert_eq(truck.supply_config.get("supply_range_m"), 150.0, "Supply range should be 150m")
	assert_eq(truck.supply_config.get("ammo_resupply_rate"), 1.0, "Ammo rate should be 1.0")


func test_type74_extra_large_truck_has_supply_config() -> void:
	## 74式特大型トラックは補給設定を持つ
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type74_ExtraLargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_true(truck.supply_config.size() > 0, "Should have supply config")
	assert_eq(truck.supply_config.get("capacity"), 150, "Capacity should be 150")
	assert_eq(truck.supply_config.get("supply_range_m"), 150.0, "Supply range should be 150m")
	assert_eq(truck.supply_config.get("ammo_resupply_rate"), 1.2, "Ammo rate should be 1.2")


# =============================================================================
# 補給システム統合テスト
# =============================================================================

func test_register_supply_unit() -> void:
	## 補給ユニットを補給システムに登録できる
	var resupply := ResupplySystemClass.new()
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	resupply.register_supply_unit(truck, truck.supply_config)

	var supply_units := resupply.get_all_supply_units()
	assert_eq(supply_units.size(), 1, "Should have 1 supply unit")
	assert_true(truck.id in supply_units, "Truck ID should be in supply units")


func test_get_supply_unit_info() -> void:
	## 登録した補給ユニットの情報を取得できる
	var resupply := ResupplySystemClass.new()
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type74_ExtraLargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	resupply.register_supply_unit(truck, truck.supply_config)

	var info := resupply.get_supply_unit_info(truck.id)
	assert_eq(info.get("capacity"), 150, "Capacity should be 150")
	assert_eq(info.get("remaining_capacity"), 150, "Remaining capacity should be 150")
	assert_eq(info.get("supply_range_m"), 150.0, "Supply range should be 150m")


func test_unregister_supply_unit() -> void:
	## 補給ユニットを登録解除できる
	var resupply := ResupplySystemClass.new()
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	resupply.register_supply_unit(truck, truck.supply_config)
	resupply.unregister_supply_unit(truck.id)

	var supply_units := resupply.get_all_supply_units()
	assert_eq(supply_units.size(), 0, "Should have 0 supply units")


# =============================================================================
# 補給処理テスト
# =============================================================================

func test_resupply_nearby_unit() -> void:
	## 近くのユニットに弾薬を補給できる
	var resupply := ResupplySystemClass.new()

	# 補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	# 弾薬が減った戦車（補給トラックの近く）
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)  # 50m離れている
	)
	tank.is_moving = false

	# 弾薬を減らす
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	var original_stowed: int = slot.count_stowed
	slot.count_stowed = max(0, slot.count_stowed - 5)  # 5発減らす

	# 補給処理
	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給が行われたか確認
	assert_true(events.size() > 0, "Should have resupply events")
	assert_true(slot.count_stowed > original_stowed - 5, "Stowed ammo should increase")


func test_no_resupply_when_out_of_range() -> void:
	## 範囲外のユニットには補給しない
	var resupply := ResupplySystemClass.new()

	# 補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	# 遠い位置の戦車（200m離れている、補給範囲100mを超える）
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(200, 0)
	)
	tank.is_moving = false

	# 弾薬を減らす
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	var original_stowed: int = slot.count_stowed
	slot.count_stowed = max(0, slot.count_stowed - 5)

	# 補給処理
	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給されていないことを確認
	assert_eq(events.size(), 0, "Should have no resupply events")
	assert_eq(slot.count_stowed, original_stowed - 5, "Stowed ammo should not change")


func test_no_resupply_to_enemy() -> void:
	## 敵ユニットには補給しない
	var resupply := ResupplySystemClass.new()

	# 青軍の補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	# 赤軍の戦車（近くにいる）
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.RED, Vector2(50, 0)
	)
	tank.is_moving = false

	# 弾薬を減らす
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	var original_stowed: int = slot.count_stowed
	slot.count_stowed = max(0, slot.count_stowed - 5)

	# 補給処理
	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給されていないことを確認
	assert_eq(events.size(), 0, "Should have no resupply events (enemy)")
	assert_eq(slot.count_stowed, original_stowed - 5, "Stowed ammo should not change")


func test_no_resupply_when_truck_moving() -> void:
	## 補給トラックが移動中は補給しない
	var resupply := ResupplySystemClass.new()

	# 移動中の補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = true  # 移動中
	resupply.register_supply_unit(truck, truck.supply_config)

	# 近くの戦車
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false

	# 弾薬を減らす
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	var original_stowed: int = slot.count_stowed
	slot.count_stowed = max(0, slot.count_stowed - 5)

	# 補給処理
	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給されていないことを確認
	assert_eq(events.size(), 0, "Should have no resupply events (truck moving)")


func test_supply_capacity_decreases() -> void:
	## 補給すると補給容量が減る
	var resupply := ResupplySystemClass.new()

	# 補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	var initial_capacity: int = resupply.get_supply_unit_info(truck.id).get("remaining_capacity")

	# 弾薬が減った戦車
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false

	# 弾薬を大幅に減らす
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	slot.count_stowed = 0

	# 補給処理
	resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給容量が減っていることを確認
	var remaining_capacity: int = resupply.get_supply_unit_info(truck.id).get("remaining_capacity")
	assert_true(remaining_capacity < initial_capacity, "Remaining capacity should decrease")
