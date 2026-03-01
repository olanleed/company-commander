class_name PositionComponent
extends RefCounted

## PositionComponent - 位置・向き・速度の管理
## コンポーネント分離フェーズ1
##
## 責務:
## - 現在位置・向き・速度の保持
## - 前tick状態の保持（補間用）
## - 位置変更時のシグナル発火

# =============================================================================
# シグナル
# =============================================================================

signal position_changed(old_pos: Vector2, new_pos: Vector2)
signal facing_changed(old_facing: float, new_facing: float)
signal velocity_changed(old_vel: Vector2, new_vel: Vector2)

# =============================================================================
# 内部状態
# =============================================================================

var _position: Vector2 = Vector2.ZERO
var _prev_position: Vector2 = Vector2.ZERO
var _facing: float = 0.0
var _prev_facing: float = 0.0
var _velocity: Vector2 = Vector2.ZERO

# =============================================================================
# プロパティアクセサ
# =============================================================================

## 現在位置
var position: Vector2:
	get: return _position
	set(value):
		if _position != value:
			var old = _position
			_position = value
			position_changed.emit(old, value)


## 向き（ラジアン）
var facing: float:
	get: return _facing
	set(value):
		if not is_equal_approx(_facing, value):
			var old = _facing
			_facing = value
			facing_changed.emit(old, value)


## 速度ベクトル
var velocity: Vector2:
	get: return _velocity
	set(value):
		if _velocity != value:
			var old = _velocity
			_velocity = value
			velocity_changed.emit(old, value)


## 前tick位置（読み取り専用）
var prev_position: Vector2:
	get: return _prev_position


## 前tick向き（読み取り専用）
var prev_facing: float:
	get: return _prev_facing


# =============================================================================
# メソッド
# =============================================================================

## 前tick状態を保存（補間用、毎tick開始時に呼び出す）
func save_prev_state() -> void:
	_prev_position = _position
	_prev_facing = _facing


## 補間位置を取得
## @param alpha: 補間係数 (0.0 = prev, 1.0 = current)
func get_interpolated_position(alpha: float) -> Vector2:
	return _prev_position.lerp(_position, alpha)


## 補間角度を取得
## @param alpha: 補間係数 (0.0 = prev, 1.0 = current)
func get_interpolated_facing(alpha: float) -> float:
	return lerp_angle(_prev_facing, _facing, alpha)


## 相対移動
## @param delta: 移動量
func move_by(delta: Vector2) -> void:
	position = _position + delta


## 位置と向きを同時に設定
## @param pos: 新しい位置
## @param face: 新しい向き（ラジアン）
func set_position_and_facing(pos: Vector2, face: float) -> void:
	position = pos
	facing = face
