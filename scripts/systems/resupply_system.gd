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

## 補給上限（最大容量の80%まで回復）- 自動補給
const RESUPPLY_MAX_RATIO: float = 0.8

## 補給ユニットからの直接補給で100%まで回復可能
const RESUPPLY_MAX_RATIO_FROM_SUPPLY_UNIT: float = 1.0

## 補給ユニットのデフォルト補給範囲 (m)
const DEFAULT_SUPPLY_RANGE_M: float = 100.0

## 補給ユニットのデフォルト補給速度倍率
const DEFAULT_SUPPLY_RATE_MULT: float = 2.0


# =============================================================================
# 内部状態
# =============================================================================

## 補給進捗: element_id -> weapon_id -> progress_ticks
var _resupply_progress: Dictionary = {}

## 補給ユニットリスト（element_id -> supply_config）
var _supply_units: Dictionary = {}


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

	# 各スロットを補給
	for slot in weapon_state.ammo_slots:
		var stowed_before: int = slot.count_stowed
		_resupply_slot(element_id, weapon_id, slot, base_rate, mult)

		# 補給で予備弾が増えた場合、即発弾が0ならリロード開始
		if slot.count_stowed > stowed_before and slot.count_ready == 0:
			weapon_state.start_reload()


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

	# スロットごとの進捗キーを生成（複数スロットの場合を考慮）
	var slot_key: String = weapon_id + "_" + slot.ammo_type_id
	if slot_key not in _resupply_progress[element_id]:
		_resupply_progress[element_id][slot_key] = 0

	# 進捗を加算
	_resupply_progress[element_id][slot_key] += 1

	# 補給完了チェック（倍率適用）
	var effective_rate := int(float(base_rate) / mult) if mult > 0 else base_rate
	if _resupply_progress[element_id][slot_key] >= effective_rate:
		_resupply_progress[element_id][slot_key] = 0

		# 予備弾にのみ追加（即発弾への直接追加は行わない）
		# 即発弾はリロードシステムで管理する
		if slot.count_stowed < slot.max_stowed:
			slot.count_stowed += 1


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


# =============================================================================
# 補給ユニット管理
# =============================================================================

## 補給ユニットを登録
func register_supply_unit(element: ElementData.ElementInstance, supply_config: Dictionary) -> void:
	_supply_units[element.id] = {
		"element": element,
		"capacity": supply_config.get("capacity", 100),
		"supply_range_m": supply_config.get("supply_range_m", DEFAULT_SUPPLY_RANGE_M),
		"ammo_resupply_rate": supply_config.get("ammo_resupply_rate", 1.0),
		"remaining_capacity": supply_config.get("capacity", 100)
	}


## 補給ユニットを登録解除
func unregister_supply_unit(element_id: String) -> void:
	if element_id in _supply_units:
		_supply_units.erase(element_id)


## 補給ユニットからの補給を処理
func process_supply_unit_resupply(elements: Array, current_tick: int) -> Array[Dictionary]:
	var resupply_events: Array[Dictionary] = []

	for supply_id in _supply_units:
		var supply_data: Dictionary = _supply_units[supply_id]
		var supply_unit: ElementData.ElementInstance = supply_data["element"]

		# 補給ユニットが破壊されているか移動中なら補給不可
		if supply_unit.is_destroyed or supply_unit.is_moving:
			continue

		# 補給容量が残っているかチェック
		if supply_data["remaining_capacity"] <= 0:
			continue

		var supply_range: float = supply_data["supply_range_m"]
		var rate_mult: float = supply_data["ammo_resupply_rate"]

		# 範囲内の味方ユニットを補給
		for element in elements:
			if element.is_destroyed:
				continue
			if element.id == supply_id:  # 自分自身は補給しない
				continue
			if element.faction != supply_unit.faction:  # 敵は補給しない
				continue
			if not element.ammo_state:
				continue

			# 距離チェック
			var dist: float = element.position.distance_to(supply_unit.position)
			if dist > supply_range:
				continue

			# 移動中は補給不可
			if element.is_moving:
				continue

			# 補給を実行
			var event := _resupply_from_supply_unit(element, supply_data, rate_mult, current_tick)
			if event.size() > 0:
				resupply_events.append(event)

	return resupply_events


## 補給ユニットからの補給を実行
func _resupply_from_supply_unit(
	element: ElementData.ElementInstance,
	supply_data: Dictionary,
	rate_mult: float,
	_current_tick: int
) -> Dictionary:
	var resupplied := false
	var ammo_added := 0

	# 主砲の補給
	if element.ammo_state.main_gun:
		var added := _resupply_weapon_from_unit(
			element, element.ammo_state.main_gun, supply_data, rate_mult
		)
		ammo_added += added
		if added > 0:
			resupplied = true

	# ATGMの補給
	if element.ammo_state.atgm:
		var added := _resupply_weapon_from_unit(
			element, element.ammo_state.atgm, supply_data, rate_mult
		)
		ammo_added += added
		if added > 0:
			resupplied = true

	# 副武装の補給
	for sec in element.ammo_state.secondary:
		var added := _resupply_weapon_from_unit(
			element, sec, supply_data, rate_mult
		)
		ammo_added += added
		if added > 0:
			resupplied = true

	if resupplied:
		return {
			"type": "RESUPPLY_FROM_UNIT",
			"target_id": element.id,
			"supply_unit_id": supply_data["element"].id,
			"ammo_added": ammo_added
		}

	return {}


## 補給ユニットから武器への補給
## 装填中でも補給可能（補給トラックからの直接補給）
func _resupply_weapon_from_unit(
	_element: ElementData.ElementInstance,
	weapon_state,
	supply_data: Dictionary,
	rate_mult: float
) -> int:
	var total_added := 0

	# 各スロットを補給
	for slot in weapon_state.ammo_slots:
		# 補給ユニットの残容量チェック
		if supply_data["remaining_capacity"] <= 0:
			break

		# 100%まで補給可能
		var max_total: int = slot.max_ready + slot.max_stowed
		var current_total: int = slot.count_ready + slot.count_stowed

		if current_total >= max_total:
			continue  # 満タン

		# 補給レートに応じて補給量を決定（基本1発/tick、rate_multで調整）
		var resupply_amount := int(ceil(rate_mult))
		var can_add := mini(resupply_amount, max_total - current_total)
		can_add = mini(can_add, supply_data["remaining_capacity"])

		if can_add > 0:
			# 予備弾に空きがあれば予備弾に追加
			var stowed_can_add := mini(can_add, slot.max_stowed - slot.count_stowed)
			if stowed_can_add > 0:
				slot.count_stowed += stowed_can_add
				supply_data["remaining_capacity"] -= stowed_can_add
				total_added += stowed_can_add
				can_add -= stowed_can_add

			# 予備弾が満杯でも即応弾に空きがあれば直接補給
			# （装填中でなければ即応弾に直接追加）
			if can_add > 0 and not weapon_state.is_reloading:
				var ready_can_add := mini(can_add, slot.max_ready - slot.count_ready)
				if ready_can_add > 0:
					slot.count_ready += ready_can_add
					supply_data["remaining_capacity"] -= ready_can_add
					total_added += ready_can_add

			# 予備弾が追加され、即発弾が0なら装填開始
			if slot.count_stowed > 0 and slot.count_ready == 0 and not weapon_state.is_reloading:
				weapon_state.start_reload()

	return total_added


## 補給ユニットの情報を取得
func get_supply_unit_info(element_id: String) -> Dictionary:
	if element_id in _supply_units:
		return _supply_units[element_id].duplicate()
	return {}


## 全補給ユニットを取得
func get_all_supply_units() -> Array[String]:
	var ids: Array[String] = []
	for id in _supply_units:
		ids.append(id)
	return ids
