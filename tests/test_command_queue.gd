extends GutTest

## CommandQueueのテスト
## フェーズ5: コマンドパターン導入

var CommandQueueClass: GDScript
var MoveCommandClass: GDScript
var HaltCommandClass: GDScript
var WorldModelClass: GDScript
var ElementFactoryClass: GDScript


func before_all() -> void:
	CommandQueueClass = load("res://scripts/commands/command_queue.gd")
	MoveCommandClass = load("res://scripts/commands/move_command.gd")
	HaltCommandClass = load("res://scripts/commands/halt_command.gd")
	WorldModelClass = load("res://scripts/core/world_model.gd")
	ElementFactoryClass = load("res://scripts/data/element_factory.gd")


# =============================================================================
# 存在テスト
# =============================================================================

func test_command_queue_class_exists() -> void:
	assert_not_null(CommandQueueClass, "CommandQueue class should exist")


func test_command_queue_can_be_instantiated() -> void:
	var queue = CommandQueueClass.new()
	assert_not_null(queue, "CommandQueue should be instantiable")


# =============================================================================
# シグナルテスト
# =============================================================================

func test_has_command_executed_signal() -> void:
	var queue = CommandQueueClass.new()
	assert_true(queue.has_signal("command_executed"), "Should have command_executed signal")


func test_has_command_undone_signal() -> void:
	var queue = CommandQueueClass.new()
	assert_true(queue.has_signal("command_undone"), "Should have command_undone signal")


func test_has_queue_changed_signal() -> void:
	var queue = CommandQueueClass.new()
	assert_true(queue.has_signal("queue_changed"), "Should have queue_changed signal")


# =============================================================================
# enqueue テスト
# =============================================================================

func test_enqueue_adds_command_to_pending() -> void:
	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100))

	queue.enqueue(cmd)

	assert_eq(queue.get_pending_count(), 1, "Pending count should be 1")


func test_enqueue_emits_queue_changed() -> void:
	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = ["test_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(100, 100))

	watch_signals(queue)
	queue.enqueue(cmd)

	assert_signal_emitted(queue, "queue_changed", "queue_changed should be emitted")


# =============================================================================
# process テスト
# =============================================================================

func test_process_executes_pending_commands() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	queue.enqueue(cmd)
	var processed = queue.process(world_model)

	assert_eq(processed, 1, "Should process 1 command")
	assert_eq(queue.get_pending_count(), 0, "Pending should be empty")
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Element should have MOVE order")


func test_process_emits_command_executed() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	watch_signals(queue)
	queue.enqueue(cmd)
	queue.process(world_model)

	assert_signal_emitted(queue, "command_executed", "command_executed should be emitted")


func test_process_skips_invalid_commands() -> void:
	var world_model = WorldModelClass.new()
	# ユニットを追加しない（コマンドは無効になる）

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = ["nonexistent_id"]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	queue.enqueue(cmd)
	var processed = queue.process(world_model)

	assert_eq(processed, 0, "Should process 0 commands (invalid)")


func test_process_multiple_commands() -> void:
	var world_model = WorldModelClass.new()
	var element1 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var element2 = ElementFactoryClass.create_element_with_vehicle(
		"USA_M2A3_Bradley",
		GameEnums.Faction.BLUE,
		Vector2(200, 200)
	)
	world_model.add_element(element1)
	world_model.add_element(element2)

	var queue = CommandQueueClass.new()

	var ids1: Array[String] = [element1.id]
	var ids2: Array[String] = [element2.id]
	queue.enqueue(MoveCommandClass.new(ids1, Vector2(500, 500)))
	queue.enqueue(HaltCommandClass.new(ids2))

	var processed = queue.process(world_model)

	assert_eq(processed, 2, "Should process 2 commands")


# =============================================================================
# undo テスト
# =============================================================================

func test_undo_last_undoes_executed_command() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	element.current_order_type = GameEnums.OrderType.HOLD
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	queue.enqueue(cmd)
	queue.process(world_model)
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE, "Should be MOVE after execute")

	var undo_result = queue.undo_last(world_model)

	assert_true(undo_result, "undo_last should return true")
	assert_eq(element.current_order_type, GameEnums.OrderType.HOLD, "Should be restored to HOLD")


func test_undo_last_emits_command_undone() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500))

	queue.enqueue(cmd)
	queue.process(world_model)

	watch_signals(queue)
	queue.undo_last(world_model)

	assert_signal_emitted(queue, "command_undone", "command_undone should be emitted")


func test_undo_last_returns_false_when_empty() -> void:
	var world_model = WorldModelClass.new()
	var queue = CommandQueueClass.new()

	var result = queue.undo_last(world_model)

	assert_false(result, "undo_last should return false when no commands executed")


func test_can_undo_returns_true_after_execute() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	queue.enqueue(MoveCommandClass.new(element_ids, Vector2(500, 500)))
	queue.process(world_model)

	assert_true(queue.can_undo(), "can_undo should return true")


func test_can_undo_returns_false_when_empty() -> void:
	var queue = CommandQueueClass.new()

	assert_false(queue.can_undo(), "can_undo should return false when empty")


# =============================================================================
# 履歴テスト
# =============================================================================

func test_get_history_returns_executed_commands() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	var cmd1 = MoveCommandClass.new(element_ids, Vector2(500, 500))
	var cmd2 = HaltCommandClass.new(element_ids)

	queue.enqueue(cmd1)
	queue.enqueue(cmd2)
	queue.process(world_model)

	var history = queue.get_history()

	assert_eq(history.size(), 2, "History should have 2 commands")


func test_get_undo_description() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	queue.enqueue(MoveCommandClass.new(element_ids, Vector2(500, 300)))
	queue.process(world_model)

	var description = queue.get_undo_description()

	assert_true("500" in description, "Description should include destination")


func test_export_history() -> void:
	var world_model = WorldModelClass.new()
	var element = ElementFactoryClass.create_element_with_vehicle(
		"USA_M1A2_SEPv3",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = [element.id]
	queue.enqueue(MoveCommandClass.new(element_ids, Vector2(500, 500)))
	queue.process(world_model)

	var exported = queue.export_history()

	assert_eq(exported.size(), 1, "Should export 1 command")
	assert_true("destination" in exported[0], "Exported should contain destination")


# =============================================================================
# clear テスト
# =============================================================================

func test_clear_pending_removes_all_pending() -> void:
	var queue = CommandQueueClass.new()
	var element_ids: Array[String] = ["test_id"]
	queue.enqueue(MoveCommandClass.new(element_ids, Vector2(100, 100)))
	queue.enqueue(MoveCommandClass.new(element_ids, Vector2(200, 200)))

	queue.clear_pending()

	assert_eq(queue.get_pending_count(), 0, "Pending should be empty")
