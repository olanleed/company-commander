extends GutTest

## MissileSystemのユニットテスト
## - ミサイル発射
## - 飛翔管理
## - 着弾処理
## - 射手拘束

const MissileDataScript := preload("res://scripts/data/missile_data.gd")
const MissileSystemScript := preload("res://scripts/systems/missile_system.gd")

var missile_system: MissileSystemScript


func before_all() -> void:
	# JSONロード状態をリセット
	MissileDataScript._reset_for_testing()


func before_each() -> void:
	missile_system = MissileSystemScript.new()


func after_each() -> void:
	missile_system.reset()


func after_all() -> void:
	MissileDataScript._reset_for_testing()


# =============================================================================
# ミサイル発射
# =============================================================================

func test_launch_missile_basic() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)  # 1km

	var missile_id: String = missile_system.launch_missile(
		"shooter_001",
		shooter_pos,
		"target_001",
		target_pos,
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0  # tick
	)

	assert_ne(missile_id, "", "Should return missile ID")
	assert_eq(missile_system.get_in_flight_count(), 1)


func test_launch_missile_out_of_range_min() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(30, 0)  # 30m < min 65m

	var missile_id: String = missile_system.launch_missile(
		"shooter_001",
		shooter_pos,
		"target_001",
		target_pos,
		javelin,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_eq(missile_id, "", "Should fail for target too close")
	assert_eq(missile_system.get_in_flight_count(), 0)


func test_launch_missile_out_of_range_max() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(5000, 0)  # 5km > max 2500m

	var missile_id: String = missile_system.launch_missile(
		"shooter_001",
		shooter_pos,
		"target_001",
		target_pos,
		javelin,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_eq(missile_id, "", "Should fail for target too far")
	assert_eq(missile_system.get_in_flight_count(), 0)


func test_launch_missile_generates_unique_ids() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var id1: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	var id2: String = missile_system.launch_missile(
		"shooter_002", shooter_pos, "target_002", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_ne(id1, id2, "Should generate unique IDs")
	assert_eq(missile_system.get_in_flight_count(), 2)


# =============================================================================
# 射手拘束
# =============================================================================

func test_saclos_shooter_constraint() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001",
		shooter_pos,
		"target_001",
		target_pos,
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained("shooter_001"),
		"SACLOS shooter should be constrained")


func test_faf_no_shooter_constraint() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001",
		shooter_pos,
		"target_001",
		target_pos,
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	assert_false(missile_system.is_shooter_constrained("shooter_001"),
		"F&F shooter should not be constrained")


func test_constrained_shooter_cannot_launch_again() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	# 最初の発射
	var id1: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# 2回目の発射（拘束中）
	var id2: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_002", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_ne(id1, "", "First launch should succeed")
	assert_eq(id2, "", "Second launch should fail (constrained)")
	assert_eq(missile_system.get_in_flight_count(), 1)


func test_get_shooter_constraint() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 100
	)

	var constraint: MissileDataScript.ShooterConstraint = missile_system.get_shooter_constraint("shooter_001")

	assert_not_null(constraint)
	assert_eq(constraint.shooter_id, "shooter_001")
	assert_eq(constraint.missile_id, missile_id)
	assert_eq(constraint.start_tick, 100)
	assert_eq(constraint.guidance_type, MissileDataScript.GuidanceType.SACLOS_LASER_BEAM)


func test_force_release_shooter() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_true(missile_system.is_shooter_constrained("shooter_001"))

	# 強制解除（射手被弾など）
	missile_system.force_release_shooter("shooter_001")

	assert_false(missile_system.is_shooter_constrained("shooter_001"))


func test_force_release_causes_guidance_lost() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	missile_system.force_release_shooter("shooter_001")

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileDataScript.MissileState.LOST,
		"Missile should lose guidance when shooter released")
	assert_false(missile.guidance_active)


# =============================================================================
# 飛翔更新
# =============================================================================

func test_missile_state_progression() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileDataScript.MissileState.LAUNCHING)

	# ブースト終了後（0.5s = 5 ticks）
	missile_system.update(6)
	missile = missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileDataScript.MissileState.IN_FLIGHT,
		"Should transition to IN_FLIGHT after boost")


func test_missile_impact_after_flight_time() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)  # 2km

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	var expected_impact_tick: int = missile.estimated_impact_tick

	# 着弾前
	var impacts: Array[Dictionary] = missile_system.update(expected_impact_tick - 1)
	assert_eq(impacts.size(), 0, "No impact before flight time")
	assert_eq(missile_system.get_in_flight_count(), 1)

	# 着弾時
	impacts = missile_system.update(expected_impact_tick)
	assert_eq(impacts.size(), 1, "One impact at flight time")
	assert_eq(impacts[0].missile_id, missile_id)
	assert_eq(impacts[0].target_id, "target_001")
	assert_eq(missile_system.get_in_flight_count(), 0, "Missile removed after impact")


func test_impact_returns_attack_profile() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	var impacts: Array[Dictionary] = missile_system.update(missile.estimated_impact_tick)

	assert_eq(impacts[0].attack_profile, MissileDataScript.AttackProfile.TOP_ATTACK)


func test_saclos_constraint_released_on_impact() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_true(missile_system.is_shooter_constrained("shooter_001"))

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	missile_system.update(missile.estimated_impact_tick)

	assert_false(missile_system.is_shooter_constrained("shooter_001"),
		"Shooter constraint released after impact")


# =============================================================================
# クエリ
# =============================================================================

func test_get_missiles_by_shooter() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_002", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"shooter_002", shooter_pos, "target_003", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	var missiles: Array[MissileDataScript.InFlightMissile] = missile_system.get_missiles_by_shooter("shooter_001")
	assert_eq(missiles.size(), 2)


func test_get_missiles_targeting() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"shooter_002", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"shooter_003", shooter_pos, "target_002", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	var missiles: Array[MissileDataScript.InFlightMissile] = missile_system.get_missiles_targeting("target_001")
	assert_eq(missiles.size(), 2)


# =============================================================================
# 対抗手段
# =============================================================================

func test_smoke_disruption_probability() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# Javelinの smoke_vulnerability は 0.7
	# 複数回試行して確率的に動作することを確認
	var disrupted_count := 0
	var test_runs := 100

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		if missile_system.check_smoke_disruption(missile_id):
			disrupted_count += 1

	# 70%の確率なので、60-80%の範囲に収まるはず
	var disruption_rate := float(disrupted_count) / float(test_runs)
	assert_almost_eq(disruption_rate, 0.7, 0.15,
		"Smoke disruption rate should be around 70%")


func test_smoke_disruption_sets_lost_state() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# 確実にLOSTになるまで試行
	for _i in range(20):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		if missile_system.check_smoke_disruption(missile_id):
			var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
			assert_eq(missile.state, MissileDataScript.MissileState.LOST)
			assert_false(missile.guidance_active)
			return

	# 20回やってもLOSTにならなければテスト失敗
	fail_test("Smoke disruption should eventually work")


func test_aps_intercept_with_vulnerability() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	# TOWの aps_vulnerability は 1.0
	# APS基本確率 0.5 × 1.0 = 0.5
	var intercepted_count := 0
	var test_runs := 100

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			tow, MissileDataScript.AttackProfile.DIRECT, 0
		)

		if missile_system.attempt_aps_intercept(missile_id, 0.5):
			intercepted_count += 1

	var intercept_rate := float(intercepted_count) / float(test_runs)
	assert_almost_eq(intercept_rate, 0.5, 0.15,
		"APS intercept rate should be around 50%")


func test_aps_intercept_sets_intercepted_state() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	# 確実にINTERCEPTEDになるまで試行
	for _i in range(20):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			tow, MissileDataScript.AttackProfile.DIRECT, 0
		)

		if missile_system.attempt_aps_intercept(missile_id, 1.0):  # 100%確率
			var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
			assert_eq(missile.state, MissileDataScript.MissileState.INTERCEPTED)
			return

	fail_test("APS intercept with 100% should work")


func test_aps_low_vulnerability_reduces_intercept() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# Javelinの aps_vulnerability は 0.9
	# TOP_ATTACKでは回避補正0.2が適用される
	# APS基本確率 1.0 × 0.9 - 0.2 = 0.7
	var intercepted_count := 0
	var test_runs := 100

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		if missile_system.attempt_aps_intercept(missile_id, 1.0):
			intercepted_count += 1

	var intercept_rate := float(intercepted_count) / float(test_runs)
	# 0.9 - 0.2 = 0.7
	assert_almost_eq(intercept_rate, 0.7, 0.12,
		"APS intercept rate should be reduced by vulnerability and attack profile")


# =============================================================================
# シグナル
# =============================================================================

func test_missile_launched_signal() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	watch_signals(missile_system)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_signal_emitted(missile_system, "missile_launched")


func test_missile_impact_signal() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	watch_signals(missile_system)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	missile_system.update(missile.estimated_impact_tick)

	assert_signal_emitted(missile_system, "missile_impact")


func test_missile_lost_signal() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	watch_signals(missile_system)

	# 射手解除で誘導喪失
	missile_system.force_release_shooter("shooter_001")

	# 次のupdate()でLOSTミサイルが処理される
	missile_system.update(100)

	assert_signal_emitted(missile_system, "missile_lost")


# =============================================================================
# ヘルパー関数
# =============================================================================

func test_can_launch_missile_static() -> void:
	assert_true(MissileSystemScript.can_launch_missile("W_USA_ATGM_JAVELIN"))
	assert_true(MissileSystemScript.can_launch_missile("W_USA_ATGM_TOW2B"))
	assert_false(MissileSystemScript.can_launch_missile("CW_NONEXISTENT"))


func test_get_profile_for_weapon_static() -> void:
	var profile: MissileDataScript.MissileProfile = MissileSystemScript.get_profile_for_weapon("W_RUS_ATGM_KORNET")

	assert_not_null(profile)
	assert_eq(profile.id, "M_RUS_KORNET")


# =============================================================================
# リセット
# =============================================================================

func test_reset_clears_all_state() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"shooter_002", shooter_pos, "target_002", Vector2(2000, 0),
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_eq(missile_system.get_in_flight_count(), 2)
	assert_true(missile_system.is_shooter_constrained("shooter_002"))

	missile_system.reset()

	assert_eq(missile_system.get_in_flight_count(), 0)
	assert_false(missile_system.is_shooter_constrained("shooter_002"))


# =============================================================================
# Phase 2: SACLOS射手拘束強化
# =============================================================================

func test_saclos_shooter_cannot_move() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_false(missile_system.can_shooter_move("shooter_001"),
		"SACLOS shooter cannot move")


func test_saclos_shooter_cannot_fire() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	assert_false(missile_system.can_shooter_fire("shooter_001"),
		"SACLOS shooter cannot fire")


func test_faf_shooter_can_move() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_true(missile_system.can_shooter_move("shooter_001"),
		"F&F shooter can move")


func test_faf_shooter_can_fire() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_true(missile_system.can_shooter_fire("shooter_001"),
		"F&F shooter can fire")


func test_try_shooter_move_emits_violation() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	watch_signals(missile_system)

	var allowed: bool = missile_system.try_shooter_move("shooter_001")

	assert_false(allowed, "Move should be denied")
	assert_signal_emitted(missile_system, "constraint_violation")


func test_try_shooter_fire_emits_violation() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	watch_signals(missile_system)

	var allowed: bool = missile_system.try_shooter_fire("shooter_001")

	assert_false(allowed, "Fire should be denied")
	assert_signal_emitted(missile_system, "constraint_violation")


# =============================================================================
# Phase 2: 有線切断判定
# =============================================================================

func test_wire_cut_on_shooter_move() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	watch_signals(missile_system)

	# 射手が移動
	var shooter_state := {"is_moving": true, "suppression": 0.0, "last_hit_tick": -1}
	var intact: bool = missile_system.check_wire_integrity("shooter_001", shooter_state)

	assert_false(intact, "Wire should be cut when shooter moves")
	assert_signal_emitted(missile_system, "wire_cut")

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileDataScript.MissileState.LOST)


func test_wire_cut_on_shooter_hit() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	watch_signals(missile_system)

	# 射手が被弾（発射後）
	var shooter_state := {"is_moving": false, "suppression": 0.0, "last_hit_tick": 5}
	var intact: bool = missile_system.check_wire_integrity("shooter_001", shooter_state)

	assert_false(intact, "Wire should be cut when shooter is hit")
	assert_signal_emitted(missile_system, "wire_cut")


func test_wire_intact_when_normal() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# 正常状態
	var shooter_state := {"is_moving": false, "suppression": 0.0, "last_hit_tick": -1}
	var intact: bool = missile_system.check_wire_integrity("shooter_001", shooter_state)

	assert_true(intact, "Wire should remain intact in normal state")


func test_wire_cut_probability_on_pinned() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	# Pinned状態での有線切断確率をテスト
	var cut_count := 0
	var test_runs := 100

	for _i in range(test_runs):
		missile_system.reset()

		missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			tow, MissileDataScript.AttackProfile.DIRECT, 0
		)

		# Pinned状態（suppression >= 60.0）
		var shooter_state := {"is_moving": false, "suppression": 70.0, "last_hit_tick": -1}
		if not missile_system.check_wire_integrity("shooter_001", shooter_state):
			cut_count += 1

	var cut_rate := float(cut_count) / float(test_runs)
	# WIRE_CUT_PROB_PINNED = 0.7
	assert_almost_eq(cut_rate, 0.7, 0.15, "Wire cut rate should be around 70% when pinned")


func test_non_wire_guided_not_affected() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# Kornetはレーザービームライディング（有線ではない）
	var shooter_state := {"is_moving": true, "suppression": 0.0, "last_hit_tick": -1}
	var intact: bool = missile_system.check_wire_integrity("shooter_001", shooter_state)

	assert_true(intact, "Laser beam guided missile not affected by wire check")


# =============================================================================
# Phase 2: SACLOS LoS判定
# =============================================================================

func test_saclos_guidance_lost_on_los_break() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# LoS失われる
	var guidance_ok: bool = missile_system.check_saclos_guidance("shooter_001", false)

	assert_false(guidance_ok, "Guidance should be lost when LoS breaks")

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileDataScript.MissileState.LOST)


func test_saclos_guidance_maintained_with_los() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(3000, 0)

	missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		kornet, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# LoS維持
	var guidance_ok: bool = missile_system.check_saclos_guidance("shooter_001", true)

	assert_true(guidance_ok, "Guidance should be maintained with LoS")


# =============================================================================
# Phase 2: Fire-and-Forget 自律追尾
# =============================================================================

func test_faf_lock_loss_on_target_invisible() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# 複数回試行してロック喪失を確認
	var lock_lost_count := 0
	var test_runs := 50

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		# 目標が見えない状態でチェック（チェック間隔に合わせる）
		var target_state := {"is_visible": false, "has_smoke_cover": false, "is_moving": false}
		if not missile_system.check_faf_lock(missile_id, target_state, 10):  # 10 ticks後
			lock_lost_count += 1

	# ロック喪失確率が上がることを確認（0.05 + 0.2 = 0.25）
	var lock_loss_rate := float(lock_lost_count) / float(test_runs)
	assert_gt(lock_loss_rate, 0.1, "Lock should be lost sometimes when target invisible")


func test_faf_lock_maintained_normally() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# 正常状態ではほとんどロック維持
	var lock_maintained_count := 0
	var test_runs := 50

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		# 正常状態
		var target_state := {"is_visible": true, "has_smoke_cover": false, "is_moving": false}
		if missile_system.check_faf_lock(missile_id, target_state, 10):
			lock_maintained_count += 1

	var lock_maintain_rate := float(lock_maintained_count) / float(test_runs)
	# 基本ロック喪失確率5%なので、95%程度は維持
	assert_gt(lock_maintain_rate, 0.85, "Lock should be maintained most of the time in normal state")


func test_faf_target_position_update() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	var old_target_pos := missile.target_position

	# 目標位置更新
	var new_target_pos := Vector2(1100, 50)
	missile_system.update_target_position(missile_id, new_target_pos)

	missile = missile_system.get_missile(missile_id)
	assert_ne(missile.target_position, old_target_pos, "Target position should be updated")
	assert_eq(missile.target_position, new_target_pos)


func test_non_faf_target_position_not_updated() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)

	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	var old_target_pos := missile.target_position

	# SACLOS誘導は目標位置更新されない
	var new_target_pos := Vector2(2100, 50)
	missile_system.update_target_position(missile_id, new_target_pos)

	missile = missile_system.get_missile(missile_id)
	assert_eq(missile.target_position, old_target_pos, "SACLOS target position should not be updated")


# =============================================================================
# Phase 3: 攻撃プロファイル
# =============================================================================

func test_attack_profile_validation() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	# JavelinはTOP_ATTACKとDIRECTが使用可能
	assert_true(missile_system.can_use_attack_profile(javelin, MissileDataScript.AttackProfile.TOP_ATTACK))
	assert_true(missile_system.can_use_attack_profile(javelin, MissileDataScript.AttackProfile.DIRECT))


func test_attack_profile_not_available() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")

	# TOWはDIRECTのみ（TOP_ATTACKは使用不可）
	assert_true(missile_system.can_use_attack_profile(tow, MissileDataScript.AttackProfile.DIRECT))
	assert_false(missile_system.can_use_attack_profile(tow, MissileDataScript.AttackProfile.TOP_ATTACK))


func test_launch_fails_with_invalid_profile() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(2000, 0)

	# TOWでTOP_ATTACKを試みる → 失敗
	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		tow, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_eq(missile_id, "", "Should fail to launch with invalid attack profile")


func test_effective_min_range_direct() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	var effective_min := missile_system.get_effective_min_range(
		javelin, MissileDataScript.AttackProfile.DIRECT
	)

	assert_eq(effective_min, javelin.min_range_m, "DIRECT has no min range increase")


func test_effective_min_range_top_attack() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	var effective_min := missile_system.get_effective_min_range(
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK
	)

	# TOP_ATTACKは+50m
	assert_eq(effective_min, javelin.min_range_m + 50.0)


func test_launch_fails_top_attack_too_close() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	# Javelinの最小射程65m + TOP_ATTACK補正50m = 115m
	# 100mでは発射不可
	var target_pos := Vector2(100, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_eq(missile_id, "", "TOP_ATTACK should fail at close range")


func test_aps_evasion_bonus_direct() -> void:
	var bonus := missile_system.get_aps_evasion_bonus(MissileDataScript.AttackProfile.DIRECT)
	assert_eq(bonus, 0.0, "DIRECT has no APS evasion bonus")


func test_aps_evasion_bonus_top_attack() -> void:
	var bonus := missile_system.get_aps_evasion_bonus(MissileDataScript.AttackProfile.TOP_ATTACK)
	assert_eq(bonus, 0.2, "TOP_ATTACK has 20% APS evasion bonus")


func test_aps_evasion_bonus_overfly_top() -> void:
	var bonus := missile_system.get_aps_evasion_bonus(MissileDataScript.AttackProfile.OVERFLY_TOP)
	assert_eq(bonus, 0.3, "OVERFLY_TOP has 30% APS evasion bonus")


func test_hit_zone_top_attack() -> void:
	var zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0.0,  # target facing east
		Vector2(0, 0),
		Vector2(1000, 0)
	)
	assert_eq(zone, MissileSystem.HitZone.TOP, "TOP_ATTACK should hit TOP zone")


func test_hit_zone_diving() -> void:
	var zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIVING,
		0.0,
		Vector2(0, 0),
		Vector2(1000, 0)
	)
	assert_eq(zone, MissileSystem.HitZone.TOP, "DIVING should hit TOP zone")


func test_hit_zone_direct_front() -> void:
	# 目標は東を向いている（facing = 0）
	# 射手は西にいる（目標の正面から撃つ）
	var zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # 東向き
		Vector2(-1000, 0),  # 西から
		Vector2(0, 0)
	)
	assert_eq(zone, MissileSystem.HitZone.FRONT, "Shooting from front should hit FRONT")


func test_hit_zone_direct_rear() -> void:
	# 目標は東を向いている（facing = 0）
	# 射手は東にいる（目標の後面から撃つ）
	var zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # 東向き
		Vector2(1000, 0),  # 東から
		Vector2(0, 0)
	)
	assert_eq(zone, MissileSystem.HitZone.REAR, "Shooting from rear should hit REAR")


func test_hit_zone_direct_side() -> void:
	# 目標は東を向いている（facing = 0）
	# 射手は北にいる（目標の側面から撃つ）
	var zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # 東向き
		Vector2(0, -1000),  # 北から（Y軸は上が負）
		Vector2(0, 0)
	)
	assert_eq(zone, MissileSystem.HitZone.SIDE, "Shooting from side should hit SIDE")


func test_top_attack_flight_time_longer() -> void:
	# JavelinはTOP_ATTACKとDIRECTの両方をサポート
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var distance := 1500.0

	# DIRECTモードでの飛翔時間を計算
	# Javelinのデフォルトはtop_attack_altitude_mが設定されているので、
	# 直接距離/速度で計算
	var boost_dist := javelin.speed_mps * javelin.boost_duration_sec * 0.5
	var remaining := maxf(0.0, distance - boost_dist)
	var direct_time := javelin.boost_duration_sec + remaining / javelin.speed_mps

	# TOP_ATTACK軌道での飛翔時間
	var top_attack_time := missile_system.calculate_top_attack_flight_time(javelin, distance)

	assert_gt(top_attack_time, direct_time, "TOP_ATTACK should take longer than DIRECT")


func test_terminal_phase_distance_top_attack() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	var terminal_dist := missile_system.get_terminal_phase_distance(
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK
	)

	assert_gt(terminal_dist, 0.0, "TOP_ATTACK should have terminal phase distance")


func test_terminal_phase_distance_direct() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")

	var terminal_dist := missile_system.get_terminal_phase_distance(
		tow, MissileDataScript.AttackProfile.DIRECT
	)

	assert_eq(terminal_dist, 0.0, "DIRECT should have no terminal phase")


func test_missile_enters_terminal_phase() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	var missile_id: String = missile_system.launch_missile(
		"shooter_001", shooter_pos, "target_001", target_pos,
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	watch_signals(missile_system)

	# 終末段階に入るまで更新
	var missile: MissileDataScript.InFlightMissile = missile_system.get_missile(missile_id)
	var max_ticks := missile.estimated_impact_tick

	for tick in range(1, max_ticks):
		missile_system.update(tick)
		missile = missile_system.get_missile(missile_id)
		if missile == null or missile.state == MissileDataScript.MissileState.TERMINAL:
			break

	# 終末段階に入ったことを確認
	if missile != null and missile.state != MissileDataScript.MissileState.IMPACT:
		assert_signal_emitted(missile_system, "missile_terminal")


func test_aps_intercept_with_top_attack_evasion() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var shooter_pos := Vector2(0, 0)
	var target_pos := Vector2(1000, 0)

	# TOP_ATTACKでのAPS迎撃率を確認（回避補正あり）
	var intercept_count := 0
	var test_runs := 100

	for _i in range(test_runs):
		missile_system.reset()

		var missile_id: String = missile_system.launch_missile(
			"shooter_001", shooter_pos, "target_001", target_pos,
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)

		# APS迎撃試行（基本確率50%）
		if missile_system.attempt_aps_intercept(missile_id, 0.5):
			intercept_count += 1

	var intercept_rate := float(intercept_count) / float(test_runs)
	# Javelin: aps_vulnerability = 0.9, TOP_ATTACK evasion = 0.2
	# 最終確率 = 0.5 * 0.9 - 0.2 = 0.25
	assert_almost_eq(intercept_rate, 0.25, 0.12, "TOP_ATTACK should reduce APS intercept rate")
