class_name WeaponComponent
extends RefCounted

## WeaponComponent - 武器・射撃状態の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 武器リストの管理
## - 現在武器・射撃目標の管理
## - 強制交戦目標の管理
## - 射撃間隔（last_fire_tick）の管理
## - SOPモードの管理

# =============================================================================
# シグナル
# =============================================================================

signal weapon_changed(element_id: String, old_weapon_id: String, new_weapon_id: String)
signal target_changed(element_id: String, old_target_id: String, new_target_id: String)
signal forced_target_set(element_id: String, target_id: String)
signal forced_target_cleared(element_id: String)
signal sop_mode_changed(element_id: String, old_mode: GameEnums.SOPMode, new_mode: GameEnums.SOPMode)
signal weapon_fired(element_id: String, weapon_id: String, target_id: String)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## 武器リスト
var _weapons: Array = []  # Array[WeaponData.WeaponType]
var _primary_weapon = null  # WeaponData.WeaponType
var _current_weapon = null  # WeaponData.WeaponType

## 射撃目標
var _current_target_id: String = ""
var _forced_target_id: String = ""
var _atgm_guided_target_id: String = ""

## 射撃タイミング
var _last_fire_tick: int = -1
var _last_hit_tick: int = 0

## 射撃ルール
var _sop_mode: GameEnums.SOPMode = GameEnums.SOPMode.FIRE_AT_WILL

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var weapons: Array:
	get: return _weapons

var primary_weapon:
	get: return _primary_weapon

var current_weapon:
	get: return _current_weapon

var current_target_id: String:
	get: return _current_target_id

var forced_target_id: String:
	get: return _forced_target_id

var atgm_guided_target_id: String:
	get: return _atgm_guided_target_id

var last_fire_tick: int:
	get: return _last_fire_tick

var last_hit_tick: int:
	get: return _last_hit_tick

var sop_mode: GameEnums.SOPMode:
	get: return _sop_mode

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String) -> void:
	_element_id = element_id
	_weapons = []


# =============================================================================
# 武器管理
# =============================================================================

## 武器を追加
## @param weapon: 追加する武器
func add_weapon(weapon) -> void:
	_weapons.append(weapon)
	# 最初に追加した武器をprimary/currentに設定
	if _weapons.size() == 1:
		_primary_weapon = weapon
		_current_weapon = weapon


## 武器リストをクリア
func clear_weapons() -> void:
	_weapons.clear()
	_primary_weapon = null
	_current_weapon = null


## 主武装を設定
## @param weapon: 主武装
func set_primary_weapon(weapon) -> void:
	_primary_weapon = weapon
	if _current_weapon == null:
		_current_weapon = weapon


## 現在の武器を切り替え
## @param weapon: 新しい武器
func set_current_weapon(weapon) -> void:
	if weapon == _current_weapon:
		return
	var old_id = _current_weapon.id if _current_weapon else ""
	var new_id = weapon.id if weapon else ""
	_current_weapon = weapon
	weapon_changed.emit(_element_id, old_id, new_id)


## インデックスで武器を取得
## @param index: 武器インデックス
## @return: 武器（なければnull）
func get_weapon_at(index: int):
	if index >= 0 and index < _weapons.size():
		return _weapons[index]
	return null


## 武器数を取得
func get_weapon_count() -> int:
	return _weapons.size()


## 武器IDで武器を検索
## @param weapon_id: 武器ID
## @return: 武器（見つからなければnull）
func find_weapon_by_id(weapon_id: String):
	for weapon in _weapons:
		if weapon.id == weapon_id:
			return weapon
	return null


# =============================================================================
# 射撃目標管理
# =============================================================================

## 射撃目標を設定
## @param target_id: 目標ID
func set_current_target(target_id: String) -> void:
	if _current_target_id == target_id:
		return
	var old_id = _current_target_id
	_current_target_id = target_id
	target_changed.emit(_element_id, old_id, target_id)


## 射撃目標をクリア
func clear_current_target() -> void:
	set_current_target("")


## 強制交戦目標を設定
## @param target_id: 目標ID
func set_forced_target(target_id: String) -> void:
	_forced_target_id = target_id
	if target_id != "":
		forced_target_set.emit(_element_id, target_id)
	else:
		forced_target_cleared.emit(_element_id)


## 強制交戦目標をクリア
func clear_forced_target() -> void:
	set_forced_target("")


## 強制交戦目標があるか
func has_forced_target() -> bool:
	return _forced_target_id != ""


## ATGM誘導目標を設定
## @param target_id: 目標ID
func set_atgm_guided_target(target_id: String) -> void:
	_atgm_guided_target_id = target_id


## ATGM誘導目標をクリア
func clear_atgm_guided_target() -> void:
	_atgm_guided_target_id = ""


# =============================================================================
# 射撃タイミング
# =============================================================================

## 射撃を記録
## @param tick: 現在のtick
func record_fire(tick: int) -> void:
	_last_fire_tick = tick
	var weapon_id = _current_weapon.id if _current_weapon else ""
	weapon_fired.emit(_element_id, weapon_id, _current_target_id)


## 被弾を記録
## @param tick: 現在のtick
func record_hit(tick: int) -> void:
	_last_hit_tick = tick


## 射撃間隔を確認（クールダウン済みか）
## @param current_tick: 現在のtick
## @param cooldown_ticks: クールダウンtick数
## @return: 射撃可能か
func can_fire(current_tick: int, cooldown_ticks: int) -> bool:
	if _last_fire_tick < 0:
		return true
	return (current_tick - _last_fire_tick) >= cooldown_ticks


## 最後の被弾からの経過tick
## @param current_tick: 現在のtick
## @return: 経過tick
func ticks_since_last_hit(current_tick: int) -> int:
	return current_tick - _last_hit_tick


# =============================================================================
# SOPモード
# =============================================================================

## SOPモードを設定
## @param mode: 新しいSOPモード
func set_sop_mode(mode: GameEnums.SOPMode) -> void:
	if _sop_mode == mode:
		return
	var old_mode = _sop_mode
	_sop_mode = mode
	sop_mode_changed.emit(_element_id, old_mode, mode)


## 射撃許可があるか（SOPモードに基づく）
## @param has_forced_target: 強制目標があるか
## @param was_recently_hit: 最近被弾したか
## @return: 射撃許可があるか
func is_fire_allowed(has_forced_target_flag: bool = false, was_recently_hit: bool = false) -> bool:
	match _sop_mode:
		GameEnums.SOPMode.FIRE_AT_WILL:
			return true
		GameEnums.SOPMode.RETURN_FIRE:
			return was_recently_hit or has_forced_target_flag
		GameEnums.SOPMode.HOLD_FIRE:
			return has_forced_target_flag
		_:
			return true


# =============================================================================
# 直接設定（後方互換用）
# =============================================================================

## last_fire_tickを直接設定
func set_last_fire_tick(tick: int) -> void:
	_last_fire_tick = tick


## last_hit_tickを直接設定
func set_last_hit_tick(tick: int) -> void:
	_last_hit_tick = tick


## 武器リストを直接設定
func set_weapons(weapon_list: Array) -> void:
	_weapons = weapon_list
	if _weapons.size() > 0 and _primary_weapon == null:
		_primary_weapon = _weapons[0]
		_current_weapon = _weapons[0]
