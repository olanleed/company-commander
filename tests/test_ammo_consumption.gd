extends GutTest

## 弾薬消費統合テスト
## 射撃ごとに弾薬が減少し、弾切れで射撃不能になることを検証

const ElementFactoryClass := preload("res://scripts/data/element_factory.gd")
const CombatSystemClass := preload("res://scripts/systems/combat_system.gd")
const AmmoStateClass := preload("res://scripts/data/ammo_state.gd")


func before_all() -> void:
	# VehicleCatalogを初期化
	ElementFactoryClass.init_vehicle_catalog()


func after_each() -> void:
	# IDカウンターをリセット
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# 弾薬初期化テスト
# =============================================================================

func test_type10_has_ammo_state() -> void:
	## 10式戦車は弾薬状態を持つ
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_not_null(type10.ammo_state, "10式 should have ammo_state")
	assert_not_null(type10.ammo_state.main_gun, "10式 should have main_gun ammo")


func test_type10_ammo_initialized_correctly() -> void:
	## 弾薬が正しく初期化される
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	var main_gun: AmmoStateClass.WeaponAmmoState = type10.ammo_state.main_gun
	assert_eq(main_gun.weapon_id, "CW_TANK_KE_120_JGSDF", "Weapon ID should match catalog")
	assert_true(main_gun.has_autoloader, "10式 should have autoloader")

	# 総弾数チェック
	# 注: 弾種配分の丸め誤差により、カタログ値(36発)より若干少なくなる場合がある
	var total: int = main_gun.get_total_remaining()
	assert_true(total >= 32 and total <= 36, "10式 should have ~36 rounds total (got %d)" % total)


func test_weapon_id_matches_between_weapon_and_ammo() -> void:
	## 装備武器のIDと弾薬状態の武器IDが一致する
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_not_null(type10.current_weapon, "Should have current weapon")

	var weapon_id: String = type10.current_weapon.id
	var ammo_weapon_id: String = type10.ammo_state.main_gun.weapon_id

	print("Weapon ID: %s, Ammo weapon_id: %s" % [weapon_id, ammo_weapon_id])
	assert_eq(weapon_id, ammo_weapon_id, "Weapon ID should match ammo state weapon_id")


# =============================================================================
# 弾薬消費テスト
# =============================================================================

func test_consume_ammo_reduces_count() -> void:
	## 弾薬消費で残弾が減る
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	var slot: AmmoStateClass.AmmoSlot = type10.ammo_state.main_gun.get_current_slot()
	var initial_ready: int = slot.count_ready

	# 弾薬消費
	var result := combat.consume_ammo(type10, type10.current_weapon)

	assert_true(result, "consume_ammo should succeed")
	assert_eq(slot.count_ready, initial_ready - 1, "Ready ammo should decrease by 1")


func test_consume_ammo_starts_autoload() -> void:
	## 自動装填機が装填を開始する
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	# 弾薬消費
	combat.consume_ammo(type10, type10.current_weapon)

	# 自動装填が開始される
	assert_true(type10.ammo_state.main_gun.is_reloading, "Should start auto-reloading")


func test_multiple_shots_consume_ammo() -> void:
	## 複数回の射撃で弾薬が減少
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	var slot: AmmoStateClass.AmmoSlot = type10.ammo_state.main_gun.get_current_slot()
	var initial_ready: int = slot.count_ready

	# 5回射撃（装填完了を待たずに即発弾を消費）
	for i in range(5):
		# 装填状態をリセット（テスト用）
		type10.ammo_state.main_gun.is_reloading = false
		combat.consume_ammo(type10, type10.current_weapon)

	# 即発弾が5発減少
	assert_eq(slot.count_ready, initial_ready - 5, "Ready ammo should decrease by 5")


# =============================================================================
# 弾切れテスト
# =============================================================================

func test_cannot_fire_when_out_of_ammo() -> void:
	## 弾切れ時は射撃不能
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	# 弾薬を全て消費
	var slot: AmmoStateClass.AmmoSlot = type10.ammo_state.main_gun.get_current_slot()
	slot.count_ready = 0
	slot.count_stowed = 0

	# 射撃可能かチェック
	var check := combat.can_fire_with_ammo(type10, type10.current_weapon)

	assert_false(check.can_fire, "Should not be able to fire with no ammo")
	assert_eq(check.reason, "OUT_OF_AMMO", "Reason should be OUT_OF_AMMO")


func test_cannot_fire_when_reloading() -> void:
	## 装填中は射撃不能
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	# 装填中に設定
	type10.ammo_state.main_gun.is_reloading = true
	type10.ammo_state.main_gun.reload_progress_ticks = 10
	type10.ammo_state.main_gun.reload_duration_ticks = 40

	# 射撃可能かチェック
	var check := combat.can_fire_with_ammo(type10, type10.current_weapon)

	assert_false(check.can_fire, "Should not be able to fire while reloading")
	assert_true(check.reason.begins_with("RELOADING"), "Reason should indicate reloading")


func test_need_reload_when_ready_empty_but_stowed_available() -> void:
	## 即発弾0、予備弾ありの場合は装填が必要
	var type10 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type10", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	# 即発弾0、予備弾あり
	var slot: AmmoStateClass.AmmoSlot = type10.ammo_state.main_gun.get_current_slot()
	slot.count_ready = 0
	slot.count_stowed = 10

	# 射撃可能かチェック
	var check := combat.can_fire_with_ammo(type10, type10.current_weapon)

	assert_false(check.can_fire, "Should not be able to fire without ready ammo")
	assert_eq(check.reason, "NEED_RELOAD_FROM_STOWED", "Reason should indicate reload needed")


# =============================================================================
# 米軍車両テスト
# =============================================================================

func test_m1a2_ammo_consumption() -> void:
	## M1A2の弾薬消費
	var m1a2 := ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3", GameEnums.Faction.BLUE, Vector2.ZERO
	)
	var combat := CombatSystemClass.new()

	assert_not_null(m1a2.ammo_state, "M1A2 should have ammo_state")
	assert_not_null(m1a2.ammo_state.main_gun, "M1A2 should have main_gun ammo")

	var slot: AmmoStateClass.AmmoSlot = m1a2.ammo_state.main_gun.get_current_slot()
	var initial_ready: int = slot.count_ready

	# 弾薬消費
	var result := combat.consume_ammo(m1a2, m1a2.current_weapon)

	assert_true(result, "consume_ammo should succeed")
	assert_eq(slot.count_ready, initial_ready - 1, "Ready ammo should decrease by 1")


# =============================================================================
# ATGMテスト
# =============================================================================

func test_type89_atgm_has_ammo() -> void:
	## 89式IFVはATGM弾薬状態を持つ
	var type89 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type89", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_not_null(type89.ammo_state, "89式 should have ammo_state")
	assert_not_null(type89.ammo_state.atgm, "89式 should have ATGM ammo")

	var atgm_state = type89.ammo_state.atgm
	assert_eq(atgm_state.weapon_id, "W_JPN_ATGM_79MAT", "ATGM weapon_id should match")

	var slot = atgm_state.get_current_slot()
	assert_not_null(slot, "ATGM should have ammo slot")
	assert_eq(slot.count_ready, 2, "Ready count should be 2")
	assert_eq(slot.count_stowed, 4, "Stowed count should be 4")


func test_bradley_atgm_has_ammo() -> void:
	## BradleyはATGM弾薬状態を持つ
	var bradley := ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	assert_not_null(bradley.ammo_state, "Bradley should have ammo_state")
	assert_not_null(bradley.ammo_state.atgm, "Bradley should have ATGM ammo")

	var atgm_state = bradley.ammo_state.atgm
	assert_eq(atgm_state.weapon_id, "W_USA_ATGM_TOW2B", "ATGM weapon_id should match")

	var slot = atgm_state.get_current_slot()
	assert_not_null(slot, "ATGM should have ammo slot")
	assert_eq(slot.count_ready, 2, "Ready count should be 2")
	assert_eq(slot.count_stowed, 5, "Stowed count should be 5")


# =============================================================================
# ATGMリロードテスト
# =============================================================================

func test_atgm_reload_starts_only_at_zero() -> void:
	## ATGMリロードは即発弾が0になったときのみ開始する
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_JPN_ATGM_79MAT")
	atgm_state.has_autoloader = false  # ATGMは手動装填
	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2
	slot.count_stowed = 4
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# 最初の発射: 2+4 → 1+4 (リロードしない)
	slot.count_ready -= 1
	if slot.count_ready == 0 and slot.count_stowed > 0:
		atgm_state.start_reload()
	assert_false(atgm_state.is_reloading, "Should NOT reload when ready=1")
	assert_eq(slot.count_ready, 1, "Ready should be 1")
	assert_eq(slot.count_stowed, 4, "Stowed should still be 4")

	# 2発目: 1+4 → 0+4 (リロード開始)
	slot.count_ready -= 1
	if slot.count_ready == 0 and slot.count_stowed > 0:
		atgm_state.start_reload()
	assert_true(atgm_state.is_reloading, "Should reload when ready=0")
	assert_eq(slot.count_ready, 0, "Ready should be 0")


func test_atgm_reload_continues_until_max_ready() -> void:
	## ATGMリロードはmax_readyに達するまで継続する
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_JPN_ATGM_79MAT")
	atgm_state.has_autoloader = false
	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 4
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# リロード開始
	atgm_state.start_reload()
	assert_true(atgm_state.is_reloading, "Should be reloading")
	assert_eq(atgm_state.reload_duration_ticks, AmmoStateClass.RELOAD_TICKS_MANUAL,
		"ATGM should use manual reload time (80 ticks)")

	# 1発目のリロード完了 (80 ticks)
	for i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 1, "Ready should be 1 after first reload")
	assert_eq(slot.count_stowed, 3, "Stowed should decrease to 3")
	# まだmax_readyに達していないのでリロード継続
	assert_true(atgm_state.is_reloading, "Should continue reloading until max_ready")

	# 2発目のリロード完了
	for i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should be 2 (max_ready)")
	assert_eq(slot.count_stowed, 2, "Stowed should be 2")
	# max_readyに達したのでリロード終了
	assert_false(atgm_state.is_reloading, "Should stop reloading at max_ready")
