class_name WeaponData
extends RefCounted

## 武器データモデル
## 仕様書: docs/combat_v0.1.md, docs/weapon_system_profile_v0.1.md
##
## WeaponType（固定仕様）を定義。ElementTypeが参照する。

# =============================================================================
# 弾頭メカニズム
# =============================================================================

enum Mechanism {
	SMALL_ARMS,      ## 小銃・LMG/HMG
	KINETIC,         ## AP/APFSDS/機関砲AP：運動エネルギー
	SHAPED_CHARGE,   ## HEAT/RPG/ATGM：成形炸薬
	BLAST_FRAG,      ## HE/迫撃/榴弾：爆風・破片
}

# =============================================================================
# 大口径HEメカニズム（装甲への追加効果）
# =============================================================================

enum HeavyHEClass {
	NONE,            ## 通常の爆風・破片（装甲に弱い）
	HEAVY_HE,        ## 大口径HE（155mm/152mm等、装甲にも効果あり）
}

# =============================================================================
# 射撃モデル
# =============================================================================

enum FireModel {
	CONTINUOUS,      ## 連続火力（小銃、MG、機関砲など）
	DISCRETE,        ## 単発/少数弾（戦車砲、RPG、ATGMなど）
	INDIRECT,        ## 間接射撃（迫撃砲など）
}

# =============================================================================
# 射程帯
# =============================================================================

enum RangeBand {
	NEAR,   ## 0-200m
	MID,    ## 200-800m
	FAR,    ## 800m+
}

# =============================================================================
# ターゲットクラス
# =============================================================================

enum TargetClass {
	SOFT,       ## 歩兵等
	LIGHT,      ## 装輪・軽装甲
	HEAVY,      ## 戦車等
	FORTIFIED,  ## 陣地・建物内扱い
}

# =============================================================================
# 脅威クラス
# =============================================================================

enum ThreatClass {
	SMALL_ARMS,   ## 小火器
	AUTOCANNON,   ## 機関砲
	HE_FRAG,      ## 榴弾・破片
	AT,           ## 対戦車
}

# =============================================================================
# 武器の優先ターゲットタイプ
# =============================================================================

enum PreferredTarget {
	SOFT,     ## 歩兵・ソフトターゲット優先
	ARMOR,    ## 装甲目標優先
	ANY,      ## 汎用（どちらにも有効）
}

# =============================================================================
# 装甲ゾーン
# =============================================================================

enum ArmorZone {
	FRONT,
	SIDE,
	REAR,
	TOP,
}

# =============================================================================
# 武器役割（弾種選択用）
# =============================================================================

## 武器の戦術的役割（IDハードコードを避けるため）
enum WeaponRole {
	MAIN_GUN_KE,    ## 戦車砲APFSDS系（対重装甲）
	MAIN_GUN_CE,    ## 戦車砲HEAT/HE-MP系（汎用）
	ATGM,           ## 対戦車ミサイル（対装甲）
	AUTOCANNON,     ## 機関砲20-40mm（対中/軽装甲）
	COAX_MG,        ## 同軸機関銃（対歩兵/ソフト）
	HMG,            ## 重機関銃12.7-14.5mm（対軽装甲/歩兵）
	AGL,            ## 自動擲弾銃（対歩兵）
	SMALL_ARMS,     ## 小銃/LMG（対歩兵）
	RPG,            ## RPG/LAW（対装甲、歩兵携行）
	MORTAR,         ## 迫撃砲（間接火力）
	HOWITZER,       ## 榴弾砲（間接火力）
	GUN_LAUNCHER,   ## 砲発射ミサイル対応砲（BMP-3等）
}

# =============================================================================
# 目標カテゴリ（詳細分類）
# =============================================================================

## 弾種選択のための詳細目標分類
enum TargetCategory {
	HEAVY_ARMOR,    ## 重装甲（MBT, armor_class >= 3）
	MEDIUM_ARMOR,   ## 中装甲（IFV, armor_class == 2）
	LIGHT_ARMOR,    ## 軽装甲（APC/RECON, armor_class == 1）
	SOFT_VEHICLE,   ## 非装甲車両（トラック等, armor_class == 0 && VEH）
	INFANTRY,       ## 歩兵（armor_class == 0 && INF/TEAM）
}

# =============================================================================
# WeaponType（武器タイプ定義）
# =============================================================================

class WeaponType:
	var id: String = ""
	var display_name: String = ""

	## 弾頭メカニズム
	var mechanism: Mechanism = Mechanism.SMALL_ARMS

	## 大口径HEクラス（BLAST_FRAGの場合に追加効果）
	var heavy_he_class: HeavyHEClass = HeavyHEClass.NONE

	## 口径（mm）：大口径判定用
	var caliber_mm: float = 0.0

	## 射撃モデル
	var fire_model: FireModel = FireModel.CONTINUOUS

	## 射程
	var min_range_m: float = 0.0
	var max_range_m: float = 500.0

	## 射程帯境界 [Near/Mid境界, Mid/Far境界]
	var range_band_thresholds_m: Array[float] = [200.0, 800.0]

	## 殺傷力レーティング（0-100）: band -> target_class -> rating
	var lethality: Dictionary = {}

	## 抑圧力レーティング（0-100）: band -> rating
	var suppression_power: Dictionary = {}

	## 脅威クラス
	var threat_class: ThreatClass = ThreatClass.SMALL_ARMS

	## 優先ターゲット（武器選択に使用）
	var preferred_target: PreferredTarget = PreferredTarget.SOFT

	## 武器役割（弾種選択ロジック用）
	var weapon_role: WeaponRole = WeaponRole.SMALL_ARMS

	## 弾薬持続時間（分）：連続交戦で尽きるまで
	var ammo_endurance_min: float = 30.0

	## Discrete武器用
	var rof_rpm: float = 0.0          ## 発射レート（発/分）
	var sigma_hit_m: float = 0.0      ## 散布（ガウス偏差）
	var direct_hit_radius_m: float = 2.0  ## 直撃半径
	var shock_radius_m: float = 20.0      ## ショック半径

	## 間接武器用
	var setup_time_sec: float = 30.0
	var displace_time_sec: float = 30.0
	var requires_observer: bool = false

	## 貫徹力（装甲目標用）
	var pen_ke: Dictionary = {}   ## band -> rating (0-100)
	var pen_ce: Dictionary = {}   ## band -> rating (0-100)

	## 爆風半径（BLAST_FRAG用）
	var blast_radius_m: float = 40.0

	## 弾速（m/s）：砲弾のビジュアル表示用
	## 0の場合は即着弾（hitscan）として扱う
	var projectile_speed_mps: float = 0.0

	## 砲弾のサイズ（ピクセル）：視覚表示用
	var projectile_size: float = 3.0


	## 射程帯を取得
	func get_range_band(distance_m: float) -> RangeBand:
		if range_band_thresholds_m.size() < 2:
			return RangeBand.MID

		if distance_m < range_band_thresholds_m[0]:
			return RangeBand.NEAR
		elif distance_m < range_band_thresholds_m[1]:
			return RangeBand.MID
		else:
			return RangeBand.FAR


	## 殺傷力を取得
	func get_lethality(distance_m: float, target_class: TargetClass) -> int:
		var band := get_range_band(distance_m)
		if band in lethality and target_class in lethality[band]:
			return lethality[band][target_class]
		return 0


	## 抑圧力を取得
	func get_suppression_power(distance_m: float) -> int:
		var band := get_range_band(distance_m)
		if band in suppression_power:
			return suppression_power[band]
		return 0


	## 射程内かどうか
	func is_in_range(distance_m: float) -> bool:
		return distance_m >= min_range_m and distance_m <= max_range_m


	## 貫徹力（KE）を取得
	func get_pen_ke(distance_m: float) -> int:
		var band := get_range_band(distance_m)
		if band in pen_ke:
			return pen_ke[band]
		return 0


	## 貫徹力（CE）を取得
	func get_pen_ce(distance_m: float) -> int:
		var band := get_range_band(distance_m)
		if band in pen_ce:
			return pen_ce[band]
		return 0


# =============================================================================
# プリセット武器の生成ヘルパー
# =============================================================================

## 小銃（M4相当）を生成
static func create_rifle() -> WeaponType:
	var weapon := WeaponType.new()
	weapon.id = "rifle_standard"
	weapon.display_name = "Standard Rifle"
	weapon.mechanism = Mechanism.SMALL_ARMS
	weapon.fire_model = FireModel.CONTINUOUS
	weapon.min_range_m = 0.0
	weapon.max_range_m = 500.0
	weapon.range_band_thresholds_m = [200.0, 800.0]
	weapon.threat_class = ThreatClass.SMALL_ARMS
	weapon.ammo_endurance_min = 30.0

	weapon.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 15,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 20,
			TargetClass.LIGHT: 5,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 0,
		},
	}

	weapon.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 50,
		RangeBand.FAR: 30,
	}

	return weapon


## 機関銃（M240相当）を生成
static func create_machine_gun() -> WeaponType:
	var weapon := WeaponType.new()
	weapon.id = "mg_standard"
	weapon.display_name = "Standard MG"
	weapon.mechanism = Mechanism.SMALL_ARMS
	weapon.fire_model = FireModel.CONTINUOUS
	weapon.min_range_m = 0.0
	weapon.max_range_m = 1000.0
	weapon.range_band_thresholds_m = [200.0, 800.0]
	weapon.threat_class = ThreatClass.SMALL_ARMS
	weapon.ammo_endurance_min = 20.0

	weapon.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 25,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 20,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
	}

	weapon.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 65,
		RangeBand.FAR: 45,
	}

	return weapon


## RPG（AT4相当）を生成
static func create_rpg() -> WeaponType:
	var weapon := WeaponType.new()
	weapon.id = "rpg_standard"
	weapon.display_name = "Standard AT Rocket"
	weapon.mechanism = Mechanism.SHAPED_CHARGE
	weapon.fire_model = FireModel.DISCRETE
	weapon.min_range_m = 20.0
	weapon.max_range_m = 300.0
	weapon.range_band_thresholds_m = [100.0, 200.0]
	weapon.threat_class = ThreatClass.AT
	weapon.ammo_endurance_min = 5.0
	weapon.rof_rpm = 2.0
	weapon.sigma_hit_m = 3.0
	weapon.direct_hit_radius_m = 1.5
	weapon.shock_radius_m = 15.0

	weapon.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 75,
			TargetClass.HEAVY: 60,
			TargetClass.FORTIFIED: 50,
		},
	}

	weapon.suppression_power = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 50,
		RangeBand.FAR: 40,
	}

	weapon.pen_ce = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 65,
		RangeBand.FAR: 55,
	}

	return weapon


# =============================================================================
# 後方互換性ヘルパー（JSONから取得）
# =============================================================================
# 注意: これらの関数は後方互換性のために残しています。
# 新規コードでは get_all_concrete_weapons() を使用してください。

static func _get_weapon(weapon_id: String) -> WeaponType:
	var weapons := get_all_concrete_weapons()
	if weapons.has(weapon_id):
		return weapons[weapon_id]
	push_error("Weapon not found: %s" % weapon_id)
	return null

# 汎用武器
static func create_cw_rifle_std() -> WeaponType: return _get_weapon("CW_RIFLE_STD")
static func create_cw_mg_std() -> WeaponType: return _get_weapon("CW_MG_STD")
static func create_cw_hmg() -> WeaponType: return _get_weapon("CW_HMG")
static func create_cw_rpg_heat() -> WeaponType: return _get_weapon("CW_RPG_HEAT")
static func create_cw_carl_gustaf() -> WeaponType: return _get_weapon("CW_CARL_GUSTAF")
static func create_cw_coax_mg() -> WeaponType: return _get_weapon("CW_COAX_MG")
static func create_cw_law() -> WeaponType: return _get_weapon("CW_RPG_HEAT")  # LAW は RPG_HEAT にマッピング

# 機関砲
static func create_cw_autocannon_25() -> WeaponType: return _get_weapon("CW_AUTOCANNON_25")
static func create_cw_autocannon_30() -> WeaponType: return _get_weapon("CW_AUTOCANNON_30")
static func create_cw_autocannon_35() -> WeaponType: return _get_weapon("CW_AUTOCANNON_35")

# ATGM
static func create_cw_atgm() -> WeaponType: return _get_weapon("CW_ATGM")
static func create_cw_atgm_topattack() -> WeaponType: return _get_weapon("CW_ATGM_TOPATTACK")
static func create_cw_atgm_beamride() -> WeaponType: return _get_weapon("CW_ATGM_BEAMRIDE")
static func create_cw_atgm_javelin() -> WeaponType: return _get_weapon("CW_ATGM_JAVELIN")
static func create_cw_atgm_tow2b() -> WeaponType: return _get_weapon("CW_ATGM_TOW2B")
static func create_cw_atgm_kornet() -> WeaponType: return _get_weapon("CW_ATGM_KORNET")

# 戦車砲
static func create_cw_tank_ke() -> WeaponType: return _get_weapon("CW_TANK_KE")
static func create_cw_tank_ke_125() -> WeaponType: return _get_weapon("CW_TANK_KE_125")
static func create_cw_tank_ke_105() -> WeaponType: return _get_weapon("CW_TANK_KE_105")
static func create_cw_tank_heatmp() -> WeaponType: return _get_weapon("CW_TANK_HEATMP")
static func create_cw_tank_ke_120_jgsdf() -> WeaponType: return _get_weapon("CW_TANK_KE_120_JGSDF")

# 間接火力
static func create_cw_mortar_he() -> WeaponType: return _get_weapon("CW_MORTAR_HE")
static func create_cw_mortar_81() -> WeaponType: return _get_weapon("CW_MORTAR_81")
static func create_cw_mortar_smoke() -> WeaponType: return _get_weapon("CW_MORTAR_SMOKE")
static func create_cw_mortar_120() -> WeaponType: return _get_weapon("CW_MORTAR_120")
static func create_cw_howitzer_152() -> WeaponType: return _get_weapon("CW_HOWITZER_152")
static func create_cw_howitzer_155() -> WeaponType: return _get_weapon("CW_HOWITZER_155")


# =============================================================================
# JSONローダー（SSoT対応）
# =============================================================================

const WEAPON_JSON_DIR := "res://data/weapons/"
static var _json_weapons: Dictionary = {}
static var _json_loaded: bool = false


## JSONファイルから武器データを読み込む
static func _ensure_json_loaded() -> void:
	if _json_loaded:
		return

	var json_files := [
		"weapons_generic.json",
		"weapons_usa.json",
		"weapons_rus.json",
		"weapons_chn.json",
		"weapons_jpn.json",
	]

	for json_file in json_files:
		var path: String = WEAPON_JSON_DIR + json_file
		if not FileAccess.file_exists(path):
			push_warning("Weapon JSON not found: %s" % path)
			continue

		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Failed to open: %s" % path)
			continue

		var json_text := file.get_as_text()
		file.close()

		var json := JSON.new()
		var error := json.parse(json_text)
		if error != OK:
			push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
			continue

		var weapons_array: Array = json.data
		for weapon_data in weapons_array:
			var weapon := _dict_to_weapon_type(weapon_data)
			if weapon != null:
				_json_weapons[weapon.id] = weapon

	_json_loaded = true
	print("Loaded %d weapons from JSON" % _json_weapons.size())


## Dictionary から WeaponType を構築
static func _dict_to_weapon_type(data: Dictionary) -> WeaponType:
	var w := WeaponType.new()

	w.id = data.get("id", "")
	w.display_name = data.get("display_name", "")
	w.mechanism = _string_to_mechanism(data.get("mechanism", "SMALL_ARMS"))
	w.heavy_he_class = _string_to_heavy_he_class(data.get("heavy_he_class", "NONE"))
	w.caliber_mm = data.get("caliber_mm", 0.0)
	w.fire_model = _string_to_fire_model(data.get("fire_model", "CONTINUOUS"))

	var range_data: Dictionary = data.get("range", {})
	w.min_range_m = range_data.get("min_m", 0.0)
	w.max_range_m = range_data.get("max_m", 500.0)
	var thresholds: Array = range_data.get("band_thresholds_m", [200.0, 800.0])
	w.range_band_thresholds_m = [thresholds[0], thresholds[1]]

	w.threat_class = _string_to_threat_class(data.get("threat_class", "SMALL_ARMS"))
	w.preferred_target = _string_to_preferred_target(data.get("preferred_target", "SOFT"))
	w.ammo_endurance_min = data.get("ammo_endurance_min", 30.0)

	# lethality
	var lethality_data: Dictionary = data.get("lethality", {})
	w.lethality = _dict_to_lethality(lethality_data)

	# suppression_power
	var suppression_data: Dictionary = data.get("suppression_power", {})
	w.suppression_power = _dict_to_suppression(suppression_data)

	# pen_ke / pen_ce
	var pen_ke_data: Dictionary = data.get("pen_ke", {})
	w.pen_ke = _dict_to_penetration(pen_ke_data)
	var pen_ce_data: Dictionary = data.get("pen_ce", {})
	w.pen_ce = _dict_to_penetration(pen_ce_data)

	# discrete_params
	var discrete_data: Dictionary = data.get("discrete_params", {})
	w.rof_rpm = discrete_data.get("rof_rpm", 0.0)
	w.sigma_hit_m = discrete_data.get("sigma_hit_m", 0.0)
	w.direct_hit_radius_m = discrete_data.get("direct_hit_radius_m", 2.0)
	w.shock_radius_m = discrete_data.get("shock_radius_m", 20.0)

	# indirect_params
	var indirect_data: Dictionary = data.get("indirect_params", {})
	w.setup_time_sec = indirect_data.get("setup_time_sec", 30.0)
	w.displace_time_sec = indirect_data.get("displace_time_sec", 30.0)
	w.requires_observer = indirect_data.get("requires_observer", false)

	w.blast_radius_m = data.get("blast_radius_m", 40.0)

	# projectile
	var projectile_data: Dictionary = data.get("projectile", {})
	w.projectile_speed_mps = projectile_data.get("speed_mps", 0.0)
	w.projectile_size = projectile_data.get("size", 3.0)

	# weapon_role は推論で設定
	w.weapon_role = infer_weapon_role(w)

	return w


## 文字列から Mechanism を取得
static func _string_to_mechanism(s: String) -> Mechanism:
	match s:
		"SMALL_ARMS": return Mechanism.SMALL_ARMS
		"KINETIC": return Mechanism.KINETIC
		"SHAPED_CHARGE": return Mechanism.SHAPED_CHARGE
		"BLAST_FRAG": return Mechanism.BLAST_FRAG
		_: return Mechanism.SMALL_ARMS


## 文字列から HeavyHEClass を取得
static func _string_to_heavy_he_class(s: String) -> HeavyHEClass:
	match s:
		"NONE": return HeavyHEClass.NONE
		"HEAVY_HE": return HeavyHEClass.HEAVY_HE
		_: return HeavyHEClass.NONE


## 文字列から FireModel を取得
static func _string_to_fire_model(s: String) -> FireModel:
	match s:
		"CONTINUOUS": return FireModel.CONTINUOUS
		"DISCRETE": return FireModel.DISCRETE
		"INDIRECT": return FireModel.INDIRECT
		_: return FireModel.CONTINUOUS


## 文字列から ThreatClass を取得
static func _string_to_threat_class(s: String) -> ThreatClass:
	match s:
		"SMALL_ARMS": return ThreatClass.SMALL_ARMS
		"AUTOCANNON": return ThreatClass.AUTOCANNON
		"HE_FRAG": return ThreatClass.HE_FRAG
		"AT": return ThreatClass.AT
		_: return ThreatClass.SMALL_ARMS


## 文字列から PreferredTarget を取得
static func _string_to_preferred_target(s: String) -> PreferredTarget:
	match s:
		"SOFT": return PreferredTarget.SOFT
		"ARMOR": return PreferredTarget.ARMOR
		"ANY": return PreferredTarget.ANY
		_: return PreferredTarget.SOFT


## 文字列から RangeBand を取得
static func _string_to_range_band(s: String) -> RangeBand:
	match s:
		"NEAR": return RangeBand.NEAR
		"MID": return RangeBand.MID
		"FAR": return RangeBand.FAR
		_: return RangeBand.MID


## 文字列から TargetClass を取得
static func _string_to_target_class(s: String) -> TargetClass:
	match s:
		"SOFT": return TargetClass.SOFT
		"LIGHT": return TargetClass.LIGHT
		"HEAVY": return TargetClass.HEAVY
		"FORTIFIED": return TargetClass.FORTIFIED
		_: return TargetClass.SOFT


## lethality の文字列キー辞書を enum キー辞書に変換
static func _dict_to_lethality(data: Dictionary) -> Dictionary:
	var result := {}
	for band_str in data.keys():
		var band := _string_to_range_band(band_str)
		result[band] = {}
		var targets: Dictionary = data[band_str]
		for target_str in targets.keys():
			var target := _string_to_target_class(target_str)
			result[band][target] = targets[target_str]
	return result


## suppression_power の文字列キー辞書を enum キー辞書に変換
static func _dict_to_suppression(data: Dictionary) -> Dictionary:
	var result := {}
	for band_str in data.keys():
		var band := _string_to_range_band(band_str)
		result[band] = data[band_str]
	return result


## penetration の文字列キー辞書を enum キー辞書に変換
static func _dict_to_penetration(data: Dictionary) -> Dictionary:
	var result := {}
	for band_str in data.keys():
		var band := _string_to_range_band(band_str)
		result[band] = data[band_str]
	return result


## 全ConcreteWeaponSetを取得（SSoT対応：JSONから読み込み）
static func get_all_concrete_weapons() -> Dictionary:
	_ensure_json_loaded()
	if _json_weapons.is_empty():
		push_error("No weapons loaded from JSON! Check data/weapons/*.json files")
	return _json_weapons


## 武器の特性から役割を推論して設定
## 既存の武器にweapon_roleが未設定の場合に使用
static func infer_weapon_role(weapon: WeaponType) -> WeaponRole:
	# IDベースの明示的な判定（優先）
	var id := weapon.id.to_upper()

	# 戦車砲APFSDS系
	if id.contains("TANK_KE") or id.contains("APFSDS"):
		return WeaponRole.MAIN_GUN_KE

	# 戦車砲HEAT/HE-MP系
	if id.contains("TANK_HEAT") or id.contains("HEATMP"):
		return WeaponRole.MAIN_GUN_CE

	# ATGM系
	if id.contains("ATGM") or id.contains("MAT") or id.contains("KORNET") or \
	   id.contains("JAVELIN") or id.contains("TOW") or id.contains("REFLEKS") or \
	   id.contains("KONKURS") or id.contains("BASTION") or id.contains("HJ"):
		return WeaponRole.ATGM

	# 砲発射ミサイル対応（GP105等）
	if id.contains("GP105"):
		return WeaponRole.GUN_LAUNCHER

	# RPG/LAW系
	if id.contains("RPG") or id.contains("CARL") or id.contains("LAW"):
		return WeaponRole.RPG

	# 機関砲（20-40mm）
	if id.contains("AUTOCANNON") or id.contains("BUSHMASTER") or \
	   id.contains("2A42") or id.contains("2A72") or id.contains("ZPT"):
		return WeaponRole.AUTOCANNON

	# 100mm砲（BMP-3等）
	if id.contains("100") and (id.contains("RUS") or id.contains("CHN")):
		return WeaponRole.GUN_LAUNCHER

	# 重機関銃（12.7-14.5mm）
	if id.contains("KPVT") or id.contains("M2HB") or id.contains("QJZ89") or \
	   id.contains("QJC88") or id.contains("KORD") or id.contains("HMG") or id.contains("_AA"):
		return WeaponRole.HMG

	# 同軸機関銃
	if id.contains("COAX") or id.contains("PKT") or id.contains("TYPE86"):
		return WeaponRole.COAX_MG

	# 自動擲弾銃
	if id.contains("AGL") or id.contains("MK19") or id.contains("AGS"):
		return WeaponRole.AGL

	# 迫撃砲
	if id.contains("MORTAR"):
		return WeaponRole.MORTAR

	# 榴弾砲
	if id.contains("HOWITZER"):
		return WeaponRole.HOWITZER

	# 特性ベースのフォールバック
	match weapon.mechanism:
		Mechanism.KINETIC:
			if weapon.fire_model == FireModel.DISCRETE:
				return WeaponRole.MAIN_GUN_KE
			elif weapon.threat_class == ThreatClass.AUTOCANNON:
				return WeaponRole.AUTOCANNON
			else:
				return WeaponRole.HMG
		Mechanism.SHAPED_CHARGE:
			if weapon.fire_model == FireModel.DISCRETE:
				if weapon.threat_class == ThreatClass.AT:
					return WeaponRole.ATGM
				else:
					return WeaponRole.RPG
			else:
				return WeaponRole.MAIN_GUN_CE
		Mechanism.BLAST_FRAG:
			if weapon.fire_model == FireModel.INDIRECT:
				return WeaponRole.MORTAR
			else:
				return WeaponRole.AGL
		_:
			return WeaponRole.SMALL_ARMS


## 武器にweapon_roleが設定されているか、未設定なら推論して設定
static func ensure_weapon_role(weapon: WeaponType) -> void:
	# デフォルト値（SMALL_ARMS）のままなら推論
	if weapon.weapon_role == WeaponRole.SMALL_ARMS:
		# IDベースで明確に判定できるものは常に推論
		var id := weapon.id.to_upper()
		if id.contains("COAX") or id.contains("PKT") or id.contains("TYPE86") or \
		   id.contains("M240") or id.contains("_MG"):
			weapon.weapon_role = infer_weapon_role(weapon)
		# それ以外は特性で判定
		elif weapon.mechanism != Mechanism.SMALL_ARMS or weapon.threat_class != ThreatClass.SMALL_ARMS:
			weapon.weapon_role = infer_weapon_role(weapon)
