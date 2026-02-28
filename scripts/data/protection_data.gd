class_name ProtectionData
extends RefCounted

## 防護システムデータモデル
## docs/vehicles_tree/armour_systems_2026_mainstream.md に基づく
##
## RHA換算スケール: 100 = 500mm RHA

# =============================================================================
# ERAタイプ
# =============================================================================

enum ERAType {
	NONE,             ## ERA無し
	KONTAKT_1,        ## Kontakt-1 (対CEのみ)
	KONTAKT_5,        ## Kontakt-5 (対CE/KE)
	RELIKT,           ## Relikt (改良型)
	MALACHIT,         ## Malachit (最新型)
	BLAZER,           ## Blazer (イスラエル)
	NXRA,             ## NXRA (西側軽量ERA)
}

# =============================================================================
# APSタイプ
# =============================================================================

enum APSType {
	NONE,             ## APS無し
	SOFT_KILL,        ## ソフトキル (煙幕/妨害)
	HARD_KILL_ARENA,  ## Arena (ロシア)
	HARD_KILL_TROPHY, ## Trophy (イスラエル/NATO)
	HARD_KILL_AFGHANIT, ## Afghanit (T-14)
	HARD_KILL_IRON_FIST, ## Iron Fist (イスラエル)
}

# =============================================================================
# 複合装甲世代
# =============================================================================

enum CompositeGen {
	NONE,    ## なし（RHA/アルミのみ）
	GEN_1,   ## 第1世代（1970s: チョバム初期）
	GEN_2,   ## 第2世代（1980s: M1A1, Leopard 2A4）
	GEN_3,   ## 第3世代（1990s: M1A2, Leopard 2A5）
	GEN_4,   ## 第4世代（2000s以降: 最新複合装甲）
}

# =============================================================================
# ERA効果定義
# =============================================================================

## ERA bonus (RHAスケール: 100 = 500mm)
const ERA_BONUS: Dictionary = {
	ERAType.NONE: { "ke": 0, "ce": 0 },
	ERAType.KONTAKT_1: { "ke": 0, "ce": 20 },      ## 対CE 100mm追加
	ERAType.KONTAKT_5: { "ke": 10, "ce": 30 },     ## 対KE 50mm, 対CE 150mm
	ERAType.RELIKT: { "ke": 15, "ce": 40 },        ## 対KE 75mm, 対CE 200mm
	ERAType.MALACHIT: { "ke": 20, "ce": 50 },      ## 対KE 100mm, 対CE 250mm
	ERAType.BLAZER: { "ke": 0, "ce": 25 },         ## 対CE 125mm
	ERAType.NXRA: { "ke": 5, "ce": 15 },           ## 軽量タイプ
}

# =============================================================================
# APS迎撃確率
# =============================================================================

## APS intercept probability vs different threats
const APS_INTERCEPT_PROB: Dictionary = {
	APSType.NONE: { "atgm": 0.0, "rpg": 0.0, "apfsds": 0.0 },
	APSType.SOFT_KILL: { "atgm": 0.3, "rpg": 0.1, "apfsds": 0.0 },
	APSType.HARD_KILL_ARENA: { "atgm": 0.7, "rpg": 0.8, "apfsds": 0.0 },
	APSType.HARD_KILL_TROPHY: { "atgm": 0.85, "rpg": 0.9, "apfsds": 0.0 },
	APSType.HARD_KILL_AFGHANIT: { "atgm": 0.9, "rpg": 0.95, "apfsds": 0.1 },  ## 対KEも一部
	APSType.HARD_KILL_IRON_FIST: { "atgm": 0.8, "rpg": 0.85, "apfsds": 0.0 },
}

# =============================================================================
# 複合装甲ボーナス
# =============================================================================

## 複合装甲世代ごとのKE/CE防御力倍率
const COMPOSITE_BONUS: Dictionary = {
	CompositeGen.NONE: { "ke_mult": 1.0, "ce_mult": 1.0 },
	CompositeGen.GEN_1: { "ke_mult": 1.2, "ce_mult": 1.5 },
	CompositeGen.GEN_2: { "ke_mult": 1.4, "ce_mult": 1.8 },
	CompositeGen.GEN_3: { "ke_mult": 1.6, "ce_mult": 2.2 },
	CompositeGen.GEN_4: { "ke_mult": 1.8, "ce_mult": 2.5 },
}

# =============================================================================
# 防護プロファイル
# =============================================================================

class ProtectionProfile:
	## 基本装甲 (RHAスケール: 100 = 500mm)
	var base_armor_ke: int = 0    ## 基本KE防御
	var base_armor_ce: int = 0    ## 基本CE防御

	## ERA
	var era_type: ERAType = ERAType.NONE

	## APS
	var aps_type: APSType = APSType.NONE

	## 複合装甲世代
	var composite_gen: CompositeGen = CompositeGen.NONE


	## ERA bonus (KE) を取得
	func get_era_bonus_ke() -> int:
		if era_type in ERA_BONUS:
			return ERA_BONUS[era_type]["ke"]
		return 0


	## ERA bonus (CE) を取得
	func get_era_bonus_ce() -> int:
		if era_type in ERA_BONUS:
			return ERA_BONUS[era_type]["ce"]
		return 0


	## 有効KE装甲を取得 (ERA+複合装甲込み)
	func get_effective_armor_ke() -> int:
		var base: float = float(base_armor_ke)

		# 複合装甲ボーナス
		if composite_gen in COMPOSITE_BONUS:
			base *= COMPOSITE_BONUS[composite_gen]["ke_mult"]

		# ERA bonus
		var era_bonus: int = get_era_bonus_ke()

		return int(base) + era_bonus


	## 有効CE装甲を取得 (ERA+複合装甲込み)
	func get_effective_armor_ce() -> int:
		var base: float = float(base_armor_ce)

		# 複合装甲ボーナス
		if composite_gen in COMPOSITE_BONUS:
			base *= COMPOSITE_BONUS[composite_gen]["ce_mult"]

		# ERA bonus
		var era_bonus: int = get_era_bonus_ce()

		return int(base) + era_bonus


	## APS迎撃確率を取得
	func get_aps_intercept_probability(threat_type: String) -> float:
		if aps_type in APS_INTERCEPT_PROB:
			var probs: Dictionary = APS_INTERCEPT_PROB[aps_type]
			if threat_type in probs:
				return probs[threat_type]
		return 0.0


	## APS迎撃判定
	func roll_aps_intercept(threat_type: String) -> bool:
		var prob: float = get_aps_intercept_probability(threat_type)
		return randf() < prob


	## ERA装備の有無
	func has_era() -> bool:
		return era_type != ERAType.NONE


	## APS装備の有無
	func has_aps() -> bool:
		return aps_type != APSType.NONE


	## タンデム弾頭によるERA無効化
	## タンデム弾頭はERA効果を無視する
	func get_effective_armor_ce_vs_tandem() -> int:
		var base: float = float(base_armor_ce)

		# 複合装甲ボーナスのみ（ERAなし）
		if composite_gen in COMPOSITE_BONUS:
			base *= COMPOSITE_BONUS[composite_gen]["ce_mult"]

		return int(base)


# =============================================================================
# ゾーン別装甲修正
# =============================================================================

## 装甲ゾーン別の防御力倍率
const ZONE_MULTIPLIERS: Dictionary = {
	"front": 1.0,
	"side": 0.4,
	"rear": 0.2,
	"top": 0.15,
}


## ゾーン別の有効装甲を取得
static func get_zone_armor(profile: ProtectionProfile, zone: String, is_ke: bool) -> int:
	var mult: float = 1.0
	if zone in ZONE_MULTIPLIERS:
		mult = ZONE_MULTIPLIERS[zone]

	if is_ke:
		return int(float(profile.get_effective_armor_ke()) * mult)
	else:
		return int(float(profile.get_effective_armor_ce()) * mult)


# =============================================================================
# プリセット防護プロファイル（JSONローダー・SSoT対応）
# =============================================================================

const PROTECTION_JSON_PATH := "res://data/protection/protection_profiles.json"

static var _profiles: Dictionary = {}
static var _json_loaded: bool = false


## JSONファイルから防護プロファイルデータを読み込む
static func _ensure_json_loaded() -> void:
	if _json_loaded:
		return

	var file := FileAccess.open(PROTECTION_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("Cannot open protection JSON: %s" % PROTECTION_JSON_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [PROTECTION_JSON_PATH, json.get_error_message()])
		return

	var profiles_array: Array = json.data
	for profile_data in profiles_array:
		var profile := _dict_to_protection_profile(profile_data)
		var profile_id: String = profile_data.get("id", "")
		_profiles[profile_id] = profile

	_json_loaded = true
	print("Loaded %d protection profiles from JSON" % _profiles.size())


## DictionaryをProtectionProfileに変換
static func _dict_to_protection_profile(data: Dictionary) -> ProtectionProfile:
	var p := ProtectionProfile.new()

	p.base_armor_ke = data.get("base_armor_ke", 0)
	p.base_armor_ce = data.get("base_armor_ce", 0)
	p.era_type = _string_to_era_type(data.get("era_type", "NONE"))
	p.aps_type = _string_to_aps_type(data.get("aps_type", "NONE"))
	p.composite_gen = _string_to_composite_gen(data.get("composite_gen", "NONE"))

	return p


## 文字列をERATypeに変換
static func _string_to_era_type(s: String) -> ERAType:
	match s:
		"NONE": return ERAType.NONE
		"KONTAKT_1": return ERAType.KONTAKT_1
		"KONTAKT_5": return ERAType.KONTAKT_5
		"RELIKT": return ERAType.RELIKT
		"MALACHIT": return ERAType.MALACHIT
		"BLAZER": return ERAType.BLAZER
		"NXRA": return ERAType.NXRA
		_: return ERAType.NONE


## 文字列をAPSTypeに変換
static func _string_to_aps_type(s: String) -> APSType:
	match s:
		"NONE": return APSType.NONE
		"SOFT_KILL": return APSType.SOFT_KILL
		"HARD_KILL_ARENA": return APSType.HARD_KILL_ARENA
		"HARD_KILL_TROPHY": return APSType.HARD_KILL_TROPHY
		"HARD_KILL_AFGHANIT": return APSType.HARD_KILL_AFGHANIT
		"HARD_KILL_IRON_FIST": return APSType.HARD_KILL_IRON_FIST
		_: return APSType.NONE


## 文字列をCompositeGenに変換
static func _string_to_composite_gen(s: String) -> CompositeGen:
	match s:
		"NONE": return CompositeGen.NONE
		"GEN_1": return CompositeGen.GEN_1
		"GEN_2": return CompositeGen.GEN_2
		"GEN_3": return CompositeGen.GEN_3
		"GEN_4": return CompositeGen.GEN_4
		_: return CompositeGen.NONE


## 全防護プロファイルを取得
static func get_all_profiles() -> Dictionary:
	_ensure_json_loaded()
	return _profiles


## IDから防護プロファイルを取得
static func get_profile(profile_id: String) -> ProtectionProfile:
	_ensure_json_loaded()
	if profile_id in _profiles:
		return _profiles[profile_id]
	# デフォルト: SOFT_SKIN
	if "SOFT_SKIN" in _profiles:
		return _profiles["SOFT_SKIN"]
	return ProtectionProfile.new()


# =============================================================================
# 後方互換用ファクトリ関数（SSoT対応：JSONから読み込み）
# =============================================================================

## MBT正面装甲 (M1A2 Abrams相当)
static func create_mbt_front_nato() -> ProtectionProfile:
	return get_profile("MBT_FRONT_NATO")


## MBT正面装甲 (T-90M相当)
static func create_mbt_front_rus() -> ProtectionProfile:
	return get_profile("MBT_FRONT_RUS")


## MBT正面装甲 (T-14 Armata相当)
static func create_mbt_front_armata() -> ProtectionProfile:
	return get_profile("MBT_FRONT_ARMATA")


## IFV正面装甲 (Bradley M2A3相当)
static func create_ifv_front_nato() -> ProtectionProfile:
	return get_profile("IFV_FRONT_NATO")


## IFV正面装甲 (BMP-3相当)
static func create_ifv_front_rus() -> ProtectionProfile:
	return get_profile("IFV_FRONT_RUS")


## 軽装甲車両 (MRAP/装輪装甲車相当)
static func create_light_armor() -> ProtectionProfile:
	return get_profile("LIGHT_ARMOR")


## ソフトスキン車両
static func create_soft_skin() -> ProtectionProfile:
	return get_profile("SOFT_SKIN")


# =============================================================================
# 弾薬庫誘爆システム
# =============================================================================

## 誘爆確率定数
const DETONATION_BASE_CATASTROPHIC: float = 0.60   ## Catastrophic hit時の基本誘爆率
const DETONATION_BASE_PENETRATION: float = 0.15    ## 通常貫通時の基本誘爆率

## ゾーン別誘爆倍率
const DETONATION_ZONE_MULT: Dictionary = {
	"FRONT": 0.8,
	"SIDE": 1.2,
	"REAR": 1.5,
	"TOP": 1.3,
}


## 誘爆確率を計算
## P = base × ammo_mult × zone_mult × protection_mult
##
## base: Catastrophic hitなら0.60、通常貫通なら0.15
## ammo_mult: 0.3 + 0.7 × (残弾率) -- 弾薬が多いほど危険
## zone_mult: 装甲ゾーン別の倍率
## protection_mult: 1.0 - vulnerability -- ブローオフパネル等の効果
static func calculate_detonation_probability(
	element: ElementData.ElementInstance,
	zone: String,
	is_catastrophic: bool
) -> float:
	# 弾薬状態がない場合は誘爆なし
	if not element.ammo_state:
		return 0.0

	# 基本確率
	var base: float = DETONATION_BASE_CATASTROPHIC if is_catastrophic else DETONATION_BASE_PENETRATION

	# 残弾率による倍率 (弾薬が多いほど危険)
	var ammo_ratio: float = element.ammo_state.get_total_ammo_ratio()
	var ammo_mult: float = 0.3 + 0.7 * ammo_ratio

	# ゾーン別倍率
	var zone_mult: float = 1.0
	if zone in DETONATION_ZONE_MULT:
		zone_mult = DETONATION_ZONE_MULT[zone]

	# 防護倍率 (ブローオフパネル等)
	var vulnerability: float = element.ammo_state.ammo_detonation_vulnerability
	var protection_mult: float = vulnerability  # 脆弱性が低いほど安全

	return base * ammo_mult * zone_mult * protection_mult


## 誘爆判定を実行
## 戻り値: 誘爆発生したらtrue
static func roll_detonation(
	element: ElementData.ElementInstance,
	zone: String,
	is_catastrophic: bool
) -> bool:
	var prob := calculate_detonation_probability(element, zone, is_catastrophic)
	return randf() < prob


## 誘爆を適用（車両即死）
static func apply_detonation(element: ElementData.ElementInstance, current_tick: int) -> void:
	# 即死
	element.current_strength = 0
	element.catastrophic_kill = true
	element.is_destroyed = true
	element.destroy_tick = current_tick
	element.state = GameEnums.UnitState.DESTROYED

	# 全サブシステム損傷
	element.mobility_hp = 0
	element.firepower_hp = 0
	element.sensors_hp = 0

	# 弾薬全損
	if element.ammo_state:
		if element.ammo_state.main_gun:
			for slot in element.ammo_state.main_gun.ammo_slots:
				slot.count_ready = 0
				slot.count_stowed = 0
		if element.ammo_state.atgm:
			for slot in element.ammo_state.atgm.ammo_slots:
				slot.count_ready = 0
				slot.count_stowed = 0
		for sec in element.ammo_state.secondary:
			for slot in sec.ammo_slots:
				slot.count_ready = 0
				slot.count_stowed = 0

	print("[Detonation] %s: AMMO COOKOFF! Catastrophic kill." % element.id)
