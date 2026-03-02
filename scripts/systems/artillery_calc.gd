class_name ArtilleryCalc
extends RefCounted

## ArtilleryCalc - 砲兵システムの純粋計算関数群
## Phase 4: 間接射撃計算の純粋関数化
##
## 責務:
## - 間接射撃の距離減衰計算
## - 分散モード係数
## - 間接火力脆弱性（ダメージ/抑圧）
## - 間接射撃のダメージ・抑圧計算
## - 展開/撤収進捗計算
##
## 仕様書: docs/indirect_fire_v0.2.md, docs/refactoring_pure_functions_v0.1.md


# =============================================================================
# 距離減衰計算
# =============================================================================

## 間接射撃の距離減衰を計算
## @param distance 着弾点からの距離 (m)
## @param blast_radius 爆風半径 (m)
## @param direct_hit_radius 直撃半径 (m) - この範囲内は最大効果
## @return 減衰係数 (0.0-1.0)
static func calc_indirect_falloff(
	distance: float,
	blast_radius: float,
	direct_hit_radius: float
) -> float:
	# 爆風半径外は影響なし
	if distance > blast_radius:
		return 0.0
	# 直撃半径内は最大効果
	if distance <= direct_hit_radius:
		return 1.0
	# 線形減衰
	return clampf(1.0 - distance / blast_radius, 0.0, 1.0)


# =============================================================================
# 分散モード係数
# =============================================================================

## 分散モード係数を取得
## @param dispersion_mode 分散モード (0=Column, 1=Deployed, 2=Dispersed)
## @return 分散係数 (密集ほど高い=被害増)
static func get_dispersion_modifier(dispersion_mode: int) -> float:
	match dispersion_mode:
		0:  # Column - 密集、被害大
			return GameConstants.DISPERSION_IF_COLUMN
		1:  # Deployed - 標準
			return GameConstants.DISPERSION_IF_DEPLOYED
		2:  # Dispersed - 分散、被害小
			return GameConstants.DISPERSION_IF_DISPERSED
		_:
			return 1.0


# =============================================================================
# 間接火力脆弱性（ダメージ）
# =============================================================================

## 間接火力に対するダメージ脆弱性を取得
## @param armor_class 装甲クラス (0=SOFT, 1=LIGHT, 2=MEDIUM, 3+=HEAVY)
## @param heavy_he_class 大口径HEクラス (0=NONE, 1=HEAVY_HE)
## @param is_direct_hit 直撃か（直撃半径内か）
## @return 脆弱性係数 (0.0-1.2)
static func get_indirect_vuln_dmg(
	armor_class: int,
	heavy_he_class: int,
	is_direct_hit: bool
) -> float:
	# 大口径HE（155mm/152mm等）は装甲にも効果がある
	if heavy_he_class == 1:  # HEAVY_HE
		if is_direct_hit:
			# 直撃時は高い効果
			match armor_class:
				0: return GameConstants.HEAVY_HE_VULN_DMG_SOFT_DIRECT
				1: return GameConstants.HEAVY_HE_VULN_DMG_LIGHT_DIRECT
				2: return GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_DIRECT
				_: return GameConstants.HEAVY_HE_VULN_DMG_HEAVY_DIRECT
		else:
			# 至近弾は低い効果
			match armor_class:
				0: return GameConstants.HEAVY_HE_VULN_DMG_SOFT_INDIRECT
				1: return GameConstants.HEAVY_HE_VULN_DMG_LIGHT_INDIRECT
				2: return GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_INDIRECT
				_: return GameConstants.HEAVY_HE_VULN_DMG_HEAVY_INDIRECT

	# 通常のBLAST_FRAGは装甲に弱い
	match armor_class:
		0: return 1.0    # SOFT
		1: return 0.4    # LIGHT
		2: return 0.15   # MEDIUM
		_: return 0.05   # HEAVY


# =============================================================================
# 間接火力脆弱性（抑圧）
# =============================================================================

## 間接火力に対する抑圧脆弱性を取得
## @param armor_class 装甲クラス (0=SOFT, 1=LIGHT, 2=MEDIUM, 3+=HEAVY)
## @param heavy_he_class 大口径HEクラス (0=NONE, 1=HEAVY_HE)
## @return 脆弱性係数 (0.1-1.0)
static func get_indirect_vuln_supp(
	armor_class: int,
	heavy_he_class: int
) -> float:
	# 大口径HEは装甲車両にも抑圧効果がある
	if heavy_he_class == 1:  # HEAVY_HE
		match armor_class:
			0: return GameConstants.HEAVY_HE_VULN_SUPP_SOFT
			1: return GameConstants.HEAVY_HE_VULN_SUPP_LIGHT
			2: return GameConstants.HEAVY_HE_VULN_SUPP_MEDIUM
			_: return GameConstants.HEAVY_HE_VULN_SUPP_HEAVY

	# 通常のBLAST_FRAGは装甲への抑圧効果が低い
	match armor_class:
		0: return 1.0   # SOFT
		1: return 0.5   # LIGHT
		2: return 0.2   # MEDIUM
		_: return 0.1   # HEAVY


# =============================================================================
# 間接射撃の抑圧計算
# =============================================================================

## 間接射撃の抑圧値を計算
## @param supp_power 抑圧力 (0-100)
## @param falloff 距離減衰 (0.0-1.0)
## @param m_total 総合係数 (遮蔽*塹壕*分散)
## @param m_vuln 脆弱性係数
## @return 抑圧増加値
static func calc_indirect_suppression(
	supp_power: float,
	falloff: float,
	m_total: float,
	m_vuln: float
) -> float:
	return GameConstants.K_IF_SUPP * (supp_power / 100.0) * falloff * m_total * m_vuln


# =============================================================================
# 間接射撃のダメージ計算
# =============================================================================

## 間接射撃のダメージを計算
## @param lethality 殺傷力 (0-100)
## @param falloff 距離減衰 (0.0-1.0)
## @param m_total 総合係数 (遮蔽*塹壕*分散)
## @param m_vuln 脆弱性係数
## @return ダメージ値
static func calc_indirect_damage(
	lethality: float,
	falloff: float,
	m_total: float,
	m_vuln: float
) -> float:
	return GameConstants.K_IF_DMG * (lethality / 100.0) * falloff * m_total * m_vuln


# =============================================================================
# 展開/撤収進捗計算
# =============================================================================

## 展開/撤収進捗を計算
## @param current_progress 現在の進捗 (0.0-1.0)
## @param delta_sec 経過秒数
## @param duration_sec 総所要時間
## @return 新しい進捗 (0.0-1.0)
static func calc_deploy_progress(
	current_progress: float,
	delta_sec: float,
	duration_sec: float
) -> float:
	if duration_sec <= 0:
		return 1.0
	return clampf(current_progress + delta_sec / duration_sec, 0.0, 1.0)
