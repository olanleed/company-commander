class_name CombatSystem
extends RefCounted

## 戦闘システム
## 仕様書: docs/combat_v0.1.md (v0.1R)
##
## 直射・間接の戦闘効果を計算する。
## VisionSystemのLoS情報と連携して動作。
##
## v0.1R変更点:
## - 抑圧と損耗の脆弱性分離 (vulnerability_dmg_vs / vulnerability_supp_vs)
## - 離散ヒットイベントモデル (p_hit = 1 - exp(-K × E))
## - 車両サブシステムHP (mobility_hp, firepower_hp, sensors_hp)
## - アスペクトアングル (Front/Side/Rear/Top)

# =============================================================================
# 定数参照
# =============================================================================

# GameConstantsを直接参照（エイリアスはGodot 4.6.1で非対応）

# =============================================================================
# 戦闘効果結果
# =============================================================================

class CombatEffectResult:
	var d_supp: float = 0.0    ## 抑圧増加量
	var d_dmg: float = 0.0     ## ダメージ（Strength減少量）- レガシー
	var is_valid: bool = false ## 射撃が成立したか


## v0.1R: 直射効果結果（離散ヒットモデル）
class DirectFireResultV01R:
	var d_supp: float = 0.0    ## 抑圧増加量
	var p_hit: float = 0.0     ## ヒット確率（1秒あたり）
	var exposure: float = 0.0  ## 期待危険度 E
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
		GameEnums.CommState.LINKED:
			comm_mult = GameConstants.COMM_RECOVERY_GOOD
		GameEnums.CommState.DEGRADED:
			comm_mult = GameConstants.COMM_RECOVERY_DEGRADED
		GameEnums.CommState.ISOLATED:
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
## d_supp: 抑圧増加量（0-1範囲、例: 0.05 = 5%増加）
## d_dmg: ダメージ量（Strength減少量、小数点以下は蓄積）
## current_tick: 現在のtick（破壊時刻記録用）
## threat_class: 脅威クラス（車両への小火器抑圧上限判定用、オプション）
func apply_damage(
	element: ElementData.ElementInstance,
	d_supp: float,
	d_dmg: float,
	current_tick: int = 0,
	threat_class: WeaponData.ThreatClass = WeaponData.ThreatClass.SMALL_ARMS
) -> void:
	# 既に破壊済みなら何もしない
	if element.is_destroyed:
		return

	# v0.1R: 車両への小火器抑圧上限（仕様書: max 20%）
	var effective_supp := d_supp
	if element.is_vehicle() and threat_class == WeaponData.ThreatClass.SMALL_ARMS:
		var current := element.suppression
		var new_supp := current + d_supp
		# 上限を超えないようにクランプ
		effective_supp = maxf(0.0, minf(d_supp, GameConstants.VEHICLE_SMALLARMS_SUPP_CAP - current))

	# 抑圧増加（d_suppは0-1範囲なのでそのまま加算）
	element.suppression = clampf(element.suppression + effective_supp, 0.0, 1.0)

	# Strength減少（小数点以下は蓄積し、1.0超過分を適用）
	element.accumulated_damage += d_dmg
	if element.accumulated_damage >= 1.0:
		var strength_reduction := int(element.accumulated_damage)
		element.accumulated_damage -= float(strength_reduction)
		element.current_strength = maxi(0, element.current_strength - strength_reduction)

	# 状態更新
	element.state = get_suppression_state(element)

	# 撃破判定
	if element.current_strength <= 0:
		_mark_destroyed(element, current_tick, false)


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


# =============================================================================
# v0.1R: 脆弱性（分離）
# =============================================================================

## v0.1R: 損耗脆弱性を取得
func get_vulnerability_dmg(
	target: ElementData.ElementInstance,
	threat_class: WeaponData.ThreatClass
) -> float:
	if not target.element_type:
		return 1.0

	var armor_class := target.element_type.armor_class

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

	# Heavy (armor_class >= 2)
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


## v0.1R: 抑圧脆弱性を取得
func get_vulnerability_supp(
	target: ElementData.ElementInstance,
	threat_class: WeaponData.ThreatClass
) -> float:
	if not target.element_type:
		return 1.0

	var armor_class := target.element_type.armor_class

	# Soft (armor_class = 0)
	if armor_class == 0:
		match threat_class:
			WeaponData.ThreatClass.SMALL_ARMS:
				return GameConstants.VULN_SOFT_SMALLARMS_SUPP
			WeaponData.ThreatClass.AUTOCANNON:
				return GameConstants.VULN_SOFT_AUTOCANNON_SUPP
			WeaponData.ThreatClass.HE_FRAG:
				return GameConstants.VULN_SOFT_HEFRAG_SUPP
			WeaponData.ThreatClass.AT:
				return GameConstants.VULN_SOFT_AT_SUPP
			_:
				return 1.0

	# Light (armor_class = 1)
	if armor_class == 1:
		match threat_class:
			WeaponData.ThreatClass.SMALL_ARMS:
				return GameConstants.VULN_LIGHT_SMALLARMS_SUPP
			WeaponData.ThreatClass.AUTOCANNON:
				return GameConstants.VULN_LIGHT_AUTOCANNON_SUPP
			WeaponData.ThreatClass.HE_FRAG:
				return GameConstants.VULN_LIGHT_HEFRAG_SUPP
			WeaponData.ThreatClass.AT:
				return GameConstants.VULN_LIGHT_AT_SUPP
			_:
				return 1.0

	# Heavy (armor_class >= 2)
	match threat_class:
		WeaponData.ThreatClass.SMALL_ARMS:
			return GameConstants.VULN_HEAVY_SMALLARMS_SUPP
		WeaponData.ThreatClass.AUTOCANNON:
			return GameConstants.VULN_HEAVY_AUTOCANNON_SUPP
		WeaponData.ThreatClass.HE_FRAG:
			return GameConstants.VULN_HEAVY_HEFRAG_SUPP
		WeaponData.ThreatClass.AT:
			return GameConstants.VULN_HEAVY_AT_SUPP
		_:
			return 1.0


# =============================================================================
# v0.1R: 離散ヒットイベントモデル
# =============================================================================

## v0.1R: ヒット確率を計算 (p_hit = 1 - exp(-K × E))
func calculate_hit_probability(exposure: float) -> float:
	if exposure <= 0.0:
		return 0.0
	return 1.0 - exp(-GameConstants.K_DF_HIT * exposure)


## v0.1R: 直射の期待危険度 E を計算
func calculate_exposure_df(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	t_los: float = 1.0,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN,
	is_entrenched: bool = false
) -> float:
	# 射程チェック
	if not weapon.is_in_range(distance_m):
		return 0.0

	# LoSチェック
	if t_los < GameConstants.LOS_BLOCK_THRESHOLD:
		return 0.0

	# 殺傷力レーティング
	var target_class := _get_target_class(target)
	var lethality := weapon.get_lethality(distance_m, target_class)

	# 各種係数
	var m_shooter := calculate_shooter_coefficient(shooter)
	var m_strength := get_strength_fire_coefficient(shooter)
	var m_visibility := _calculate_visibility_coefficient(t_los)
	var m_evasion := get_target_evasion_coefficient(target)
	var m_cover := get_cover_coefficient_df(target_terrain)
	var m_entrench := GameConstants.ENTRENCH_DF_MULT if is_entrenched else 1.0
	var m_vuln_dmg := get_vulnerability_dmg(target, weapon.threat_class)

	# E = (L/100) × M_shooter × M_visibility × M_evasion × M_cover × M_entrench × M_vuln_dmg
	return (float(lethality) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * m_vuln_dmg


## v0.1R: 直射効果を計算（離散ヒットモデル）
func calculate_direct_fire_effect_v01r(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	dt: float,
	t_los: float = 1.0,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN,
	is_entrenched: bool = false
) -> DirectFireResultV01R:
	var result := DirectFireResultV01R.new()

	# 射程チェック
	if not weapon.is_in_range(distance_m):
		return result

	# LoSチェック
	if t_los < GameConstants.LOS_BLOCK_THRESHOLD:
		return result

	result.is_valid = true

	# 抑圧レーティング
	var supp_power := weapon.get_suppression_power(distance_m)

	# 各種係数
	var m_shooter := calculate_shooter_coefficient(shooter)
	var m_strength := get_strength_fire_coefficient(shooter)
	var m_visibility := _calculate_visibility_coefficient(t_los)
	var m_evasion := get_target_evasion_coefficient(target)
	var m_cover := get_cover_coefficient_df(target_terrain)
	var m_entrench := GameConstants.ENTRENCH_DF_MULT if is_entrenched else 1.0
	var m_vuln_supp := get_vulnerability_supp(target, weapon.threat_class)

	# 抑圧増加（連続）
	# dSupp = K_DF_SUPP × (S/100) × M_shooter × ... × M_vuln_supp × dt
	result.d_supp = GameConstants.K_DF_SUPP * (float(supp_power) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * m_vuln_supp * dt

	# 期待危険度 E
	result.exposure = calculate_exposure_df(
		shooter, target, weapon, distance_m, t_los, target_terrain, is_entrenched
	)

	# ヒット確率（1秒あたり）→ dt秒あたりに調整
	var p_hit_1s := calculate_hit_probability(result.exposure)
	# dt秒でのヒット確率: p_hit_dt = 1 - (1 - p_hit_1s)^dt
	result.p_hit = 1.0 - pow(1.0 - p_hit_1s, dt)

	return result


## v0.1R: 装甲目標への直射効果を計算（ゾーン別装甲・貫徹判定含む）
## 仕様書: docs/damage_model_v0.1.md
func calculate_direct_fire_vs_armor(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	dt: float,
	t_los: float = 1.0,
	target_terrain: GameEnums.TerrainType = GameEnums.TerrainType.OPEN,
	is_entrenched: bool = false
) -> DirectFireResultV01R:
	var result := DirectFireResultV01R.new()

	# 射程チェック
	if not weapon.is_in_range(distance_m):
		return result

	# LoSチェック
	if t_los < GameConstants.LOS_BLOCK_THRESHOLD:
		return result

	result.is_valid = true

	# アスペクト（命中部位）を計算
	var aspect := calculate_aspect_v01r(
		shooter.position, target.position, target.facing
	)

	# 貫徹確率を取得
	var p_pen := get_penetration_probability(shooter, target, weapon, distance_m, aspect)

	# 抑圧レーティング
	var supp_power := weapon.get_suppression_power(distance_m)

	# 各種係数
	var m_shooter := calculate_shooter_coefficient(shooter)
	var m_strength := get_strength_fire_coefficient(shooter)
	var m_visibility := _calculate_visibility_coefficient(t_los)
	var m_evasion := get_target_evasion_coefficient(target)
	var m_cover := get_cover_coefficient_df(target_terrain)
	var m_entrench := GameConstants.ENTRENCH_DF_MULT if is_entrenched else 1.0
	var m_vuln_supp := get_vulnerability_supp(target, weapon.threat_class)
	var m_aspect := get_aspect_multiplier(target, aspect)

	# 抑圧増加（連続）- 貫徹に関係なく発生
	result.d_supp = GameConstants.K_DF_SUPP * (float(supp_power) / 100.0) * m_shooter * m_strength * m_visibility * m_evasion * m_cover * m_entrench * m_vuln_supp * dt

	# 期待危険度 E（貫徹確率 × アスペクト倍率を含む）
	var base_exposure := calculate_exposure_df(
		shooter, target, weapon, distance_m, t_los, target_terrain, is_entrenched
	)
	result.exposure = base_exposure * p_pen * m_aspect

	# ヒット確率（1秒あたり）→ dt秒あたりに調整
	var p_hit_1s := calculate_hit_probability(result.exposure)
	result.p_hit = 1.0 - pow(1.0 - p_hit_1s, dt)

	return result


# =============================================================================
# v0.1R: 車両サブシステム状態
# =============================================================================

## v0.1R: Mobility状態を取得
func get_mobility_state(element: ElementData.ElementInstance) -> GameEnums.VehicleMobilityState:
	if element.mobility_hp > GameConstants.VEHICLE_MOBILITY_DAMAGED_THRESHOLD:
		return GameEnums.VehicleMobilityState.NORMAL
	elif element.mobility_hp > GameConstants.VEHICLE_MOBILITY_CRITICAL_THRESHOLD:
		return GameEnums.VehicleMobilityState.DAMAGED
	elif element.mobility_hp > GameConstants.VEHICLE_MOBILITY_IMMOBILIZED_THRESHOLD:
		return GameEnums.VehicleMobilityState.CRITICAL
	else:
		return GameEnums.VehicleMobilityState.IMMOBILIZED


## v0.1R: Firepower状態を取得
func get_firepower_state(element: ElementData.ElementInstance) -> GameEnums.VehicleFirepowerState:
	if element.firepower_hp > GameConstants.VEHICLE_FIREPOWER_DAMAGED_THRESHOLD:
		return GameEnums.VehicleFirepowerState.NORMAL
	elif element.firepower_hp > GameConstants.VEHICLE_FIREPOWER_CRITICAL_THRESHOLD:
		return GameEnums.VehicleFirepowerState.DAMAGED
	elif element.firepower_hp > GameConstants.VEHICLE_FIREPOWER_DISABLED_THRESHOLD:
		return GameEnums.VehicleFirepowerState.CRITICAL
	else:
		return GameEnums.VehicleFirepowerState.WEAPON_DISABLED


## v0.1R: Sensors状態を取得
func get_sensors_state(element: ElementData.ElementInstance) -> GameEnums.VehicleSensorsState:
	if element.sensors_hp > GameConstants.VEHICLE_SENSORS_DAMAGED_THRESHOLD:
		return GameEnums.VehicleSensorsState.NORMAL
	elif element.sensors_hp > GameConstants.VEHICLE_SENSORS_CRITICAL_THRESHOLD:
		return GameEnums.VehicleSensorsState.DAMAGED
	elif element.sensors_hp > GameConstants.VEHICLE_SENSORS_DOWN_THRESHOLD:
		return GameEnums.VehicleSensorsState.CRITICAL
	else:
		return GameEnums.VehicleSensorsState.SENSORS_DOWN


## v0.1R: 車両の速度倍率を取得
func get_vehicle_speed_multiplier(element: ElementData.ElementInstance) -> float:
	var state := get_mobility_state(element)
	match state:
		GameEnums.VehicleMobilityState.NORMAL:
			return 1.0
		GameEnums.VehicleMobilityState.DAMAGED:
			return GameConstants.VEHICLE_MOBILITY_DAMAGED_MULT
		GameEnums.VehicleMobilityState.CRITICAL:
			return GameConstants.VEHICLE_MOBILITY_CRITICAL_MULT
		GameEnums.VehicleMobilityState.IMMOBILIZED:
			return GameConstants.VEHICLE_MOBILITY_IMMOBILIZED_MULT
		_:
			return 1.0


# =============================================================================
# v0.1R: アスペクトアングル
# =============================================================================

## v0.1R: アスペクトを計算
func calculate_aspect(
	shooter_pos: Vector2,
	target_pos: Vector2,
	target_facing: float
) -> WeaponData.ArmorZone:
	# 射手→目標ベクトル
	var to_target := (target_pos - shooter_pos).normalized()

	# 目標の facing方向（ラジアン）を単位ベクトルに
	var facing_dir := Vector2.from_angle(target_facing)

	# 目標から見た射手の方向
	var to_shooter := -to_target

	# facing_dir と to_shooter の角度差を計算
	var angle_diff: float = absf(facing_dir.angle_to(to_shooter))

	# 角度に応じてゾーンを決定
	# Front: ±45° (PI/4)
	# Side: ±45° ~ ±135° (PI/4 ~ 3PI/4)
	# Rear: ±135° ~ ±180° (3PI/4 ~ PI)
	if angle_diff <= PI / 4.0:
		return WeaponData.ArmorZone.FRONT
	elif angle_diff <= 3.0 * PI / 4.0:
		return WeaponData.ArmorZone.SIDE
	else:
		return WeaponData.ArmorZone.REAR


## v0.1R: 仕様書準拠のゾーン判定（±60°=FRONT, ±150°〜=REAR）
func calculate_aspect_v01r(
	shooter_pos: Vector2,
	target_pos: Vector2,
	target_facing: float
) -> WeaponData.ArmorZone:
	# 射手→目標ベクトル
	var to_target := (target_pos - shooter_pos).normalized()

	# 目標の facing方向（ラジアン）を単位ベクトルに
	var facing_dir := Vector2.from_angle(target_facing)

	# 目標から見た射手の方向
	var to_shooter := -to_target

	# facing_dir と to_shooter の角度差を計算
	var angle_diff: float = absf(facing_dir.angle_to(to_shooter))

	# 仕様書: |θ| ≤ 60° = FRONT, |θ| ≥ 150° = REAR, else = SIDE
	if angle_diff <= GameConstants.ZONE_FRONT_ANGLE_RAD:
		return WeaponData.ArmorZone.FRONT
	elif angle_diff >= GameConstants.ZONE_REAR_ANGLE_RAD:
		return WeaponData.ArmorZone.REAR
	else:
		return WeaponData.ArmorZone.SIDE


## v0.1R: 貫徹確率を計算
## p_pen = sigmoid((P - A) / 8)
func calculate_penetration_probability(
	penetration: int,
	armor: int
) -> float:
	var diff := float(penetration - armor)
	var x := diff / GameConstants.PENETRATION_SIGMOID_SCALE
	return 1.0 / (1.0 + exp(-x))


## v0.1R: 装甲目標に対する貫徹確率を取得
## 武器のpen_ke/pen_ceと目標のarmor_ke/armor_ceを比較
func get_penetration_probability(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	aspect: WeaponData.ArmorZone
) -> float:
	# 非装甲は貫徹判定なし（常に貫通）
	if not target.element_type or target.element_type.armor_class == 0:
		return 1.0

	# 武器メカニズムに応じた貫徹力と装甲を取得
	var penetration: int = 0
	var armor: int = 0

	match weapon.mechanism:
		WeaponData.Mechanism.KINETIC:
			penetration = weapon.get_pen_ke(distance_m)
			if aspect in target.element_type.armor_ke:
				armor = target.element_type.armor_ke[aspect]
		WeaponData.Mechanism.SHAPED_CHARGE:
			penetration = weapon.get_pen_ce(distance_m)
			if aspect in target.element_type.armor_ce:
				armor = target.element_type.armor_ce[aspect]
		WeaponData.Mechanism.SMALL_ARMS:
			# 小火器は装甲に対して貫通不可
			if target.element_type.armor_class >= 1:
				return 0.0
			return 1.0
		WeaponData.Mechanism.BLAST_FRAG:
			# HE/爆風は貫徹判定なし、脆弱性で対応
			return 1.0

	# 貫徹力が0なら貫通不可
	if penetration <= 0:
		return 0.0

	return calculate_penetration_probability(penetration, armor)


## v0.1R: アスペクト倍率を取得
func get_aspect_multiplier(
	target: ElementData.ElementInstance,
	aspect: WeaponData.ArmorZone
) -> float:
	if not target.element_type:
		return 1.0

	var armor_class := target.element_type.armor_class

	# Heavy (armor_class >= 2)
	if armor_class >= 2:
		match aspect:
			WeaponData.ArmorZone.FRONT:
				return GameConstants.ASPECT_HEAVY_FRONT
			WeaponData.ArmorZone.SIDE:
				return GameConstants.ASPECT_HEAVY_SIDE
			WeaponData.ArmorZone.REAR:
				return GameConstants.ASPECT_HEAVY_REAR
			WeaponData.ArmorZone.TOP:
				return GameConstants.ASPECT_HEAVY_TOP
			_:
				return 1.0

	# Light (armor_class == 1)
	if armor_class == 1:
		match aspect:
			WeaponData.ArmorZone.FRONT:
				return GameConstants.ASPECT_LIGHT_FRONT
			WeaponData.ArmorZone.SIDE:
				return GameConstants.ASPECT_LIGHT_SIDE
			WeaponData.ArmorZone.REAR:
				return GameConstants.ASPECT_LIGHT_REAR
			WeaponData.ArmorZone.TOP:
				return GameConstants.ASPECT_LIGHT_TOP
			_:
				return 1.0

	# Soft (armor_class == 0) - アスペクトは影響しない
	return 1.0


# =============================================================================
# v0.1R: 被害分布
# =============================================================================

## v0.1R: 被害カテゴリをロール
func roll_damage_category(exposure: float) -> GameEnums.DamageCategory:
	var minor_chance := GameConstants.DAMAGE_CAT_BASE_MINOR
	var major_chance := GameConstants.DAMAGE_CAT_BASE_MAJOR
	var critical_chance := GameConstants.DAMAGE_CAT_BASE_CRITICAL

	# Eによる調整
	if exposure >= 0.7:
		critical_chance += 0.02
		minor_chance -= 0.02
	elif exposure <= 0.2:
		major_chance -= 0.10
		minor_chance += 0.10

	var roll: float = randf()
	if roll < critical_chance:
		return GameEnums.DamageCategory.CRITICAL
	elif roll < critical_chance + major_chance:
		return GameEnums.DamageCategory.MAJOR
	else:
		return GameEnums.DamageCategory.MINOR


## v0.1R: Soft被害量を計算
func calculate_soft_damage(category: GameEnums.DamageCategory) -> float:
	match category:
		GameEnums.DamageCategory.MINOR:
			return randf_range(
				GameConstants.SOFT_DAMAGE_MINOR_MIN,
				GameConstants.SOFT_DAMAGE_MINOR_MAX
			)
		GameEnums.DamageCategory.MAJOR:
			return randf_range(
				GameConstants.SOFT_DAMAGE_MAJOR_MIN,
				GameConstants.SOFT_DAMAGE_MAJOR_MAX
			)
		GameEnums.DamageCategory.CRITICAL:
			return randf_range(
				GameConstants.SOFT_DAMAGE_CRITICAL_MIN,
				GameConstants.SOFT_DAMAGE_CRITICAL_MAX
			)
		_:
			return 1.0


# =============================================================================
# 破壊処理
# =============================================================================

## 要素を破壊状態にマーク
func _mark_destroyed(
	element: ElementData.ElementInstance,
	current_tick: int,
	is_catastrophic: bool
) -> void:
	element.state = GameEnums.UnitState.DESTROYED
	element.is_destroyed = true
	element.destroy_tick = current_tick
	element.catastrophic_kill = is_catastrophic
	element.current_strength = 0
	element.is_moving = false
	element.current_path.clear()

	print("[Combat] %s DESTROYED%s at tick %d" % [
		element.id,
		" (CATASTROPHIC)" if is_catastrophic else "",
		current_tick
	])


## 車両にダメージを適用（AT/重火器用）
## HITイベント発生時に被害カテゴリに基づいて1両撃破を判定
## Strength = 車両数（例: 4両小隊 → Strength=4）
func apply_vehicle_damage(
	element: ElementData.ElementInstance,
	threat_class: WeaponData.ThreatClass,
	exposure: float,
	current_tick: int
) -> void:
	# 既に破壊済みなら何もしない
	if element.is_destroyed:
		return

	# 車両でなければ通常ダメージ処理
	if not element.element_type or element.element_type.armor_class == 0:
		return

	# 被害カテゴリをロール
	var category := roll_damage_category(exposure)

	# 1両撃破かどうかを判定
	var vehicle_killed := false

	match category:
		GameEnums.DamageCategory.CRITICAL:
			# CRITICAL: 確実に1両撃破 + 追加でcatastrophic判定
			var catastrophic_roll := randf()
			if catastrophic_roll < GameConstants.VEHICLE_CRITICAL_CATASTROPHIC_CHANCE:
				# Catastrophic Kill: ユニット全体が即時破壊（弾薬庫誘爆・燃料火災等）
				print("[Combat] %s CATASTROPHIC KILL! Unit destroyed at tick %d" % [element.id, current_tick])
				_mark_destroyed(element, current_tick, true)
				return  # 即時破壊なので以降の処理をスキップ
			else:
				# 通常のCRITICAL: 1両撃破
				vehicle_killed = true
				print("[Combat] %s CRITICAL HIT (1 vehicle destroyed) at tick %d" % [element.id, current_tick])

		GameEnums.DamageCategory.MAJOR:
			# MAJOR: 高確率で1両撃破（80%）
			if randf() < 0.80:
				vehicle_killed = true
				print("[Combat] %s MAJOR HIT (1 vehicle destroyed) at tick %d" % [element.id, current_tick])
			else:
				# ダメージのみ（サブシステムにダメージ）
				var damage := randi_range(
					GameConstants.VEHICLE_DAMAGE_MAJOR_MIN,
					GameConstants.VEHICLE_DAMAGE_MAJOR_MAX
				)
				_distribute_subsystem_damage(element, damage, threat_class)
				print("[Combat] %s MAJOR HIT (subsystem damage) at tick %d" % [element.id, current_tick])

		GameEnums.DamageCategory.MINOR:
			# MINOR: 低確率で1両撃破（30%）、それ以外はサブシステムダメージ
			if randf() < 0.30:
				vehicle_killed = true
				print("[Combat] %s MINOR HIT (1 vehicle destroyed) at tick %d" % [element.id, current_tick])
			else:
				var damage := randi_range(
					GameConstants.VEHICLE_DAMAGE_MINOR_MIN,
					GameConstants.VEHICLE_DAMAGE_MINOR_MAX
				)
				_distribute_subsystem_damage(element, damage, threat_class)

	# 1両撃破時: Strength-1
	if vehicle_killed:
		element.current_strength = maxi(0, element.current_strength - 1)
		print("[Combat] %s: %d vehicles remaining" % [element.id, element.current_strength])

	# Strengthが0になったらユニット壊滅
	if element.current_strength <= 0:
		_mark_destroyed(element, current_tick, category == GameEnums.DamageCategory.CRITICAL)


## サブシステムにダメージを分配
func _distribute_subsystem_damage(
	element: ElementData.ElementInstance,
	damage: int,
	threat_class: WeaponData.ThreatClass
) -> void:
	# 脅威クラスによる分配比率を取得
	var dist: Array[float]
	match threat_class:
		WeaponData.ThreatClass.SMALL_ARMS:
			dist = GameConstants.SUBSYS_DIST_SMALLARMS.duplicate()
		WeaponData.ThreatClass.AUTOCANNON:
			dist = GameConstants.SUBSYS_DIST_AUTOCANNON.duplicate()
		WeaponData.ThreatClass.HE_FRAG:
			dist = GameConstants.SUBSYS_DIST_HEFRAG.duplicate()
		WeaponData.ThreatClass.AT:
			dist = GameConstants.SUBSYS_DIST_AT.duplicate()
		_:
			dist = [0.33, 0.33, 0.34]

	# 分配 [sensors, mobility, firepower]
	var sensors_dmg := int(float(damage) * dist[0])
	var mobility_dmg := int(float(damage) * dist[1])
	var firepower_dmg := int(float(damage) * dist[2])

	element.sensors_hp = maxi(0, element.sensors_hp - sensors_dmg)
	element.mobility_hp = maxi(0, element.mobility_hp - mobility_dmg)
	element.firepower_hp = maxi(0, element.firepower_hp - firepower_dmg)

	print("[Combat] %s subsystem damage: mob=%d fire=%d sens=%d (now %d/%d/%d)" % [
		element.id, mobility_dmg, firepower_dmg, sensors_dmg,
		element.mobility_hp, element.firepower_hp, element.sensors_hp
	])


# =============================================================================
# 武器選択システム
# =============================================================================

## ターゲットのクラスを取得
func get_target_class(target: ElementData.ElementInstance) -> WeaponData.TargetClass:
	if not target.element_type:
		return WeaponData.TargetClass.SOFT

	var armor_class := target.element_type.armor_class
	if armor_class >= 3:
		return WeaponData.TargetClass.HEAVY
	elif armor_class >= 1:
		return WeaponData.TargetClass.LIGHT
	else:
		return WeaponData.TargetClass.SOFT


## 射手の全武器から目標に対して最適な武器を選択
## 戻り値: 最適な武器、または利用可能な武器がなければnull
func select_best_weapon(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	distance_m: float,
	debug_log: bool = false
) -> WeaponData.WeaponType:
	if shooter.weapons.size() == 0:
		return shooter.primary_weapon  # フォールバック

	var target_class := get_target_class(target)
	var is_armored := target.is_vehicle()

	var best_weapon: WeaponData.WeaponType = null
	var best_score: float = -INF  # 負のスコアも考慮

	if debug_log:
		print("[WeaponSelect] %s vs %s (dist=%.1fm, armored=%s)" % [
			shooter.id, target.id, distance_m, is_armored
		])

	for weapon in shooter.weapons:
		# 射程外はスキップ
		if not weapon.is_in_range(distance_m):
			if debug_log:
				print("  [SKIP] %s: out of range (max=%.0fm)" % [weapon.id, weapon.max_range_m])
			continue

		var score := _calculate_weapon_score(weapon, target, target_class, distance_m, is_armored)

		if debug_log:
			print("  [EVAL] %s: score=%.1f (pref=%d, threat=%d)" % [
				weapon.id, score, weapon.preferred_target, weapon.threat_class
			])

		# 負のスコアはスキップ（完全に不適切な武器）
		if score < 0:
			if debug_log:
				print("  [SKIP] %s: negative score (ineffective)" % weapon.id)
			continue

		if score > best_score:
			best_score = score
			best_weapon = weapon

	# 有効な武器がない場合
	if best_weapon == null:
		# 装甲目標に対してはSMALL_ARMSをフォールバックとして使わない
		if is_armored:
			if debug_log:
				print("  [NO WEAPON] no effective weapon for armored target")
			return null
		# 非装甲目標にはprimary_weaponをフォールバック
		if debug_log:
			print("  [FALLBACK] using primary_weapon: %s" % (shooter.primary_weapon.id if shooter.primary_weapon else "NONE"))
		best_weapon = shooter.primary_weapon

	if debug_log and best_weapon:
		print("  [SELECTED] %s (score=%.1f)" % [best_weapon.id, best_score])

	return best_weapon


## 武器のスコアを計算（目標に対する有効性）
func _calculate_weapon_score(
	weapon: WeaponData.WeaponType,
	target: ElementData.ElementInstance,
	target_class: WeaponData.TargetClass,
	distance_m: float,
	is_armored: bool
) -> float:
	var score: float = 0.0

	# 基本殺傷力
	var lethality := weapon.get_lethality(distance_m, target_class)
	score += float(lethality)

	# 装甲目標に対する特別判定
	if is_armored:
		# 小火器は装甲目標に効果なし → 使用不可
		if weapon.mechanism == WeaponData.Mechanism.SMALL_ARMS:
			if target.element_type and target.element_type.armor_class >= 1:
				return -1000.0  # 絶対使わない

		# 対装甲武器なら大きなボーナス
		if weapon.preferred_target == WeaponData.PreferredTarget.ARMOR:
			score += 100.0  # 強いボーナス

		# 貫徹力を考慮
		var pen := 0
		if weapon.mechanism == WeaponData.Mechanism.KINETIC:
			pen = weapon.get_pen_ke(distance_m)
		elif weapon.mechanism == WeaponData.Mechanism.SHAPED_CHARGE:
			pen = weapon.get_pen_ce(distance_m)

		if pen > 0:
			score += float(pen) * 0.5
	else:
		# ソフトターゲット（歩兵など）への判定
		# 対装甲専用武器は歩兵には使わない（弾薬節約＆オーバーキル）
		if weapon.preferred_target == WeaponData.PreferredTarget.ARMOR:
			# AT専用武器は対歩兵に大きなペナルティ
			score -= 200.0
		elif weapon.preferred_target == WeaponData.PreferredTarget.SOFT:
			# 対歩兵優先武器にはボーナス
			score += 100.0
		elif weapon.preferred_target == WeaponData.PreferredTarget.ANY:
			# 汎用武器は対歩兵では避ける（主砲弾薬は貴重）
			# 特にATカテゴリの汎用武器は主砲なので使わない
			if weapon.threat_class == WeaponData.ThreatClass.AT:
				score -= 50.0

	# 抑圧力も考慮（対歩兵では重要）
	if not is_armored:
		var supp := weapon.get_suppression_power(distance_m)
		score += float(supp) * 0.3

	return score


## ユニットの武器切り替えログを出力（デバッグ用）
func log_weapon_switch(
	shooter: ElementData.ElementInstance,
	old_weapon: WeaponData.WeaponType,
	new_weapon: WeaponData.WeaponType,
	target: ElementData.ElementInstance
) -> void:
	if old_weapon == null or new_weapon == null:
		return
	if old_weapon.id == new_weapon.id:
		return

	var target_type := "SOFT"
	if target.is_vehicle():
		if target.element_type and target.element_type.armor_class >= 3:
			target_type = "HEAVY"
		else:
			target_type = "LIGHT"

	print("[Weapon] %s: %s -> %s (target %s is %s)" % [
		shooter.id, old_weapon.id, new_weapon.id, target.id, target_type
	])


# =============================================================================
# v0.2: 戦車戦モデル (Tank Combat Model)
# 先手必勝・アスペクト重視の離散ヒットモデル
# =============================================================================

## v0.2: 戦車交戦結果
class TankEngagementResult:
	var fired: bool = false         ## 発砲したか
	var hit: bool = false           ## 命中したか
	var aspect: GameEnums.ArmorAspect = GameEnums.ArmorAspect.FRONT  ## 命中部位
	var kill: bool = false          ## 撃破したか
	var mission_kill: bool = false  ## ミッションキルか
	var catastrophic: bool = false  ## 爆発炎上か
	var p_hit: float = 0.0          ## 命中確率（デバッグ用）
	var p_kill: float = 0.0         ## 撃破確率（デバッグ用）


## v0.2: 距離帯を取得
func get_range_band(distance_m: float) -> GameEnums.RangeBand:
	if distance_m <= GameConstants.TANK_RANGE_BAND_NEAR_M:
		return GameEnums.RangeBand.NEAR
	elif distance_m <= GameConstants.TANK_RANGE_BAND_MID_M:
		return GameEnums.RangeBand.MID
	else:
		return GameEnums.RangeBand.FAR


## v0.2: アスペクト（射撃者から見た目標の方向）を計算
func calculate_armor_aspect(
	shooter_pos: Vector2,
	target_pos: Vector2,
	target_facing: float
) -> GameEnums.ArmorAspect:
	# 射手→目標ベクトル
	var to_target := (target_pos - shooter_pos).normalized()

	# 目標の facing方向を単位ベクトルに
	var facing_dir := Vector2.from_angle(target_facing)

	# 目標から見た射手の方向
	var to_shooter := -to_target

	# facing_dir と to_shooter の角度差を計算
	var angle_diff: float = absf(facing_dir.angle_to(to_shooter))

	# 仕様書: |θ| ≤ 60° = FRONT, |θ| ≥ 150° = REAR, else = SIDE
	if angle_diff <= GameConstants.ZONE_FRONT_ANGLE_RAD:
		return GameEnums.ArmorAspect.FRONT
	elif angle_diff >= GameConstants.ZONE_REAR_ANGLE_RAD:
		return GameEnums.ArmorAspect.REAR
	else:
		return GameEnums.ArmorAspect.SIDE


## v0.2: 戦車砲命中確率を取得
func get_tank_hit_probability(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	range_band: GameEnums.RangeBand
) -> float:
	var shooter_moving := shooter.is_moving
	var target_moving := target.is_moving

	var p_hit: float

	if not shooter_moving and not target_moving:
		# 静止→静止
		match range_band:
			GameEnums.RangeBand.NEAR:
				p_hit = GameConstants.TANK_HIT_SS_NEAR
			GameEnums.RangeBand.MID:
				p_hit = GameConstants.TANK_HIT_SS_MID
			GameEnums.RangeBand.FAR:
				p_hit = GameConstants.TANK_HIT_SS_FAR
			_:
				p_hit = GameConstants.TANK_HIT_SS_MID
	elif not shooter_moving and target_moving:
		# 静止→移動
		match range_band:
			GameEnums.RangeBand.NEAR:
				p_hit = GameConstants.TANK_HIT_SM_NEAR
			GameEnums.RangeBand.MID:
				p_hit = GameConstants.TANK_HIT_SM_MID
			GameEnums.RangeBand.FAR:
				p_hit = GameConstants.TANK_HIT_SM_FAR
			_:
				p_hit = GameConstants.TANK_HIT_SM_MID
	elif shooter_moving and not target_moving:
		# 移動→静止
		match range_band:
			GameEnums.RangeBand.NEAR:
				p_hit = GameConstants.TANK_HIT_MS_NEAR
			GameEnums.RangeBand.MID:
				p_hit = GameConstants.TANK_HIT_MS_MID
			GameEnums.RangeBand.FAR:
				p_hit = GameConstants.TANK_HIT_MS_FAR
			_:
				p_hit = GameConstants.TANK_HIT_MS_MID
	else:
		# 移動→移動
		match range_band:
			GameEnums.RangeBand.NEAR:
				p_hit = GameConstants.TANK_HIT_MM_NEAR
			GameEnums.RangeBand.MID:
				p_hit = GameConstants.TANK_HIT_MM_MID
			GameEnums.RangeBand.FAR:
				p_hit = GameConstants.TANK_HIT_MM_FAR
			_:
				p_hit = GameConstants.TANK_HIT_MM_MID

	# 射手の抑圧による命中率低下
	var m_shooter := calculate_shooter_coefficient(shooter)
	p_hit *= m_shooter

	# センサー損傷による命中率低下
	if shooter.is_vehicle():
		var sensors_state := get_sensors_state(shooter)
		match sensors_state:
			GameEnums.VehicleSensorsState.DAMAGED:
				p_hit *= 0.85
			GameEnums.VehicleSensorsState.CRITICAL:
				p_hit *= 0.65
			GameEnums.VehicleSensorsState.SENSORS_DOWN:
				p_hit *= 0.40

	# 火器損傷による命中率低下
	if shooter.is_vehicle():
		var firepower_state := get_firepower_state(shooter)
		match firepower_state:
			GameEnums.VehicleFirepowerState.DAMAGED:
				p_hit *= 0.90
			GameEnums.VehicleFirepowerState.CRITICAL:
				p_hit *= 0.60
			GameEnums.VehicleFirepowerState.WEAPON_DISABLED:
				p_hit = 0.0  # 射撃不能

	return clampf(p_hit, 0.0, 1.0)


## v0.2: APFSDS（戦車砲）の撃破確率を取得
func get_apfsds_kill_probability(
	aspect: GameEnums.ArmorAspect,
	range_band: GameEnums.RangeBand
) -> Dictionary:
	var result := {"kill": 0.0, "mission_kill": 0.0}

	match aspect:
		GameEnums.ArmorAspect.FRONT:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.APFSDS_KILL_FRONT_NEAR
					result.mission_kill = GameConstants.APFSDS_MKILL_FRONT_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.APFSDS_KILL_FRONT_MID
					result.mission_kill = GameConstants.APFSDS_MKILL_FRONT_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.APFSDS_KILL_FRONT_FAR
					result.mission_kill = GameConstants.APFSDS_MKILL_FRONT_FAR

		GameEnums.ArmorAspect.SIDE:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.APFSDS_KILL_SIDE_NEAR
					result.mission_kill = GameConstants.APFSDS_MKILL_SIDE_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.APFSDS_KILL_SIDE_MID
					result.mission_kill = GameConstants.APFSDS_MKILL_SIDE_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.APFSDS_KILL_SIDE_FAR
					result.mission_kill = GameConstants.APFSDS_MKILL_SIDE_FAR

		GameEnums.ArmorAspect.REAR:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.APFSDS_KILL_REAR_NEAR
					result.mission_kill = GameConstants.APFSDS_MKILL_REAR_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.APFSDS_KILL_REAR_MID
					result.mission_kill = GameConstants.APFSDS_MKILL_REAR_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.APFSDS_KILL_REAR_FAR
					result.mission_kill = GameConstants.APFSDS_MKILL_REAR_FAR

	return result


## v0.2: HEAT/RPGの撃破確率を取得
func get_heat_kill_probability(
	aspect: GameEnums.ArmorAspect,
	range_band: GameEnums.RangeBand
) -> Dictionary:
	var result := {"kill": 0.0, "mission_kill": 0.0}

	match aspect:
		GameEnums.ArmorAspect.FRONT:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.HEAT_KILL_FRONT_NEAR
					result.mission_kill = GameConstants.HEAT_MKILL_FRONT_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.HEAT_KILL_FRONT_MID
					result.mission_kill = GameConstants.HEAT_MKILL_FRONT_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.HEAT_KILL_FRONT_FAR
					result.mission_kill = GameConstants.HEAT_MKILL_FRONT_FAR

		GameEnums.ArmorAspect.SIDE:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.HEAT_KILL_SIDE_NEAR
					result.mission_kill = GameConstants.HEAT_MKILL_SIDE_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.HEAT_KILL_SIDE_MID
					result.mission_kill = GameConstants.HEAT_MKILL_SIDE_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.HEAT_KILL_SIDE_FAR
					result.mission_kill = GameConstants.HEAT_MKILL_SIDE_FAR

		GameEnums.ArmorAspect.REAR:
			match range_band:
				GameEnums.RangeBand.NEAR:
					result.kill = GameConstants.HEAT_KILL_REAR_NEAR
					result.mission_kill = GameConstants.HEAT_MKILL_REAR_NEAR
				GameEnums.RangeBand.MID:
					result.kill = GameConstants.HEAT_KILL_REAR_MID
					result.mission_kill = GameConstants.HEAT_MKILL_REAR_MID
				GameEnums.RangeBand.FAR:
					result.kill = GameConstants.HEAT_KILL_REAR_FAR
					result.mission_kill = GameConstants.HEAT_MKILL_REAR_FAR

	return result


## v0.2: 戦車交戦を処理（離散発砲モデル）
## 重装甲同士の交戦で呼ばれる。発砲→命中→撃破判定を行う
## **注意**: この関数はダメージを適用しない。呼び出し側でapply_tank_damage_resultを使用すること。
## 遅延ダメージモデル: ProjectileManagerで砲弾を飛ばし、着弾時にダメージを適用する。
func process_tank_engagement(
	shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType,
	distance_m: float,
	current_tick: int
) -> TankEngagementResult:
	var result := TankEngagementResult.new()

	# 発砲可能かチェック（リロード時間）
	if not _can_fire_tank_gun(shooter, current_tick):
		return result

	# 発砲をマーク
	result.fired = true
	shooter.last_fire_tick = current_tick

	# 距離帯
	var range_band := get_range_band(distance_m)

	# アスペクト（命中部位）
	result.aspect = calculate_armor_aspect(
		shooter.position, target.position, target.facing
	)

	# 命中判定
	var p_hit := get_tank_hit_probability(shooter, target, range_band)
	result.p_hit = p_hit

	if randf() > p_hit:
		# ミス
		print("[TankCombat] %s FIRED at %s (%.0fm, %s): MISS (p_hit=%.1f%%)" % [
			shooter.id, target.id, distance_m,
			_aspect_to_string(result.aspect), p_hit * 100.0
		])
		return result

	result.hit = true

	# 撃破確率テーブルを取得
	var kill_table: Dictionary
	match weapon.mechanism:
		WeaponData.Mechanism.KINETIC:
			kill_table = get_apfsds_kill_probability(result.aspect, range_band)
		WeaponData.Mechanism.SHAPED_CHARGE:
			kill_table = get_heat_kill_probability(result.aspect, range_band)
		_:
			# その他の武器は旧モデルにフォールバック
			return result

	result.p_kill = kill_table.kill

	# 撃破判定（ダメージ適用は行わない、結果のみ記録）
	var damage_roll := randf()
	if damage_roll < kill_table.kill:
		# Kill
		result.kill = true
		# Catastrophic判定
		if randf() < GameConstants.TANK_CATASTROPHIC_CHANCE:
			result.catastrophic = true

	elif damage_roll < kill_table.kill + kill_table.mission_kill:
		# Mission Kill
		result.mission_kill = true

	# ログは着弾時に出力するため、ここでは発砲ログのみ
	print("[TankCombat] %s FIRED at %s (%.0fm, %s, p_hit=%.1f%%)" % [
		shooter.id, target.id, distance_m,
		_aspect_to_string(result.aspect), p_hit * 100.0
	])

	return result


## v0.2: 戦車ダメージ結果を適用（着弾時に呼ばれる）
## Main.gdがprojectile_impactシグナルを受け取り、targetを解決してから呼び出す
func apply_tank_damage_result(
	target: ElementData.ElementInstance,
	damage_info: Dictionary,
	current_tick: int
) -> void:
	if not target:
		print("[TankCombat] WARNING: Target is null for delayed damage")
		return

	var hit: bool = damage_info.get("hit", false)
	var kill: bool = damage_info.get("kill", false)
	var mission_kill: bool = damage_info.get("mission_kill", false)
	var catastrophic: bool = damage_info.get("catastrophic", false)
	var aspect: int = damage_info.get("aspect", GameEnums.ArmorAspect.FRONT)
	var shooter_id: String = damage_info.get("shooter_id", "")
	var p_kill: float = damage_info.get("p_kill", 0.0)
	var threat_class: int = damage_info.get("threat_class", WeaponData.ThreatClass.AT)

	if not hit:
		# ミス（既にログは出力済み）
		return

	if kill:
		# Kill
		_apply_tank_kill(target, current_tick, catastrophic)
		print("[TankCombat] %s -> %s IMPACT (%s): %s (p_kill=%.1f%%)" % [
			shooter_id, target.id,
			_aspect_to_string(aspect),
			"CATASTROPHIC KILL" if catastrophic else "KILL",
			p_kill * 100.0
		])

	elif mission_kill:
		# Mission Kill
		_apply_mission_kill(target, threat_class)
		print("[TankCombat] %s -> %s IMPACT (%s): MISSION KILL" % [
			shooter_id, target.id,
			_aspect_to_string(aspect)
		])

	else:
		# No Effect（貫通失敗）
		print("[TankCombat] %s -> %s IMPACT (%s): NO EFFECT (armor held)" % [
			shooter_id, target.id,
			_aspect_to_string(aspect)
		])


## v0.2: 砲発射可能かチェック
func _can_fire_tank_gun(shooter: ElementData.ElementInstance, current_tick: int) -> bool:
	# 火器損傷チェック
	if shooter.is_vehicle():
		var firepower_state := get_firepower_state(shooter)
		if firepower_state == GameEnums.VehicleFirepowerState.WEAPON_DISABLED:
			return false

	# 初回射撃は即座に許可（last_fire_tick = -1）
	if shooter.last_fire_tick < 0:
		return true

	# リロード時間チェック
	var ticks_since_last_fire := current_tick - shooter.last_fire_tick
	var reload_ticks := int(GameConstants.TANK_GUN_RELOAD_TIME * GameConstants.SIM_HZ)

	var can_fire := ticks_since_last_fire >= reload_ticks
	if not can_fire and current_tick % 50 == 0:
		print("[TankCombat] %s: RELOADING (%d/%d ticks)" % [
			shooter.id, ticks_since_last_fire, reload_ticks
		])
	return can_fire


## v0.2: 戦車撃破を適用
func _apply_tank_kill(
	target: ElementData.ElementInstance,
	current_tick: int,
	is_catastrophic: bool
) -> void:
	# 1両撃破
	target.current_strength = maxi(0, target.current_strength - 1)

	print("[TankCombat] %s: %d vehicles remaining" % [target.id, target.current_strength])

	# Strengthが0になったらユニット壊滅
	if target.current_strength <= 0:
		_mark_destroyed(target, current_tick, is_catastrophic)


## v0.2: ミッションキルを適用
func _apply_mission_kill(
	target: ElementData.ElementInstance,
	_threat_class: WeaponData.ThreatClass
) -> void:
	# ランダムでmobilityかfirepowerを0に
	if randf() < 0.5:
		target.mobility_hp = 0
		print("[TankCombat] %s: IMMOBILIZED (mobility_hp=0)" % target.id)
	else:
		target.firepower_hp = 0
		print("[TankCombat] %s: WEAPON DISABLED (firepower_hp=0)" % target.id)


## v0.2: アスペクトを文字列に変換（ログ用）
func _aspect_to_string(aspect: GameEnums.ArmorAspect) -> String:
	match aspect:
		GameEnums.ArmorAspect.FRONT:
			return "FRONT"
		GameEnums.ArmorAspect.SIDE:
			return "SIDE"
		GameEnums.ArmorAspect.REAR:
			return "REAR"
		_:
			return "UNKNOWN"


## v0.2: 重装甲目標かどうかを判定
func is_heavy_armor(element: ElementData.ElementInstance) -> bool:
	if not element.element_type:
		return false
	return element.element_type.armor_class >= 3


## v0.2: 戦車戦で処理すべきかを判定
## 目標が重装甲、武器がAT（KINETIC or SHAPED_CHARGE）
func should_use_tank_combat(
	_shooter: ElementData.ElementInstance,
	target: ElementData.ElementInstance,
	weapon: WeaponData.WeaponType
) -> bool:
	# 目標が重装甲でなければ通常モデル
	if not is_heavy_armor(target):
		return false

	# 武器がAT系でなければ通常モデル
	if weapon.mechanism != WeaponData.Mechanism.KINETIC and \
	   weapon.mechanism != WeaponData.Mechanism.SHAPED_CHARGE:
		return false

	# 武器がAT脅威クラスでなければ通常モデル
	if weapon.threat_class != WeaponData.ThreatClass.AT:
		return false

	return true
