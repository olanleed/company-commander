class_name TransportSystem
extends RefCounted

## 輸送システム
## IFV/APCの歩兵乗降を処理する
##
## 仕様:
## - IFV/APCは出撃時に歩兵を搭乗させた状態で開始可能
## - Unloadコマンドで搭乗歩兵を下車させる
## - Boardコマンド（歩兵側）で近くの車両に乗車

# =============================================================================
# 定数
# =============================================================================

## 下車時の歩兵出現位置オフセット（車両からの距離、m）
## NOTE: 衝突検出範囲は (20+15)*1.5 = 52.5m なので、それより遠くに配置
const UNLOAD_OFFSET_DISTANCE: float = 60.0

## 乗車可能距離（m）
## NOTE: UNLOAD_OFFSET_DISTANCEが25mなので、衝突回避などによる移動を考慮して余裕を持たせる
const BOARD_RANGE: float = 75.0

## Board命令時の車両検索範囲（m）
## 歩兵がBoard命令を出したとき、この範囲内の車両を検索して移動を開始する
const BOARD_SEARCH_RANGE: float = 500.0

# =============================================================================
# 依存
# =============================================================================

var world_model: WorldModel

# =============================================================================
# 初期化
# =============================================================================

func setup(p_world_model: WorldModel) -> void:
	world_model = p_world_model

# =============================================================================
# 乗降処理
# =============================================================================

## 歩兵の下車を開始する（歩兵が車両から歩いて出る）
## transport: 輸送車両
## target_pos: 下車目標位置（車両の後方に配置）
## returns: 下車を開始した歩兵ユニット（存在しない場合null）
func start_unload_infantry(transport: ElementData.ElementInstance, target_pos: Vector2 = Vector2.ZERO) -> ElementData.ElementInstance:
	if not transport:
		print("[TransportSystem] start_unload_infantry: transport is null")
		return null

	if not transport.element_type:
		print("[TransportSystem] start_unload_infantry: element_type is null")
		return null

	# 輸送能力チェック
	if not transport.element_type.can_transport_infantry:
		print("[TransportSystem] %s has no transport capability" % transport.id)
		return null

	# 搭乗歩兵がいるかチェック
	if transport.embarked_infantry_id.is_empty():
		print("[TransportSystem] %s has no embarked infantry" % transport.id)
		return null

	# 搭乗歩兵を取得
	var infantry: ElementData.ElementInstance = null
	if world_model:
		infantry = world_model.get_element_by_id(transport.embarked_infantry_id)

	if not infantry:
		print("[TransportSystem] Could not find embarked infantry: %s" % transport.embarked_infantry_id)
		# 存在しない歩兵IDをクリア
		transport.embarked_infantry_id = ""
		return null

	# 下車位置を計算（車両の後方）
	var unload_pos: Vector2
	if target_pos != Vector2.ZERO:
		# 目標位置が指定されている場合、車両と目標の方向に配置
		var dir_to_target := (target_pos - transport.position).normalized()
		unload_pos = transport.position + dir_to_target * UNLOAD_OFFSET_DISTANCE
	else:
		# 目標位置がない場合、車両の後方に配置
		var rear_dir := Vector2(cos(transport.facing + PI), sin(transport.facing + PI))
		unload_pos = transport.position + rear_dir * UNLOAD_OFFSET_DISTANCE

	# 歩兵を車両位置からスタートさせる（まだ非表示）
	infantry.position = transport.position
	infantry.prev_position = transport.position
	infantry.facing = transport.facing
	infantry.prev_facing = transport.facing
	infantry.is_embarked = false
	infantry.transport_vehicle_id = ""
	infantry.unloading_target_pos = unload_pos  # 下車移動目標を設定

	# 輸送車両の状態を更新
	transport.embarked_infantry_id = ""

	print("[TransportSystem] %s started unloading %s toward %s" % [transport.id, infantry.id, unload_pos])

	return infantry


## 歩兵を下車させる（即座に完了、後方互換用）
## transport: 輸送車両
## target_pos: 下車目標位置（車両の後方に配置）
## returns: 下車した歩兵ユニット（存在しない場合null）
func unload_infantry(transport: ElementData.ElementInstance, target_pos: Vector2 = Vector2.ZERO) -> ElementData.ElementInstance:
	if not transport:
		print("[TransportSystem] unload_infantry: transport is null")
		return null

	if not transport.element_type:
		print("[TransportSystem] unload_infantry: element_type is null")
		return null

	# 輸送能力チェック
	if not transport.element_type.can_transport_infantry:
		print("[TransportSystem] %s has no transport capability" % transport.id)
		return null

	# 搭乗歩兵がいるかチェック
	if transport.embarked_infantry_id.is_empty():
		print("[TransportSystem] %s has no embarked infantry" % transport.id)
		return null

	# 搭乗歩兵を取得
	var infantry: ElementData.ElementInstance = null
	if world_model:
		infantry = world_model.get_element_by_id(transport.embarked_infantry_id)

	if not infantry:
		print("[TransportSystem] Could not find embarked infantry: %s" % transport.embarked_infantry_id)
		# 存在しない歩兵IDをクリア
		transport.embarked_infantry_id = ""
		return null

	# 下車位置を計算（車両の後方）
	var unload_pos: Vector2
	if target_pos != Vector2.ZERO:
		# 目標位置が指定されている場合、車両と目標の中間点の車両寄りに配置
		var dir_to_target := (target_pos - transport.position).normalized()
		unload_pos = transport.position + dir_to_target * UNLOAD_OFFSET_DISTANCE
	else:
		# 目標位置がない場合、車両の後方に配置
		var rear_dir := Vector2(cos(transport.facing + PI), sin(transport.facing + PI))
		unload_pos = transport.position + rear_dir * UNLOAD_OFFSET_DISTANCE

	# 歩兵の状態を更新
	infantry.position = unload_pos
	infantry.prev_position = unload_pos  # 補間のため
	infantry.facing = transport.facing
	infantry.prev_facing = transport.facing
	infantry.is_embarked = false
	infantry.transport_vehicle_id = ""
	infantry.velocity = Vector2.ZERO
	infantry.is_moving = false

	# 輸送車両の状態を更新
	transport.embarked_infantry_id = ""

	print("[TransportSystem] %s unloaded %s at %s" % [transport.id, infantry.id, unload_pos])

	return infantry


## 歩兵を乗車させる
## infantry: 乗車する歩兵
## transport: 乗車先の輸送車両
## returns: 成功したかどうか
func board_infantry(infantry: ElementData.ElementInstance, transport: ElementData.ElementInstance) -> bool:
	if not infantry or not transport:
		print("[TransportSystem] board_infantry: invalid parameters")
		return false

	if not transport.element_type:
		print("[TransportSystem] board_infantry: transport has no element_type")
		return false

	# 輸送能力チェック
	if not transport.element_type.can_transport_infantry:
		print("[TransportSystem] %s has no transport capability" % transport.id)
		return false

	# すでに歩兵が乗っていないかチェック
	if not transport.embarked_infantry_id.is_empty():
		print("[TransportSystem] %s already has embarked infantry: %s" % [transport.id, transport.embarked_infantry_id])
		return false

	# 距離チェック
	var distance := infantry.position.distance_to(transport.position)
	if distance > BOARD_RANGE:
		print("[TransportSystem] %s is too far from %s (%.1fm > %.1fm)" % [infantry.id, transport.id, distance, BOARD_RANGE])
		return false

	# 同じ陣営かチェック
	if infantry.faction != transport.faction:
		print("[TransportSystem] Cannot board enemy vehicle")
		return false

	# 乗車処理
	infantry.is_embarked = true
	infantry.transport_vehicle_id = transport.id
	infantry.is_moving = false
	infantry.velocity = Vector2.ZERO
	infantry.current_path.clear()

	transport.embarked_infantry_id = infantry.id

	print("[TransportSystem] %s boarded %s" % [infantry.id, transport.id])

	return true


## 輸送車両が歩兵を搭乗しているかチェック
func has_embarked_infantry(transport: ElementData.ElementInstance) -> bool:
	if not transport:
		return false
	return not transport.embarked_infantry_id.is_empty()


## 歩兵が乗車中かチェック
func is_infantry_embarked(infantry: ElementData.ElementInstance) -> bool:
	if not infantry:
		return false
	return infantry.is_embarked


## 乗車可能な車両を検索（BOARD_RANGE以内）
func find_available_transport(infantry: ElementData.ElementInstance) -> ElementData.ElementInstance:
	return find_transport_in_range(infantry, BOARD_RANGE)


## 指定範囲内の乗車可能な車両を検索（最も近い車両を返す）
## infantry: 乗車する歩兵
## search_range: 検索範囲（m）
## returns: 最も近い乗車可能な車両（存在しない場合null）
func find_transport_in_range(infantry: ElementData.ElementInstance, search_range: float) -> ElementData.ElementInstance:
	if not infantry or not world_model:
		print("[TransportSystem] find_transport_in_range: infantry or world_model is null")
		return null

	print("[TransportSystem] find_transport_in_range: searching for %s at %s (range=%.1f)" % [infantry.id, infantry.position, search_range])
	var nearby := world_model.get_elements_near(infantry.position, search_range * 1.5)
	print("[TransportSystem]   nearby elements: %d" % nearby.size())

	var best_transport: ElementData.ElementInstance = null
	var best_distance: float = INF

	for element in nearby:
		if element.id == infantry.id:
			continue
		if element.faction != infantry.faction:
			continue
		if not element.element_type:
			continue
		if not element.element_type.can_transport_infantry:
			continue
		if not element.embarked_infantry_id.is_empty():
			print("[TransportSystem]   %s: already has embarked infantry (%s)" % [element.id, element.embarked_infantry_id])
			continue
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		var distance := infantry.position.distance_to(element.position)
		if distance <= search_range and distance < best_distance:
			best_transport = element
			best_distance = distance
			print("[TransportSystem]   %s: distance=%.1f (candidate)" % [element.id, distance])

	if best_transport:
		print("[TransportSystem]   -> Found transport: %s at %.1fm" % [best_transport.id, best_distance])
	else:
		print("[TransportSystem]   -> No available transport found within %.1fm" % search_range)

	return best_transport


## 指定位置にある乗車可能な車両を取得（カーソル位置での車両選択用）
## infantry: 乗車する歩兵
## target_pos: カーソル位置
## detection_radius: 検出半径（m）
## returns: 乗車可能な車両（存在しない場合null）
func get_transport_at_position(infantry: ElementData.ElementInstance, target_pos: Vector2, detection_radius: float) -> ElementData.ElementInstance:
	if not infantry or not world_model:
		return null

	# 指定位置付近のユニットを取得
	var nearby := world_model.get_elements_near(target_pos, detection_radius * 2.0)

	var best_transport: ElementData.ElementInstance = null
	var best_distance: float = INF

	for element in nearby:
		if element.id == infantry.id:
			continue
		# 同じ陣営のみ
		if element.faction != infantry.faction:
			continue
		if not element.element_type:
			continue
		# 輸送能力がある車両のみ
		if not element.element_type.can_transport_infantry:
			continue
		# 既に歩兵が乗っている場合は除外
		if not element.embarked_infantry_id.is_empty():
			continue
		# 破壊されている場合は除外
		if element.state == GameEnums.UnitState.DESTROYED:
			continue

		# カーソル位置からの距離をチェック
		var distance := target_pos.distance_to(element.position)
		if distance <= detection_radius and distance < best_distance:
			best_transport = element
			best_distance = distance

	return best_transport


## 初期配置時に歩兵を搭乗させる（ゲーム開始時用）
## transport: 輸送車両
## infantry: 搭乗させる歩兵
func embark_initial(transport: ElementData.ElementInstance, infantry: ElementData.ElementInstance) -> void:
	if not transport or not infantry:
		return

	if not transport.element_type or not transport.element_type.can_transport_infantry:
		print("[TransportSystem] %s cannot transport infantry" % transport.id)
		return

	# 搭乗状態を設定
	transport.embarked_infantry_id = infantry.id
	infantry.is_embarked = true
	infantry.transport_vehicle_id = transport.id
	infantry.position = transport.position  # 車両と同じ位置に

	print("[TransportSystem] Initial embark: %s in %s" % [infantry.id, transport.id])


## 搭乗中の歩兵の位置を輸送車両に同期させる
## SimRunnerのtick処理で呼び出す
func sync_embarked_positions() -> void:
	if not world_model:
		return

	for element in world_model.elements:
		# 搭乗中の歩兵をチェック
		if element.is_embarked and not element.transport_vehicle_id.is_empty():
			var transport := world_model.get_element_by_id(element.transport_vehicle_id)
			if transport:
				# 車両の位置に追従
				element.position = transport.position
				element.prev_position = transport.position
				element.facing = transport.facing
				element.prev_facing = transport.facing
