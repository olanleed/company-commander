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

	## 優先ターゲット（武器選択に使用）
	var preferred_target: PreferredTarget = PreferredTarget.SOFT

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


# =============================================================================
# ConcreteWeaponSet（仕様書定義の6武器セット）
# =============================================================================

## CW_RIFLE_STD: 小銃（M4/AK相当）
## 仕様書: docs/concrete_weapons_v0.1.md
static func create_cw_rifle_std() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_RIFLE_STD"
	w.display_name = "Standard Rifle"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 300.0
	w.range_band_thresholds_m = [100.0, 200.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 30.0

	# L/S テーブル（Near/Mid/Far）
	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 5,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 25,
			TargetClass.LIGHT: 0,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 55,
		RangeBand.FAR: 35,
	}

	return w


## CW_MG_STD: 機関銃（M240/PKM相当）
static func create_cw_mg_std() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_MG_STD"
	w.display_name = "Standard MG"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 800.0
	w.range_band_thresholds_m = [200.0, 500.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 20.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 20,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 20,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 15,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 70,
		RangeBand.FAR: 50,
	}

	return w


## CW_RPG_HEAT: 対戦車ロケット（RPG-7 PG-7VL/AT4相当）
## 仕様書: docs/concrete_weapons_v0.1.md
## RHA換算: RPG-7 PG-7VL = 約500mm CE貫徹力
## スケール: 100 = 500mm RHA → RPG = 100
static func create_cw_rpg_heat() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_RPG_HEAT"
	w.display_name = "AT Rocket (Heavy)"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 20.0
	w.max_range_m = 300.0  # RPG-7の有効射程
	w.range_band_thresholds_m = [100.0, 200.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 5.0
	w.rof_rpm = 2.0
	w.sigma_hit_m = 2.5
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 10.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 100,  # 軽装甲は確実
			TargetClass.HEAVY: 85,   # MBT側面/後部に有効
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 65,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 30,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 60,
			TargetClass.FORTIFIED: 55,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 55,
		RangeBand.FAR: 45,
	}

	# RHA換算貫徹力: 500mm = 100（スケール: 100 = 500mm RHA）
	w.pen_ce = {
		RangeBand.NEAR: 100,  # 500mm RHA相当
		RangeBand.MID: 95,    # 475mm RHA相当
		RangeBand.FAR: 85,    # 425mm RHA相当
	}

	return w


## CW_TANK_KE: 戦車主砲APFSDS（120mm相当）
## 仕様書: docs/concrete_weapons_v0.1.md
## RHA換算: 120mm L44 APFSDS = 約600mm KE貫徹力 @ 2km
## スケール: 100 = 500mm RHA → APFSDS近距離 = 140, 遠距離 = 120
static func create_cw_tank_ke() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE"
	w.display_name = "Tank Gun APFSDS"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 2500.0  # 戦車砲の有効射程
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 10.0
	w.rof_rpm = 6.0
	w.sigma_hit_m = 1.5
	w.direct_hit_radius_m = 2.0
	w.shock_radius_m = 5.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,  # 他戦車に対しても高殺傷力
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# RHA換算貫徹力: 700mm近距離→500mm遠距離（KE弾は距離で減衰）
	# スケール: 100 = 500mm RHA
	w.pen_ke = {
		RangeBand.NEAR: 140,  # 700mm RHA相当
		RangeBand.MID: 130,   # 650mm RHA相当
		RangeBand.FAR: 120,   # 600mm RHA相当
	}

	return w


## CW_TANK_HEATMP: 戦車主砲HEAT-MP + 同軸MG
## 仕様書: docs/concrete_weapons_v0.1.md
## RHA換算: 120mm HEAT-MP = 約450mm CE貫徹力
## スケール: 100 = 500mm RHA → HEAT-MP = 90
static func create_cw_tank_heatmp() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_HEATMP"
	w.display_name = "Tank Gun HEAT-MP"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.CONTINUOUS  # 同軸MGを含む連続火力
	w.min_range_m = 0.0
	w.max_range_m = 1500.0
	w.range_band_thresholds_m = [300.0, 1000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ANY  # HEATは対装甲、同軸MGは対歩兵
	w.ammo_endurance_min = 15.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 60,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 65,
		RangeBand.FAR: 50,
	}

	# RHA換算貫徹力: 450mm（HEATは距離で減衰しない）
	# スケール: 100 = 500mm RHA
	w.pen_ce = {
		RangeBand.NEAR: 90,   # 450mm RHA相当
		RangeBand.MID: 90,    # 450mm RHA相当
		RangeBand.FAR: 90,    # 450mm RHA相当
	}

	return w


## CW_MORTAR_HE: 迫撃砲HE弾（81mm相当）
## 仕様書: docs/concrete_weapons_v0.1.md
static func create_cw_mortar_he() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_MORTAR_HE"
	w.display_name = "Mortar HE"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 100.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT  # 対歩兵・陣地
	w.ammo_endurance_min = 10.0
	w.rof_rpm = 15.0
	w.sigma_hit_m = 30.0
	w.blast_radius_m = 40.0
	w.setup_time_sec = 30.0
	w.displace_time_sec = 30.0
	w.requires_observer = true

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 40,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 30,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 35,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 25,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 30,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 20,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 95,
		RangeBand.MID: 90,
		RangeBand.FAR: 85,
	}

	return w


## CW_MORTAR_SMOKE: 迫撃砲発煙弾
## 仕様書: docs/concrete_weapons_v0.1.md
static func create_cw_mortar_smoke() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_MORTAR_SMOKE"
	w.display_name = "Mortar Smoke"
	w.mechanism = Mechanism.BLAST_FRAG  # 特殊: 煙幕用
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 100.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.ammo_endurance_min = 5.0
	w.rof_rpm = 10.0
	w.sigma_hit_m = 25.0
	w.blast_radius_m = 50.0  # 煙幕範囲
	w.setup_time_sec = 30.0
	w.displace_time_sec = 30.0
	w.requires_observer = false

	# 煙幕は殺傷力なし
	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 0,
			TargetClass.LIGHT: 0,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 0,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 0,
			TargetClass.LIGHT: 0,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 0,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 0,
			TargetClass.LIGHT: 0,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 0,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 20,
		RangeBand.MID: 15,
		RangeBand.FAR: 10,
	}

	return w


## CW_COAX_MG: 戦車同軸機関銃（7.62mm相当）
## 対歩兵用の継続火力
static func create_cw_coax_mg() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_COAX_MG"
	w.display_name = "Coaxial MG"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 800.0
	w.range_band_thresholds_m = [200.0, 500.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 30.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 15,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 5,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 65,
		RangeBand.FAR: 45,
	}

	return w


## CW_LAW: 軽対戦車火器（M72 LAW/RPG-26相当）
## 歩兵分隊の対装甲自衛用
## RHA換算: M72 LAW = 約300mm CE貫徹力
## スケール: 100 = 500mm RHA → LAW = 60
static func create_cw_law() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_LAW"
	w.display_name = "Light AT Rocket"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 10.0
	w.max_range_m = 250.0  # M72 LAW相当の有効射程
	w.range_band_thresholds_m = [80.0, 150.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 3.0  # 使い捨て火器なので少ない
	w.rof_rpm = 1.0  # 装填不要だが1本/分程度
	w.sigma_hit_m = 3.0
	w.direct_hit_radius_m = 1.0
	w.shock_radius_m = 8.0

	# AT武器のlethalityは「当たった時の効果」を表す
	# 距離による減衰は命中精度の低下として反映
	# HEAVY目標への値を上げて、ヒット率を確保
	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 90,   # 軽装甲に対しては有効
			TargetClass.HEAVY: 75,   # MBT側面/後部なら有効（上方修正）
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 65,   # 上方修正
			TargetClass.FORTIFIED: 50,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 30,
			TargetClass.LIGHT: 65,
			TargetClass.HEAVY: 55,   # 上方修正（35→55）
			TargetClass.FORTIFIED: 40,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 55,
		RangeBand.MID: 45,
		RangeBand.FAR: 35,
	}

	# RHA換算貫徹力: 300mm = 60（スケール: 100 = 500mm RHA）
	# 距離による減衰はHEATでは小さい
	w.pen_ce = {
		RangeBand.NEAR: 60,   # 300mm RHA相当
		RangeBand.MID: 58,    # 290mm RHA相当
		RangeBand.FAR: 55,    # 275mm RHA相当
	}

	return w


## 全ConcreteWeaponSetを取得
static func get_all_concrete_weapons() -> Dictionary:
	return {
		"CW_RIFLE_STD": create_cw_rifle_std(),
		"CW_MG_STD": create_cw_mg_std(),
		"CW_RPG_HEAT": create_cw_rpg_heat(),
		"CW_LAW": create_cw_law(),
		"CW_COAX_MG": create_cw_coax_mg(),
		"CW_TANK_KE": create_cw_tank_ke(),
		"CW_TANK_HEATMP": create_cw_tank_heatmp(),
		"CW_MORTAR_HE": create_cw_mortar_he(),
		"CW_MORTAR_SMOKE": create_cw_mortar_smoke(),
	}
