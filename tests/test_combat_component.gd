extends "res://tests/test_base.gd"

## CombatComponent テスト
## コンポーネント分離フェーズ1: 戦闘状態（戦力・抑圧・ダメージ）の管理

# =============================================================================
# テスト対象
# =============================================================================

const CombatComponent = preload("res://scripts/components/combat_component.gd")

# =============================================================================
# 基本機能テスト
# =============================================================================

func test_initial_values():
	var comp = CombatComponent.new("test_unit", 100)

	assert_eq(comp.current_strength, 100, "Initial strength should be max")
	assert_eq(comp.max_strength, 100, "Max strength should be 100")
	assert_eq(comp.suppression, 0.0, "Initial suppression should be 0")
	assert_false(comp.is_destroyed, "Should not be destroyed initially")
	_pass("initial_values")


func test_custom_max_strength():
	var comp = CombatComponent.new("tank_plt", 4)

	assert_eq(comp.max_strength, 4, "Max strength should be 4")
	assert_eq(comp.current_strength, 4, "Current strength should be 4")
	_pass("custom_max_strength")


# =============================================================================
# ダメージ適用テスト
# =============================================================================

func test_apply_damage_reduces_strength():
	var comp = CombatComponent.new("test_unit", 100)

	comp.apply_damage(30)

	assert_eq(comp.current_strength, 70, "Strength should be reduced to 70")
	_pass("apply_damage_reduces_strength")


func test_apply_damage_emits_signal():
	var comp = CombatComponent.new("test_unit", 100)
	var events: Array = []

	comp.strength_changed.connect(func(id, old, new):
		events.append({"id": id, "old": old, "new": new})
	)

	comp.apply_damage(30)

	assert_eq(events.size(), 1, "One event should be emitted")
	assert_eq(events[0].id, "test_unit", "Event ID should match")
	assert_eq(events[0].old, 100, "Old value should be 100")
	assert_eq(events[0].new, 70, "New value should be 70")
	_pass("apply_damage_emits_signal")


func test_apply_damage_zero_does_not_emit():
	var comp = CombatComponent.new("test_unit", 100)
	var signal_count = 0

	comp.strength_changed.connect(func(_id, _old, _new): signal_count += 1)

	comp.apply_damage(0)

	assert_eq(signal_count, 0, "No signal for zero damage")
	assert_eq(comp.current_strength, 100, "Strength should be unchanged")
	_pass("apply_damage_zero_does_not_emit")


func test_apply_damage_clamped_to_zero():
	var comp = CombatComponent.new("test_unit", 100)

	comp.apply_damage(150)  # 超過ダメージ

	assert_eq(comp.current_strength, 0, "Strength should be clamped to 0")
	_pass("apply_damage_clamped_to_zero")


# =============================================================================
# 破壊判定テスト
# =============================================================================

func test_destruction_when_strength_zero():
	var comp = CombatComponent.new("test_unit", 10)
	var destroyed = false
	var was_catastrophic = false

	comp.unit_destroyed.connect(func(id, catastrophic):
		destroyed = true
		was_catastrophic = catastrophic
	)

	comp.apply_damage(15)

	assert_true(destroyed, "Destroyed signal should be emitted")
	assert_false(was_catastrophic, "Should not be catastrophic by default")
	assert_true(comp.is_destroyed, "is_destroyed flag should be true")
	_pass("destruction_when_strength_zero")


func test_catastrophic_kill():
	var comp = CombatComponent.new("test_unit", 10)
	var was_catastrophic = false

	comp.unit_destroyed.connect(func(_id, catastrophic):
		was_catastrophic = catastrophic
	)

	comp.apply_damage(15, true)  # catastrophic = true

	assert_true(was_catastrophic, "Should be catastrophic")
	assert_true(comp.catastrophic_kill, "catastrophic_kill flag should be true")
	_pass("catastrophic_kill")


func test_multiple_damage_does_not_re_destroy():
	var comp = CombatComponent.new("test_unit", 10)
	var destroy_count = 0

	comp.unit_destroyed.connect(func(_id, _catastrophic): destroy_count += 1)

	comp.apply_damage(10)  # 破壊
	comp.apply_damage(5)   # 追加ダメージ

	assert_eq(destroy_count, 1, "Destroy signal should only fire once")
	_pass("multiple_damage_does_not_re_destroy")


# =============================================================================
# 抑圧テスト
# =============================================================================

func test_apply_suppression():
	var comp = CombatComponent.new("test_unit", 100)

	comp.apply_suppression(0.3)

	assert_almost_eq(comp.suppression, 0.3, 0.001, "Suppression should be 0.3")
	_pass("apply_suppression")


func test_apply_suppression_emits_signal():
	var comp = CombatComponent.new("test_unit", 100)
	var events: Array = []

	comp.suppression_changed.connect(func(id, old, new):
		events.append({"id": id, "old": old, "new": new})
	)

	comp.apply_suppression(0.5)

	assert_eq(events.size(), 1, "One suppression event should be emitted")
	assert_almost_eq(events[0].old, 0.0, 0.001, "Old suppression should be 0")
	assert_almost_eq(events[0].new, 0.5, 0.001, "New suppression should be 0.5")
	_pass("apply_suppression_emits_signal")


func test_suppression_clamped_to_max():
	var comp = CombatComponent.new("test_unit", 100)

	comp.apply_suppression(1.5)  # 超過

	assert_eq(comp.suppression, 1.0, "Suppression should be clamped to 1.0")
	_pass("suppression_clamped_to_max")


func test_suppression_clamped_to_min():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.5)

	comp.apply_suppression(-1.0)  # 負の値

	assert_eq(comp.suppression, 0.0, "Suppression should be clamped to 0.0")
	_pass("suppression_clamped_to_min")


func test_suppression_no_signal_for_tiny_change():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.5)

	var signal_count = 0
	comp.suppression_changed.connect(func(_id, _old, _new): signal_count += 1)

	comp.apply_suppression(0.001)  # 非常に小さな変化

	# 閾値0.01未満の変化はシグナルを発行しない
	assert_eq(signal_count, 0, "No signal for tiny change")
	_pass("suppression_no_signal_for_tiny_change")


func test_recover_suppression():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.5)

	comp.recover_suppression(0.1)

	assert_almost_eq(comp.suppression, 0.4, 0.001, "Suppression should decrease")
	_pass("recover_suppression")


# =============================================================================
# ダメージ蓄積テスト
# =============================================================================

func test_accumulate_damage():
	var comp = CombatComponent.new("test_unit", 100)
	var damage_events: Array = []

	comp.damage_accumulated.connect(func(id, damage, total):
		damage_events.append({"id": id, "damage": damage, "total": total})
	)

	var applied1 = comp.accumulate_damage(0.5)
	assert_eq(applied1, 0, "No damage applied yet")
	assert_eq(comp.current_strength, 100, "Strength unchanged")

	var applied2 = comp.accumulate_damage(0.6)
	assert_eq(applied2, 1, "1 damage should be applied")
	assert_eq(comp.current_strength, 99, "Strength should decrease by 1")
	_pass("accumulate_damage")


func test_accumulate_damage_multiple():
	var comp = CombatComponent.new("test_unit", 100)

	# 2.5ダメージを蓄積
	comp.accumulate_damage(2.5)

	assert_eq(comp.current_strength, 98, "2 damage should be applied")
	# 残りの0.5は蓄積中
	_pass("accumulate_damage_multiple")


# =============================================================================
# サブシステムHP テスト（装甲車両用）
# =============================================================================

func test_subsystem_initial_values():
	var comp = CombatComponent.new("tank", 4)

	assert_eq(comp.mobility_hp, 100, "Initial mobility HP should be 100")
	assert_eq(comp.firepower_hp, 100, "Initial firepower HP should be 100")
	assert_eq(comp.sensors_hp, 100, "Initial sensors HP should be 100")
	_pass("subsystem_initial_values")


func test_apply_subsystem_damage_mobility():
	var comp = CombatComponent.new("tank", 4)
	var events: Array = []

	comp.subsystem_damaged.connect(func(id, subsystem, old, new):
		events.append({"id": id, "subsystem": subsystem, "old": old, "new": new})
	)

	comp.apply_subsystem_damage("MOBILITY", 25)

	assert_eq(comp.mobility_hp, 75, "Mobility HP should be 75")
	assert_eq(events.size(), 1, "One event should be emitted")
	assert_eq(events[0].subsystem, "MOBILITY", "Subsystem should be MOBILITY")
	_pass("apply_subsystem_damage_mobility")


func test_apply_subsystem_damage_firepower():
	var comp = CombatComponent.new("tank", 4)

	comp.apply_subsystem_damage("FIREPOWER", 50)

	assert_eq(comp.firepower_hp, 50, "Firepower HP should be 50")
	_pass("apply_subsystem_damage_firepower")


func test_apply_subsystem_damage_sensors():
	var comp = CombatComponent.new("tank", 4)

	comp.apply_subsystem_damage("SENSORS", 100)

	assert_eq(comp.sensors_hp, 0, "Sensors HP should be 0")
	_pass("apply_subsystem_damage_sensors")


func test_subsystem_damage_clamped():
	var comp = CombatComponent.new("tank", 4)

	comp.apply_subsystem_damage("MOBILITY", 150)

	assert_eq(comp.mobility_hp, 0, "HP should be clamped to 0")
	_pass("subsystem_damage_clamped")


func test_is_mobility_killed():
	var comp = CombatComponent.new("tank", 4)

	assert_false(comp.is_mobility_killed(), "Not M-KILL initially")

	comp.apply_subsystem_damage("MOBILITY", 100)

	assert_true(comp.is_mobility_killed(), "Should be M-KILL")
	_pass("is_mobility_killed")


func test_is_firepower_killed():
	var comp = CombatComponent.new("tank", 4)

	assert_false(comp.is_firepower_killed(), "Not F-KILL initially")

	comp.apply_subsystem_damage("FIREPOWER", 100)

	assert_true(comp.is_firepower_killed(), "Should be F-KILL")
	_pass("is_firepower_killed")


# =============================================================================
# 抑圧状態判定テスト
# =============================================================================

func test_get_suppression_state_active():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.2)

	var state = comp.get_suppression_state()

	assert_eq(state, GameEnums.SuppressionState.ACTIVE, "Should be ACTIVE")
	_pass("get_suppression_state_active")


func test_get_suppression_state_suppressed():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.5)

	var state = comp.get_suppression_state()

	assert_eq(state, GameEnums.SuppressionState.SUPPRESSED, "Should be SUPPRESSED")
	_pass("get_suppression_state_suppressed")


func test_get_suppression_state_pinned():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(0.8)

	var state = comp.get_suppression_state()

	assert_eq(state, GameEnums.SuppressionState.PINNED, "Should be PINNED")
	_pass("get_suppression_state_pinned")


func test_get_suppression_state_broken():
	var comp = CombatComponent.new("test_unit", 100)
	comp.apply_suppression(1.0)

	var state = comp.get_suppression_state()

	assert_eq(state, GameEnums.SuppressionState.BROKEN, "Should be BROKEN")
	_pass("get_suppression_state_broken")


# =============================================================================
# テスト実行
# =============================================================================

func get_test_methods() -> Array:
	return [
		"test_initial_values",
		"test_custom_max_strength",
		"test_apply_damage_reduces_strength",
		"test_apply_damage_emits_signal",
		"test_apply_damage_zero_does_not_emit",
		"test_apply_damage_clamped_to_zero",
		"test_destruction_when_strength_zero",
		"test_catastrophic_kill",
		"test_multiple_damage_does_not_re_destroy",
		"test_apply_suppression",
		"test_apply_suppression_emits_signal",
		"test_suppression_clamped_to_max",
		"test_suppression_clamped_to_min",
		"test_suppression_no_signal_for_tiny_change",
		"test_recover_suppression",
		"test_accumulate_damage",
		"test_accumulate_damage_multiple",
		"test_subsystem_initial_values",
		"test_apply_subsystem_damage_mobility",
		"test_apply_subsystem_damage_firepower",
		"test_apply_subsystem_damage_sensors",
		"test_subsystem_damage_clamped",
		"test_is_mobility_killed",
		"test_is_firepower_killed",
		"test_get_suppression_state_active",
		"test_get_suppression_state_suppressed",
		"test_get_suppression_state_pinned",
		"test_get_suppression_state_broken",
	]
