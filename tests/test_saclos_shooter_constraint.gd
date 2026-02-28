extends GutTest

## SACLOS誘導中の射手拘束テスト
## 仕様:
## - SACLOS誘導ミサイル飛翔中は射手が拘束される（移動不可）
## - 通常の移動命令は着弾まで待機してから実行
## - HOLD_FIREで誘導を打ち切り、即座に移動可能
## - Fire-and-Forget（Javelin等）は発射後即移動可能

const MissileSystem := preload("res://scripts/systems/missile_system.gd")
const MissileData := preload("res://scripts/data/missile_data.gd")
const ElementData := preload("res://scripts/data/element_data.gd")
const GameEnums := preload("res://scripts/core/game_enums.gd")

var missile_system: MissileSystem


func before_each() -> void:
	missile_system = MissileSystem.new()


func after_each() -> void:
	missile_system.reset()


# =============================================================================
# テスト用ヘルパー
# =============================================================================

func _create_saclos_wire_profile() -> MissileData.MissileProfile:
	## TOWのような有線SACLOS誘導ミサイル
	var profile := MissileData.MissileProfile.new()
	profile.id = "test_saclos_wire"
	profile.display_name = "Test SACLOS Wire"
	profile.guidance_type = MissileData.GuidanceType.SACLOS_WIRE
	profile.lock_mode = MissileData.LockMode.CONTINUOUS_TRACK
	profile.speed_mps = 200.0
	profile.max_range_m = 3750.0
	profile.min_range_m = 65.0
	profile.default_attack_profile = MissileData.AttackProfile.DIRECT
	profile.available_profiles = [MissileData.AttackProfile.DIRECT]
	profile.shooter_constrained = true
	profile.wire_guided = true
	return profile


func _create_saclos_laser_profile() -> MissileData.MissileProfile:
	## Kornetのようなレーザービームライディング誘導ミサイル
	var profile := MissileData.MissileProfile.new()
	profile.id = "test_saclos_laser"
	profile.display_name = "Test SACLOS Laser"
	profile.guidance_type = MissileData.GuidanceType.SACLOS_LASER_BEAM
	profile.lock_mode = MissileData.LockMode.CONTINUOUS_TRACK
	profile.speed_mps = 300.0
	profile.max_range_m = 5500.0
	profile.min_range_m = 100.0
	profile.default_attack_profile = MissileData.AttackProfile.DIRECT
	profile.available_profiles = [MissileData.AttackProfile.DIRECT]
	profile.shooter_constrained = true
	profile.wire_guided = false  # 無線
	return profile


func _create_fire_and_forget_profile() -> MissileData.MissileProfile:
	## JavelinのようなFire-and-Forgetミサイル
	var profile := MissileData.MissileProfile.new()
	profile.id = "test_faf"
	profile.display_name = "Test Fire-and-Forget"
	profile.guidance_type = MissileData.GuidanceType.IIR_HOMING
	profile.lock_mode = MissileData.LockMode.LOBL
	profile.speed_mps = 150.0
	profile.max_range_m = 2500.0
	profile.min_range_m = 65.0
	profile.default_attack_profile = MissileData.AttackProfile.TOP_ATTACK
	profile.available_profiles = [
		MissileData.AttackProfile.TOP_ATTACK,
		MissileData.AttackProfile.DIRECT
	]
	profile.top_attack_altitude_m = 150.0
	profile.dive_angle_deg = 45.0
	profile.shooter_constrained = false
	profile.wire_guided = false
	return profile


# =============================================================================
# 射手拘束基本テスト
# =============================================================================

func test_saclos_wire_constrains_shooter() -> void:
	## 有線SACLOSミサイル発射後、射手が拘束される
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_001"
	var target_id := "TARGET_001"

	# 発射前は拘束なし
	assert_false(missile_system.is_shooter_constrained(shooter_id), "発射前は拘束なし")
	assert_true(missile_system.can_shooter_move(shooter_id), "発射前は移動可能")

	# ミサイル発射
	var missile_id := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0  # current_tick
	)

	assert_ne(missile_id, "", "ミサイルが発射される")

	# 発射後は拘束あり
	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射後は拘束あり")
	assert_false(missile_system.can_shooter_move(shooter_id), "発射後は移動不可")
	assert_false(missile_system.can_shooter_fire(shooter_id), "発射後は他の射撃不可")


func test_saclos_laser_constrains_shooter() -> void:
	## レーザービームSACLOSミサイル発射後、射手が拘束される
	var profile := _create_saclos_laser_profile()
	var shooter_id := "SHOOTER_002"
	var target_id := "TARGET_002"

	var missile_id := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(1500, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "ミサイルが発射される")
	assert_true(missile_system.is_shooter_constrained(shooter_id), "レーザーSACLOSも拘束あり")
	assert_false(missile_system.can_shooter_move(shooter_id), "移動不可")


func test_fire_and_forget_does_not_constrain_shooter() -> void:
	## Fire-and-Forgetミサイルは射手を拘束しない
	var profile := _create_fire_and_forget_profile()
	var shooter_id := "SHOOTER_003"
	var target_id := "TARGET_003"

	var missile_id := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(800, 100),
		profile,
		MissileData.AttackProfile.TOP_ATTACK,
		0
	)

	assert_ne(missile_id, "", "ミサイルが発射される")
	assert_false(missile_system.is_shooter_constrained(shooter_id), "FaFは拘束なし")
	assert_true(missile_system.can_shooter_move(shooter_id), "FaFは発射後即移動可能")
	assert_true(missile_system.can_shooter_fire(shooter_id), "FaFは発射後射撃可能")


# =============================================================================
# 拘束解除テスト
# =============================================================================

func test_constraint_released_on_impact() -> void:
	## ミサイル着弾時に拘束が解除される
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_004"
	var target_id := "TARGET_004"

	# 近距離発射（すぐ着弾）
	var missile_id := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(200, 100),  # 100m先
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射直後は拘束")

	# 着弾まで更新
	var impacts := missile_system.update(10)  # 1秒後

	# 着弾確認
	assert_eq(impacts.size(), 1, "ミサイルが着弾")
	assert_false(missile_system.is_shooter_constrained(shooter_id), "着弾後は拘束解除")
	assert_true(missile_system.can_shooter_move(shooter_id), "着弾後は移動可能")


func test_constraint_released_on_force_release() -> void:
	## force_release_shooterで拘束を強制解除できる
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_005"
	var target_id := "TARGET_005"

	missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射直後は拘束")

	# 強制解除
	missile_system.force_release_shooter(shooter_id)

	assert_false(missile_system.is_shooter_constrained(shooter_id), "強制解除後は拘束なし")
	assert_true(missile_system.can_shooter_move(shooter_id), "強制解除後は移動可能")

	# ミサイルの誘導も喪失している
	var missiles := missile_system.get_missiles_by_shooter(shooter_id)
	assert_eq(missiles.size(), 1, "ミサイルはまだ存在")
	assert_eq(missiles[0].state, MissileData.MissileState.LOST, "誘導喪失状態")


func test_wire_cut_releases_constraint() -> void:
	## 有線切断時に拘束が解除される
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_006"
	var target_id := "TARGET_006"

	missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射直後は拘束")

	# 射手が移動（有線切断）
	var shooter_state := {
		"is_moving": true,
		"suppression": 0.0,
		"last_hit_tick": -1
	}
	var integrity := missile_system.check_wire_integrity(shooter_id, shooter_state, 5)

	assert_false(integrity, "有線が切断される")
	assert_false(missile_system.is_shooter_constrained(shooter_id), "有線切断後は拘束解除")


# =============================================================================
# 移動命令との連携テスト（MovementSystemとの統合テスト用仕様確認）
# =============================================================================

func test_try_shooter_move_returns_false_when_constrained() -> void:
	## 拘束中にtry_shooter_moveはfalseを返す
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_007"
	var target_id := "TARGET_007"

	missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 移動試行
	var can_move := missile_system.try_shooter_move(shooter_id)
	assert_false(can_move, "拘束中は移動試行がfalse")


func test_try_shooter_move_returns_true_when_not_constrained() -> void:
	## 拘束なし時にtry_shooter_moveはtrueを返す
	var shooter_id := "SHOOTER_008"

	var can_move := missile_system.try_shooter_move(shooter_id)
	assert_true(can_move, "拘束なしは移動試行がtrue")


func test_constraint_violation_signal_emitted_on_move_attempt() -> void:
	## 拘束中の移動試行でconstraint_violationシグナルが発火する
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_009"
	var target_id := "TARGET_009"

	missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# シグナル監視
	watch_signals(missile_system)

	# 移動試行
	missile_system.try_shooter_move(shooter_id)

	# シグナル確認
	assert_signal_emitted(missile_system, "constraint_violation")


# =============================================================================
# 複数ミサイル・複数射手テスト
# =============================================================================

func test_multiple_shooters_independent_constraints() -> void:
	## 複数射手は独立して拘束される
	var profile := _create_saclos_wire_profile()

	# 射手A
	missile_system.launch_missile(
		"SHOOTER_A",
		Vector2(100, 100),
		"TARGET_A",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 射手B（FaF）
	var faf_profile := _create_fire_and_forget_profile()
	missile_system.launch_missile(
		"SHOOTER_B",
		Vector2(100, 200),
		"TARGET_B",
		Vector2(1000, 200),
		faf_profile,
		MissileData.AttackProfile.TOP_ATTACK,
		0
	)

	assert_true(missile_system.is_shooter_constrained("SHOOTER_A"), "射手Aは拘束")
	assert_false(missile_system.is_shooter_constrained("SHOOTER_B"), "射手Bは拘束なし（FaF）")

	# 射手Aの強制解除は射手Bに影響しない
	missile_system.force_release_shooter("SHOOTER_A")

	assert_false(missile_system.is_shooter_constrained("SHOOTER_A"), "射手A解除")
	assert_false(missile_system.is_shooter_constrained("SHOOTER_B"), "射手Bは変化なし")


func test_shooter_cannot_launch_second_missile_while_constrained() -> void:
	## 拘束中の射手は2発目を発射できない
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_010"

	# 1発目
	var first_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_1",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)
	assert_ne(first_missile, "", "1発目は発射成功")

	# 2発目（拘束中）
	var second_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_2",
		Vector2(1500, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		5
	)
	assert_eq(second_missile, "", "2発目は発射失敗（拘束中）")


# =============================================================================
# HOLD_FIREによる誘導打ち切りテスト（仕様確認用）
# =============================================================================

func test_hold_fire_scenario_with_force_release() -> void:
	## HOLD_FIREシナリオ: force_release_shooterで誘導打ち切り→即移動可能
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_011"
	var target_id := "TARGET_011"

	# ミサイル発射
	var missile_id := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		target_id,
		Vector2(3000, 100),  # 遠距離
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射後は拘束")

	# シグナル監視
	watch_signals(missile_system)

	# HOLD_FIRE = force_release_shooter を呼ぶ
	missile_system.force_release_shooter(shooter_id)

	# 拘束解除確認
	assert_false(missile_system.is_shooter_constrained(shooter_id), "HOLD_FIRE後は拘束解除")
	assert_true(missile_system.can_shooter_move(shooter_id), "HOLD_FIRE後は即移動可能")

	# ミサイルは誘導喪失
	var missile := missile_system.get_missile(missile_id)
	assert_eq(missile.state, MissileData.MissileState.LOST, "ミサイルは誘導喪失")
	assert_false(missile.guidance_active, "誘導非アクティブ")


# =============================================================================
# 移動命令待機テスト（待機→着弾→移動のフロー確認）
# =============================================================================

func test_pending_move_order_flow_spec() -> void:
	## 仕様確認: SACLOS飛翔中に移動命令→着弾まで待機→着弾後移動開始
	## （実際のMovementSystemとの統合は別テストで）

	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_012"

	# ミサイル発射（短距離）
	missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_012",
		Vector2(300, 100),  # 200m先（約1秒で着弾）
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 移動命令が来た（try_shooter_move = false）
	assert_false(missile_system.try_shooter_move(shooter_id), "飛翔中は移動不可")

	# 着弾を待つ
	missile_system.update(5)  # 0.5秒
	assert_true(missile_system.is_shooter_constrained(shooter_id), "まだ飛翔中")

	missile_system.update(15)  # 1.5秒後
	assert_false(missile_system.is_shooter_constrained(shooter_id), "着弾後は拘束解除")

	# 着弾後は移動可能
	assert_true(missile_system.try_shooter_move(shooter_id), "着弾後は移動可能")


# =============================================================================
# SACLOS即射撃テスト（着弾後即座に次弾発射可能）
# =============================================================================

func test_saclos_can_fire_immediately_after_impact() -> void:
	## SACLOS: 着弾後、即発弾があれば即座に次弾を発射できる
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_013"

	# 1発目発射（短距離 = 200m, 約1秒で着弾）
	var first_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_013",
		Vector2(300, 100),  # 200m先
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)
	assert_ne(first_missile, "", "1発目発射成功")
	assert_true(missile_system.is_shooter_constrained(shooter_id), "1発目発射後は拘束中")

	# 着弾前は2発目発射不可
	var second_attempt := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_013B",
		Vector2(400, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		5
	)
	assert_eq(second_attempt, "", "着弾前は2発目発射不可")

	# 着弾を待つ（200m @ 200m/s = 1秒 = 10 ticks）
	missile_system.update(12)  # 1.2秒後、着弾
	assert_false(missile_system.is_shooter_constrained(shooter_id), "着弾後は拘束解除")

	# 即座に2発目発射可能
	var second_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_013C",
		Vector2(500, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		12  # 着弾直後
	)
	assert_ne(second_missile, "", "着弾後即座に2発目発射可能")
	assert_true(missile_system.is_shooter_constrained(shooter_id), "2発目発射後は再度拘束")


func test_saclos_can_fire_immediately_after_guidance_lost() -> void:
	## SACLOS: 誘導喪失後、即発弾があれば即座に次弾を発射できる
	var profile := _create_saclos_wire_profile()
	var shooter_id := "SHOOTER_014"

	# 1発目発射（遠距離 = 飛行時間長め）
	var first_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_014",
		Vector2(2000, 100),  # 1900m先
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)
	assert_ne(first_missile, "", "1発目発射成功")
	assert_true(missile_system.is_shooter_constrained(shooter_id), "1発目発射後は拘束中")

	# force_release（HOLD_FIREや被弾による誘導打ち切り）
	missile_system.force_release_shooter(shooter_id)
	assert_false(missile_system.is_shooter_constrained(shooter_id), "force_release後は拘束解除")

	# 即座に2発目発射可能
	var second_missile := missile_system.launch_missile(
		shooter_id,
		Vector2(100, 100),
		"TARGET_014B",
		Vector2(1500, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		5
	)
	assert_ne(second_missile, "", "誘導喪失後即座に2発目発射可能")
