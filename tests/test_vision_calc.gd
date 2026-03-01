extends GutTest

## VisionCalc純粋関数のユニットテスト

const VC = preload("res://scripts/systems/vision_calc.gd")


# =============================================================================
# calc_forest_transmittance
# =============================================================================

func test_forest_transmittance_zero_distance() -> void:
	# 森林を通過しない場合は透過率1.0
	var result := VC.calc_forest_transmittance(0.0)
	assert_almost_eq(result, 1.0, 0.001)


func test_forest_transmittance_negative_distance() -> void:
	# 負の距離も透過率1.0（エッジケース）
	var result := VC.calc_forest_transmittance(-10.0)
	assert_almost_eq(result, 1.0, 0.001)


func test_forest_transmittance_decay_constant() -> void:
	# 減衰距離定数分（60m）で透過率は1/e ≈ 0.368
	var result := VC.calc_forest_transmittance(GameConstants.FOREST_LOS_DECAY_M)
	assert_almost_eq(result, exp(-1.0), 0.001)


func test_forest_transmittance_double_decay() -> void:
	# 2倍の距離で透過率は1/e^2 ≈ 0.135
	var result := VC.calc_forest_transmittance(GameConstants.FOREST_LOS_DECAY_M * 2.0)
	assert_almost_eq(result, exp(-2.0), 0.001)


func test_forest_transmittance_monotonic_decrease() -> void:
	# 距離が増えると透過率は減少する
	var t1 := VC.calc_forest_transmittance(10.0)
	var t2 := VC.calc_forest_transmittance(30.0)
	var t3 := VC.calc_forest_transmittance(60.0)
	var t4 := VC.calc_forest_transmittance(120.0)

	assert_gt(t1, t2)
	assert_gt(t2, t3)
	assert_gt(t3, t4)


func test_forest_transmittance_range() -> void:
	# 任意の距離で透過率は0-1の範囲
	for dist in [1.0, 10.0, 50.0, 100.0, 500.0]:
		var t := VC.calc_forest_transmittance(dist)
		assert_true(t >= 0.0, "透過率は0以上")
		assert_true(t <= 1.0, "透過率は1以下")


# =============================================================================
# calc_los_transmittance
# =============================================================================

func test_los_transmittance_clear() -> void:
	# 森林も煙もない場合は透過率1.0
	var result := VC.calc_los_transmittance(0.0, 1.0)
	assert_almost_eq(result, 1.0, 0.001)


func test_los_transmittance_with_forest() -> void:
	# 森林のみ（煙なし）
	var forest_t := VC.calc_forest_transmittance(60.0)
	var result := VC.calc_los_transmittance(60.0, 1.0)
	assert_almost_eq(result, forest_t, 0.001)


func test_los_transmittance_with_smoke() -> void:
	# 煙のみ（森林なし）
	var smoke_factor := 0.5
	var result := VC.calc_los_transmittance(0.0, smoke_factor)
	assert_almost_eq(result, smoke_factor, 0.001)


func test_los_transmittance_combined() -> void:
	# 森林と煙の両方
	var forest_t := VC.calc_forest_transmittance(30.0)
	var smoke_factor := 0.7
	var result := VC.calc_los_transmittance(30.0, smoke_factor)
	assert_almost_eq(result, forest_t * smoke_factor, 0.001)


func test_los_transmittance_blocked() -> void:
	# 厚い森林で透過率が閾値以下
	var result := VC.calc_los_transmittance(200.0, 1.0)
	assert_true(result < GameConstants.LOS_BLOCK_THRESHOLD, "厚い森林でブロック閾値以下")


# =============================================================================
# get_concealment_modifier
# =============================================================================

func test_concealment_open() -> void:
	var result := VC.get_concealment_modifier(GameEnums.TerrainType.OPEN)
	assert_almost_eq(result, 1.0, 0.001)


func test_concealment_road() -> void:
	var result := VC.get_concealment_modifier(GameEnums.TerrainType.ROAD)
	assert_almost_eq(result, 1.0, 0.001)


func test_concealment_forest() -> void:
	var result := VC.get_concealment_modifier(GameEnums.TerrainType.FOREST)
	assert_almost_eq(result, 0.6, 0.001)


func test_concealment_urban() -> void:
	var result := VC.get_concealment_modifier(GameEnums.TerrainType.URBAN)
	assert_almost_eq(result, 0.7, 0.001)


func test_concealment_water() -> void:
	var result := VC.get_concealment_modifier(GameEnums.TerrainType.WATER)
	assert_almost_eq(result, 1.0, 0.001)


func test_concealment_ordering() -> void:
	# 隠蔽効果: OPEN > URBAN > FOREST
	var open := VC.get_concealment_modifier(GameEnums.TerrainType.OPEN)
	var urban := VC.get_concealment_modifier(GameEnums.TerrainType.URBAN)
	var forest := VC.get_concealment_modifier(GameEnums.TerrainType.FOREST)

	assert_gt(open, urban)
	assert_gt(urban, forest)


# =============================================================================
# calc_effective_range
# =============================================================================

func test_effective_range_no_concealment() -> void:
	# 隠蔽なしで基本射程がそのまま
	var result := VC.calc_effective_range(300.0, 1.0)
	assert_almost_eq(result, 300.0, 0.001)


func test_effective_range_with_concealment() -> void:
	# 森林内（隠蔽0.6）で射程が短縮
	var result := VC.calc_effective_range(300.0, 0.6)
	assert_almost_eq(result, 180.0, 0.001)


func test_effective_range_zero_base() -> void:
	# 基本射程0ならどんな隠蔽でも0
	var result := VC.calc_effective_range(0.0, 0.6)
	assert_almost_eq(result, 0.0, 0.001)


func test_effective_range_scales_linearly() -> void:
	# 線形スケーリング確認
	var r1 := VC.calc_effective_range(1000.0, 1.0)
	var r2 := VC.calc_effective_range(1000.0, 0.5)
	assert_almost_eq(r2, r1 * 0.5, 0.001)


# =============================================================================
# calc_position_error_growth
# =============================================================================

func test_position_error_growth_from_zero() -> void:
	# 初期誤差0から成長
	var result := VC.calc_position_error_growth(0.0, 1.0)
	assert_almost_eq(result, GameConstants.ERROR_GROWTH_MPS * 1.0, 0.001)


func test_position_error_growth_capped() -> void:
	# 最大誤差でキャップ
	var result := VC.calc_position_error_growth(GameConstants.ERROR_MAX_M, 1.0)
	assert_almost_eq(result, GameConstants.ERROR_MAX_M, 0.001)


func test_position_error_growth_near_cap() -> void:
	# 最大誤差に近い場合
	var start := GameConstants.ERROR_MAX_M - 1.0
	var result := VC.calc_position_error_growth(start, 1.0)
	assert_almost_eq(result, GameConstants.ERROR_MAX_M, 0.001)


func test_position_error_growth_rate() -> void:
	# 成長率確認
	var result := VC.calc_position_error_growth(10.0, 2.0)
	var expected := minf(GameConstants.ERROR_MAX_M, 10.0 + GameConstants.ERROR_GROWTH_MPS * 2.0)
	assert_almost_eq(result, expected, 0.001)


func test_position_error_growth_zero_dt() -> void:
	# dt=0なら変化なし
	var result := VC.calc_position_error_growth(50.0, 0.0)
	assert_almost_eq(result, 50.0, 0.001)
