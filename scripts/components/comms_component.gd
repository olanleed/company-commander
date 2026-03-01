class_name CommsComponent
extends RefCounted

## CommsComponent - 通信状態・データリンクの管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 通信状態（CommState）の管理
## - 接続先ハブIDの管理
## - 通信状態変更時のシグナル発火

# =============================================================================
# シグナル
# =============================================================================

signal comm_state_changed(element_id: String, old_state: GameEnums.CommState, new_state: GameEnums.CommState)
signal hub_changed(element_id: String, old_hub_id: String, new_hub_id: String)
signal link_established(element_id: String, hub_id: String)
signal link_lost(element_id: String)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## 通信状態
var _comm_state: GameEnums.CommState = GameEnums.CommState.LINKED
var _comm_hub_id: String = ""

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var comm_state: GameEnums.CommState:
	get: return _comm_state

var comm_hub_id: String:
	get: return _comm_hub_id

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String) -> void:
	_element_id = element_id


# =============================================================================
# 通信状態管理
# =============================================================================

## 通信状態を設定
## @param state: 新しい通信状態
func set_comm_state(state: GameEnums.CommState) -> void:
	if _comm_state == state:
		return
	var old_state = _comm_state
	_comm_state = state
	comm_state_changed.emit(_element_id, old_state, state)

	# 特定の状態遷移でシグナルを発火
	if state == GameEnums.CommState.ISOLATED and old_state != GameEnums.CommState.ISOLATED:
		link_lost.emit(_element_id)


## 接続先ハブIDを設定
## @param hub_id: ハブID
func set_hub_id(hub_id: String) -> void:
	if _comm_hub_id == hub_id:
		return
	var old_hub_id = _comm_hub_id
	_comm_hub_id = hub_id
	hub_changed.emit(_element_id, old_hub_id, hub_id)

	# ハブ設定時にリンク確立シグナル
	if hub_id != "" and old_hub_id == "":
		link_established.emit(_element_id, hub_id)


## データリンクを確立
## @param hub_id: 接続先ハブID
func establish_link(hub_id: String) -> void:
	set_hub_id(hub_id)
	set_comm_state(GameEnums.CommState.LINKED)


## データリンクを劣化状態に変更
func degrade_link() -> void:
	set_comm_state(GameEnums.CommState.DEGRADED)


## データリンクを切断（孤立状態）
func isolate() -> void:
	set_comm_state(GameEnums.CommState.ISOLATED)


## データリンクをクリア
func clear_link() -> void:
	set_hub_id("")
	set_comm_state(GameEnums.CommState.ISOLATED)


## 接続中かどうか
func is_linked() -> bool:
	return _comm_state == GameEnums.CommState.LINKED


## 劣化状態かどうか
func is_degraded() -> bool:
	return _comm_state == GameEnums.CommState.DEGRADED


## 孤立状態かどうか
func is_isolated() -> bool:
	return _comm_state == GameEnums.CommState.ISOLATED


## ハブに接続しているか
func has_hub() -> bool:
	return _comm_hub_id != ""


## 情報共有可能かどうか（LINKED または DEGRADED）
func can_share_info() -> bool:
	return _comm_state != GameEnums.CommState.ISOLATED


## 通信状態をリセット
func reset() -> void:
	_comm_state = GameEnums.CommState.LINKED
	_comm_hub_id = ""


# =============================================================================
# 直接設定（後方互換用）
# =============================================================================

## comm_stateを直接設定（シグナルなし）
func set_comm_state_raw(state: GameEnums.CommState) -> void:
	_comm_state = state


## comm_hub_idを直接設定（シグナルなし）
func set_hub_id_raw(hub_id: String) -> void:
	_comm_hub_id = hub_id
