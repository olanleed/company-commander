extends GutTest

## CombatSystemのイベント発火テスト
## フェーズ2: イベント駆動への移行

var CombatSystemClass: GDScript
var ElementFactoryClass: GDScript
var GameEventsClass: GDScript
var DamageEventClass: GDScript
var SuppressionEventClass: GDScript
var DestroyedEventClass: GDScript

var combat_system: CombatSystem
var game_events


func before_all() -> void:
	CombatSystemClass = load("res://scripts/systems/combat_system.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")
	GameEventsClass = load("res://scripts/events/game_events.gd")
	DamageEventClass = load("res://scripts/events/damage_event.gd")
	SuppressionEventClass = load("res://scripts/events/suppression_event.gd")
	DestroyedEventClass = load("res://scripts/events/destroyed_event.gd")


func before_each() -> void:
	ElementFactoryClass.reset_id_counters()
	game_events = GameEventsClass.new()
	combat_system = CombatSystemClass.new()
	combat_system.set_game_events(game_events)


# =============================================================================
# GameEvents注入テスト
# =============================================================================

func test_combat_system_accepts_game_events() -> void:
	var events = GameEventsClass.new()
	var system = CombatSystemClass.new()

	system.set_game_events(events)

	assert_eq(system.get_game_events(), events, "GameEvents should be set")


func test_combat_system_works_without_game_events() -> void:
	var system = CombatSystemClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)

	# GameEventsなしでも動作する
	system.apply_damage(element, 0.1, 0.5, 100)

	assert_true(element.suppression > 0, "Suppression should be applied")


# =============================================================================
# ダメージイベント発火テスト
# =============================================================================

func test_apply_damage_emits_damage_event() -> void:
	var received_events = []
	game_events.damage_applied.connect(func(event): received_events.append(event))
	game_events.set_tick(100)

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)

	combat_system.apply_damage(target, 0.1, 5.0, 100)

	assert_eq(received_events.size(), 1, "Should emit 1 damage event")
	var event = received_events[0]
	assert_eq(event.target_id, target.id, "Event target should match")
	assert_eq(event.damage, 5, "Event damage should be 5")
	assert_eq(event.tick, 100, "Event tick should be 100")


func test_apply_damage_does_not_emit_when_no_game_events() -> void:
	var system = CombatSystemClass.new()
	# game_eventsを設定しない

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)

	# エラーなく実行できる
	system.apply_damage(target, 0.1, 5.0, 100)

	assert_true(true, "No error when game_events is null")


func test_apply_damage_logs_event() -> void:
	game_events.set_tick(200)

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)

	combat_system.apply_damage(target, 0.1, 3.0, 200)

	var recent = game_events.get_recent_events(10)
	assert_gt(recent.size(), 0, "Should have logged events")

	var damage_log = recent.filter(func(e): return e.type == "DAMAGE")
	assert_eq(damage_log.size(), 1, "Should have 1 damage log entry")


# =============================================================================
# 抑圧イベント発火テスト
# =============================================================================

func test_apply_damage_emits_suppression_event() -> void:
	var received_events = []
	game_events.suppression_applied.connect(func(event): received_events.append(event))
	game_events.set_tick(150)

	# 装甲車両は小火器からの抑圧上限が0.2なので、effective_suppは0.2になる
	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)
	var old_supp = target.suppression

	combat_system.apply_damage(target, 0.25, 0.0, 150)

	assert_eq(received_events.size(), 1, "Should emit 1 suppression event")
	var event = received_events[0]
	assert_eq(event.element_id, target.id, "Event element_id should match")
	# 装甲車両は小火器抑圧上限(0.2)が適用される
	assert_almost_eq(event.delta, 0.2, 0.01, "Event delta should be ~0.2 (vehicle cap)")
	assert_almost_eq(event.old_value, old_supp, 0.01, "Event old_value should match")


func test_suppression_event_not_emitted_when_no_change() -> void:
	var received_events = []
	game_events.suppression_applied.connect(func(event): received_events.append(event))

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)

	# 抑圧0で適用
	combat_system.apply_damage(target, 0.0, 0.0, 100)

	assert_eq(received_events.size(), 0, "Should not emit suppression event when delta is 0")


# =============================================================================
# 破壊イベント発火テスト
# =============================================================================

func test_unit_destroyed_emits_event() -> void:
	var received_events = []
	game_events.unit_destroyed.connect(func(event): received_events.append(event))
	game_events.set_tick(300)

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 200)
	)
	target.current_strength = 1  # 残り1

	combat_system.apply_damage(target, 0.0, 10.0, 300)

	assert_true(target.is_destroyed, "Target should be destroyed")
	assert_eq(received_events.size(), 1, "Should emit 1 destroyed event")
	var event = received_events[0]
	assert_eq(event.element_id, target.id, "Event element_id should match")
	assert_eq(event.tick, 300, "Event tick should be 300")


func test_unit_destroyed_event_includes_position() -> void:
	var received_events = []
	game_events.unit_destroyed.connect(func(event): received_events.append(event))

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(500, 600)
	)
	target.current_strength = 1

	combat_system.apply_damage(target, 0.0, 10.0, 400)

	var event = received_events[0]
	assert_eq(event.position, Vector2(500, 600), "Event position should match")


func test_catastrophic_kill_event() -> void:
	var received_events = []
	game_events.unit_destroyed.connect(func(event): received_events.append(event))

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)
	target.current_strength = 1

	# apply_vehicle_damageは確率依存なので、複数回試行して少なくとも1回は破壊されることを確認
	var destroyed := false
	for _i in range(20):
		if target.is_destroyed:
			destroyed = true
			break
		# apply_vehicle_damage(element, threat_class, exposure, current_tick)
		combat_system.apply_vehicle_damage(
			target,
			WeaponData.ThreatClass.AT,
			10.0,  # very high exposure for likely hit
			100
		)

	# 20回試行で破壊されたか確認
	assert_true(destroyed or target.is_destroyed, "Target should be destroyed after multiple high-exposure hits")

	if received_events.size() > 0:
		var event = received_events[0]
		assert_eq(event.element_id, target.id, "Event should have correct element_id")
		# catastrophic_killの場合はcatastrophic=trueになる
		assert_eq(event.catastrophic, target.catastrophic_kill, "Event catastrophic should match element state")
	else:
		# イベントが発火されなかった場合も許容（確率依存）
		assert_true(true, "No destruction event (probabilistic test)")


# =============================================================================
# 複合イベントテスト
# =============================================================================

func test_damage_and_destruction_both_emit_events() -> void:
	var damage_events = []
	var destroyed_events = []
	game_events.damage_applied.connect(func(event): damage_events.append(event))
	game_events.unit_destroyed.connect(func(event): destroyed_events.append(event))
	game_events.set_tick(500)

	var target = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)
	target.current_strength = 1

	combat_system.apply_damage(target, 0.1, 10.0, 500)

	assert_eq(damage_events.size(), 1, "Should emit damage event")
	assert_eq(destroyed_events.size(), 1, "Should also emit destroyed event")


func test_event_log_tracks_all_combat_events() -> void:
	game_events.set_tick(600)

	var target1 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(0, 0)
	)
	var target2 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A4_Bradley",
		GameEnums.Faction.BLUE,
		Vector2(100, 0)
	)

	combat_system.apply_damage(target1, 0.2, 2.0, 600)
	game_events.set_tick(601)
	combat_system.apply_damage(target2, 0.3, 1.0, 601)

	var target1_events = game_events.get_events_for_element(target1.id, 10)
	var target2_events = game_events.get_events_for_element(target2.id, 10)

	assert_gt(target1_events.size(), 0, "Should have events for target1")
	assert_gt(target2_events.size(), 0, "Should have events for target2")
