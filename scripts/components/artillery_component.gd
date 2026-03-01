class_name ArtilleryComponent
extends RefCounted

## ArtilleryComponent - 砲兵展開状態の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 展開状態（STOWED/DEPLOYING/DEPLOYED/PACKING）の管理
## - 展開/撤収進捗の管理
## - 間接射撃任務目標の管理

# =============================================================================
# 定数（ElementInstanceの定義を参照）
# =============================================================================

enum DeployState {
	STOWED = 0,    ## 収納状態（移動可能、射撃不可）
	DEPLOYING = 1, ## 展開中（移動不可、射撃不可）
	DEPLOYED = 2,  ## 展開完了（移動不可、射撃可能）
	PACKING = 3,   ## 撤収中（移動不可、射撃不可）
}

# =============================================================================
# シグナル
# =============================================================================

signal deploy_state_changed(element_id: String, old_state: DeployState, new_state: DeployState)
signal deploy_progress_changed(element_id: String, progress: float)
signal deploy_completed(element_id: String)
signal pack_completed(element_id: String)
signal fire_mission_assigned(element_id: String, target: Vector2)
signal fire_mission_cleared(element_id: String)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## 展開状態
var _deploy_state: DeployState = DeployState.STOWED
var _deploy_progress: float = 0.0
var _deploy_time_sec: float = 30.0
var _pack_time_sec: float = 30.0

## 間接射撃任務
var _fire_mission_target: Vector2 = Vector2.ZERO
var _fire_mission_active: bool = false

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

var deploy_state: DeployState:
	get: return _deploy_state

var deploy_progress: float:
	get: return _deploy_progress

var deploy_time_sec: float:
	get: return _deploy_time_sec

var pack_time_sec: float:
	get: return _pack_time_sec

var fire_mission_target: Vector2:
	get: return _fire_mission_target

var fire_mission_active: bool:
	get: return _fire_mission_active

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String, p_deploy_time: float = 30.0, p_pack_time: float = 30.0) -> void:
	_element_id = element_id
	_deploy_time_sec = p_deploy_time
	_pack_time_sec = p_pack_time


# =============================================================================
# 展開状態管理
# =============================================================================

## 展開を開始
func start_deploy() -> void:
	if _deploy_state != DeployState.STOWED:
		return
	var old_state = _deploy_state
	_deploy_state = DeployState.DEPLOYING
	_deploy_progress = 0.0
	deploy_state_changed.emit(_element_id, old_state, _deploy_state)


## 撤収を開始
func start_pack() -> void:
	if _deploy_state != DeployState.DEPLOYED:
		return
	var old_state = _deploy_state
	_deploy_state = DeployState.PACKING
	_deploy_progress = 0.0
	deploy_state_changed.emit(_element_id, old_state, _deploy_state)


## 展開/撤収の進捗を更新
## @param delta_sec: 経過秒数
## @return: 完了したか
func update_progress(delta_sec: float) -> bool:
	if _deploy_state == DeployState.DEPLOYING:
		_deploy_progress += delta_sec / _deploy_time_sec
		deploy_progress_changed.emit(_element_id, _deploy_progress)
		if _deploy_progress >= 1.0:
			_deploy_progress = 1.0
			var old_state = _deploy_state
			_deploy_state = DeployState.DEPLOYED
			deploy_state_changed.emit(_element_id, old_state, _deploy_state)
			deploy_completed.emit(_element_id)
			return true
	elif _deploy_state == DeployState.PACKING:
		_deploy_progress += delta_sec / _pack_time_sec
		deploy_progress_changed.emit(_element_id, _deploy_progress)
		if _deploy_progress >= 1.0:
			_deploy_progress = 1.0
			var old_state = _deploy_state
			_deploy_state = DeployState.STOWED
			deploy_state_changed.emit(_element_id, old_state, _deploy_state)
			pack_completed.emit(_element_id)
			return true
	return false


## 展開状態を直接設定
## @param state: 新しい展開状態
func set_deploy_state(state: DeployState) -> void:
	if _deploy_state == state:
		return
	var old_state = _deploy_state
	_deploy_state = state
	deploy_state_changed.emit(_element_id, old_state, state)


## 収納状態か
func is_stowed() -> bool:
	return _deploy_state == DeployState.STOWED


## 展開中か
func is_deploying() -> bool:
	return _deploy_state == DeployState.DEPLOYING


## 展開完了か
func is_deployed() -> bool:
	return _deploy_state == DeployState.DEPLOYED


## 撤収中か
func is_packing() -> bool:
	return _deploy_state == DeployState.PACKING


## 移動可能か（収納状態のみ）
func can_move() -> bool:
	return _deploy_state == DeployState.STOWED


## 射撃可能か（展開完了のみ）
func can_fire() -> bool:
	return _deploy_state == DeployState.DEPLOYED


# =============================================================================
# 間接射撃任務
# =============================================================================

## 射撃任務を割り当て
## @param target: 目標位置
func assign_fire_mission(target: Vector2) -> void:
	_fire_mission_target = target
	_fire_mission_active = true
	fire_mission_assigned.emit(_element_id, target)


## 射撃任務をクリア
func clear_fire_mission() -> void:
	if not _fire_mission_active:
		return
	_fire_mission_target = Vector2.ZERO
	_fire_mission_active = false
	fire_mission_cleared.emit(_element_id)


## 射撃任務があるか
func has_fire_mission() -> bool:
	return _fire_mission_active


# =============================================================================
# ユーティリティ
# =============================================================================

## 状態をリセット
func reset() -> void:
	_deploy_state = DeployState.STOWED
	_deploy_progress = 0.0
	_fire_mission_target = Vector2.ZERO
	_fire_mission_active = false


# =============================================================================
# 直接設定（後方互換用）
# =============================================================================

## deploy_stateを直接設定（シグナルなし）
func set_deploy_state_raw(state: DeployState) -> void:
	_deploy_state = state


## deploy_progressを直接設定
func set_deploy_progress_raw(progress: float) -> void:
	_deploy_progress = progress


## deploy_time_secを直接設定
func set_deploy_time_sec_raw(time: float) -> void:
	_deploy_time_sec = time


## pack_time_secを直接設定
func set_pack_time_sec_raw(time: float) -> void:
	_pack_time_sec = time


## fire_mission_targetを直接設定
func set_fire_mission_target_raw(target: Vector2) -> void:
	_fire_mission_target = target


## fire_mission_activeを直接設定
func set_fire_mission_active_raw(active: bool) -> void:
	_fire_mission_active = active
