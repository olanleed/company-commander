extends GutTest

## MissileCalc純粋関数のユニットテスト

const MC = preload("res://scripts/systems/missile_calc.gd")
const MissileData := preload("res://scripts/data/missile_data.gd")


# =============================================================================
# normalize_angle
# =============================================================================

func test_normalize_angle_zero() -> void:
	var result := MC.normalize_angle(0.0)
	assert_almost_eq(result, 0.0, 0.001)


func test_normalize_angle_pi() -> void:
	var result := MC.normalize_angle(PI)
	assert_almost_eq(result, PI, 0.001)


func test_normalize_angle_negative_pi() -> void:
	var result := MC.normalize_angle(-PI)
	# -PIはそのまま（または+PIと等価）
	assert_true(absf(result) <= PI + 0.001)


func test_normalize_angle_over_pi() -> void:
	# PI + 0.5 → -PI + 0.5 = -2.64...
	var result := MC.normalize_angle(PI + 0.5)
	assert_true(result >= -PI and result <= PI)
	assert_almost_eq(result, -PI + 0.5, 0.001)


func test_normalize_angle_under_negative_pi() -> void:
	# -PI - 0.5 → PI - 0.5 = 2.64...
	var result := MC.normalize_angle(-PI - 0.5)
	assert_true(result >= -PI and result <= PI)
	assert_almost_eq(result, PI - 0.5, 0.001)


func test_normalize_angle_large_positive() -> void:
	# 3*PI → PI
	var result := MC.normalize_angle(3.0 * PI)
	assert_almost_eq(result, PI, 0.001)


func test_normalize_angle_large_negative() -> void:
	# -3*PI → -PI (or PI)
	var result := MC.normalize_angle(-3.0 * PI)
	assert_true(absf(result) <= PI + 0.001)


# =============================================================================
# calc_effective_min_range
# =============================================================================

func test_effective_min_range_direct() -> void:
	# DIRECTプロファイルでは最小射程増加なし
	var base_min := 100.0
	var result := MC.calc_effective_min_range(base_min, MissileData.AttackProfile.DIRECT)
	assert_almost_eq(result, base_min, 0.001)


func test_effective_min_range_top_attack() -> void:
	# TOP_ATTACKは50m増加
	var base_min := 100.0
	var result := MC.calc_effective_min_range(base_min, MissileData.AttackProfile.TOP_ATTACK)
	assert_almost_eq(result, 150.0, 0.001)


func test_effective_min_range_diving() -> void:
	# DIVINGは増加なし
	var base_min := 100.0
	var result := MC.calc_effective_min_range(base_min, MissileData.AttackProfile.DIVING)
	assert_almost_eq(result, 100.0, 0.001)


func test_effective_min_range_overfly_top() -> void:
	# OVERFLY_TOPは100m増加
	var base_min := 100.0
	var result := MC.calc_effective_min_range(base_min, MissileData.AttackProfile.OVERFLY_TOP)
	assert_almost_eq(result, 200.0, 0.001)


func test_effective_min_range_zero_base() -> void:
	# 基本最小射程0でも増加分は追加
	var result := MC.calc_effective_min_range(0.0, MissileData.AttackProfile.TOP_ATTACK)
	assert_almost_eq(result, 50.0, 0.001)


# =============================================================================
# get_aps_evasion_bonus
# =============================================================================

func test_aps_evasion_bonus_direct() -> void:
	var result := MC.get_aps_evasion_bonus(MissileData.AttackProfile.DIRECT)
	assert_almost_eq(result, 0.0, 0.001)


func test_aps_evasion_bonus_top_attack() -> void:
	var result := MC.get_aps_evasion_bonus(MissileData.AttackProfile.TOP_ATTACK)
	assert_almost_eq(result, 0.2, 0.001)


func test_aps_evasion_bonus_diving() -> void:
	var result := MC.get_aps_evasion_bonus(MissileData.AttackProfile.DIVING)
	assert_almost_eq(result, 0.1, 0.001)


func test_aps_evasion_bonus_overfly_top() -> void:
	var result := MC.get_aps_evasion_bonus(MissileData.AttackProfile.OVERFLY_TOP)
	assert_almost_eq(result, 0.3, 0.001)


func test_aps_evasion_bonus_ordering() -> void:
	# 回避ボーナス: DIRECT < DIVING < TOP_ATTACK < OVERFLY_TOP
	var direct := MC.get_aps_evasion_bonus(MissileData.AttackProfile.DIRECT)
	var diving := MC.get_aps_evasion_bonus(MissileData.AttackProfile.DIVING)
	var top := MC.get_aps_evasion_bonus(MissileData.AttackProfile.TOP_ATTACK)
	var overfly := MC.get_aps_evasion_bonus(MissileData.AttackProfile.OVERFLY_TOP)

	assert_lt(direct, diving)
	assert_lt(diving, top)
	assert_lt(top, overfly)


# =============================================================================
# calc_top_attack_flight_time
# =============================================================================

func test_top_attack_flight_time_zero_distance() -> void:
	var result := MC.calc_top_attack_flight_time(300.0, 0.0)
	assert_almost_eq(result, 0.0, 0.001)


func test_top_attack_flight_time_short_range() -> void:
	# 近距離（<500m）: 2%増加
	var speed := 300.0
	var distance := 300.0
	var direct_time := distance / speed
	var result := MC.calc_top_attack_flight_time(speed, distance)
	assert_almost_eq(result, direct_time * 1.02, 0.01)


func test_top_attack_flight_time_mid_range() -> void:
	# 中距離（500-1500m）: 8%増加
	var speed := 300.0
	var distance := 1000.0
	var direct_time := distance / speed
	var result := MC.calc_top_attack_flight_time(speed, distance)
	assert_almost_eq(result, direct_time * 1.08, 0.01)


func test_top_attack_flight_time_long_range() -> void:
	# 遠距離（>1500m）: 12%増加
	var speed := 300.0
	var distance := 2000.0
	var direct_time := distance / speed
	var result := MC.calc_top_attack_flight_time(speed, distance)
	assert_almost_eq(result, direct_time * 1.12, 0.01)


func test_top_attack_flight_time_always_longer_than_direct() -> void:
	# TOP_ATTACKは常に直射より遅い
	var speed := 300.0
	var distances: Array[float] = [200.0, 500.0, 1000.0, 2000.0]
	for dist in distances:
		var direct_time: float = dist / speed
		var top_time := MC.calc_top_attack_flight_time(speed, dist)
		assert_gt(top_time, direct_time, "TOP_ATTACK should be slower at %s m" % dist)


# =============================================================================
# calc_terminal_phase_distance
# =============================================================================

func test_terminal_phase_distance_direct() -> void:
	# DIRECTは終末段階なし
	var result := MC.calc_terminal_phase_distance(
		MissileData.AttackProfile.DIRECT, 150.0, 45.0
	)
	assert_almost_eq(result, 0.0, 0.001)


func test_terminal_phase_distance_top_attack() -> void:
	# TOP_ATTACK: altitude / tan(dive_angle)
	# altitude=150m, dive_angle=45度 → 150 / tan(45°) = 150m
	var altitude := 150.0
	var dive_angle := 45.0
	var result := MC.calc_terminal_phase_distance(
		MissileData.AttackProfile.TOP_ATTACK, altitude, dive_angle
	)
	var expected := altitude / tan(deg_to_rad(dive_angle))
	assert_almost_eq(result, expected, 1.0)


func test_terminal_phase_distance_diving() -> void:
	# DIVINGは固定200m
	var result := MC.calc_terminal_phase_distance(
		MissileData.AttackProfile.DIVING, 100.0, 60.0
	)
	assert_almost_eq(result, 200.0, 0.001)


func test_terminal_phase_distance_overfly_top() -> void:
	# OVERFLY_TOPは固定100m
	var result := MC.calc_terminal_phase_distance(
		MissileData.AttackProfile.OVERFLY_TOP, 100.0, 60.0
	)
	assert_almost_eq(result, 100.0, 0.001)


func test_terminal_phase_distance_top_attack_steep_dive() -> void:
	# 急角度の降下（60度）→ 終末段階開始が近い
	var altitude := 150.0
	var dive_angle := 60.0
	var result := MC.calc_terminal_phase_distance(
		MissileData.AttackProfile.TOP_ATTACK, altitude, dive_angle
	)
	var expected := altitude / tan(deg_to_rad(dive_angle))  # ~86.6m
	assert_almost_eq(result, expected, 1.0)


# =============================================================================
# determine_hit_zone
# =============================================================================

func test_hit_zone_top_attack_is_top() -> void:
	# TOP_ATTACKは常に上面
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.TOP_ATTACK, 0.0, Vector2.ZERO, Vector2(100, 0)
	)
	assert_eq(result, MC.HitZone.TOP)


func test_hit_zone_diving_is_top() -> void:
	# DIVINGも上面
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIVING, 0.0, Vector2.ZERO, Vector2(100, 0)
	)
	assert_eq(result, MC.HitZone.TOP)


func test_hit_zone_overfly_top_is_top() -> void:
	# OVERFLY_TOPも上面
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.OVERFLY_TOP, 0.0, Vector2.ZERO, Vector2(100, 0)
	)
	assert_eq(result, MC.HitZone.TOP)


func test_hit_zone_direct_front() -> void:
	# 目標が東向き（0度）、射手が西にいる → 正面
	var target_facing := 0.0  # 東向き（Godot: 右向き）
	var shooter_pos := Vector2(-100, 0)  # 西
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.FRONT)


func test_hit_zone_direct_rear() -> void:
	# 目標が東向き（0度）、射手が東にいる → 後面
	var target_facing := 0.0  # 東向き
	var shooter_pos := Vector2(100, 0)  # 東
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.REAR)


func test_hit_zone_direct_side_left() -> void:
	# 目標が東向き（0度）、射手が北にいる → 側面
	var target_facing := 0.0  # 東向き
	var shooter_pos := Vector2(0, -100)  # 北（Y-）
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.SIDE)


func test_hit_zone_direct_side_right() -> void:
	# 目標が東向き（0度）、射手が南にいる → 側面
	var target_facing := 0.0  # 東向き
	var shooter_pos := Vector2(0, 100)  # 南（Y+）
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.SIDE)


func test_hit_zone_direct_diagonal_front() -> void:
	# 目標が東向き、射手が南西（45度以内）→ 正面
	var target_facing := 0.0  # 東向き
	var shooter_pos := Vector2(-100, 30)  # 南西（Xが主）
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.FRONT)


func test_hit_zone_direct_diagonal_rear() -> void:
	# 目標が東向き、射手が北東（135度超）→ 後面
	var target_facing := 0.0  # 東向き
	var shooter_pos := Vector2(100, -30)  # 北東（Xが主）
	var target_pos := Vector2(0, 0)
	var result := MC.determine_hit_zone(
		MissileData.AttackProfile.DIRECT, target_facing, shooter_pos, target_pos
	)
	assert_eq(result, MC.HitZone.REAR)


# =============================================================================
# calc_missile_progress
# =============================================================================

func test_missile_progress_at_launch() -> void:
	var result := MC.calc_missile_progress(0.0, 10.0)
	assert_almost_eq(result, 0.0, 0.001)


func test_missile_progress_at_impact() -> void:
	var result := MC.calc_missile_progress(10.0, 10.0)
	assert_almost_eq(result, 1.0, 0.001)


func test_missile_progress_midway() -> void:
	var result := MC.calc_missile_progress(5.0, 10.0)
	assert_almost_eq(result, 0.5, 0.001)


func test_missile_progress_over_time() -> void:
	# 予定を過ぎても1.0を超えない
	var result := MC.calc_missile_progress(15.0, 10.0)
	assert_almost_eq(result, 1.0, 0.001)


func test_missile_progress_zero_total() -> void:
	# 飛翔時間0の場合は0
	var result := MC.calc_missile_progress(5.0, 0.0)
	assert_almost_eq(result, 0.0, 0.001)


# =============================================================================
# calc_missile_position
# =============================================================================

func test_missile_position_at_launch() -> void:
	var start := Vector2(0, 0)
	var target := Vector2(100, 0)
	var result := MC.calc_missile_position(start, target, 0.0)
	assert_almost_eq(result.x, start.x, 0.1)
	assert_almost_eq(result.y, start.y, 0.1)


func test_missile_position_at_impact() -> void:
	var start := Vector2(0, 0)
	var target := Vector2(100, 0)
	var result := MC.calc_missile_position(start, target, 1.0)
	assert_almost_eq(result.x, target.x, 0.1)
	assert_almost_eq(result.y, target.y, 0.1)


func test_missile_position_midway() -> void:
	var start := Vector2(0, 0)
	var target := Vector2(100, 0)
	var result := MC.calc_missile_position(start, target, 0.5)
	assert_almost_eq(result.x, 50.0, 0.1)
	assert_almost_eq(result.y, 0.0, 0.1)


func test_missile_position_diagonal() -> void:
	var start := Vector2(0, 0)
	var target := Vector2(100, 100)
	var result := MC.calc_missile_position(start, target, 0.5)
	assert_almost_eq(result.x, 50.0, 0.1)
	assert_almost_eq(result.y, 50.0, 0.1)


# =============================================================================
# calc_final_aps_intercept_prob
# =============================================================================

func test_aps_intercept_prob_basic() -> void:
	# 基本確率0.5、脆弱性1.0、回避0.0 → 0.5
	var result := MC.calc_final_aps_intercept_prob(0.5, 1.0, 0.0)
	assert_almost_eq(result, 0.5, 0.001)


func test_aps_intercept_prob_with_vulnerability() -> void:
	# 脆弱性0.5 → 確率も半分
	var result := MC.calc_final_aps_intercept_prob(0.5, 0.5, 0.0)
	assert_almost_eq(result, 0.25, 0.001)


func test_aps_intercept_prob_with_evasion() -> void:
	# 回避0.2 → 確率から引く
	var result := MC.calc_final_aps_intercept_prob(0.5, 1.0, 0.2)
	assert_almost_eq(result, 0.3, 0.001)


func test_aps_intercept_prob_clamped_to_zero() -> void:
	# 回避が高すぎて負になる場合は0
	var result := MC.calc_final_aps_intercept_prob(0.3, 1.0, 0.5)
	assert_almost_eq(result, 0.0, 0.001)


func test_aps_intercept_prob_all_factors() -> void:
	# 全ての要素を組み合わせ
	# base=0.6, vuln=0.8, evasion=0.1 → 0.6*0.8 - 0.1 = 0.38
	var result := MC.calc_final_aps_intercept_prob(0.6, 0.8, 0.1)
	assert_almost_eq(result, 0.38, 0.001)
