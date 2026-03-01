extends GutTest

## ミサイルシステム統合テスト
## Main.gdで実装したミサイルシステム統合をテスト
##
## テスト対象:
## - ATGM発射がミサイルシステム経由で処理される
## - SACLOS誘導中の射手拘束（移動/射撃不可）
## - Fire-and-Forget発射後の射手の自由移動
## - 有線切断判定（移動/被弾時）
## - ミサイル着弾処理

const MissileDataScript := preload("res://scripts/data/missile_data.gd")
const MissileSystemScript := preload("res://scripts/systems/missile_system.gd")
const ElementDataScript := preload("res://scripts/data/element_data.gd")
const WeaponDataScript := preload("res://scripts/data/weapon_data.gd")
const CombatSystemScript := preload("res://scripts/systems/combat_system.gd")
const GameEnumsScript := preload("res://scripts/core/game_enums.gd")

var missile_system: MissileSystemScript
var combat_system: CombatSystemScript


func before_all() -> void:
	MissileDataScript._reset_for_testing()


func before_each() -> void:
	missile_system = MissileSystemScript.new()
	combat_system = CombatSystemScript.new()


func after_each() -> void:
	missile_system.reset()


func after_all() -> void:
	MissileDataScript._reset_for_testing()


# =============================================================================
# ヘルパー関数
# =============================================================================

func _create_mock_element(id: String, pos: Vector2, faction: int = 0) -> ElementDataScript.ElementInstance:
	var element := ElementDataScript.ElementInstance.new()
	element.id = id
	element.position = pos
	element.faction = faction
	element.state = GameEnumsScript.UnitState.ACTIVE
	element.is_moving = false
	element.suppression = 0.0
	element.last_hit_tick = -1
	element.facing = 0.0
	return element


func _get_javelin_profile() -> MissileDataScript.MissileProfile:
	return MissileDataScript.get_profile("M_USA_JAVELIN")


func _get_tow_profile() -> MissileDataScript.MissileProfile:
	return MissileDataScript.get_profile("M_USA_TOW2B")


func _get_kornet_profile() -> MissileDataScript.MissileProfile:
	return MissileDataScript.get_profile("M_RUS_KORNET")


func _get_mmpm_profile() -> MissileDataScript.MissileProfile:
	return MissileDataScript.get_profile("M_JPN_MMPM")


func _get_79mat_profile() -> MissileDataScript.MissileProfile:
	return MissileDataScript.get_profile("M_JPN_79MAT")


# =============================================================================
# SACLOS射手拘束テスト
# =============================================================================

func test_saclos_tow_constrains_shooter() -> void:
	var tow := _get_tow_profile()
	assert_true(tow.is_saclos(), "TOW should be SACLOS")

	var missile_id := missile_system.launch_missile(
		"shooter_001",
		Vector2(0, 0),
		"target_001",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "Should launch missile")
	assert_true(missile_system.is_shooter_constrained("shooter_001"), "Shooter should be constrained")


func test_saclos_kornet_constrains_shooter() -> void:
	var kornet := _get_kornet_profile()
	assert_true(kornet.is_saclos(), "Kornet should be SACLOS")

	var missile_id := missile_system.launch_missile(
		"shooter_002",
		Vector2(0, 0),
		"target_002",
		Vector2(3000, 0),
		kornet,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "Should launch missile")
	assert_true(missile_system.is_shooter_constrained("shooter_002"), "Kornet shooter should be constrained")


func test_saclos_79mat_constrains_shooter() -> void:
	var mat79 := _get_79mat_profile()
	assert_true(mat79.is_saclos(), "79MAT should be SACLOS")

	var missile_id := missile_system.launch_missile(
		"shooter_003",
		Vector2(0, 0),
		"target_003",
		Vector2(2000, 0),
		mat79,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_ne(missile_id, "", "Should launch missile")
	assert_true(missile_system.is_shooter_constrained("shooter_003"), "79MAT shooter should be constrained")


func test_saclos_shooter_cannot_move() -> void:
	var tow := _get_tow_profile()

	missile_system.launch_missile(
		"shooter_move_test",
		Vector2(0, 0),
		"target_move_test",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_false(missile_system.can_shooter_move("shooter_move_test"), "SACLOS shooter cannot move")


func test_saclos_shooter_cannot_fire() -> void:
	var tow := _get_tow_profile()

	missile_system.launch_missile(
		"shooter_fire_test",
		Vector2(0, 0),
		"target_fire_test",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_false(missile_system.can_shooter_fire("shooter_fire_test"), "SACLOS shooter cannot fire")


func test_saclos_constraint_released_on_impact() -> void:
	var tow := _get_tow_profile()

	var missile_id := missile_system.launch_missile(
		"shooter_impact_test",
		Vector2(0, 0),
		"target_impact_test",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained("shooter_impact_test"))

	# ミサイル飛翔を進める（着弾まで）
	var missile := missile_system.get_missile(missile_id)
	var impact_tick := missile.estimated_impact_tick

	# 着弾tickまで更新
	for tick in range(1, impact_tick + 5):
		missile_system.update(tick)

	assert_false(missile_system.is_shooter_constrained("shooter_impact_test"), "Constraint should be released after impact")


# =============================================================================
# Fire-and-Forget動作テスト
# =============================================================================

func test_faf_javelin_no_constraint() -> void:
	var javelin := _get_javelin_profile()
	assert_true(javelin.is_fire_and_forget(), "Javelin should be Fire-and-Forget")

	var missile_id := missile_system.launch_missile(
		"faf_shooter_001",
		Vector2(0, 0),
		"faf_target_001",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	assert_ne(missile_id, "", "Should launch missile")
	assert_false(missile_system.is_shooter_constrained("faf_shooter_001"), "FaF shooter should NOT be constrained")


func test_faf_mmpm_no_constraint() -> void:
	var mmpm := _get_mmpm_profile()
	assert_true(mmpm.is_fire_and_forget(), "MMPM should be Fire-and-Forget")

	var missile_id := missile_system.launch_missile(
		"faf_shooter_002",
		Vector2(0, 0),
		"faf_target_002",
		Vector2(3000, 0),
		mmpm,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	assert_ne(missile_id, "", "Should launch missile")
	assert_false(missile_system.is_shooter_constrained("faf_shooter_002"), "MMPM shooter should NOT be constrained")


func test_faf_shooter_can_move() -> void:
	var javelin := _get_javelin_profile()

	missile_system.launch_missile(
		"faf_move_test",
		Vector2(0, 0),
		"faf_move_target",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	assert_true(missile_system.can_shooter_move("faf_move_test"), "FaF shooter CAN move")


func test_faf_shooter_can_fire() -> void:
	var javelin := _get_javelin_profile()

	missile_system.launch_missile(
		"faf_fire_test",
		Vector2(0, 0),
		"faf_fire_target",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	assert_true(missile_system.can_shooter_fire("faf_fire_test"), "FaF shooter CAN fire")


func test_faf_missile_tracks_target() -> void:
	var javelin := _get_javelin_profile()

	var missile_id := missile_system.launch_missile(
		"faf_track_shooter",
		Vector2(0, 0),
		"faf_track_target",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	var missile := missile_system.get_missile(missile_id)
	var original_target_pos := missile.target_position

	# 目標位置を更新
	var new_target_pos := Vector2(1600, 100)
	missile_system.update_target_position(missile_id, new_target_pos)

	assert_eq(missile.target_position, new_target_pos, "FaF missile should track new position")
	assert_ne(missile.target_position, original_target_pos, "Target position should have changed")


# =============================================================================
# 有線切断判定テスト
# =============================================================================

func test_wire_cut_on_shooter_movement() -> void:
	var tow := _get_tow_profile()
	assert_true(tow.wire_guided, "TOW should be wire-guided")

	var missile_id := missile_system.launch_missile(
		"wire_shooter_move",
		Vector2(0, 0),
		"wire_target_move",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# 射手が移動した状態をシミュレート
	var shooter_state := {
		"is_moving": true,
		"suppression": 0.0,
		"last_hit_tick": -1,
	}

	var wire_intact := missile_system.check_wire_integrity("wire_shooter_move", shooter_state, 10)

	assert_false(wire_intact, "Wire should be cut when shooter moves")


func test_wire_cut_on_shooter_hit() -> void:
	var tow := _get_tow_profile()

	var missile_id := missile_system.launch_missile(
		"wire_shooter_hit",
		Vector2(0, 0),
		"wire_target_hit",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# 射手が発射後に被弾
	var shooter_state := {
		"is_moving": false,
		"suppression": 0.0,
		"last_hit_tick": 5,  # launch_tick(0) より後
	}

	var wire_intact := missile_system.check_wire_integrity("wire_shooter_hit", shooter_state, 10)

	assert_false(wire_intact, "Wire should be cut when shooter is hit")


func test_wire_intact_when_stationary() -> void:
	var tow := _get_tow_profile()

	missile_system.launch_missile(
		"wire_shooter_ok",
		Vector2(0, 0),
		"wire_target_ok",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# 射手は静止、被弾なし、抑圧なし
	var shooter_state := {
		"is_moving": false,
		"suppression": 0.0,
		"last_hit_tick": -1,
	}

	var wire_intact := missile_system.check_wire_integrity("wire_shooter_ok", shooter_state, 10)

	assert_true(wire_intact, "Wire should be intact when shooter is stationary")


func test_wire_cut_probability_on_suppression() -> void:
	var tow := _get_tow_profile()

	# 複数回テストして確率的な有線切断を確認
	var cut_count := 0
	var test_runs := 100

	for i in range(test_runs):
		missile_system.reset()

		missile_system.launch_missile(
			"wire_shooter_supp_%d" % i,
			Vector2(0, 0),
			"wire_target_supp_%d" % i,
			Vector2(2000, 0),
			tow,
			MissileDataScript.AttackProfile.DIRECT,
			0
		)

		# 射手がPinned状態（suppression >= 60）
		var shooter_state := {
			"is_moving": false,
			"suppression": 70.0,
			"last_hit_tick": -1,
		}

		var wire_intact := missile_system.check_wire_integrity("wire_shooter_supp_%d" % i, shooter_state, 10)
		if not wire_intact:
			cut_count += 1

	# Pinned状態では70%の確率で切断されるはず
	var cut_rate := float(cut_count) / float(test_runs)
	assert_gt(cut_rate, 0.4, "Wire should be cut frequently when shooter is pinned (got %.2f)" % cut_rate)
	assert_lt(cut_rate, 0.95, "Wire should not always be cut (got %.2f)" % cut_rate)


func test_non_wire_guided_not_affected_by_movement() -> void:
	var kornet := _get_kornet_profile()
	assert_false(kornet.wire_guided, "Kornet should NOT be wire-guided (laser beam riding)")

	missile_system.launch_missile(
		"laser_shooter",
		Vector2(0, 0),
		"laser_target",
		Vector2(3000, 0),
		kornet,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# 射手が移動しても有線切断はない（レーザービームライディング）
	var shooter_state := {
		"is_moving": true,
		"suppression": 0.0,
		"last_hit_tick": -1,
	}

	var guidance_ok := missile_system.check_wire_integrity("laser_shooter", shooter_state, 10)

	assert_true(guidance_ok, "Non-wire SACLOS should not be affected by wire cut check")


# =============================================================================
# ミサイル着弾処理テスト
# =============================================================================

func test_missile_impact_after_flight_time() -> void:
	var javelin := _get_javelin_profile()

	var missile_id := missile_system.launch_missile(
		"impact_shooter",
		Vector2(0, 0),
		"impact_target",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	var missile := missile_system.get_missile(missile_id)
	var impact_tick := missile.estimated_impact_tick

	# 着弾前
	var impacts := missile_system.update(impact_tick - 1)
	assert_eq(impacts.size(), 0, "No impact before estimated tick")

	# 着弾tick
	impacts = missile_system.update(impact_tick)
	assert_eq(impacts.size(), 1, "Should have impact at estimated tick")
	assert_eq(impacts[0].target_id, "impact_target")


func test_top_attack_hits_top_armor() -> void:
	var javelin := _get_javelin_profile()

	var missile_id := missile_system.launch_missile(
		"top_shooter",
		Vector2(0, 0),
		"top_target",
		Vector2(1500, 0),
		javelin,
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0
	)

	var missile := missile_system.get_missile(missile_id)

	# 命中ゾーン判定
	var hit_zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.TOP_ATTACK,
		0.0,  # target facing
		Vector2.ZERO,
		Vector2(1500, 0)
	)

	assert_eq(hit_zone, MissileSystemScript.HitZone.TOP, "TOP_ATTACK should hit TOP zone")


func test_direct_attack_hits_side_armor() -> void:
	var tow := _get_tow_profile()

	# 目標は東向き（facing = 0）、射手は南から（Y軸方向）
	var hit_zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # target facing east
		Vector2(1000, 1000),  # shooter position (south)
		Vector2(1000, 0)  # target position
	)

	assert_eq(hit_zone, MissileSystemScript.HitZone.SIDE, "DIRECT from side should hit SIDE zone")


func test_direct_attack_hits_rear_armor() -> void:
	var tow := _get_tow_profile()

	# 目標は東向き（facing = 0）、射手は東から（後方）
	var hit_zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # target facing east
		Vector2(2000, 0),  # shooter position (east, behind target)
		Vector2(1000, 0)  # target position
	)

	assert_eq(hit_zone, MissileSystemScript.HitZone.REAR, "DIRECT from behind should hit REAR zone")


func test_direct_attack_hits_front_armor() -> void:
	var tow := _get_tow_profile()

	# 目標は東向き（facing = 0）、射手は西から（正面）
	var hit_zone := missile_system.determine_hit_zone(
		MissileDataScript.AttackProfile.DIRECT,
		0.0,  # target facing east
		Vector2(0, 0),  # shooter position (west, in front of target)
		Vector2(1000, 0)  # target position
	)

	assert_eq(hit_zone, MissileSystemScript.HitZone.FRONT, "DIRECT from front should hit FRONT zone")


# =============================================================================
# 攻撃プロファイルテスト
# =============================================================================

func test_javelin_supports_top_attack() -> void:
	var javelin := _get_javelin_profile()
	assert_true(javelin.can_use_profile(MissileDataScript.AttackProfile.TOP_ATTACK))
	assert_true(javelin.can_use_profile(MissileDataScript.AttackProfile.DIRECT))


func test_tow_does_not_support_top_attack() -> void:
	var tow := _get_tow_profile()
	# TOW-2BはOVERFLY_TOPのみサポート（TOP_ATTACKは不可）
	assert_false(tow.can_use_profile(MissileDataScript.AttackProfile.TOP_ATTACK))
	assert_true(tow.can_use_profile(MissileDataScript.AttackProfile.DIRECT))


func test_mmpm_supports_top_attack() -> void:
	var mmpm := _get_mmpm_profile()
	assert_true(mmpm.can_use_profile(MissileDataScript.AttackProfile.TOP_ATTACK))
	assert_true(mmpm.can_use_profile(MissileDataScript.AttackProfile.DIRECT))


func test_top_attack_increases_min_range() -> void:
	var javelin := _get_javelin_profile()

	var direct_min := missile_system.get_effective_min_range(
		javelin, MissileDataScript.AttackProfile.DIRECT
	)
	var top_min := missile_system.get_effective_min_range(
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK
	)

	assert_gt(top_min, direct_min, "TOP_ATTACK should have greater minimum range")


func test_top_attack_provides_aps_evasion() -> void:
	var direct_bonus := missile_system.get_aps_evasion_bonus(MissileDataScript.AttackProfile.DIRECT)
	var top_bonus := missile_system.get_aps_evasion_bonus(MissileDataScript.AttackProfile.TOP_ATTACK)

	assert_eq(direct_bonus, 0.0, "DIRECT should have no APS evasion bonus")
	assert_gt(top_bonus, 0.0, "TOP_ATTACK should have APS evasion bonus")


# =============================================================================
# 貫通判定テスト
# =============================================================================

func test_penetration_probability_calculation() -> void:
	# 貫通力 > 装甲 の場合、高確率で貫通
	var p_high := combat_system.calculate_penetration_probability(200, 100)
	assert_gt(p_high, 0.8, "High penetration vs low armor should have high p_pen")

	# 貫通力 = 装甲 の場合、50%程度
	var p_equal := combat_system.calculate_penetration_probability(100, 100)
	assert_gt(p_equal, 0.3)
	assert_lt(p_equal, 0.7, "Equal penetration and armor should be ~50%")

	# 貫通力 < 装甲 の場合、低確率
	var p_low := combat_system.calculate_penetration_probability(50, 150)
	assert_lt(p_low, 0.3, "Low penetration vs high armor should have low p_pen")


func test_tandem_warhead_defeats_era() -> void:
	var javelin := _get_javelin_profile()
	assert_true(javelin.defeats_era, "Javelin tandem warhead should defeat ERA")

	var mmpm := _get_mmpm_profile()
	assert_true(mmpm.defeats_era, "MMPM tandem warhead should defeat ERA")


# =============================================================================
# 誘導タイプ分類テスト
# =============================================================================

func test_guidance_type_classification() -> void:
	# SACLOS（有線）
	var tow := _get_tow_profile()
	assert_true(tow.is_saclos())
	assert_false(tow.is_fire_and_forget())
	assert_true(tow.wire_guided)

	# SACLOS（レーザービーム）
	var kornet := _get_kornet_profile()
	assert_true(kornet.is_saclos())
	assert_false(kornet.is_fire_and_forget())
	assert_false(kornet.wire_guided)

	# Fire-and-Forget（IIR）
	var javelin := _get_javelin_profile()
	assert_false(javelin.is_saclos())
	assert_true(javelin.is_fire_and_forget())
	assert_false(javelin.wire_guided)


func test_all_atgm_profiles_classified() -> void:
	var profiles := ["M_USA_JAVELIN", "M_USA_TOW2B", "M_RUS_KORNET", "M_RUS_KONKURS",
					  "M_RUS_REFLEKS", "M_CHN_HJ10", "M_CHN_HJ9", "M_JPN_01LMAT",
					  "M_JPN_79MAT", "M_JPN_MMPM"]

	for profile_id in profiles:
		var profile := MissileDataScript.get_profile(profile_id)
		assert_not_null(profile, "Profile %s should exist" % profile_id)

		# いずれかの誘導タイプに分類される
		var is_saclos := profile.is_saclos()
		var is_faf := profile.is_fire_and_forget()
		assert_true(is_saclos or is_faf,
			"Profile %s should be either SACLOS or FaF (saclos=%s, faf=%s)" % [profile_id, is_saclos, is_faf])


# =============================================================================
# 射手拘束違反テスト
# =============================================================================

func test_try_shooter_move_emits_violation_signal() -> void:
	var tow := _get_tow_profile()

	missile_system.launch_missile(
		"violation_shooter",
		Vector2(0, 0),
		"violation_target",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# シグナル監視
	watch_signals(missile_system)

	var allowed := missile_system.try_shooter_move("violation_shooter")

	assert_false(allowed, "Movement should be denied")
	assert_signal_emitted(missile_system, "constraint_violation")


func test_try_shooter_fire_emits_violation_signal() -> void:
	var tow := _get_tow_profile()

	missile_system.launch_missile(
		"fire_violation_shooter",
		Vector2(0, 0),
		"fire_violation_target",
		Vector2(2000, 0),
		tow,
		MissileDataScript.AttackProfile.DIRECT,
		0
	)

	# シグナル監視
	watch_signals(missile_system)

	var allowed := missile_system.try_shooter_fire("fire_violation_shooter")

	assert_false(allowed, "Fire should be denied")
	assert_signal_emitted(missile_system, "constraint_violation")


# =============================================================================
# 複数ミサイル同時処理テスト
# =============================================================================

func test_multiple_missiles_in_flight() -> void:
	var javelin := _get_javelin_profile()
	var tow := _get_tow_profile()

	# 複数のミサイルを発射
	var id1 := missile_system.launch_missile(
		"multi_shooter_1", Vector2(0, 0), "multi_target_1", Vector2(1500, 0),
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	var id2 := missile_system.launch_missile(
		"multi_shooter_2", Vector2(100, 0), "multi_target_2", Vector2(2500, 0),
		tow, MissileDataScript.AttackProfile.DIRECT, 0
	)
	var id3 := missile_system.launch_missile(
		"multi_shooter_3", Vector2(200, 0), "multi_target_3", Vector2(1800, 0),
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)

	assert_eq(missile_system.get_in_flight_count(), 3, "Should have 3 missiles in flight")

	# FaF shooter は拘束されない
	assert_false(missile_system.is_shooter_constrained("multi_shooter_1"))
	assert_false(missile_system.is_shooter_constrained("multi_shooter_3"))

	# SACLOS shooter は拘束される
	assert_true(missile_system.is_shooter_constrained("multi_shooter_2"))


func test_missiles_targeting_same_target() -> void:
	var javelin := _get_javelin_profile()

	# 同じ目標に複数発射
	missile_system.launch_missile(
		"same_shooter_1", Vector2(0, 0), "same_target", Vector2(1500, 0),
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
	)
	missile_system.launch_missile(
		"same_shooter_2", Vector2(100, 100), "same_target", Vector2(1500, 0),
		javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 5
	)

	var missiles := missile_system.get_missiles_targeting("same_target")
	assert_eq(missiles.size(), 2, "Should have 2 missiles targeting same target")


# =============================================================================
# APS迎撃テスト
# =============================================================================

func test_aps_intercept_with_vulnerability() -> void:
	var javelin := _get_javelin_profile()

	var missile_id := missile_system.launch_missile(
		"aps_shooter", Vector2(0, 0), "aps_target", Vector2(1500, 0),
		javelin, MissileDataScript.AttackProfile.DIRECT, 0
	)

	# APS迎撃を試行（100%迎撃確率、脆弱性で減衰）
	var intercepted_count := 0
	var test_runs := 100

	for i in range(test_runs):
		missile_system.reset()

		missile_system.launch_missile(
			"aps_shooter_%d" % i, Vector2(0, 0), "aps_target_%d" % i, Vector2(1500, 0),
			javelin, MissileDataScript.AttackProfile.DIRECT, 0
		)

		if missile_system.attempt_aps_intercept("MSL_000001", 1.0):
			intercepted_count += 1

	# Javelin APS vulnerability = 0.85 なので約85%が迎撃される
	var intercept_rate := float(intercepted_count) / float(test_runs)
	assert_gt(intercept_rate, 0.6, "APS should intercept frequently (got %.2f)" % intercept_rate)


func test_top_attack_evades_aps() -> void:
	var javelin := _get_javelin_profile()

	# TOP_ATTACKとDIRECTで迎撃率を比較
	var direct_intercepts := 0
	var top_intercepts := 0
	var test_runs := 200

	for i in range(test_runs):
		missile_system.reset()

		# DIRECT
		var id1 := missile_system.launch_missile(
			"aps_direct_%d" % i, Vector2(0, 0), "aps_target_d_%d" % i, Vector2(1500, 0),
			javelin, MissileDataScript.AttackProfile.DIRECT, 0
		)
		if missile_system.attempt_aps_intercept(id1, 1.0):
			direct_intercepts += 1

		# TOP_ATTACK
		missile_system.reset()
		var id2 := missile_system.launch_missile(
			"aps_top_%d" % i, Vector2(0, 0), "aps_target_t_%d" % i, Vector2(1500, 0),
			javelin, MissileDataScript.AttackProfile.TOP_ATTACK, 0
		)
		if missile_system.attempt_aps_intercept(id2, 1.0):
			top_intercepts += 1

	# TOP_ATTACKは回避ボーナスがあるので迎撃率が低い
	var direct_rate := float(direct_intercepts) / float(test_runs)
	var top_rate := float(top_intercepts) / float(test_runs)

	assert_lt(top_rate, direct_rate,
		"TOP_ATTACK should have lower intercept rate (top=%.2f, direct=%.2f)" % [top_rate, direct_rate])
