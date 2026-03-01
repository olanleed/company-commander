## アーカイブ: 旧ProtectionDataハードコード版
## 現在は scripts/data/protection_data.gd を使用
## class_name は競合を避けるため削除済み
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
# プリセット防護プロファイル
# =============================================================================

## MBT正面装甲 (M1A2 Abrams相当)
static func create_mbt_front_nato() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 100   # 500mm RHA base
	p.base_armor_ce = 80    # 400mm RHA base
	p.composite_gen = CompositeGen.GEN_3
	p.era_type = ERAType.NONE  # M1はERAなし
	p.aps_type = APSType.HARD_KILL_TROPHY  # Trophy装備型
	return p


## MBT正面装甲 (T-90M相当)
static func create_mbt_front_rus() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 90    # 450mm RHA base
	p.base_armor_ce = 70    # 350mm RHA base
	p.composite_gen = CompositeGen.GEN_2
	p.era_type = ERAType.RELIKT
	p.aps_type = APSType.SOFT_KILL  # Shtora
	return p


## MBT正面装甲 (T-14 Armata相当)
static func create_mbt_front_armata() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 100   # 500mm RHA base
	p.base_armor_ce = 85    # 425mm RHA base
	p.composite_gen = CompositeGen.GEN_4
	p.era_type = ERAType.MALACHIT
	p.aps_type = APSType.HARD_KILL_AFGHANIT
	return p


## IFV正面装甲 (Bradley M2A3相当)
static func create_ifv_front_nato() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 30    # 150mm RHA
	p.base_armor_ce = 25    # 125mm RHA
	p.composite_gen = CompositeGen.NONE
	p.era_type = ERAType.NXRA
	p.aps_type = APSType.NONE
	return p


## IFV正面装甲 (BMP-3相当)
static func create_ifv_front_rus() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 25    # 125mm RHA
	p.base_armor_ce = 20    # 100mm RHA
	p.composite_gen = CompositeGen.NONE
	p.era_type = ERAType.KONTAKT_1
	p.aps_type = APSType.NONE
	return p


## 軽装甲車両 (MRAP/装輪装甲車相当)
static func create_light_armor() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 10    # 50mm RHA (14.5mm防御)
	p.base_armor_ce = 8     # 40mm RHA
	p.composite_gen = CompositeGen.NONE
	p.era_type = ERAType.NONE
	p.aps_type = APSType.NONE
	return p


## ソフトスキン車両
static func create_soft_skin() -> ProtectionProfile:
	var p := ProtectionProfile.new()
	p.base_armor_ke = 0
	p.base_armor_ce = 0
	p.composite_gen = CompositeGen.NONE
	p.era_type = ERAType.NONE
	p.aps_type = APSType.NONE
	return p


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
