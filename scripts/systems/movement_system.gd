class_name MovementSystem
extends RefCounted

## ユニット移動システム
## 仕様書: docs/navigation_v0.1.md
##
## パス追従とステアリングを処理する

# =============================================================================
# 定数
# =============================================================================

## パス到達判定距離 (m)
const WAYPOINT_REACH_DISTANCE: float = 5.0

## 最終目標到達判定距離 (m)
const GOAL_REACH_DISTANCE: float = 3.0

## 回転速度 (rad/s)
const ROTATION_SPEED: float = PI

# =============================================================================
# 依存
# =============================================================================

var nav_manager: NavigationManager
var map_data: MapData
var world_model: WorldModel
var missile_system  ## MissileSystem（SACLOS射手拘束チェック用）

# =============================================================================
# 初期化
# =============================================================================

func setup(p_nav_manager: NavigationManager, p_map_data: MapData, p_world_model: WorldModel = null, p_missile_system = null) -> void:
	nav_manager = p_nav_manager
	map_data = p_map_data
	world_model = p_world_model
	missile_system = p_missile_system

# =============================================================================
# 移動命令
# =============================================================================

## 移動命令を発行
## SACLOS誘導中は待機命令として保存し、着弾後に実行
func issue_move_order(element: ElementData.ElementInstance, target: Vector2, use_route: bool = false) -> bool:
	if not element or not element.element_type:
		print("MovementSystem: Invalid element")
		return false

	if not nav_manager:
		print("MovementSystem: nav_manager is null")
		return false

	# SACLOS誘導中は移動を待機（着弾後に実行）
	if _is_shooter_constrained(element.id):
		element.pending_move_order = {
			"target": target,
			"use_route": use_route
		}
		print("[MovementSystem] %s: Move order QUEUED (SACLOS constraint active)" % element.id)
		return true  # 命令は受け付けた（待機中）

	# マップ範囲内にクランプ（マップ外クリック対策）
	var clamped_target := target
	if map_data:
		clamped_target.x = clampf(target.x, 0.0, map_data.size_m.x)
		clamped_target.y = clampf(target.y, 0.0, map_data.size_m.y)
		if clamped_target != target:
			print("MovementSystem: Target clamped from ", target, " to ", clamped_target)

	var mobility := element.element_type.mobility_class
	var path := nav_manager.find_path(element.position, clamped_target, mobility, use_route)

	if path.is_empty():
		print("MovementSystem: No path found for ", element.id)
		return false

	# デバッグ: 経路の確認
	print("MovementSystem: Path for ", element.id)
	print("  target: ", clamped_target)
	print("  path_end: ", path[path.size() - 1], " diff: ", path[path.size() - 1] - clamped_target)
	print("  path_size: ", path.size())

	element.current_path = path
	# パスの最初のポイントは現在位置に近いので、次のポイントから開始
	element.path_index = 1 if path.size() > 1 else 0
	element.is_moving = true
	element.use_road_only = use_route
	element.order_target_position = target
	# ATTACKやATTACK_MOVE命令の場合は上書きしない（目標追跡を維持）
	if element.current_order_type != GameEnums.OrderType.ATTACK and element.current_order_type != GameEnums.OrderType.ATTACK_MOVE:
		element.current_order_type = GameEnums.OrderType.MOVE
	element.is_reversing = false  # 通常移動

	# 待機命令をクリア（実行したので）
	element.pending_move_order = {}

	# ATGMは移動中射撃不可のため、射撃対象をクリア
	_cancel_atgm_engagement_on_move(element)

	return true


## 停止命令を発行（即座に移動を停止）
## 待機中の移動命令もクリアする
func issue_stop_order(element: ElementData.ElementInstance) -> void:
	if not element:
		return

	_stop_movement(element)
	element.current_order_type = GameEnums.OrderType.HOLD
	element.forced_target_id = ""
	element.pending_move_order = {}  # 待機命令もクリア
	print("[MovementSystem] %s -> STOP" % element.id)


## 後退命令を発行（正面を維持したまま後退）
## SACLOS誘導中は待機命令として保存
func issue_reverse_order(element: ElementData.ElementInstance, distance: float = 100.0) -> bool:
	if not element or not element.element_type:
		return false

	# 現在の向きと反対方向に目標を設定
	var reverse_direction := Vector2(cos(element.facing), sin(element.facing)) * -1.0
	var target := element.position + reverse_direction * distance

	# マップ範囲内にクランプ
	if map_data:
		target.x = clampf(target.x, 0.0, map_data.size_m.x)
		target.y = clampf(target.y, 0.0, map_data.size_m.y)

	# SACLOS誘導中は移動を待機（着弾後に実行）
	if _is_shooter_constrained(element.id):
		element.pending_move_order = {
			"target": target,
			"use_route": false,
			"is_reverse": true
		}
		print("[MovementSystem] %s: Reverse order QUEUED (SACLOS constraint active)" % element.id)
		return true

	# パスを生成（後退中は経路探索をシンプルに）
	var path := PackedVector2Array()
	path.append(element.position)
	path.append(target)

	element.current_path = path
	element.path_index = 1
	element.is_moving = true
	element.is_reversing = true  # 後退フラグ
	element.use_road_only = false
	element.order_target_position = target
	element.current_order_type = GameEnums.OrderType.RETREAT
	element.forced_target_id = ""
	element.pending_move_order = {}  # 待機命令をクリア

	# ATGMは移動中射撃不可のため、射撃対象をクリア
	_cancel_atgm_engagement_on_move(element)

	print("[MovementSystem] %s -> REVERSE to %s" % [element.id, target])
	return true


## 離脱命令を発行（戦闘離脱：後退＋煙幕）
## SACLOS誘導中は待機命令として保存
func issue_break_contact_order(element: ElementData.ElementInstance, retreat_pos: Vector2) -> bool:
	if not element or not element.element_type:
		return false

	# マップ範囲内にクランプ
	var clamped_target := retreat_pos
	if map_data:
		clamped_target.x = clampf(retreat_pos.x, 0.0, map_data.size_m.x)
		clamped_target.y = clampf(retreat_pos.y, 0.0, map_data.size_m.y)

	# SACLOS誘導中は移動を待機（着弾後に実行）
	if _is_shooter_constrained(element.id):
		element.pending_move_order = {
			"target": clamped_target,
			"use_route": false,
			"is_break_contact": true
		}
		print("[MovementSystem] %s: Break contact order QUEUED (SACLOS constraint active)" % element.id)
		return true

	# 経路探索
	var path := PackedVector2Array()
	if nav_manager:
		var mobility := element.element_type.mobility_class
		path = nav_manager.find_path(element.position, clamped_target, mobility, false)

	if path.is_empty():
		# パスが見つからない場合は直線移動
		path = PackedVector2Array()
		path.append(element.position)
		path.append(clamped_target)

	element.current_path = path
	element.path_index = 1 if path.size() > 1 else 0
	element.is_moving = true
	element.is_reversing = false
	element.use_road_only = false
	element.order_target_position = clamped_target
	element.current_order_type = GameEnums.OrderType.BREAK_CONTACT
	element.forced_target_id = ""
	element.break_contact_smoke_requested = true  # 煙幕要請フラグ
	element.pending_move_order = {}  # 待機命令をクリア

	# ATGMは移動中射撃不可のため、射撃対象をクリア
	_cancel_atgm_engagement_on_move(element)

	print("[MovementSystem] %s -> BREAK_CONTACT to %s" % [element.id, clamped_target])
	return true

# =============================================================================
# Tick更新
# =============================================================================

## 1tickの移動を処理
func update_element(element: ElementData.ElementInstance, dt: float) -> void:
	if not element or not element.is_moving:
		return

	if element.current_path.is_empty():
		_stop_movement(element)
		return

	# 状態を保存 (補間用)
	element.save_prev_state()

	# 現在のウェイポイントを取得
	if element.path_index >= element.current_path.size():
		_stop_movement(element)
		return

	var current_waypoint := element.current_path[element.path_index]
	var to_waypoint := current_waypoint - element.position
	var distance := to_waypoint.length()

	# ウェイポイント到達チェック
	var reach_dist := GOAL_REACH_DISTANCE if element.path_index == element.current_path.size() - 1 else WAYPOINT_REACH_DISTANCE

	if distance < reach_dist:
		element.path_index += 1
		if element.path_index >= element.current_path.size():
			_stop_movement(element)
			return
		current_waypoint = element.current_path[element.path_index]
		to_waypoint = current_waypoint - element.position
		distance = to_waypoint.length()

	# 移動方向と速度を計算
	var direction := to_waypoint.normalized()

	# 後退モードかどうかで挙動を変える
	if element.is_reversing:
		# 後退時：正面を維持（回転しない）、移動速度は半減
		var terrain := map_data.get_terrain_at(element.position) if map_data else GameEnums.TerrainType.OPEN
		var speed := element.get_speed(terrain) * 0.5  # 後退は半速

		# 抑圧による速度低下
		speed *= (1.0 - element.suppression * 0.5)

		# 衝突回避ベクトルを計算
		var avoidance := _calculate_collision_avoidance(element)

		# 移動方向に衝突回避を加算
		var final_direction := (direction + avoidance).normalized()

		# 移動
		var move_dist: float = min(speed * dt, distance)
		element.velocity = final_direction * speed
		element.position += final_direction * move_dist
	else:
		# 通常移動：移動方向に向きを変える
		var target_facing := atan2(direction.y, direction.x)
		element.facing = _rotate_toward(element.facing, target_facing, ROTATION_SPEED * dt)

		# 現在地の地形に応じた速度を取得
		var terrain := map_data.get_terrain_at(element.position) if map_data else GameEnums.TerrainType.OPEN
		var speed := element.get_speed(terrain)

		# 抑圧による速度低下
		speed *= (1.0 - element.suppression * 0.5)

		# 衝突回避ベクトルを計算
		var avoidance := _calculate_collision_avoidance(element)

		# 移動方向に衝突回避を加算
		var final_direction := (direction + avoidance).normalized()

		# 移動
		var move_dist: float = min(speed * dt, distance)
		element.velocity = final_direction * speed
		element.position += final_direction * move_dist

	# ハード衝突解消（移動後に重なりをチェック）
	resolve_hard_collisions(element)

	# マップ範囲内にクランプ
	if map_data:
		element.position.x = clampf(element.position.x, 0.0, map_data.size_m.x)
		element.position.y = clampf(element.position.y, 0.0, map_data.size_m.y)


func _stop_movement(element: ElementData.ElementInstance) -> void:
	element.is_moving = false
	element.is_reversing = false
	element.velocity = Vector2.ZERO
	element.current_path.clear()
	element.path_index = 0

	# ATGM誘導中ターゲットがあれば復元（停止後に射撃再開できるように）
	_restore_atgm_target_on_stop(element)


## 停止時にATGM誘導ターゲットを復元
func _restore_atgm_target_on_stop(element: ElementData.ElementInstance) -> void:
	if element.atgm_guided_target_id != "" and element.current_target_id == "":
		element.current_target_id = element.atgm_guided_target_id
		element.atgm_guided_target_id = ""
		print("[MovementSystem] %s: ATGM target restored: %s" % [element.id, element.current_target_id])


func _rotate_toward(current: float, target: float, max_delta: float) -> float:
	var diff := wrapf(target - current, -PI, PI)
	if abs(diff) <= max_delta:
		return target
	return current + sign(diff) * max_delta


## ユニットの衝突半径を取得
func _get_collision_radius(element: ElementData.ElementInstance) -> float:
	if element.is_vehicle():
		return GameConstants.UNIT_COLLISION_RADIUS_VEHICLE
	return GameConstants.UNIT_COLLISION_RADIUS_INFANTRY


## 衝突回避ベクトルを計算（ソフト：移動方向に影響）
func _calculate_collision_avoidance(element: ElementData.ElementInstance) -> Vector2:
	if not world_model:
		return Vector2.ZERO

	# 搭乗中の歩兵は衝突計算しない
	if element.is_embarked:
		return Vector2.ZERO

	var avoidance := Vector2.ZERO
	var my_radius := _get_collision_radius(element)

	# 検出範囲内の他ユニットを取得
	var detection_range := my_radius * GameConstants.COLLISION_DETECTION_MULT * 2.0
	var nearby := world_model.get_elements_near(element.position, detection_range)

	for other in nearby:
		if other.id == element.id:
			continue
		if other.state == GameEnums.UnitState.DESTROYED:
			continue
		# 搭乗中の歩兵は衝突判定から除外
		if other.is_embarked:
			continue
		# 乗車待機中の車両と乗車移動中の歩兵は互いに衝突回避しない
		if _is_boarding_pair(element, other):
			continue

		var other_radius := _get_collision_radius(other)
		var min_dist := (my_radius + other_radius) * GameConstants.COLLISION_DETECTION_MULT
		var to_other := other.position - element.position
		var dist := to_other.length()

		if dist < min_dist and dist > 0.01:
			# 離れる方向へのベクトルを計算
			var push_dir := -to_other.normalized()
			# 距離が近いほど強い力（2乗で急激に増加）
			var overlap_ratio := 1.0 - dist / min_dist
			var strength := overlap_ratio * overlap_ratio * GameConstants.COLLISION_AVOIDANCE_FORCE
			avoidance += push_dir * strength

	return avoidance


## 乗降関連のペアかどうかをチェック（衝突回避を除外する）
func _is_boarding_pair(a: ElementData.ElementInstance, b: ElementData.ElementInstance) -> bool:
	# aが車両でbが乗車移動中の歩兵
	if not a.awaiting_boarding_id.is_empty() and a.awaiting_boarding_id == b.id:
		return true
	# bが車両でaが乗車移動中の歩兵
	if not b.awaiting_boarding_id.is_empty() and b.awaiting_boarding_id == a.id:
		return true
	# aが歩兵でbに向かって乗車移動中
	if not a.boarding_target_id.is_empty() and a.boarding_target_id == b.id:
		return true
	# bが歩兵でaに向かって乗車移動中
	if not b.boarding_target_id.is_empty() and b.boarding_target_id == a.id:
		return true
	# 下車移動中の歩兵は近くの車両と衝突回避しない（下車直後の衝突を防ぐ）
	if a.unloading_target_pos != Vector2.ZERO and b.element_type and b.element_type.can_transport_infantry:
		return true
	if b.unloading_target_pos != Vector2.ZERO and a.element_type and a.element_type.can_transport_infantry:
		return true
	# 味方の歩兵と輸送車両は衝突回避しない（乗車のために接近できるようにする）
	if _is_friendly_infantry_transport_pair(a, b):
		return true
	return false


## 味方の歩兵と輸送車両のペアかどうかをチェック
func _is_friendly_infantry_transport_pair(a: ElementData.ElementInstance, b: ElementData.ElementInstance) -> bool:
	# 同じ陣営でないなら除外しない
	if a.faction != b.faction:
		return false
	# aが歩兵でbが輸送車両
	if a.element_type and b.element_type:
		if a.element_type.category == ElementData.Category.INF and b.element_type.can_transport_infantry:
			return true
		# bが歩兵でaが輸送車両
		if b.element_type.category == ElementData.Category.INF and a.element_type.can_transport_infantry:
			return true
	return false


## ハード衝突解消（重なりを即座に解消）
func resolve_hard_collisions(element: ElementData.ElementInstance) -> void:
	if not world_model:
		return

	# 搭乗中の歩兵は衝突計算しない
	if element.is_embarked:
		return

	var my_radius := _get_collision_radius(element)
	var detection_range := my_radius * 3.0
	var nearby := world_model.get_elements_near(element.position, detection_range)

	for other in nearby:
		if other.id == element.id:
			continue
		if other.state == GameEnums.UnitState.DESTROYED:
			continue
		# 搭乗中の歩兵は衝突判定から除外
		if other.is_embarked:
			continue
		# 乗車待機中の車両と乗車移動中の歩兵は互いに衝突回避しない
		if _is_boarding_pair(element, other):
			continue

		var other_radius := _get_collision_radius(other)
		var min_dist := my_radius + other_radius  # 最小許容距離（重なり禁止）
		var to_other := other.position - element.position
		var dist := to_other.length()

		if dist < min_dist and dist > 0.001:
			# 重なっている！即座に押し出す
			var overlap := min_dist - dist
			var push_dir := -to_other.normalized()
			# 自分だけ押し出す（半分ずつにすると両方動いてしまう）
			element.position += push_dir * (overlap * 0.6)
		elif dist <= 0.001:
			# 完全に重なっている場合はランダム方向に押し出す
			var random_dir := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			element.position += random_dir * min_dist

	# マップ範囲内にクランプ
	if map_data:
		element.position.x = clampf(element.position.x, 0.0, map_data.size_m.x)
		element.position.y = clampf(element.position.y, 0.0, map_data.size_m.y)


## 静止ユニットの衝突回避（移動していないユニット用）
func apply_separation(element: ElementData.ElementInstance, dt: float) -> void:
	if not world_model:
		return
	if element.is_moving:
		return  # 移動中は update_element で処理
	# 搭乗中の歩兵は処理しない
	if element.is_embarked:
		return
	# 乗車待機中の車両は動かない
	if not element.awaiting_boarding_id.is_empty():
		return

	# まずハード衝突を解消
	resolve_hard_collisions(element)

	# ソフト衝突回避（近づきすぎを防ぐ）
	var avoidance := _calculate_collision_avoidance(element)
	if avoidance.length_squared() < 0.01:
		return

	# 回避方向に移動
	var speed := 5.0 * (1.0 - element.suppression * 0.5)
	var displacement := avoidance.normalized() * speed * dt

	element.position += displacement

	# マップ範囲内にクランプ
	if map_data:
		element.position.x = clampf(element.position.x, 0.0, map_data.size_m.x)
		element.position.y = clampf(element.position.y, 0.0, map_data.size_m.y)


# =============================================================================
# ユーティリティ
# =============================================================================

## 移動中かどうか
func is_moving(element: ElementData.ElementInstance) -> bool:
	return element and element.is_moving


## 残り距離を取得
func get_remaining_distance(element: ElementData.ElementInstance) -> float:
	if not element or element.current_path.is_empty():
		return 0.0

	var total := 0.0
	var current_pos := element.position

	for i in range(element.path_index, element.current_path.size()):
		total += current_pos.distance_to(element.current_path[i])
		current_pos = element.current_path[i]

	return total


## 到着予想時間を取得 (秒)
func get_eta(element: ElementData.ElementInstance) -> float:
	if not element or not element.element_type:
		return 0.0

	var distance := get_remaining_distance(element)
	var speed := element.element_type.road_speed  # 概算として道路速度を使用
	if speed <= 0:
		return INF

	return distance / speed


## ATGM使用中に移動を開始した場合、射撃対象をクリアする
## ATGMは静止射撃専用のため、移動開始時に射撃を中断する
## ただし、誘導中ターゲットはUI表示用に保持する
func _cancel_atgm_engagement_on_move(element: ElementData.ElementInstance) -> void:
	if not element:
		return

	# 現在の武器がATGMかチェック
	if element.current_weapon:
		WeaponData.ensure_weapon_role(element.current_weapon)
		if element.current_weapon.weapon_role == WeaponData.WeaponRole.ATGM:
			# ATGMは移動中射撃不可のため、射撃対象をクリア
			if element.current_target_id != "":
				print("[MovementSystem] %s: ATGM engagement paused (moving), target saved for display" % element.id)
				# 誘導中ターゲットを保存（UI表示用）
				element.atgm_guided_target_id = element.current_target_id
				element.current_target_id = ""


# =============================================================================
# SACLOS射手拘束
# =============================================================================

## 射手がSACLOS誘導で拘束中かどうか
func _is_shooter_constrained(shooter_id: String) -> bool:
	if not missile_system:
		return false
	return missile_system.is_shooter_constrained(shooter_id)


## 待機中の移動命令を実行（拘束解除後に呼び出し）
func execute_pending_move_order(element: ElementData.ElementInstance) -> bool:
	if not element:
		return false

	if element.pending_move_order.is_empty():
		return false

	# まだ拘束中なら実行しない
	if _is_shooter_constrained(element.id):
		return false

	var target: Vector2 = element.pending_move_order.get("target", Vector2.ZERO)
	var use_route: bool = element.pending_move_order.get("use_route", false)
	var is_reverse: bool = element.pending_move_order.get("is_reverse", false)
	var is_break_contact: bool = element.pending_move_order.get("is_break_contact", false)

	# 待機命令をクリア
	element.pending_move_order = {}

	print("[MovementSystem] %s: Executing pending move order" % element.id)

	# 命令タイプに応じて実行
	if is_reverse:
		var distance := element.position.distance_to(target)
		return issue_reverse_order(element, distance)
	elif is_break_contact:
		return issue_break_contact_order(element, target)
	else:
		return issue_move_order(element, target, use_route)


## 待機中の移動命令があるかチェック
func has_pending_move_order(element: ElementData.ElementInstance) -> bool:
	if not element:
		return false
	return not element.pending_move_order.is_empty()


## 待機命令のチェックと実行（毎tick呼び出し用）
## 拘束が解除されていれば待機命令を実行
func check_and_execute_pending_orders(element: ElementData.ElementInstance) -> void:
	if not element:
		return

	# 待機命令がなければ何もしない
	if element.pending_move_order.is_empty():
		return

	# まだ拘束中なら何もしない
	if _is_shooter_constrained(element.id):
		return

	# 拘束解除されたので待機命令を実行
	execute_pending_move_order(element)
