extends GutTest

## CombatVisualizerのユニットテスト
## DISCRETE/CONTINUOUS武器の射撃イベント管理をテスト

const CombatVisualizer := preload("res://scripts/ui/combat_visualizer.gd")
const WeaponData := preload("res://scripts/data/weapon_data.gd")
const GameEnums := preload("res://scripts/core/game_enums.gd")

var visualizer: CombatVisualizer


func before_each() -> void:
	visualizer = CombatVisualizer.new()
	# シーンツリーに追加（_ready呼び出しのため）
	add_child_autofree(visualizer)


# =============================================================================
# DISCRETE武器テスト（戦車砲、ATGM等）
# =============================================================================

func test_discrete_weapon_creates_new_event_each_time() -> void:
	# DISCRETE武器は同じターゲットへの射撃でも毎回新しいイベントを作成すべき
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0,
		0.5,
		true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	assert_eq(visualizer.get_active_fire_count(), 1, "最初の射撃でイベント1つ")

	# 同じshooter->targetで2回目の射撃
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0,
		0.5,
		true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	assert_eq(visualizer.get_active_fire_count(), 2, "DISCRETE武器は毎回新しいイベントを作成")


func test_discrete_weapon_draw_count_starts_at_zero() -> void:
	# DISCRETE武器の新しいイベントはdraw_count=0で開始すべき
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0,
		0.5,
		true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	# 内部状態を確認（_fire_eventsにアクセス）
	var events = visualizer._fire_events
	assert_eq(events.size(), 1, "イベントが1つ存在")
	assert_eq(events[0].draw_count, 0, "新しいイベントのdraw_countは0")


# =============================================================================
# CONTINUOUS武器テスト（機関銃等）
# =============================================================================

func test_continuous_weapon_updates_existing_event() -> void:
	# CONTINUOUS武器は同じターゲットへの射撃で既存イベントを更新すべき
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0,
		0.5,
		true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	assert_eq(visualizer.get_active_fire_count(), 1, "最初の射撃でイベント1つ")

	# 同じshooter->targetで2回目の射撃
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0,
		0.5,
		true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	assert_eq(visualizer.get_active_fire_count(), 1, "CONTINUOUS武器は既存イベントを更新")


func test_continuous_weapon_different_targets_create_separate_events() -> void:
	# 異なるターゲットへの射撃は別々のイベントを作成
	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0, 0.5, true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	visualizer.add_fire_event(
		"SHOOTER_001",
		"TARGET_002",
		Vector2(100, 100),
		Vector2(500, 200),
		GameEnums.Faction.BLUE,
		1.0, 0.5, true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	assert_eq(visualizer.get_active_fire_count(), 2, "異なるターゲットは別イベント")


# =============================================================================
# 陣営別色テスト
# =============================================================================

func test_blue_faction_event_has_correct_faction() -> void:
	visualizer.add_fire_event(
		"BLUE_SHOOTER",
		"RED_TARGET",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0, 0.5, true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	var events = visualizer._fire_events
	assert_eq(events[0].shooter_faction, GameEnums.Faction.BLUE, "BLUE陣営が正しく設定")


func test_red_faction_event_has_correct_faction() -> void:
	visualizer.add_fire_event(
		"RED_SHOOTER",
		"BLUE_TARGET",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.RED,
		1.0, 0.5, true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	var events = visualizer._fire_events
	assert_eq(events[0].shooter_faction, GameEnums.Faction.RED, "RED陣営が正しく設定")


# =============================================================================
# クリアテスト
# =============================================================================

func test_clear_all_removes_all_events() -> void:
	# 複数のイベントを追加
	for i in range(5):
		visualizer.add_fire_event(
			"SHOOTER_%d" % i,
			"TARGET_%d" % i,
			Vector2(100 * i, 100),
			Vector2(500, 100),
			GameEnums.Faction.BLUE,
			1.0, 0.5, true,
			WeaponData.Mechanism.KINETIC,
			WeaponData.FireModel.DISCRETE
		)

	assert_eq(visualizer.get_active_fire_count(), 5, "5つのイベントが存在")

	visualizer.clear_all()

	assert_eq(visualizer.get_active_fire_count(), 0, "クリア後はイベントなし")


# =============================================================================
# 混合テスト（DISCRETE + CONTINUOUS）
# =============================================================================

func test_mixed_fire_models() -> void:
	# DISCRETE射撃
	visualizer.add_fire_event(
		"TANK_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0, 0.5, true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	# CONTINUOUS射撃（同じターゲット）
	visualizer.add_fire_event(
		"MG_001",
		"TARGET_001",
		Vector2(150, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		0.5, 0.3, true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	assert_eq(visualizer.get_active_fire_count(), 2, "異なるshooterは別イベント")

	# DISCRETE射撃（同じshooter、同じtarget）
	visualizer.add_fire_event(
		"TANK_001",
		"TARGET_001",
		Vector2(100, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		1.0, 0.5, true,
		WeaponData.Mechanism.KINETIC,
		WeaponData.FireModel.DISCRETE
	)

	assert_eq(visualizer.get_active_fire_count(), 3, "DISCRETEは新規イベント追加")

	# CONTINUOUS射撃（同じshooter、同じtarget）→更新
	visualizer.add_fire_event(
		"MG_001",
		"TARGET_001",
		Vector2(150, 100),
		Vector2(500, 100),
		GameEnums.Faction.BLUE,
		0.5, 0.3, true,
		WeaponData.Mechanism.SMALL_ARMS,
		WeaponData.FireModel.CONTINUOUS
	)

	assert_eq(visualizer.get_active_fire_count(), 3, "CONTINUOUSは既存更新")
