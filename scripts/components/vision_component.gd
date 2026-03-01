class_name VisionComponent
extends RefCounted

## VisionComponent - 視認状態・接触記録の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 他陣営から見た視認状態（ContactState）の管理
## - 最終目視tick・最終既知位置の管理
## - 視認状態変更時のシグナル発火

# =============================================================================
# シグナル
# =============================================================================

signal contact_state_changed(element_id: String, old_state: GameEnums.ContactState, new_state: GameEnums.ContactState)
signal position_updated(element_id: String, position: Vector2)
signal contact_lost(element_id: String)
signal contact_confirmed(element_id: String, position: Vector2)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## 視認状態（他陣営から見た状態）
var _contact_state: GameEnums.ContactState = GameEnums.ContactState.UNKNOWN
var _last_seen_tick: int = -1
var _last_known_position: Vector2 = Vector2.ZERO

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var contact_state: GameEnums.ContactState:
	get: return _contact_state

var last_seen_tick: int:
	get: return _last_seen_tick

var last_known_position: Vector2:
	get: return _last_known_position

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String) -> void:
	_element_id = element_id


# =============================================================================
# 視認状態管理
# =============================================================================

## 視認状態を設定
## @param state: 新しい視認状態
func set_contact_state(state: GameEnums.ContactState) -> void:
	if _contact_state == state:
		return
	var old_state = _contact_state
	_contact_state = state
	contact_state_changed.emit(_element_id, old_state, state)

	# 特定の状態遷移でシグナルを発火
	if state == GameEnums.ContactState.UNKNOWN and old_state != GameEnums.ContactState.UNKNOWN:
		contact_lost.emit(_element_id)
	elif state == GameEnums.ContactState.CONFIRMED and old_state != GameEnums.ContactState.CONFIRMED:
		contact_confirmed.emit(_element_id, _last_known_position)


## 接触確認（視認した時に呼び出し）
## @param tick: 現在のtick
## @param position: 確認した位置
func confirm_contact(tick: int, position: Vector2) -> void:
	_last_seen_tick = tick
	_last_known_position = position
	position_updated.emit(_element_id, position)
	set_contact_state(GameEnums.ContactState.CONFIRMED)


## 接触を疑わしい状態に変更
## @param tick: 現在のtick
func set_suspected(tick: int) -> void:
	set_contact_state(GameEnums.ContactState.SUSPECTED)


## 接触を不明状態に変更（ロスト）
func set_unknown() -> void:
	set_contact_state(GameEnums.ContactState.UNKNOWN)


## 接触を古い状態に変更（一定時間視認できなかった）
func set_stale() -> void:
	# STALE状態がない場合はSUSPECTEDを使用
	set_contact_state(GameEnums.ContactState.SUSPECTED)


## 最終既知位置を更新
## @param position: 新しい位置
func update_last_known_position(position: Vector2) -> void:
	_last_known_position = position
	position_updated.emit(_element_id, position)


## 確認済みかどうか
func is_confirmed() -> bool:
	return _contact_state == GameEnums.ContactState.CONFIRMED


## 不明かどうか
func is_unknown() -> bool:
	return _contact_state == GameEnums.ContactState.UNKNOWN


## 最後に目視してからの経過tick
## @param current_tick: 現在のtick
## @return: 経過tick（一度も目視していなければ-1）
func ticks_since_last_seen(current_tick: int) -> int:
	if _last_seen_tick < 0:
		return -1
	return current_tick - _last_seen_tick


## 視認情報をリセット
func reset() -> void:
	_contact_state = GameEnums.ContactState.UNKNOWN
	_last_seen_tick = -1
	_last_known_position = Vector2.ZERO


# =============================================================================
# 直接設定（後方互換用）
# =============================================================================

## last_seen_tickを直接設定
func set_last_seen_tick(tick: int) -> void:
	_last_seen_tick = tick


## last_known_positionを直接設定
func set_last_known_position(position: Vector2) -> void:
	_last_known_position = position


## contact_stateを直接設定（シグナルなし）
func set_contact_state_raw(state: GameEnums.ContactState) -> void:
	_contact_state = state
