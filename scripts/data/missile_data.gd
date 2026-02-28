class_name MissileData
extends RefCounted

## ミサイルデータモデル
## 仕様書: docs/missile_system_v0.2.md
##
## ATGMの誘導方式、飛翔特性、攻撃プロファイルを定義

# =============================================================================
# 誘導方式
# =============================================================================

enum GuidanceType {
	NONE,                    ## 無誘導（RPG等）

	# 指令誘導（Command Guidance）
	SACLOS_WIRE,             ## 有線SACLOS（TOW, Konkurs）
	SACLOS_RADIO,            ## 無線SACLOS
	SACLOS_LASER_BEAM,       ## レーザービームライディング（Kornet）

	# 自律誘導（Autonomous Homing）
	IR_HOMING,               ## 赤外線ホーミング
	IIR_HOMING,              ## 画像式赤外線（Javelin）
	MMW_RADAR,               ## ミリ波レーダー（Hellfire Longbow）
	SALH,                    ## 半自動レーザー誘導（Hellfire, Krasnopol）

	# 航法誘導（砲弾向け）
	GPS_INS,                 ## GPS/INS（Excalibur）
	LASER_GUIDED,            ## レーザー誘導（Krasnopol）
}

# =============================================================================
# ロックオンモード
# =============================================================================

enum LockMode {
	NONE,                    ## 無誘導
	LOBL,                    ## Lock-On Before Launch（発射前ロック）
	LOAL_HI,                 ## Lock-On After Launch - High（高弾道後ロック）
	LOAL_LO,                 ## Lock-On After Launch - Low（低弾道後ロック）
	CONTINUOUS_TRACK,        ## 継続追尾（SACLOS）
}

# =============================================================================
# 攻撃プロファイル
# =============================================================================

enum AttackProfile {
	DIRECT,                  ## 直射（ダイレクトアタック）
	TOP_ATTACK,              ## トップアタック（上面攻撃）
	DIVING,                  ## ダイビング（急降下）
	OVERFLY_TOP,             ## オーバーフライトップアタック（BILL等）
}

# =============================================================================
# ミサイル状態
# =============================================================================

enum MissileState {
	LAUNCHING,               ## 発射中（ブースト段階）
	IN_FLIGHT,               ## 飛翔中
	TERMINAL,                ## 終末段階（ロックオン/ダイブ中）
	IMPACT,                  ## 着弾
	LOST,                    ## 誘導喪失（煙幕、妨害等）
	INTERCEPTED,             ## APS迎撃
}

# =============================================================================
# 弾頭タイプ
# =============================================================================

enum WarheadType {
	HEAT,                    ## 単弾頭HEAT
	TANDEM_HEAT,             ## タンデムHEAT（ERA貫通）
	EFP,                     ## 自己鍛造弾（TOW-2B）
	MULTIPURPOSE,            ## 多目的弾頭
	THERMOBARIC,             ## サーモバリック
}

# =============================================================================
# ミサイルプロファイル
# =============================================================================

class MissileProfile:
	var id: String = ""
	var display_name: String = ""
	var weapon_id: String = ""        ## WeaponData への参照ID

	## 誘導
	var guidance_type: GuidanceType = GuidanceType.NONE
	var lock_mode: LockMode = LockMode.NONE
	var lock_time_sec: float = 0.0    ## ロックオン所要時間
	var can_loal: bool = false        ## LOAL可能か
	var loal_acquisition_range_m: float = 0.0  ## LOAL時の捕捉距離

	## 飛翔
	var speed_mps: float = 150.0      ## 巡航速度 (m/s)
	var max_speed_mps: float = 300.0  ## 最大速度 (m/s)
	var boost_duration_sec: float = 0.5  ## ブースト時間
	var max_range_m: float = 2500.0   ## 最大射程
	var min_range_m: float = 65.0     ## 最小射程

	## 攻撃プロファイル
	var default_attack_profile: AttackProfile = AttackProfile.DIRECT
	var available_profiles: Array[AttackProfile] = [AttackProfile.DIRECT]
	var top_attack_altitude_m: float = 150.0  ## トップアタック時の高度
	var dive_angle_deg: float = 45.0  ## 急降下角度

	## 弾頭
	var warhead_type: WarheadType = WarheadType.HEAT
	var penetration_ce: int = 100     ## CE貫通力（RHAスケール）
	var defeats_era: bool = false     ## ERA貫通能力
	var blast_radius_m: float = 3.0   ## 爆風半径

	## 対抗手段耐性
	var aps_vulnerability: float = 1.0    ## APS迎撃されやすさ (1.0=標準)
	var smoke_vulnerability: float = 0.5  ## 煙幕妨害されやすさ
	var ecm_vulnerability: float = 0.0    ## ECM妨害されやすさ

	## 運用制約
	var shooter_constrained: bool = false  ## 飛翔中に射手が拘束されるか
	var wire_guided: bool = false          ## 有線誘導か


	## SACLOS誘導かどうか
	func is_saclos() -> bool:
		return guidance_type in [
			GuidanceType.SACLOS_WIRE,
			GuidanceType.SACLOS_RADIO,
			GuidanceType.SACLOS_LASER_BEAM,
		]


	## Fire-and-Forget かどうか
	func is_fire_and_forget() -> bool:
		return guidance_type in [
			GuidanceType.IR_HOMING,
			GuidanceType.IIR_HOMING,
			GuidanceType.MMW_RADAR,
		]


	## 指定した攻撃プロファイルが使用可能か
	func can_use_profile(profile: AttackProfile) -> bool:
		return profile in available_profiles


	## 飛翔時間を計算（直線軌道基準）
	## NOTE: TOP_ATTACKの飛行時間はMissileSystem.calculate_top_attack_flight_time()で計算
	func calculate_flight_time(distance_m: float) -> float:
		if distance_m <= 0:
			return 0.0

		var boost_dist := speed_mps * boost_duration_sec * 0.5
		var remaining_dist := maxf(0, distance_m - boost_dist)

		return boost_duration_sec + remaining_dist / speed_mps


# =============================================================================
# 飛翔中ミサイル
# =============================================================================

class InFlightMissile:
	var id: String = ""
	var profile: MissileProfile
	var shooter_id: String = ""
	var target_id: String = ""
	var state: MissileState = MissileState.LAUNCHING

	## 位置・速度
	var position: Vector2 = Vector2.ZERO
	var target_position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO

	## 時間管理
	var launch_tick: int = 0
	var estimated_impact_tick: int = 0
	var current_flight_time: float = 0.0

	## 攻撃設定
	var attack_profile: AttackProfile = AttackProfile.DIRECT

	## 誘導状態
	var has_lock: bool = false
	var guidance_active: bool = true


	func _init(p_profile: MissileProfile = null) -> void:
		if p_profile:
			profile = p_profile
			attack_profile = p_profile.default_attack_profile


	## 飛翔中かどうか
	func is_in_flight() -> bool:
		return state in [MissileState.LAUNCHING, MissileState.IN_FLIGHT, MissileState.TERMINAL]


	## 終了状態かどうか
	func is_terminated() -> bool:
		return state in [MissileState.IMPACT, MissileState.LOST, MissileState.INTERCEPTED]


# =============================================================================
# 射手拘束
# =============================================================================

class ShooterConstraint:
	var shooter_id: String = ""
	var missile_id: String = ""
	var start_tick: int = 0
	var guidance_type: GuidanceType = GuidanceType.NONE


	func _init(p_shooter_id: String = "", p_missile_id: String = "",
			   p_tick: int = 0, p_guidance: GuidanceType = GuidanceType.NONE) -> void:
		shooter_id = p_shooter_id
		missile_id = p_missile_id
		start_tick = p_tick
		guidance_type = p_guidance


	## 拘束中かどうか
	func is_constrained() -> bool:
		return guidance_type in [
			GuidanceType.SACLOS_WIRE,
			GuidanceType.SACLOS_RADIO,
			GuidanceType.SACLOS_LASER_BEAM,
			GuidanceType.SALH,
		]


# =============================================================================
# JSONローダー（SSoT対応）
# =============================================================================

const MISSILE_JSON_PATH := "res://data/missiles/missile_profiles.json"

static var _profiles: Dictionary = {}
static var _json_loaded: bool = false


## JSONファイルからミサイルプロファイルを読み込む
static func _ensure_json_loaded() -> void:
	if _json_loaded:
		return

	var file := FileAccess.open(MISSILE_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("Cannot open missile JSON: %s" % MISSILE_JSON_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [MISSILE_JSON_PATH, json.get_error_message()])
		return

	var profiles_array: Array = json.data
	for profile_data in profiles_array:
		var profile := _dict_to_missile_profile(profile_data)
		_profiles[profile.id] = profile

	_json_loaded = true
	print("Loaded %d missile profiles from JSON" % _profiles.size())


## DictionaryをMissileProfileに変換
static func _dict_to_missile_profile(data: Dictionary) -> MissileProfile:
	var p := MissileProfile.new()

	p.id = data.get("id", "")
	p.display_name = data.get("display_name", "")
	p.weapon_id = data.get("weapon_id", "")

	# 誘導
	var guidance: Dictionary = data.get("guidance", {})
	p.guidance_type = _string_to_guidance_type(str(guidance.get("type", "NONE")))
	p.lock_mode = _string_to_lock_mode(str(guidance.get("lock_mode", "NONE")))
	p.lock_time_sec = float(guidance.get("lock_time_sec", 0.0))
	p.can_loal = bool(guidance.get("can_loal", false))
	p.loal_acquisition_range_m = float(guidance.get("loal_acquisition_range_m", 0.0))

	# 飛翔
	var flight: Dictionary = data.get("flight", {})
	p.speed_mps = float(flight.get("speed_mps", 150.0))
	p.max_speed_mps = float(flight.get("max_speed_mps", 300.0))
	p.boost_duration_sec = float(flight.get("boost_duration_sec", 0.5))
	p.max_range_m = float(flight.get("max_range_m", 2500.0))
	p.min_range_m = float(flight.get("min_range_m", 65.0))

	# 攻撃プロファイル
	var attack: Dictionary = data.get("attack_profile", {})
	p.default_attack_profile = _string_to_attack_profile(str(attack.get("default", "DIRECT")))
	var selectable: Array = attack.get("selectable", ["DIRECT"])
	p.available_profiles = []
	for s in selectable:
		p.available_profiles.append(_string_to_attack_profile(str(s)))
	p.top_attack_altitude_m = float(attack.get("top_attack_altitude_m", 150.0))
	p.dive_angle_deg = float(attack.get("dive_angle_deg", 45.0))

	# 弾頭
	var warhead: Dictionary = data.get("warhead", {})
	p.warhead_type = _string_to_warhead_type(str(warhead.get("type", "HEAT")))
	p.penetration_ce = int(warhead.get("penetration_ce", 100))
	p.defeats_era = bool(warhead.get("defeats_era", false))
	p.blast_radius_m = float(warhead.get("blast_radius_m", 3.0))

	# 対抗手段耐性
	var cm: Dictionary = data.get("countermeasures", {})
	p.aps_vulnerability = float(cm.get("aps_vulnerability", 1.0))
	p.smoke_vulnerability = float(cm.get("smoke_vulnerability", 0.5))
	p.ecm_vulnerability = float(cm.get("ecm_vulnerability", 0.0))

	# 運用制約
	var constraints: Dictionary = data.get("constraints", {})
	p.shooter_constrained = bool(constraints.get("shooter_immobile_during_flight", false))
	p.wire_guided = int(constraints.get("wire_max_range_m", 0)) > 0

	# SACLOS系は射手拘束
	if p.is_saclos():
		p.shooter_constrained = true

	return p


## 文字列をGuidanceTypeに変換
static func _string_to_guidance_type(s: String) -> GuidanceType:
	match s:
		"NONE": return GuidanceType.NONE
		"SACLOS_WIRE": return GuidanceType.SACLOS_WIRE
		"SACLOS_RADIO": return GuidanceType.SACLOS_RADIO
		"SACLOS_LASER_BEAM": return GuidanceType.SACLOS_LASER_BEAM
		"IR_HOMING": return GuidanceType.IR_HOMING
		"IIR_HOMING": return GuidanceType.IIR_HOMING
		"MMW_RADAR": return GuidanceType.MMW_RADAR
		"SALH": return GuidanceType.SALH
		"GPS_INS": return GuidanceType.GPS_INS
		"LASER_GUIDED": return GuidanceType.LASER_GUIDED
		_: return GuidanceType.NONE


## 文字列をLockModeに変換
static func _string_to_lock_mode(s: String) -> LockMode:
	match s:
		"NONE": return LockMode.NONE
		"LOBL": return LockMode.LOBL
		"LOAL_HI": return LockMode.LOAL_HI
		"LOAL_LO": return LockMode.LOAL_LO
		"CONTINUOUS_TRACK": return LockMode.CONTINUOUS_TRACK
		_: return LockMode.NONE


## 文字列をAttackProfileに変換
static func _string_to_attack_profile(s: String) -> AttackProfile:
	match s:
		"DIRECT": return AttackProfile.DIRECT
		"TOP_ATTACK": return AttackProfile.TOP_ATTACK
		"DIVING": return AttackProfile.DIVING
		"OVERFLY_TOP": return AttackProfile.OVERFLY_TOP
		_: return AttackProfile.DIRECT


## 文字列をWarheadTypeに変換
static func _string_to_warhead_type(s: String) -> WarheadType:
	match s:
		"HEAT": return WarheadType.HEAT
		"TANDEM_HEAT": return WarheadType.TANDEM_HEAT
		"EFP": return WarheadType.EFP
		"MULTIPURPOSE": return WarheadType.MULTIPURPOSE
		"THERMOBARIC": return WarheadType.THERMOBARIC
		_: return WarheadType.HEAT


## 全プロファイルを取得
static func get_all_profiles() -> Dictionary:
	_ensure_json_loaded()
	return _profiles


## IDからプロファイルを取得
static func get_profile(profile_id: String) -> MissileProfile:
	_ensure_json_loaded()
	if profile_id in _profiles:
		return _profiles[profile_id]
	return null


## 武器IDからプロファイルを取得
static func get_profile_for_weapon(weapon_id: String) -> MissileProfile:
	_ensure_json_loaded()
	for profile in _profiles.values():
		if profile.weapon_id == weapon_id:
			return profile
	return null


## JSONロード状態をリセット（テスト用）
static func _reset_for_testing() -> void:
	_profiles.clear()
	_json_loaded = false
