class_name ResupplySystem
extends RefCounted

## 補給システム
## 仕様: docs/ammunition_system_v0.1.md
##
## 時間経過による弾薬回復を管理する。
## 移動中・戦闘中は補給不可、停止中に徐々に回復。


# =============================================================================
# 定数
# =============================================================================

## 補給レート (1発あたりのtick数 @ 10Hz)
const RESUPPLY_RATE_TANK_GUN: int = 300      ## 戦車砲: 30秒/発
const RESUPPLY_RATE_ATGM: int = 600          ## ATGM: 60秒/発
const RESUPPLY_RATE_AUTOCANNON: int = 5      ## 機関砲: 0.5秒/発
const RESUPPLY_RATE_MG: int = 2              ## MG: 0.2秒/発

## クールダウン (tick @ 10Hz)
const COOLDOWN_AFTER_MOVE: int = 50          ## 移動後: 5秒
const COOLDOWN_AFTER_COMBAT: int = 300       ## 戦闘後: 30秒

## 補給速度倍率
const RESUPPLY_MULT_STOPPED: float = 1.0     ## 停止中: 100%
const RESUPPLY_MULT_SUPPRESSED: float = 0.5  ## 抑圧中: 50%
const RESUPPLY_MULT_COMBAT: float = 0.25     ## 戦闘中: 25%
const RESUPPLY_MULT_MOVING: float = 0.0      ## 移動中: 0%

## 補給上限（最大容量の80%まで回復）
const RESUPPLY_MAX_RATIO: float = 0.8


# =============================================================================
# 内部状態
# =============================================================================

## 補給進捗: element_id -> weapon_id -> progress_ticks
var _resupply_progress: Dictionary = {}


# =============================================================================
# 更新処理
# =============================================================================

## 全ユニットの補給状態を更新（毎tick呼び出し）
func update(elements: Array, current_tick: int) -> void:
	for element in elements:
		if element.is_destroyed:
			continue
		if not element.ammo_state:
			continue

		_update_element_resupply(element, current_tick)


## 単一ユニットの補給を更新
func _update_element_resupply(element: ElementData.ElementInstance, current_tick: int) -> void:
	# 補給可能かチェック
	var mult := _get_resupply_multiplier(element, current_tick)
	if mult <= 0.0:
		return

	# 補給クールダウンチェック
	if element.ammo_state.supply_cooldown_ticks > 0:
		element.ammo_state.supply_cooldown_ticks -= 1
		return

	# 主砲の補給
	if element.ammo_state.main_gun:
		_resupply_weapon(element, element.ammo_state.main_gun, RESUPPLY_RATE_TANK_GUN, mult)

	# ATGMの補給
	if element.ammo_state.atgm:
		_resupply_weapon(element, element.ammo_state.atgm, RESUPPLY_RATE_ATGM, mult)

	# 副武装の補給
	for sec in element.ammo_state.secondary:
		# 武器タイプによってレートを変える
		var rate := _get_weapon_resupply_rate(sec.weapon_id)
		_resupply_weapon(element, sec, rate, mult)


## 武器の補給処理
func _resupply_weapon(
	element: ElementData.ElementInstance,
	weapon_state,
	base_rate: int,
	mult: float
) -> void:
	# 装填中は補給しない
	if weapon_state.is_reloading:
		return

	# 進捗を取得/初期化
	var element_id: String = element.id
	var weapon_id: String = weapon_state.weapon_id

	if element_id not in _resupply_progress:
		_resupply_progress[element_id] = {}
	if weapon_id not in _resupply_progress[element_id]:
		_resupply_progress[element_id][weapon_id] = 0

	# 各スロットを補給
	for slot in weapon_state.ammo_slots:
		_resupply_slot(element_id, weapon_id, slot, base_rate, mult)


## スロットの補給処理
func _resupply_slot(
	element_id: String,
	weapon_id: String,
	slot,
	base_rate: int,
	mult: float
) -> void:
	# 補給上限チェック
	var max_total: int = slot.max_ready + slot.max_stowed
	var current_total: int = slot.count_ready + slot.count_stowed
	var max_resupply := int(float(max_total) * RESUPPLY_MAX_RATIO)

	if current_total >= max_resupply:
		return  # 補給上限に達している

	# 進捗を加算
	_resupply_progress[element_id][weapon_id] += 1

	# 補給完了チェック（倍率適用）
	var effective_rate := int(float(base_rate) / mult) if mult > 0 else base_rate
	if _resupply_progress[element_id][weapon_id] >= effective_rate:
		_resupply_progress[element_id][weapon_id] = 0

		# 予備弾に1発追加
		if slot.count_stowed < slot.max_stowed:
			slot.count_stowed += 1
		elif slot.count_ready < slot.max_ready:
			# 予備弾が満タンなら即発弾に追加
			slot.count_ready += 1


## 補給倍率を取得
func _get_resupply_multiplier(element: ElementData.ElementInstance, current_tick: int) -> float:
	# 移動中は補給なし
	if element.is_moving:
		# 移動終了時刻を記録
		element.ammo_state.last_move_tick = current_tick
		return RESUPPLY_MULT_MOVING

	# 移動直後のクールダウン
	if element.ammo_state.last_move_tick >= 0:
		var ticks_since_move: int = current_tick - element.ammo_state.last_move_tick
		if ticks_since_move < COOLDOWN_AFTER_MOVE:
			return RESUPPLY_MULT_MOVING

	# 戦闘直後のクールダウン
	if element.ammo_state.last_combat_tick >= 0:
		var ticks_since_combat: int = current_tick - element.ammo_state.last_combat_tick
		if ticks_since_combat < COOLDOWN_AFTER_COMBAT:
			return RESUPPLY_MULT_COMBAT

	# 抑圧状態
	if element.suppression >= 60.0:  # Pinned
		return RESUPPLY_MULT_SUPPRESSED
	elif element.suppression >= 30.0:  # Suppressed
		return RESUPPLY_MULT_SUPPRESSED

	return RESUPPLY_MULT_STOPPED


## 武器IDから補給レートを取得
func _get_weapon_resupply_rate(weapon_id: String) -> int:
	# 武器IDから推測
	if "MG" in weapon_id or "MG_" in weapon_id:
		return RESUPPLY_RATE_MG
	elif "AUTOCANNON" in weapon_id or "30MM" in weapon_id or "35MM" in weapon_id:
		return RESUPPLY_RATE_AUTOCANNON
	elif "ATGM" in weapon_id:
		return RESUPPLY_RATE_ATGM
	else:
		return RESUPPLY_RATE_TANK_GUN


# =============================================================================
# ユーティリティ
# =============================================================================

## 戦闘発生を記録（外部から呼び出し）
func mark_combat(element: ElementData.ElementInstance, current_tick: int) -> void:
	if element.ammo_state:
		element.ammo_state.mark_combat(current_tick)


## 進捗をリセット（ユニット撃破時等）
func clear_progress(element_id: String) -> void:
	if element_id in _resupply_progress:
		_resupply_progress.erase(element_id)
