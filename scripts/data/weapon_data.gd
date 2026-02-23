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
	w.weapon_role = WeaponRole.MAIN_GUN_KE  # APFSDS系
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
	w.weapon_role = WeaponRole.MAIN_GUN_CE  # HEAT/HE-MP系
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


# =============================================================================
# ロシア軍専用武器
# =============================================================================

## CW_TANK_KE_125_RUS: ロシア軍125mm滑腔砲 (2A46M-5/2A82-1M) - 3BM60 Svinets-2
## T-90M, T-80BVM等に搭載
static func create_cw_tank_ke_125_rus() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125_RUS"
	w.display_name = "125mm 2A46M-5 (3BM60)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [1500.0, 3000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 15.0  # 自動装填装置
	w.rof_rpm = 7.0  # 自動装填: 7-8発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 100,
		RangeBand.MID: 95,
		RangeBand.FAR: 85,
	}

	# 3BM60 Svinets-2: 700mm RHA @ 2km (pen_ke = 700/5 = 140)
	w.pen_ke = {
		RangeBand.NEAR: 150,  # 750mm
		RangeBand.MID: 140,   # 700mm
		RangeBand.FAR: 125,   # 625mm
	}

	w.projectile_speed_mps = 1780.0
	w.projectile_size = 3.0

	return w


## CW_TANK_KE_125_MANGO: ロシア軍125mm滑腔砲 - 3BM42 Mango
## T-72B3, T-80U等に搭載（旧世代弾薬）
static func create_cw_tank_ke_125_mango() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125_MANGO"
	w.display_name = "125mm 2A46M (3BM42)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [1500.0, 3000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 15.0
	w.rof_rpm = 7.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 60,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 100,
		RangeBand.MID: 95,
		RangeBand.FAR: 85,
	}

	# 3BM42 Mango: 500mm RHA @ 2km (pen_ke = 500/5 = 100)
	w.pen_ke = {
		RangeBand.NEAR: 110,  # 550mm
		RangeBand.MID: 100,   # 500mm
		RangeBand.FAR: 85,    # 425mm
	}

	w.projectile_speed_mps = 1700.0
	w.projectile_size = 3.0

	return w


## CW_AUTOCANNON_30_RUS: ロシア軍30mm機関砲 (2A42/2A72)
## BMP-2, BMP-3, BTR-82A等に搭載
static func create_cw_autocannon_30_rus() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_30_RUS"
	w.display_name = "30mm 2A42/2A72"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [800.0, 2000.0]
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 550.0  # 2A42: 200-800発/分 (デュアルフィード)

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 25,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 75,
			TargetClass.HEAVY: 15,
			TargetClass.FORTIFIED: 55,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 50,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 35,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 70,
		RangeBand.FAR: 50,
	}

	# 3UBR8 APDS: 60-70mm @ 1km (pen_ke = 65/5 = 13)
	w.pen_ke = {
		RangeBand.NEAR: 14,   # 70mm
		RangeBand.MID: 12,    # 60mm
		RangeBand.FAR: 8,     # 40mm
	}

	w.projectile_speed_mps = 1120.0
	w.projectile_size = 1.0

	return w


## CW_AUTOCANNON_100_RUS: BMP-3 100mm低圧砲 (2A70)
## HE弾メイン、対ソフトターゲット
static func create_cw_autocannon_100_rus() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_100_RUS"
	w.display_name = "100mm 2A70 低圧砲"
	w.mechanism = Mechanism.BLAST_FRAG
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 50.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [1000.0, 2500.0]
	w.threat_class = ThreatClass.HE_FRAG
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 12.0  # 22発HE + 8発ATGM
	w.rof_rpm = 10.0  # 自動装填

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 30,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 75,
			TargetClass.HEAVY: 20,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 60,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 55,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 90,
		RangeBand.MID: 80,
		RangeBand.FAR: 65,
	}

	# HEAT弾: 約500mm
	w.pen_ce = {
		RangeBand.NEAR: 100,  # 500mm
		RangeBand.MID: 100,   # 500mm
		RangeBand.FAR: 100,   # 500mm
	}

	w.blast_radius_m = 8.0  # HE弾効果
	w.projectile_speed_mps = 355.0  # 低圧砲
	w.projectile_size = 2.0

	return w


## CW_HMG_KPVT: ロシア軍14.5mm重機関銃 (KPVT)
## BTR-80等に搭載
static func create_cw_hmg_kpvt() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_HMG_KPVT"
	w.display_name = "14.5mm KPVT"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [400.0, 1000.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 600.0  # 550-600発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 50,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 50,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 35,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 30,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 20,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 70,
		RangeBand.FAR: 55,
	}

	# 14.5mm BS-41: 32mm @ 500m (pen_ke = 32/5 = 6.4)
	w.pen_ke = {
		RangeBand.NEAR: 8,    # 40mm
		RangeBand.MID: 6,     # 30mm
		RangeBand.FAR: 4,     # 20mm
	}

	w.projectile_speed_mps = 1000.0
	w.projectile_size = 0.6

	return w


## CW_PKT_COAX: ロシア軍7.62mm同軸機銃 (PKT/PKTM)
static func create_cw_pkt_coax() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_PKT_COAX"
	w.display_name = "7.62mm PKT 同軸機銃"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1000.0
	w.range_band_thresholds_m = [200.0, 500.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 12.0  # 2000発ベルト
	w.rof_rpm = 750.0  # 700-800発/分

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 30,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 25,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 20,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 55,
		RangeBand.FAR: 40,
	}

	w.projectile_speed_mps = 855.0
	w.projectile_size = 0.3

	return w


## CW_KORD_AA: ロシア軍12.7mm重機関銃 (Kord)
## T-90M, T-80BVM等の対空機銃
static func create_cw_kord_aa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_KORD_AA"
	w.display_name = "12.7mm Kord"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.min_range_m = 0.0
	w.max_range_m = 1500.0
	w.range_band_thresholds_m = [300.0, 800.0]
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 700.0  # 650-750発/分

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

	# 12.7mm B-32: 20mm @ 500m (pen_ke = 4-5)
	w.pen_ke = {
		RangeBand.NEAR: 5,    # 25mm
		RangeBand.MID: 4,     # 20mm
		RangeBand.FAR: 3,     # 15mm
	}

	w.projectile_speed_mps = 850.0
	w.projectile_size = 0.5

	return w


## CW_ATGM_KORNET: 9M133 Kornet ATGM
## 最新のロシア軍ATGM、タンデム弾頭
static func create_cw_atgm_kornet() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_KORNET"
	w.display_name = "9M133 Kornet"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 100.0
	w.max_range_m = 5500.0  # Kornet-EM: 8km
	w.range_band_thresholds_m = [1500.0, 4000.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 8.0
	w.rof_rpm = 3.0
	w.requires_observer = false  # レーザービームライディング

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 95,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 85,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 90,
		RangeBand.MID: 85,
		RangeBand.FAR: 80,
	}

	# Kornet: 1200-1300mm RHA (ERA後) (pen_ce = 1200/5 = 240)
	w.pen_ce = {
		RangeBand.NEAR: 240,  # 1200mm
		RangeBand.MID: 240,   # 1200mm
		RangeBand.FAR: 240,   # 1200mm
	}

	w.projectile_speed_mps = 300.0  # 亜音速
	w.projectile_size = 1.5

	return w


## CW_ATGM_REFLEKS: 9M119M Refleks (AT-11 Sniper-B)
## T-90, T-80等の砲発射式ATGM
static func create_cw_atgm_refleks() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_REFLEKS"
	w.display_name = "9M119M Refleks"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 100.0
	w.max_range_m = 5000.0
	w.range_band_thresholds_m = [1500.0, 3500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 6.0  # カルーセル内に限定搭載
	w.rof_rpm = 3.0
	w.requires_observer = false

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 80,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 80,
		RangeBand.FAR: 75,
	}

	# Refleks: 850-900mm RHA (タンデム) (pen_ce = 900/5 = 180)
	w.pen_ce = {
		RangeBand.NEAR: 180,  # 900mm
		RangeBand.MID: 180,   # 900mm
		RangeBand.FAR: 180,   # 900mm
	}

	w.projectile_speed_mps = 350.0
	w.projectile_size = 1.5

	return w


## CW_ATGM_KONKURS: 9M113M Konkurs-M (AT-5B Spandrel)
## BMP-2等の車載ATGM
static func create_cw_atgm_konkurs() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_KONKURS"
	w.display_name = "9M113M Konkurs-M"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 75.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [1000.0, 2500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 5.0
	w.rof_rpm = 2.0  # SACLOS、再装填時間長い

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 75,
		RangeBand.FAR: 65,
	}

	# Konkurs-M: 750-800mm RHA (タンデム) (pen_ce = 800/5 = 160)
	w.pen_ce = {
		RangeBand.NEAR: 160,  # 800mm
		RangeBand.MID: 160,   # 800mm
		RangeBand.FAR: 160,   # 800mm
	}

	w.projectile_speed_mps = 200.0  # 低速ワイヤー誘導
	w.projectile_size = 1.2

	return w


## CW_ATGM_BASTION: 9M117 Bastion (AT-10 Stabber)
## BMP-3 100mm砲発射式ATGM
static func create_cw_atgm_bastion() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_BASTION"
	w.display_name = "9M117 Bastion"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.min_range_m = 100.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [1000.0, 2500.0]
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.ammo_endurance_min = 5.0  # 100mm砲と弾倉共有
	w.rof_rpm = 3.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 45,
			TargetClass.FORTIFIED: 65,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 75,
		RangeBand.MID: 70,
		RangeBand.FAR: 60,
	}

	# Bastion: 550mm RHA (pen_ce = 550/5 = 110)
	w.pen_ce = {
		RangeBand.NEAR: 110,  # 550mm
		RangeBand.MID: 110,   # 550mm
		RangeBand.FAR: 110,   # 550mm
	}

	w.projectile_speed_mps = 370.0
	w.projectile_size = 1.2

	return w


# =============================================================================
# 中国軍専用武器
# =============================================================================

## 125mm ZPT-98 (DTC10-125 APFSDS) - Type 99A
static func create_cw_tank_ke_125_chn() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125_CHN"
	w.display_name = "125mm ZPT-98 (DTC10-125)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 0.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 80,
		RangeBand.FAR: 70,
	}

	# DTC10-125 APFSDS: 960mm @ 1000m, 800mm @ 2000m
	w.pen_ke = {
		RangeBand.NEAR: 192,  # 960mm
		RangeBand.MID: 160,   # 800mm
		RangeBand.FAR: 130,   # 650mm
	}

	w.projectile_speed_mps = 1780.0
	w.projectile_size = 1.5

	return w


## 125mm ZPT-98 (DTW-125 Type II) - Type 99, Type 96A
static func create_cw_tank_ke_125_chn_std() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125_CHN_STD"
	w.display_name = "125mm ZPT-98 (DTW-125 II)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 0.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 70,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 80,
		RangeBand.FAR: 70,
	}

	# DTW-125 Type II: 750mm @ 500m, 700mm @ 1000m
	w.pen_ke = {
		RangeBand.NEAR: 150,  # 750mm
		RangeBand.MID: 140,   # 700mm
		RangeBand.FAR: 115,   # 575mm
	}

	w.projectile_speed_mps = 1700.0
	w.projectile_size = 1.5

	return w


## 125mm ZPT-96 (DTW-125) - Type 96
static func create_cw_tank_ke_125_chn_old() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_125_CHN_OLD"
	w.display_name = "125mm ZPT-96 (DTW-125)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 0.0
	w.max_range_m = 3500.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 8.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 75,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 60,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 85,
		RangeBand.MID: 80,
		RangeBand.FAR: 70,
	}

	# DTW-125 (first gen): 650mm @ 500m, 550mm @ 1000m
	w.pen_ke = {
		RangeBand.NEAR: 130,  # 650mm
		RangeBand.MID: 110,   # 550mm
		RangeBand.FAR: 90,    # 450mm
	}

	w.projectile_speed_mps = 1650.0
	w.projectile_size = 1.5

	return w


## 105mm ZPL-151 Rifled - Type 15 Light Tank
static func create_cw_tank_ke_105_chn() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_105_CHN"
	w.display_name = "105mm ZPL-151"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 0.0
	w.max_range_m = 3000.0
	w.range_band_thresholds_m = [400.0, 1500.0]
	w.rof_rpm = 10.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 65,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 55,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 80,
		RangeBand.MID: 75,
		RangeBand.FAR: 65,
	}

	# Modern 105mm APFSDS: 550mm @ 500m, 500mm @ 2000m
	w.pen_ke = {
		RangeBand.NEAR: 110,  # 550mm
		RangeBand.MID: 100,   # 500mm
		RangeBand.FAR: 85,    # 425mm
	}

	w.projectile_speed_mps = 1500.0
	w.projectile_size = 1.3

	return w


## 105mm Type 83 Rifled - Type 63A, ZTL-11
static func create_cw_tank_ke_105_chn_old() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TANK_KE_105_CHN_OLD"
	w.display_name = "105mm Type 83"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 0.0
	w.max_range_m = 2500.0
	w.range_band_thresholds_m = [400.0, 1500.0]
	w.rof_rpm = 7.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 40,
			TargetClass.FORTIFIED: 50,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 75,
		RangeBand.MID: 70,
		RangeBand.FAR: 60,
	}

	# Standard 105mm APFSDS: 450mm @ 500m, 400mm @ 1000m
	w.pen_ke = {
		RangeBand.NEAR: 90,   # 450mm
		RangeBand.MID: 80,    # 400mm
		RangeBand.FAR: 65,    # 325mm
	}

	w.projectile_speed_mps = 1400.0
	w.projectile_size = 1.3

	return w


## 30mm ZPT-99 Autocannon - ZBD-04A, ZBD-09, ZBD-03
static func create_cw_autocannon_30_chn() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_30_CHN"
	w.display_name = "30mm ZPT-99"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.min_range_m = 0.0
	w.max_range_m = 2000.0
	w.range_band_thresholds_m = [300.0, 1000.0]
	w.rof_rpm = 300.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 30,
			TargetClass.FORTIFIED: 45,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 70,
			TargetClass.HEAVY: 20,
			TargetClass.FORTIFIED: 35,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 60,
			TargetClass.LIGHT: 55,
			TargetClass.HEAVY: 10,
			TargetClass.FORTIFIED: 25,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 55,
		RangeBand.FAR: 40,
	}

	# 30mm APFSDS: 70mm @ 500m, 60mm @ 1000m
	w.pen_ke = {
		RangeBand.NEAR: 14,   # 70mm
		RangeBand.MID: 12,    # 60mm
		RangeBand.FAR: 8,     # 40mm
	}

	w.projectile_speed_mps = 970.0
	w.projectile_size = 0.4

	return w


## 35mm Type 90 (PG99) Twin Autocannon - PGZ-09
static func create_cw_autocannon_35_chn() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_35_CHN"
	w.display_name = "35mm Type 90 (PG99)"
	w.mechanism = Mechanism.KINETIC
	w.fire_model = FireModel.CONTINUOUS
	w.threat_class = ThreatClass.AUTOCANNON
	w.preferred_target = PreferredTarget.ANY
	w.min_range_m = 0.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 1100.0  # Twin mount combined

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 35,
			TargetClass.FORTIFIED: 50,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 75,
			TargetClass.HEAVY: 25,
			TargetClass.FORTIFIED: 40,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 65,
			TargetClass.LIGHT: 60,
			TargetClass.HEAVY: 15,
			TargetClass.FORTIFIED: 30,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 75,
		RangeBand.MID: 65,
		RangeBand.FAR: 50,
	}

	# 35mm APDS: 90mm NEAR, 70mm MID
	w.pen_ke = {
		RangeBand.NEAR: 18,   # 90mm
		RangeBand.MID: 14,    # 70mm
		RangeBand.FAR: 10,    # 50mm
	}

	w.projectile_speed_mps = 1175.0
	w.projectile_size = 0.45

	return w


## 100mm Gun/Missile Launcher - ZBD-04
static func create_cw_autocannon_100_chn() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_AUTOCANNON_100_CHN"
	w.display_name = "100mm Gun-Launcher"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 100.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 10.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 75,
			TargetClass.LIGHT: 80,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 60,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 70,
		RangeBand.MID: 65,
		RangeBand.FAR: 55,
	}

	# 100mm ATGM capability: 600mm
	w.pen_ce = {
		RangeBand.NEAR: 120,  # 600mm
		RangeBand.MID: 120,   # 600mm
		RangeBand.FAR: 100,   # 500mm (HE-FRAG reduced)
	}

	w.projectile_speed_mps = 355.0
	w.projectile_size = 1.0

	return w


## HJ-10 (Red Arrow-10) / AFT-10 - Fire-and-forget
static func create_cw_atgm_hj10() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_HJ10"
	w.display_name = "HJ-10 (Red Arrow-10)"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 3000.0  # Long minimum range
	w.max_range_m = 10000.0
	w.range_band_thresholds_m = [4000.0, 7000.0]
	w.rof_rpm = 2.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,
			TargetClass.FORTIFIED: 95,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 100,
			TargetClass.FORTIFIED: 95,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 90,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 55,
		RangeBand.FAR: 50,
	}

	# HJ-10: 1400mm RHA post-ERA (pen_ce = 280)
	w.pen_ce = {
		RangeBand.NEAR: 280,  # 1400mm
		RangeBand.MID: 280,   # 1400mm
		RangeBand.FAR: 280,   # 1400mm
	}

	w.projectile_speed_mps = 230.0  # Terminal speed
	w.projectile_size = 1.3

	return w


## HJ-9 (Red Arrow-9)
static func create_cw_atgm_hj9() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_HJ9"
	w.display_name = "HJ-9 (Red Arrow-9)"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 100.0
	w.max_range_m = 5500.0
	w.range_band_thresholds_m = [1000.0, 3000.0]
	w.rof_rpm = 3.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 95,
			TargetClass.FORTIFIED: 90,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 90,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 80,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 60,
		RangeBand.FAR: 55,
	}

	# HJ-9: 1200mm RHA (pen_ce = 240)
	w.pen_ce = {
		RangeBand.NEAR: 240,  # 1200mm
		RangeBand.MID: 240,   # 1200mm
		RangeBand.FAR: 240,   # 1200mm
	}

	w.projectile_speed_mps = 300.0
	w.projectile_size = 1.2

	return w


## HJ-8E (Red Arrow-8E) - Tandem HEAT
static func create_cw_atgm_hj8e() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_HJ8E"
	w.display_name = "HJ-8E (Red Arrow-8E)"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 100.0
	w.max_range_m = 4000.0
	w.range_band_thresholds_m = [500.0, 2000.0]
	w.rof_rpm = 3.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 100,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 85,
			TargetClass.FORTIFIED: 85,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 80,
			TargetClass.FORTIFIED: 80,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 75,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 65,
		RangeBand.MID: 60,
		RangeBand.FAR: 50,
	}

	# HJ-8E: 1000mm RHA post-ERA (pen_ce = 200)
	w.pen_ce = {
		RangeBand.NEAR: 200,  # 1000mm
		RangeBand.MID: 200,   # 1000mm
		RangeBand.FAR: 200,   # 1000mm
	}

	w.projectile_speed_mps = 240.0
	w.projectile_size = 1.1

	return w


## HJ-73 (Red Arrow-73) - Legacy ATGM
static func create_cw_atgm_hj73() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_HJ73"
	w.display_name = "HJ-73 (Red Arrow-73)"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 100.0
	w.max_range_m = 3000.0
	w.range_band_thresholds_m = [500.0, 1500.0]
	w.rof_rpm = 3.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 45,
			TargetClass.FORTIFIED: 60,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 85,
			TargetClass.HEAVY: 35,
			TargetClass.FORTIFIED: 50,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 55,
		RangeBand.FAR: 45,
	}

	# HJ-73: 425mm RHA (pen_ce = 85) - first gen, no tandem
	w.pen_ce = {
		RangeBand.NEAR: 85,   # 425mm
		RangeBand.MID: 85,    # 425mm
		RangeBand.FAR: 85,    # 425mm
	}

	w.projectile_speed_mps = 120.0
	w.projectile_size = 1.0

	return w


## GP105 Gun-Launched ATGM - Type 15, ZTL-11
static func create_cw_atgm_gp105() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_ATGM_GP105"
	w.display_name = "GP105 Gun-Launched ATGM"
	w.mechanism = Mechanism.SHAPED_CHARGE
	w.fire_model = FireModel.DISCRETE
	w.threat_class = ThreatClass.AT
	w.preferred_target = PreferredTarget.ARMOR
	w.min_range_m = 500.0
	w.max_range_m = 5200.0
	w.range_band_thresholds_m = [1000.0, 3000.0]
	w.rof_rpm = 3.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 95,
			TargetClass.LIGHT: 100,
			TargetClass.HEAVY: 70,
			TargetClass.FORTIFIED: 75,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 90,
			TargetClass.LIGHT: 95,
			TargetClass.HEAVY: 65,
			TargetClass.FORTIFIED: 70,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 85,
			TargetClass.LIGHT: 90,
			TargetClass.HEAVY: 55,
			TargetClass.FORTIFIED: 60,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 55,
		RangeBand.FAR: 50,
	}

	# GP105: 700mm RHA (pen_ce = 140)
	w.pen_ce = {
		RangeBand.NEAR: 140,  # 700mm
		RangeBand.MID: 140,   # 700mm
		RangeBand.FAR: 140,   # 700mm
	}

	w.projectile_speed_mps = 370.0
	w.projectile_size = 1.1

	return w


## 12.7mm QJZ-89 (Type 89 HMG) - AA mount
static func create_cw_qjz89_aa() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_QJZ89_AA"
	w.display_name = "12.7mm QJZ-89"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.min_range_m = 0.0
	w.max_range_m = 1800.0
	w.range_band_thresholds_m = [300.0, 800.0]
	w.rof_rpm = 550.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 80,
			TargetClass.LIGHT: 45,
			TargetClass.HEAVY: 5,
			TargetClass.FORTIFIED: 25,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 70,
			TargetClass.LIGHT: 35,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 15,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 55,
			TargetClass.LIGHT: 25,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 60,
		RangeBand.MID: 50,
		RangeBand.FAR: 35,
	}

	# 12.7mm API: 25mm @ 100m, 20mm @ 500m
	w.pen_ke = {
		RangeBand.NEAR: 5,    # 25mm
		RangeBand.MID: 4,     # 20mm
		RangeBand.FAR: 3,     # 15mm
	}

	w.projectile_speed_mps = 850.0
	w.projectile_size = 0.15

	return w


## 7.62mm Type 86 Coaxial MG
static func create_cw_type86_coax() -> WeaponType:
	var w := WeaponType.new()
	w.id = "CW_TYPE86_COAX"
	w.display_name = "7.62mm Type 86"
	w.mechanism = Mechanism.SMALL_ARMS
	w.fire_model = FireModel.CONTINUOUS
	w.threat_class = ThreatClass.SMALL_ARMS
	w.preferred_target = PreferredTarget.SOFT
	w.min_range_m = 0.0
	w.max_range_m = 1000.0
	w.range_band_thresholds_m = [200.0, 500.0]
	w.rof_rpm = 700.0

	w.lethality = {
		RangeBand.NEAR: {
			TargetClass.SOFT: 50,
			TargetClass.LIGHT: 10,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 10,
		},
		RangeBand.MID: {
			TargetClass.SOFT: 40,
			TargetClass.LIGHT: 5,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 5,
		},
		RangeBand.FAR: {
			TargetClass.SOFT: 25,
			TargetClass.LIGHT: 0,
			TargetClass.HEAVY: 0,
			TargetClass.FORTIFIED: 0,
		},
	}

	w.suppression_power = {
		RangeBand.NEAR: 45,
		RangeBand.MID: 35,
		RangeBand.FAR: 25,
	}

	w.projectile_speed_mps = 825.0
	w.projectile_size = 0.08

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
		# ロシア軍専用
		"CW_TANK_KE_125_RUS": create_cw_tank_ke_125_rus(),
		"CW_TANK_KE_125_MANGO": create_cw_tank_ke_125_mango(),
		"CW_AUTOCANNON_30_RUS": create_cw_autocannon_30_rus(),
		"CW_AUTOCANNON_100_RUS": create_cw_autocannon_100_rus(),
		"CW_HMG_KPVT": create_cw_hmg_kpvt(),
		"CW_PKT_COAX": create_cw_pkt_coax(),
		"CW_KORD_AA": create_cw_kord_aa(),
		"CW_ATGM_KORNET": create_cw_atgm_kornet(),
		"CW_ATGM_REFLEKS": create_cw_atgm_refleks(),
		"CW_ATGM_KONKURS": create_cw_atgm_konkurs(),
		"CW_ATGM_BASTION": create_cw_atgm_bastion(),
		# 中国軍専用
		"CW_TANK_KE_125_CHN": create_cw_tank_ke_125_chn(),
		"CW_TANK_KE_125_CHN_STD": create_cw_tank_ke_125_chn_std(),
		"CW_TANK_KE_125_CHN_OLD": create_cw_tank_ke_125_chn_old(),
		"CW_TANK_KE_105_CHN": create_cw_tank_ke_105_chn(),
		"CW_TANK_KE_105_CHN_OLD": create_cw_tank_ke_105_chn_old(),
		"CW_AUTOCANNON_30_CHN": create_cw_autocannon_30_chn(),
		"CW_AUTOCANNON_35_CHN": create_cw_autocannon_35_chn(),
		"CW_AUTOCANNON_100_CHN": create_cw_autocannon_100_chn(),
		"CW_ATGM_HJ10": create_cw_atgm_hj10(),
		"CW_ATGM_HJ9": create_cw_atgm_hj9(),
		"CW_ATGM_HJ8E": create_cw_atgm_hj8e(),
		"CW_ATGM_HJ73": create_cw_atgm_hj73(),
		"CW_ATGM_GP105": create_cw_atgm_gp105(),
		"CW_QJZ89_AA": create_cw_qjz89_aa(),
		"CW_TYPE86_COAX": create_cw_type86_coax(),
	}


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
	   id.contains("KORD") or id.contains("HMG") or id.contains("_AA"):
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
