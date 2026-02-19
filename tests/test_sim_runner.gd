extends Node

## SimRunnerのユニットテスト
## 実行方法: このシーンを直接実行するか、テストランナーから呼び出す

var _sim_runner: SimRunner
var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("=== SimRunner Tests ===")
	_run_all_tests()
	_print_summary()


func _run_all_tests() -> void:
	# 各テストの前にSimRunnerを再作成
	_test_initial_state()
	_test_start_sets_seed()
	_test_pause_unpause()
	_test_toggle_pause()
	_test_speed_up_down()
	_test_tick_advances_on_process()
	_test_step_one_tick()
	_test_alpha_calculation()
	_test_max_steps_per_frame()
	_test_rand_determinism()
	_test_time_conversion()


func _setup() -> void:
	if _sim_runner:
		_sim_runner.queue_free()
	_sim_runner = SimRunner.new()
	add_child(_sim_runner)


func _teardown() -> void:
	if _sim_runner:
		_sim_runner.queue_free()
		_sim_runner = null

# =============================================================================
# テストケース
# =============================================================================

func _test_initial_state() -> void:
	_setup()
	var name := "initial_state"

	_assert_eq(_sim_runner.tick_index, 0, name + ": tick_index should be 0")
	_assert_eq(_sim_runner.sim_speed, 1.0, name + ": sim_speed should be 1.0")
	_assert_eq(_sim_runner.alpha, 0.0, name + ": alpha should be 0.0")
	_assert_eq(_sim_runner.is_paused(), false, name + ": should not be paused")

	_teardown()


func _test_start_sets_seed() -> void:
	_setup()
	var name := "start_sets_seed"

	_sim_runner.start(12345)
	_assert_eq(_sim_runner.match_seed, 12345, name + ": seed should be 12345")
	_assert_eq(_sim_runner.tick_index, 0, name + ": tick should reset to 0")

	_teardown()


func _test_pause_unpause() -> void:
	_setup()
	var name := "pause_unpause"

	_sim_runner.pause()
	_assert_eq(_sim_runner.is_paused(), true, name + ": should be paused")
	_assert_eq(_sim_runner.sim_speed, 0.0, name + ": speed should be 0")

	_sim_runner.unpause()
	_assert_eq(_sim_runner.is_paused(), false, name + ": should not be paused")
	_assert_eq(_sim_runner.sim_speed, 1.0, name + ": speed should be 1.0")

	_teardown()


func _test_toggle_pause() -> void:
	_setup()
	var name := "toggle_pause"

	_sim_runner.toggle_pause()
	_assert_eq(_sim_runner.is_paused(), true, name + ": first toggle should pause")

	_sim_runner.toggle_pause()
	_assert_eq(_sim_runner.is_paused(), false, name + ": second toggle should unpause")

	_teardown()


func _test_speed_up_down() -> void:
	_setup()
	var name := "speed_up_down"

	# 初期: 1.0
	_sim_runner.speed_up()
	_assert_eq(_sim_runner.sim_speed, 2.0, name + ": speed_up to 2.0")

	_sim_runner.speed_up()
	_assert_eq(_sim_runner.sim_speed, 4.0, name + ": speed_up to 4.0")

	_sim_runner.speed_up()
	_assert_eq(_sim_runner.sim_speed, 4.0, name + ": should stay at max 4.0")

	_sim_runner.speed_down()
	_assert_eq(_sim_runner.sim_speed, 2.0, name + ": speed_down to 2.0")

	_sim_runner.speed_down()
	_assert_eq(_sim_runner.sim_speed, 1.0, name + ": speed_down to 1.0")

	_sim_runner.speed_down()
	_assert_eq(_sim_runner.sim_speed, 0.0, name + ": speed_down to 0.0 (pause)")

	_teardown()


func _test_tick_advances_on_process() -> void:
	_setup()
	var name := "tick_advances"

	_sim_runner.start()

	# 0.1秒 (SIM_DT) 経過をシミュレート
	_sim_runner._advance_simulation(0.1)
	_assert_eq(_sim_runner.tick_index, 1, name + ": should advance 1 tick")

	# 0.25秒経過 (2 tick + 余り)
	_sim_runner._advance_simulation(0.25)
	_assert_eq(_sim_runner.tick_index, 3, name + ": should advance to 3 ticks")

	_teardown()


func _test_step_one_tick() -> void:
	_setup()
	var name := "step_one_tick"

	_sim_runner.start()
	_sim_runner.pause()

	var initial_tick := _sim_runner.tick_index
	_sim_runner.step_one_tick()
	_assert_eq(_sim_runner.tick_index, initial_tick + 1, name + ": should advance 1 tick when paused")

	# Pause中でないときは進まない
	_sim_runner.unpause()
	var current_tick := _sim_runner.tick_index
	_sim_runner.step_one_tick()
	_assert_eq(_sim_runner.tick_index, current_tick, name + ": should not advance when not paused")

	_teardown()


func _test_alpha_calculation() -> void:
	_setup()
	var name := "alpha_calculation"

	_sim_runner.start()

	# 0.05秒経過 (半tick)
	_sim_runner._advance_simulation(0.05)
	_assert_approx(_sim_runner.alpha, 0.5, 0.01, name + ": alpha should be ~0.5")

	# さらに0.03秒経過 (合計0.08秒)
	_sim_runner._advance_simulation(0.03)
	_assert_approx(_sim_runner.alpha, 0.8, 0.01, name + ": alpha should be ~0.8")

	_teardown()


func _test_max_steps_per_frame() -> void:
	_setup()
	var name := "max_steps_per_frame"

	_sim_runner.start()

	# 大量の時間経過 (MAX_STEPS_PER_FRAME=8 を超える)
	_sim_runner._advance_simulation(2.0)  # 20 ticks分
	_assert_eq(_sim_runner.tick_index, 8, name + ": should be capped at MAX_STEPS_PER_FRAME")

	_teardown()


func _test_rand_determinism() -> void:
	_setup()
	var name := "rand_determinism"

	# 同じシードで2回実行して結果を比較
	_sim_runner.start(99999)
	var values1: Array[float] = []
	for i in range(5):
		values1.append(_sim_runner.rand())

	_sim_runner.reset()
	_sim_runner.start(99999)
	var values2: Array[float] = []
	for i in range(5):
		values2.append(_sim_runner.rand())

	var all_same := true
	for i in range(5):
		if values1[i] != values2[i]:
			all_same = false
			break

	_assert_eq(all_same, true, name + ": same seed should produce same random sequence")

	_teardown()


func _test_time_conversion() -> void:
	_setup()
	var name := "time_conversion"

	_assert_eq(_sim_runner.ticks_to_seconds(10), 1.0, name + ": 10 ticks = 1.0 sec")
	_assert_eq(_sim_runner.ticks_to_seconds(25), 2.5, name + ": 25 ticks = 2.5 sec")

	_assert_eq(_sim_runner.seconds_to_ticks(1.0), 10, name + ": 1.0 sec = 10 ticks")
	_assert_eq(_sim_runner.seconds_to_ticks(1.5), 15, name + ": 1.5 sec = 15 ticks")
	_assert_eq(_sim_runner.seconds_to_ticks(0.15), 2, name + ": 0.15 sec = 2 ticks (ceiling)")

	_teardown()

# =============================================================================
# アサーション
# =============================================================================

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) <= tolerance:
		_passed += 1
		_test_results.append("[PASS] " + message)
	else:
		_failed += 1
		_test_results.append("[FAIL] " + message + " (got: " + str(actual) + ", expected: " + str(expected) + ")")


func _print_summary() -> void:
	print("")
	for result in _test_results:
		print(result)
	print("")
	print("=== Summary: " + str(_passed) + " passed, " + str(_failed) + " failed ===")

	if _failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
