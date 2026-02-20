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
# 装甲ゾーン
# =============================================================================

enum ArmorZone {
	FRONT,
	SIDE,
	REAR,
	TOP,
}

# =============================================================================
# WeaponType（武器タイプ定義）
# =============================================================================

class WeaponType:
	var id: String = ""
	var display_name: String = ""

	## 弾頭メカニズム
	var mechanism: Mechanism = Mechanism.SMALL_ARMS

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
