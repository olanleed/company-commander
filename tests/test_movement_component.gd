extends "res://tests/test_base.gd"

## MovementComponent テスト
## コンポーネント分離フェーズ1: 移動パス・状態・命令の管理

# =============================================================================
# テスト対象
# =============================================================================

const MovementComponent = preload("res://scripts/components/movement_component.gd")

# =============================================================================
# 基本機能テスト
# =============================================================================

func test_initial_values():
	var comp = MovementComponent.new("test_unit")

	assert_false(comp.is_moving, "Should not be moving initially")
	assert_eq(comp.current_path.size(), 0, "Path should be empty")
	assert_eq(comp.current_order_type, GameEnums.OrderType.HOLD, "Initial order should be HOLD")
	assert_false(comp.is_reversing, "Should not be reversing")
	assert_false(comp.use_road_only, "Should not be road only")
	_pass("initial_values")


# =============================================================================
# 移動開始・停止テスト
# =============================================================================

func test_start_movement():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200), Vector2(300, 300)])
	var signal_received = false
	var dest: Vector2

	comp.movement_started.connect(func(id, destination):
		signal_received = true
		dest = destination
	)

	comp.start_movement(path)

	assert_true(comp.is_moving, "Should be moving")
	assert_eq(comp.current_path.size(), 3, "Path should have 3 waypoints")
	assert_true(signal_received, "Signal should be emitted")
	assert_eq(dest, Vector2(300, 300), "Destination should be last waypoint")
	_pass("start_movement")


func test_start_movement_with_road_flag():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100)])

	comp.start_movement(path, true)

	assert_true(comp.use_road_only, "use_road_only should be true")
	_pass("start_movement_with_road_flag")


func test_stop_movement():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200)])
	comp.start_movement(path)

	var signal_received = false
	comp.movement_completed.connect(func(_id): signal_received = true)

	comp.stop_movement()

	assert_false(comp.is_moving, "Should not be moving")
	assert_eq(comp.current_path.size(), 0, "Path should be cleared")
	assert_true(signal_received, "Completed signal should be emitted")
	_pass("stop_movement")


func test_stop_movement_when_not_moving():
	var comp = MovementComponent.new("test_unit")
	var signal_count = 0
	comp.movement_completed.connect(func(_id): signal_count += 1)

	comp.stop_movement()

	assert_eq(signal_count, 0, "No signal when not moving")
	_pass("stop_movement_when_not_moving")


# =============================================================================
# ウェイポイント進行テスト
# =============================================================================

func test_get_next_waypoint():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200)])
	comp.start_movement(path)

	var next = comp.get_next_waypoint()

	assert_eq(next, Vector2(100, 100), "First waypoint should be (100, 100)")
	_pass("get_next_waypoint")


func test_get_next_waypoint_empty_path():
	var comp = MovementComponent.new("test_unit")

	var next = comp.get_next_waypoint()

	assert_eq(next, Vector2.ZERO, "Should return ZERO for empty path")
	_pass("get_next_waypoint_empty_path")


func test_advance_waypoint():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200), Vector2(300, 300)])
	comp.start_movement(path)

	assert_eq(comp.get_next_waypoint(), Vector2(100, 100), "First waypoint")

	var has_more = comp.advance_waypoint()

	assert_true(has_more, "Should have more waypoints")
	assert_eq(comp.get_next_waypoint(), Vector2(200, 200), "Second waypoint")
	_pass("advance_waypoint")


func test_advance_waypoint_to_end():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200)])
	comp.start_movement(path)

	comp.advance_waypoint()  # -> index 1
	var has_more = comp.advance_waypoint()  # -> index 2 (out of range)

	assert_false(has_more, "Should not have more waypoints")
	_pass("advance_waypoint_to_end")


# =============================================================================
# 命令設定テスト
# =============================================================================

func test_set_order_move():
	var comp = MovementComponent.new("test_unit")
	var signal_received = false
	var received_order: GameEnums.OrderType

	comp.order_changed.connect(func(id, order_type):
		signal_received = true
		received_order = order_type
	)

	comp.set_order(GameEnums.OrderType.MOVE, Vector2(500, 500))

	assert_eq(comp.current_order_type, GameEnums.OrderType.MOVE, "Order should be MOVE")
	assert_eq(comp.order_target_position, Vector2(500, 500), "Target position should be set")
	assert_true(signal_received, "Signal should be emitted")
	assert_eq(received_order, GameEnums.OrderType.MOVE, "Signal order should match")
	_pass("set_order_move")


func test_set_order_attack():
	var comp = MovementComponent.new("test_unit")

	comp.set_order(GameEnums.OrderType.ATTACK, Vector2(600, 600), "enemy_1")

	assert_eq(comp.current_order_type, GameEnums.OrderType.ATTACK, "Order should be ATTACK")
	assert_eq(comp.order_target_position, Vector2(600, 600), "Target position should be set")
	assert_eq(comp.order_target_id, "enemy_1", "Target ID should be set")
	_pass("set_order_attack")


func test_set_order_hold():
	var comp = MovementComponent.new("test_unit")
	comp.set_order(GameEnums.OrderType.MOVE, Vector2(100, 100))

	comp.set_order(GameEnums.OrderType.HOLD)

	assert_eq(comp.current_order_type, GameEnums.OrderType.HOLD, "Order should be HOLD")
	_pass("set_order_hold")


# =============================================================================
# 後退・離脱フラグテスト
# =============================================================================

func test_set_reversing():
	var comp = MovementComponent.new("test_unit")

	comp.set_reversing(true)

	assert_true(comp.is_reversing, "Should be reversing")

	comp.set_reversing(false)

	assert_false(comp.is_reversing, "Should not be reversing")
	_pass("set_reversing")


func test_clear_reversing_on_stop():
	var comp = MovementComponent.new("test_unit")
	var path = PackedVector2Array([Vector2(100, 100)])
	comp.start_movement(path)
	comp.set_reversing(true)

	comp.stop_movement()

	assert_false(comp.is_reversing, "Reversing should be cleared on stop")
	_pass("clear_reversing_on_stop")


func test_break_contact_smoke_flag():
	var comp = MovementComponent.new("test_unit")

	assert_false(comp.break_contact_smoke_requested, "Initially false")

	comp.request_break_contact_smoke()

	assert_true(comp.break_contact_smoke_requested, "Should be true after request")

	comp.clear_break_contact_smoke()

	assert_false(comp.break_contact_smoke_requested, "Should be cleared")
	_pass("break_contact_smoke_flag")


# =============================================================================
# 待機命令テスト
# =============================================================================

func test_set_pending_move_order():
	var comp = MovementComponent.new("test_unit")
	var pending = {
		"target": Vector2(400, 400),
		"use_route": true,
		"is_reverse": false,
		"is_break_contact": false
	}

	comp.set_pending_move_order(pending)

	assert_true(comp.has_pending_order(), "Should have pending order")
	_pass("set_pending_move_order")


func test_get_and_clear_pending_order():
	var comp = MovementComponent.new("test_unit")
	var pending = {
		"target": Vector2(400, 400),
		"use_route": true
	}
	comp.set_pending_move_order(pending)

	var retrieved = comp.get_and_clear_pending_order()

	assert_eq(retrieved.target, Vector2(400, 400), "Target should match")
	assert_false(comp.has_pending_order(), "Pending order should be cleared")
	_pass("get_and_clear_pending_order")


func test_no_pending_order():
	var comp = MovementComponent.new("test_unit")

	assert_false(comp.has_pending_order(), "No pending order initially")

	var retrieved = comp.get_and_clear_pending_order()

	assert_true(retrieved.is_empty(), "Should return empty dict")
	_pass("no_pending_order")


# =============================================================================
# パス変更シグナルテスト
# =============================================================================

func test_path_changed_signal():
	var comp = MovementComponent.new("test_unit")
	var signal_received = false
	var received_path: PackedVector2Array

	comp.path_changed.connect(func(id, new_path):
		signal_received = true
		received_path = new_path
	)

	var path = PackedVector2Array([Vector2(100, 100), Vector2(200, 200)])
	comp.start_movement(path)

	assert_true(signal_received, "Path changed signal should be emitted")
	assert_eq(received_path.size(), 2, "Path should have 2 waypoints")
	_pass("path_changed_signal")


# =============================================================================
# テスト実行
# =============================================================================

func get_test_methods() -> Array:
	return [
		"test_initial_values",
		"test_start_movement",
		"test_start_movement_with_road_flag",
		"test_stop_movement",
		"test_stop_movement_when_not_moving",
		"test_get_next_waypoint",
		"test_get_next_waypoint_empty_path",
		"test_advance_waypoint",
		"test_advance_waypoint_to_end",
		"test_set_order_move",
		"test_set_order_attack",
		"test_set_order_hold",
		"test_set_reversing",
		"test_clear_reversing_on_stop",
		"test_break_contact_smoke_flag",
		"test_set_pending_move_order",
		"test_get_and_clear_pending_order",
		"test_no_pending_order",
		"test_path_changed_signal",
	]
