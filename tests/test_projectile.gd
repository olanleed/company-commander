extends Node

## 砲弾モデルのテスト
## テスト項目:
## 1. 武器に弾速が設定されていること
## 2. ProjectileManagerが砲弾を生成・更新できること
## 3. 砲弾が正しい時間で目標に到達すること
## 4. 陣営に応じた色が正しいこと


func _ready() -> void:
	run_tests()


func run_tests() -> void:
	print("=== Projectile Model Tests ===")
	test_weapon_projectile_speed()
	test_projectile_manager_creation()
	test_projectile_flight_time()
	test_projectile_faction_colors()
	test_fire_rate_calculation()
	print("=== All Projectile Tests Complete ===")
	get_tree().quit()


## 武器に弾速が設定されているかテスト
func test_weapon_projectile_speed() -> void:
	print("\n--- Test: Weapon Projectile Speed ---")

	# 戦車砲APFSDS
	var tank_ke := WeaponData.create_cw_tank_ke()
	print("Tank APFSDS speed: %d m/s (expected ~1700)" % int(tank_ke.projectile_speed_mps))
	assert(tank_ke.projectile_speed_mps > 1500, "Tank gun should have high projectile speed")
	assert(tank_ke.projectile_size > 0, "Tank gun should have projectile size")

	# RPG
	var rpg := WeaponData.create_cw_rpg_heat()
	print("RPG speed: %d m/s (expected ~300)" % int(rpg.projectile_speed_mps))
	assert(rpg.projectile_speed_mps > 200, "RPG should have projectile speed")
	assert(rpg.projectile_speed_mps < 500, "RPG should be slower than tank gun")

	# Carl Gustaf
	var cg := WeaponData.create_cw_carl_gustaf()
	print("Carl Gustaf speed: %d m/s (expected ~255)" % int(cg.projectile_speed_mps))
	assert(cg.projectile_speed_mps > 200, "Carl Gustaf should have projectile speed")

	# 小銃（弾速なし＝hitscan）
	var rifle := WeaponData.create_cw_rifle_std()
	print("Rifle speed: %d m/s (expected 0 - hitscan)" % int(rifle.projectile_speed_mps))
	assert(rifle.projectile_speed_mps == 0.0, "Rifle should be hitscan (no projectile)")

	print("PASS: Weapon projectile speeds correct")


## ProjectileManager生成テスト
func test_projectile_manager_creation() -> void:
	print("\n--- Test: ProjectileManager Creation ---")

	var manager := ProjectileManager.new()
	assert(manager != null, "ProjectileManager should be created")

	# 初期状態では砲弾なし
	assert(manager.get_active_count() == 0, "Should have no projectiles initially")

	# 砲弾を発射
	var tank_ke := WeaponData.create_cw_tank_ke()
	manager.fire_projectile(
		Vector2(0, 0),
		Vector2(1000, 0),
		tank_ke,
		GameEnums.Faction.BLUE,
		true
	)

	assert(manager.get_active_count() == 1, "Should have 1 projectile after firing")
	assert(manager.get_count_by_faction(GameEnums.Faction.BLUE) == 1, "Should have 1 BLUE projectile")
	assert(manager.get_count_by_faction(GameEnums.Faction.RED) == 0, "Should have 0 RED projectiles")

	# REDからも発射
	manager.fire_projectile(
		Vector2(1000, 0),
		Vector2(0, 0),
		tank_ke,
		GameEnums.Faction.RED,
		false
	)

	assert(manager.get_active_count() == 2, "Should have 2 projectiles")
	assert(manager.get_count_by_faction(GameEnums.Faction.RED) == 1, "Should have 1 RED projectile")

	# クリア
	manager.clear_all()
	assert(manager.get_active_count() == 0, "Should have no projectiles after clear")

	manager.queue_free()
	print("PASS: ProjectileManager creation correct")


## 砲弾飛翔時間テスト
func test_projectile_flight_time() -> void:
	print("\n--- Test: Projectile Flight Time ---")

	var manager := ProjectileManager.new()
	var tank_ke := WeaponData.create_cw_tank_ke()

	# 1700m/s で 850m を飛ぶ → 0.5秒
	var distance := 850.0
	var expected_time := distance / tank_ke.projectile_speed_mps
	print("Distance: %.0fm, Speed: %.0fm/s, Expected time: %.3fs" % [
		distance, tank_ke.projectile_speed_mps, expected_time
	])

	manager.fire_projectile(
		Vector2(0, 0),
		Vector2(distance, 0),
		tank_ke,
		GameEnums.Faction.BLUE,
		true
	)

	# 0.4秒後：まだ飛んでいる
	manager.update_projectiles(0.4)
	assert(manager.get_active_count() == 1, "Should still be flying at 0.4s")

	# さらに0.2秒後（合計0.6秒）：到達している
	manager.update_projectiles(0.2)
	assert(manager.get_active_count() == 0, "Should have arrived by 0.6s")

	manager.queue_free()
	print("PASS: Projectile flight time correct")


## 陣営色テスト
func test_projectile_faction_colors() -> void:
	print("\n--- Test: Projectile Faction Colors ---")

	# 色の定数を確認
	var blue_color := ProjectileManager.COLOR_BLUE
	var red_color := ProjectileManager.COLOR_RED

	print("BLUE color: R=%.2f G=%.2f B=%.2f" % [blue_color.r, blue_color.g, blue_color.b])
	print("RED color: R=%.2f G=%.2f B=%.2f" % [red_color.r, red_color.g, red_color.b])

	# BLUEは青っぽい
	assert(blue_color.b > blue_color.r, "BLUE should have more blue than red")

	# REDは赤っぽい
	assert(red_color.r > red_color.b, "RED should have more red than blue")

	print("PASS: Faction colors correct")


## ファイアレート計算テスト
func test_fire_rate_calculation() -> void:
	print("\n--- Test: Fire Rate Calculation ---")

	var tank_ke := WeaponData.create_cw_tank_ke()

	# 15 rpm = 4秒/発
	# 10Hz → 600 tick/分
	# 600 / 15 = 40 tick/発
	var expected_ticks_per_shot := int(600.0 / tank_ke.rof_rpm)
	print("Tank gun ROF: %.1f rpm" % tank_ke.rof_rpm)
	print("Expected ticks per shot: %d (at 10Hz)" % expected_ticks_per_shot)

	assert(expected_ticks_per_shot == 40, "Tank gun should fire every 40 ticks (4 seconds)")

	# RPGは2 rpm = 30秒/発 = 300 tick/発
	var rpg := WeaponData.create_cw_rpg_heat()
	var rpg_ticks := int(600.0 / rpg.rof_rpm)
	print("RPG ROF: %.1f rpm, ticks per shot: %d" % [rpg.rof_rpm, rpg_ticks])
	assert(rpg_ticks == 300, "RPG should fire every 300 ticks (30 seconds)")

	# Carl Gustafは6 rpm = 10秒/発 = 100 tick/発
	var cg := WeaponData.create_cw_carl_gustaf()
	var cg_ticks := int(600.0 / cg.rof_rpm)
	print("Carl Gustaf ROF: %.1f rpm, ticks per shot: %d" % [cg.rof_rpm, cg_ticks])
	assert(cg_ticks == 100, "Carl Gustaf should fire every 100 ticks (10 seconds)")

	print("PASS: Fire rate calculation correct")
