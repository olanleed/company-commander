extends GutTest

## 弾薬状態システムのテスト
## 仕様: docs/ammunition_system_v0.1.md

const AmmoState := preload("res://scripts/data/ammo_state.gd")


# =============================================================================
# AmmoSlotテスト
# =============================================================================

func test_ammo_slot_total() -> void:
	## 総弾数の計算
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 10
	slot.count_stowed = 20
	slot.max_ready = 14
	slot.max_stowed = 26

	assert_eq(slot.total(), 30, "Total should be ready + stowed")
	assert_eq(slot.max_total(), 40, "Max total should be max_ready + max_stowed")


func test_ammo_slot_is_empty() -> void:
	## 弾切れ判定
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 0
	slot.count_stowed = 0

	assert_true(slot.is_empty(), "Slot should be empty when both counts are 0")

	slot.count_ready = 1
	assert_false(slot.is_empty(), "Slot should not be empty when ready > 0")


func test_ammo_slot_ratios() -> void:
	## 充填率
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 7
	slot.count_stowed = 13
	slot.max_ready = 14
	slot.max_stowed = 26

	assert_almost_eq(slot.ready_ratio(), 0.5, 0.01, "Ready ratio should be 0.5")
	assert_almost_eq(slot.total_ratio(), 0.5, 0.01, "Total ratio should be 0.5")


# =============================================================================
# WeaponAmmoStateテスト
# =============================================================================

func test_weapon_ammo_state_can_fire() -> void:
	## 発射可能判定
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 5
	slot.count_stowed = 10
	slot.max_ready = 14
	slot.max_stowed = 26
	weapon_state.ammo_slots.append(slot)

	assert_true(weapon_state.can_fire(), "Should be able to fire with ready ammo")


func test_weapon_ammo_state_cannot_fire_reloading() -> void:
	## 装填中は発射不可
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 5
	weapon_state.ammo_slots.append(slot)
	weapon_state.is_reloading = true

	assert_false(weapon_state.can_fire(), "Should not be able to fire while reloading")


func test_weapon_ammo_state_cannot_fire_empty() -> void:
	## 即発弾0では発射不可
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 0
	slot.count_stowed = 10
	weapon_state.ammo_slots.append(slot)

	assert_false(weapon_state.can_fire(), "Should not be able to fire with no ready ammo")


func test_weapon_ammo_state_reload() -> void:
	## 装填処理（継続装填）
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	weapon_state.has_autoloader = true
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 0
	slot.count_stowed = 10
	slot.max_ready = 14
	weapon_state.ammo_slots.append(slot)

	# 装填開始
	weapon_state.start_reload()
	assert_true(weapon_state.is_reloading, "Should be reloading after start_reload")
	assert_eq(weapon_state.reload_duration_ticks, AmmoState.RELOAD_TICKS_AUTOLOADER,
		"Autoloader should use fast reload time")

	# 装填進行
	for i in range(AmmoState.RELOAD_TICKS_AUTOLOADER - 1):
		assert_false(weapon_state.update_reload(), "Reload should not complete yet")
		assert_true(weapon_state.is_reloading, "Should still be reloading")

	# 装填完了（1発目）
	assert_true(weapon_state.update_reload(), "Reload should complete")
	assert_eq(slot.count_ready, 1, "Ready count should increase by 1")
	assert_eq(slot.count_stowed, 9, "Stowed count should decrease by 1")
	# まだmax_readyに達していないので継続装填中
	assert_true(weapon_state.is_reloading, "Should continue reloading until max_ready")


func test_weapon_ammo_state_reload_stops_at_max() -> void:
	## 装填はmax_readyで停止する
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	weapon_state.has_autoloader = true
	var slot := AmmoState.AmmoSlot.new("APFSDS")
	slot.count_ready = 1
	slot.count_stowed = 5
	slot.max_ready = 2  # max_readyを2に設定
	weapon_state.ammo_slots.append(slot)

	# 装填開始
	weapon_state.start_reload()

	# 装填完了まで進める
	for i in range(AmmoState.RELOAD_TICKS_AUTOLOADER):
		weapon_state.update_reload()

	# max_readyに達したので装填停止
	assert_eq(slot.count_ready, 2, "Ready count should be max_ready")
	assert_eq(slot.count_stowed, 4, "Stowed count should decrease by 1")
	assert_false(weapon_state.is_reloading, "Should stop reloading at max_ready")


func test_weapon_ammo_state_ammo_switch() -> void:
	## 弾種切替
	var weapon_state := AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	var slot1 := AmmoState.AmmoSlot.new("APFSDS")
	slot1.count_ready = 10
	var slot2 := AmmoState.AmmoSlot.new("HEAT")
	slot2.count_ready = 5
	weapon_state.ammo_slots.append(slot1)
	weapon_state.ammo_slots.append(slot2)

	# 切替
	assert_true(weapon_state.switch_ammo(1), "Should be able to switch ammo")
	assert_eq(weapon_state.current_ammo_index, 1, "Current ammo index should be 1")
	assert_true(weapon_state.is_reloading, "Should be reloading during ammo switch")
	assert_eq(weapon_state.reload_duration_ticks, AmmoState.RELOAD_TICKS_AMMO_SWITCH,
		"Should use ammo switch time")


# =============================================================================
# AmmoStateテスト
# =============================================================================

func test_ammo_state_get_weapon_state() -> void:
	## 武器IDからの弾薬状態取得
	var state := AmmoState.new()
	state.main_gun = AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	state.atgm = AmmoState.WeaponAmmoState.new("W_JPN_ATGM_MMPM")

	assert_not_null(state.get_weapon_state("CW_TANK_KE"), "Should find main gun")
	assert_not_null(state.get_weapon_state("W_JPN_ATGM_MMPM"), "Should find ATGM")
	assert_null(state.get_weapon_state("UNKNOWN"), "Should return null for unknown weapon")


func test_ammo_state_total_ratio() -> void:
	## 総残弾率
	var state := AmmoState.new()

	# 主砲: 20/40
	state.main_gun = AmmoState.WeaponAmmoState.new("CW_TANK_KE")
	var gun_slot := AmmoState.AmmoSlot.new("APFSDS")
	gun_slot.count_ready = 10
	gun_slot.count_stowed = 10
	gun_slot.max_ready = 14
	gun_slot.max_stowed = 26
	state.main_gun.ammo_slots.append(gun_slot)

	# ATGM: 3/6
	state.atgm = AmmoState.WeaponAmmoState.new("W_JPN_ATGM_MMPM")
	var atgm_slot := AmmoState.AmmoSlot.new("ATGM")
	atgm_slot.count_ready = 1
	atgm_slot.count_stowed = 2
	atgm_slot.max_ready = 2
	atgm_slot.max_stowed = 4
	state.atgm.ammo_slots.append(atgm_slot)

	# 合計: (20+3) / (40+6) = 23/46 = 0.5
	var ratio := state.get_total_ammo_ratio()
	assert_almost_eq(ratio, 0.5, 0.01, "Total ammo ratio should be ~0.5")


# =============================================================================
# カタログからの初期化テスト
# =============================================================================

func test_create_from_catalog_main_gun() -> void:
	## 主砲の初期化
	var catalog := {
		"main_gun": {
			"weapon_id": "CW_TANK_KE",
			"ammo_capacity_total": 40,
			"ammo_capacity_ready": 14,
			"autoloader": true,
			"ammo_types": ["APFSDS", "HEAT"]
		}
	}

	var state = AmmoState.create_from_catalog(catalog)

	assert_not_null(state.main_gun, "Main gun should be initialized")
	assert_eq(state.main_gun.weapon_id, "CW_TANK_KE", "Weapon ID should match")
	assert_true(state.main_gun.has_autoloader, "Should have autoloader")
	assert_eq(state.main_gun.ammo_slots.size(), 2, "Should have 2 ammo types")


func test_create_from_catalog_atgm() -> void:
	## ATGMの初期化
	var catalog := {
		"atgm": {
			"weapon_id": "W_JPN_ATGM_MMPM",
			"type": "MMPM",
			"ready_count": 2,
			"reserve_count": 4
		}
	}

	var state = AmmoState.create_from_catalog(catalog)

	assert_not_null(state.atgm, "ATGM should be initialized")
	assert_eq(state.atgm.weapon_id, "W_JPN_ATGM_MMPM", "Weapon ID should match")
	assert_false(state.atgm.has_autoloader, "ATGM should not have autoloader")

	var slot = state.atgm.ammo_slots[0]
	assert_eq(slot.max_ready, 2, "Ready count should be 2")
	assert_eq(slot.max_stowed, 4, "Reserve count should be 4")
	assert_eq(slot.count_ready, 2, "Initial ready should be full")
	assert_eq(slot.count_stowed, 4, "Initial stowed should be full")


func test_create_from_catalog_protection() -> void:
	## 防護情報（誘爆脆弱性）
	var catalog := {
		"protection": {
			"blowout_panels": true
		}
	}

	var state = AmmoState.create_from_catalog(catalog)
	assert_almost_eq(state.ammo_detonation_vulnerability, 0.2, 0.01,
		"Blowout panels should reduce vulnerability to 0.2")
