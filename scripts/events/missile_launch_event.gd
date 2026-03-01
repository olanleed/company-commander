class_name MissileLaunchEvent
extends RefCounted

## MissileLaunchEvent - ミサイル発射イベント
## フェーズ2: イベント駆動への移行
##
## 責務:
## - ミサイル発射イベントのデータ保持
## - シリアライズ/デシリアライズ

# =============================================================================
# プロパティ
# =============================================================================

var tick: int = 0
var missile_id: String = ""
var shooter_id: String = ""
var target_id: String = ""
var weapon_id: String = ""
var launch_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var guidance_type: String = ""  # "SACLOS", "TOP_ATTACK", "FIRE_AND_FORGET"


# =============================================================================
# シリアライズ
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"missile_id": missile_id,
		"shooter_id": shooter_id,
		"target_id": target_id,
		"weapon_id": weapon_id,
		"launch_position": {"x": launch_position.x, "y": launch_position.y},
		"target_position": {"x": target_position.x, "y": target_position.y},
		"guidance_type": guidance_type
	}


static func from_dict(dict: Dictionary):
	var MissileLaunchEventClass = load("res://scripts/events/missile_launch_event.gd")
	var event = MissileLaunchEventClass.new()
	event.tick = dict.get("tick", 0)
	event.missile_id = dict.get("missile_id", "")
	event.shooter_id = dict.get("shooter_id", "")
	event.target_id = dict.get("target_id", "")
	event.weapon_id = dict.get("weapon_id", "")
	var lpos = dict.get("launch_position", {"x": 0, "y": 0})
	event.launch_position = Vector2(lpos.get("x", 0), lpos.get("y", 0))
	var tpos = dict.get("target_position", {"x": 0, "y": 0})
	event.target_position = Vector2(tpos.get("x", 0), tpos.get("y", 0))
	event.guidance_type = dict.get("guidance_type", "")
	return event
