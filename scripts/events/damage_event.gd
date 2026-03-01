class_name DamageEvent
extends RefCounted

## DamageEvent - ダメージ適用イベント
## フェーズ2: イベント駆動への移行
##
## 責務:
## - ダメージイベントのデータ保持
## - シリアライズ/デシリアライズ

# =============================================================================
# プロパティ
# =============================================================================

var tick: int = 0
var target_id: String = ""
var shooter_id: String = ""
var weapon_id: String = ""
var damage: int = 0
var penetration_result: String = ""  # "FULL_PEN", "PARTIAL_PEN", "NO_PEN"
var hit_zone: String = ""  # "FRONT", "SIDE", "REAR", "TOP"
var armor_damage: float = 0.0
var subsystem_hit: String = ""  # "MOBILITY", "FIREPOWER", "SENSORS", ""


# =============================================================================
# シリアライズ
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"target_id": target_id,
		"shooter_id": shooter_id,
		"weapon_id": weapon_id,
		"damage": damage,
		"penetration_result": penetration_result,
		"hit_zone": hit_zone,
		"armor_damage": armor_damage,
		"subsystem_hit": subsystem_hit
	}


static func from_dict(dict: Dictionary):
	var DamageEventClass = load("res://scripts/events/damage_event.gd")
	var event = DamageEventClass.new()
	event.tick = dict.get("tick", 0)
	event.target_id = dict.get("target_id", "")
	event.shooter_id = dict.get("shooter_id", "")
	event.weapon_id = dict.get("weapon_id", "")
	event.damage = dict.get("damage", 0)
	event.penetration_result = dict.get("penetration_result", "")
	event.hit_zone = dict.get("hit_zone", "")
	event.armor_damage = dict.get("armor_damage", 0.0)
	event.subsystem_hit = dict.get("subsystem_hit", "")
	return event
