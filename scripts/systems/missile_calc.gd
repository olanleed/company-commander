class_name MissileCalc
extends RefCounted

## MissileSystemの純粋計算関数群
## 副作用なし、決定的な計算のみ
## 仕様書: docs/missile_system_v0.2.md

const MissileData := preload("res://scripts/data/missile_data.gd")

# =============================================================================
# 命中ゾーン
# =============================================================================

## 命中ゾーン（HitZone）
enum HitZone {
	FRONT,   ## 正面
	SIDE,    ## 側面
	REAR,    ## 後面
	TOP,     ## 上面
}

# =============================================================================
# 攻撃プロファイル定数
# =============================================================================

## APS回避補正（攻撃プロファイル別）
const APS_EVASION_BONUS: Dictionary = {
	MissileData.AttackProfile.DIRECT: 0.0,
	MissileData.AttackProfile.TOP_ATTACK: 0.2,
	MissileData.AttackProfile.DIVING: 0.1,
	MissileData.AttackProfile.OVERFLY_TOP: 0.3,
}

## 最小射程増加（攻撃プロファイル別）
const MIN_RANGE_INCREASE_M: Dictionary = {
	MissileData.AttackProfile.DIRECT: 0.0,
	MissileData.AttackProfile.TOP_ATTACK: 50.0,
	MissileData.AttackProfile.DIVING: 0.0,
	MissileData.AttackProfile.OVERFLY_TOP: 100.0,
}

# =============================================================================
# 角度計算
# =============================================================================

## 角度を-PI〜PIに正規化
## @param angle 入力角度（ラジアン）
## @return 正規化された角度 (-PI〜PI)
static func normalize_angle(angle: float) -> float:
	while angle > PI:
		angle -= TAU
	while angle < -PI:
		angle += TAU
	return angle


# =============================================================================
# 有効射程計算
# =============================================================================

## 攻撃プロファイルに基づく有効最小射程を計算
## @param base_min_range 基本最小射程（メートル）
## @param attack_profile 攻撃プロファイル
## @return 有効最小射程（メートル）
static func calc_effective_min_range(
	base_min_range: float,
	attack_profile: MissileData.AttackProfile
) -> float:
	var increase: float = MIN_RANGE_INCREASE_M.get(attack_profile, 0.0)
	return base_min_range + increase


# =============================================================================
# APS回避補正
# =============================================================================

## 攻撃プロファイルに基づくAPS回避補正を取得
## @param attack_profile 攻撃プロファイル
## @return APS迎撃確率に対する減算値（0.0〜0.3）
static func get_aps_evasion_bonus(attack_profile: MissileData.AttackProfile) -> float:
	var bonus: float = APS_EVASION_BONUS.get(attack_profile, 0.0)
	return bonus


# =============================================================================
# 飛翔時間計算
# =============================================================================

## TOP_ATTACK軌道の飛翔時間を計算（ゲームバランス版）
## @param speed_mps ミサイル速度（m/s）
## @param distance_m 目標までの距離（メートル）
## @return 飛翔時間（秒）
static func calc_top_attack_flight_time(speed_mps: float, distance_m: float) -> float:
	if distance_m <= 0 or speed_mps <= 0:
		return 0.0

	# 基本飛行時間（直線軌道）
	var direct_time := distance_m / speed_mps

	# TOP_ATTACKは直線より10-15%長い（迂回軌道のペナルティ）
	# 近距離（<500m）: ほぼペナルティなし（上昇する余裕がない）
	# 中距離（500-1500m）: 5-10%増加
	# 遠距離（>1500m）: 10-15%増加
	var penalty_factor: float
	if distance_m < 500.0:
		penalty_factor = 1.02  # 2%増加
	elif distance_m < 1500.0:
		penalty_factor = 1.08  # 8%増加
	else:
		penalty_factor = 1.12  # 12%増加

	return direct_time * penalty_factor


# =============================================================================
# 終末段階計算
# =============================================================================

## 攻撃プロファイル別の終末段階開始条件を取得
## @param attack_profile 攻撃プロファイル
## @param top_attack_altitude_m TOP_ATTACK高度（メートル）
## @param dive_angle_deg 降下角度（度）
## @return 目標までの距離（m）がこの値以下で終末段階（0.0は終末段階なし）
static func calc_terminal_phase_distance(
	attack_profile: MissileData.AttackProfile,
	top_attack_altitude_m: float,
	dive_angle_deg: float
) -> float:
	match attack_profile:
		MissileData.AttackProfile.TOP_ATTACK:
			# 上昇→降下に入る距離
			var dive_angle := deg_to_rad(dive_angle_deg)
			if dive_angle <= 0:
				return 0.0
			return top_attack_altitude_m / tan(dive_angle)
		MissileData.AttackProfile.DIVING:
			# 急降下開始距離
			return 200.0
		MissileData.AttackProfile.OVERFLY_TOP:
			# オーバーフライ開始距離
			return 100.0
		_:
			# DIRECT: 終末段階なし（着弾まで直進）
			return 0.0


# =============================================================================
# 命中ゾーン判定
# =============================================================================

## 攻撃プロファイルに基づく命中ゾーンを決定
## @param attack_profile 攻撃プロファイル
## @param target_facing 目標の向き（ラジアン、0=東向き）
## @param shooter_pos 射手位置
## @param target_pos 目標位置
## @return 命中ゾーン
static func determine_hit_zone(
	attack_profile: MissileData.AttackProfile,
	target_facing: float,
	shooter_pos: Vector2,
	target_pos: Vector2
) -> HitZone:
	# TOP_ATTACK / DIVING / OVERFLY_TOP は上面命中
	if attack_profile in [
		MissileData.AttackProfile.TOP_ATTACK,
		MissileData.AttackProfile.DIVING,
		MissileData.AttackProfile.OVERFLY_TOP
	]:
		return HitZone.TOP

	# DIRECT の場合は射撃角度から決定
	return calc_direct_hit_zone(target_facing, shooter_pos, target_pos)


## 直射攻撃の命中ゾーンを決定
## @param target_facing 目標の向き（ラジアン、0=東向き）
## @param shooter_pos 射手位置
## @param target_pos 目標位置
## @return 命中ゾーン（FRONT/SIDE/REAR）
static func calc_direct_hit_zone(
	target_facing: float,
	shooter_pos: Vector2,
	target_pos: Vector2
) -> HitZone:
	# 射手から目標への方向ベクトル
	var attack_direction := (target_pos - shooter_pos).normalized()
	var attack_angle := attack_direction.angle()

	# 目標の向きとの角度差（-PI〜PIに正規化）
	var angle_diff := normalize_angle(attack_angle - target_facing)

	# 角度差による判定
	# 正面: ±45度以内
	# 側面: 45〜135度
	# 後面: 135度以上
	var abs_diff := absf(angle_diff)

	if abs_diff <= PI / 4.0:  # 45度
		return HitZone.FRONT
	elif abs_diff >= PI * 3.0 / 4.0:  # 135度
		return HitZone.REAR
	else:
		return HitZone.SIDE


# =============================================================================
# ミサイル位置計算
# =============================================================================

## ミサイルの進行度を計算
## @param time_since_launch 発射からの経過時間（秒）
## @param total_flight_time 総飛翔時間（秒）
## @return 進行度 (0.0〜1.0)
static func calc_missile_progress(time_since_launch: float, total_flight_time: float) -> float:
	if total_flight_time <= 0:
		return 0.0
	return clampf(time_since_launch / total_flight_time, 0.0, 1.0)


## ミサイル位置を計算（線形補間）
## @param start_pos 発射位置
## @param target_pos 目標位置
## @param progress 進行度 (0.0〜1.0)
## @return 現在位置
static func calc_missile_position(
	start_pos: Vector2,
	target_pos: Vector2,
	progress: float
) -> Vector2:
	return start_pos.lerp(target_pos, progress)


# =============================================================================
# APS迎撃確率計算
# =============================================================================

## 最終APS迎撃確率を計算
## @param base_intercept_prob 基本迎撃確率
## @param aps_vulnerability ミサイルのAPS脆弱性 (0.0〜1.0)
## @param evasion_bonus 攻撃プロファイルによる回避ボーナス
## @return 最終迎撃確率 (0.0〜1.0)
static func calc_final_aps_intercept_prob(
	base_intercept_prob: float,
	aps_vulnerability: float,
	evasion_bonus: float
) -> float:
	var adjusted_prob := base_intercept_prob * aps_vulnerability
	return maxf(0.0, adjusted_prob - evasion_bonus)
