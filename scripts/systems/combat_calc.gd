class_name CombatCalc
extends RefCounted

## CombatCalc - 純粋戦闘計算関数群
## 仕様書: docs/refactoring_pure_functions_v0.1.md
##
## 責務:
## - 戦闘計算を純粋関数として提供
## - 副作用なし、決定的、テスト容易
## - CombatSystemから計算ロジックを分離

# =============================================================================
# 射手係数
# =============================================================================

## 射手の抑圧状態に応じた係数を計算
## @param suppression 抑圧レベル (0.0-1.0)
## @return 射撃能力係数 (0.15-1.0)
static func calc_shooter_coeff(suppression: float) -> float:
	if suppression >= GameConstants.SUPP_THRESHOLD_BROKEN:
		return GameConstants.M_SHOOTER_BROKEN
	elif suppression >= GameConstants.SUPP_THRESHOLD_PINNED:
		return GameConstants.M_SHOOTER_PINNED
	elif suppression >= GameConstants.SUPP_THRESHOLD_SUPPRESSED:
		return GameConstants.M_SHOOTER_SUPPRESSED
	else:
		return GameConstants.M_SHOOTER_NORMAL


# =============================================================================
# ヒット確率
# =============================================================================

## ヒット確率を計算（離散ヒットモデル）
## @param exposure 期待危険度 E (0.0+)
## @return ヒット確率 (0.0-1.0)
static func calc_hit_prob(exposure: float) -> float:
	if exposure <= 0.0:
		return 0.0
	return 1.0 - exp(-GameConstants.K_DF_HIT * exposure)


# =============================================================================
# 遮蔽係数
# =============================================================================

## 地形の遮蔽係数を取得（直射用）
## @param terrain 地形タイプ
## @return 遮蔽係数 (0.0-1.0、低いほど防護効果大)
static func get_cover_coeff_df(terrain: GameEnums.TerrainType) -> float:
	match terrain:
		GameEnums.TerrainType.OPEN:
			return GameConstants.COVER_DF_OPEN
		GameEnums.TerrainType.ROAD:
			return GameConstants.COVER_DF_ROAD
		GameEnums.TerrainType.FOREST:
			return GameConstants.COVER_DF_FOREST
		GameEnums.TerrainType.URBAN:
			return GameConstants.COVER_DF_URBAN
		_:
			return GameConstants.COVER_DF_OPEN


## 地形の遮蔽係数を取得（間接用）
## @param terrain 地形タイプ
## @return 遮蔽係数 (0.0-1.0、低いほど防護効果大)
static func get_cover_coeff_if(terrain: GameEnums.TerrainType) -> float:
	match terrain:
		GameEnums.TerrainType.OPEN:
			return GameConstants.COVER_IF_OPEN
		GameEnums.TerrainType.ROAD:
			return GameConstants.COVER_IF_ROAD
		GameEnums.TerrainType.FOREST:
			return GameConstants.COVER_IF_FOREST
		GameEnums.TerrainType.URBAN:
			return GameConstants.COVER_IF_URBAN
		_:
			return GameConstants.COVER_IF_OPEN


# =============================================================================
# アスペクト計算
# =============================================================================

## アスペクトアングルを計算
## @param shooter_pos 射手位置
## @param target_pos 目標位置
## @param target_facing 目標の向き（ラジアン）
## @return アスペクト (FRONT/SIDE/REAR)
static func calc_aspect(
	shooter_pos: Vector2,
	target_pos: Vector2,
	target_facing: float
) -> GameEnums.ArmorAspect:
	var to_shooter := (shooter_pos - target_pos).normalized()
	var facing_vec := Vector2.from_angle(target_facing)
	var dot := facing_vec.dot(to_shooter)

	# ±60° = cos(60°) = 0.5
	if dot >= 0.5:
		return GameEnums.ArmorAspect.FRONT
	# ±150° = cos(150°) ≈ -0.866
	elif dot <= -0.5:
		return GameEnums.ArmorAspect.REAR
	else:
		return GameEnums.ArmorAspect.SIDE


# =============================================================================
# 貫通確率
# =============================================================================

## 貫通確率を計算
## @param penetration 貫通力 (mm RHA等価)
## @param armor 装甲厚 (mm RHA等価)
## @param angle 入射角 (度) - 0度は垂直、60度で実効厚が2倍
## @return 貫通確率 (0.0-1.0)
static func calc_pen_prob(
	penetration: float,
	armor: float,
	angle: float = 0.0
) -> float:
	if armor <= 0.0:
		return 1.0
	if penetration <= 0.0:
		return 0.0

	# 傾斜装甲の実効厚
	var angle_rad := deg_to_rad(angle)
	var cos_angle := cos(angle_rad)
	if cos_angle <= 0.0:
		return 0.0  # 90度以上は貫通不可
	var effective_armor := armor / cos_angle

	# 貫通力と実効装甲の差分
	var diff := penetration - effective_armor

	# シグモイド関数で確率を計算
	# PENETRATION_SIGMOID_SCALE = 15.0
	# diff=+30→88%, diff=0→50%, diff=-30→12%
	return 1.0 / (1.0 + exp(-diff / GameConstants.PENETRATION_SIGMOID_SCALE))


# =============================================================================
# 距離帯
# =============================================================================

## 距離から距離帯を計算
## @param distance 距離（メートル）
## @return 距離帯 (NEAR/MID/FAR)
static func calc_range_band(distance: float) -> GameEnums.RangeBand:
	if distance <= GameConstants.TANK_RANGE_BAND_NEAR_M:
		return GameEnums.RangeBand.NEAR
	elif distance <= GameConstants.TANK_RANGE_BAND_MID_M:
		return GameEnums.RangeBand.MID
	else:
		return GameEnums.RangeBand.FAR


# =============================================================================
# 被害量計算
# =============================================================================

## ソフトターゲット（歩兵）の被害量を計算
## @param category ダメージカテゴリ (MINOR/MAJOR/CRITICAL)
## @param rng 乱数生成器（テスト用、nullの場合はグローバル乱数を使用）
## @return 被害量 (0.8-12.0)
static func calc_soft_damage(
	category: GameEnums.DamageCategory,
	rng: RandomNumberGenerator = null
) -> float:
	var min_dmg: float
	var max_dmg: float

	match category:
		GameEnums.DamageCategory.MINOR:
			min_dmg = GameConstants.SOFT_DAMAGE_MINOR_MIN
			max_dmg = GameConstants.SOFT_DAMAGE_MINOR_MAX
		GameEnums.DamageCategory.MAJOR:
			min_dmg = GameConstants.SOFT_DAMAGE_MAJOR_MIN
			max_dmg = GameConstants.SOFT_DAMAGE_MAJOR_MAX
		GameEnums.DamageCategory.CRITICAL:
			min_dmg = GameConstants.SOFT_DAMAGE_CRITICAL_MIN
			max_dmg = GameConstants.SOFT_DAMAGE_CRITICAL_MAX
		_:
			min_dmg = GameConstants.SOFT_DAMAGE_MINOR_MIN
			max_dmg = GameConstants.SOFT_DAMAGE_MINOR_MAX

	if rng:
		return rng.randf_range(min_dmg, max_dmg)
	else:
		return randf_range(min_dmg, max_dmg)


## 車両の被害量を計算
## @param category ダメージカテゴリ (MINOR/MAJOR)
## @param rng 乱数生成器（テスト用）
## @return 被害量 (8-35)
static func calc_vehicle_damage(
	category: GameEnums.DamageCategory,
	rng: RandomNumberGenerator = null
) -> int:
	var min_dmg: int
	var max_dmg: int

	match category:
		GameEnums.DamageCategory.MINOR:
			min_dmg = GameConstants.VEHICLE_DAMAGE_MINOR_MIN
			max_dmg = GameConstants.VEHICLE_DAMAGE_MINOR_MAX
		GameEnums.DamageCategory.MAJOR, GameEnums.DamageCategory.CRITICAL:
			min_dmg = GameConstants.VEHICLE_DAMAGE_MAJOR_MIN
			max_dmg = GameConstants.VEHICLE_DAMAGE_MAJOR_MAX
		_:
			min_dmg = GameConstants.VEHICLE_DAMAGE_MINOR_MIN
			max_dmg = GameConstants.VEHICLE_DAMAGE_MINOR_MAX

	if rng:
		return rng.randi_range(min_dmg, max_dmg)
	else:
		return randi_range(min_dmg, max_dmg)


# =============================================================================
# 抑圧状態判定
# =============================================================================

## 抑圧値から抑圧状態を判定
## @param suppression 抑圧値 (0.0-1.0)
## @return 抑圧状態 (ACTIVE/SUPPRESSED/PINNED/BROKEN)
static func calc_suppression_state(suppression: float) -> GameEnums.SuppressionState:
	if suppression >= GameConstants.SUPP_THRESHOLD_BROKEN:
		return GameEnums.SuppressionState.BROKEN
	elif suppression >= GameConstants.SUPP_THRESHOLD_PINNED:
		return GameEnums.SuppressionState.PINNED
	elif suppression >= GameConstants.SUPP_THRESHOLD_SUPPRESSED:
		return GameEnums.SuppressionState.SUPPRESSED
	else:
		return GameEnums.SuppressionState.ACTIVE


## 抑圧状態による移動速度倍率を取得
## @param state 抑圧状態
## @return 速度倍率 (0.0-1.0)
static func get_speed_mult_for_suppression(state: GameEnums.SuppressionState) -> float:
	match state:
		GameEnums.SuppressionState.SUPPRESSED:
			return GameConstants.SPEED_MULT_SUPPRESSED
		GameEnums.SuppressionState.PINNED:
			return GameConstants.SPEED_MULT_PINNED
		GameEnums.SuppressionState.BROKEN:
			return GameConstants.SPEED_MULT_BROKEN
		_:
			return 1.0


# =============================================================================
# 戦車戦ヒット確率
# =============================================================================

## 戦車砲の命中確率を取得
## @param shooter_moving 射手が移動中か
## @param target_moving 目標が移動中か
## @param range_band 距離帯
## @return 命中確率 (0.0-1.0)
static func get_tank_hit_prob(
	shooter_moving: bool,
	target_moving: bool,
	range_band: GameEnums.RangeBand
) -> float:
	if not shooter_moving and not target_moving:
		# 静止→静止
		match range_band:
			GameEnums.RangeBand.NEAR:
				return GameConstants.TANK_HIT_SS_NEAR
			GameEnums.RangeBand.MID:
				return GameConstants.TANK_HIT_SS_MID
			GameEnums.RangeBand.FAR:
				return GameConstants.TANK_HIT_SS_FAR
	elif not shooter_moving and target_moving:
		# 静止→移動
		match range_band:
			GameEnums.RangeBand.NEAR:
				return GameConstants.TANK_HIT_SM_NEAR
			GameEnums.RangeBand.MID:
				return GameConstants.TANK_HIT_SM_MID
			GameEnums.RangeBand.FAR:
				return GameConstants.TANK_HIT_SM_FAR
	elif shooter_moving and not target_moving:
		# 移動→静止
		match range_band:
			GameEnums.RangeBand.NEAR:
				return GameConstants.TANK_HIT_MS_NEAR
			GameEnums.RangeBand.MID:
				return GameConstants.TANK_HIT_MS_MID
			GameEnums.RangeBand.FAR:
				return GameConstants.TANK_HIT_MS_FAR
	else:
		# 移動→移動
		match range_band:
			GameEnums.RangeBand.NEAR:
				return GameConstants.TANK_HIT_MM_NEAR
			GameEnums.RangeBand.MID:
				return GameConstants.TANK_HIT_MM_MID
			GameEnums.RangeBand.FAR:
				return GameConstants.TANK_HIT_MM_FAR

	return 0.5  # フォールバック


# =============================================================================
# APFSDS撃破確率
# =============================================================================

## APFSDS（戦車砲）の撃破確率を取得
## @param aspect アスペクト
## @param range_band 距離帯
## @return {kill: float, mission_kill: float}
static func get_apfsds_kill_prob(
	aspect: GameEnums.ArmorAspect,
	range_band: GameEnums.RangeBand
) -> Dictionary:
	match aspect:
		GameEnums.ArmorAspect.FRONT:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.APFSDS_KILL_FRONT_NEAR, "mission_kill": GameConstants.APFSDS_MKILL_FRONT_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.APFSDS_KILL_FRONT_MID, "mission_kill": GameConstants.APFSDS_MKILL_FRONT_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.APFSDS_KILL_FRONT_FAR, "mission_kill": GameConstants.APFSDS_MKILL_FRONT_FAR}
		GameEnums.ArmorAspect.SIDE:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.APFSDS_KILL_SIDE_NEAR, "mission_kill": GameConstants.APFSDS_MKILL_SIDE_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.APFSDS_KILL_SIDE_MID, "mission_kill": GameConstants.APFSDS_MKILL_SIDE_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.APFSDS_KILL_SIDE_FAR, "mission_kill": GameConstants.APFSDS_MKILL_SIDE_FAR}
		GameEnums.ArmorAspect.REAR:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.APFSDS_KILL_REAR_NEAR, "mission_kill": GameConstants.APFSDS_MKILL_REAR_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.APFSDS_KILL_REAR_MID, "mission_kill": GameConstants.APFSDS_MKILL_REAR_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.APFSDS_KILL_REAR_FAR, "mission_kill": GameConstants.APFSDS_MKILL_REAR_FAR}

	return {"kill": 0.5, "mission_kill": 0.3}  # フォールバック


# =============================================================================
# HEAT撃破確率
# =============================================================================

## HEAT/RPGの撃破確率を取得
## @param aspect アスペクト
## @param range_band 距離帯
## @return {kill: float, mission_kill: float}
static func get_heat_kill_prob(
	aspect: GameEnums.ArmorAspect,
	range_band: GameEnums.RangeBand
) -> Dictionary:
	match aspect:
		GameEnums.ArmorAspect.FRONT:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.HEAT_KILL_FRONT_NEAR, "mission_kill": GameConstants.HEAT_MKILL_FRONT_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.HEAT_KILL_FRONT_MID, "mission_kill": GameConstants.HEAT_MKILL_FRONT_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.HEAT_KILL_FRONT_FAR, "mission_kill": GameConstants.HEAT_MKILL_FRONT_FAR}
		GameEnums.ArmorAspect.SIDE:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.HEAT_KILL_SIDE_NEAR, "mission_kill": GameConstants.HEAT_MKILL_SIDE_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.HEAT_KILL_SIDE_MID, "mission_kill": GameConstants.HEAT_MKILL_SIDE_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.HEAT_KILL_SIDE_FAR, "mission_kill": GameConstants.HEAT_MKILL_SIDE_FAR}
		GameEnums.ArmorAspect.REAR:
			match range_band:
				GameEnums.RangeBand.NEAR:
					return {"kill": GameConstants.HEAT_KILL_REAR_NEAR, "mission_kill": GameConstants.HEAT_MKILL_REAR_NEAR}
				GameEnums.RangeBand.MID:
					return {"kill": GameConstants.HEAT_KILL_REAR_MID, "mission_kill": GameConstants.HEAT_MKILL_REAR_MID}
				GameEnums.RangeBand.FAR:
					return {"kill": GameConstants.HEAT_KILL_REAR_FAR, "mission_kill": GameConstants.HEAT_MKILL_REAR_FAR}

	return {"kill": 0.3, "mission_kill": 0.2}  # フォールバック


# =============================================================================
# アスペクト倍率
# =============================================================================

## 重装甲（戦車）のアスペクト倍率を取得
## @param aspect アスペクト
## @return ダメージ倍率
static func get_aspect_mult_heavy(aspect: GameEnums.ArmorAspect) -> float:
	match aspect:
		GameEnums.ArmorAspect.FRONT:
			return GameConstants.ASPECT_HEAVY_FRONT
		GameEnums.ArmorAspect.SIDE:
			return GameConstants.ASPECT_HEAVY_SIDE
		GameEnums.ArmorAspect.REAR:
			return GameConstants.ASPECT_HEAVY_REAR
		_:
			return 1.0


## 軽装甲のアスペクト倍率を取得
## @param aspect アスペクト
## @return ダメージ倍率
static func get_aspect_mult_light(aspect: GameEnums.ArmorAspect) -> float:
	match aspect:
		GameEnums.ArmorAspect.FRONT:
			return GameConstants.ASPECT_LIGHT_FRONT
		GameEnums.ArmorAspect.SIDE:
			return GameConstants.ASPECT_LIGHT_SIDE
		GameEnums.ArmorAspect.REAR:
			return GameConstants.ASPECT_LIGHT_REAR
		_:
			return 1.0


# =============================================================================
# 目標回避係数
# =============================================================================

## 目標の回避係数を取得
## @param is_moving 目標が移動中か
## @return 回避係数 (移動中は1.0超、静止は1.0)
static func get_target_evasion_coeff(is_moving: bool) -> float:
	if is_moving:
		return GameConstants.M_EVASION_MOVING
	else:
		return GameConstants.M_EVASION_STATIONARY


# =============================================================================
# 戦力火力係数
# =============================================================================

## Strengthによる火力倍率を計算
## @param current_strength 現在のStrength
## @param max_strength 最大Strength
## @return 火力倍率 (0.3-1.0)
static func get_strength_fire_coeff(current_strength: int, max_strength: int) -> float:
	if max_strength <= 0:
		return 1.0
	var strength_ratio := float(current_strength) / float(max_strength)
	return GameConstants.M_STRENGTH_FIRE_MIN + GameConstants.M_STRENGTH_FIRE_SCALE * strength_ratio


# =============================================================================
# 視認性係数
# =============================================================================

## LoS透過率から視認性係数を計算
## @param t_los LoS透過率 (0.0-1.0)
## @return 視認性係数 (0.25-1.0)
static func calc_visibility_coeff(t_los: float) -> float:
	# 煙と森林の影響を統合したT_LoSから係数を算出
	# 簡易化：T_LoSをそのまま係数として使用（0.25-1.0をクランプ）
	return clampf(t_los, 0.25, 1.0)


# =============================================================================
# 脆弱性係数 (ダメージ)
# =============================================================================

## armor_classとthreat_classからダメージ脆弱性係数を取得
## @param armor_class 装甲クラス (0=Soft, 1=Light, 2=Medium, 3+=Heavy)
## @param threat_class 脅威クラス
## @return ダメージ倍率
static func get_vuln_dmg(armor_class: int, threat_class: WeaponData.ThreatClass) -> float:
	# Soft (armor_class = 0)
	if armor_class == 0:
		match threat_class:
			WeaponData.ThreatClass.SMALL_ARMS:
				return GameConstants.VULN_SOFT_SMALLARMS_DMG
			WeaponData.ThreatClass.AUTOCANNON:
				return GameConstants.VULN_SOFT_AUTOCANNON_DMG
			WeaponData.ThreatClass.HE_FRAG:
				return GameConstants.VULN_SOFT_HEFRAG_DMG
			WeaponData.ThreatClass.AT:
				return GameConstants.VULN_SOFT_AT_DMG
			_:
				return 1.0

	# Light (armor_class = 1)
	if armor_class == 1:
		match threat_class:
			WeaponData.ThreatClass.SMALL_ARMS:
				return GameConstants.VULN_LIGHT_SMALLARMS_DMG
			WeaponData.ThreatClass.AUTOCANNON:
				return GameConstants.VULN_LIGHT_AUTOCANNON_DMG
			WeaponData.ThreatClass.HE_FRAG:
				return GameConstants.VULN_LIGHT_HEFRAG_DMG
			WeaponData.ThreatClass.AT:
				return GameConstants.VULN_LIGHT_AT_DMG
			_:
				return 1.0

	# Medium (armor_class = 2) - IFV/APC
	if armor_class == 2:
		match threat_class:
			WeaponData.ThreatClass.SMALL_ARMS:
				return GameConstants.VULN_MEDIUM_SMALLARMS_DMG
			WeaponData.ThreatClass.AUTOCANNON:
				return GameConstants.VULN_MEDIUM_AUTOCANNON_DMG
			WeaponData.ThreatClass.HE_FRAG:
				return GameConstants.VULN_MEDIUM_HEFRAG_DMG
			WeaponData.ThreatClass.AT:
				return GameConstants.VULN_MEDIUM_AT_DMG
			_:
				return 1.0

	# Heavy (armor_class >= 3) - MBT
	match threat_class:
		WeaponData.ThreatClass.SMALL_ARMS:
			return GameConstants.VULN_HEAVY_SMALLARMS_DMG
		WeaponData.ThreatClass.AUTOCANNON:
			return GameConstants.VULN_HEAVY_AUTOCANNON_DMG
		WeaponData.ThreatClass.HE_FRAG:
			return GameConstants.VULN_HEAVY_HEFRAG_DMG
		WeaponData.ThreatClass.AT:
			return GameConstants.VULN_HEAVY_AT_DMG
		_:
			return 1.0


# =============================================================================
# 期待危険度 (Exposure) 計算
# =============================================================================

## 直射の期待危険度を計算
## E = (L/100) × M_shooter × M_strength × M_visibility × M_evasion × M_cover × M_entrench × M_vuln_dmg
## @param lethality 殺傷力レーティング (0-100+)
## @param m_shooter 射手係数 (抑圧影響)
## @param m_strength 戦力火力係数
## @param m_visibility 視認性係数 (LoS透過率)
## @param m_evasion 目標回避係数
## @param m_cover 遮蔽係数
## @param is_entrenched 塹壕中か
## @param m_vuln_dmg 脆弱性係数
## @return 期待危険度 E (0.0+)
static func calc_exposure_df(
	lethality: int,
	m_shooter: float,
	m_strength: float,
	m_visibility: float,
	m_evasion: float,
	m_cover: float,
	is_entrenched: bool,
	m_vuln_dmg: float
) -> float:
	var m_entrench := GameConstants.ENTRENCH_DF_MULT if is_entrenched else 1.0
	return (float(lethality) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * m_vuln_dmg
