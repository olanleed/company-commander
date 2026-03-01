class_name CombatComponent
extends RefCounted

## CombatComponent - 戦闘状態の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 戦力（Strength）の管理
## - 抑圧（Suppression）の管理
## - ダメージ蓄積の管理
## - サブシステムHP（装甲車両用）の管理
## - 破壊判定とシグナル発火

# =============================================================================
# 定数
# =============================================================================

## 抑圧状態閾値
const SUPPRESSION_THRESHOLD_SUPPRESSED := 0.3
const SUPPRESSION_THRESHOLD_PINNED := 0.7
const SUPPRESSION_THRESHOLD_BROKEN := 0.95

## シグナル発火の最小変化量
const SUPPRESSION_SIGNAL_THRESHOLD := 0.01

# =============================================================================
# シグナル
# =============================================================================

signal strength_changed(element_id: String, old_value: int, new_value: int)
signal suppression_changed(element_id: String, old_value: float, new_value: float)
signal unit_destroyed(element_id: String, catastrophic: bool)
signal damage_accumulated(element_id: String, damage: float, total: float)
signal subsystem_damaged(element_id: String, subsystem: String, old_value: int, new_value: int)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String
var _max_strength: int = 100
var _current_strength: int = 100
var _suppression: float = 0.0
var _accumulated_damage: float = 0.0
var _accumulated_armor_damage: float = 0.0
var _is_destroyed: bool = false
var _catastrophic_kill: bool = false
var _destroy_tick: int = -1

## v0.1R: 車両サブシステムHP（armor_class >= 1 の場合のみ使用）
var _mobility_hp: int = 100
var _firepower_hp: int = 100
var _sensors_hp: int = 100

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var current_strength: int:
	get: return _current_strength

var max_strength: int:
	get: return _max_strength

var suppression: float:
	get: return _suppression

var is_destroyed: bool:
	get: return _is_destroyed

var catastrophic_kill: bool:
	get: return _catastrophic_kill

var destroy_tick: int:
	get: return _destroy_tick

var accumulated_damage: float:
	get: return _accumulated_damage

var accumulated_armor_damage: float:
	get: return _accumulated_armor_damage

var mobility_hp: int:
	get: return _mobility_hp

var firepower_hp: int:
	get: return _firepower_hp

var sensors_hp: int:
	get: return _sensors_hp

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String, max_str: int) -> void:
	_element_id = element_id
	_max_strength = max_str
	_current_strength = max_str


# =============================================================================
# ダメージ適用
# =============================================================================

## ダメージ適用
## @param damage: ダメージ量
## @param is_catastrophic: 爆発・炎上による破壊か
func apply_damage(damage: int, is_catastrophic: bool = false) -> void:
	if damage <= 0:
		return

	var old = _current_strength
	_current_strength = maxi(0, _current_strength - damage)

	if old != _current_strength:
		strength_changed.emit(_element_id, old, _current_strength)

	if _current_strength <= 0 and not _is_destroyed:
		_is_destroyed = true
		_catastrophic_kill = is_catastrophic
		unit_destroyed.emit(_element_id, is_catastrophic)


## 浮動小数点ダメージを蓄積し、整数ダメージを適用
## @param damage: 蓄積するダメージ（浮動小数点）
## @return: 実際に適用されたダメージ量
func accumulate_damage(damage: float) -> int:
	_accumulated_damage += damage
	damage_accumulated.emit(_element_id, damage, _accumulated_damage)

	var applied := 0
	while _accumulated_damage >= 1.0:
		_accumulated_damage -= 1.0
		applied += 1

	if applied > 0:
		apply_damage(applied)

	return applied


## 装甲ダメージを蓄積
## @param damage: 蓄積するダメージ
func accumulate_armor_damage(damage: float) -> void:
	_accumulated_armor_damage += damage


## 装甲ダメージ蓄積をリセット
func reset_armor_damage() -> void:
	_accumulated_armor_damage = 0.0


# =============================================================================
# 抑圧管理
# =============================================================================

## 抑圧適用
## @param delta: 抑圧変化量（正=増加、負=回復）
func apply_suppression(delta: float) -> void:
	var old = _suppression
	_suppression = clampf(_suppression + delta, 0.0, 1.0)

	if absf(old - _suppression) > SUPPRESSION_SIGNAL_THRESHOLD:
		suppression_changed.emit(_element_id, old, _suppression)


## 抑圧回復（毎tick呼び出し）
## @param rate: 回復速度
func recover_suppression(rate: float) -> void:
	if _suppression > 0:
		apply_suppression(-rate)


## 現在の抑圧状態を取得
func get_suppression_state() -> GameEnums.SuppressionState:
	if _suppression >= SUPPRESSION_THRESHOLD_BROKEN:
		return GameEnums.SuppressionState.BROKEN
	elif _suppression >= SUPPRESSION_THRESHOLD_PINNED:
		return GameEnums.SuppressionState.PINNED
	elif _suppression >= SUPPRESSION_THRESHOLD_SUPPRESSED:
		return GameEnums.SuppressionState.SUPPRESSED
	else:
		return GameEnums.SuppressionState.ACTIVE


# =============================================================================
# サブシステムダメージ（装甲車両用）
# =============================================================================

## サブシステムにダメージを適用
## @param subsystem: "MOBILITY", "FIREPOWER", "SENSORS"
## @param damage: ダメージ量
func apply_subsystem_damage(subsystem: String, damage: int) -> void:
	var old: int
	var new_val: int

	match subsystem:
		"MOBILITY":
			old = _mobility_hp
			_mobility_hp = maxi(0, _mobility_hp - damage)
			new_val = _mobility_hp
		"FIREPOWER":
			old = _firepower_hp
			_firepower_hp = maxi(0, _firepower_hp - damage)
			new_val = _firepower_hp
		"SENSORS":
			old = _sensors_hp
			_sensors_hp = maxi(0, _sensors_hp - damage)
			new_val = _sensors_hp
		_:
			return

	if old != new_val:
		subsystem_damaged.emit(_element_id, subsystem, old, new_val)


## Mobility Kill判定
func is_mobility_killed() -> bool:
	return _mobility_hp <= 0


## Firepower Kill判定
func is_firepower_killed() -> bool:
	return _firepower_hp <= 0


## Sensors Kill判定
func is_sensors_killed() -> bool:
	return _sensors_hp <= 0


# =============================================================================
# 破壊状態設定（外部から設定用）
# =============================================================================

## 破壊tickを設定
func set_destroy_tick(tick: int) -> void:
	_destroy_tick = tick


## 破壊状態を直接設定（後方互換用）
func set_destroyed(value: bool, is_catastrophic: bool = false) -> void:
	if _is_destroyed == value:
		return
	_is_destroyed = value
	if value:
		_catastrophic_kill = is_catastrophic
		unit_destroyed.emit(_element_id, is_catastrophic)


## catastrophic_killを直接設定（後方互換用）
func set_catastrophic_kill(value: bool) -> void:
	_catastrophic_kill = value


## 戦力を直接設定（後方互換用、外部からの設定）
func set_strength(value: int) -> void:
	var old = _current_strength
	_current_strength = clampi(value, 0, _max_strength)
	if old != _current_strength:
		strength_changed.emit(_element_id, old, _current_strength)


## 抑圧を直接設定（後方互換用、外部からの設定）
func set_suppression(value: float) -> void:
	var old = _suppression
	_suppression = clampf(value, 0.0, 1.0)
	if absf(old - _suppression) > SUPPRESSION_SIGNAL_THRESHOLD:
		suppression_changed.emit(_element_id, old, _suppression)
