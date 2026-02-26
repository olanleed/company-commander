class_name AmmunitionData
extends RefCounted

## 弾種データモデル
## docs/weapons_tree/ に基づく弾種の抽象化
##
## RHA換算スケール: 100 = 500mm RHA

# =============================================================================
# 弾種タイプ
# =============================================================================

enum AmmoType {
	## 戦車砲 - APFSDS (Armor Piercing Fin Stabilized Discarding Sabot)
	APFSDS_120MM,      ## NATO 120mm滑腔砲
	APFSDS_125MM,      ## ロシア 125mm滑腔砲
	APFSDS_105MM,      ## 軽戦車/旧世代 105mmライフル砲

	## 戦車砲 - HEAT (High Explosive Anti Tank)
	HEAT_120MM,        ## 120mm HEAT
	HEAT_125MM,        ## 125mm HEAT

	## 戦車砲 - HE-MP (High Explosive Multi Purpose)
	HE_MP_120MM,       ## 120mm HE-MP/HEAT-MP
	HE_MP_125MM,       ## 125mm HE-MP

	## 機関砲 - AP/APDS (Armor Piercing Discarding Sabot)
	APDS_30MM,         ## 30mm APDS (BMP-2, BTR-82A)
	APDS_25MM,         ## 25mm APDS (M242 Bushmaster)
	APDS_20MM,         ## 20mm APDS
	APDS_35MM,         ## 35mm APDS (エリコン/SPAAG)

	## 機関砲 - HE/HEI (High Explosive Incendiary)
	HEI_30MM,          ## 30mm HEI
	HEI_25MM,          ## 25mm HEI
	HEI_35MM,          ## 35mm HEI
	SAPHEI_30MM,       ## 30mm SAPHEI (Semi AP HEI)

	## 迫撃砲
	HE_120MM_MORTAR,   ## 120mm HE
	HE_81MM_MORTAR,    ## 81mm HE
	HE_60MM_MORTAR,    ## 60mm HE
	GUIDED_120MM_MORTAR, ## 120mm GPS誘導 (XM395 Strix)
	SMOKE_81MM,        ## 81mm 発煙弾
	SMOKE_120MM,       ## 120mm 発煙弾
	ILLUM_81MM,        ## 81mm 照明弾
	ILLUM_120MM,       ## 120mm 照明弾

	## 榴弾砲
	HE_155MM,          ## 155mm HE (NATO)
	HE_152MM,          ## 152mm HE (ロシア)
	GUIDED_155MM,      ## 155mm GPS誘導 (M982 Excalibur)
	GUIDED_152MM,      ## 152mm レーザー誘導 (Krasnopol)

	## ATGM
	ATGM_TANDEM,       ## タンデム弾頭 (ERA貫通)
	ATGM_TOPATTACK,    ## トップアタック (Javelin)
	ATGM_SACLOS,       ## SACLOS誘導 (TOW, Konkurs)

	## RPG
	RPG_HEAT,          ## 単弾頭HEAT (RPG-7 PG-7V)
	RPG_TANDEM,        ## タンデムHEAT (RPG-7 PG-7VR)
	RPG_THERMOBARIC,   ## サーモバリック (RPG-7 TBG-7V)
}

# =============================================================================
# 誘導方式
# =============================================================================

enum GuidanceType {
	NONE,              ## 無誘導
	SACLOS,            ## Semi-Automatic Command Line of Sight (ワイヤー/レーザー)
	BEAM_RIDING,       ## ビームライディング
	IR_HOMING,         ## 赤外線ホーミング
	LASER_GUIDED,      ## レーザー誘導
	GPS_INS,           ## GPS/INS
	MMW_RADAR,         ## ミリ波レーダー
}

# =============================================================================
# 信管タイプ
# =============================================================================

enum FuzeType {
	IMPACT,            ## 着発信管
	DELAY,             ## 遅延信管
	PROXIMITY,         ## 近接信管
	TIME,              ## 時限信管
	AIRBURST,          ## エアバースト
}

# =============================================================================
# 弾種プロファイル
# =============================================================================

class AmmoProfile:
	var ammo_type: AmmoType = AmmoType.APFSDS_120MM
	var display_name: String = ""

	## 貫徹力 (RHAスケール: 100 = 500mm)
	var pen_ke: int = 0        ## KE弾の貫徹力
	var pen_ce: int = 0        ## CE弾の貫徹力

	## 殺傷性
	var lethality: float = 0.0        ## 殺傷力（0-100）
	var blast_radius: float = 0.0     ## 爆風半径（m）
	var smoke_radius: float = 0.0     ## 煙幕半径（m）

	## 誘導・信管
	var guidance: GuidanceType = GuidanceType.NONE
	var fuze: FuzeType = FuzeType.IMPACT

	## 特殊フラグ
	var defeats_era: bool = false       ## ERA貫通能力（タンデム弾頭）
	var is_top_attack: bool = false     ## トップアタックモード


	## KE弾かどうか
	func is_ke_round() -> bool:
		return pen_ke > 0 and pen_ce == 0


	## CE弾かどうか
	func is_ce_round() -> bool:
		return pen_ce > 0


	## 誘導弾かどうか
	func is_guided() -> bool:
		return guidance != GuidanceType.NONE


# =============================================================================
# 弾種プロファイル定義
# =============================================================================

static var _ammo_profiles: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialize_profiles()
	_initialized = true


static func _initialize_profiles() -> void:
	# 戦車砲 - APFSDS
	_ammo_profiles[AmmoType.APFSDS_120MM] = _create_apfsds_120mm()
	_ammo_profiles[AmmoType.APFSDS_125MM] = _create_apfsds_125mm()
	_ammo_profiles[AmmoType.APFSDS_105MM] = _create_apfsds_105mm()

	# 戦車砲 - HEAT
	_ammo_profiles[AmmoType.HEAT_120MM] = _create_heat_120mm()
	_ammo_profiles[AmmoType.HEAT_125MM] = _create_heat_125mm()

	# 戦車砲 - HE-MP
	_ammo_profiles[AmmoType.HE_MP_120MM] = _create_he_mp_120mm()
	_ammo_profiles[AmmoType.HE_MP_125MM] = _create_he_mp_125mm()

	# 機関砲 - APDS
	_ammo_profiles[AmmoType.APDS_30MM] = _create_apds_30mm()
	_ammo_profiles[AmmoType.APDS_25MM] = _create_apds_25mm()
	_ammo_profiles[AmmoType.APDS_20MM] = _create_apds_20mm()
	_ammo_profiles[AmmoType.APDS_35MM] = _create_apds_35mm()

	# 機関砲 - HEI
	_ammo_profiles[AmmoType.HEI_30MM] = _create_hei_30mm()
	_ammo_profiles[AmmoType.HEI_25MM] = _create_hei_25mm()
	_ammo_profiles[AmmoType.HEI_35MM] = _create_hei_35mm()
	_ammo_profiles[AmmoType.SAPHEI_30MM] = _create_saphei_30mm()

	# 迫撃砲
	_ammo_profiles[AmmoType.HE_120MM_MORTAR] = _create_he_120mm_mortar()
	_ammo_profiles[AmmoType.HE_81MM_MORTAR] = _create_he_81mm_mortar()
	_ammo_profiles[AmmoType.HE_60MM_MORTAR] = _create_he_60mm_mortar()
	_ammo_profiles[AmmoType.GUIDED_120MM_MORTAR] = _create_guided_120mm_mortar()
	_ammo_profiles[AmmoType.SMOKE_81MM] = _create_smoke_81mm()
	_ammo_profiles[AmmoType.SMOKE_120MM] = _create_smoke_120mm()
	_ammo_profiles[AmmoType.ILLUM_81MM] = _create_illum_81mm()
	_ammo_profiles[AmmoType.ILLUM_120MM] = _create_illum_120mm()

	# 榴弾砲
	_ammo_profiles[AmmoType.HE_155MM] = _create_he_155mm()
	_ammo_profiles[AmmoType.HE_152MM] = _create_he_152mm()
	_ammo_profiles[AmmoType.GUIDED_155MM] = _create_guided_155mm()
	_ammo_profiles[AmmoType.GUIDED_152MM] = _create_guided_152mm()

	# ATGM
	_ammo_profiles[AmmoType.ATGM_TANDEM] = _create_atgm_tandem()
	_ammo_profiles[AmmoType.ATGM_TOPATTACK] = _create_atgm_topattack()
	_ammo_profiles[AmmoType.ATGM_SACLOS] = _create_atgm_saclos()

	# RPG
	_ammo_profiles[AmmoType.RPG_HEAT] = _create_rpg_heat()
	_ammo_profiles[AmmoType.RPG_TANDEM] = _create_rpg_tandem()
	_ammo_profiles[AmmoType.RPG_THERMOBARIC] = _create_rpg_thermobaric()


## 弾種プロファイルを取得
static func get_ammo_profile(ammo_type: AmmoType) -> AmmoProfile:
	_ensure_initialized()
	if ammo_type in _ammo_profiles:
		return _ammo_profiles[ammo_type]
	return AmmoProfile.new()


# =============================================================================
# 弾種選択ロジック
# =============================================================================

## 装甲目標に対して最適な弾種を選択
## armor_value: 目標装甲値（RHAスケール）
## has_era: ERA装備の有無
static func select_best_ammo_for_armor(available: Array, armor_value: int, has_era: bool) -> AmmoType:
	_ensure_initialized()

	var best_ammo: AmmoType = available[0] if available.size() > 0 else AmmoType.APFSDS_120MM
	var best_score: float = -1.0

	for ammo_type in available:
		var profile: AmmoProfile = get_ammo_profile(ammo_type)
		var score: float = 0.0

		# ERA装備の場合、タンデム弾頭を優先
		if has_era and profile.defeats_era:
			score += 50.0

		# 貫徹力と装甲のマッチング
		var pen: int = profile.pen_ke if profile.is_ke_round() else profile.pen_ce
		if pen > armor_value:
			score += float(pen - armor_value) * 0.5
		else:
			score -= float(armor_value - pen) * 2.0  # 貫通できない場合ペナルティ

		# KE弾は装甲に対して安定
		if profile.is_ke_round():
			score += 10.0

		if score > best_score:
			best_score = score
			best_ammo = ammo_type

	return best_ammo


## ソフトターゲットに対して最適な弾種を選択
static func select_best_ammo_for_soft(available: Array) -> AmmoType:
	_ensure_initialized()

	var best_ammo: AmmoType = available[0] if available.size() > 0 else AmmoType.HE_MP_120MM
	var best_score: float = -1.0

	for ammo_type in available:
		var profile: AmmoProfile = get_ammo_profile(ammo_type)
		var score: float = 0.0

		# HE弾を優先
		if profile.blast_radius > 0:
			score += profile.blast_radius * 2.0
			score += profile.lethality

		# サーモバリックは対歩兵に有効
		if ammo_type == AmmoType.RPG_THERMOBARIC:
			score += 50.0

		if score > best_score:
			best_score = score
			best_ammo = ammo_type

	return best_ammo


# =============================================================================
# プロファイル作成ヘルパー
# =============================================================================

## 120mm APFSDS (M829A4相当)
## RHA: 700mm @ 2km
static func _create_apfsds_120mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APFSDS_120MM
	p.display_name = "120mm APFSDS"
	p.pen_ke = 140  # 700mm RHA
	p.pen_ce = 0
	p.lethality = 100.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 125mm APFSDS (3BM60 Svinets-2相当)
## RHA: 650mm @ 2km
static func _create_apfsds_125mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APFSDS_125MM
	p.display_name = "125mm APFSDS"
	p.pen_ke = 130  # 650mm RHA
	p.pen_ce = 0
	p.lethality = 100.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 105mm APFSDS (M900相当)
## RHA: 500mm
static func _create_apfsds_105mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APFSDS_105MM
	p.display_name = "105mm APFSDS"
	p.pen_ke = 100  # 500mm RHA
	p.pen_ce = 0
	p.lethality = 90.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 120mm HEAT
## RHA: 450mm CE
static func _create_heat_120mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HEAT_120MM
	p.display_name = "120mm HEAT"
	p.pen_ke = 0
	p.pen_ce = 90  # 450mm RHA
	p.lethality = 85.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 125mm HEAT
static func _create_heat_125mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HEAT_125MM
	p.display_name = "125mm HEAT"
	p.pen_ke = 0
	p.pen_ce = 85  # 425mm RHA
	p.lethality = 85.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 120mm HE-MP (M830A1相当)
static func _create_he_mp_120mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_MP_120MM
	p.display_name = "120mm HE-MP"
	p.pen_ke = 0
	p.pen_ce = 50  # 軽HEAT効果
	p.lethality = 90.0
	p.blast_radius = 15.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 125mm HE-MP
static func _create_he_mp_125mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_MP_125MM
	p.display_name = "125mm HE-MP"
	p.pen_ke = 0
	p.pen_ce = 45
	p.lethality = 90.0
	p.blast_radius = 15.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 30mm APDS (2A42相当)
## RHA: 160mm @ 500m
static func _create_apds_30mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APDS_30MM
	p.display_name = "30mm APDS"
	p.pen_ke = 32  # 160mm RHA
	p.pen_ce = 0
	p.lethality = 70.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 25mm APDS (M242相当)
## RHA: 125mm
static func _create_apds_25mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APDS_25MM
	p.display_name = "25mm APDS"
	p.pen_ke = 25  # 125mm RHA
	p.pen_ce = 0
	p.lethality = 60.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 20mm APDS
static func _create_apds_20mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APDS_20MM
	p.display_name = "20mm APDS"
	p.pen_ke = 18  # 90mm RHA
	p.pen_ce = 0
	p.lethality = 50.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 35mm APDS (エリコン相当)
## RHA: 200mm
static func _create_apds_35mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.APDS_35MM
	p.display_name = "35mm APDS"
	p.pen_ke = 40  # 200mm RHA
	p.pen_ce = 0
	p.lethality = 75.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 30mm HEI
static func _create_hei_30mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HEI_30MM
	p.display_name = "30mm HEI"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 65.0
	p.blast_radius = 3.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 25mm HEI
static func _create_hei_25mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HEI_25MM
	p.display_name = "25mm HEI"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 55.0
	p.blast_radius = 2.5
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 35mm HEI
static func _create_hei_35mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HEI_35MM
	p.display_name = "35mm HEI"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 70.0
	p.blast_radius = 4.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 30mm SAPHEI (Semi-AP HEI)
static func _create_saphei_30mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.SAPHEI_30MM
	p.display_name = "30mm SAPHEI"
	p.pen_ke = 15  # 軽AP効果
	p.pen_ce = 0
	p.lethality = 60.0
	p.blast_radius = 2.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.DELAY
	return p


## 120mm HE 迫撃砲弾
static func _create_he_120mm_mortar() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_120MM_MORTAR
	p.display_name = "120mm Mortar HE"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 80.0
	p.blast_radius = 25.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 81mm HE 迫撃砲弾
static func _create_he_81mm_mortar() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_81MM_MORTAR
	p.display_name = "81mm Mortar HE"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 70.0
	p.blast_radius = 18.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 60mm HE 迫撃砲弾
static func _create_he_60mm_mortar() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_60MM_MORTAR
	p.display_name = "60mm Mortar HE"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 55.0
	p.blast_radius = 12.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 120mm GPS誘導迫撃砲弾 (XM395 Strix相当)
static func _create_guided_120mm_mortar() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.GUIDED_120MM_MORTAR
	p.display_name = "120mm Guided Mortar"
	p.pen_ke = 0
	p.pen_ce = 40  # 対装甲効果あり
	p.lethality = 85.0
	p.blast_radius = 15.0
	p.guidance = GuidanceType.GPS_INS
	p.fuze = FuzeType.IMPACT
	return p


## 81mm 発煙弾
static func _create_smoke_81mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.SMOKE_81MM
	p.display_name = "81mm Smoke"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 0.0
	p.smoke_radius = 30.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 120mm 発煙弾
static func _create_smoke_120mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.SMOKE_120MM
	p.display_name = "120mm Smoke"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 0.0
	p.smoke_radius = 50.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 81mm 照明弾
static func _create_illum_81mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.ILLUM_81MM
	p.display_name = "81mm Illumination"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 0.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.TIME
	return p


## 120mm 照明弾
static func _create_illum_120mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.ILLUM_120MM
	p.display_name = "120mm Illumination"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 0.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.TIME
	return p


## 155mm HE (NATO)
static func _create_he_155mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_155MM
	p.display_name = "155mm HE"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 95.0
	p.blast_radius = 50.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 152mm HE (ロシア)
static func _create_he_152mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.HE_152MM
	p.display_name = "152mm HE"
	p.pen_ke = 0
	p.pen_ce = 0
	p.lethality = 95.0
	p.blast_radius = 48.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## 155mm GPS誘導 (M982 Excalibur)
static func _create_guided_155mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.GUIDED_155MM
	p.display_name = "155mm Excalibur"
	p.pen_ke = 0
	p.pen_ce = 30
	p.lethality = 90.0
	p.blast_radius = 25.0
	p.guidance = GuidanceType.GPS_INS
	p.fuze = FuzeType.IMPACT
	return p


## 152mm レーザー誘導 (Krasnopol)
static func _create_guided_152mm() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.GUIDED_152MM
	p.display_name = "152mm Krasnopol"
	p.pen_ke = 0
	p.pen_ce = 30
	p.lethality = 90.0
	p.blast_radius = 25.0
	p.guidance = GuidanceType.LASER_GUIDED
	p.fuze = FuzeType.IMPACT
	return p


## ATGM タンデム弾頭 (Kornet-EM相当)
## RHA: 1200mm CE (ERA後)
static func _create_atgm_tandem() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.ATGM_TANDEM
	p.display_name = "ATGM Tandem"
	p.pen_ke = 0
	p.pen_ce = 180  # 900mm RHA (ERA貫通後)
	p.lethality = 100.0
	p.guidance = GuidanceType.SACLOS
	p.fuze = FuzeType.IMPACT
	p.defeats_era = true
	return p


## ATGM トップアタック (Javelin相当)
static func _create_atgm_topattack() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.ATGM_TOPATTACK
	p.display_name = "ATGM Top Attack"
	p.pen_ke = 0
	p.pen_ce = 150  # 750mm RHA
	p.lethality = 100.0
	p.guidance = GuidanceType.IR_HOMING
	p.fuze = FuzeType.IMPACT
	p.is_top_attack = true
	return p


## ATGM SACLOS (TOW2相当)
## RHA: 900mm CE
static func _create_atgm_saclos() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.ATGM_SACLOS
	p.display_name = "ATGM SACLOS"
	p.pen_ke = 0
	p.pen_ce = 180  # 900mm RHA
	p.lethality = 100.0
	p.guidance = GuidanceType.SACLOS
	p.fuze = FuzeType.IMPACT
	return p


## RPG HEAT (PG-7VL相当)
## RHA: 500mm CE
static func _create_rpg_heat() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.RPG_HEAT
	p.display_name = "RPG HEAT"
	p.pen_ke = 0
	p.pen_ce = 100  # 500mm RHA
	p.lethality = 85.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p


## RPG タンデムHEAT (PG-7VR相当)
## RHA: 600mm CE (ERA後)
static func _create_rpg_tandem() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.RPG_TANDEM
	p.display_name = "RPG Tandem HEAT"
	p.pen_ke = 0
	p.pen_ce = 120  # 600mm RHA (ERA貫通後)
	p.lethality = 90.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	p.defeats_era = true
	return p


## RPG サーモバリック (TBG-7V相当)
static func _create_rpg_thermobaric() -> AmmoProfile:
	var p := AmmoProfile.new()
	p.ammo_type = AmmoType.RPG_THERMOBARIC
	p.display_name = "RPG Thermobaric"
	p.pen_ke = 0
	p.pen_ce = 20  # 軽装甲貫通
	p.lethality = 100.0
	p.blast_radius = 10.0
	p.guidance = GuidanceType.NONE
	p.fuze = FuzeType.IMPACT
	return p
