extends GutTest

## CombatEventBusのユニットテスト

var event_bus: CombatEventBus
var _received_events: Array[CombatEventBus.CombatEvent] = []


func before_each() -> void:
	event_bus = CombatEventBus.new()
	_received_events.clear()
	event_bus.event_emitted.connect(_on_event_emitted)


func _on_event_emitted(event: CombatEventBus.CombatEvent) -> void:
	_received_events.append(event)


# =============================================================================
# 基本テスト
# =============================================================================

func test_event_bus_initialization() -> void:
	assert_not_null(event_bus)
	var events := event_bus.get_events_since(0)
	assert_eq(events.size(), 0, "初期状態ではイベントは空")


func test_combat_event_creation() -> void:
	var event := CombatEventBus.CombatEvent.new()
	assert_eq(event.event_id, 0)
	assert_eq(event.tick, 0)
	assert_eq(event.team, GameEnums.Faction.NONE)


# =============================================================================
# イベント生成テスト
# =============================================================================

func test_emit_event() -> void:
	var subject_ids: Array[String] = ["elem_1"]
	var tags := {"test": true}

	var event := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2(500, 500),
		"source_1",
		subject_ids,
		tags
	)

	assert_not_null(event, "イベントが生成される")
	assert_eq(event.type, GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED)
	assert_eq(event.severity, GameEnums.EventSeverity.S1_ALERT)
	assert_eq(event.team, GameEnums.Faction.BLUE)
	assert_eq(event.tick, 100)
	assert_eq(event.pos_m, Vector2(500, 500))
	assert_eq(event.source_unit_id, "source_1")
	assert_eq(event.subject_unit_ids.size(), 1)
	assert_eq(event.tags["test"], true)


func test_emit_event_increments_id() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	var event1 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"",
		subject_ids,
		tags
	)

	# クールダウンを回避するため、異なるソースIDを使用
	var event2 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"different_source",
		subject_ids,
		tags
	)

	assert_eq(event2.event_id, event1.event_id + 1, "event_idが連番で増加する")


func test_signal_emitted() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_UNDER_FIRE,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.RED,
		50,
		Vector2(100, 200),
		"",
		subject_ids,
		tags
	)

	assert_eq(_received_events.size(), 1, "シグナルが発火される")
	assert_eq(_received_events[0].type, GameEnums.CombatEventType.EV_UNDER_FIRE)


# =============================================================================
# 接触イベントテスト
# =============================================================================

func test_emit_contact_event_confirmed() -> void:
	var event := event_bus.emit_contact_event(
		true,  # is_confirmed
		GameEnums.Faction.BLUE,
		100,
		Vector2(500, 500),
		"enemy_1",
		GameEnums.TargetClass.SOFT,
		800.0  # distance
	)

	assert_not_null(event)
	assert_eq(event.type, GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED)
	assert_eq(event.severity, GameEnums.EventSeverity.S1_ALERT)


func test_emit_contact_event_confirmed_near() -> void:
	# 近距離（600m以内）の確定接触は S2_ENGAGE に昇格
	var event := event_bus.emit_contact_event(
		true,
		GameEnums.Faction.BLUE,
		100,
		Vector2(500, 500),
		"enemy_1",
		GameEnums.TargetClass.SOFT,
		500.0  # 近距離
	)

	assert_not_null(event)
	assert_eq(event.severity, GameEnums.EventSeverity.S2_ENGAGE, "近距離接触はS2に昇格")


func test_emit_contact_event_suspected() -> void:
	var event := event_bus.emit_contact_event(
		false,  # is_confirmed = false → SUS
		GameEnums.Faction.BLUE,
		100,
		Vector2(500, 500),
		"enemy_1"
	)

	assert_not_null(event)
	assert_eq(event.type, GameEnums.CombatEventType.EV_CONTACT_SUS_ACQUIRED)
	assert_eq(event.severity, GameEnums.EventSeverity.S1_ALERT)


# =============================================================================
# クールダウンテスト
# =============================================================================

func test_cooldown_blocks_duplicate_events() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	var event1 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	# 同じtickで同じソースからのイベント
	var event2 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	assert_not_null(event1)
	assert_null(event2, "クールダウン中はイベントが生成されない")


func test_cooldown_allows_after_timeout() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	var event1 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	# CONTACT_COOLDOWN_TICKS (20tick) 経過後
	var event2 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		125,  # 100 + 25 > 100 + 20
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	assert_not_null(event1)
	assert_not_null(event2, "クールダウン後はイベントが生成される")


func test_casualty_bypasses_cooldown() -> void:
	var subject_ids: Array[String] = ["elem_1"]
	var tags := {}

	var event1 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CASUALTY_TAKEN,
		GameEnums.EventSeverity.S3_EMERGENCY,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"",
		subject_ids,
		tags
	)

	var event2 := event_bus.emit_event(
		GameEnums.CombatEventType.EV_CASUALTY_TAKEN,
		GameEnums.EventSeverity.S3_EMERGENCY,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"",
		subject_ids,
		tags
	)

	assert_not_null(event1)
	assert_not_null(event2, "損耗イベントはクールダウンをバイパスする")


# =============================================================================
# クエリテスト
# =============================================================================

func test_get_events_since() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_UNDER_FIRE,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.BLUE,
		50,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_EXPLOSION_NEAR,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_2",
		subject_ids,
		tags
	)

	var events := event_bus.get_events_since(75)
	assert_eq(events.size(), 1, "指定tick以降のイベントのみ取得")
	assert_eq(events[0].tick, 100)


func test_get_events_near() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_UNDER_FIRE,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.BLUE,
		100,
		Vector2(100, 100),
		"source_1",
		subject_ids,
		tags
	)

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_EXPLOSION_NEAR,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.BLUE,
		100,
		Vector2(1000, 1000),
		"source_2",
		subject_ids,
		tags
	)

	var events := event_bus.get_events_near(Vector2(150, 150), 200.0, 0)
	assert_eq(events.size(), 1, "指定範囲内のイベントのみ取得")
	assert_eq(events[0].pos_m, Vector2(100, 100))


func test_get_threat_events_for_team() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	# BLUE陣営のS1イベント
	event_bus.emit_event(
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED,
		GameEnums.EventSeverity.S1_ALERT,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	# RED陣営のイベント
	event_bus.emit_event(
		GameEnums.CombatEventType.EV_UNDER_FIRE,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.RED,
		100,
		Vector2.ZERO,
		"source_2",
		subject_ids,
		tags
	)

	var blue_events := event_bus.get_threat_events_for_team(GameEnums.Faction.BLUE, 0)
	assert_eq(blue_events.size(), 1)
	assert_eq(blue_events[0].team, GameEnums.Faction.BLUE)


func test_clear() -> void:
	var subject_ids: Array[String] = []
	var tags := {}

	event_bus.emit_event(
		GameEnums.CombatEventType.EV_UNDER_FIRE,
		GameEnums.EventSeverity.S2_ENGAGE,
		GameEnums.Faction.BLUE,
		100,
		Vector2.ZERO,
		"source_1",
		subject_ids,
		tags
	)

	event_bus.clear()

	var events := event_bus.get_events_since(0)
	assert_eq(events.size(), 0, "クリア後はイベントが空")


# =============================================================================
# アラート半径テスト
# =============================================================================

func test_get_alert_radius_contact() -> void:
	var event := CombatEventBus.CombatEvent.new()
	event.type = GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED

	assert_eq(event.get_alert_radius(), GameConstants.ALERT_RADIUS_CONTACT_M)


func test_get_alert_radius_fire() -> void:
	var event := CombatEventBus.CombatEvent.new()
	event.type = GameEnums.CombatEventType.EV_UNDER_FIRE

	assert_eq(event.get_alert_radius(), GameConstants.ALERT_RADIUS_FIRE_M)


func test_get_alert_radius_custom() -> void:
	var event := CombatEventBus.CombatEvent.new()
	event.type = GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED
	event.radius_m = 500.0  # カスタム値

	assert_eq(event.get_alert_radius(), 500.0, "カスタム半径が優先される")
