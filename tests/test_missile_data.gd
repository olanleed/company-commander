extends GutTest

## MissileDataのユニットテスト
## - JSONローディング
## - enum変換
## - 飛翔時間計算
## - ヘルパー関数

const MissileDataScript := preload("res://scripts/data/missile_data.gd")


func before_all() -> void:
	# JSONロード状態をリセット
	MissileDataScript._reset_for_testing()


func after_all() -> void:
	# テスト後にリセット
	MissileDataScript._reset_for_testing()


# =============================================================================
# JSONローディング
# =============================================================================

func test_json_loading_all_profiles() -> void:
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	# 10種のミサイルが定義されている
	assert_true(profiles.size() >= 10, "Should have at least 10 missile profiles")

	# キーとしてIDが存在する
	assert_true("M_USA_JAVELIN" in profiles, "Should have Javelin")
	assert_true("M_USA_TOW2B" in profiles, "Should have TOW-2B")
	assert_true("M_RUS_KORNET" in profiles, "Should have Kornet")
	assert_true("M_RUS_KONKURS" in profiles, "Should have Konkurs")
	assert_true("M_RUS_REFLEKS" in profiles, "Should have Refleks")
	assert_true("M_CHN_HJ10" in profiles, "Should have HJ-10")
	assert_true("M_CHN_HJ9" in profiles, "Should have HJ-9")
	assert_true("M_JPN_01LMAT" in profiles, "Should have 01LMAT")
	assert_true("M_JPN_79MAT" in profiles, "Should have 79MAT")
	assert_true("M_JPN_MMPM" in profiles, "Should have MMPM")


func test_get_profile_by_id() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_not_null(javelin, "Javelin profile should exist")
	assert_eq(javelin.id, "M_USA_JAVELIN")
	assert_eq(javelin.display_name, "FGM-148 Javelin")
	assert_eq(javelin.weapon_id, "W_USA_ATGM_JAVELIN")


func test_get_profile_nonexistent() -> void:
	var nonexistent: MissileDataScript.MissileProfile = MissileDataScript.get_profile("MSL_NONEXISTENT")
	assert_null(nonexistent, "Nonexistent profile should return null")


func test_get_profile_for_weapon() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile_for_weapon("W_USA_ATGM_JAVELIN")

	assert_not_null(javelin, "Should find profile by weapon_id")
	assert_eq(javelin.id, "M_USA_JAVELIN")


func test_get_profile_for_weapon_nonexistent() -> void:
	var nonexistent: MissileDataScript.MissileProfile = MissileDataScript.get_profile_for_weapon("CW_NONEXISTENT")
	assert_null(nonexistent, "Nonexistent weapon_id should return null")


# =============================================================================
# 誘導方式
# =============================================================================

func test_javelin_guidance() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_eq(javelin.guidance_type, MissileDataScript.GuidanceType.IIR_HOMING)
	assert_eq(javelin.lock_mode, MissileDataScript.LockMode.LOBL)
	assert_almost_eq(javelin.lock_time_sec, 3.0, 0.01)
	assert_true(javelin.can_loal, "Javelin can LOAL")
	assert_almost_eq(javelin.loal_acquisition_range_m, 500.0, 0.1)


func test_tow_guidance() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")

	assert_eq(tow.guidance_type, MissileDataScript.GuidanceType.SACLOS_WIRE)
	assert_eq(tow.lock_mode, MissileDataScript.LockMode.CONTINUOUS_TRACK)
	assert_false(tow.can_loal, "TOW cannot LOAL")


func test_kornet_guidance() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	assert_eq(kornet.guidance_type, MissileDataScript.GuidanceType.SACLOS_LASER_BEAM)
	assert_eq(kornet.lock_mode, MissileDataScript.LockMode.CONTINUOUS_TRACK)


func test_is_saclos() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_true(tow.is_saclos(), "TOW is SACLOS")
	assert_true(kornet.is_saclos(), "Kornet is SACLOS")
	assert_false(javelin.is_saclos(), "Javelin is not SACLOS")


func test_is_fire_and_forget() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var hj10: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_CHN_HJ10")

	assert_true(javelin.is_fire_and_forget(), "Javelin is F&F")
	assert_true(hj10.is_fire_and_forget(), "HJ-10 is F&F")
	assert_false(tow.is_fire_and_forget(), "TOW is not F&F")


# =============================================================================
# 飛翔パラメータ
# =============================================================================

func test_javelin_flight_params() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_almost_eq(javelin.speed_mps, 140.0, 0.1)
	assert_almost_eq(javelin.max_speed_mps, 290.0, 0.1)
	assert_almost_eq(javelin.boost_duration_sec, 0.5, 0.01)
	assert_almost_eq(javelin.max_range_m, 2500.0, 0.1)
	assert_almost_eq(javelin.min_range_m, 65.0, 0.1)


func test_kornet_flight_params() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	assert_almost_eq(kornet.speed_mps, 250.0, 0.1)
	assert_almost_eq(kornet.max_range_m, 5500.0, 0.1)
	assert_almost_eq(kornet.min_range_m, 100.0, 0.1)


# =============================================================================
# 攻撃プロファイル
# =============================================================================

func test_javelin_attack_profiles() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_eq(javelin.default_attack_profile, MissileDataScript.AttackProfile.TOP_ATTACK)
	assert_true(javelin.can_use_profile(MissileDataScript.AttackProfile.DIRECT))
	assert_true(javelin.can_use_profile(MissileDataScript.AttackProfile.TOP_ATTACK))
	assert_false(javelin.can_use_profile(MissileDataScript.AttackProfile.DIVING))


func test_kornet_attack_profiles() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	assert_eq(kornet.default_attack_profile, MissileDataScript.AttackProfile.DIRECT)
	assert_true(kornet.can_use_profile(MissileDataScript.AttackProfile.DIRECT))
	assert_false(kornet.can_use_profile(MissileDataScript.AttackProfile.TOP_ATTACK))


func test_tow2b_attack_profiles() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")

	# TOW-2Bは DIRECT と OVERFLY_TOP が選択可能
	assert_eq(tow.default_attack_profile, MissileDataScript.AttackProfile.DIRECT)
	assert_true(tow.can_use_profile(MissileDataScript.AttackProfile.DIRECT))
	assert_true(tow.can_use_profile(MissileDataScript.AttackProfile.OVERFLY_TOP))


# =============================================================================
# 弾頭
# =============================================================================

func test_warhead_tandem_heat() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_eq(javelin.warhead_type, MissileDataScript.WarheadType.TANDEM_HEAT)
	assert_eq(javelin.penetration_ce, 160)
	assert_true(javelin.defeats_era, "Javelin defeats ERA")
	assert_almost_eq(javelin.blast_radius_m, 3.0, 0.1)


func test_kornet_high_penetration() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	assert_eq(kornet.penetration_ce, 240)  # 高い貫通力


# =============================================================================
# 対抗手段耐性
# =============================================================================

func test_javelin_countermeasures() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_almost_eq(javelin.aps_vulnerability, 0.85, 0.01)
	assert_almost_eq(javelin.smoke_vulnerability, 0.7, 0.01)
	assert_almost_eq(javelin.ecm_vulnerability, 0.0, 0.01)


func test_saclos_countermeasures() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")

	# 有線SACLOSはAPSに弱く、煙幕には強い
	assert_almost_eq(tow.aps_vulnerability, 1.0, 0.01)
	assert_almost_eq(tow.smoke_vulnerability, 0.3, 0.01)


# =============================================================================
# 運用制約
# =============================================================================

func test_shooter_constraint_saclos() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	assert_true(tow.shooter_constrained, "TOW constrains shooter")
	assert_true(kornet.shooter_constrained, "Kornet constrains shooter")


func test_shooter_constraint_faf() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var hj10: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_CHN_HJ10")

	assert_false(javelin.shooter_constrained, "Javelin does not constrain shooter")
	assert_false(hj10.shooter_constrained, "HJ-10 does not constrain shooter")


func test_wire_guided() -> void:
	var tow: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_TOW2B")
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	assert_true(tow.wire_guided, "TOW is wire-guided")
	assert_false(kornet.wire_guided, "Kornet is not wire-guided (laser beam)")
	assert_false(javelin.wire_guided, "Javelin is not wire-guided")


# =============================================================================
# 飛翔時間計算
# =============================================================================

func test_flight_time_direct() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")

	# Kornet: 250 m/s, boost 0.4s
	# 2000mの場合: boost中に 250 * 0.4 * 0.5 = 50m
	# 残り 1950m / 250 = 7.8s
	# 合計 約 8.2s
	var flight_time: float = kornet.calculate_flight_time(2000.0)
	assert_almost_eq(flight_time, 8.2, 0.5, "Kornet 2km flight time ~8.2s")


func test_flight_time_top_attack() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	# Javelin: 140 m/s, boost 0.5s, top_attack 150m alt
	# 2000mの場合、上昇+水平+降下でより長い経路
	var flight_time: float = javelin.calculate_flight_time(2000.0)
	assert_gt(flight_time, 10.0, "Javelin 2km top attack > 10s")
	assert_lt(flight_time, 20.0, "Javelin 2km top attack < 20s")


func test_flight_time_zero_distance() -> void:
	var kornet: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_RUS_KORNET")
	var flight_time: float = kornet.calculate_flight_time(0.0)
	assert_eq(flight_time, 0.0, "Zero distance = zero flight time")


func test_flight_time_min_range() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")

	# 最小射程（65m）での飛翔時間
	var flight_time: float = javelin.calculate_flight_time(65.0)
	assert_gt(flight_time, 0.0, "Min range should have flight time > 0")


# =============================================================================
# InFlightMissile
# =============================================================================

func test_in_flight_missile_creation() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var missile: MissileDataScript.InFlightMissile = MissileDataScript.InFlightMissile.new(javelin)

	assert_not_null(missile.profile)
	assert_eq(missile.profile.id, "M_USA_JAVELIN")
	assert_eq(missile.attack_profile, MissileDataScript.AttackProfile.TOP_ATTACK)  # デフォルト


func test_in_flight_missile_states() -> void:
	var javelin: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_USA_JAVELIN")
	var missile: MissileDataScript.InFlightMissile = MissileDataScript.InFlightMissile.new(javelin)

	# 初期状態
	missile.state = MissileDataScript.MissileState.LAUNCHING
	assert_true(missile.is_in_flight(), "LAUNCHING is in flight")
	assert_false(missile.is_terminated(), "LAUNCHING is not terminated")

	# 飛翔中
	missile.state = MissileDataScript.MissileState.IN_FLIGHT
	assert_true(missile.is_in_flight())
	assert_false(missile.is_terminated())

	# 終末段階
	missile.state = MissileDataScript.MissileState.TERMINAL
	assert_true(missile.is_in_flight())
	assert_false(missile.is_terminated())

	# 着弾
	missile.state = MissileDataScript.MissileState.IMPACT
	assert_false(missile.is_in_flight())
	assert_true(missile.is_terminated())

	# 誘導喪失
	missile.state = MissileDataScript.MissileState.LOST
	assert_false(missile.is_in_flight())
	assert_true(missile.is_terminated())

	# APS迎撃
	missile.state = MissileDataScript.MissileState.INTERCEPTED
	assert_false(missile.is_in_flight())
	assert_true(missile.is_terminated())


# =============================================================================
# ShooterConstraint
# =============================================================================

func test_shooter_constraint_creation() -> void:
	var constraint: MissileDataScript.ShooterConstraint = MissileDataScript.ShooterConstraint.new(
		"shooter_001",
		"missile_001",
		100,
		MissileDataScript.GuidanceType.SACLOS_WIRE
	)

	assert_eq(constraint.shooter_id, "shooter_001")
	assert_eq(constraint.missile_id, "missile_001")
	assert_eq(constraint.start_tick, 100)
	assert_eq(constraint.guidance_type, MissileDataScript.GuidanceType.SACLOS_WIRE)


func test_shooter_constraint_is_constrained() -> void:
	# SACLOS誘導は拘束あり
	var saclos_wire: MissileDataScript.ShooterConstraint = MissileDataScript.ShooterConstraint.new(
		"", "", 0, MissileDataScript.GuidanceType.SACLOS_WIRE
	)
	assert_true(saclos_wire.is_constrained())

	var saclos_laser: MissileDataScript.ShooterConstraint = MissileDataScript.ShooterConstraint.new(
		"", "", 0, MissileDataScript.GuidanceType.SACLOS_LASER_BEAM
	)
	assert_true(saclos_laser.is_constrained())

	var salh: MissileDataScript.ShooterConstraint = MissileDataScript.ShooterConstraint.new(
		"", "", 0, MissileDataScript.GuidanceType.SALH
	)
	assert_true(salh.is_constrained())

	# F&F誘導は拘束なし
	var iir: MissileDataScript.ShooterConstraint = MissileDataScript.ShooterConstraint.new(
		"", "", 0, MissileDataScript.GuidanceType.IIR_HOMING
	)
	assert_false(iir.is_constrained())


# =============================================================================
# 日本軍ミサイル
# =============================================================================

func test_01lmat_profile() -> void:
	var lmat: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_JPN_01LMAT")

	assert_not_null(lmat)
	assert_eq(lmat.display_name, "01 Shiki LMAT")
	assert_eq(lmat.guidance_type, MissileDataScript.GuidanceType.IIR_HOMING)
	assert_eq(lmat.default_attack_profile, MissileDataScript.AttackProfile.TOP_ATTACK)
	assert_almost_eq(lmat.max_range_m, 2000.0, 0.1)
	assert_false(lmat.shooter_constrained)


func test_79mat_profile() -> void:
	var mat: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_JPN_79MAT")

	assert_not_null(mat)
	assert_eq(mat.display_name, "79 Shiki MAT")
	assert_eq(mat.guidance_type, MissileDataScript.GuidanceType.SACLOS_WIRE)
	assert_true(mat.shooter_constrained)
	assert_true(mat.wire_guided)


func test_mmpm_profile() -> void:
	var mmpm: MissileDataScript.MissileProfile = MissileDataScript.get_profile("M_JPN_MMPM")

	assert_not_null(mmpm)
	assert_eq(mmpm.display_name, "MMPM (Chu-MAT)")
	assert_eq(mmpm.guidance_type, MissileDataScript.GuidanceType.IIR_HOMING)
	assert_true(mmpm.can_loal)
	assert_false(mmpm.shooter_constrained)
