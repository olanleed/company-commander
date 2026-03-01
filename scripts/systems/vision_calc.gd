class_name VisionCalc
extends RefCounted

## VisionSystemの純粋計算関数群
## 副作用なし、決定的な計算のみ
## 仕様書: docs/vision_v0.1.md

# =============================================================================
# 森林透過率計算
# =============================================================================

## 森林内通過距離から透過率を計算
## @param forest_distance_m 森林内通過距離（メートル）
## @return 透過率 (0.0-1.0)
static func calc_forest_transmittance(forest_distance_m: float) -> float:
	if forest_distance_m <= 0.0:
		return 1.0
	return exp(-forest_distance_m / GameConstants.FOREST_LOS_DECAY_M)


# =============================================================================
# LoS透過率計算（総合）
# =============================================================================

## 森林と煙を統合したLoS透過率を計算
## @param forest_distance_m 森林内通過距離（メートル）
## @param smoke_transmittance 煙による透過率 (0.0-1.0)
## @return 総合透過率 (0.0-1.0)
static func calc_los_transmittance(forest_distance_m: float, smoke_transmittance: float) -> float:
	var t_forest := calc_forest_transmittance(forest_distance_m)
	return t_forest * smoke_transmittance


# =============================================================================
# 地形隠蔽係数
# =============================================================================

## 地形タイプから隠蔽係数を取得
## @param terrain 地形タイプ
## @return 隠蔽係数 (0.0-1.0、低いほど隠蔽効果大)
static func get_concealment_modifier(terrain: GameEnums.TerrainType) -> float:
	match terrain:
		GameEnums.TerrainType.OPEN:
			return 1.0
		GameEnums.TerrainType.ROAD:
			return 1.0
		GameEnums.TerrainType.FOREST:
			return 0.6
		GameEnums.TerrainType.URBAN:
			return 0.7
		GameEnums.TerrainType.WATER:
			return 1.0
		_:
			return 1.0


# =============================================================================
# 実効発見距離計算
# =============================================================================

## 基本視界範囲と隠蔽係数から実効発見距離を計算
## @param base_range 基本視界範囲（メートル）
## @param concealment 隠蔽係数 (0.0-1.0)
## @return 実効発見距離（メートル）
static func calc_effective_range(base_range: float, concealment: float) -> float:
	return base_range * concealment


# =============================================================================
# 位置誤差成長計算
# =============================================================================

## 位置誤差の成長を計算（SUS/LOST状態で呼ばれる）
## @param current_error 現在の位置誤差（メートル）
## @param dt 経過時間（秒）
## @return 新しい位置誤差（メートル）
static func calc_position_error_growth(current_error: float, dt: float) -> float:
	var new_error := current_error + GameConstants.ERROR_GROWTH_MPS * dt
	return minf(new_error, GameConstants.ERROR_MAX_M)
