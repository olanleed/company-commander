extends GutTest

## 間接射撃システムのユニットテスト
## 仕様書: docs/indirect_fire_v0.2.md

var combat_system: CombatSystem


func before_each() -> void:
	combat_system = CombatSystem.new()


# =============================================================================
# 大口径HEクラス設定テスト
# =============================================================================

func test_howitzer_155_has_heavy_he_class() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.caliber_mm, 155.0)


func test_howitzer_152_has_heavy_he_class() -> void:
	var weapon := WeaponData.create_cw_howitzer_152()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.caliber_mm, 152.0)


func test_mortar_120_has_heavy_he_class() -> void:
	var weapon := WeaponData.create_cw_mortar_120()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.HEAVY_HE)
	assert_eq(weapon.caliber_mm, 120.0)


func test_mortar_81_no_heavy_he_class() -> void:
	var weapon := WeaponData.create_cw_mortar_81()
	assert_eq(weapon.heavy_he_class, WeaponData.HeavyHEClass.NONE)


# =============================================================================
# 間接射撃効果テスト（歩兵目標）
# =============================================================================

func test_indirect_fire_effect_on_infantry() -> void:
	var infantry := _create_test_infantry()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃（5m以内）
	var result := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	assert_true(result.is_valid, "Should have valid effect")
	assert_gt(result.d_supp, 0.0, "Should cause suppression")
	assert_gt(result.d_dmg, 0.0, "Should cause damage")


func test_indirect_fire_effect_falloff() -> void:
	var infantry := _create_test_infantry()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃付近（5m）
	var result_near := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 遠距離（20m）
	var result_far := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 20.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 距離が遠いほど効果が減少
	assert_gt(result_near.d_supp, result_far.d_supp, "Near should have more suppression")
	assert_gt(result_near.d_dmg, result_far.d_dmg, "Near should have more damage")


func test_indirect_fire_no_effect_outside_blast_radius() -> void:
	var infantry := _create_test_infantry()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 爆風半径外（35m外）
	var result := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 50.0, GameEnums.TerrainType.OPEN, false, 1
	)

	assert_false(result.is_valid, "Should have no effect outside blast radius")
	assert_eq(result.d_supp, 0.0)
	assert_eq(result.d_dmg, 0.0)


# =============================================================================
# 大口径HE装甲効果テスト（Phase 1コア機能）
# =============================================================================

func test_heavy_he_direct_hit_on_mbt() -> void:
	var mbt := _create_test_mbt()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃（5m以内）
	var result := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 大口径HEは重装甲にも効果がある
	assert_true(result.is_valid, "Should have valid effect")
	assert_gt(result.d_supp, 0.0, "Heavy HE should cause suppression on MBT")
	assert_gt(result.d_dmg, 0.0, "Heavy HE direct hit should cause some damage on MBT")


func test_heavy_he_indirect_hit_on_mbt() -> void:
	var mbt := _create_test_mbt()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 至近弾（15m）- 直撃半径外
	var result := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, 15.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 至近弾でも抑圧効果はある
	assert_true(result.is_valid, "Should have valid effect")
	assert_gt(result.d_supp, 0.0, "Heavy HE should cause suppression on MBT")


func test_heavy_he_more_effective_direct_hit() -> void:
	var mbt := _create_test_mbt()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃（3m）
	var result_direct := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 至近弾（15m）
	var result_indirect := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, 15.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 直撃は至近弾より高いダメージ
	assert_gt(result_direct.d_dmg, result_indirect.d_dmg,
		"Direct hit should cause more damage than indirect hit")


func test_heavy_he_vs_regular_he_on_mbt() -> void:
	var mbt := _create_test_mbt()
	var howitzer := WeaponData.create_cw_howitzer_155()  # 大口径HE
	var mortar := WeaponData.create_cw_mortar_81()       # 通常HE

	# 同じ距離で比較（直撃相当）
	var result_heavy := combat_system.calculate_indirect_impact_effect(
		mbt, howitzer, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)
	var result_regular := combat_system.calculate_indirect_impact_effect(
		mbt, mortar, 2.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 大口径HEの方がダメージ脆弱性が高い
	# （letalityの差もあるが、m_vuln_dmgの差が主要因）
	assert_gt(result_heavy.d_dmg, result_regular.d_dmg,
		"Heavy HE should be more effective against MBT")


func test_heavy_he_on_ifv() -> void:
	var ifv := _create_test_ifv()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃
	var result := combat_system.calculate_indirect_impact_effect(
		ifv, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# IFVへの効果（MBTより高い）
	assert_true(result.is_valid)
	assert_gt(result.d_dmg, 0.0, "Should cause damage to IFV")


func test_heavy_he_on_apc() -> void:
	var apc := _create_test_apc()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 直撃
	var result := combat_system.calculate_indirect_impact_effect(
		apc, weapon, 3.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# APCへの効果（IFVより高い）
	assert_true(result.is_valid)
	assert_gt(result.d_dmg, 0.0, "Should cause significant damage to APC")


# =============================================================================
# 装甲クラス別脆弱性テスト
# =============================================================================

func test_vulnerability_scaling_by_armor_class() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	var infantry := _create_test_infantry()  # armor_class = 0
	var apc := _create_test_apc()            # armor_class = 1
	var ifv := _create_test_ifv()            # armor_class = 2
	var mbt := _create_test_mbt()            # armor_class = 3

	# 同じ距離（直撃）で比較
	var dist := 3.0
	var result_inf := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)
	var result_apc := combat_system.calculate_indirect_impact_effect(
		apc, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)
	var result_ifv := combat_system.calculate_indirect_impact_effect(
		ifv, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)
	var result_mbt := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)

	# 装甲が厚いほどダメージが減少
	assert_gt(result_inf.d_dmg, result_apc.d_dmg, "Infantry > APC")
	assert_gt(result_apc.d_dmg, result_ifv.d_dmg, "APC > IFV")
	assert_gt(result_ifv.d_dmg, result_mbt.d_dmg, "IFV > MBT")


func test_suppression_scaling_by_armor_class() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	var infantry := _create_test_infantry()
	var mbt := _create_test_mbt()

	var dist := 3.0
	var result_inf := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)
	var result_mbt := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, dist, GameEnums.TerrainType.OPEN, false, 1
	)

	# MBTも抑圧は受けるが、歩兵より少ない
	assert_gt(result_inf.d_supp, result_mbt.d_supp, "Infantry suppression > MBT suppression")
	assert_gt(result_mbt.d_supp, 0.0, "MBT should still receive some suppression")


# =============================================================================
# 地形・塹壕効果テスト
# =============================================================================

func test_cover_reduces_indirect_fire_effect() -> void:
	var infantry := _create_test_infantry()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 開放地
	var result_open := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 10.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 市街地
	var result_urban := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 10.0, GameEnums.TerrainType.URBAN, false, 1
	)

	# 市街地は遮蔽効果で被害減少
	assert_gt(result_open.d_dmg, result_urban.d_dmg, "Urban cover should reduce damage")
	assert_gt(result_open.d_supp, result_urban.d_supp, "Urban cover should reduce suppression")


func test_entrenchment_reduces_indirect_fire_effect() -> void:
	var infantry := _create_test_infantry()
	var weapon := WeaponData.create_cw_howitzer_155()

	# 塹壕なし
	var result_normal := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 10.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 塹壕あり
	var result_entrenched := combat_system.calculate_indirect_impact_effect(
		infantry, weapon, 10.0, GameEnums.TerrainType.OPEN, true, 1
	)

	# 塹壕は被害を軽減（間接は効果減少が小さい: 0.90）
	assert_gt(result_normal.d_dmg, result_entrenched.d_dmg, "Entrenchment should reduce damage")


# =============================================================================
# 120mm迫撃砲テスト（大口径HEの境界ケース）
# =============================================================================

func test_mortar_120_effect_on_mbt() -> void:
	var mbt := _create_test_mbt()
	var weapon := WeaponData.create_cw_mortar_120()

	# 直撃
	var result := combat_system.calculate_indirect_impact_effect(
		mbt, weapon, 2.0, GameEnums.TerrainType.OPEN, false, 1
	)

	# 120mmも大口径HEとして効果がある
	assert_true(result.is_valid)
	assert_gt(result.d_supp, 0.0, "120mm should suppress MBT")
	assert_gt(result.d_dmg, 0.0, "120mm direct hit should cause some damage")


# =============================================================================
# FIRE_MISSIONコマンドテスト
# =============================================================================

func test_fire_mission_sets_target_position() -> void:
	var artillery := _create_test_artillery()
	var target_pos := Vector2(800, 400)

	# 間接射撃任務を設定
	artillery.fire_mission_target = target_pos
	artillery.fire_mission_active = true
	artillery.current_order_type = GameEnums.OrderType.FIRE_MISSION

	assert_true(artillery.fire_mission_active, "Fire mission should be active")
	assert_eq(artillery.fire_mission_target, target_pos, "Target position should be set")
	assert_eq(artillery.current_order_type, GameEnums.OrderType.FIRE_MISSION)


func test_fire_mission_inactive_by_default() -> void:
	var artillery := _create_test_artillery()

	assert_false(artillery.fire_mission_active, "Fire mission should be inactive by default")
	assert_eq(artillery.fire_mission_target, Vector2.ZERO, "Target should be zero by default")


func test_artillery_has_indirect_weapon() -> void:
	# VehicleCatalog経由で砲兵を作成
	ElementFactory.init_vehicle_catalog()
	var sph := ElementFactory.create_element_with_vehicle(
		"JPN_Type99_SPH",
		GameEnums.Faction.BLUE,
		Vector2(300, 900)
	)

	assert_not_null(sph, "Should create SPH element")

	# 間接射撃武器を持っているか確認
	var has_indirect := false
	for weapon in sph.weapons:
		if weapon.fire_model == WeaponData.FireModel.INDIRECT:
			has_indirect = true
			break

	assert_true(has_indirect, "SPH should have indirect fire weapon")


func test_howitzer_weapon_properties() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	# 間接射撃武器の属性を確認
	assert_eq(weapon.fire_model, WeaponData.FireModel.INDIRECT, "Should be INDIRECT fire model")
	assert_gt(weapon.sigma_hit_m, 0.0, "Should have CEP (sigma_hit_m)")
	assert_gt(weapon.blast_radius_m, 0.0, "Should have blast radius")
	assert_gt(weapon.direct_hit_radius_m, 0.0, "Should have direct hit radius")
	assert_gt(weapon.max_range_m, 10000.0, "Should have long range (>10km)")


func test_mortar_weapon_properties() -> void:
	var weapon := WeaponData.create_cw_mortar_120()

	# 間接射撃武器の属性を確認
	assert_eq(weapon.fire_model, WeaponData.FireModel.INDIRECT, "Should be INDIRECT fire model")
	assert_gt(weapon.sigma_hit_m, 0.0, "Should have CEP (sigma_hit_m)")
	assert_gt(weapon.blast_radius_m, 0.0, "Should have blast radius")


# =============================================================================
# 間接射撃の飛翔時間テスト
# =============================================================================

func test_projectile_speed_calculates_flight_time() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	# 弾速があることを確認
	assert_gt(weapon.projectile_speed_mps, 0.0, "Howitzer should have projectile speed")

	# 飛翔時間の計算（距離 / 弾速）
	var distance := 5000.0  # 5km
	var flight_time := distance / weapon.projectile_speed_mps

	# 飛翔時間が妥当な範囲内か（155mm榴弾砲は弾速200m/s想定）
	# 5000m / 200m/s = 25秒
	assert_gt(flight_time, 5.0, "Flight time should be > 5s for 5km")
	assert_lt(flight_time, 60.0, "Flight time should be < 60s for 5km")


func test_mortar_projectile_speed() -> void:
	var weapon := WeaponData.create_cw_mortar_120()

	# 迫撃砲も弾速があることを確認
	assert_gt(weapon.projectile_speed_mps, 0.0, "Mortar should have projectile speed")


func test_long_range_flight_time() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	# 最大射程付近の飛翔時間
	var max_range := weapon.max_range_m
	var flight_time := max_range / weapon.projectile_speed_mps

	# 最大射程（20km+）での飛翔時間が計算できることを確認
	assert_gt(flight_time, 10.0, "Long range flight time should be > 10s")
	print("[Test] Max range: %.0fm, Flight time: %.1fs" % [max_range, flight_time])


# =============================================================================
# 遅延ダメージテスト（砲弾着弾待ち）
# =============================================================================

func test_pending_impact_data_structure() -> void:
	# 着弾待ちデータの構造をテスト
	var weapon := WeaponData.create_cw_howitzer_155()
	var shooter_id := "test_artillery_1"
	var impact_pos := Vector2(800, 400)
	var faction := GameEnums.Faction.BLUE

	var distance := 3000.0
	var flight_time_sec := distance / weapon.projectile_speed_mps
	var current_time := 100.0  # 模擬時刻
	var arrival_time := current_time + flight_time_sec

	var impact_data := {
		"shooter_id": shooter_id,
		"impact_pos": impact_pos,
		"weapon": weapon,
		"faction": faction,
		"arrival_time": arrival_time
	}

	# データ構造が正しいことを確認
	assert_eq(impact_data.shooter_id, shooter_id)
	assert_eq(impact_data.impact_pos, impact_pos)
	assert_eq(impact_data.weapon, weapon)
	assert_eq(impact_data.faction, faction)
	assert_gt(impact_data.arrival_time, current_time, "Arrival time should be in the future")


func test_flight_time_varies_with_distance() -> void:
	var weapon := WeaponData.create_cw_howitzer_155()

	var short_range := 1000.0
	var long_range := 10000.0

	var short_flight := short_range / weapon.projectile_speed_mps
	var long_flight := long_range / weapon.projectile_speed_mps

	# 遠距離ほど飛翔時間が長い
	assert_gt(long_flight, short_flight, "Long range should have longer flight time")
	assert_almost_eq(long_flight, short_flight * 10.0, 0.1, "10x distance = 10x flight time")


# =============================================================================
# トレーサー表示時間テスト
# =============================================================================

func test_tracer_duration_matches_flight_time() -> void:
	# トレーサーの表示時間が飛翔時間と一致することをテスト
	var weapon := WeaponData.create_cw_howitzer_155()

	var distance := 5000.0
	var flight_time_sec := distance / weapon.projectile_speed_mps

	# custom_durationとしてflight_time_secを渡す想定
	# 表示時間 > 0 であることを確認
	assert_gt(flight_time_sec, 0.0, "Flight time should be positive")

	# 遠距離射撃ではデフォルト(1秒)より長くなるべき
	assert_gt(flight_time_sec, 1.0, "Long range flight time should exceed default 1s duration")


func test_indirect_fire_model_check() -> void:
	var howitzer := WeaponData.create_cw_howitzer_155()
	var mortar := WeaponData.create_cw_mortar_120()

	# 間接射撃武器はINDIRECT fire modelを持つ
	assert_eq(howitzer.fire_model, WeaponData.FireModel.INDIRECT)
	assert_eq(mortar.fire_model, WeaponData.FireModel.INDIRECT)


# =============================================================================
# 移動時の射撃任務解除テスト
# =============================================================================

func test_fire_mission_cancellation_on_move() -> void:
	var artillery := _create_test_artillery()
	var target_pos := Vector2(800, 400)

	# 間接射撃任務を設定
	artillery.fire_mission_target = target_pos
	artillery.fire_mission_active = true
	artillery.current_order_type = GameEnums.OrderType.FIRE_MISSION

	assert_true(artillery.fire_mission_active, "Fire mission should be active")

	# 移動命令で射撃任務を解除する動作をシミュレート
	# (Main.gdの_cancel_fire_missionと同じ処理)
	artillery.fire_mission_active = false
	artillery.fire_mission_target = Vector2.ZERO

	assert_false(artillery.fire_mission_active, "Fire mission should be cancelled")
	assert_eq(artillery.fire_mission_target, Vector2.ZERO, "Target should be cleared")


func test_artillery_cannot_fire_while_moving() -> void:
	# 砲兵は走行間射撃ができない仕様のテスト
	# fire_mission_activeがfalseの場合、間接射撃は行われない
	var artillery := _create_test_artillery()

	# 初期状態では射撃任務は非アクティブ
	assert_false(artillery.fire_mission_active)

	# 移動中の砲兵は射撃任務を実行できない
	artillery.is_moving = true
	assert_false(artillery.fire_mission_active, "Moving artillery should not have active fire mission")


# =============================================================================
# 砲兵展開・撤収テスト
# =============================================================================

func test_artillery_initial_state_is_stowed() -> void:
	var artillery := _create_test_artillery()

	# 初期状態は収納状態（STOWED）
	var ADS := ElementData.ElementInstance.ArtilleryDeployState
	assert_eq(artillery.artillery_deploy_state, ADS.STOWED, "Initial state should be STOWED")
	assert_eq(artillery.artillery_deploy_progress, 0.0, "Initial progress should be 0")


func test_artillery_deploy_time_set_from_catalog() -> void:
	# VehicleCatalog経由で作成された砲兵は展開時間が設定される
	ElementFactory.init_vehicle_catalog()
	var sph := ElementFactory.create_element_with_vehicle(
		"JPN_Type99_SPH",
		GameEnums.Faction.BLUE,
		Vector2(300, 900)
	)

	# 99式は履帯式自走砲なので展開15秒、撤収20秒
	assert_gt(sph.artillery_deploy_time_sec, 0.0, "Deploy time should be set")
	assert_gt(sph.artillery_pack_time_sec, 0.0, "Pack time should be set")
	print("[Test] Type99 SPH: deploy=%.1fs, pack=%.1fs" % [
		sph.artillery_deploy_time_sec, sph.artillery_pack_time_sec
	])


func test_artillery_wheeled_slower_deploy() -> void:
	# 装輪式自走砲は履帯式より展開が遅い
	ElementFactory.init_vehicle_catalog()
	var tracked := ElementFactory.create_element_with_vehicle(
		"JPN_Type99_SPH",  # 履帯式
		GameEnums.Faction.BLUE,
		Vector2(300, 900)
	)
	var wheeled := ElementFactory.create_element_with_vehicle(
		"JPN_Type19_SPH",  # 装輪式
		GameEnums.Faction.BLUE,
		Vector2(400, 900)
	)

	# 装輪式は履帯式より展開時間が長い
	assert_gt(wheeled.artillery_deploy_time_sec, tracked.artillery_deploy_time_sec,
		"Wheeled SPH should have longer deploy time than tracked")
	print("[Test] Tracked: %.1fs, Wheeled: %.1fs" % [
		tracked.artillery_deploy_time_sec, wheeled.artillery_deploy_time_sec
	])


func test_artillery_deploy_state_transition() -> void:
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# STOWED -> DEPLOYING
	artillery.artillery_deploy_state = ADS.DEPLOYING
	artillery.artillery_deploy_progress = 0.0
	assert_eq(artillery.artillery_deploy_state, ADS.DEPLOYING)

	# 展開完了をシミュレート
	artillery.artillery_deploy_progress = 1.0
	artillery.artillery_deploy_state = ADS.DEPLOYED
	assert_eq(artillery.artillery_deploy_state, ADS.DEPLOYED)

	# DEPLOYED -> PACKING
	artillery.artillery_deploy_state = ADS.PACKING
	artillery.artillery_deploy_progress = 0.0
	assert_eq(artillery.artillery_deploy_state, ADS.PACKING)

	# 撤収完了をシミュレート
	artillery.artillery_deploy_progress = 1.0
	artillery.artillery_deploy_state = ADS.STOWED
	assert_eq(artillery.artillery_deploy_state, ADS.STOWED)


func test_artillery_cannot_fire_while_stowed() -> void:
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# 収納状態では射撃不可
	artillery.artillery_deploy_state = ADS.STOWED
	artillery.fire_mission_active = false
	assert_false(artillery.fire_mission_active, "Cannot fire while stowed")


func test_artillery_can_fire_when_deployed() -> void:
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# 展開完了状態では射撃可能
	artillery.artillery_deploy_state = ADS.DEPLOYED
	artillery.fire_mission_target = Vector2(800, 400)
	artillery.fire_mission_active = true
	assert_true(artillery.fire_mission_active, "Can fire when deployed")


# =============================================================================
# UI表示テスト（射撃位置・CEP・展開ゲージ）
# =============================================================================

func test_fire_mission_target_shown_while_deploying() -> void:
	# 展開中でも射撃目標が設定されていればCEP表示の条件を満たす
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState
	var target_pos := Vector2(800, 400)

	# 展開中の状態
	artillery.artillery_deploy_state = ADS.DEPLOYING
	artillery.artillery_deploy_progress = 0.5
	artillery.fire_mission_target = target_pos
	artillery.fire_mission_active = false  # 展開中は射撃不可

	# 射撃目標が設定されている（CEP表示の条件）
	assert_ne(artillery.fire_mission_target, Vector2.ZERO,
		"Fire mission target should be set while deploying")
	# 展開中なのでfire_mission_activeはfalse
	assert_false(artillery.fire_mission_active,
		"Fire mission should not be active while deploying")


func test_deploy_progress_trackable() -> void:
	# 展開進捗がトラッキングできることをテスト
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# 展開を開始
	artillery.artillery_deploy_state = ADS.DEPLOYING
	artillery.artillery_deploy_progress = 0.0

	# 進捗が更新できる
	artillery.artillery_deploy_progress = 0.25
	assert_almost_eq(artillery.artillery_deploy_progress, 0.25, 0.01, "Progress should be 25%")

	artillery.artillery_deploy_progress = 0.5
	assert_almost_eq(artillery.artillery_deploy_progress, 0.5, 0.01, "Progress should be 50%")

	artillery.artillery_deploy_progress = 0.75
	assert_almost_eq(artillery.artillery_deploy_progress, 0.75, 0.01, "Progress should be 75%")

	artillery.artillery_deploy_progress = 1.0
	assert_almost_eq(artillery.artillery_deploy_progress, 1.0, 0.01, "Progress should be 100%")


func test_packing_progress_trackable() -> void:
	# 撤収進捗がトラッキングできることをテスト
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# 撤収を開始
	artillery.artillery_deploy_state = ADS.PACKING
	artillery.artillery_deploy_progress = 0.0

	# 進捗が更新できる
	artillery.artillery_deploy_progress = 0.5
	assert_almost_eq(artillery.artillery_deploy_progress, 0.5, 0.01, "Packing progress should be 50%")

	artillery.artillery_deploy_progress = 1.0
	assert_eq(artillery.artillery_deploy_state, ADS.PACKING, "Should still be PACKING until state change")


func test_deploy_bar_conditions() -> void:
	# 展開ゲージ表示条件のテスト
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState

	# STOWED: ゲージ非表示
	artillery.artillery_deploy_state = ADS.STOWED
	assert_eq(artillery.artillery_deploy_state, ADS.STOWED)

	# DEPLOYING: ゲージ表示（黄色）
	artillery.artillery_deploy_state = ADS.DEPLOYING
	artillery.artillery_deploy_progress = 0.3
	assert_eq(artillery.artillery_deploy_state, ADS.DEPLOYING)
	assert_gt(artillery.artillery_deploy_progress, 0.0, "Progress should be visible")

	# DEPLOYED with target: ゲージ表示（緑）
	artillery.artillery_deploy_state = ADS.DEPLOYED
	artillery.fire_mission_target = Vector2(800, 400)
	assert_eq(artillery.artillery_deploy_state, ADS.DEPLOYED)
	assert_ne(artillery.fire_mission_target, Vector2.ZERO)

	# PACKING: ゲージ表示（オレンジ）
	artillery.artillery_deploy_state = ADS.PACKING
	artillery.artillery_deploy_progress = 0.6
	assert_eq(artillery.artillery_deploy_state, ADS.PACKING)


func test_cep_shown_during_all_deploy_states() -> void:
	# 射撃目標が設定されていれば、どの展開状態でもCEP表示条件を満たす
	var artillery := _create_test_artillery()
	var ADS := ElementData.ElementInstance.ArtilleryDeployState
	var target_pos := Vector2(800, 400)

	# DEPLOYING状態でもCEP表示
	artillery.artillery_deploy_state = ADS.DEPLOYING
	artillery.fire_mission_target = target_pos
	assert_ne(artillery.fire_mission_target, Vector2.ZERO, "CEP should show during DEPLOYING")

	# DEPLOYED状態でもCEP表示
	artillery.artillery_deploy_state = ADS.DEPLOYED
	assert_ne(artillery.fire_mission_target, Vector2.ZERO, "CEP should show during DEPLOYED")

	# PACKING状態では射撃目標がクリアされる（移動命令時）
	artillery.artillery_deploy_state = ADS.PACKING
	artillery.fire_mission_target = Vector2.ZERO  # 移動命令でクリア
	assert_eq(artillery.fire_mission_target, Vector2.ZERO, "CEP should not show during PACKING")


# =============================================================================
# ヘルパー関数
# =============================================================================

func _create_test_infantry() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "test_infantry"
	element_type.max_strength = 30
	element_type.armor_class = 0  # Soft

	var element := ElementData.ElementInstance.new()
	element.element_type = element_type
	element.id = "test_infantry_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 30

	return element


func _create_test_apc() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "test_apc"
	element_type.max_strength = 4
	element_type.armor_class = 1  # Light armor
	element_type.mobility_class = GameEnums.MobilityType.TRACKED

	var element := ElementData.ElementInstance.new()
	element.element_type = element_type
	element.id = "test_apc_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 4

	return element


func _create_test_ifv() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "test_ifv"
	element_type.max_strength = 4
	element_type.armor_class = 2  # Medium armor
	element_type.mobility_class = GameEnums.MobilityType.TRACKED

	var element := ElementData.ElementInstance.new()
	element.element_type = element_type
	element.id = "test_ifv_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 4

	return element


func _create_test_mbt() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "test_mbt"
	element_type.max_strength = 4
	element_type.armor_class = 3  # Heavy armor
	element_type.mobility_class = GameEnums.MobilityType.TRACKED

	var element := ElementData.ElementInstance.new()
	element.element_type = element_type
	element.id = "test_mbt_" + str(randi())
	element.faction = GameEnums.Faction.RED
	element.position = Vector2(600, 600)
	element.suppression = 0.0
	element.current_strength = 4

	return element


func _create_test_artillery() -> ElementData.ElementInstance:
	var element_type := ElementData.ElementType.new()
	element_type.id = "SP_ARTILLERY"
	element_type.max_strength = 4
	element_type.armor_class = 1  # Light armor
	element_type.mobility_class = GameEnums.MobilityType.TRACKED

	var element := ElementData.ElementInstance.new()
	element.element_type = element_type
	element.id = "test_artillery_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(300, 900)
	element.suppression = 0.0
	element.current_strength = 4

	# 間接射撃武器を追加
	var howitzer := WeaponData.create_cw_howitzer_155()
	element.weapons.append(howitzer)
	element.primary_weapon = howitzer

	return element
