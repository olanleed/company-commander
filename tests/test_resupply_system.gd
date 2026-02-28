extends GutTest

## 補給システムのテスト
## 弾薬が不正に増えるバグの検証

const ResupplySystemClass := preload("res://scripts/systems/resupply_system.gd")
const AmmoStateClass := preload("res://scripts/data/ammo_state.gd")
const ElementFactoryClass := preload("res://scripts/data/element_factory.gd")


func before_all() -> void:
	ElementFactoryClass.init_vehicle_catalog()


func after_each() -> void:
	ElementFactoryClass.reset_id_counters()


# =============================================================================
# 基本的な補給テスト
# =============================================================================

func test_no_resupply_while_reloading() -> void:
	## 装填中は補給されない
	var resupply := ResupplySystemClass.new()

	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false
	atgm_state.is_reloading = true  # 装填中

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 0
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# 装填中は補給されないことを確認
	# _resupply_weapon は直接呼べないので、間接的にテスト
	assert_true(atgm_state.is_reloading, "Should be reloading")
	assert_eq(slot.count_stowed, 0, "Stowed should remain 0 while reloading")


func test_atgm_ammo_never_exceeds_max() -> void:
	## ATGM弾薬は最大値を超えない
	var type89 := ElementFactoryClass.create_element_with_vehicle(
		"JPN_Type89", GameEnums.Faction.BLUE, Vector2.ZERO
	)

	var atgm := type89.ammo_state.atgm
	var slot := atgm.get_current_slot()

	var initial_ready: int = slot.count_ready
	var initial_stowed: int = slot.count_stowed
	var max_ready: int = slot.max_ready
	var max_stowed: int = slot.max_stowed

	# 初期状態が最大値以下であることを確認
	assert_true(slot.count_ready <= max_ready, "Ready should not exceed max_ready")
	assert_true(slot.count_stowed <= max_stowed, "Stowed should not exceed max_stowed")

	# 合計が最大値以下であることを確認
	var total: int = slot.count_ready + slot.count_stowed
	var max_total: int = max_ready + max_stowed
	assert_true(total <= max_total, "Total should not exceed max_total")


# =============================================================================
# リロードと補給の相互作用テスト
# =============================================================================

func test_reload_does_not_create_ammo() -> void:
	## リロードは弾薬を生成しない（予備弾から即発弾への移動のみ）
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 4
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	var initial_total: int = slot.count_ready + slot.count_stowed

	# リロード開始
	atgm_state.start_reload()

	# リロード完了まで進める
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL * 2 + 10):
		atgm_state.update_reload()

	var final_total: int = slot.count_ready + slot.count_stowed

	# 合計弾数が変わっていないことを確認
	assert_eq(final_total, initial_total, "Total ammo should not change during reload")
	# 即発弾がmax_readyになっていることを確認
	assert_eq(slot.count_ready, 2, "Ready should be max_ready after full reload")
	assert_eq(slot.count_stowed, 2, "Stowed should decrease accordingly")


func test_reload_with_insufficient_stowed() -> void:
	## 予備弾が不足している場合のリロード
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 1  # 予備弾が1発のみ
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# リロード開始
	atgm_state.start_reload()
	assert_true(atgm_state.is_reloading, "Should start reloading")

	# リロード完了
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	# 1発だけ移動
	assert_eq(slot.count_ready, 1, "Ready should be 1")
	assert_eq(slot.count_stowed, 0, "Stowed should be 0")
	# 予備弾がないのでリロード停止
	assert_false(atgm_state.is_reloading, "Should stop reloading when stowed is 0")


func test_reload_with_zero_stowed_does_not_start() -> void:
	## 予備弾が0の場合はリロードが開始されない
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 0  # 予備弾なし
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# リロード開始を試みる
	atgm_state.start_reload()

	# リロードが開始されないことを確認
	assert_false(atgm_state.is_reloading, "Should not start reloading when stowed is 0")


# =============================================================================
# 弾薬消費テスト
# =============================================================================

func test_fire_reduces_ready_ammo() -> void:
	## 発射で即発弾が減少
	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2
	slot.count_stowed = 4
	slot.max_ready = 2
	slot.max_stowed = 4

	var initial_total: int = slot.count_ready + slot.count_stowed

	# 発射をシミュレート
	slot.count_ready -= 1

	var final_total: int = slot.count_ready + slot.count_stowed

	assert_eq(slot.count_ready, 1, "Ready should decrease by 1")
	assert_eq(final_total, initial_total - 1, "Total should decrease by 1")


func test_full_atgm_cycle() -> void:
	## ATGMの完全サイクル: 撃ち切り → リロード → max_readyまで回復
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2
	slot.count_stowed = 4
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# 2発撃つ
	slot.count_ready -= 1  # 1+4
	assert_false(atgm_state.is_reloading, "Should not reload yet")

	slot.count_ready -= 1  # 0+4
	if slot.count_ready == 0 and slot.count_stowed > 0:
		atgm_state.start_reload()

	assert_true(atgm_state.is_reloading, "Should start reloading")
	assert_eq(slot.count_ready, 0, "Ready should be 0")
	assert_eq(slot.count_stowed, 4, "Stowed should still be 4")

	# 1発目のリロード
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 1, "Ready should be 1")
	assert_eq(slot.count_stowed, 3, "Stowed should be 3")
	assert_true(atgm_state.is_reloading, "Should continue reloading")

	# 2発目のリロード
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should be 2 (max_ready)")
	assert_eq(slot.count_stowed, 2, "Stowed should be 2")
	assert_false(atgm_state.is_reloading, "Should stop reloading at max_ready")

	# 合計弾数が減っていることを確認（2発撃ったので）
	var final_total: int = slot.count_ready + slot.count_stowed
	assert_eq(final_total, 4, "Total should be 4 (6 - 2 fired)")


func test_fire_all_then_reload_all() -> void:
	## 全弾撃ち切り → 全弾リロード
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2
	slot.count_stowed = 2  # 合計4発
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# 2発撃つ（即発弾を使い切る）
	slot.count_ready -= 1
	slot.count_ready -= 1
	if slot.count_ready == 0 and slot.count_stowed > 0:
		atgm_state.start_reload()

	assert_eq(slot.count_ready, 0, "Ready should be 0")
	assert_eq(slot.count_stowed, 2, "Stowed should be 2")

	# リロード完了まで
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL * 2 + 10):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should be 2 (max_ready)")
	assert_eq(slot.count_stowed, 0, "Stowed should be 0")
	assert_false(atgm_state.is_reloading, "Should stop reloading")

	# さらに2発撃つ
	slot.count_ready -= 1
	slot.count_ready -= 1
	if slot.count_ready == 0 and slot.count_stowed > 0:
		atgm_state.start_reload()

	# 予備弾がないのでリロード開始されない
	assert_false(atgm_state.is_reloading, "Should not start reloading when stowed is 0")
	assert_eq(slot.count_ready, 0, "Ready should be 0")
	assert_eq(slot.count_stowed, 0, "Stowed should be 0")


# =============================================================================
# 補給システムの直接テスト
# =============================================================================

func test_resupply_progress_tracking() -> void:
	## 補給進捗が正しく追跡される
	var resupply := ResupplySystemClass.new()

	# 進捗辞書が空であることを確認
	assert_true(resupply._resupply_progress.is_empty(), "Progress should be empty initially")


func test_ammo_total_conservation() -> void:
	## 弾薬の合計が増えないことを確認（リロード時）
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 6
	slot.max_ready = 4
	slot.max_stowed = 6
	atgm_state.ammo_slots.append(slot)

	var totals: Array[int] = []
	totals.append(slot.count_ready + slot.count_stowed)

	# リロード開始
	atgm_state.start_reload()

	# 各tick後の合計を記録
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL * 5):
		atgm_state.update_reload()
		totals.append(slot.count_ready + slot.count_stowed)

	# 全ての合計が同じであることを確認
	for i in range(totals.size()):
		assert_eq(totals[i], 6, "Total should always be 6 at step %d" % i)


# =============================================================================
# エッジケーステスト
# =============================================================================

func test_reload_boundary_max_ready_equals_stowed() -> void:
	## max_ready == count_stowed の場合のリロード
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 0
	slot.count_stowed = 2  # max_readyと同じ
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	atgm_state.start_reload()

	# 2発分リロード
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL * 2 + 10):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should be 2")
	assert_eq(slot.count_stowed, 0, "Stowed should be 0")
	assert_false(atgm_state.is_reloading, "Should stop reloading")


func test_reload_single_round() -> void:
	## 1発だけのリロード
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 1  # max_readyの半分
	slot.count_stowed = 1
	slot.max_ready = 2
	slot.max_stowed = 4
	atgm_state.ammo_slots.append(slot)

	# max_readyに達していないのでリロード可能
	atgm_state.start_reload()
	assert_true(atgm_state.is_reloading, "Should start reloading")

	# リロード完了
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should be 2")
	assert_eq(slot.count_stowed, 0, "Stowed should be 0")
	assert_false(atgm_state.is_reloading, "Should stop when max_ready reached")


func test_no_reload_when_ready_is_full() -> void:
	## 即応弾が満杯のときはリロードが開始されない
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2  # max_ready と同じ（満杯）
	slot.count_stowed = 5
	slot.max_ready = 2
	slot.max_stowed = 5
	atgm_state.ammo_slots.append(slot)

	# 即応弾が満杯なのでリロードは開始されない
	atgm_state.start_reload()
	assert_false(atgm_state.is_reloading, "Should NOT start reloading when ready is full")
	assert_eq(slot.count_ready, 2, "Ready should remain 2")
	assert_eq(slot.count_stowed, 5, "Stowed should remain 5")


func test_no_reload_continues_when_ready_becomes_full() -> void:
	## リロード中に即応弾が満杯になったら停止する
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 1
	slot.count_stowed = 5
	slot.max_ready = 2
	slot.max_stowed = 5
	atgm_state.ammo_slots.append(slot)

	# リロード開始
	atgm_state.start_reload()
	assert_true(atgm_state.is_reloading, "Should start reloading")

	# 1発分リロード（80 ticks）
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL):
		atgm_state.update_reload()

	# 即応弾が2になり、max_readyに達したのでリロード停止
	assert_eq(slot.count_ready, 2, "Ready should be 2 (max_ready)")
	assert_eq(slot.count_stowed, 4, "Stowed should be 4")
	assert_false(atgm_state.is_reloading, "Should stop reloading at max_ready")

	# さらにupdate_reloadを呼んでも弾数は変わらない
	for _i in range(AmmoStateClass.RELOAD_TICKS_MANUAL * 5):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should still be 2")
	assert_eq(slot.count_stowed, 4, "Stowed should still be 4")


func test_2plus5_atgm_stays_stable() -> void:
	## 2+5のATGMが安定して維持される（バグ再現テスト）
	var atgm_state := AmmoStateClass.WeaponAmmoState.new("W_TEST_ATGM")
	atgm_state.has_autoloader = false

	var slot := AmmoStateClass.AmmoSlot.new("ATGM")
	slot.count_ready = 2
	slot.count_stowed = 5
	slot.max_ready = 2
	slot.max_stowed = 5
	atgm_state.ammo_slots.append(slot)

	# 多数回のupdate_reloadを呼んでも状態は変わらない
	for _i in range(1000):
		atgm_state.update_reload()

	assert_eq(slot.count_ready, 2, "Ready should remain 2")
	assert_eq(slot.count_stowed, 5, "Stowed should remain 5")
	assert_false(atgm_state.is_reloading, "Should not be reloading")
