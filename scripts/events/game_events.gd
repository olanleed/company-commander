class_name GameEvents
extends RefCounted

## GameEvents - ゲームイベントバス
## フェーズ2: イベント駆動への移行
##
## 責務:
## - イベントシグナルの集約
## - イベントログの管理
## - Tick管理

# =============================================================================
# シグナル - ダメージ・破壊
# =============================================================================

signal damage_applied(event)
signal suppression_applied(event)
signal unit_destroyed(event)

# =============================================================================
# シグナル - 移動
# =============================================================================

signal movement_started(element_id, destination)
signal movement_completed(element_id)
signal waypoint_reached(element_id, waypoint)

# =============================================================================
# シグナル - 接触
# =============================================================================

signal contact_established(observer_id, target_id, state)
signal contact_lost(observer_id, target_id)
signal contact_updated(observer_id, target_id, old_state, new_state)

# =============================================================================
# シグナル - 弾薬
# =============================================================================

signal ammunition_consumed(element_id, weapon_id, count)
signal ammo_depleted(element_id, weapon_id)
signal reload_started(element_id, weapon_id)
signal reload_completed(element_id, weapon_id)

# =============================================================================
# シグナル - ミサイル
# =============================================================================

signal missile_launched(event)
signal missile_hit(missile_id, target_id)
signal missile_missed(missile_id, reason)

# =============================================================================
# シグナル - 補給
# =============================================================================

signal resupply_received(element_id, supplier_id, amount)
signal resupply_completed(element_id)

# =============================================================================
# シグナル - 命令
# =============================================================================

signal order_issued(event)

# =============================================================================
# 内部状態
# =============================================================================

var _current_tick: int = 0
var _event_log: Array = []
var _max_log_size: int = 1000


# =============================================================================
# プロパティ
# =============================================================================

var current_tick: int:
	get: return _current_tick


# =============================================================================
# Tick管理
# =============================================================================

func set_tick(tick: int) -> void:
	_current_tick = tick


# =============================================================================
# ログ管理
# =============================================================================

func set_max_log_size(size: int) -> void:
	_max_log_size = size
	_trim_log()


func log_event(event_type: String, data: Dictionary) -> void:
	var entry = {
		"tick": _current_tick,
		"type": event_type,
		"data": data
	}
	_event_log.append(entry)
	_trim_log()


func _trim_log() -> void:
	while _event_log.size() > _max_log_size:
		_event_log.pop_front()


func get_recent_events(count: int) -> Array:
	var start = maxi(0, _event_log.size() - count)
	return _event_log.slice(start)


func get_events_for_element(element_id: String, count: int) -> Array:
	var result = []
	for i in range(_event_log.size() - 1, -1, -1):
		var entry = _event_log[i]
		var data = entry.data
		# element_id, target_id, shooter_id のいずれかにマッチ
		if data.get("element_id") == element_id or \
		   data.get("target_id") == element_id or \
		   data.get("shooter_id") == element_id:
			result.insert(0, entry)
			if result.size() >= count:
				break
	return result


func clear_log() -> void:
	_event_log.clear()


# =============================================================================
# イベント発火メソッド
# =============================================================================

func emit_damage_applied(event) -> void:
	event.tick = _current_tick
	log_event("DAMAGE", event.to_dict())
	damage_applied.emit(event)


func emit_suppression_applied(event) -> void:
	event.tick = _current_tick
	log_event("SUPPRESSION", event.to_dict())
	suppression_applied.emit(event)


func emit_unit_destroyed(event) -> void:
	event.tick = _current_tick
	log_event("DESTROYED", event.to_dict())
	unit_destroyed.emit(event)


func emit_movement_started(element_id: String, destination: Vector2) -> void:
	log_event("MOVEMENT_STARTED", {"element_id": element_id, "destination": {"x": destination.x, "y": destination.y}})
	movement_started.emit(element_id, destination)


func emit_movement_completed(element_id: String) -> void:
	log_event("MOVEMENT_COMPLETED", {"element_id": element_id})
	movement_completed.emit(element_id)


func emit_waypoint_reached(element_id: String, waypoint: Vector2) -> void:
	log_event("WAYPOINT_REACHED", {"element_id": element_id, "waypoint": {"x": waypoint.x, "y": waypoint.y}})
	waypoint_reached.emit(element_id, waypoint)


func emit_contact_established(observer_id: String, target_id: String, state: GameEnums.ContactState) -> void:
	log_event("CONTACT_ESTABLISHED", {"observer_id": observer_id, "target_id": target_id, "state": state})
	contact_established.emit(observer_id, target_id, state)


func emit_contact_lost(observer_id: String, target_id: String) -> void:
	log_event("CONTACT_LOST", {"observer_id": observer_id, "target_id": target_id})
	contact_lost.emit(observer_id, target_id)


func emit_contact_updated(observer_id: String, target_id: String, old_state: GameEnums.ContactState, new_state: GameEnums.ContactState) -> void:
	log_event("CONTACT_UPDATED", {"observer_id": observer_id, "target_id": target_id, "old_state": old_state, "new_state": new_state})
	contact_updated.emit(observer_id, target_id, old_state, new_state)


func emit_ammunition_consumed(element_id: String, weapon_id: String, count: int) -> void:
	log_event("AMMO_CONSUMED", {"element_id": element_id, "weapon_id": weapon_id, "count": count})
	ammunition_consumed.emit(element_id, weapon_id, count)


func emit_ammo_depleted(element_id: String, weapon_id: String) -> void:
	log_event("AMMO_DEPLETED", {"element_id": element_id, "weapon_id": weapon_id})
	ammo_depleted.emit(element_id, weapon_id)


func emit_reload_started(element_id: String, weapon_id: String) -> void:
	log_event("RELOAD_STARTED", {"element_id": element_id, "weapon_id": weapon_id})
	reload_started.emit(element_id, weapon_id)


func emit_reload_completed(element_id: String, weapon_id: String) -> void:
	log_event("RELOAD_COMPLETED", {"element_id": element_id, "weapon_id": weapon_id})
	reload_completed.emit(element_id, weapon_id)


func emit_missile_launched(event) -> void:
	event.tick = _current_tick
	log_event("MISSILE_LAUNCHED", event.to_dict())
	missile_launched.emit(event)


func emit_missile_hit(missile_id: String, target_id: String) -> void:
	log_event("MISSILE_HIT", {"missile_id": missile_id, "target_id": target_id})
	missile_hit.emit(missile_id, target_id)


func emit_missile_missed(missile_id: String, reason: String) -> void:
	log_event("MISSILE_MISSED", {"missile_id": missile_id, "reason": reason})
	missile_missed.emit(missile_id, reason)


func emit_resupply_received(element_id: String, supplier_id: String, amount: int) -> void:
	log_event("RESUPPLY_RECEIVED", {"element_id": element_id, "supplier_id": supplier_id, "amount": amount})
	resupply_received.emit(element_id, supplier_id, amount)


func emit_resupply_completed(element_id: String) -> void:
	log_event("RESUPPLY_COMPLETED", {"element_id": element_id})
	resupply_completed.emit(element_id)


func emit_order_issued(event) -> void:
	event.tick = _current_tick
	log_event("ORDER", event.to_dict())
	order_issued.emit(event)
