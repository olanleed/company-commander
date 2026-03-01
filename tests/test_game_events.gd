extends SceneTree

## GameEvents と イベントクラスのテスト

var _test_count := 0
var _pass_count := 0

func _init():
	print("\n[GameEvents Tests]")

	# GameEventsテスト
	test_game_events_tick_management()
	test_game_events_log_event()
	test_game_events_log_max_size()
	test_game_events_get_recent_events()
	test_game_events_get_events_for_element()
	test_game_events_damage_signal()
	test_game_events_suppression_signal()
	test_game_events_unit_destroyed_signal()
	test_game_events_movement_signals()
	test_game_events_contact_signals()
	test_game_events_ammunition_signals()
	test_game_events_missile_signals()
	test_game_events_resupply_signals()

	# DamageEventテスト
	test_damage_event_creation()
	test_damage_event_to_dict()
	test_damage_event_from_dict()

	# MissileLaunchEventテスト
	test_missile_launch_event_creation()
	test_missile_launch_event_to_dict()

	# SuppressionEventテスト
	test_suppression_event_creation()
	test_suppression_event_to_dict()

	# OrderEventテスト
	test_order_event_creation()
	test_order_event_to_dict()

	print("\n[GameEvents Tests] %d/%d passed" % [_pass_count, _test_count])
	quit()


func assert_true(condition: bool, message: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
	else:
		print("  FAIL: %s" % message)


func assert_eq(actual, expected, message: String) -> void:
	_test_count += 1
	if actual == expected:
		_pass_count += 1
	else:
		print("  FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)])


# =============================================================================
# GameEvents テスト
# =============================================================================

func test_game_events_tick_management():
	print("  ✓ tick_management")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	assert_eq(events.current_tick, 0, "Initial tick should be 0")

	events.set_tick(100)
	assert_eq(events.current_tick, 100, "Tick should be 100 after set_tick")


func test_game_events_log_event():
	print("  ✓ log_event")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	events.set_tick(50)
	events.log_event("TEST_EVENT", {"element_id": "tank1", "value": 42})

	var recent = events.get_recent_events(10)
	assert_eq(recent.size(), 1, "Should have 1 logged event")
	assert_eq(recent[0].tick, 50, "Event tick should be 50")
	assert_eq(recent[0].type, "TEST_EVENT", "Event type should be TEST_EVENT")
	assert_eq(recent[0].data.element_id, "tank1", "Event data should contain element_id")


func test_game_events_log_max_size():
	print("  ✓ log_max_size")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()
	events.set_max_log_size(5)

	for i in range(10):
		events.log_event("EVENT_%d" % i, {"index": i})

	var recent = events.get_recent_events(100)
	assert_eq(recent.size(), 5, "Log should be limited to max_log_size")
	assert_eq(recent[0].data.index, 5, "Oldest event should be index 5")


func test_game_events_get_recent_events():
	print("  ✓ get_recent_events")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	for i in range(20):
		events.log_event("EVENT", {"index": i})

	var recent5 = events.get_recent_events(5)
	assert_eq(recent5.size(), 5, "Should return 5 recent events")
	assert_eq(recent5[4].data.index, 19, "Last event should be index 19")


func test_game_events_get_events_for_element():
	print("  ✓ get_events_for_element")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	events.log_event("DAMAGE", {"element_id": "tank1", "damage": 10})
	events.log_event("DAMAGE", {"element_id": "tank2", "damage": 20})
	events.log_event("MOVE", {"element_id": "tank1", "pos": Vector2(100, 100)})
	events.log_event("DAMAGE", {"target_id": "tank1", "damage": 5})
	events.log_event("FIRE", {"shooter_id": "tank1", "target_id": "tank2"})

	var tank1_events = events.get_events_for_element("tank1", 10)
	assert_eq(tank1_events.size(), 4, "Should return 4 events for tank1")


func test_game_events_damage_signal():
	print("  ✓ damage_applied_signal")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var DamageEvent = preload("res://scripts/events/damage_event.gd")
	var events = GameEvents.new()

	var received_events = []
	events.damage_applied.connect(func(event): received_events.append(event))

	var damage_event = DamageEvent.new()
	damage_event.target_id = "tank1"
	damage_event.damage = 25
	events.emit_damage_applied(damage_event)

	assert_eq(received_events.size(), 1, "Should receive 1 damage event")
	assert_eq(received_events[0].target_id, "tank1", "Target should be tank1")
	assert_eq(received_events[0].damage, 25, "Damage should be 25")


func test_game_events_suppression_signal():
	print("  ✓ suppression_applied_signal")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var SuppressionEvent = preload("res://scripts/events/suppression_event.gd")
	var events = GameEvents.new()

	var received = []
	events.suppression_applied.connect(func(event): received.append(event))

	var supp_event = SuppressionEvent.new()
	supp_event.element_id = "inf1"
	supp_event.delta = 0.3
	events.emit_suppression_applied(supp_event)

	assert_eq(received.size(), 1, "Should receive 1 suppression event")
	assert_eq(received[0].element_id, "inf1", "Element should be inf1")


func test_game_events_unit_destroyed_signal():
	print("  ✓ unit_destroyed_signal")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var DestroyedEvent = preload("res://scripts/events/destroyed_event.gd")
	var events = GameEvents.new()

	var received = []
	events.unit_destroyed.connect(func(event): received.append(event))

	var destroyed_event = DestroyedEvent.new()
	destroyed_event.element_id = "tank1"
	destroyed_event.catastrophic = true
	events.emit_unit_destroyed(destroyed_event)

	assert_eq(received.size(), 1, "Should receive 1 destroyed event")
	assert_true(received[0].catastrophic, "Should be catastrophic")


func test_game_events_movement_signals():
	print("  ✓ movement_signals")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	var started = []
	var completed = []
	events.movement_started.connect(func(id, dest): started.append({"id": id, "dest": dest}))
	events.movement_completed.connect(func(id): completed.append(id))

	events.emit_movement_started("tank1", Vector2(500, 500))
	events.emit_movement_completed("tank1")

	assert_eq(started.size(), 1, "Should receive 1 movement started")
	assert_eq(started[0].dest, Vector2(500, 500), "Destination should match")
	assert_eq(completed.size(), 1, "Should receive 1 movement completed")


func test_game_events_contact_signals():
	print("  ✓ contact_signals")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	var established = []
	var lost = []
	events.contact_established.connect(func(obs, tgt, state): established.append({"obs": obs, "tgt": tgt}))
	events.contact_lost.connect(func(obs, tgt): lost.append({"obs": obs, "tgt": tgt}))

	events.emit_contact_established("recon1", "enemy1", GameEnums.ContactState.CONFIRMED)
	events.emit_contact_lost("recon1", "enemy1")

	assert_eq(established.size(), 1, "Should receive 1 contact established")
	assert_eq(lost.size(), 1, "Should receive 1 contact lost")


func test_game_events_ammunition_signals():
	print("  ✓ ammunition_signals")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	var consumed = []
	var depleted = []
	events.ammunition_consumed.connect(func(eid, wid, cnt): consumed.append({"eid": eid, "cnt": cnt}))
	events.ammo_depleted.connect(func(eid, wid): depleted.append(eid))

	events.emit_ammunition_consumed("tank1", "TANK_120MM", 1)
	events.emit_ammo_depleted("tank1", "TANK_120MM")

	assert_eq(consumed.size(), 1, "Should receive 1 ammo consumed")
	assert_eq(depleted.size(), 1, "Should receive 1 ammo depleted")


func test_game_events_missile_signals():
	print("  ✓ missile_signals")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var MissileLaunchEvent = preload("res://scripts/events/missile_launch_event.gd")
	var events = GameEvents.new()

	var launched = []
	events.missile_launched.connect(func(event): launched.append(event))

	var launch_event = MissileLaunchEvent.new()
	launch_event.missile_id = "missile_001"
	launch_event.shooter_id = "ifv1"
	events.emit_missile_launched(launch_event)

	assert_eq(launched.size(), 1, "Should receive 1 missile launched")
	assert_eq(launched[0].missile_id, "missile_001", "Missile ID should match")


func test_game_events_resupply_signals():
	print("  ✓ resupply_signals")
	var GameEvents = preload("res://scripts/events/game_events.gd")
	var events = GameEvents.new()

	var received = []
	events.resupply_received.connect(func(eid, sid, amt): received.append({"eid": eid, "amt": amt}))

	events.emit_resupply_received("tank1", "supply_truck", 5)

	assert_eq(received.size(), 1, "Should receive 1 resupply event")
	assert_eq(received[0].amt, 5, "Amount should be 5")


# =============================================================================
# DamageEvent テスト
# =============================================================================

func test_damage_event_creation():
	print("  ✓ damage_event_creation")
	var DamageEvent = preload("res://scripts/events/damage_event.gd")
	var event = DamageEvent.new()

	event.tick = 100
	event.target_id = "tank1"
	event.shooter_id = "tank2"
	event.weapon_id = "TANK_120MM"
	event.damage = 30
	event.penetration_result = "FULL_PEN"
	event.hit_zone = "FRONT"

	assert_eq(event.tick, 100, "Tick should be 100")
	assert_eq(event.target_id, "tank1", "Target should be tank1")
	assert_eq(event.damage, 30, "Damage should be 30")


func test_damage_event_to_dict():
	print("  ✓ damage_event_to_dict")
	var DamageEvent = preload("res://scripts/events/damage_event.gd")
	var event = DamageEvent.new()

	event.tick = 50
	event.target_id = "tank1"
	event.shooter_id = "ifv1"
	event.weapon_id = "TOW_2B"
	event.damage = 100
	event.penetration_result = "FULL_PEN"
	event.hit_zone = "TOP"
	event.armor_damage = 1.5
	event.subsystem_hit = "MOBILITY"

	var dict = event.to_dict()

	assert_eq(dict.tick, 50, "Dict tick should be 50")
	assert_eq(dict.target_id, "tank1", "Dict target_id should be tank1")
	assert_eq(dict.subsystem_hit, "MOBILITY", "Dict subsystem_hit should be MOBILITY")


func test_damage_event_from_dict():
	print("  ✓ damage_event_from_dict")
	var DamageEvent = preload("res://scripts/events/damage_event.gd")

	var dict = {
		"tick": 200,
		"target_id": "ifv1",
		"shooter_id": "tank3",
		"weapon_id": "APFSDS",
		"damage": 50,
		"penetration_result": "PARTIAL_PEN",
		"hit_zone": "SIDE",
		"armor_damage": 0.8,
		"subsystem_hit": "FIREPOWER"
	}

	var event = DamageEvent.from_dict(dict)

	assert_eq(event.tick, 200, "Event tick should be 200")
	assert_eq(event.target_id, "ifv1", "Event target should be ifv1")
	assert_eq(event.damage, 50, "Event damage should be 50")
	assert_eq(event.subsystem_hit, "FIREPOWER", "Event subsystem should be FIREPOWER")


# =============================================================================
# MissileLaunchEvent テスト
# =============================================================================

func test_missile_launch_event_creation():
	print("  ✓ missile_launch_event_creation")
	var MissileLaunchEvent = preload("res://scripts/events/missile_launch_event.gd")
	var event = MissileLaunchEvent.new()

	event.tick = 300
	event.missile_id = "missile_001"
	event.shooter_id = "ifv1"
	event.target_id = "tank1"
	event.weapon_id = "TOW_2B"
	event.launch_position = Vector2(100, 200)
	event.target_position = Vector2(500, 600)
	event.guidance_type = "SACLOS"

	assert_eq(event.tick, 300, "Tick should be 300")
	assert_eq(event.missile_id, "missile_001", "Missile ID should match")
	assert_eq(event.guidance_type, "SACLOS", "Guidance type should be SACLOS")


func test_missile_launch_event_to_dict():
	print("  ✓ missile_launch_event_to_dict")
	var MissileLaunchEvent = preload("res://scripts/events/missile_launch_event.gd")
	var event = MissileLaunchEvent.new()

	event.tick = 400
	event.missile_id = "javelin_001"
	event.shooter_id = "inf1"
	event.target_id = "tank2"
	event.weapon_id = "JAVELIN"
	event.launch_position = Vector2(50, 100)
	event.target_position = Vector2(800, 900)
	event.guidance_type = "TOP_ATTACK"

	var dict = event.to_dict()

	assert_eq(dict.tick, 400, "Dict tick should be 400")
	assert_eq(dict.guidance_type, "TOP_ATTACK", "Dict guidance_type should be TOP_ATTACK")
	assert_eq(dict.launch_position.x, 50, "Dict launch_position.x should be 50")


# =============================================================================
# SuppressionEvent テスト
# =============================================================================

func test_suppression_event_creation():
	print("  ✓ suppression_event_creation")
	var SuppressionEvent = preload("res://scripts/events/suppression_event.gd")
	var event = SuppressionEvent.new()

	event.tick = 150
	event.element_id = "inf1"
	event.old_value = 0.2
	event.new_value = 0.5
	event.delta = 0.3
	event.source_id = "mg_team"

	assert_eq(event.tick, 150, "Tick should be 150")
	assert_eq(event.delta, 0.3, "Delta should be 0.3")


func test_suppression_event_to_dict():
	print("  ✓ suppression_event_to_dict")
	var SuppressionEvent = preload("res://scripts/events/suppression_event.gd")
	var event = SuppressionEvent.new()

	event.tick = 200
	event.element_id = "inf2"
	event.old_value = 0.0
	event.new_value = 0.7
	event.delta = 0.7

	var dict = event.to_dict()

	assert_eq(dict.tick, 200, "Dict tick should be 200")
	assert_eq(dict.element_id, "inf2", "Dict element_id should be inf2")


# =============================================================================
# OrderEvent テスト
# =============================================================================

func test_order_event_creation():
	print("  ✓ order_event_creation")
	var OrderEvent = preload("res://scripts/events/order_event.gd")
	var event = OrderEvent.new()

	event.tick = 500
	event.element_id = "tank1"
	event.order_type = GameEnums.OrderType.MOVE
	event.target_position = Vector2(1000, 1000)
	event.target_id = ""

	assert_eq(event.tick, 500, "Tick should be 500")
	assert_eq(event.order_type, GameEnums.OrderType.MOVE, "Order type should be MOVE")


func test_order_event_to_dict():
	print("  ✓ order_event_to_dict")
	var OrderEvent = preload("res://scripts/events/order_event.gd")
	var event = OrderEvent.new()

	event.tick = 600
	event.element_id = "ifv1"
	event.order_type = GameEnums.OrderType.ATTACK
	event.target_position = Vector2(800, 900)
	event.target_id = "enemy_tank"

	var dict = event.to_dict()

	assert_eq(dict.tick, 600, "Dict tick should be 600")
	assert_eq(dict.target_id, "enemy_tank", "Dict target_id should be enemy_tank")
