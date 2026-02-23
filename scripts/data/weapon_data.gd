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

	# 弾速: RPG-7 = 約300m/s
	w.projectile_speed_mps = 300.0
	w.projectile_size = 5.0

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
	w.rof_rpm = 15.0  # 4秒に1発
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

	# 弾速: APFSDS = 約1700m/s
	w.projectile_speed_mps = 1700.0
	w.projectile_size = 4.0

	return w


## CW_TANK_HEATMP: 戦車主砲HEAT-MP（多目的榴弾）
## 仕様書: docs/concrete_weapons_v0.1.md
## RHA換算: 120mm HEAT-MP = 約450mm CE貫徹力
## スケール: 100 = 500mm RHA → HEAT-MP = 90
## 用途: 軽装甲車両、建物、歩兵（HE効果）
## 注意: 同軸MGは別武器(CW_COAX_MG)として分離
static func create_cw_tank_heatmp() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_HEATMP"
	w.display_name = "Tank Gun HEAT-MP"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE  # 戦車砲は離散射撃
	w.min_range_m = 0.0
	w.max_range_m = 1500.0
	w.range_band_thresholds_m = [300.0, 1000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ANY  # 多目的弾
	w.ammo_endurance_min = 15.0
	w.rof_rpm = 10.0  # 6秒に1発（APFSDSより遅い：弾頭交換時間を考慮）
	w.sigma_hit_m = 2.0  # APFSDSより精度が低い
	w.direct_hit_radius_m = 3.0  # HE効果の範囲
	w.shock_radius_m = 8.0  # 破片効果の範囲

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

	# 弾速: HEAT = 約1000m/s（APFSDSより遅い）
	w.projectile_speed_mps = 1000.0
	w.projectile_size = 4.0

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


## CW_CARL_GUSTAF: 84mm無反動砲（Carl Gustaf M3/M4相当）
## 歩兵分隊の主力対装甲火器、再装填可能
## RHA換算: 84mm HEAT FFV551 = 約400mm CE貫徹力
## スケール: 100 = 500mm RHA → Carl Gustaf = 80
static func create_cw_carl_gustaf() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_CARL_GUSTAF"
	w.display_name = "84mm Recoilless"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 20.0
	w.max_range_m = 500.0  # Carl Gustaf HEAT有効射程
	w.range_band_thresholds_m = [150.0, 300.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 5.0  # 再装填可能、複数弾携行
	w.rof_rpm = 6.0  # 約10秒に1発（再装填込み）
	w.sigma_hit_m = 2.5
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 12.0

	# 84mm HEATは軽装甲に対して非常に有効
	# MBT正面は厳しいが側面/後部なら貫通可能
	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 95,   # 軽装甲は確実
			TargetClass.HEAVY: 80,   # MBT側面/後部に有効
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 60,
			TargetClass.FORTIFIED: 50,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 55,
		RangeBand.FAR: 45,
	}

	# RHA換算貫徹力: 400mm = 80（スケール: 100 = 500mm RHA）
	# HEATは距離による減衰が小さい
	w.pen_ce = {
		RangeBand.NEAR: 80,   # 400mm RHA相当
		RangeBand.MID: 78,    # 390mm RHA相当
		RangeBand.FAR: 75,    # 375mm RHA相当
	}

	# 弾速: Carl Gustaf HEAT = 約255m/s
	w.projectile_speed_mps = 255.0
	w.projectile_size = 5.0

	return w


## CW_AUTOCANNON_30: 30mm機関砲（2A42/Mk44相当）
## IFVの主武装、軽装甲車両に有効
## RHA換算: 30mm APDS = 約120-150mm KE貫徹力 @ 500m
## 近距離ではIFV正面装甲を貫通可能
## スケール: 100 = 500mm RHA
static func create_cw_autocannon_30() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_30"
	w.display_name = "30mm Autocannon"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1500.0
	w.range_band_thresholds_m = [300.0, 1000.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 15.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 95,   # 軽装甲に非常に有効
			TargetClass.HEAVY: 25,   # MBT側面に若干有効
			TargetClass.FORTIFIED: 50,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 15,
			TargetClass.FORTIFIED: 40,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 30,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 90,
		RangeBand.MID: 75,
		RangeBand.FAR: 55,
	}

	# RHA換算貫徹力: 150mm近距離→80mm遠距離
	# 近距離ではIFV正面(30=150mm)を50%以上の確率で貫通
	# スケール: 100 = 500mm RHA
	w.pen_ke = {
		RangeBand.NEAR: 32,   # 160mm RHA相当 - IFV正面を貫通可能
		RangeBand.MID: 24,    # 120mm RHA相当 - IFV側面を確実貫通
		RangeBand.FAR: 16,    # 80mm RHA相当 - 軽装甲のみ有効
	}

	# 弾速: 30mm APDS = 約1100m/s
	w.projectile_speed_mps = 1100.0
	w.projectile_size = 2.0

	return w


## CW_ATGM: 対戦車ミサイル（TOW/Konkurs/96式相当）
## IFVの対戦車火力、MBTにも有効
## RHA換算: TOW2 = 約900mm CE貫徹力
## スケール: 100 = 500mm RHA → ATGM = 180
static func create_cw_atgm() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM"
	w.display_name = "ATGM"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 65.0   # 最小射程（安全装置）
	w.max_range_m = 3750.0 # TOW2の最大射程
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 3.0  # ミサイル数が限られる
	w.rof_rpm = 2.0  # 約30秒に1発（再装填込み）
	w.sigma_hit_m = 1.5  # ワイヤー誘導で精度が高い
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,  # 軽装甲は確実
			TargetClass.HEAVY: 95,   # MBT正面にも有効
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 55,
		RangeBand.MID: 50,
		RangeBand.FAR: 45,
	}

	# RHA換算貫徹力: 900mm（HEATは距離で減衰しない）
	# スケール: 100 = 500mm RHA
	w.pen_ce = {
		RangeBand.NEAR: 180,  # 900mm RHA相当
		RangeBand.MID: 180,   # 900mm RHA相当
		RangeBand.FAR: 180,   # 900mm RHA相当
	}

	# 弾速: TOW = 約300m/s
	w.projectile_speed_mps = 300.0
	w.projectile_size = 6.0

	return w


## CW_HMG: 12.7mm重機関銃
## M2/NSV相当
## 軽装甲車両の主武装、対歩兵・軽車両に有効
static func create_cw_hmg() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_HMG"
	w.display_name = "12.7mm HMG"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1500.0
	w.range_band_thresholds_m = [300.0, 800.0]  # NEAR < 300m, MID < 800m, FAR >= 800m
	w.threat_class = ThreatClass.AUTOCANNON  # 機関砲扱い
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 10.0
	w.rof_rpm = 450.0
	w.sigma_hit_m = 3.0
	w.direct_hit_radius_m = 0.5
	w.shock_radius_m = 3.0

	# 対歩兵
	w.lethality = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.8, RangeBand.MID: 0.6, RangeBand.FAR: 0.4 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.5, RangeBand.MID: 0.3, RangeBand.FAR: 0.1 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.0, RangeBand.MID: 0.0, RangeBand.FAR: 0.0 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.2, RangeBand.MID: 0.1, RangeBand.FAR: 0.05 },
	}
	w.suppression_power = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.9, RangeBand.MID: 0.7, RangeBand.FAR: 0.5 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.6, RangeBand.MID: 0.4, RangeBand.FAR: 0.2 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.2, RangeBand.MID: 0.1, RangeBand.FAR: 0.05 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.4, RangeBand.MID: 0.2, RangeBand.FAR: 0.1 },
	}

	# KE貫徹力（12.7mm AP弾）
	# RHA換算: 約20mm（近距離）- 軽装甲車の側面を貫通可能
	w.pen_ke = {
		RangeBand.NEAR: 4,    # 20mm RHA相当
		RangeBand.MID: 3,     # 15mm RHA相当
		RangeBand.FAR: 2,     # 10mm RHA相当
	}

	w.projectile_speed_mps = 900.0
	w.projectile_size = 2.0

	return w


## CW_AUTOCANNON_35: 35mm機関砲（連装）
## エリコン35mm/87式SPAAG相当
## 対空・対地両用、高発射レート
static func create_cw_autocannon_35() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_35"
	w.display_name = "35mm Twin Autocannon"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]  # NEAR < 500m, MID < 2000m, FAR >= 2000m
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 5.0
	w.rof_rpm = 1100.0  # 連装で高発射レート
	w.sigma_hit_m = 2.0
	w.direct_hit_radius_m = 1.0
	w.shock_radius_m = 5.0

	w.lethality = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.95, RangeBand.MID: 0.8, RangeBand.FAR: 0.6 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.8, RangeBand.MID: 0.6, RangeBand.FAR: 0.4 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.3, RangeBand.MID: 0.2, RangeBand.FAR: 0.1 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.5, RangeBand.MID: 0.3, RangeBand.FAR: 0.2 },
	}
	w.suppression_power = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.95, RangeBand.MID: 0.85, RangeBand.FAR: 0.7 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.8, RangeBand.MID: 0.6, RangeBand.FAR: 0.4 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.4, RangeBand.MID: 0.25, RangeBand.FAR: 0.15 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.6, RangeBand.MID: 0.4, RangeBand.FAR: 0.25 },
	}

	# 35mm APDS - 30mmより高貫徹
	# RHA換算貫徹力
	w.pen_ke = {
		RangeBand.NEAR: 40,   # 200mm RHA相当 - IFV正面を貫通可能
		RangeBand.MID: 30,    # 150mm RHA相当
		RangeBand.FAR: 20,    # 100mm RHA相当
	}

	w.projectile_speed_mps = 1175.0
	w.projectile_size = 3.5

	return w


## CW_HOWITZER_155: 155mm榴弾砲
## 自走砲用、長距離間接射撃
static func create_cw_howitzer_155() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_HOWITZER_155"
	w.display_name = "155mm Howitzer"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 2000.0  # 最小射程2km
	w.max_range_m = 30000.0  # 最大射程30km
	w.range_band_thresholds_m = [5000.0, 15000.0]  # NEAR < 5km, MID < 15km, FAR >= 15km
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 15.0
	w.rof_rpm = 6.0  # 6発/分
	w.sigma_hit_m = 30.0  # 命中精度（CEP）
	w.direct_hit_radius_m = 5.0
	w.shock_radius_m = 50.0
	w.blast_radius_m = 30.0
	w.requires_observer = true  # 前進観測員が必要

	# 155mm HE - 大威力
	w.lethality = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.95, RangeBand.MID: 0.9, RangeBand.FAR: 0.85 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.7, RangeBand.MID: 0.65, RangeBand.FAR: 0.6 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.2, RangeBand.MID: 0.15, RangeBand.FAR: 0.1 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.8, RangeBand.MID: 0.75, RangeBand.FAR: 0.7 },
	}
	w.suppression_power = {
		TargetClass.SOFT: { RangeBand.NEAR: 1.0, RangeBand.MID: 0.95, RangeBand.FAR: 0.9 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.9, RangeBand.MID: 0.85, RangeBand.FAR: 0.8 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.5, RangeBand.MID: 0.4, RangeBand.FAR: 0.3 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.95, RangeBand.MID: 0.9, RangeBand.FAR: 0.85 },
	}

	# 砲弾速度（高角射撃）
	w.projectile_speed_mps = 800.0
	w.projectile_size = 8.0

	return w


## CW_MORTAR_120: 120mm迫撃砲（自走）
## 自走迫撃砲用、中距離間接射撃
static func create_cw_mortar_120() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_MORTAR_120"
	w.display_name = "120mm Mortar"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 200.0
	w.max_range_m = 8000.0
	w.range_band_thresholds_m = [1500.0, 4000.0]  # NEAR < 1.5km, MID < 4km, FAR >= 4km
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 10.0
	w.rof_rpm = 10.0  # 10発/分
	w.sigma_hit_m = 20.0
	w.direct_hit_radius_m = 3.0
	w.shock_radius_m = 30.0
	w.blast_radius_m = 20.0
	w.requires_observer = true

	w.lethality = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.85, RangeBand.MID: 0.8, RangeBand.FAR: 0.75 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.5, RangeBand.MID: 0.45, RangeBand.FAR: 0.4 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.1, RangeBand.MID: 0.08, RangeBand.FAR: 0.05 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.6, RangeBand.MID: 0.55, RangeBand.FAR: 0.5 },
	}
	w.suppression_power = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.95, RangeBand.MID: 0.9, RangeBand.FAR: 0.85 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.7, RangeBand.MID: 0.65, RangeBand.FAR: 0.6 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.3, RangeBand.MID: 0.25, RangeBand.FAR: 0.2 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.8, RangeBand.MID: 0.75, RangeBand.FAR: 0.7 },
	}

	w.projectile_speed_mps = 300.0
	w.projectile_size = 6.0

	return w


## CW_TANK_KE_125: 125mm戦車砲APFSDS（ロシア/中国）
## RHA換算: 125mm APFSDS = 約650mm KE貫徹力 @ 2km
static func create_cw_tank_ke_125() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125"
	w.display_name = "Tank Gun 125mm APFSDS"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 2500.0
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 8.0  # 自動装填で少ない予備
	w.rof_rpm = 8.0  # 自動装填で遅め
	w.sigma_hit_m = 1.8
	w.direct_hit_radius_m = 2.0
	w.shock_radius_m = 5.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 65,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# 125mm APFSDS: 650mm @ 2km
	w.pen_ke = {
		RangeBand.NEAR: 130,  # 650mm RHA相当
		RangeBand.MID: 120,   # 600mm RHA相当
		RangeBand.FAR: 110,   # 550mm RHA相当
	}

	w.projectile_speed_mps = 1750.0
	w.projectile_size = 4.0

	return w


## CW_TANK_KE_105: 105mm戦車砲APFSDS（軽戦車/旧世代）
## RHA換算: 105mm APFSDS = 約500mm KE貫徹力
static func create_cw_tank_ke_105() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_105"
	w.display_name = "Tank Gun 105mm APFSDS"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [400.0, 1200.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 12.0
	w.rof_rpm = 12.0  # 手動装填、小口径で速い
	w.sigma_hit_m = 1.5
	w.direct_hit_radius_m = 1.8
	w.shock_radius_m = 4.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 30,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 50,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 45,
		RangeBand.MID: 40,
		RangeBand.FAR: 35,
	}

	# 105mm APFSDS: 500mm
	w.pen_ke = {
		RangeBand.NEAR: 100,  # 500mm RHA相当
		RangeBand.MID: 90,    # 450mm RHA相当
		RangeBand.FAR: 80,    # 400mm RHA相当
	}

	w.projectile_speed_mps = 1500.0
	w.projectile_size = 3.5

	return w


## CW_AUTOCANNON_25: 25mm機関砲（M242 Bushmaster相当）
static func create_cw_autocannon_25() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_25"
	w.display_name = "25mm Autocannon"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1200.0
	w.range_band_thresholds_m = [250.0, 800.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 15.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 15,
			TargetClass.FORTIFIED: 45,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 35,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 65,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 25,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 70,
		RangeBand.FAR: 50,
	}

	# 25mm APDS: 125mm
	w.pen_ke = {
		RangeBand.NEAR: 25,   # 125mm RHA相当
		RangeBand.MID: 18,    # 90mm RHA相当
		RangeBand.FAR: 12,    # 60mm RHA相当
	}

	w.projectile_speed_mps = 1100.0
	w.projectile_size = 2.0

	return w


## CW_MORTAR_81: 81mm迫撃砲
static func create_cw_mortar_81() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_MORTAR_81"
	w.display_name = "81mm Mortar"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 80.0
	w.max_range_m = 5000.0
	w.range_band_thresholds_m = [1000.0, 3000.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 15.0
	w.rof_rpm = 20.0  # 81mmは高発射レート
	w.sigma_hit_m = 25.0
	w.direct_hit_radius_m = 2.5
	w.shock_radius_m = 25.0
	w.blast_radius_m = 18.0
	w.requires_observer = true

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 35,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 25,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 30,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 20,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 25,
			TargetClass.HEAVY: 3,
			TargetClass.FORTIFIED: 15,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 90,
		RangeBand.MID: 85,
		RangeBand.FAR: 80,
	}

	w.projectile_speed_mps = 250.0
	w.projectile_size = 5.0

	return w


## CW_HOWITZER_152: 152mm榴弾砲（ロシア）
static func create_cw_howitzer_152() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_HOWITZER_152"
	w.display_name = "152mm Howitzer"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.INDIRECT
	w.min_range_m = 2000.0
	w.max_range_m = 28000.0
	w.range_band_thresholds_m = [5000.0, 14000.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 12.0
	w.rof_rpm = 5.0  # 155mmより若干遅い
	w.sigma_hit_m = 35.0
	w.direct_hit_radius_m = 5.0
	w.shock_radius_m = 48.0
	w.blast_radius_m = 28.0
	w.requires_observer = true

	w.lethality = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.93, RangeBand.MID: 0.88, RangeBand.FAR: 0.83 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.68, RangeBand.MID: 0.63, RangeBand.FAR: 0.58 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.18, RangeBand.MID: 0.13, RangeBand.FAR: 0.08 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.78, RangeBand.MID: 0.73, RangeBand.FAR: 0.68 },
	}
	w.suppression_power = {
		TargetClass.SOFT: { RangeBand.NEAR: 0.98, RangeBand.MID: 0.93, RangeBand.FAR: 0.88 },
		TargetClass.LIGHT: { RangeBand.NEAR: 0.88, RangeBand.MID: 0.83, RangeBand.FAR: 0.78 },
		TargetClass.HEAVY: { RangeBand.NEAR: 0.48, RangeBand.MID: 0.38, RangeBand.FAR: 0.28 },
		TargetClass.FORTIFIED: { RangeBand.NEAR: 0.93, RangeBand.MID: 0.88, RangeBand.FAR: 0.83 },
	}

	w.projectile_speed_mps = 780.0
	w.projectile_size = 8.0

	return w


## CW_ATGM_TOPATTACK: トップアタックATGM（Javelin相当）
static func create_cw_atgm_topattack() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_TOPATTACK"
	w.display_name = "ATGM Top Attack"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 75.0   # Javelin最小射程
	w.max_range_m = 2500.0 # Javelin最大射程
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 2.0  # 高価で数が少ない
	w.rof_rpm = 1.5  # Fire-and-forget、再装填遅い
	w.sigma_hit_m = 0.5  # 非常に高精度
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 6.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,  # トップアタックでMBT確殺
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 98,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# Javelin: 750mm RHA (トップアタックで装甲薄い上面を狙う)
	w.pen_ce = {
		RangeBand.NEAR: 150,
		RangeBand.MID: 150,
		RangeBand.FAR: 150,
	}

	w.projectile_speed_mps = 150.0  # 遅いがホーミング
	w.projectile_size = 5.0

	return w


## CW_TANK_KE_120_JGSDF: 10式/90式戦車 120mm APFSDS（自衛隊）
## 10式APFSDS: 575mm @ 2km, JM33: 470mm @ 2km
## RHA換算スケール: 100 = 500mm RHA
static func create_cw_tank_ke_120_jgsdf() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_120_JGSDF"
	w.display_name = "120mm Tank Gun (JGSDF)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 3000.0  # 10式/90式は長射程
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 10.0  # 36発搭載
	w.rof_rpm = 12.0  # 自動装填（10式: 10-15発/分）
	w.sigma_hit_m = 1.2  # 高精度FCS
	w.direct_hit_radius_m = 2.0
	w.shock_radius_m = 5.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,
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
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# 10式APFSDS: 575mm = 115 (RHA scale)
	# 距離減衰あり
	w.pen_ke = {
		RangeBand.NEAR: 125,  # 625mm RHA相当（近距離）
		RangeBand.MID: 115,   # 575mm RHA相当（2km）
		RangeBand.FAR: 105,   # 525mm RHA相当（3km）
	}

	w.projectile_speed_mps = 1750.0
	w.projectile_size = 4.0

	return w


## CW_TANK_KE_105_JGSDF: 16式機動戦闘車 105mm APFSDS（自衛隊）
## 93式APFSDS: 350mm @ 2km
## 52口径長砲身、高初速
static func create_cw_tank_ke_105_jgsdf() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_105_JGSDF"
	w.display_name = "105mm Tank Gun (Type 16)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 2500.0
	w.range_band_thresholds_m = [400.0, 1200.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 12.0  # 40発搭載
	w.rof_rpm = 7.0  # 手動装填（6-8発/分）
	w.sigma_hit_m = 1.5
	w.direct_hit_radius_m = 1.8
	w.shock_radius_m = 4.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 75,  # MBT正面は厳しい
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 30,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 50,
			TargetClass.FORTIFIED: 50,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 45,
		RangeBand.MID: 40,
		RangeBand.FAR: 35,
	}

	# 93式APFSDS: 350mm = 70 (RHA scale)
	w.pen_ke = {
		RangeBand.NEAR: 80,   # 400mm RHA相当（近距離）
		RangeBand.MID: 70,    # 350mm RHA相当（2km）
		RangeBand.FAR: 60,    # 300mm RHA相当（遠距離）
	}

	w.projectile_speed_mps = 1550.0  # 52口径で高初速
	w.projectile_size = 3.5

	return w


## CW_AUTOCANNON_35_JGSDF: 89式IFV 35mm機関砲（エリコンKDE）
## 35mm APDS: 90-100mm @ 1km
## デュアルフィード（APDS/SAPHEI切替可能）
static func create_cw_autocannon_35_jgsdf() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_35_JGSDF"
	w.display_name = "35mm Autocannon (Type 89)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 3000.0  # 対地3,000m
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 10.0  # 400発
	w.rof_rpm = 200.0  # 単砲200発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 20,  # MBT側面には若干有効
			TargetClass.FORTIFIED: 55,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 12,
			TargetClass.FORTIFIED: 45,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 35,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 90,
		RangeBand.MID: 75,
		RangeBand.FAR: 55,
	}

	# 35mm APDS: 95mm = 19 (RHA scale @ 1km)
	w.pen_ke = {
		RangeBand.NEAR: 22,   # 110mm RHA相当
		RangeBand.MID: 19,    # 95mm RHA相当（1km）
		RangeBand.FAR: 14,    # 70mm RHA相当（2km+）
	}

	w.projectile_speed_mps = 1175.0
	w.projectile_size = 3.0

	return w


## CW_AUTOCANNON_25_JGSDF: 87式ARV 25mm機関砲（KBA-B02）
## 25mm APDS-T: 50-60mm @ 1km
static func create_cw_autocannon_25_jgsdf() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_25_JGSDF"
	w.display_name = "25mm Autocannon (Type 87)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [400.0, 1000.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 10.0  # 400発
	w.rof_rpm = 570.0  # 高発射レート

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 40,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 30,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 55,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 20,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 70,
		RangeBand.FAR: 50,
	}

	# 25mm APDS-T: 55mm = 11 (RHA scale @ 1km)
	w.pen_ke = {
		RangeBand.NEAR: 14,   # 70mm RHA相当
		RangeBand.MID: 11,    # 55mm RHA相当
		RangeBand.FAR: 8,     # 40mm RHA相当
	}

	w.projectile_speed_mps = 1100.0
	w.projectile_size = 2.0

	return w


## CW_ATGM_79MAT: 79式対舟艇対戦車誘導弾（重MAT）
## SACLOS誘導、タンデムHEAT、射程4km
## 89式IFVに搭載
static func create_cw_atgm_79mat() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_79MAT"
	w.display_name = "Type 79 Heavy MAT"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 200.0  # 最小射程200m
	w.max_range_m = 4000.0  # 最大射程4km
	w.range_band_thresholds_m = [800.0, 2500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 3.0  # 即応2発、予備4発
	w.rof_rpm = 2.0  # 再装填に時間がかかる
	w.sigma_hit_m = 1.5  # SACLOS誘導
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,  # MBT正面にも有効
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 65,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 55,
		RangeBand.MID: 50,
		RangeBand.FAR: 45,
	}

	# タンデムHEAT: 550mm (対ERA後) = 110 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 110,
		RangeBand.MID: 110,
		RangeBand.FAR: 110,
	}

	w.projectile_speed_mps = 200.0  # SACLOS誘導
	w.projectile_size = 6.0

	return w


## CW_ATGM_MMPM: 中距離多目的誘導弾
## Fire-and-Forget (IIR+SALH)、トップアタック可能
## 射程5-8km、タンデムHEAT
static func create_cw_atgm_mmpm() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_MMPM"
	w.display_name = "MMPM"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 300.0
	w.max_range_m = 5000.0  # 実際は5-8km
	w.range_band_thresholds_m = [1000.0, 3000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 2.0  # 4連装
	w.rof_rpm = 4.0  # Fire-and-Forget、連続発射可能
	w.sigma_hit_m = 0.5  # 高精度誘導
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,  # トップアタックでMBT確殺
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 98,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# タンデムHEAT: 750mm = 150 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 150,
		RangeBand.MID: 150,
		RangeBand.FAR: 150,
	}

	w.projectile_speed_mps = 250.0  # 比較的高速
	w.projectile_size = 5.0

	return w


## CW_ATGM_01LMAT: 01式軽対戦車誘導弾
## Fire-and-Forget (IIR)、歩兵携行、トップアタック可能
## 射程2km、タンデムHEAT
static func create_cw_atgm_01lmat() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_01LMAT"
	w.display_name = "Type 01 LMAT"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 100.0  # 最小射程100m
	w.max_range_m = 2000.0  # 最大射程2km
	w.range_band_thresholds_m = [400.0, 1200.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 1.5  # 携行数限定
	w.rof_rpm = 1.5  # Fire-and-Forget
	w.sigma_hit_m = 0.8  # IIR誘導で高精度
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 6.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,  # トップアタックでMBTに有効
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
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

	# タンデムHEAT: 650mm = 130 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 130,
		RangeBand.MID: 130,
		RangeBand.FAR: 130,
	}

	w.projectile_speed_mps = 180.0
	w.projectile_size = 4.5

	return w


## CW_ATGM_BEAMRIDE: ビームライディングATGM（Kornet-EM相当）
static func create_cw_atgm_beamride() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_BEAMRIDE"
	w.display_name = "ATGM Beam Riding"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 100.0
	w.max_range_m = 5500.0  # Kornet-EM長射程
	w.range_band_thresholds_m = [1000.0, 3000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 3.0
	w.rof_rpm = 2.0
	w.sigma_hit_m = 1.0
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 55,
		RangeBand.MID: 50,
		RangeBand.FAR: 45,
	}

	# Kornet-EM タンデム: 1200mm RHA (ERA貫通後)
	w.pen_ce = {
		RangeBand.NEAR: 200,  # 1000mm RHA
		RangeBand.MID: 200,
		RangeBand.FAR: 200,
	}

	w.projectile_speed_mps = 300.0
	w.projectile_size = 6.0

	return w


# =============================================================================
# 米軍専用武器
# =============================================================================

## CW_TANK_KE_120_USA: M1 Abrams 120mm M256砲（M829A4 APFSDS）
## M829A4: 推定750mm @ 2km (DU弾、対ERA/APS設計)
## M829A3: 推定675mm @ 2km
## RHA換算スケール: 100 = 500mm RHA
static func create_cw_tank_ke_120_usa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_120_USA"
	w.display_name = "120mm M256 (M829A4)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 3500.0  # M829A4は4km+有効
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 12.0  # 42発搭載
	w.rof_rpm = 7.0  # 手動装填（6-8発/分）
	w.sigma_hit_m = 1.0  # 高精度FCS
	w.direct_hit_radius_m = 2.0
	w.shock_radius_m = 5.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 98,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 98,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# M829A4: 750mm = 150 (RHA scale) - 最高クラスのKE弾
	w.pen_ke = {
		RangeBand.NEAR: 160,  # 800mm RHA相当（近距離）
		RangeBand.MID: 150,   # 750mm RHA相当（2km）
		RangeBand.FAR: 140,   # 700mm RHA相当（3km+）
	}

	w.projectile_speed_mps = 1750.0
	w.projectile_size = 4.0

	return w


## CW_TANK_HEAT_USA: M1 Abrams 120mm M830A1 MPAT
## M830A1: 350mm HEAT、1400m/s、対ヘリ可能
static func create_cw_tank_heat_usa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_HEAT_USA"
	w.display_name = "120mm M830A1 MPAT"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 2500.0
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ANY  # 対ヘリ可
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 7.0
	w.sigma_hit_m = 1.5
	w.direct_hit_radius_m = 2.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 65,  # MBT正面には不十分
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 45,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 55,
		RangeBand.MID: 50,
		RangeBand.FAR: 45,
	}

	# M830A1: 350mm = 70 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 70,
		RangeBand.FAR: 70,
	}

	w.projectile_speed_mps = 1400.0  # 高速HEAT
	w.projectile_size = 4.0

	return w


## CW_AUTOCANNON_25_USA: M242 Bushmaster 25mm（M919 DU APFSDS）
## M919 APFSDS-T: 推定90mm @ 1km (DU弾、対BMP)
## M791 APDS-T: 55mm @ 1km (タングステン)
static func create_cw_autocannon_25_usa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_25_USA"
	w.display_name = "25mm M242 (M919)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 2500.0
	w.range_band_thresholds_m = [400.0, 1200.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 8.0  # 300発即応
	w.rof_rpm = 200.0  # 可変100-200発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 15,  # MBTには効果薄
			TargetClass.FORTIFIED: 50,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 40,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 30,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 55,
		RangeBand.FAR: 45,
	}

	# M919 DU APFSDS: 推定90mm = 18 (RHA scale)
	w.pen_ke = {
		RangeBand.NEAR: 20,  # 100mm RHA相当
		RangeBand.MID: 18,   # 90mm RHA相当
		RangeBand.FAR: 14,   # 70mm RHA相当
	}

	w.projectile_speed_mps = 1385.0  # M919
	w.projectile_size = 1.0

	return w


## CW_AUTOCANNON_30_USA: XM813 30mm Bushmaster II（Stryker Dragoon）
## MK258 APFSDS-T: 55mm @ 1km (60°)
static func create_cw_autocannon_30_usa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_30_USA"
	w.display_name = "30mm XM813"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 3000.0  # 精密射撃3km
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 200.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 98,
			TargetClass.HEAVY: 20,
			TargetClass.FORTIFIED: 55,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 92,
			TargetClass.HEAVY: 15,
			TargetClass.FORTIFIED: 45,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 35,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 60,
		RangeBand.FAR: 50,
	}

	# MK258 APFSDS: 55mm @ 60° = 約14 (RHA scale)
	# 垂直換算でより高い
	w.pen_ke = {
		RangeBand.NEAR: 22,  # 110mm RHA相当
		RangeBand.MID: 18,   # 90mm RHA相当
		RangeBand.FAR: 14,   # 70mm RHA相当
	}

	w.projectile_speed_mps = 1405.0
	w.projectile_size = 1.2

	return w


## CW_ATGM_TOW2B: BGM-71F TOW-2B（トップアタック）
## デュアルEFP、射程3750m（Aero: 4500m）
## トップアタック: 推定300mm
static func create_cw_atgm_tow2b() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_TOW2B"
	w.display_name = "TOW-2B"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 65.0  # 最小射程
	w.max_range_m = 4500.0  # TOW-2B Aero
	w.range_band_thresholds_m = [1000.0, 2500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 2.0  # 2発搭載（Bradley）
	w.rof_rpm = 2.0  # SACLOS誘導
	w.sigma_hit_m = 0.8
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 6.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,  # トップアタックでMBT有効
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 65,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 35,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 60,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 45,
		RangeBand.MID: 40,
		RangeBand.FAR: 35,
	}

	# TOW-2B トップアタック: 300mm = 60 (RHA scale)
	# デュアルEFPで屋根装甲を貫通
	w.pen_ce = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 60,
		RangeBand.FAR: 60,
	}

	w.projectile_speed_mps = 300.0
	w.projectile_size = 5.0

	return w


## CW_ATGM_JAVELIN: FGM-148 Javelin（Fire-and-Forget、トップアタック）
## タンデムHEAT: 800mm、射程2500m
static func create_cw_atgm_javelin() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_JAVELIN"
	w.display_name = "FGM-148 Javelin"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 65.0  # 最小射程
	w.max_range_m = 2500.0  # 標準射程（実証4km）
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 1.5  # 携行数限定
	w.rof_rpm = 1.5  # Fire-and-Forget
	w.sigma_hit_m = 0.5  # IIR誘導で高精度
	w.direct_hit_radius_m = 1.5
	w.shock_radius_m = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,  # トップアタックでMBT確殺
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 98,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 80,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 50,
		RangeBand.MID: 45,
		RangeBand.FAR: 40,
	}

	# タンデムHEAT: 800mm = 160 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 160,
		RangeBand.MID: 160,
		RangeBand.FAR: 160,
	}

	w.projectile_speed_mps = 140.0
	w.projectile_size = 4.5

	return w


## CW_AGL_MK19: MK19 40mm自動擲弾銃
## HEDP: 75mm貫徹、射程1600m
static func create_cw_agl_mk19() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AGL_MK19"
	w.display_name = "MK19 40mm AGL"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 75.0  # 安全距離
	w.max_range_m = 1600.0  # 有効射程
	w.range_band_thresholds_m = [300.0, 800.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 6.0
	w.rof_rpm = 350.0  # 325-375発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 55,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 45,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 75,
		RangeBand.FAR: 60,
	}

	# HEDP: 75mm = 15 (RHA scale)
	w.pen_ce = {
		RangeBand.NEAR: 15,
		RangeBand.MID: 15,
		RangeBand.FAR: 15,
	}

	w.blast_radius_m = 5.0  # 殺傷5m、負傷15m
	w.projectile_speed_mps = 241.0
	w.projectile_size = 1.5

	return w


## CW_M240_COAX: M240C 7.62mm同軸機関銃
static func create_cw_m240_coax() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_M240_COAX"
	w.display_name = "M240C 7.62mm Coax"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1500.0  # 実用射程
	w.range_band_thresholds_m = [200.0, 600.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 15.0
	w.rof_rpm = 750.0  # 650-950発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 25,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 20,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 15,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 45,
			TargetClass.LIGHT: 5,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 55,
		RangeBand.FAR: 40,
	}

	w.projectile_speed_mps = 853.0
	w.projectile_size = 0.3

	return w


## CW_M2HB: M2HB 12.7mm重機関銃
static func create_cw_m2hb() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_M2HB"
	w.display_name = "M2HB .50 Cal"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1800.0  # 有効射程
	w.range_band_thresholds_m = [300.0, 900.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 10.0
	w.rof_rpm = 550.0  # 450-600発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 55,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 40,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 40,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 30,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 25,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 20,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 65,
		RangeBand.FAR: 50,
	}

	# 12.7mm AP: 19mm @ 1370m
	w.pen_ke = {
		RangeBand.NEAR: 5,   # 25mm
		RangeBand.MID: 4,    # 20mm
		RangeBand.FAR: 3,    # 15mm
	}

	w.projectile_speed_mps = 890.0
	w.projectile_size = 0.5

	return w


## 全ConcreteWeaponSetを取得
static func get_all_concrete_weapons() -> Dictionary:
	return {
		# 汎用
		"CW_RIFLE_STD": create_cw_rifle_std(),
		"CW_MG_STD": create_cw_mg_std(),
		"CW_HMG": create_cw_hmg(),
		"CW_RPG_HEAT": create_cw_rpg_heat(),
		"CW_CARL_GUSTAF": create_cw_carl_gustaf(),
		"CW_COAX_MG": create_cw_coax_mg(),
		# 機関砲（汎用）
		"CW_AUTOCANNON_25": create_cw_autocannon_25(),
		"CW_AUTOCANNON_30": create_cw_autocannon_30(),
		"CW_AUTOCANNON_35": create_cw_autocannon_35(),
		# ATGM（汎用）
		"CW_ATGM": create_cw_atgm(),
		"CW_ATGM_TOPATTACK": create_cw_atgm_topattack(),
		"CW_ATGM_BEAMRIDE": create_cw_atgm_beamride(),
		# 戦車砲（汎用）
		"CW_TANK_KE": create_cw_tank_ke(),
		"CW_TANK_KE_125": create_cw_tank_ke_125(),
		"CW_TANK_KE_105": create_cw_tank_ke_105(),
		"CW_TANK_HEATMP": create_cw_tank_heatmp(),
		# 間接火力
		"CW_MORTAR_HE": create_cw_mortar_he(),
		"CW_MORTAR_81": create_cw_mortar_81(),
		"CW_MORTAR_SMOKE": create_cw_mortar_smoke(),
		"CW_MORTAR_120": create_cw_mortar_120(),
		"CW_HOWITZER_152": create_cw_howitzer_152(),
		"CW_HOWITZER_155": create_cw_howitzer_155(),
		# 自衛隊専用
		"CW_TANK_KE_120_JGSDF": create_cw_tank_ke_120_jgsdf(),
		"CW_TANK_KE_105_JGSDF": create_cw_tank_ke_105_jgsdf(),
		"CW_AUTOCANNON_35_JGSDF": create_cw_autocannon_35_jgsdf(),
		"CW_AUTOCANNON_25_JGSDF": create_cw_autocannon_25_jgsdf(),
		"CW_ATGM_79MAT": create_cw_atgm_79mat(),
		"CW_ATGM_MMPM": create_cw_atgm_mmpm(),
		"CW_ATGM_01LMAT": create_cw_atgm_01lmat(),
		# 米軍専用
		"CW_TANK_KE_120_USA": create_cw_tank_ke_120_usa(),
		"CW_TANK_HEAT_USA": create_cw_tank_heat_usa(),
		"CW_AUTOCANNON_25_USA": create_cw_autocannon_25_usa(),
		"CW_AUTOCANNON_30_USA": create_cw_autocannon_30_usa(),
		"CW_ATGM_TOW2B": create_cw_atgm_tow2b(),
		"CW_ATGM_JAVELIN": create_cw_atgm_javelin(),
		"CW_AGL_MK19": create_cw_agl_mk19(),
		"CW_M240_COAX": create_cw_m240_coax(),
		"CW_M2HB": create_cw_m2hb(),
	}
