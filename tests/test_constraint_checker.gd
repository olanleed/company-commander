extends GutTest

## IConstraintCheckerインターフェースとMissileSystem実装のテスト
## フェーズ3: システム依存の整理

const MissileSystem := preload("res://scripts/systems/missile_system.gd")
const MissileData := preload("res://scripts/data/missile_data.gd")
const IConstraintChecker := preload("res://scripts/interfaces/constraint_checker.gd")


# =============================================================================
# IConstraintChecker インターフェーステスト
# =============================================================================

func test_interface_exists() -> void:
	assert_not_null(IConstraintChecker, "IConstraintChecker should exist")


func test_interface_has_can_move_method() -> void:
	var checker = IConstraintChecker.new()
	assert_true(checker.has_method("can_move"), "Should have can_move method")


func test_interface_has_can_fire_method() -> void:
	var checker = IConstraintChecker.new()
	assert_true(checker.has_method("can_fire"), "Should have can_fire method")


func test_interface_has_get_constraint_reason_method() -> void:
	var checker = IConstraintChecker.new()
	assert_true(checker.has_method("get_constraint_reason"), "Should have get_constraint_reason method")


func test_interface_default_can_move_returns_true() -> void:
	var checker = IConstraintChecker.new()
	assert_true(checker.can_move("any_id"), "Default can_move should return true")


func test_interface_default_can_fire_returns_true() -> void:
	var checker = IConstraintChecker.new()
	assert_true(checker.can_fire("any_id"), "Default can_fire should return true")


func test_interface_default_get_constraint_reason_returns_empty() -> void:
	var checker = IConstraintChecker.new()
	assert_eq(checker.get_constraint_reason("any_id"), "", "Default get_constraint_reason should return empty string")


# =============================================================================
# ヘルパー
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
# MissileSystem as IConstraintChecker テスト
# =============================================================================

func test_missile_system_implements_constraint_checker() -> void:
	var missile_system = MissileSystem.new()
	assert_true(missile_system.has_method("can_move"), "MissileSystem should have can_move")
	assert_true(missile_system.has_method("can_fire"), "MissileSystem should have can_fire")
	assert_true(missile_system.has_method("get_constraint_reason"), "MissileSystem should have get_constraint_reason")


func test_missile_system_can_move_when_not_constrained() -> void:
	var missile_system = MissileSystem.new()
	assert_true(missile_system.can_move("shooter_001"), "Should allow move when not constrained")


func test_missile_system_can_fire_when_not_constrained() -> void:
	var missile_system = MissileSystem.new()
	assert_true(missile_system.can_fire("shooter_001"), "Should allow fire when not constrained")


func test_missile_system_cannot_move_when_saclos_constrained() -> void:
	var missile_system = MissileSystem.new()
	var profile = _create_saclos_wire_profile()

	var missile_id = missile_system.launch_missile(
		"shooter_001",
		Vector2(100, 100),
		"target_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "Missile should be launched")
	assert_false(missile_system.can_move("shooter_001"), "Should not allow move when SACLOS constrained")


func test_missile_system_cannot_fire_when_saclos_constrained() -> void:
	var missile_system = MissileSystem.new()
	var profile = _create_saclos_wire_profile()

	missile_system.launch_missile(
		"shooter_001",
		Vector2(100, 100),
		"target_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_false(missile_system.can_fire("shooter_001"), "Should not allow fire when SACLOS constrained")


func test_missile_system_constraint_reason_saclos() -> void:
	var missile_system = MissileSystem.new()
	var profile = _create_saclos_wire_profile()

	missile_system.launch_missile(
		"shooter_001",
		Vector2(100, 100),
		"target_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	var reason = missile_system.get_constraint_reason("shooter_001")
	assert_eq(reason, "SACLOS_GUIDANCE", "Constraint reason should be SACLOS_GUIDANCE")


func test_missile_system_constraint_reason_empty_when_not_constrained() -> void:
	var missile_system = MissileSystem.new()
	var reason = missile_system.get_constraint_reason("shooter_001")
	assert_eq(reason, "", "Constraint reason should be empty when not constrained")


func test_missile_system_can_move_fire_and_forget() -> void:
	var missile_system = MissileSystem.new()
	var profile = _create_fire_and_forget_profile()

	missile_system.launch_missile(
		"shooter_001",
		Vector2(100, 100),
		"target_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# Fire-and-Forgetは拘束しない
	assert_true(missile_system.can_move("shooter_001"), "Should allow move with Fire-and-Forget")
	assert_true(missile_system.can_fire("shooter_001"), "Should allow fire with Fire-and-Forget")


func test_missile_system_constraint_released_on_impact() -> void:
	var missile_system = MissileSystem.new()
	var profile = _create_saclos_wire_profile()

	missile_system.launch_missile(
		"shooter_001",
		Vector2(100, 100),
		"target_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 拘束中を確認
	assert_false(missile_system.can_move("shooter_001"), "Should be constrained initially")

	# ミサイルが着弾するまでtickを進める
	var tick := 0
	while missile_system.get_in_flight_count() > 0 and tick < 1000:
		tick += 1
		missile_system.update(tick)

	# 拘束解除を確認
	assert_true(missile_system.can_move("shooter_001"), "Should allow move after impact")
	assert_true(missile_system.can_fire("shooter_001"), "Should allow fire after impact")
