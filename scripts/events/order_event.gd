class_name OrderEvent
extends RefCounted

## OrderEvent - 命令発行イベント
## フェーズ2: イベント駆動への移行
##
## 責務:
## - 命令イベントのデータ保持
## - シリアライズ/デシリアライズ

# =============================================================================
# プロパティ
# =============================================================================

var tick: int = 0
var element_id: String = ""
var order_type: GameEnums.OrderType = GameEnums.OrderType.HOLD
var target_position: Vector2 = Vector2.ZERO
var target_id: String = ""


# =============================================================================
# シリアライズ
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"element_id": element_id,
		"order_type": order_type,
		"target_position": {"x": target_position.x, "y": target_position.y},
		"target_id": target_id
	}


static func from_dict(dict: Dictionary):
	var OrderEventClass = load("res://scripts/events/order_event.gd")
	var event = OrderEventClass.new()
	event.tick = dict.get("tick", 0)
	event.element_id = dict.get("element_id", "")
	event.order_type = dict.get("order_type", GameEnums.OrderType.HOLD)
	var pos = dict.get("target_position", {"x": 0, "y": 0})
	event.target_position = Vector2(pos.get("x", 0), pos.get("y", 0))
	event.target_id = dict.get("target_id", "")
	return event
