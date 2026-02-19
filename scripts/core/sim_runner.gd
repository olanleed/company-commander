class_name SimRunner
extends Node

## 10Hzシミュレーションを駆動するコアエンジン
## 仕様書: docs/game_loop_v0.1.md
##
## 責務:
## - 固定タイムステップ (SIM_DT=0.1s) でシミュレーションを進行
## - 描画フレームとシムtickを分離
## - 時間操作 (Pause/1x/2x/4x) を提供
## - 補間係数 (alpha) を提供して滑らかな描画を実現

# =============================================================================
# シグナル
# =============================================================================

## シムが1tick進行したときに発火
signal tick_advanced(tick_index: int)

## シム速度が変更されたときに発火
signal speed_changed(new_speed: float)

## Pause状態が変更されたときに発火
signal paused_changed(is_paused: bool)

# =============================================================================
# 状態
# =============================================================================

## 現在のtickインデックス (0から開始)
var tick_index: int = 0

## delta蓄積器
var _accumulator: float = 0.0

## 現在のシム速度倍率 (0=pause, 1=通常, 2=早送り, 4=高速)
var sim_speed: float = 1.0

## 描画補間用係数 (0.0 ~ 1.0)
var alpha: float = 0.0

## シミュレーション実行中かどうか
var _running: bool = false

## 乱数シード (決定論保証用)
var match_seed: int = 0

## 乱数生成器
var _rng: RandomNumberGenerator

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	_rng = RandomNumberGenerator.new()


func _process(delta: float) -> void:
	if not _running:
		return

	_advance_simulation(delta)


## シミュレーションを開始する
func start(seed_value: int = 0) -> void:
	match_seed = seed_value if seed_value != 0 else randi()
	_rng.seed = match_seed
	tick_index = 0
	_accumulator = 0.0
	alpha = 0.0
	_running = true


## シミュレーションを停止する
func stop() -> void:
	_running = false


## シミュレーションをリセットする
func reset() -> void:
	stop()
	tick_index = 0
	_accumulator = 0.0
	alpha = 0.0
	sim_speed = 1.0

# =============================================================================
# 時間操作
# =============================================================================

## 一時停止する
func pause() -> void:
	if sim_speed != 0.0:
		sim_speed = 0.0
		paused_changed.emit(true)
		speed_changed.emit(sim_speed)


## 一時停止を解除する (前の速度に戻す)
func unpause() -> void:
	if sim_speed == 0.0:
		sim_speed = 1.0
		paused_changed.emit(false)
		speed_changed.emit(sim_speed)


## Pause/Unpauseをトグルする
func toggle_pause() -> void:
	if is_paused():
		unpause()
	else:
		pause()


## 一時停止中かどうか
func is_paused() -> bool:
	return sim_speed == 0.0


## シム速度を設定する
func set_sim_speed(speed: float) -> void:
	var was_paused := is_paused()
	sim_speed = speed
	speed_changed.emit(sim_speed)

	var is_now_paused := is_paused()
	if was_paused != is_now_paused:
		paused_changed.emit(is_now_paused)


## 速度を上げる (次の段階へ)
func speed_up() -> void:
	var speeds := GameConstants.SIM_SPEEDS
	for i in range(speeds.size() - 1):
		if sim_speed <= speeds[i]:
			set_sim_speed(speeds[i + 1])
			return
	# 既に最大速度


## 速度を下げる (前の段階へ)
func speed_down() -> void:
	var speeds := GameConstants.SIM_SPEEDS
	for i in range(speeds.size() - 1, 0, -1):
		if sim_speed >= speeds[i]:
			set_sim_speed(speeds[i - 1])
			return
	# 既に最低速度 (Pause)


## 1tickだけ進める (デバッグ用、Pause中のみ有効)
func step_one_tick() -> void:
	if not is_paused():
		return

	_execute_tick()

# =============================================================================
# シム進行
# =============================================================================

## 蓄積器方式でシミュレーションを進行
func _advance_simulation(delta: float) -> void:
	_accumulator += delta * sim_speed

	var steps := 0
	while _accumulator >= GameConstants.SIM_DT and steps < GameConstants.MAX_STEPS_PER_FRAME:
		_execute_tick()
		_accumulator -= GameConstants.SIM_DT
		steps += 1

	# 補間係数を計算 (描画用)
	if GameConstants.SIM_DT > 0.0:
		alpha = _accumulator / GameConstants.SIM_DT
	else:
		alpha = 0.0


## 1tickを実行する
func _execute_tick() -> void:
	tick_index += 1

	# TODO: apply_orders_scheduled_for(tick_index)
	# TODO: simulate_one_tick()

	tick_advanced.emit(tick_index)

# =============================================================================
# 乱数 (決定論保証)
# =============================================================================

## シム用の乱数を取得 (0.0 ~ 1.0)
func rand() -> float:
	return _rng.randf()


## シム用の乱数を取得 (min ~ max)
func rand_range(min_val: float, max_val: float) -> float:
	return _rng.randf_range(min_val, max_val)


## シム用の整数乱数を取得 (0 ~ max-1)
func rand_int(max_val: int) -> int:
	return _rng.randi() % max_val

# =============================================================================
# ユーティリティ
# =============================================================================

## 現在のシム時間を秒で取得
func get_sim_time() -> float:
	return tick_index * GameConstants.SIM_DT


## tickから秒に変換
func ticks_to_seconds(ticks: int) -> float:
	return ticks * GameConstants.SIM_DT


## 秒からtickに変換 (切り上げ)
func seconds_to_ticks(seconds: float) -> int:
	return ceili(seconds / GameConstants.SIM_DT)
