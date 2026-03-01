class_name SuppressionEvent
extends RefCounted

## SuppressionEvent - 抑圧適用イベント
## フェーズ2: イベント駆動への移行
##
## 責務:
## - 抑圧イベントのデータ保持
## - シリアライズ/デシリアライズ

# =============================================================================
# プロパティ
# =============================================================================

var tick: int = 0
var element_id: String = ""
var old_value: float = 0.0
var new_value: float = 0.0
var delta: float = 0.0
var source_id: String = ""


# =============================================================================
# シリアライズ
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"element_id": element_id,
		"old_value": old_value,
		"new_value": new_value,
		"delta": delta,
		"source_id": source_id
	}


static func from_dict(dict: Dictionary):
	var SuppressionEventClass = load("res://scripts/events/suppression_event.gd")
	var event = SuppressionEventClass.new()
	event.tick = dict.get("tick", 0)
	event.element_id = dict.get("element_id", "")
	event.old_value = dict.get("old_value", 0.0)
	event.new_value = dict.get("new_value", 0.0)
	event.delta = dict.get("delta", 0.0)
	event.source_id = dict.get("source_id", "")
	return event
