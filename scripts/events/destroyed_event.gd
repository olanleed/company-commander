class_name DestroyedEvent
extends RefCounted

## DestroyedEvent - ユニット破壊イベント
## フェーズ2: イベント駆動への移行
##
## 責務:
## - 破壊イベントのデータ保持
## - シリアライズ/デシリアライズ

# =============================================================================
# プロパティ
# =============================================================================

var tick: int = 0
var element_id: String = ""
var killer_id: String = ""
var weapon_id: String = ""
var catastrophic: bool = false
var position: Vector2 = Vector2.ZERO


# =============================================================================
# シリアライズ
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"element_id": element_id,
		"killer_id": killer_id,
		"weapon_id": weapon_id,
		"catastrophic": catastrophic,
		"position": {"x": position.x, "y": position.y}
	}


static func from_dict(dict: Dictionary):
	var DestroyedEventClass = load("res://scripts/events/destroyed_event.gd")
	var event = DestroyedEventClass.new()
	event.tick = dict.get("tick", 0)
	event.element_id = dict.get("element_id", "")
	event.killer_id = dict.get("killer_id", "")
	event.weapon_id = dict.get("weapon_id", "")
	event.catastrophic = dict.get("catastrophic", false)
	var pos = dict.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.get("x", 0), pos.get("y", 0))
	return event
