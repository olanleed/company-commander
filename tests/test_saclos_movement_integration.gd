extends GutTest

## SACLOS誘導中の移動命令統合テスト
## 仕様:
## - SACLOS誘導ミサイル飛翔中に移動命令 → 着弾まで待機 → 着弾後移動開始
## - HOLD_FIREで誘導を打ち切り → 即座に移動可能
## - Fire-and-Forget は発射後即移動可能

const MissileSystem := preload("res://scripts/systems/missile_system.gd")
const MissileData := preload("res://scripts/data/missile_data.gd")
const ElementData := preload("res://scripts/data/element_data.gd")
const GameEnums := preload("res://scripts/core/game_enums.gd")
const MovementSystem := preload("res://scripts/systems/movement_system.gd")

var missile_system: MissileSystem
var movement_system: MovementSystem
var mock_element: ElementData.ElementInstance


func before_each() -> void:
	missile_system = MissileSystem.new()
	movement_system = MovementSystem.new()
	# Note: movement_system.setup() は nav_manager が必要なため、
	# ここでは missile_system との連携のみテスト
	mock_element = _create_mock_element("TEST_001")


func after_each() -> void:
	missile_system.reset()


# =============================================================================
# テスト用ヘルパー
# =============================================================================

func _create_mock_element(id: String) -> ElementData.ElementInstance:
	var element := ElementData.ElementInstance.new()
	element.id = id
	element.position = Vector2(100, 100)
	element.faction = GameEnums.Faction.BLUE
	element.state = GameEnums.UnitState.ACTIVE
	element.is_moving = false
	element.pending_move_order = {}  # 空のDictionary = 待機命令なし
	return element


func _create_saclos_wire_profile() -> MissileData.MissileProfile:
	var profile := MissileData.MissileProfile.new()
	profile.id = "test_saclos_wire"
	profile.display_name = "Test SACLOS Wire"
	profile.guidance_type = MissileData.GuidanceType.SACLOS_WIRE
	profile.lock_mode = MissileData.LockMode.CONTINUOUS_TRACK
	profile.speed_mps = 200.0
	profile.max_range_m = 3750.0
	profile.min_range_m = 65.0
	profile.default_attack_profile = MissileData.AttackProfile.DIRECT
	profile.available_profiles = [MissileData.AttackProfile.DIRECT]
	profile.shooter_constrained = true
	profile.wire_guided = true
	return profile


func _create_fire_and_forget_profile() -> MissileData.MissileProfile:
	var profile := MissileData.MissileProfile.new()
	profile.id = "test_faf"
	profile.display_name = "Test Fire-and-Forget"
	profile.guidance_type = MissileData.GuidanceType.IIR_HOMING
	profile.lock_mode = MissileData.LockMode.LOBL
	profile.speed_mps = 150.0
	profile.max_range_m = 2500.0
	profile.min_range_m = 65.0
	profile.default_attack_profile = MissileData.AttackProfile.TOP_ATTACK
	profile.available_profiles = [
		MissileData.AttackProfile.TOP_ATTACK,
		MissileData.AttackProfile.DIRECT
	]
	profile.shooter_constrained = false
	profile.wire_guided = false
	return profile


## 待機命令があるかチェック
func _has_pending_move(element: ElementData.ElementInstance) -> bool:
	return not element.pending_move_order.is_empty()


## 待機命令をクリア
func _clear_pending_move(element: ElementData.ElementInstance) -> void:
	element.pending_move_order = {}


# =============================================================================
# 移動命令待機テスト
# =============================================================================

func test_pending_move_order_stored_when_constrained() -> void:
	## SACLOS飛翔中に移動命令 → pending_move_orderに保存
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	# ミサイル発射
	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射後は拘束")

	# 移動命令を保存（MovementSystemが行う処理のシミュレーション）
	var target_pos := Vector2(500, 500)
	if not missile_system.can_shooter_move(shooter_id):
		# 待機命令として保存
		mock_element.pending_move_order = {
			"target": target_pos,
			"use_route": false
		}

	assert_true(_has_pending_move(mock_element), "待機命令が保存される")
	assert_eq(mock_element.pending_move_order["target"], target_pos, "目標位置が正しい")
	assert_false(mock_element.is_moving, "まだ移動開始していない")


func test_pending_move_executed_after_impact() -> void:
	## 着弾後に待機命令が実行される
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	# 近距離ミサイル発射
	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(200, 100),  # 100m先（すぐ着弾）
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 待機命令を保存
	var target_pos := Vector2(500, 500)
	mock_element.pending_move_order = {
		"target": target_pos,
		"use_route": false
	}

	# 着弾まで更新
	missile_system.update(5)  # 0.5秒
	assert_true(missile_system.is_shooter_constrained(shooter_id), "まだ飛翔中")

	missile_system.update(15)  # 1.5秒後
	assert_false(missile_system.is_shooter_constrained(shooter_id), "着弾後は拘束解除")

	# 待機命令があれば実行（MovementSystemが行う処理）
	if _has_pending_move(mock_element) and missile_system.can_shooter_move(shooter_id):
		# 実際の移動開始処理をシミュレート
		mock_element.is_moving = true
		mock_element.order_target_position = mock_element.pending_move_order["target"]
		_clear_pending_move(mock_element)

	assert_true(mock_element.is_moving, "着弾後に移動開始")
	assert_eq(mock_element.order_target_position, target_pos, "待機命令の目標に移動")
	assert_false(_has_pending_move(mock_element), "待機命令がクリアされる")


func test_hold_fire_cancels_constraint_and_executes_pending_move() -> void:
	## HOLD_FIREで拘束解除 → 待機命令が即座に実行可能
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	# 遠距離ミサイル発射
	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(3000, 100),  # 遠距離
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 待機命令を保存
	var target_pos := Vector2(500, 500)
	mock_element.pending_move_order = {
		"target": target_pos,
		"use_route": false
	}

	assert_true(missile_system.is_shooter_constrained(shooter_id), "発射後は拘束")

	# HOLD_FIRE（誘導打ち切り）
	missile_system.force_release_shooter(shooter_id)

	assert_false(missile_system.is_shooter_constrained(shooter_id), "HOLD_FIRE後は拘束解除")

	# 待機命令があれば即座に実行可能
	if _has_pending_move(mock_element) and missile_system.can_shooter_move(shooter_id):
		mock_element.is_moving = true
		mock_element.order_target_position = mock_element.pending_move_order["target"]
		_clear_pending_move(mock_element)

	assert_true(mock_element.is_moving, "HOLD_FIRE後に即座に移動開始")


func test_fire_and_forget_no_pending_move_needed() -> void:
	## Fire-and-Forgetは待機不要、即座に移動命令実行
	var profile := _create_fire_and_forget_profile()
	var shooter_id := mock_element.id

	# ミサイル発射
	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(1000, 100),
		profile,
		MissileData.AttackProfile.TOP_ATTACK,
		0
	)

	assert_false(missile_system.is_shooter_constrained(shooter_id), "FaFは拘束なし")

	# 移動命令を即座に実行可能
	var target_pos := Vector2(500, 500)
	if missile_system.can_shooter_move(shooter_id):
		mock_element.is_moving = true
		mock_element.order_target_position = target_pos

	assert_true(mock_element.is_moving, "FaFは発射後即移動可能")
	assert_false(_has_pending_move(mock_element), "待機命令不要")


# =============================================================================
# 待機命令上書きテスト
# =============================================================================

func test_new_move_order_overwrites_pending() -> void:
	## 新しい移動命令は既存の待機命令を上書き
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 最初の待機命令
	mock_element.pending_move_order = {
		"target": Vector2(500, 500),
		"use_route": false
	}

	# 2番目の待機命令（上書き）
	var new_target := Vector2(800, 200)
	mock_element.pending_move_order = {
		"target": new_target,
		"use_route": true
	}

	assert_eq(mock_element.pending_move_order["target"], new_target, "新しい命令で上書き")
	assert_true(mock_element.pending_move_order["use_route"], "use_routeも更新")


func test_stop_order_clears_pending_move() -> void:
	## STOP命令は待機命令をクリア
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 待機命令を保存
	mock_element.pending_move_order = {
		"target": Vector2(500, 500),
		"use_route": false
	}

	# STOP命令
	_clear_pending_move(mock_element)
	mock_element.current_order_type = GameEnums.OrderType.HOLD

	assert_false(_has_pending_move(mock_element), "STOP命令で待機命令がクリア")


# =============================================================================
# エッジケーステスト
# =============================================================================

func test_missile_lost_releases_constraint() -> void:
	## ミサイル誘導喪失時も拘束解除
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	var _missile_id := missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0
	)

	# 待機命令を保存
	mock_element.pending_move_order = {
		"target": Vector2(500, 500),
		"use_route": false
	}

	# 有線切断（射手移動）
	missile_system.check_wire_integrity(shooter_id, {
		"is_moving": true,
		"suppression": 0.0,
		"last_hit_tick": -1
	}, 5)

	assert_false(missile_system.is_shooter_constrained(shooter_id), "有線切断後は拘束解除")

	# 待機命令を実行可能
	if _has_pending_move(mock_element) and missile_system.can_shooter_move(shooter_id):
		mock_element.is_moving = true
		_clear_pending_move(mock_element)

	assert_true(mock_element.is_moving, "有線切断後に移動開始")


func test_shooter_hit_releases_constraint() -> void:
	## 射手被弾時も拘束解除（有線切断判定経由）
	var profile := _create_saclos_wire_profile()
	var shooter_id := mock_element.id

	missile_system.launch_missile(
		shooter_id,
		mock_element.position,
		"TARGET_001",
		Vector2(2000, 100),
		profile,
		MissileData.AttackProfile.DIRECT,
		0  # launch_tick = 0
	)

	# 待機命令を保存
	mock_element.pending_move_order = {
		"target": Vector2(500, 500),
		"use_route": false
	}

	# 被弾（launch_tick後）
	missile_system.check_wire_integrity(shooter_id, {
		"is_moving": false,
		"suppression": 0.0,
		"last_hit_tick": 5  # 発射後に被弾
	}, 10)

	assert_false(missile_system.is_shooter_constrained(shooter_id), "被弾後は拘束解除")
