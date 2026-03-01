class_name TransportComponent
extends RefCounted

## TransportComponent - 搭乗・降車状態の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 輸送車両としての搭載歩兵ID管理
## - 歩兵としての乗車中車両ID管理
## - 乗車中フラグ・乗車移動目標の管理
## - 下車目標位置の管理

# =============================================================================
# シグナル
# =============================================================================

signal infantry_embarked(vehicle_id: String, infantry_id: String)
signal infantry_disembarked(vehicle_id: String, infantry_id: String, position: Vector2)
signal boarding_started(infantry_id: String, vehicle_id: String)
signal boarding_completed(infantry_id: String, vehicle_id: String)
signal unloading_started(vehicle_id: String, infantry_id: String, target_pos: Vector2)

# =============================================================================
# 内部状態
# =============================================================================

var _element_id: String

## 輸送車両用（IFV/APC）
var _embarked_infantry_id: String = ""
var _awaiting_boarding_id: String = ""  # 乗車待機中の歩兵ID（衝突回避除外用）

## 歩兵用
var _transport_vehicle_id: String = ""
var _is_embarked: bool = false
var _boarding_target_id: String = ""
var _unloading_target_pos: Vector2 = Vector2.ZERO

# =============================================================================
# 読み取り専用プロパティ
# =============================================================================

## 輸送車両用
var embarked_infantry_id: String:
	get: return _embarked_infantry_id

var awaiting_boarding_id: String:
	get: return _awaiting_boarding_id

## 歩兵用
var transport_vehicle_id: String:
	get: return _transport_vehicle_id

var is_embarked: bool:
	get: return _is_embarked

var boarding_target_id: String:
	get: return _boarding_target_id

var unloading_target_pos: Vector2:
	get: return _unloading_target_pos

# =============================================================================
# 初期化
# =============================================================================

func _init(element_id: String) -> void:
	_element_id = element_id


# =============================================================================
# 輸送車両メソッド
# =============================================================================

## 歩兵を搭載
## @param infantry_id: 搭載する歩兵ID
func embark_infantry(infantry_id: String) -> void:
	_embarked_infantry_id = infantry_id
	_awaiting_boarding_id = ""  # 乗車完了で待機IDをクリア
	infantry_embarked.emit(_element_id, infantry_id)


## 搭載歩兵をクリア
func clear_embarked_infantry() -> void:
	_embarked_infantry_id = ""


## 歩兵を下車させる
## @param target_pos: 下車目標位置
func start_unload_infantry(target_pos: Vector2) -> void:
	if _embarked_infantry_id == "":
		return
	unloading_started.emit(_element_id, _embarked_infantry_id, target_pos)


## 下車完了
## @param position: 下車位置
func complete_unload_infantry(position: Vector2) -> void:
	if _embarked_infantry_id == "":
		return
	var infantry_id = _embarked_infantry_id
	_embarked_infantry_id = ""
	infantry_disembarked.emit(_element_id, infantry_id, position)


## 歩兵が搭載されているか
func has_embarked_infantry() -> bool:
	return _embarked_infantry_id != ""


## 乗車待機中の歩兵を設定
## @param infantry_id: 待機中の歩兵ID
func set_awaiting_boarding(infantry_id: String) -> void:
	_awaiting_boarding_id = infantry_id


## 乗車待機をクリア
func clear_awaiting_boarding() -> void:
	_awaiting_boarding_id = ""


# =============================================================================
# 歩兵メソッド
# =============================================================================

## 乗車する車両を設定（乗車中状態にする）
## @param vehicle_id: 乗車する車両ID
func embark_to_vehicle(vehicle_id: String) -> void:
	_transport_vehicle_id = vehicle_id
	_is_embarked = true
	_boarding_target_id = ""  # 乗車完了で目標をクリア
	boarding_completed.emit(_element_id, vehicle_id)


## 乗車移動を開始
## @param vehicle_id: 目標車両ID
func start_boarding(vehicle_id: String) -> void:
	_boarding_target_id = vehicle_id
	boarding_started.emit(_element_id, vehicle_id)


## 下車する
## @param position: 下車位置
func disembark_at(position: Vector2) -> void:
	var vehicle_id = _transport_vehicle_id
	_transport_vehicle_id = ""
	_is_embarked = false
	_unloading_target_pos = Vector2.ZERO


## 下車目標位置を設定
## @param target_pos: 下車後の移動目標位置
func set_unloading_target(target_pos: Vector2) -> void:
	_unloading_target_pos = target_pos


## 下車目標位置をクリア
func clear_unloading_target() -> void:
	_unloading_target_pos = Vector2.ZERO


## 乗車中かどうか
func is_in_vehicle() -> bool:
	return _is_embarked


## 乗車移動中かどうか
func is_boarding() -> bool:
	return _boarding_target_id != ""


## 乗車移動をキャンセル
func cancel_boarding() -> void:
	_boarding_target_id = ""


# =============================================================================
# ユーティリティ
# =============================================================================

## 状態をリセット
func reset() -> void:
	_embarked_infantry_id = ""
	_awaiting_boarding_id = ""
	_transport_vehicle_id = ""
	_is_embarked = false
	_boarding_target_id = ""
	_unloading_target_pos = Vector2.ZERO


# =============================================================================
# 直接設定（後方互換用）
# =============================================================================

## embarked_infantry_idを直接設定
func set_embarked_infantry_id_raw(id: String) -> void:
	_embarked_infantry_id = id


## transport_vehicle_idを直接設定
func set_transport_vehicle_id_raw(id: String) -> void:
	_transport_vehicle_id = id


## is_embarkedを直接設定
func set_is_embarked_raw(value: bool) -> void:
	_is_embarked = value


## boarding_target_idを直接設定
func set_boarding_target_id_raw(id: String) -> void:
	_boarding_target_id = id


## unloading_target_posを直接設定
func set_unloading_target_pos_raw(pos: Vector2) -> void:
	_unloading_target_pos = pos


## awaiting_boarding_idを直接設定
func set_awaiting_boarding_id_raw(id: String) -> void:
	_awaiting_boarding_id = id
