extends "res://tests/test_base.gd"

## PositionComponent テスト
## コンポーネント分離フェーズ1: 位置・向き・速度の管理

# =============================================================================
# テスト対象
# =============================================================================

const PositionComponent = preload("res://scripts/components/position_component.gd")

# =============================================================================
# 基本機能テスト
# =============================================================================

func test_position_initial_values():
	var comp = PositionComponent.new()

	assert_eq(comp.position, Vector2.ZERO, "Initial position should be ZERO")
	assert_eq(comp.facing, 0.0, "Initial facing should be 0.0")
	assert_eq(comp.velocity, Vector2.ZERO, "Initial velocity should be ZERO")
	_pass("position_initial_values")


func test_position_change_emits_signal():
	var comp = PositionComponent.new()
	var signal_received = false
	var old_pos: Vector2
	var new_pos: Vector2

	comp.position_changed.connect(func(old, new):
		signal_received = true
		old_pos = old
		new_pos = new
	)

	comp.position = Vector2(100, 200)

	assert_true(signal_received, "Signal should be emitted")
	assert_eq(old_pos, Vector2.ZERO, "Old position should be ZERO")
	assert_eq(new_pos, Vector2(100, 200), "New position should be (100, 200)")
	_pass("position_change_emits_signal")


func test_same_position_does_not_emit_signal():
	var comp = PositionComponent.new()
	comp.position = Vector2(50, 50)

	var signal_count = 0
	comp.position_changed.connect(func(_old, _new): signal_count += 1)

	comp.position = Vector2(50, 50)  # 同じ値

	assert_eq(signal_count, 0, "Signal should not be emitted for same value")
	_pass("same_position_does_not_emit_signal")


func test_facing_change_emits_signal():
	var comp = PositionComponent.new()
	var signal_received = false

	comp.facing_changed.connect(func(_old, _new):
		signal_received = true
	)

	comp.facing = PI / 2

	assert_true(signal_received, "Facing signal should be emitted")
	assert_almost_eq(comp.facing, PI / 2, 0.001, "Facing should be PI/2")
	_pass("facing_change_emits_signal")


func test_same_facing_does_not_emit_signal():
	var comp = PositionComponent.new()
	comp.facing = 1.0

	var signal_count = 0
	comp.facing_changed.connect(func(_old, _new): signal_count += 1)

	comp.facing = 1.0  # 同じ値

	assert_eq(signal_count, 0, "Signal should not be emitted for same facing")
	_pass("same_facing_does_not_emit_signal")


func test_velocity_change_emits_signal():
	var comp = PositionComponent.new()
	var signal_received = false

	comp.velocity_changed.connect(func(_old, _new):
		signal_received = true
	)

	comp.velocity = Vector2(10, 0)

	assert_true(signal_received, "Velocity signal should be emitted")
	assert_eq(comp.velocity, Vector2(10, 0), "Velocity should be (10, 0)")
	_pass("velocity_change_emits_signal")


# =============================================================================
# 前状態保存・補間テスト
# =============================================================================

func test_save_prev_state():
	var comp = PositionComponent.new()
	comp.position = Vector2(100, 100)
	comp.facing = PI

	comp.save_prev_state()

	# prev_position と prev_facing が保存されている
	comp.position = Vector2(200, 200)
	comp.facing = 0.0

	# 補間で確認
	var mid_pos = comp.get_interpolated_position(0.0)
	assert_eq(mid_pos, Vector2(100, 100), "Alpha 0 should return prev_position")
	_pass("save_prev_state")


func test_interpolation_position():
	var comp = PositionComponent.new()
	comp.position = Vector2(0, 0)
	comp.save_prev_state()
	comp.position = Vector2(100, 100)

	var mid = comp.get_interpolated_position(0.5)

	assert_eq(mid, Vector2(50, 50), "Midpoint should be (50, 50)")
	_pass("interpolation_position")


func test_interpolation_position_alpha_0():
	var comp = PositionComponent.new()
	comp.position = Vector2(0, 0)
	comp.save_prev_state()
	comp.position = Vector2(100, 100)

	var start = comp.get_interpolated_position(0.0)

	assert_eq(start, Vector2(0, 0), "Alpha 0 should return prev_position")
	_pass("interpolation_position_alpha_0")


func test_interpolation_position_alpha_1():
	var comp = PositionComponent.new()
	comp.position = Vector2(0, 0)
	comp.save_prev_state()
	comp.position = Vector2(100, 100)

	var end = comp.get_interpolated_position(1.0)

	assert_eq(end, Vector2(100, 100), "Alpha 1 should return current position")
	_pass("interpolation_position_alpha_1")


func test_interpolation_facing():
	var comp = PositionComponent.new()
	comp.facing = 0.0
	comp.save_prev_state()
	comp.facing = PI

	var mid = comp.get_interpolated_facing(0.5)

	assert_almost_eq(mid, PI / 2, 0.001, "Midpoint facing should be PI/2")
	_pass("interpolation_facing")


func test_interpolation_facing_wrapping():
	var comp = PositionComponent.new()
	# 角度ラップテスト: -PI から PI への補間
	comp.facing = -PI + 0.1
	comp.save_prev_state()
	comp.facing = PI - 0.1

	# lerp_angle は短い方向を選ぶので、0付近を通らず-PI/PI境界を通る
	var mid = comp.get_interpolated_facing(0.5)

	# 中間点は PI か -PI に近いはず
	assert_true(absf(mid) > 2.5, "Midpoint should be near PI/-PI boundary")
	_pass("interpolation_facing_wrapping")


# =============================================================================
# 位置更新メソッドテスト
# =============================================================================

func test_move_by():
	var comp = PositionComponent.new()
	comp.position = Vector2(100, 100)

	comp.move_by(Vector2(50, -25))

	assert_eq(comp.position, Vector2(150, 75), "Position should be updated by delta")
	_pass("move_by")


func test_set_position_and_facing():
	var comp = PositionComponent.new()

	comp.set_position_and_facing(Vector2(300, 400), PI / 4)

	assert_eq(comp.position, Vector2(300, 400), "Position should be set")
	assert_almost_eq(comp.facing, PI / 4, 0.001, "Facing should be set")
	_pass("set_position_and_facing")


# =============================================================================
# テスト実行
# =============================================================================

func get_test_methods() -> Array:
	return [
		"test_position_initial_values",
		"test_position_change_emits_signal",
		"test_same_position_does_not_emit_signal",
		"test_facing_change_emits_signal",
		"test_same_facing_does_not_emit_signal",
		"test_velocity_change_emits_signal",
		"test_save_prev_state",
		"test_interpolation_position",
		"test_interpolation_position_alpha_0",
		"test_interpolation_position_alpha_1",
		"test_interpolation_facing",
		"test_interpolation_facing_wrapping",
		"test_move_by",
		"test_set_position_and_facing",
	]
