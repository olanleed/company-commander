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

# =============================================================================
# 初期化
# =============================================================================

func setup(p_nav_manager: NavigationManager, p_map_data: MapData, p_world_model: WorldModel = null) -> void:
	nav_manager = p_nav_manager
	map_data = p_map_data
	world_model = p_world_model

# =============================================================================
# 移動命令
# =============================================================================

## 移動命令を発行
func issue_move_order(element: ElementData.ElementInstance, target: Vector2, use_route: bool = false) -> bool:
	if not element or not element.element_type:
		print("MovementSystem: Invalid element")
		return false

	if not nav_manager:
		print("MovementSystem: nav_manager is null")
		return false

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
	element.current_order_type = GameEnums.OrderType.MOVE

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
	var target_facing := atan2(direction.y, direction.x)

	# 回転 (スムーズに)
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
	element.velocity = Vector2.ZERO
	element.current_path.clear()
	element.path_index = 0


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


## ハード衝突解消（重なりを即座に解消）
func resolve_hard_collisions(element: ElementData.ElementInstance) -> void:
	if not world_model:
		return

	var my_radius := _get_collision_radius(element)
	var detection_range := my_radius * 3.0
	var nearby := world_model.get_elements_near(element.position, detection_range)

	for other in nearby:
		if other.id == element.id:
			continue
		if other.state == GameEnums.UnitState.DESTROYED:
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
