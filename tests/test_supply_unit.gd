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
	# 74式特大型トラック: capacity=150, unit_count=2 → total=300
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type74_ExtraLargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	resupply.register_supply_unit(truck, truck.supply_config)

	var info := resupply.get_supply_unit_info(truck.id)
	assert_eq(info.get("capacity"), 300, "Capacity should be 150 * 2 = 300")
	assert_eq(info.get("remaining_capacity"), 300, "Remaining capacity should be 300")
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


# =============================================================================
# 補給容量・消費テスト
# =============================================================================

func test_supply_remaining_initialized_with_unit_count() -> void:
	## supply_remainingはunit_count × capacityで初期化される
	# 73式大型トラック: capacity=100, unit_count=4 → supply_remaining=400
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_eq(truck.supply_remaining, 400, "supply_remaining should be 100 * 4 = 400")


func test_supply_remaining_for_medium_truck() -> void:
	## 73式中型トラックのsupply_remaining: 60 * 4 = 240
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_eq(truck.supply_remaining, 240, "supply_remaining should be 60 * 4 = 240")


func test_supply_remaining_for_extra_large_truck() -> void:
	## 74式特大型トラックのsupply_remaining: 150 * 2 = 300
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type74_ExtraLargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_eq(truck.supply_remaining, 300, "supply_remaining should be 150 * 2 = 300")


func test_supply_remaining_decreases_after_resupply() -> void:
	## 補給実行後にsupply_remainingが減少する
	var resupply := ResupplySystemClass.new()

	# 補給トラック
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	var initial_remaining: int = truck.supply_remaining  # 400

	# 弾薬が減った戦車
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false

	# 弾薬を減らす（予備弾を0に）
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	slot.count_stowed = 0

	# 補給処理
	resupply.process_supply_unit_resupply([truck, tank], 100)

	# ElementInstance.supply_remainingも減少していることを確認
	assert_true(truck.supply_remaining < initial_remaining,
		"supply_remaining should decrease: %d -> %d" % [initial_remaining, truck.supply_remaining])


func test_supply_remaining_synced_with_resupply_system() -> void:
	## supply_remainingとResupplySystemのremaining_capacityが同期している
	var resupply := ResupplySystemClass.new()

	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	# 戦車を複数tick補給
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false
	tank.ammo_state.main_gun.get_current_slot().count_stowed = 0

	for i in range(5):
		resupply.process_supply_unit_resupply([truck, tank], 100 + i)

	# 両者が同期していることを確認
	var info := resupply.get_supply_unit_info(truck.id)
	assert_eq(truck.supply_remaining, info.get("remaining_capacity"),
		"supply_remaining and remaining_capacity should be synced")


func test_no_resupply_when_supply_exhausted() -> void:
	## 補給容量が0になると補給できない
	var resupply := ResupplySystemClass.new()

	# 補給トラックを作成
	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_MediumTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	# 登録後に補給容量を0に設定（使い果たした状態をシミュレート）
	truck.supply_remaining = 0

	# 弾薬が減った戦車
	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false
	var slot: AmmoStateClass.AmmoSlot = tank.ammo_state.main_gun.get_current_slot()
	slot.count_stowed = 0

	# 補給処理
	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	# 補給されていないことを確認
	assert_eq(events.size(), 0, "Should have no resupply events when exhausted")
	assert_eq(slot.count_stowed, 0, "Stowed ammo should remain 0")


func test_usa_supply_trucks_capacity() -> void:
	## 米軍補給トラックのsupply_remainingが正しく設定される
	# FMTV: capacity=80, unit_count=4 → 320
	var fmtv := ElementFactoryClass.create_element_with_vehicle(
		"USA_FMTV_M1083A1P2", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	assert_eq(fmtv.supply_remaining, 320, "FMTV supply_remaining should be 80 * 4 = 320")

	# HEMTT LHS: capacity=120, unit_count=3 → 360
	var hemtt := ElementFactoryClass.create_element_with_vehicle(
		"USA_HEMTT_A4_LHS", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	assert_eq(hemtt.supply_remaining, 360, "HEMTT supply_remaining should be 120 * 3 = 360")

	# PLS: capacity=200, unit_count=2 → 400
	var pls := ElementFactoryClass.create_element_with_vehicle(
		"USA_M1120A4_PLS", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	assert_eq(pls.supply_remaining, 400, "PLS supply_remaining should be 200 * 2 = 400")


func test_resupply_event_includes_remaining_capacity() -> void:
	## 補給イベントにremaining_capacityが含まれる
	var resupply := ResupplySystemClass.new()

	var truck := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type73_LargeTruck", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	truck.is_moving = false
	resupply.register_supply_unit(truck, truck.supply_config)

	var tank := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2(50, 0)
	)
	tank.is_moving = false
	tank.ammo_state.main_gun.get_current_slot().count_stowed = 0

	var events := resupply.process_supply_unit_resupply([truck, tank], 100)

	assert_true(events.size() > 0, "Should have resupply events")
	var event: Dictionary = events[0]
	assert_true(event.has("remaining_capacity"), "Event should include remaining_capacity")
	assert_true(event.get("remaining_capacity") < 400, "remaining_capacity should be less than initial")
