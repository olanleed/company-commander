extends GutTest

## ArtilleryCalc純粋関数のユニットテスト
## Phase 4: 砲兵システム純粋関数化
##
## テスト対象:
## - calc_indirect_falloff: 距離減衰計算
## - get_dispersion_modifier: 分散モード係数
## - get_indirect_vuln_dmg: 間接火力ダメージ脆弱性
## - get_indirect_vuln_supp: 間接火力抑圧脆弱性
## - calc_indirect_suppression: 間接射撃抑圧値計算
## - calc_indirect_damage: 間接射撃ダメージ計算
## - calc_deploy_progress: 展開/撤収進捗計算

const AC = preload("res://scripts/systems/artillery_calc.gd")


# =============================================================================
# calc_indirect_falloff - 距離減衰計算
# =============================================================================

func test_falloff_at_impact_point() -> void:
	# 着弾点（距離0）は最大効果
	var result := AC.calc_indirect_falloff(0.0, 50.0, 5.0)
	assert_eq(result, 1.0, "着弾点では最大効果(1.0)")


func test_falloff_within_direct_hit_radius() -> void:
	# 直撃半径内は最大効果
	var result := AC.calc_indirect_falloff(3.0, 50.0, 5.0)
	assert_eq(result, 1.0, "直撃半径内(3m < 5m)は最大効果")


func test_falloff_at_direct_hit_boundary() -> void:
	# 直撃半径境界は最大効果
	var result := AC.calc_indirect_falloff(5.0, 50.0, 5.0)
	assert_eq(result, 1.0, "直撃半径境界は最大効果")


func test_falloff_at_blast_radius_boundary() -> void:
	# 爆風半径境界は効果ゼロ
	var result := AC.calc_indirect_falloff(50.0, 50.0, 5.0)
	assert_eq(result, 0.0, "爆風半径境界(50m)は効果ゼロ")


func test_falloff_outside_blast_radius() -> void:
	# 爆風半径外は効果なし
	var result := AC.calc_indirect_falloff(60.0, 50.0, 5.0)
	assert_eq(result, 0.0, "爆風半径外(60m > 50m)は効果なし")


func test_falloff_linear_decay_mid_point() -> void:
	# 中間距離での線形減衰確認（25m = 半分）
	var result := AC.calc_indirect_falloff(25.0, 50.0, 0.0)
	assert_almost_eq(result, 0.5, 0.01, "中間距離(25m/50m)で約50%減衰")


# =============================================================================
# get_dispersion_modifier - 分散モード係数
# =============================================================================

func test_dispersion_column() -> void:
	var result := AC.get_dispersion_modifier(0)
	assert_eq(result, GameConstants.DISPERSION_IF_COLUMN, "縦隊は最大被害(1.3)")


func test_dispersion_deployed() -> void:
	var result := AC.get_dispersion_modifier(1)
	assert_eq(result, GameConstants.DISPERSION_IF_DEPLOYED, "展開は標準(1.0)")


func test_dispersion_dispersed() -> void:
	var result := AC.get_dispersion_modifier(2)
	assert_eq(result, GameConstants.DISPERSION_IF_DISPERSED, "分散は軽減(0.7)")


func test_dispersion_ordering() -> void:
	# 密集 > 展開 > 分散（被害の大きさ順）
	var column := AC.get_dispersion_modifier(0)
	var deployed := AC.get_dispersion_modifier(1)
	var dispersed := AC.get_dispersion_modifier(2)
	assert_gt(column, deployed, "縦隊 > 展開")
	assert_gt(deployed, dispersed, "展開 > 分散")


# =============================================================================
# get_indirect_vuln_dmg - 間接火力ダメージ脆弱性
# =============================================================================

## 通常HE (heavy_he_class = 0) のテスト

func test_vuln_dmg_normal_he_soft() -> void:
	# ソフトスキンは通常HEに脆弱
	var result := AC.get_indirect_vuln_dmg(0, 0, false)
	assert_eq(result, 1.0, "ソフトスキンは通常HEに完全脆弱")


func test_vuln_dmg_normal_he_light() -> void:
	# 軽装甲は通常HEにやや抵抗
	var result := AC.get_indirect_vuln_dmg(1, 0, false)
	assert_eq(result, 0.4, "軽装甲は通常HEに40%脆弱")


func test_vuln_dmg_normal_he_medium() -> void:
	# 中装甲は通常HEに強い抵抗
	var result := AC.get_indirect_vuln_dmg(2, 0, false)
	assert_eq(result, 0.15, "中装甲は通常HEに15%脆弱")


func test_vuln_dmg_normal_he_heavy() -> void:
	# 重装甲は通常HEにほぼ耐える
	var result := AC.get_indirect_vuln_dmg(3, 0, false)
	assert_eq(result, 0.05, "重装甲は通常HEに5%脆弱")


## 大口径HE (heavy_he_class = 1) 直撃テスト

func test_vuln_dmg_heavy_he_soft_direct() -> void:
	var result := AC.get_indirect_vuln_dmg(0, 1, true)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_SOFT_DIRECT, "ソフトスキンへの大口径HE直撃")


func test_vuln_dmg_heavy_he_light_direct() -> void:
	var result := AC.get_indirect_vuln_dmg(1, 1, true)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_LIGHT_DIRECT, "軽装甲への大口径HE直撃")


func test_vuln_dmg_heavy_he_medium_direct() -> void:
	var result := AC.get_indirect_vuln_dmg(2, 1, true)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_DIRECT, "中装甲への大口径HE直撃")


func test_vuln_dmg_heavy_he_heavy_direct() -> void:
	var result := AC.get_indirect_vuln_dmg(3, 1, true)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_HEAVY_DIRECT, "重装甲への大口径HE直撃")


## 大口径HE (heavy_he_class = 1) 至近弾テスト

func test_vuln_dmg_heavy_he_soft_indirect() -> void:
	var result := AC.get_indirect_vuln_dmg(0, 1, false)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_SOFT_INDIRECT, "ソフトスキンへの大口径HE至近弾")


func test_vuln_dmg_heavy_he_light_indirect() -> void:
	var result := AC.get_indirect_vuln_dmg(1, 1, false)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_LIGHT_INDIRECT, "軽装甲への大口径HE至近弾")


func test_vuln_dmg_heavy_he_medium_indirect() -> void:
	var result := AC.get_indirect_vuln_dmg(2, 1, false)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_INDIRECT, "中装甲への大口径HE至近弾")


func test_vuln_dmg_heavy_he_heavy_indirect() -> void:
	var result := AC.get_indirect_vuln_dmg(3, 1, false)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_DMG_HEAVY_INDIRECT, "重装甲への大口径HE至近弾")


# =============================================================================
# get_indirect_vuln_supp - 間接火力抑圧脆弱性
# =============================================================================

## 通常HE抑圧テスト

func test_vuln_supp_normal_he_soft() -> void:
	var result := AC.get_indirect_vuln_supp(0, 0)
	assert_eq(result, 1.0, "ソフトスキンは通常HE抑圧に完全脆弱")


func test_vuln_supp_normal_he_light() -> void:
	var result := AC.get_indirect_vuln_supp(1, 0)
	assert_eq(result, 0.5, "軽装甲は通常HE抑圧に50%脆弱")


func test_vuln_supp_normal_he_medium() -> void:
	var result := AC.get_indirect_vuln_supp(2, 0)
	assert_eq(result, 0.2, "中装甲は通常HE抑圧に20%脆弱")


func test_vuln_supp_normal_he_heavy() -> void:
	var result := AC.get_indirect_vuln_supp(3, 0)
	assert_eq(result, 0.1, "重装甲は通常HE抑圧に10%脆弱")


## 大口径HE抑圧テスト

func test_vuln_supp_heavy_he_soft() -> void:
	var result := AC.get_indirect_vuln_supp(0, 1)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_SUPP_SOFT, "ソフトスキンへの大口径HE抑圧")


func test_vuln_supp_heavy_he_light() -> void:
	var result := AC.get_indirect_vuln_supp(1, 1)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_SUPP_LIGHT, "軽装甲への大口径HE抑圧")


func test_vuln_supp_heavy_he_medium() -> void:
	var result := AC.get_indirect_vuln_supp(2, 1)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_SUPP_MEDIUM, "中装甲への大口径HE抑圧")


func test_vuln_supp_heavy_he_heavy() -> void:
	var result := AC.get_indirect_vuln_supp(3, 1)
	assert_eq(result, GameConstants.HEAVY_HE_VULN_SUPP_HEAVY, "重装甲への大口径HE抑圧")


# =============================================================================
# calc_indirect_suppression - 間接射撃抑圧値計算
# =============================================================================

func test_indirect_supp_full_effect() -> void:
	# 最大効果：supp_power=100, falloff=1.0, m_total=1.0, m_vuln=1.0
	var result := AC.calc_indirect_suppression(100.0, 1.0, 1.0, 1.0)
	var expected := GameConstants.K_IF_SUPP * 1.0 * 1.0 * 1.0 * 1.0
	assert_almost_eq(result, expected, 0.001, "最大効果の抑圧計算")


func test_indirect_supp_with_falloff() -> void:
	# 距離減衰50%適用
	var result := AC.calc_indirect_suppression(100.0, 0.5, 1.0, 1.0)
	var expected := GameConstants.K_IF_SUPP * 1.0 * 0.5 * 1.0 * 1.0
	assert_almost_eq(result, expected, 0.001, "50%減衰での抑圧計算")


func test_indirect_supp_with_cover() -> void:
	# 遮蔽係数0.5適用
	var result := AC.calc_indirect_suppression(100.0, 1.0, 0.5, 1.0)
	var expected := GameConstants.K_IF_SUPP * 1.0 * 1.0 * 0.5 * 1.0
	assert_almost_eq(result, expected, 0.001, "遮蔽50%での抑圧計算")


func test_indirect_supp_with_vuln() -> void:
	# 脆弱性係数0.3（装甲車両）適用
	var result := AC.calc_indirect_suppression(100.0, 1.0, 1.0, 0.3)
	var expected := GameConstants.K_IF_SUPP * 1.0 * 1.0 * 1.0 * 0.3
	assert_almost_eq(result, expected, 0.001, "装甲車両への抑圧計算")


func test_indirect_supp_combined() -> void:
	# 複合条件：supp=70, falloff=0.8, m_total=0.6, m_vuln=0.5
	var result := AC.calc_indirect_suppression(70.0, 0.8, 0.6, 0.5)
	var expected := GameConstants.K_IF_SUPP * 0.7 * 0.8 * 0.6 * 0.5
	assert_almost_eq(result, expected, 0.001, "複合条件での抑圧計算")


# =============================================================================
# calc_indirect_damage - 間接射撃ダメージ計算
# =============================================================================

func test_indirect_dmg_full_effect() -> void:
	# 最大効果
	var result := AC.calc_indirect_damage(100.0, 1.0, 1.0, 1.0)
	var expected := GameConstants.K_IF_DMG * 1.0 * 1.0 * 1.0 * 1.0
	assert_almost_eq(result, expected, 0.001, "最大効果のダメージ計算")


func test_indirect_dmg_with_falloff() -> void:
	# 距離減衰50%適用
	var result := AC.calc_indirect_damage(100.0, 0.5, 1.0, 1.0)
	var expected := GameConstants.K_IF_DMG * 1.0 * 0.5 * 1.0 * 1.0
	assert_almost_eq(result, expected, 0.001, "50%減衰でのダメージ計算")


func test_indirect_dmg_with_entrench() -> void:
	# 塹壕効果（m_total経由で0.4）
	var result := AC.calc_indirect_damage(100.0, 1.0, 0.4, 1.0)
	var expected := GameConstants.K_IF_DMG * 1.0 * 1.0 * 0.4 * 1.0
	assert_almost_eq(result, expected, 0.001, "塹壕でのダメージ軽減")


func test_indirect_dmg_against_armor() -> void:
	# 装甲車両（m_vuln=0.1）
	var result := AC.calc_indirect_damage(100.0, 1.0, 1.0, 0.1)
	var expected := GameConstants.K_IF_DMG * 1.0 * 1.0 * 1.0 * 0.1
	assert_almost_eq(result, expected, 0.001, "重装甲へのダメージ計算")


func test_indirect_dmg_combined() -> void:
	# 複合条件：lethality=80, falloff=0.7, m_total=0.5, m_vuln=0.8
	var result := AC.calc_indirect_damage(80.0, 0.7, 0.5, 0.8)
	var expected := GameConstants.K_IF_DMG * 0.8 * 0.7 * 0.5 * 0.8
	assert_almost_eq(result, expected, 0.001, "複合条件でのダメージ計算")


# =============================================================================
# calc_deploy_progress - 展開/撤収進捗計算
# =============================================================================

func test_deploy_progress_start() -> void:
	# 開始から5秒経過（30秒中）
	var result := AC.calc_deploy_progress(0.0, 5.0, 30.0)
	assert_almost_eq(result, 5.0 / 30.0, 0.001, "5秒/30秒で約16.7%進捗")


func test_deploy_progress_mid() -> void:
	# 50%から10秒経過（30秒中）
	var result := AC.calc_deploy_progress(0.5, 10.0, 30.0)
	var expected := clampf(0.5 + 10.0 / 30.0, 0.0, 1.0)
	assert_almost_eq(result, expected, 0.001, "50%+33%で約83%進捗")


func test_deploy_progress_complete() -> void:
	# 完了を超える場合はクランプ
	var result := AC.calc_deploy_progress(0.9, 10.0, 30.0)
	assert_eq(result, 1.0, "1.0を超えないようにクランプ")


func test_deploy_progress_zero_duration() -> void:
	# 所要時間0の場合は即完了
	var result := AC.calc_deploy_progress(0.0, 5.0, 0.0)
	assert_eq(result, 1.0, "所要時間0は即完了")
