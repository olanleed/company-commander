class_name CombatEventBus
extends RefCounted

## 戦闘イベントバス
## 仕様書: docs/combat_events_v0.1.md
##
## 戦闘関連イベントの生成、配信、重複抑制を管理

# =============================================================================
# シグナル
# =============================================================================

signal event_emitted(event: CombatEvent)

# =============================================================================
# CombatEvent構造
# =============================================================================

class CombatEvent:
	var event_id: int = 0                          ## 連番（試合内ユニーク）
	var tick: int = 0                              ## 発生tick
	var type: GameEnums.CombatEventType            ## イベント種別
	var severity: GameEnums.EventSeverity          ## 重要度
	var team: GameEnums.Faction = GameEnums.Faction.NONE  ## 陣営視点
	var subject_unit_ids: Array[String] = []       ## 影響を受けるユニット
	var source_unit_id: String = ""                ## 原因ユニット
	var pos_m: Vector2 = Vector2.ZERO              ## 発生地点
	var radius_m: float = 0.0                      ## 影響半径
	var confidence: GameEnums.ContactState = GameEnums.ContactState.UNKNOWN  ## 確度
	var tags: Dictionary = {}                      ## 追加タグ

	func _init() -> void:
		pass

	## 影響半径を取得（イベント種別に応じたデフォルト値）
	func get_alert_radius() -> float:
		if radius_m > 0:
			return radius_m

		match type:
			GameEnums.CombatEventType.EV_CONTACT_SUS_ACQUIRED, \
			GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED:
				return GameConstants.ALERT_RADIUS_CONTACT_M
			GameEnums.CombatEventType.EV_CP_CONTESTED_ENTER:
				return GameConstants.ALERT_RADIUS_CP_M
			GameEnums.CombatEventType.EV_UNDER_FIRE, \
			GameEnums.CombatEventType.EV_EXPLOSION_NEAR, \
			GameEnums.CombatEventType.EV_NEAR_MISS:
				return GameConstants.ALERT_RADIUS_FIRE_M
			_:
				return 0.0

# =============================================================================
# 内部状態
# =============================================================================

var _next_event_id: int = 1
var _event_history: Array[CombatEvent] = []
var _cooldowns: Dictionary = {}  # "type_id" -> last_tick

## 履歴の最大保持数
const MAX_HISTORY_SIZE: int = 500

# =============================================================================
# イベント生成
# =============================================================================

## イベントを生成してエミット
func emit_event(
	type: GameEnums.CombatEventType,
	severity: GameEnums.EventSeverity,
	team: GameEnums.Faction,
	current_tick: int,
	pos: Vector2 = Vector2.ZERO,
	source_id: String = "",
	subject_ids: Array[String] = [],
	tags: Dictionary = {}
) -> CombatEvent:
	# クールダウンチェック
	var cooldown_key := _get_cooldown_key(type, source_id, subject_ids)
	if _is_on_cooldown(cooldown_key, current_tick, type):
		return null

	# イベント作成
	var event := CombatEvent.new()
	event.event_id = _next_event_id
	_next_event_id += 1
	event.tick = current_tick
	event.type = type
	event.severity = severity
	event.team = team
	event.pos_m = pos
	event.source_unit_id = source_id
	event.subject_unit_ids = subject_ids
	event.tags = tags

	# クールダウン設定
	_set_cooldown(cooldown_key, current_tick)

	# 履歴に追加
	_event_history.append(event)
	if _event_history.size() > MAX_HISTORY_SIZE:
		_event_history.pop_front()

	# シグナル発火
	event_emitted.emit(event)

	return event


## 接触イベント（SUS/CONF）を生成
func emit_contact_event(
	is_confirmed: bool,
	team: GameEnums.Faction,
	current_tick: int,
	contact_pos: Vector2,
	target_id: String,
	target_class: GameEnums.TargetClass = GameEnums.TargetClass.UNKNOWN,
	distance_to_nearest: float = 0.0
) -> CombatEvent:
	var type: GameEnums.CombatEventType
	var severity: GameEnums.EventSeverity

	if is_confirmed:
		type = GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED
		# 近距離または重装甲なら昇格
		if distance_to_nearest <= GameConstants.ESCALATION_CONTACT_NEAR_M:
			severity = GameEnums.EventSeverity.S2_ENGAGE
		elif target_class == GameEnums.TargetClass.ARMORED_HEAVY and \
			 distance_to_nearest <= GameConstants.ESCALATION_ARMOR_THREAT_M:
			severity = GameEnums.EventSeverity.S2_ENGAGE
		else:
			severity = GameEnums.EventSeverity.S1_ALERT
	else:
		type = GameEnums.CombatEventType.EV_CONTACT_SUS_ACQUIRED
		severity = GameEnums.EventSeverity.S1_ALERT

	var tags := {
		"target_class": target_class,
		"distance": distance_to_nearest,
	}

	var subject_ids: Array[String] = []
	return emit_event(type, severity, team, current_tick, contact_pos, target_id, subject_ids, tags)


## CP争奪イベントを生成
func emit_cp_contested_event(
	is_enter: bool,
	team: GameEnums.Faction,
	current_tick: int,
	cp_pos: Vector2,
	cp_id: String
) -> CombatEvent:
	var type: GameEnums.CombatEventType
	var severity: GameEnums.EventSeverity

	if is_enter:
		type = GameEnums.CombatEventType.EV_CP_CONTESTED_ENTER
		severity = GameEnums.EventSeverity.S2_ENGAGE
	else:
		type = GameEnums.CombatEventType.EV_CP_CONTESTED_EXIT
		severity = GameEnums.EventSeverity.S0_INFO

	var tags := {"cp_id": cp_id}
	var subject_ids: Array[String] = []
	return emit_event(type, severity, team, current_tick, cp_pos, "", subject_ids, tags)


## 戦闘状態変化イベントを生成
func emit_combat_state_changed(
	team: GameEnums.Faction,
	current_tick: int,
	element_id: String,
	old_state: GameEnums.CombatState,
	new_state: GameEnums.CombatState
) -> CombatEvent:
	var type := GameEnums.CombatEventType.EV_COMBAT_STATE_CHANGED
	var severity: GameEnums.EventSeverity

	# 新状態に基づいて重要度を決定
	match new_state:
		GameEnums.CombatState.ENGAGED:
			severity = GameEnums.EventSeverity.S2_ENGAGE
		GameEnums.CombatState.ALERT:
			severity = GameEnums.EventSeverity.S1_ALERT
		_:
			severity = GameEnums.EventSeverity.S0_INFO

	var tags := {
		"old_state": old_state,
		"new_state": new_state,
	}
	var subject_ids: Array[String] = [element_id]
	return emit_event(type, severity, team, current_tick, Vector2.ZERO, "", subject_ids, tags)

# =============================================================================
# クールダウン管理
# =============================================================================

func _get_cooldown_key(type: GameEnums.CombatEventType, source_id: String, subject_ids: Array[String]) -> String:
	var key := str(type)
	if not source_id.is_empty():
		key += "_" + source_id
	elif subject_ids.size() > 0:
		key += "_" + subject_ids[0]
	return key


func _is_on_cooldown(key: String, current_tick: int, type: GameEnums.CombatEventType) -> bool:
	if key not in _cooldowns:
		return false

	var last_tick: int = _cooldowns[key]
	var cooldown_ticks: int

	match type:
		GameEnums.CombatEventType.EV_CONTACT_SUS_ACQUIRED, \
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED, \
		GameEnums.CombatEventType.EV_CONTACT_TYPE_REFINED:
			cooldown_ticks = GameConstants.CONTACT_COOLDOWN_TICKS
		GameEnums.CombatEventType.EV_UNDER_FIRE, \
		GameEnums.CombatEventType.EV_NEAR_MISS, \
		GameEnums.CombatEventType.EV_EXPLOSION_NEAR:
			cooldown_ticks = GameConstants.FIRE_COOLDOWN_TICKS
		GameEnums.CombatEventType.EV_CASUALTY_TAKEN:
			return false  # 損耗は常に通す
		_:
			cooldown_ticks = 0

	return current_tick - last_tick < cooldown_ticks


func _set_cooldown(key: String, current_tick: int) -> void:
	_cooldowns[key] = current_tick

# =============================================================================
# クエリ
# =============================================================================

## 指定tick以降のイベントを取得
func get_events_since(since_tick: int) -> Array[CombatEvent]:
	var result: Array[CombatEvent] = []
	for event in _event_history:
		if event.tick >= since_tick:
			result.append(event)
	return result


## 指定範囲内の最近のイベントを取得
func get_events_near(pos: Vector2, radius: float, since_tick: int) -> Array[CombatEvent]:
	var result: Array[CombatEvent] = []
	var radius_sq := radius * radius

	for event in _event_history:
		if event.tick >= since_tick:
			if event.pos_m.distance_squared_to(pos) <= radius_sq:
				result.append(event)

	return result


## 指定陣営の最近の脅威イベントを取得
func get_threat_events_for_team(team: GameEnums.Faction, since_tick: int) -> Array[CombatEvent]:
	var result: Array[CombatEvent] = []
	for event in _event_history:
		if event.tick >= since_tick and event.team == team:
			if event.severity >= GameEnums.EventSeverity.S1_ALERT:
				result.append(event)
	return result


## クリア
func clear() -> void:
	_event_history.clear()
	_cooldowns.clear()
	_next_event_id = 1
