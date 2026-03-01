extends GutTest

## CombatCalc純粋関数のユニットテスト
## 仕様書: docs/refactoring_pure_functions_v0.1.md
##
## 各関数が以下の性質を持つことを検証:
## - 決定的: 同じ入力には常に同じ出力
## - 副作用なし: 外部状態を読み書きしない
## - 境界条件の正しい処理

const CC = preload("res://scripts/systems/combat_calc.gd")


# =============================================================================
# calc_shooter_coeff
# =============================================================================

func test_shooter_coeff_normal() -> void:
	var result = CC.calc_shooter_coeff(0.0)
	assert_almost_eq(result, GameConstants.M_SHOOTER_NORMAL, 0.001)


func test_shooter_coeff_low_suppression() -> void:
	# 抑圧閾値未満はNORMAL
	var result = CC.calc_shooter_coeff(0.39)
	assert_almost_eq(result, GameConstants.M_SHOOTER_NORMAL, 0.001)


func test_shooter_coeff_suppressed_threshold() -> void:
	# SUPP_THRESHOLD_SUPPRESSED = 0.40
	var result = CC.calc_shooter_coeff(GameConstants.SUPP_THRESHOLD_SUPPRESSED)
	assert_almost_eq(result, GameConstants.M_SHOOTER_SUPPRESSED, 0.001)


func test_shooter_coeff_suppressed() -> void:
	var result = CC.calc_shooter_coeff(0.5)
	assert_almost_eq(result, GameConstants.M_SHOOTER_SUPPRESSED, 0.001)


func test_shooter_coeff_pinned_threshold() -> void:
	# SUPP_THRESHOLD_PINNED = 0.70
	var result = CC.calc_shooter_coeff(GameConstants.SUPP_THRESHOLD_PINNED)
	assert_almost_eq(result, GameConstants.M_SHOOTER_PINNED, 0.001)


func test_shooter_coeff_pinned() -> void:
	var result = CC.calc_shooter_coeff(0.85)
	assert_almost_eq(result, GameConstants.M_SHOOTER_PINNED, 0.001)


func test_shooter_coeff_broken_threshold() -> void:
	# SUPP_THRESHOLD_BROKEN = 0.90
	var result = CC.calc_shooter_coeff(GameConstants.SUPP_THRESHOLD_BROKEN)
	assert_almost_eq(result, GameConstants.M_SHOOTER_BROKEN, 0.001)


func test_shooter_coeff_broken() -> void:
	var result = CC.calc_shooter_coeff(0.95)
	assert_almost_eq(result, GameConstants.M_SHOOTER_BROKEN, 0.001)


func test_shooter_coeff_max_suppression() -> void:
	var result = CC.calc_shooter_coeff(1.0)
	assert_almost_eq(result, GameConstants.M_SHOOTER_BROKEN, 0.001)


# =============================================================================
# calc_hit_prob
# =============================================================================

func test_hit_prob_zero_exposure() -> void:
	var result = CC.calc_hit_prob(0.0)
	assert_eq(result, 0.0)


func test_hit_prob_negative_exposure() -> void:
	var result = CC.calc_hit_prob(-1.0)
	assert_eq(result, 0.0)


func test_hit_prob_small_exposure() -> void:
	var result = CC.calc_hit_prob(0.1)
	assert_gt(result, 0.0)
	assert_lt(result, 0.1)


func test_hit_prob_medium_exposure() -> void:
	var result = CC.calc_hit_prob(1.0)
	assert_gt(result, 0.3)
	assert_lt(result, 0.6)


func test_hit_prob_high_exposure() -> void:
	var result = CC.calc_hit_prob(3.0)
	assert_gt(result, 0.7)
	assert_true(result <= 1.0)


func test_hit_prob_monotonic() -> void:
	# 期待危険度が増えるとヒット確率も増える（単調増加）
	var p1 = CC.calc_hit_prob(0.5)
	var p2 = CC.calc_hit_prob(1.0)
	var p3 = CC.calc_hit_prob(2.0)
	assert_lt(p1, p2)
	assert_lt(p2, p3)


func test_hit_prob_deterministic() -> void:
	# 決定的: 同じ入力には同じ出力
	var result1 = CC.calc_hit_prob(1.5)
	var result2 = CC.calc_hit_prob(1.5)
	assert_eq(result1, result2)


# =============================================================================
# get_cover_coeff_df
# =============================================================================

func test_cover_coeff_df_open() -> void:
	var result = CC.get_cover_coeff_df(GameEnums.TerrainType.OPEN)
	assert_eq(result, GameConstants.COVER_DF_OPEN)


func test_cover_coeff_df_road() -> void:
	var result = CC.get_cover_coeff_df(GameEnums.TerrainType.ROAD)
	assert_eq(result, GameConstants.COVER_DF_ROAD)


func test_cover_coeff_df_forest() -> void:
	var result = CC.get_cover_coeff_df(GameEnums.TerrainType.FOREST)
	assert_eq(result, GameConstants.COVER_DF_FOREST)


func test_cover_coeff_df_urban() -> void:
	var result = CC.get_cover_coeff_df(GameEnums.TerrainType.URBAN)
	assert_eq(result, GameConstants.COVER_DF_URBAN)


func test_cover_coeff_df_ordering() -> void:
	# 遮蔽効果: OPEN >= ROAD > FOREST > URBAN
	var open_val = CC.get_cover_coeff_df(GameEnums.TerrainType.OPEN)
	var road_val = CC.get_cover_coeff_df(GameEnums.TerrainType.ROAD)
	var forest_val = CC.get_cover_coeff_df(GameEnums.TerrainType.FOREST)
	var urban_val = CC.get_cover_coeff_df(GameEnums.TerrainType.URBAN)

	assert_true(open_val >= road_val)
	assert_gt(road_val, forest_val)
	assert_gt(forest_val, urban_val)


# =============================================================================
# get_cover_coeff_if
# =============================================================================

func test_cover_coeff_if_open() -> void:
	var result = CC.get_cover_coeff_if(GameEnums.TerrainType.OPEN)
	assert_eq(result, GameConstants.COVER_IF_OPEN)


func test_cover_coeff_if_forest() -> void:
	var result = CC.get_cover_coeff_if(GameEnums.TerrainType.FOREST)
	assert_eq(result, GameConstants.COVER_IF_FOREST)


func test_cover_coeff_if_urban() -> void:
	var result = CC.get_cover_coeff_if(GameEnums.TerrainType.URBAN)
	assert_eq(result, GameConstants.COVER_IF_URBAN)


# =============================================================================
# calc_aspect
# =============================================================================

func test_aspect_front_direct() -> void:
	# 目標は上向き（Y-方向）、射手は目標の前方にいる
	var shooter := Vector2(0, -100)
	var target := Vector2(0, 0)
	var facing := -PI / 2  # 上向き
	var result = CC.calc_aspect(shooter, target, facing)
	assert_eq(result, GameEnums.ArmorAspect.FRONT)


func test_aspect_rear_direct() -> void:
	# 目標は上向き、射手は目標の後方にいる
	var shooter := Vector2(0, 100)
	var target := Vector2(0, 0)
	var facing := -PI / 2  # 上向き
	var result = CC.calc_aspect(shooter, target, facing)
	assert_eq(result, GameEnums.ArmorAspect.REAR)


func test_aspect_side_left() -> void:
	# 目標は上向き、射手は目標の左にいる
	var shooter := Vector2(-100, 0)
	var target := Vector2(0, 0)
	var facing := -PI / 2  # 上向き
	var result = CC.calc_aspect(shooter, target, facing)
	assert_eq(result, GameEnums.ArmorAspect.SIDE)


func test_aspect_side_right() -> void:
	# 目標は上向き、射手は目標の右にいる
	var shooter := Vector2(100, 0)
	var target := Vector2(0, 0)
	var facing := -PI / 2  # 上向き
	var result = CC.calc_aspect(shooter, target, facing)
	assert_eq(result, GameEnums.ArmorAspect.SIDE)


func test_aspect_diagonal_front() -> void:
	# 45度前方 → FRONT（cos(45°) ≈ 0.707 > 0.5）
	var shooter := Vector2(70, -70)
	var target := Vector2(0, 0)
	var facing := -PI / 2  # 上向き
	var result = CC.calc_aspect(shooter, target, facing)
	assert_eq(result, GameEnums.ArmorAspect.FRONT)


# =============================================================================
# calc_pen_prob
# =============================================================================

func test_pen_prob_zero_armor() -> void:
	var result = CC.calc_pen_prob(500.0, 0.0)
	assert_eq(result, 1.0)


func test_pen_prob_zero_penetration() -> void:
	var result = CC.calc_pen_prob(0.0, 500.0)
	assert_eq(result, 0.0)


func test_pen_prob_equal() -> void:
	# 貫通力 = 装甲厚 の場合、約50%
	var result = CC.calc_pen_prob(500.0, 500.0)
	assert_almost_eq(result, 0.5, 0.01)


func test_pen_prob_high_pen() -> void:
	# 貫通力 >> 装甲厚 の場合、高確率
	var result = CC.calc_pen_prob(550.0, 500.0)  # +50 diff
	assert_gt(result, 0.9)


func test_pen_prob_low_pen() -> void:
	# 貫通力 << 装甲厚 の場合、低確率
	var result = CC.calc_pen_prob(450.0, 500.0)  # -50 diff
	assert_lt(result, 0.1)


func test_pen_prob_angled_armor_reduces_prob() -> void:
	# 傾斜装甲は実効的に厚くなる
	var result_0deg = CC.calc_pen_prob(500.0, 400.0, 0.0)
	var result_30deg = CC.calc_pen_prob(500.0, 400.0, 30.0)
	var result_60deg = CC.calc_pen_prob(500.0, 400.0, 60.0)

	assert_gt(result_0deg, result_30deg)
	assert_gt(result_30deg, result_60deg)


func test_pen_prob_monotonic() -> void:
	# 貫通力が増えると貫通確率も増える（単調増加）
	var p1 = CC.calc_pen_prob(400.0, 500.0)
	var p2 = CC.calc_pen_prob(500.0, 500.0)
	var p3 = CC.calc_pen_prob(600.0, 500.0)

	assert_lt(p1, p2)
	assert_lt(p2, p3)


func test_pen_prob_deterministic() -> void:
	# 決定的: 同じ入力には同じ出力
	var result1 = CC.calc_pen_prob(500.0, 400.0, 30.0)
	var result2 = CC.calc_pen_prob(500.0, 400.0, 30.0)
	assert_eq(result1, result2)


# =============================================================================
# calc_range_band
# =============================================================================

func test_range_band_near() -> void:
	var result = CC.calc_range_band(400.0)
	assert_eq(result, GameEnums.RangeBand.NEAR)


func test_range_band_near_boundary() -> void:
	var result = CC.calc_range_band(GameConstants.TANK_RANGE_BAND_NEAR_M)
	assert_eq(result, GameEnums.RangeBand.NEAR)


func test_range_band_mid() -> void:
	var result = CC.calc_range_band(1000.0)
	assert_eq(result, GameEnums.RangeBand.MID)


func test_range_band_mid_boundary() -> void:
	var result = CC.calc_range_band(GameConstants.TANK_RANGE_BAND_MID_M)
	assert_eq(result, GameEnums.RangeBand.MID)


func test_range_band_far() -> void:
	var result = CC.calc_range_band(2000.0)
	assert_eq(result, GameEnums.RangeBand.FAR)


# =============================================================================
# calc_suppression_state
# =============================================================================

func test_suppression_state_active() -> void:
	var result = CC.calc_suppression_state(0.0)
	assert_eq(result, GameEnums.SuppressionState.ACTIVE)


func test_suppression_state_suppressed() -> void:
	var result = CC.calc_suppression_state(0.5)
	assert_eq(result, GameEnums.SuppressionState.SUPPRESSED)


func test_suppression_state_pinned() -> void:
	var result = CC.calc_suppression_state(0.8)
	assert_eq(result, GameEnums.SuppressionState.PINNED)


func test_suppression_state_broken() -> void:
	var result = CC.calc_suppression_state(0.95)
	assert_eq(result, GameEnums.SuppressionState.BROKEN)


# =============================================================================
# get_speed_mult_for_suppression
# =============================================================================

func test_speed_mult_active() -> void:
	var result = CC.get_speed_mult_for_suppression(GameEnums.SuppressionState.ACTIVE)
	assert_eq(result, 1.0)


func test_speed_mult_suppressed() -> void:
	var result = CC.get_speed_mult_for_suppression(GameEnums.SuppressionState.SUPPRESSED)
	assert_eq(result, GameConstants.SPEED_MULT_SUPPRESSED)


func test_speed_mult_pinned() -> void:
	var result = CC.get_speed_mult_for_suppression(GameEnums.SuppressionState.PINNED)
	assert_eq(result, GameConstants.SPEED_MULT_PINNED)


func test_speed_mult_broken() -> void:
	var result = CC.get_speed_mult_for_suppression(GameEnums.SuppressionState.BROKEN)
	assert_eq(result, GameConstants.SPEED_MULT_BROKEN)


# =============================================================================
# get_tank_hit_prob
# =============================================================================

func test_tank_hit_prob_ss_near() -> void:
	# 静止→静止、近距離は高命中
	var result = CC.get_tank_hit_prob(false, false, GameEnums.RangeBand.NEAR)
	assert_eq(result, GameConstants.TANK_HIT_SS_NEAR)


func test_tank_hit_prob_mm_far() -> void:
	# 移動→移動、遠距離は低命中
	var result = CC.get_tank_hit_prob(true, true, GameEnums.RangeBand.FAR)
	assert_eq(result, GameConstants.TANK_HIT_MM_FAR)


func test_tank_hit_prob_movement_penalty() -> void:
	# 移動すると命中率が下がる
	var ss = CC.get_tank_hit_prob(false, false, GameEnums.RangeBand.MID)
	var ms = CC.get_tank_hit_prob(true, false, GameEnums.RangeBand.MID)
	var sm = CC.get_tank_hit_prob(false, true, GameEnums.RangeBand.MID)
	var mm = CC.get_tank_hit_prob(true, true, GameEnums.RangeBand.MID)

	assert_gt(ss, ms)
	assert_gt(ss, sm)
	assert_gt(ms, mm)
	assert_gt(sm, mm)


func test_tank_hit_prob_range_penalty() -> void:
	# 距離が増えると命中率が下がる
	var near = CC.get_tank_hit_prob(false, false, GameEnums.RangeBand.NEAR)
	var mid = CC.get_tank_hit_prob(false, false, GameEnums.RangeBand.MID)
	var far = CC.get_tank_hit_prob(false, false, GameEnums.RangeBand.FAR)

	assert_gt(near, mid)
	assert_gt(mid, far)


# =============================================================================
# get_apfsds_kill_prob
# =============================================================================

func test_apfsds_kill_prob_front_near() -> void:
	var result = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)
	assert_eq(result.kill, GameConstants.APFSDS_KILL_FRONT_NEAR)
	assert_eq(result.mission_kill, GameConstants.APFSDS_MKILL_FRONT_NEAR)


func test_apfsds_kill_prob_side_more_lethal_than_front() -> void:
	# 側面攻撃は正面より致命的
	var front = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.MID)
	var side = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.SIDE, GameEnums.RangeBand.MID)
	assert_gt(side.kill, front.kill)


func test_apfsds_kill_prob_rear_most_lethal() -> void:
	# 後部攻撃が最も致命的
	var front = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.MID)
	var side = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.SIDE, GameEnums.RangeBand.MID)
	var rear = CC.get_apfsds_kill_prob(GameEnums.ArmorAspect.REAR, GameEnums.RangeBand.MID)
	assert_gt(rear.kill, side.kill)
	assert_gt(side.kill, front.kill)


# =============================================================================
# get_heat_kill_prob
# =============================================================================

func test_heat_kill_prob_front_low() -> void:
	# HEAT/RPGは正面装甲に対して低効果
	var result = CC.get_heat_kill_prob(GameEnums.ArmorAspect.FRONT, GameEnums.RangeBand.NEAR)
	assert_lt(result.kill, 0.1)


func test_heat_kill_prob_rear_high() -> void:
	# HEAT/RPGは後部に対して高効果
	var result = CC.get_heat_kill_prob(GameEnums.ArmorAspect.REAR, GameEnums.RangeBand.NEAR)
	assert_gt(result.kill, 0.8)


# =============================================================================
# get_aspect_mult_heavy
# =============================================================================

func test_aspect_mult_heavy_front_lowest() -> void:
	# 正面装甲が最も効果的（係数が低い）
	var front = CC.get_aspect_mult_heavy(GameEnums.ArmorAspect.FRONT)
	var side = CC.get_aspect_mult_heavy(GameEnums.ArmorAspect.SIDE)
	var rear = CC.get_aspect_mult_heavy(GameEnums.ArmorAspect.REAR)
	assert_lt(front, side)
	assert_lt(side, rear)


# =============================================================================
# calc_soft_damage（乱数を使うのでRNG注入でテスト）
# =============================================================================

func test_soft_damage_minor_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var total := 0.0
	for i in range(100):
		var dmg = CC.calc_soft_damage(GameEnums.DamageCategory.MINOR, rng)
		total += dmg
		assert_true(dmg >= GameConstants.SOFT_DAMAGE_MINOR_MIN)
		assert_true(dmg <= GameConstants.SOFT_DAMAGE_MINOR_MAX)
	# 平均は範囲の中央付近
	var avg := total / 100.0
	var expected_mid := (GameConstants.SOFT_DAMAGE_MINOR_MIN + GameConstants.SOFT_DAMAGE_MINOR_MAX) / 2.0
	assert_almost_eq(avg, expected_mid, 0.3)


func test_soft_damage_major_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(100):
		var dmg = CC.calc_soft_damage(GameEnums.DamageCategory.MAJOR, rng)
		assert_true(dmg >= GameConstants.SOFT_DAMAGE_MAJOR_MIN)
		assert_true(dmg <= GameConstants.SOFT_DAMAGE_MAJOR_MAX)


func test_soft_damage_deterministic_with_same_seed() -> void:
	# 同じシードなら同じ結果
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 99999
	var result1 = CC.calc_soft_damage(GameEnums.DamageCategory.MINOR, rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99999
	var result2 = CC.calc_soft_damage(GameEnums.DamageCategory.MINOR, rng2)

	assert_eq(result1, result2)


# =============================================================================
# calc_vehicle_damage
# =============================================================================

func test_vehicle_damage_minor_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(100):
		var dmg = CC.calc_vehicle_damage(GameEnums.DamageCategory.MINOR, rng)
		assert_true(dmg >= GameConstants.VEHICLE_DAMAGE_MINOR_MIN)
		assert_true(dmg <= GameConstants.VEHICLE_DAMAGE_MINOR_MAX)


func test_vehicle_damage_major_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(100):
		var dmg = CC.calc_vehicle_damage(GameEnums.DamageCategory.MAJOR, rng)
		assert_true(dmg >= GameConstants.VEHICLE_DAMAGE_MAJOR_MIN)
		assert_true(dmg <= GameConstants.VEHICLE_DAMAGE_MAJOR_MAX)
