class_name CombatSystem
extends RefCounted

## 戦闘システム
## 仕様書: docs/combat_v0.1.md
##
## 直射・間接の戦闘効果を計算する。
## VisionSystemのLoS情報と連携して動作。

# =============================================================================
# 定数参照
# =============================================================================

# GameConstantsを直接参照（エイリアスはGodot 4.6.1で非対応）

# =============================================================================
# 戦闘効果結果
# =============================================================================

class CombatEffectResult:
	var d_supp: float = 0.0    ## 抑圧増加量
	var d_dmg: float = 0.0     ## ダメージ（Strength減少量）
	var is_valid: bool = false ## 射撃が成立したか


# =============================================================================
# 射手状態係数
# =============================================================================

## 射手の抑圧状態に応じた係数を計算
func calculate_shooter_coefficient(shooter: ElementData.ElementInstance) -> float:
	var base_m := _get_suppression_state_coefficient(shooter.suppression)

	# Cohesion/Fatigue補正（将来拡張用）
	# M_cohesion = 0.6 + 0.4 × (Cohesion/100)
	# M_fatigue = 1.0 - 0.3 × (Fatigue/100)
	# 現在はCohesion=100、Fatigue=0として計算
	var m_cohesion := GameConstants.M_COHESION_MIN + GameConstants.M_COHESION_SCALE * 1.0
	var m_fatigue := 1.0 - GameConstants.M_FATIGUE_MAX_PENALTY * 0.0

	return base_m * m_cohesion * m_fatigue


## 抑圧レベルに応じた基本係数
func _get_suppression_state_coefficient(suppression: float) -> float:
	if suppression >= GameConstants.SUPP_THRESHOLD_BROKEN:
		return GameConstants.M_SHOOTER_BROKEN
	elif suppression >= GameConstants.SUPP_THRESHOLD_PINNED:
		return GameConstants.M_SHOOTER_PINNED
	elif suppression >= GameConstants.SUPP_THRESHOLD_SUPPRESSED:
		return GameConstants.M_SHOOTER_SUPPRESSED
	else:
		return GameConstants.M_SHOOTER_NORMAL


# =============================================================================
# 遮蔽係数
# =============================================================================

## 直射遮蔽係数を取得
func get_cover_coefficient_df(terrain: GameEnums.TerrainType) -> float:
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


## 間接遮蔽係数を取得
func get_cover_coefficient_if(terrain: GameEnums.TerrainType) -> float:
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
# 目標回避係数
# =============================================================================

## 目標の移動状態に応じた回避係数
func get_target_evasion_coefficient(target: ElementData.ElementInstance) -> float:
	if target.is_moving:
		return GameConstants.M_EVASION_MOVING
	else:
		return GameConstants.M_EVASION_STATIONARY


# =============================================================================
# Strength影響係数
# =============================================================================

## Strengthによる火力倍率
func get_strength_fire_coefficient(element: ElementData.ElementInstance) -> float:
	if not element.element_type:
		return 1.0
	var strength_ratio := float(element.current_strength) / float(element.element_type.max_strength)
	return GameConstants.M_STRENGTH_FIRE_MIN + GameConstants.M_STRENGTH_FIRE_SCALE * strength_ratio


# =============================================================================
# 直射戦闘
# =============================================================================

## 直射効果を計算（1 tick分）
func calculate_direct_fire_effect(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	dt: float,
	t_los: float = 1.0,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN,
	is_entrenched: bool = false
) -> CombatEffectResult:
	var result := CombatEffectResult.new()

	# 射程チェック
	if not weapon.is_in_range(distance_m):
		return result

	# LoSチェック（T_LoS < 0.10 は射撃不可）
	if t_los < GameConstants.LOS_BLOCK_THRESHOLD:
		return result

	result.is_valid = true

	# 射程帯からレーティングを取得
	var target_class := _get_target_class(target)
	var lethality := weapon.get_lethality(distance_m, target_class)
	var supp_power := weapon.get_suppression_power(distance_m)

	# 各種係数
	var m_shooter := calculate_shooter_coefficient(shooter)
	var m_strength := get_strength_fire_coefficient(shooter)
	var m_visibility := _calculate_visibility_coefficient(t_los)
	var m_evasion := get_target_evasion_coefficient(target)
	var m_cover := get_cover_coefficient_df(target_terrain)
	var m_entrench := GameConstants.ENTRENCH_DF_MULT if is_entrenched else 1.0
	var m_vuln := _get_vulnerability_coefficient(target, weapon)

	# 抑圧増加
	# dSupp = K_DF_SUPP × (S/100) × M_shooter × M_visibility × M_evasion × M_cover × M_entrench × dt
	result.d_supp = GameConstants.K_DF_SUPP * (float(supp_power) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * dt

	# ダメージ（Strength減少）
	# dDmg = K_DF_DMG × (L/100) × M_shooter × M_visibility × M_evasion × M_cover × M_entrench × M_vuln × dt
	result.d_dmg = GameConstants.K_DF_DMG * (float(lethality) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * m_vuln * dt

	return result


## ターゲットクラスを取得
func _get_target_class(target: ElementData.ElementInstance) -> WeaponData.TargetClass:
	if not target.element_type:
		return WeaponData.TargetClass.SOFT

	match target.element_type.armor_class:
		0:
			return WeaponData.TargetClass.SOFT
		1:
			return WeaponData.TargetClass.LIGHT
		2, 3:
			return WeaponData.TargetClass.HEAVY
		_:
			return WeaponData.TargetClass.SOFT


## 視認・射撃困難係数を計算
func _calculate_visibility_coefficient(t_los: float) -> float:
	# 煙と森林の影響を統合したT_LoSから係数を算出
	# 簡易化：T_LoSをそのまま係数として使用（0.10-1.0をクランプ）
	return clampf(t_los, 0.25, 1.0)


## 脆弱性係数を取得
func _get_vulnerability_coefficient(
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType
) -> float:
	# v0.1では簡略化：threat_classとarmor_classで決定
	if not target.element_type:
		return 1.0

	var armor_class := target.element_type.armor_class

	match weapon.threat_class:
		WeaponData.ThreatClass.SMALL_ARMS:
			# 小火器は装甲に対して無効
			if armor_class >= 1:
				return 0.0
			return 1.0

		WeaponData.ThreatClass.AUTOCANNON:
			match armor_class:
				0: return 1.0
				1: return 0.8
				2: return 0.3
				_: return 0.1

		WeaponData.ThreatClass.HE_FRAG:
			match armor_class:
				0: return 1.0
				1: return 0.6
				_: return 0.2

		WeaponData.ThreatClass.AT:
			# ATは装甲に有効（貫徹判定は別途）
			return 1.0

		_:
			return 1.0


# =============================================================================
# 抑圧状態
# =============================================================================

## 抑圧値から状態を取得
func get_suppression_state(element: ElementData.ElementInstance) -> GameEnums.UnitState:
	if element.suppression >= GameConstants.SUPP_THRESHOLD_BROKEN:
		return GameEnums.UnitState.BROKEN
	elif element.suppression >= GameConstants.SUPP_THRESHOLD_PINNED:
		return GameEnums.UnitState.PINNED
	elif element.suppression >= GameConstants.SUPP_THRESHOLD_SUPPRESSED:
		return GameEnums.UnitState.SUPPRESSED
	else:
		return GameEnums.UnitState.ACTIVE


# =============================================================================
# 抑圧回復
# =============================================================================

## 抑圧回復量を計算
func calculate_suppression_recovery(
	element: ElementData.ElementInstance,
	is_under_fire: bool,
	comm_state: GameEnums.CommState,
	is_defending: bool,
	dt: float
) -> float:
	# 被弾中は回復なし
	if is_under_fire:
		return 0.0

	# 基本回復
	var base_recovery := GameConstants.SUPP_RECOVERY_BASE * dt

	# 通信状態補正
	var comm_mult := 1.0
	match comm_state:
		GameEnums.CommState.GOOD:
			comm_mult = GameConstants.COMM_RECOVERY_GOOD
		GameEnums.CommState.DEGRADED:
			comm_mult = GameConstants.COMM_RECOVERY_DEGRADED
		GameEnums.CommState.LOST:
			comm_mult = GameConstants.COMM_RECOVERY_LOST

	# 姿勢補正
	var posture_mult := GameConstants.POSTURE_RECOVERY_DEFEND if is_defending else GameConstants.POSTURE_RECOVERY_ATTACK

	return base_recovery * comm_mult * posture_mult


# =============================================================================
# 能力低下
# =============================================================================

## 抑圧による速度倍率を取得
func get_speed_multiplier(element: ElementData.ElementInstance) -> float:
	var state := get_suppression_state(element)
	match state:
		GameEnums.UnitState.BROKEN:
			return GameConstants.SPEED_MULT_BROKEN
		GameEnums.UnitState.PINNED:
			return GameConstants.SPEED_MULT_PINNED
		GameEnums.UnitState.SUPPRESSED:
			return GameConstants.SPEED_MULT_SUPPRESSED
		_:
			return 1.0


## 抑圧による制圧力倍率を取得
func get_capture_power_multiplier(element: ElementData.ElementInstance) -> float:
	var state := get_suppression_state(element)
	match state:
		GameEnums.UnitState.BROKEN:
			return GameConstants.CAP_MULT_BROKEN
		GameEnums.UnitState.PINNED:
			return GameConstants.CAP_MULT_PINNED
		GameEnums.UnitState.SUPPRESSED:
			return GameConstants.CAP_MULT_SUPPRESSED
		_:
			return 1.0


# =============================================================================
# 面制圧（Attack Area）
# =============================================================================

## 面制圧効果を計算
func calculate_area_attack_effect(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	target_dist_from_center: float,
	area_radius: float,
	distance_to_center_m: float,
	dt: float,
	t_los: float = 1.0,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN
) -> CombatEffectResult:
	# 基本の直射効果を計算
	var result := calculate_direct_fire_effect(
		shooter, target, weapon, distance_to_center_m, dt, t_los, target_terrain, false
	)

	if not result.is_valid:
		return result

	# 面制圧ペナルティ
	result.d_dmg *= GameConstants.AREA_ATTACK_DMG_MULT
	result.d_supp *= GameConstants.AREA_ATTACK_SUPP_MULT

	# 距離減衰
	var falloff := clampf(1.0 - target_dist_from_center / area_radius, 0.0, 1.0)
	result.d_dmg *= falloff
	result.d_supp *= falloff

	return result


# =============================================================================
# 間接戦闘（着弾効果）
# =============================================================================

## 着弾効果を計算（1発あたり）
func calculate_indirect_impact_effect(
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_from_impact: float,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN,
	is_entrenched: bool = false,
	dispersion_mode: int = 1  # 0=Column, 1=Deployed, 2=Dispersed
) -> CombatEffectResult:
	var result := CombatEffectResult.new()

	# 爆風半径
	var blast_radius := weapon.blast_radius_m if weapon.blast_radius_m > 0 else GameConstants.R_BLAST_M

	# 半径外は影響なし
	if distance_from_impact > blast_radius:
		return result

	result.is_valid = true

	# レーティング取得（間接はMid固定）
	var target_class := _get_target_class(target)
	var lethality := weapon.get_lethality(400.0, target_class)  # Mid距離固定
	var supp_power := weapon.get_suppression_power(400.0)

	# 距離減衰
	var falloff := clampf(1.0 - distance_from_impact / blast_radius, 0.0, 1.0)

	# 遮蔽係数
	var m_cover := get_cover_coefficient_if(target_terrain)
	var m_entrench := GameConstants.ENTRENCH_IF_MULT if is_entrenched else 1.0

	# 分散モード係数
	var m_dispersion := 1.0
	match dispersion_mode:
		0:  # Column
			m_dispersion = GameConstants.DISPERSION_IF_COLUMN
		1:  # Deployed
			m_dispersion = GameConstants.DISPERSION_IF_DEPLOYED
		2:  # Dispersed
			m_dispersion = GameConstants.DISPERSION_IF_DISPERSED

	var m_total := m_cover * m_entrench * m_dispersion
	var m_vuln := _get_indirect_vulnerability(target, weapon)

	# 抑圧増加
	result.d_supp = GameConstants.K_IF_SUPP * (float(supp_power) / 100.0) * falloff * m_total

	# ダメージ
	result.d_dmg = GameConstants.K_IF_DMG * (float(lethality) / 100.0) * falloff * m_total * m_vuln

	return result


## 間接火力に対する脆弱性
func _get_indirect_vulnerability(
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType
) -> float:
	if not target.element_type:
		return 1.0

	var armor_class := target.element_type.armor_class

	# BLAST_FRAGは装甲に弱い
	if weapon.mechanism == WeaponData.Mechanism.BLAST_FRAG:
		match armor_class:
			0: return 1.0
			1: return 0.4
			2: return 0.15
			_: return 0.05

	return 1.0


# =============================================================================
# 戦闘更新（メインループから呼ばれる）
# =============================================================================

## 要素にダメージを適用
func apply_damage(
	element: ElementData.ElementInstance,
	d_supp: float,
	d_dmg: float
) -> void:
	# 抑圧増加
	element.suppression = clampf(element.suppression + d_supp / 100.0, 0.0, 1.0)

	# Strength減少
	var strength_reduction := d_dmg
	element.current_strength = maxi(0, element.current_strength - int(strength_reduction))

	# 状態更新
	element.state = get_suppression_state(element)

	# 撃破判定
	if element.current_strength <= 0:
		element.state = GameEnums.UnitState.DESTROYED


## 抑圧回復を適用
func apply_suppression_recovery(
	element: ElementData.ElementInstance,
	is_under_fire: bool,
	comm_state: GameEnums.CommState,
	is_defending: bool,
	dt: float
) -> void:
	var recovery := calculate_suppression_recovery(
		element, is_under_fire, comm_state, is_defending, dt
	)

	element.suppression = maxf(0.0, element.suppression - recovery / 100.0)

	# 状態更新
	element.state = get_suppression_state(element)
