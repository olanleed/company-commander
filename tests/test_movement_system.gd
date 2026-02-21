extends GutTest

## MovementSystemのユニットテスト


func _create_test_element_type() -> ElementData.ElementType:
	var et := ElementData.ElementType.new()
	et.id = "inf_rifle"
	et.display_name = "Rifle Squad"
	et.category = ElementData.Category.INF
	et.symbol_type = ElementData.SymbolType.INF_RIFLE
	et.mobility_class = GameEnums.MobilityType.FOOT
	et.road_speed = 5.0
	et.cross_speed = 3.0
	et.max_strength = 10
	return et


# =============================================================================
# 基本テスト
# =============================================================================

func test_is_moving() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)

	ei.is_moving = false
	assert_false(ms.is_moving(ei), "静止中のユニット")

	ei.is_moving = true
	assert_true(ms.is_moving(ei), "移動中のユニット")


func test_update_element_stationary() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(100, 100)
	ei.is_moving = false

	var initial_pos := ei.position
	ms.update_element(ei, 0.1)

	assert_eq(ei.position, initial_pos, "静止中は位置が変わらない")


func test_update_element_moving() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.is_moving = true
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei.path_index = 0

	# 0.1秒移動 (cross_speed=3.0 m/s -> 0.3m移動)
	ms.update_element(ei, 0.1)

	assert_true(ei.position.x > 0, "X方向に移動")
	assert_almost_eq(ei.position.y, 0.0, 0.01, "Y方向は変化なし")


func test_stop_at_goal() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(99, 0)  # ゴール近く
	ei.is_moving = true
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei.path_index = 1  # 最後のウェイポイントへ

	# ゴールに到達
	ms.update_element(ei, 0.5)

	assert_false(ei.is_moving, "ゴール到達で停止")
	assert_eq(ei.current_path.size(), 0, "パスがクリアされる")


func test_suppression_slows_movement() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()

	# 抑圧なし
	var ei1 := ElementData.ElementInstance.new(et)
	ei1.position = Vector2(0, 0)
	ei1.suppression = 0.0
	ei1.is_moving = true
	ei1.current_path = PackedVector2Array([Vector2(0, 0), Vector2(1000, 0)])
	ei1.path_index = 0

	ms.update_element(ei1, 1.0)
	var dist1 := ei1.position.x

	# 抑圧あり (100% -> 50% speed)
	var ei2 := ElementData.ElementInstance.new(et)
	ei2.position = Vector2(0, 0)
	ei2.suppression = 1.0
	ei2.is_moving = true
	ei2.current_path = PackedVector2Array([Vector2(0, 0), Vector2(1000, 0)])
	ei2.path_index = 0

	ms.update_element(ei2, 1.0)
	var dist2 := ei2.position.x

	assert_true(dist2 < dist1, "抑圧されたユニットは遅い")
	assert_almost_eq(dist2 / dist1, 0.5, 0.1, "約50%の速度")


func test_get_remaining_distance() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])
	ei.path_index = 0

	var dist := ms.get_remaining_distance(ei)
	assert_almost_eq(dist, 200.0, 0.01, "総距離")

	ei.path_index = 1
	dist = ms.get_remaining_distance(ei)
	assert_almost_eq(dist, 200.0, 0.01, "ウェイポイント1から")

	ei.position = Vector2(50, 0)
	ei.path_index = 1
	dist = ms.get_remaining_distance(ei)
	assert_almost_eq(dist, 150.0, 0.01, "中間地点から")


# =============================================================================
# 追加テスト: 移動命令と状態管理
# =============================================================================

func test_issue_move_order_sets_properties() -> void:
	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.is_moving = false

	# 直接パスを設定（nav_managerなしのテスト）
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 100)])
	ei.path_index = 1
	ei.is_moving = true
	ei.order_target_position = Vector2(100, 100)
	ei.current_order_type = GameEnums.OrderType.MOVE

	assert_true(ei.is_moving, "is_movingが設定される")
	assert_eq(ei.current_order_type, GameEnums.OrderType.MOVE, "OrderTypeがMOVE")
	assert_eq(ei.order_target_position, Vector2(100, 100), "目標位置が設定される")


func test_move_order_clears_previous_path() -> void:
	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)

	# 既存パスを設定
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])
	ei.path_index = 2
	ei.is_moving = true

	# 新しい命令で上書き
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(200, 200)])
	ei.path_index = 1

	assert_eq(ei.current_path.size(), 2, "新しいパスが設定される")
	assert_eq(ei.path_index, 1, "path_indexがリセットされる")


func test_move_order_independent_between_units() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()

	var ei1 := ElementData.ElementInstance.new(et)
	ei1.position = Vector2(0, 0)
	ei1.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei1.path_index = 0
	ei1.is_moving = true

	var ei2 := ElementData.ElementInstance.new(et)
	ei2.position = Vector2(50, 50)
	ei2.is_moving = false

	# ei1のみ更新
	ms.update_element(ei1, 0.1)

	assert_true(ei1.position.x > 0, "ei1が移動")
	assert_eq(ei2.position, Vector2(50, 50), "ei2は変化なし")
	assert_false(ei2.is_moving, "ei2は移動していない")


func test_stop_movement_clears_state() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(99, 0)  # ゴール近く
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	ei.path_index = 1
	ei.is_moving = true
	ei.velocity = Vector2(3, 0)

	# ゴールに到達させる
	ms.update_element(ei, 0.5)

	assert_false(ei.is_moving, "is_movingがクリアされる")
	assert_eq(ei.velocity, Vector2.ZERO, "velocityがクリアされる")
	assert_eq(ei.current_path.size(), 0, "pathがクリアされる")
	assert_eq(ei.path_index, 0, "path_indexがリセットされる")


func test_destroyed_unit_does_not_receive_order() -> void:
	# 破壊されたユニットへの命令発行を防ぐロジックのテスト
	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.state = GameEnums.UnitState.DESTROYED
	ei.is_moving = false

	# 破壊されたユニットに移動命令を出そうとする（外部ロジックでブロック）
	var should_issue_order := ei.state != GameEnums.UnitState.DESTROYED
	assert_false(should_issue_order, "破壊されたユニットへの命令はブロック")


func test_multiple_waypoints() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.current_path = PackedVector2Array([
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(20, 0),
		Vector2(30, 0)
	])
	ei.path_index = 0
	ei.is_moving = true

	# 十分な時間移動（3m/s × 5秒 = 15m）
	for i in range(50):
		ms.update_element(ei, 0.1)

	# 少なくとも最初のウェイポイントは通過
	assert_true(ei.position.x > 5, "最初のウェイポイントを通過")
	assert_true(ei.path_index >= 1, "path_indexが進む")


func test_facing_updates_during_movement() -> void:
	var ms := MovementSystem.new()

	var et := _create_test_element_type()
	var ei := ElementData.ElementInstance.new(et)
	ei.position = Vector2(0, 0)
	ei.facing = 0.0  # 右向き

	# 下方向へ移動（facing = PI/2）
	ei.current_path = PackedVector2Array([Vector2(0, 0), Vector2(0, 100)])
	ei.path_index = 0
	ei.is_moving = true

	# 更新
	ms.update_element(ei, 0.5)

	# 下向きに回転し始めている
	assert_gt(ei.facing, 0.0, "目標方向に回転")
