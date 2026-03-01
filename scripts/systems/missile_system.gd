class_name MissileSystem
extends RefCounted

## ミサイル飛翔・着弾システム
## 仕様書: docs/missile_system_v0.2.md
##
## ATGMの飛翔を管理し、遅延着弾を実現する。
## combat_system.gdと連携して動作する。
##
## Phase 2: 誘導システム
## - SACLOS射手拘束（移動/射撃/目標変更不可）
## - 有線切断判定（移動、抑圧、被弾）
## - Fire-and-Forget自律追尾
##
## Phase 3: 攻撃プロファイル
## - TOP_ATTACK軌道計算
## - 攻撃プロファイルによる命中ゾーン決定
## - APS回避補正、最小射程補正

# =============================================================================
# 定数参照
# =============================================================================

const MissileData := preload("res://scripts/data/missile_data.gd")
const AmmoStateClass := preload("res://scripts/data/ammo_state.gd")

# Tick/秒の定数
const TICKS_PER_SEC: float = 10.0

# 抑圧閾値（Pinned以上で有線切断）
const SUPPRESSION_PINNED: float = 60.0

# 有線切断確率（抑圧状態時）
const WIRE_CUT_PROB_SUPPRESSED: float = 0.3
const WIRE_CUT_PROB_PINNED: float = 0.7

# Fire-and-Forget ロック維持判定
const FAF_LOCK_CHECK_INTERVAL_TICKS: int = 10  # 1秒ごとにチェック
const FAF_LOCK_LOSS_BASE_PROB: float = 0.05    # 基本ロック喪失確率

# =============================================================================
# 攻撃プロファイル定数（Phase 3）
# =============================================================================

# APS回避補正（攻撃プロファイル別）
const APS_EVASION_BONUS: Dictionary = {
	MissileData.AttackProfile.DIRECT: 0.0,
	MissileData.AttackProfile.TOP_ATTACK: 0.2,
	MissileData.AttackProfile.DIVING: 0.1,
	MissileData.AttackProfile.OVERFLY_TOP: 0.3,
}

# 最小射程増加（攻撃プロファイル別）
const MIN_RANGE_INCREASE_M: Dictionary = {
	MissileData.AttackProfile.DIRECT: 0.0,
	MissileData.AttackProfile.TOP_ATTACK: 50.0,
	MissileData.AttackProfile.DIVING: 0.0,
	MissileData.AttackProfile.OVERFLY_TOP: 100.0,
}

# 命中ゾーン（HitZone）
enum HitZone {
	FRONT,   ## 正面
	SIDE,    ## 側面
	REAR,    ## 後面
	TOP,     ## 上面
}

# =============================================================================
# シグナル
# =============================================================================

## ミサイル発射時
signal missile_launched(missile_id: String, shooter_id: String, target_id: String)

## ミサイル着弾時
signal missile_impact(missile_id: String, shooter_id: String, target_id: String, attack_profile: int, profile: MissileData.MissileProfile)

## ミサイル誘導喪失時
signal missile_lost(missile_id: String, reason: String)

## ミサイルAPS迎撃時
signal missile_intercepted(missile_id: String, target_id: String)

## 有線切断時
signal wire_cut(missile_id: String, shooter_id: String, reason: String)

## 射手拘束違反時（移動/射撃試行）
signal constraint_violation(shooter_id: String, violation_type: String)

## ミサイル終末段階進入時
signal missile_terminal(missile_id: String, attack_profile: int)

# =============================================================================
# 内部状態
# =============================================================================

## 飛翔中ミサイル: id -> InFlightMissile
var in_flight_missiles: Dictionary = {}

## 射手拘束: shooter_id -> ShooterConstraint
var shooter_constraints: Dictionary = {}

## ユニークID生成用
var _next_missile_id: int = 0

# =============================================================================
# 初期化
# =============================================================================

func _init() -> void:
	pass


## 状態リセット（テスト用）
func reset() -> void:
	in_flight_missiles.clear()
	shooter_constraints.clear()
	_next_missile_id = 0


# =============================================================================
# ミサイル発射
# =============================================================================

## ミサイルを発射
## 戻り値: 発射されたミサイルのID（発射失敗時は空文字）
## shooter: 射手のElementInstance（弾薬管理用、オプショナル）
func launch_missile(
	shooter_id: String,
	shooter_pos: Vector2,
	target_id: String,
	target_pos: Vector2,
	profile: MissileData.MissileProfile,
	attack_profile: MissileData.AttackProfile,
	current_tick: int,
	shooter: ElementData.ElementInstance = null
) -> String:
	# 攻撃プロファイルが使用可能かチェック
	if not profile.can_use_profile(attack_profile):
		return ""

	# 射程チェック（攻撃プロファイルによる最小射程増加を考慮）
	var distance := shooter_pos.distance_to(target_pos)
	var effective_min_range := get_effective_min_range(profile, attack_profile)
	if distance < effective_min_range or distance > profile.max_range_m:
		return ""

	# 射手拘束チェック（既に拘束中なら発射不可）
	if shooter_id in shooter_constraints:
		return ""

	# 弾薬チェック（弾薬システムが有効な場合）
	if shooter and shooter.ammo_state and shooter.ammo_state.atgm:
		var atgm_state = shooter.ammo_state.atgm
		# 装填中
		if atgm_state.is_reloading:
			return ""
		# 発射可能か
		if not atgm_state.can_fire():
			return ""

	# ミサイル生成
	var missile := MissileData.InFlightMissile.new(profile)
	missile.id = _generate_missile_id()
	missile.shooter_id = shooter_id
	missile.target_id = target_id
	missile.position = shooter_pos
	missile.target_position = target_pos
	missile.launch_tick = current_tick
	missile.attack_profile = attack_profile
	missile.state = MissileData.MissileState.LAUNCHING
	missile.has_lock = true  # Phase 1では常にロック成功

	# 飛翔時間計算（攻撃プロファイルを考慮）
	var flight_time_sec: float
	if attack_profile == MissileData.AttackProfile.TOP_ATTACK:
		flight_time_sec = calculate_top_attack_flight_time(profile, distance)
	else:
		flight_time_sec = profile.calculate_flight_time(distance)
	missile.estimated_impact_tick = current_tick + int(flight_time_sec * TICKS_PER_SEC)

	# 初期速度設定
	var direction := (target_pos - shooter_pos).normalized()
	missile.velocity = direction * profile.speed_mps

	# 登録
	in_flight_missiles[missile.id] = missile

	# SACLOS誘導の場合は射手拘束
	if profile.is_saclos():
		var constraint := MissileData.ShooterConstraint.new(
			shooter_id, missile.id, current_tick, profile.guidance_type
		)
		shooter_constraints[shooter_id] = constraint

	# 弾薬消費（弾薬システムが有効な場合）
	if shooter and shooter.ammo_state and shooter.ammo_state.atgm:
		var atgm_state = shooter.ammo_state.atgm
		var slot = atgm_state.get_current_slot()
		if slot and slot.count_ready > 0:
			slot.count_ready -= 1
			# 即発弾が0になったら予備弾から装填開始（手動装填: 8秒）
			# 装填はmax_readyに達するまで継続する（update_reload内で処理）
			if slot.count_ready == 0 and slot.count_stowed > 0:
				atgm_state.start_reload()

	missile_launched.emit(missile.id, shooter_id, target_id)

	return missile.id


## ミサイルIDを生成
func _generate_missile_id() -> String:
	_next_missile_id += 1
	return "MSL_%06d" % _next_missile_id


# =============================================================================
# 更新処理
# =============================================================================

## 毎tick更新
## 戻り値: 着弾したミサイルのリスト [{"missile_id", "target_id", "attack_profile", "profile"}]
func update(current_tick: int) -> Array[Dictionary]:
	var impacts: Array[Dictionary] = []
	var to_remove: Array[String] = []

	for missile_id in in_flight_missiles:
		var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

		# 状態更新
		_update_missile_state(missile, current_tick)

		# 終了判定
		if missile.is_terminated():
			to_remove.append(missile_id)

	# 終了したミサイルを削除（シグナル発火前に削除して射手拘束を解除）
	for missile_id in to_remove:
		var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]
		var state := missile.state
		var shooter_id := missile.shooter_id
		var target_id := missile.target_id
		var attack_profile := missile.attack_profile
		var profile := missile.profile

		# ミサイルを削除（射手拘束も解除される）
		_remove_missile(missile_id)

		# シグナル発火（射手拘束解除後）
		if state == MissileData.MissileState.IMPACT:
			impacts.append({
				"missile_id": missile_id,
				"shooter_id": shooter_id,
				"target_id": target_id,
				"attack_profile": attack_profile,
				"profile": profile
			})
			missile_impact.emit(missile_id, shooter_id, target_id, attack_profile, profile)
		elif state == MissileData.MissileState.LOST:
			missile_lost.emit(missile_id, "guidance_lost")
		elif state == MissileData.MissileState.INTERCEPTED:
			missile_intercepted.emit(missile_id, target_id)

	return impacts


## ミサイル状態を更新
func _update_missile_state(missile: MissileData.InFlightMissile, current_tick: int) -> void:
	# すでに終了状態なら更新不要
	if missile.is_terminated():
		return

	var ticks_since_launch := current_tick - missile.launch_tick
	var time_since_launch := float(ticks_since_launch) / TICKS_PER_SEC

	missile.current_flight_time = time_since_launch

	# 位置更新（簡易版: 直線補間）
	_update_missile_position(missile, time_since_launch)

	# ブースト段階 → 飛翔中
	if missile.state == MissileData.MissileState.LAUNCHING:
		if time_since_launch >= missile.profile.boost_duration_sec:
			missile.state = MissileData.MissileState.IN_FLIGHT

	# 飛翔中 → 終末段階（TOP_ATTACKなど）
	if missile.state == MissileData.MissileState.IN_FLIGHT:
		var terminal_dist := get_terminal_phase_distance(missile.profile, missile.attack_profile)
		if terminal_dist > 0:
			var distance_to_target := missile.position.distance_to(missile.target_position)
			if distance_to_target <= terminal_dist:
				missile.state = MissileData.MissileState.TERMINAL
				missile_terminal.emit(missile.id, missile.attack_profile)

	# 着弾判定（予定tick到達）
	if current_tick >= missile.estimated_impact_tick:
		missile.state = MissileData.MissileState.IMPACT


## ミサイル位置を更新
func _update_missile_position(missile: MissileData.InFlightMissile, time_since_launch: float) -> void:
	var total_flight_time := float(missile.estimated_impact_tick - missile.launch_tick) / TICKS_PER_SEC
	if total_flight_time <= 0:
		return

	# 進行度（0〜1）
	var progress := clampf(time_since_launch / total_flight_time, 0.0, 1.0)

	if progress < 0.01:  # 初期位置は発射位置
		return

	# 発射位置から目標位置への補間（TOP_ATTACKでも2D上は直線として扱う）
	var launch_pos := missile.position - missile.velocity * time_since_launch
	missile.position = launch_pos.lerp(missile.target_position, progress)


## ミサイルを削除し、関連する射手拘束も解除
func _remove_missile(missile_id: String) -> void:
	if missile_id not in in_flight_missiles:
		return

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# 射手拘束を解除
	if missile.shooter_id in shooter_constraints:
		var constraint: MissileData.ShooterConstraint = shooter_constraints[missile.shooter_id]
		if constraint.missile_id == missile_id:
			shooter_constraints.erase(missile.shooter_id)

	in_flight_missiles.erase(missile_id)


# =============================================================================
# 射手拘束
# =============================================================================

## 射手が拘束中かどうか
func is_shooter_constrained(shooter_id: String) -> bool:
	return shooter_id in shooter_constraints


## 射手の拘束情報を取得
func get_shooter_constraint(shooter_id: String) -> MissileData.ShooterConstraint:
	if shooter_id in shooter_constraints:
		return shooter_constraints[shooter_id]
	return null


## 射手が移動可能か（SACLOS拘束中は不可）
func can_shooter_move(shooter_id: String) -> bool:
	if shooter_id not in shooter_constraints:
		return true
	var constraint: MissileData.ShooterConstraint = shooter_constraints[shooter_id]
	return not constraint.is_constrained()


## 射手が射撃可能か（SACLOS拘束中は不可）
func can_shooter_fire(shooter_id: String) -> bool:
	if shooter_id not in shooter_constraints:
		return true
	var constraint: MissileData.ShooterConstraint = shooter_constraints[shooter_id]
	return not constraint.is_constrained()


## 射手の移動を試行（拘束違反チェック付き）
## 戻り値: 移動が許可されたか
func try_shooter_move(shooter_id: String) -> bool:
	if can_shooter_move(shooter_id):
		return true

	# 拘束違反
	constraint_violation.emit(shooter_id, "movement")
	return false


## 射手の射撃を試行（拘束違反チェック付き）
## 戻り値: 射撃が許可されたか
func try_shooter_fire(shooter_id: String) -> bool:
	if can_shooter_fire(shooter_id):
		return true

	# 拘束違反
	constraint_violation.emit(shooter_id, "fire")
	return false


## 射手拘束を強制解除（射手被弾時など）
## 関連するミサイルの誘導も喪失する
func force_release_shooter(shooter_id: String) -> void:
	if shooter_id not in shooter_constraints:
		return

	var constraint: MissileData.ShooterConstraint = shooter_constraints[shooter_id]
	var missile_id := constraint.missile_id

	# ミサイルの誘導喪失
	if missile_id in in_flight_missiles:
		var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]
		missile.state = MissileData.MissileState.LOST
		missile.guidance_active = false

	shooter_constraints.erase(shooter_id)


# =============================================================================
# 有線切断判定（Phase 2）
# =============================================================================

## 射手状態を元に有線切断をチェック
## shooter_state: { "is_moving": bool, "suppression": float, "last_hit_tick": int }
func check_wire_integrity(
	shooter_id: String,
	shooter_state: Dictionary,
	_current_tick: int = 0
) -> bool:
	if shooter_id not in shooter_constraints:
		return true  # 拘束なし = 有線なし

	var constraint: MissileData.ShooterConstraint = shooter_constraints[shooter_id]
	var missile_id := constraint.missile_id

	if missile_id not in in_flight_missiles:
		return true

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# 有線誘導でない場合はチェック不要
	if not missile.profile.wire_guided:
		return true

	var cut_reason := ""

	# 射手が移動した
	if shooter_state.get("is_moving", false):
		cut_reason = "shooter_moved"

	# 射手が被弾した（発射後）
	var last_hit_tick: int = shooter_state.get("last_hit_tick", -1)
	if last_hit_tick > missile.launch_tick:
		cut_reason = "shooter_hit"

	# 射手が抑圧状態
	var suppression: float = shooter_state.get("suppression", 0.0)
	if suppression >= SUPPRESSION_PINNED:
		# Pinned以上は高確率で切断
		if randf() < WIRE_CUT_PROB_PINNED:
			cut_reason = "shooter_pinned"
	elif suppression >= 30.0:  # Suppressed状態
		# 抑圧状態は低確率で切断
		if randf() < WIRE_CUT_PROB_SUPPRESSED:
			cut_reason = "shooter_suppressed"

	if cut_reason != "":
		_cut_wire(missile_id, shooter_id, cut_reason)
		return false

	return true


## 有線を切断
func _cut_wire(missile_id: String, shooter_id: String, reason: String) -> void:
	if missile_id not in in_flight_missiles:
		return

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]
	missile.state = MissileData.MissileState.LOST
	missile.guidance_active = false

	# 射手拘束も解除
	if shooter_id in shooter_constraints:
		shooter_constraints.erase(shooter_id)

	wire_cut.emit(missile_id, shooter_id, reason)


## SACLOS誘導の継続チェック（レーザービームライディング用）
## los_clear: 射手-目標間のLoSが確保されているか
func check_saclos_guidance(
	shooter_id: String,
	los_clear: bool,
	_current_tick: int = 0
) -> bool:
	if shooter_id not in shooter_constraints:
		return true

	var constraint: MissileData.ShooterConstraint = shooter_constraints[shooter_id]
	var missile_id := constraint.missile_id

	if missile_id not in in_flight_missiles:
		return true

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# SACLOS（非有線）の場合
	if missile.profile.is_saclos() and not missile.profile.wire_guided:
		# LoSが失われたら誘導喪失
		if not los_clear:
			missile.state = MissileData.MissileState.LOST
			missile.guidance_active = false
			shooter_constraints.erase(shooter_id)
			return false

	return true


# =============================================================================
# Fire-and-Forget 自律追尾（Phase 2）
# =============================================================================

## Fire-and-Forgetミサイルのロック維持をチェック
## target_state: { "is_visible": bool, "has_smoke_cover": bool, "is_moving": bool }
func check_faf_lock(
	missile_id: String,
	target_state: Dictionary,
	current_tick: int
) -> bool:
	if missile_id not in in_flight_missiles:
		return false

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# Fire-and-Forgetでない場合はチェック不要
	if not missile.profile.is_fire_and_forget():
		return true

	# 定期チェック（毎tickではなく間隔を開ける）
	var ticks_since_launch := current_tick - missile.launch_tick
	if ticks_since_launch % FAF_LOCK_CHECK_INTERVAL_TICKS != 0:
		return true  # チェックタイミングでない

	var lock_loss_prob := FAF_LOCK_LOSS_BASE_PROB

	# 目標が見えない場合
	if not target_state.get("is_visible", true):
		lock_loss_prob += 0.2

	# 煙幕で覆われている場合（IR誘導に影響）
	if target_state.get("has_smoke_cover", false):
		lock_loss_prob += missile.profile.smoke_vulnerability * 0.5

	# 目標が移動中（追尾難易度上昇、ただしわずか）
	if target_state.get("is_moving", false):
		lock_loss_prob += 0.02

	# ロック喪失判定
	if randf() < lock_loss_prob:
		missile.has_lock = false
		missile.state = MissileData.MissileState.LOST
		missile.guidance_active = false
		return false

	return true


## 目標位置を更新（追尾中のFire-and-Forgetミサイル用）
func update_target_position(missile_id: String, new_target_pos: Vector2) -> void:
	if missile_id not in in_flight_missiles:
		return

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# Fire-and-Forgetでロック維持中のみ更新
	if missile.profile.is_fire_and_forget() and missile.has_lock:
		missile.target_position = new_target_pos
		# 新しい飛翔時間を再計算
		var distance := missile.position.distance_to(new_target_pos)
		var remaining_flight_time := missile.profile.calculate_flight_time(distance)
		var current_tick := missile.launch_tick + int(missile.current_flight_time * TICKS_PER_SEC)
		missile.estimated_impact_tick = current_tick + int(remaining_flight_time * TICKS_PER_SEC)


# =============================================================================
# クエリ
# =============================================================================

## 飛翔中のミサイル数
func get_in_flight_count() -> int:
	return in_flight_missiles.size()


## 特定の射手が発射したミサイルを取得
func get_missiles_by_shooter(shooter_id: String) -> Array[MissileData.InFlightMissile]:
	var result: Array[MissileData.InFlightMissile] = []
	for missile in in_flight_missiles.values():
		if missile.shooter_id == shooter_id:
			result.append(missile)
	return result


## 特定の目標に向かっているミサイルを取得
func get_missiles_targeting(target_id: String) -> Array[MissileData.InFlightMissile]:
	var result: Array[MissileData.InFlightMissile] = []
	for missile in in_flight_missiles.values():
		if missile.target_id == target_id:
			result.append(missile)
	return result


## ミサイルを取得
func get_missile(missile_id: String) -> MissileData.InFlightMissile:
	if missile_id in in_flight_missiles:
		return in_flight_missiles[missile_id]
	return null


# =============================================================================
# ミサイル誘導喪失（外部からの呼び出し）
# =============================================================================

## 煙幕によるIR誘導喪失判定
func check_smoke_disruption(missile_id: String) -> bool:
	if missile_id not in in_flight_missiles:
		return false

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]
	var profile := missile.profile

	# 煙幕脆弱性による確率判定
	if randf() < profile.smoke_vulnerability:
		missile.state = MissileData.MissileState.LOST
		missile.guidance_active = false
		return true

	return false


## APS迎撃判定（攻撃プロファイルによる回避補正を考慮）
func attempt_aps_intercept(missile_id: String, intercept_probability: float) -> bool:
	if missile_id not in in_flight_missiles:
		return false

	var missile: MissileData.InFlightMissile = in_flight_missiles[missile_id]

	# APS脆弱性を考慮
	var base_prob := intercept_probability * missile.profile.aps_vulnerability

	# 攻撃プロファイルによる回避補正（TOP_ATTACKなど）
	var evasion_bonus := get_aps_evasion_bonus(missile.attack_profile)
	var final_prob := maxf(0.0, base_prob - evasion_bonus)

	if randf() < final_prob:
		missile.state = MissileData.MissileState.INTERCEPTED
		return true

	return false


# =============================================================================
# ヘルパー
# =============================================================================

## 武器IDからミサイルプロファイルを取得し、発射可能か判定
static func can_launch_missile(weapon_id: String) -> bool:
	var profile := MissileData.get_profile_for_weapon(weapon_id)
	return profile != null


## 武器IDからミサイルプロファイルを取得
static func get_profile_for_weapon(weapon_id: String) -> MissileData.MissileProfile:
	return MissileData.get_profile_for_weapon(weapon_id)


# =============================================================================
# 攻撃プロファイル（Phase 3）
# =============================================================================

## 攻撃プロファイルが使用可能かチェック
func can_use_attack_profile(
	profile: MissileData.MissileProfile,
	attack_profile: MissileData.AttackProfile
) -> bool:
	return profile.can_use_profile(attack_profile)


## 攻撃プロファイルに基づく有効最小射程を計算
func get_effective_min_range(
	profile: MissileData.MissileProfile,
	attack_profile: MissileData.AttackProfile
) -> float:
	var base_min := profile.min_range_m
	var increase: float = MIN_RANGE_INCREASE_M.get(attack_profile, 0.0)
	return base_min + increase


## 攻撃プロファイルに基づくAPS回避補正を取得
## 戻り値: APS迎撃確率に対する減算値（0.0〜0.3）
func get_aps_evasion_bonus(attack_profile: MissileData.AttackProfile) -> float:
	var bonus: float = APS_EVASION_BONUS.get(attack_profile, 0.0)
	return bonus


## 攻撃プロファイルに基づく命中ゾーンを決定
## target_facing: 目標の向き（ラジアン、0=東向き）
## shooter_pos: 射手位置
## target_pos: 目標位置
func determine_hit_zone(
	attack_profile: MissileData.AttackProfile,
	target_facing: float,
	shooter_pos: Vector2,
	target_pos: Vector2
) -> HitZone:
	# TOP_ATTACK / DIVING / OVERFLY_TOP は上面命中
	if attack_profile in [
		MissileData.AttackProfile.TOP_ATTACK,
		MissileData.AttackProfile.DIVING,
		MissileData.AttackProfile.OVERFLY_TOP
	]:
		return HitZone.TOP

	# DIRECT の場合は射撃角度から決定
	return _determine_direct_hit_zone(target_facing, shooter_pos, target_pos)


## 直射攻撃の命中ゾーンを決定
func _determine_direct_hit_zone(
	target_facing: float,
	shooter_pos: Vector2,
	target_pos: Vector2
) -> HitZone:
	# 射手から目標への方向ベクトル
	var attack_direction := (target_pos - shooter_pos).normalized()
	var attack_angle := attack_direction.angle()

	# 目標の向きとの角度差（-PI〜PIに正規化）
	var angle_diff := _normalize_angle(attack_angle - target_facing)

	# 角度差による判定
	# 正面: ±45度以内
	# 側面: 45〜135度
	# 後面: 135度以上
	var abs_diff := absf(angle_diff)

	if abs_diff <= PI / 4.0:  # 45度
		return HitZone.FRONT
	elif abs_diff >= PI * 3.0 / 4.0:  # 135度
		return HitZone.REAR
	else:
		return HitZone.SIDE


## 角度を-PI〜PIに正規化
func _normalize_angle(angle: float) -> float:
	while angle > PI:
		angle -= TAU
	while angle < -PI:
		angle += TAU
	return angle


## TOP_ATTACK軌道の飛翔時間を計算（ゲームバランス版）
## 実際のJavelinは15-20秒程度かかるが、ゲームプレイ上は
## DIRECT攻撃より10-15%程度長い程度に抑える
func calculate_top_attack_flight_time(
	profile: MissileData.MissileProfile,
	distance_m: float
) -> float:
	if distance_m <= 0:
		return 0.0

	# 基本飛行時間（直線軌道）
	var direct_time := profile.calculate_flight_time(distance_m)

	# TOP_ATTACKは直線より10-15%長い（迂回軌道のペナルティ）
	# 近距離（<500m）: ほぼペナルティなし（上昇する余裕がない）
	# 中距離（500-1500m）: 5-10%増加
	# 遠距離（>1500m）: 10-15%増加
	var penalty_factor: float
	if distance_m < 500.0:
		penalty_factor = 1.02  # 2%増加
	elif distance_m < 1500.0:
		penalty_factor = 1.08  # 8%増加
	else:
		penalty_factor = 1.12  # 12%増加

	return direct_time * penalty_factor


## 攻撃プロファイル別の終末段階開始条件を取得
## 戻り値: 目標までの距離（m）がこの値以下で終末段階
func get_terminal_phase_distance(
	profile: MissileData.MissileProfile,
	attack_profile: MissileData.AttackProfile
) -> float:
	match attack_profile:
		MissileData.AttackProfile.TOP_ATTACK:
			# 上昇→降下に入る距離
			var dive_angle := deg_to_rad(profile.dive_angle_deg)
			return profile.top_attack_altitude_m / tan(dive_angle)
		MissileData.AttackProfile.DIVING:
			# 急降下開始距離
			return 200.0
		MissileData.AttackProfile.OVERFLY_TOP:
			# オーバーフライ開始距離
			return 100.0
		_:
			# DIRECT: 終末段階なし（着弾まで直進）
			return 0.0
