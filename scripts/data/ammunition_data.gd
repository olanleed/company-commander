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
# JSONローダー（SSoT対応）
# =============================================================================

const AMMO_JSON_PATH := "res://data/ammunition/ammunition_profiles.json"

static var _ammo_profiles: Dictionary = {}
static var _json_loaded: bool = false


## JSONファイルから弾薬データを読み込む
static func _ensure_json_loaded() -> void:
	if _json_loaded:
		return

	var file := FileAccess.open(AMMO_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("Cannot open ammunition JSON: %s" % AMMO_JSON_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [AMMO_JSON_PATH, json.get_error_message()])
		return

	var profiles_array: Array = json.data
	for profile_data in profiles_array:
		var profile := _dict_to_ammo_profile(profile_data)
		var type_name: String = profile_data.get("ammo_type", "")
		if AmmoType.has(type_name):
			var type_value: int = AmmoType[type_name]
			_ammo_profiles[type_value] = profile

	_json_loaded = true
	print("Loaded %d ammunition profiles from JSON" % _ammo_profiles.size())


## Dictionary を AmmoProfile に変換
static func _dict_to_ammo_profile(data: Dictionary) -> AmmoProfile:
	var profile := AmmoProfile.new()

	# 基本値
	var type_name: String = data.get("ammo_type", "")
	if AmmoType.has(type_name):
		profile.ammo_type = AmmoType[type_name]

	profile.display_name = data.get("display_name", "")
	profile.pen_ke = int(data.get("pen_ke", 0))
	profile.pen_ce = int(data.get("pen_ce", 0))
	profile.lethality = float(data.get("lethality", 0.0))
	profile.blast_radius = float(data.get("blast_radius", 0.0))
	profile.smoke_radius = float(data.get("smoke_radius", 0.0))

	# enum変換
	profile.guidance = _string_to_guidance(data.get("guidance", "NONE"))
	profile.fuze = _string_to_fuze(data.get("fuze", "IMPACT"))

	# フラグ
	profile.defeats_era = data.get("defeats_era", false)
	profile.is_top_attack = data.get("is_top_attack", false)

	return profile


## 文字列をGuidanceTypeに変換
static func _string_to_guidance(s: String) -> GuidanceType:
	match s:
		"NONE": return GuidanceType.NONE
		"SACLOS": return GuidanceType.SACLOS
		"BEAM_RIDING": return GuidanceType.BEAM_RIDING
		"IR_HOMING": return GuidanceType.IR_HOMING
		"LASER_GUIDED": return GuidanceType.LASER_GUIDED
		"GPS_INS": return GuidanceType.GPS_INS
		"MMW_RADAR": return GuidanceType.MMW_RADAR
		_: return GuidanceType.NONE


## 文字列をFuzeTypeに変換
static func _string_to_fuze(s: String) -> FuzeType:
	match s:
		"IMPACT": return FuzeType.IMPACT
		"DELAY": return FuzeType.DELAY
		"PROXIMITY": return FuzeType.PROXIMITY
		"TIME": return FuzeType.TIME
		"AIRBURST": return FuzeType.AIRBURST
		_: return FuzeType.IMPACT


## 弾種プロファイルを取得（SSoT対応：JSONから読み込み）
static func get_ammo_profile(ammo_type: AmmoType) -> AmmoProfile:
	_ensure_json_loaded()
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
	_ensure_json_loaded()

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
	_ensure_json_loaded()

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
