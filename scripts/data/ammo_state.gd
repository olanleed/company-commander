class_name AmmoState
extends RefCounted

## 弾薬状態管理クラス
## 仕様: docs/ammunition_system_v0.1.md
##
## 武器スロットごとの弾薬状況を追跡する。
## - 即発弾 (ready rounds): 即座に発射可能な弾薬
## - 予備弾 (stowed rounds): 車体内に格納された弾薬（装填が必要）


# =============================================================================
# 定数
# =============================================================================

## 装填時間 (ticks @ 10Hz)
const RELOAD_TICKS_AUTOLOADER: int = 40      ## 自動装填: 4秒
const RELOAD_TICKS_MANUAL: int = 80          ## 手動装填: 8秒
const RELOAD_TICKS_AMMO_SWITCH: int = 40     ## 弾種切替: 4秒

## 弾種配分デフォルト (主砲)
const TANK_GUN_AMMO_DISTRIBUTION := {
	"APFSDS": 0.65,   ## APFSDSは65%
	"HEAT": 0.25,     ## HEATは25%
	"HE_MP": 0.10,    ## HE-MPは10%
}

## 弾種配分デフォルト (機関砲)
const AUTOCANNON_AMMO_DISTRIBUTION := {
	"AP": 0.50,       ## AP系50%
	"HE": 0.50,       ## HE系50%
}


# =============================================================================
# 弾種スロット
# =============================================================================

class AmmoSlot:
	extends RefCounted

	var ammo_type_id: String = ""           ## 弾種ID (例: "10式APFSDS")
	var count_ready: int = 0                ## 即発弾数 (ready rounds)
	var count_stowed: int = 0               ## 予備弾数 (stowed rounds)
	var max_ready: int = 0                  ## 即発弾最大数
	var max_stowed: int = 0                 ## 予備弾最大数


	func _init(p_ammo_type_id: String = "") -> void:
		ammo_type_id = p_ammo_type_id


	## 総弾数
	func total() -> int:
		return count_ready + count_stowed


	## 最大総弾数
	func max_total() -> int:
		return max_ready + max_stowed


	## 弾切れか
	func is_empty() -> bool:
		return count_ready == 0 and count_stowed == 0


	## 即発弾の充填率 (0.0-1.0)
	func ready_ratio() -> float:
		return float(count_ready) / float(max_ready) if max_ready > 0 else 0.0


	## 総弾数の充填率 (0.0-1.0)
	func total_ratio() -> float:
		var m := max_total()
		return float(total()) / float(m) if m > 0 else 0.0


	## デバッグ用文字列
	func get_debug_string() -> String:
		return "%s: %d/%d ready, %d/%d stowed" % [
			ammo_type_id, count_ready, max_ready, count_stowed, max_stowed
		]


# =============================================================================
# 武器弾薬状態
# =============================================================================

class WeaponAmmoState:
	extends RefCounted

	var weapon_id: String = ""              ## 武器ID (例: "CW_TANK_KE_120_JGSDF")
	var ammo_slots: Array[AmmoSlot] = []    ## 弾種ごとのスロット
	var current_ammo_index: int = 0         ## 現在選択中の弾種インデックス

	## 装填状態
	var is_reloading: bool = false          ## 装填中フラグ
	var reload_progress_ticks: int = 0      ## 装填進捗 (tick)
	var reload_duration_ticks: int = 60     ## 装填所要時間 (tick, 6秒@10Hz)

	## 自動装填機能
	var has_autoloader: bool = false        ## 自動装填装置の有無


	func _init(p_weapon_id: String = "") -> void:
		weapon_id = p_weapon_id
		ammo_slots = []


	## 現在選択中の弾種スロットを取得
	func get_current_slot() -> AmmoSlot:
		if current_ammo_index >= 0 and current_ammo_index < ammo_slots.size():
			return ammo_slots[current_ammo_index]
		return null


	## 発射可能か
	func can_fire() -> bool:
		var slot := get_current_slot()
		return slot != null and slot.count_ready > 0 and not is_reloading


	## 総残弾数
	func get_total_remaining() -> int:
		var total := 0
		for slot in ammo_slots:
			total += slot.total()
		return total


	## 最大総弾数
	func get_max_total() -> int:
		var total := 0
		for slot in ammo_slots:
			total += slot.max_total()
		return total


	## 総残弾率 (0.0-1.0)
	func get_total_ratio() -> float:
		var max_t := get_max_total()
		return float(get_total_remaining()) / float(max_t) if max_t > 0 else 0.0


	## 弾種を切り替え
	func switch_ammo(new_index: int) -> bool:
		if new_index < 0 or new_index >= ammo_slots.size():
			return false
		if current_ammo_index == new_index:
			return true  # 既に選択中

		current_ammo_index = new_index
		is_reloading = true
		reload_progress_ticks = 0
		reload_duration_ticks = RELOAD_TICKS_AMMO_SWITCH
		return true


	## 装填を開始
	func start_reload() -> void:
		if is_reloading:
			return

		var slot := get_current_slot()
		if not slot or slot.count_stowed <= 0:
			return

		# 即発弾がすでに満杯なら装填しない
		if slot.count_ready >= slot.max_ready:
			return

		is_reloading = true
		reload_progress_ticks = 0
		reload_duration_ticks = RELOAD_TICKS_AUTOLOADER if has_autoloader else RELOAD_TICKS_MANUAL


	## 装填を更新 (毎tick呼び出し)
	## 戻り値: 装填が完了したらtrue
	func update_reload() -> bool:
		if not is_reloading:
			return false

		var slot := get_current_slot()
		if not slot:
			is_reloading = false
			reload_progress_ticks = 0
			return false

		# 即発弾がすでに満杯なら装填を停止
		if slot.count_ready >= slot.max_ready:
			is_reloading = false
			reload_progress_ticks = 0
			return false

		reload_progress_ticks += 1

		if reload_progress_ticks >= reload_duration_ticks:
			# 装填完了
			is_reloading = false
			reload_progress_ticks = 0

			if slot.count_stowed > 0 and slot.count_ready < slot.max_ready:
				var transfer := mini(1, slot.count_stowed)
				slot.count_stowed -= transfer
				slot.count_ready += transfer

				# まだmax_readyに達していなければ継続して装填
				if slot.count_ready < slot.max_ready and slot.count_stowed > 0:
					start_reload()

				return true

		return false


	## デバッグ用文字列
	func get_debug_string() -> String:
		var slot_strs: PackedStringArray = []
		for slot in ammo_slots:
			slot_strs.append(slot.get_debug_string())
		return "%s [%s]: %s" % [
			weapon_id,
			"RELOADING" if is_reloading else "READY",
			", ".join(slot_strs)
		]


# =============================================================================
# ユニット弾薬状態
# =============================================================================

var main_gun: WeaponAmmoState = null        ## 主砲
var secondary: Array[WeaponAmmoState] = []  ## 副武装 (同軸MG, HMG等)
var atgm: WeaponAmmoState = null            ## ATGM

## 補給状態
var supply_cooldown_ticks: int = 0          ## 補給クールダウン (tick)
var last_combat_tick: int = -1              ## 最後の戦闘tick
var last_move_tick: int = -1                ## 最後の移動tick

## 誘爆リスク (0.0 = 完全防護, 1.0 = 無防護)
## ブローオフパネル装備車両は低い値
var ammo_detonation_vulnerability: float = 0.5


func _init() -> void:
	secondary = []


# =============================================================================
# ユーティリティ
# =============================================================================

## 総残弾率を取得 (誘爆確率計算用)
func get_total_ammo_ratio() -> float:
	var total_current := 0
	var total_max := 0

	if main_gun:
		total_current += main_gun.get_total_remaining()
		total_max += main_gun.get_max_total()

	if atgm:
		total_current += atgm.get_total_remaining()
		total_max += atgm.get_max_total()

	for sec in secondary:
		total_current += sec.get_total_remaining()
		total_max += sec.get_max_total()

	return float(total_current) / float(total_max) if total_max > 0 else 0.0


## 武器IDから弾薬状態を取得
func get_weapon_state(weapon_id: String) -> WeaponAmmoState:
	if main_gun and main_gun.weapon_id == weapon_id:
		return main_gun
	if atgm and atgm.weapon_id == weapon_id:
		return atgm
	for sec in secondary:
		if sec.weapon_id == weapon_id:
			return sec
	return null


## 全武器の装填状態を更新
func update_all_reloads() -> void:
	if main_gun:
		main_gun.update_reload()
	if atgm:
		atgm.update_reload()
	for sec in secondary:
		sec.update_reload()


## 戦闘発生を記録
func mark_combat(current_tick: int) -> void:
	last_combat_tick = current_tick


## 移動発生を記録
func mark_move(current_tick: int) -> void:
	last_move_tick = current_tick


## デバッグ用文字列
func get_debug_string() -> String:
	var parts: PackedStringArray = []
	if main_gun:
		parts.append("MainGun: " + main_gun.get_debug_string())
	if atgm:
		parts.append("ATGM: " + atgm.get_debug_string())
	for i in secondary.size():
		parts.append("Secondary[%d]: %s" % [i, secondary[i].get_debug_string()])
	return "\n".join(parts)


# =============================================================================
# ファクトリメソッド
# =============================================================================

## 車両カタログデータから弾薬状態を作成
static func create_from_catalog(catalog_data: Dictionary):
	var state = load("res://scripts/data/ammo_state.gd").new()

	# 主砲
	if "main_gun" in catalog_data:
		state.main_gun = _create_weapon_state_from_catalog(catalog_data.main_gun)

	# ATGM
	if "atgm" in catalog_data:
		state.atgm = _create_atgm_state_from_catalog(catalog_data.atgm)

	# 誘爆脆弱性 (protection から取得、なければデフォルト)
	if "protection" in catalog_data:
		var protection: Dictionary = catalog_data.protection
		# ブローオフパネル等の防護がある場合は脆弱性が低い
		if protection.get("blowout_panels", false):
			state.ammo_detonation_vulnerability = 0.2
		elif protection.get("wet_ammo_stowage", false):
			state.ammo_detonation_vulnerability = 0.3
		else:
			state.ammo_detonation_vulnerability = 0.5

	return state


## 主砲/機関砲用の弾薬状態を作成
static func _create_weapon_state_from_catalog(gun_data: Dictionary) -> WeaponAmmoState:
	var weapon_state := WeaponAmmoState.new(gun_data.get("weapon_id", ""))
	weapon_state.has_autoloader = gun_data.get("autoloader", false)

	var total_capacity: int = gun_data.get("ammo_capacity_total", 40)
	var ready_capacity: int = gun_data.get("ammo_capacity_ready", 14)
	var stowed_capacity: int = total_capacity - ready_capacity

	var ammo_types: Array = gun_data.get("ammo_types", ["APFSDS"])

	# 弾種ごとにスロットを作成
	var num_types := ammo_types.size()
	if num_types == 0:
		num_types = 1
		ammo_types = ["DEFAULT"]

	# 配分を計算
	var distribution := _get_ammo_distribution(ammo_types)

	for i in num_types:
		var ammo_type_id: String = ammo_types[i] if i < ammo_types.size() else "DEFAULT"
		var ratio: float = distribution[i] if i < distribution.size() else 1.0 / float(num_types)

		var slot := AmmoSlot.new(ammo_type_id)
		slot.max_ready = int(float(ready_capacity) * ratio)
		slot.max_stowed = int(float(stowed_capacity) * ratio)
		# 初期状態は満載
		slot.count_ready = slot.max_ready
		slot.count_stowed = slot.max_stowed

		weapon_state.ammo_slots.append(slot)

	return weapon_state


## ATGM用の弾薬状態を作成
static func _create_atgm_state_from_catalog(atgm_data: Dictionary) -> WeaponAmmoState:
	var weapon_state := WeaponAmmoState.new(atgm_data.get("weapon_id", ""))
	weapon_state.has_autoloader = false  # ATGMは手動装填

	var ready_count: int
	var reserve_count: int

	# ready_count/reserve_count が明示的に指定されている場合はそれを使用
	if "ready_count" in atgm_data:
		ready_count = atgm_data.get("ready_count", 2)
		reserve_count = atgm_data.get("reserve_count", 4)
	elif "count" in atgm_data:
		# count のみが指定されている場合は分配する
		# 一般的なIFV: 即発2発、予備は残り
		var total_count: int = atgm_data.get("count", 4)
		ready_count = mini(2, total_count)  # 最大2発を即発弾として
		reserve_count = total_count - ready_count
	else:
		# デフォルト値
		ready_count = 2
		reserve_count = 4

	var slot := AmmoSlot.new(atgm_data.get("type", "ATGM"))
	slot.max_ready = ready_count
	slot.max_stowed = reserve_count
	slot.count_ready = ready_count
	slot.count_stowed = reserve_count

	weapon_state.ammo_slots.append(slot)

	return weapon_state


## 弾種名から配分比率を取得
static func _get_ammo_distribution(ammo_types: Array) -> Array[float]:
	var distribution: Array[float] = []
	var num_types := ammo_types.size()

	if num_types == 1:
		distribution.append(1.0)
		return distribution

	# 砲兵弾種（全てHE系）かどうか判定
	var is_artillery := _is_artillery_ammo_types(ammo_types)
	if is_artillery:
		# 砲兵は均等配分（または主弾種HEを多め）
		return _get_artillery_distribution(ammo_types)

	# 戦車砲用：弾種名からカテゴリを推定して配分
	for ammo_type in ammo_types:
		var type_str := str(ammo_type).to_upper()
		if "APFSDS" in type_str or "SABOT" in type_str:
			distribution.append(0.65)
		elif "HEAT" in type_str:
			distribution.append(0.25)
		elif "HE" in type_str or "MP" in type_str:
			distribution.append(0.10)
		else:
			distribution.append(1.0 / float(num_types))

	# 正規化
	var total := 0.0
	for d in distribution:
		total += d
	if total > 0:
		for i in distribution.size():
			distribution[i] /= total

	return distribution


## 砲兵弾種かどうか判定（全てHE系、または口径指定がある）
static func _is_artillery_ammo_types(ammo_types: Array) -> bool:
	# APFSDSやHEATがあれば戦車砲
	for ammo_type in ammo_types:
		var type_str := str(ammo_type).to_upper()
		if "APFSDS" in type_str or "SABOT" in type_str or "HEAT" in type_str:
			return false
	# 口径指定（155mm, 152mm, 120mm等）があれば砲兵
	for ammo_type in ammo_types:
		var type_str := str(ammo_type).to_upper()
		if "155" in type_str or "152" in type_str or "122" in type_str or "120MM" in type_str:
			return true
		if "HOWITZER" in type_str or "MORTAR" in type_str:
			return true
		# M795, M982等の米軍砲弾
		if type_str.begins_with("M7") or type_str.begins_with("M9"):
			return true
	# 全てHE系なら砲兵と判定
	var all_he := true
	for ammo_type in ammo_types:
		var type_str := str(ammo_type).to_upper()
		if not ("HE" in type_str or "SMOKE" in type_str or "ICM" in type_str or "EXCALIBUR" in type_str or "GUIDED" in type_str or "RAP" in type_str or "PGK" in type_str):
			all_he = false
			break
	return all_he


## 砲兵用弾種配分（主弾種HEを多め）
static func _get_artillery_distribution(ammo_types: Array) -> Array[float]:
	var distribution: Array[float] = []
	var num_types := ammo_types.size()

	# 標準HE（最初の弾種）を多め、特殊弾（誘導弾等）を少なめ
	for i in num_types:
		var ammo_type: String = str(ammo_types[i]).to_upper()
		if i == 0:
			# 最初の弾種（標準HE）は60-70%
			distribution.append(0.70)
		elif "EXCALIBUR" in ammo_type or "GUIDED" in ammo_type or "PGK" in ammo_type:
			# 誘導弾は少なめ (10%)
			distribution.append(0.10)
		elif "SMOKE" in ammo_type:
			# 煙幕弾は少なめ (10%)
			distribution.append(0.10)
		elif "ICM" in ammo_type or "DPICM" in ammo_type:
			# クラスター弾は中程度 (15%)
			distribution.append(0.15)
		else:
			# その他 (15%)
			distribution.append(0.15)

	# 正規化
	var total := 0.0
	for d in distribution:
		total += d
	if total > 0:
		for i in distribution.size():
			distribution[i] /= total

	return distribution
