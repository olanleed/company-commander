extends GutTest

## コマンドUndo機能のテスト
## 選択ユニット対応Undoの検証

var WorldModelClass: GDScript
var CommandQueueClass: GDScript
var MoveCommandClass: GDScript
var HaltCommandClass: GDScript
var FireMissionCommandClass: GDScript

var world_model: WorldModel
var command_queue


func before_all() -> void:
	WorldModelClass = load("res://scripts/core/world_model.gd")
	CommandQueueClass = load("res://scripts/commands/command_queue.gd")
	MoveCommandClass = load("res://scripts/commands/move_command.gd")
	HaltCommandClass = load("res://scripts/commands/halt_command.gd")
	FireMissionCommandClass = load("res://scripts/commands/fire_mission_command.gd")


func before_each() -> void:
	world_model = WorldModelClass.new()
	command_queue = CommandQueueClass.new()
	ElementFactory.init_vehicle_catalog()
	ElementFactory.reset_id_counters()


# =============================================================================
# 基本Undoテスト
# =============================================================================

func test_undo_last_returns_false_when_empty() -> void:
	## 履歴が空の場合はfalseを返す
	assert_false(command_queue.undo_last(world_model),
		"undo_last should return false when history is empty")


func test_undo_last_undoes_last_command() -> void:
	## 最後に実行されたコマンドをUndoする
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	# MoveCommandを実行
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500), false)
	command_queue.enqueue(cmd)
	command_queue.process(world_model)

	# 移動命令が設定されていることを確認
	assert_eq(element.current_order_type, GameEnums.OrderType.MOVE,
		"Order should be MOVE after execute")

	# Undo
	assert_true(command_queue.undo_last(world_model),
		"undo_last should return true")

	# 元の状態に戻っていることを確認（HOLD）
	assert_eq(element.current_order_type, GameEnums.OrderType.HOLD,
		"Order should be HOLD after undo")


# =============================================================================
# 選択ユニット対応Undoテスト
# =============================================================================

func test_undo_for_elements_returns_false_when_empty() -> void:
	## 履歴が空の場合はfalseを返す
	var element_ids: Array[String] = ["test_id"]
	assert_false(command_queue.undo_for_elements(world_model, element_ids),
		"undo_for_elements should return false when history is empty")


func test_undo_for_elements_returns_false_when_no_match() -> void:
	## 対象エレメントに関連するコマンドがない場合はfalseを返す
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	# element_idとは異なるIDでコマンドを実行
	var other_ids: Array[String] = ["other_element_id"]
	var cmd = MoveCommandClass.new(other_ids, Vector2(500, 500), false)
	command_queue.enqueue(cmd)
	command_queue.process(world_model)

	# 対象外のエレメントIDでUndo
	var element_ids: Array[String] = [element.id]
	assert_false(command_queue.undo_for_elements(world_model, element_ids),
		"undo_for_elements should return false when no matching command")


func test_undo_for_elements_undoes_matching_command() -> void:
	## 対象エレメントに関連するコマンドをUndoする
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	# MoveCommandを実行
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500), false)
	command_queue.enqueue(cmd)
	command_queue.process(world_model)

	# Undo for elements
	assert_true(command_queue.undo_for_elements(world_model, element_ids),
		"undo_for_elements should return true")

	# 元の状態に戻っていることを確認
	assert_eq(element.current_order_type, GameEnums.OrderType.HOLD,
		"Order should be HOLD after undo")


func test_undo_for_elements_skips_unrelated_commands() -> void:
	## 異なるユニットのコマンドはスキップして、対象ユニットのコマンドをUndoする
	var tank := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var supply := ElementFactory.create_element_with_vehicle(
		"JPN_Type73_Supply",
		GameEnums.Faction.BLUE,
		Vector2(200, 200)
	)
	world_model.add_element(tank)
	world_model.add_element(supply)

	# 1. 戦車にMoveCommand
	var tank_ids: Array[String] = [tank.id]
	var tank_cmd = MoveCommandClass.new(tank_ids, Vector2(500, 500), false)
	command_queue.enqueue(tank_cmd)
	command_queue.process(world_model)

	# 2. 補給車にMoveCommand（後に実行）
	var supply_ids: Array[String] = [supply.id]
	var supply_cmd = MoveCommandClass.new(supply_ids, Vector2(600, 600), false)
	command_queue.enqueue(supply_cmd)
	command_queue.process(world_model)

	# 両方とも移動中であることを確認
	assert_eq(tank.current_order_type, GameEnums.OrderType.MOVE,
		"Tank should be MOVE")
	assert_eq(supply.current_order_type, GameEnums.OrderType.MOVE,
		"Supply should be MOVE")

	# 戦車を選択してUndo → 戦車のコマンドのみがUndoされる
	assert_true(command_queue.undo_for_elements(world_model, tank_ids),
		"undo_for_elements should return true for tank")

	# 戦車はUndoされる、補給車はそのまま
	assert_eq(tank.current_order_type, GameEnums.OrderType.HOLD,
		"Tank should be HOLD after undo")
	assert_eq(supply.current_order_type, GameEnums.OrderType.MOVE,
		"Supply should still be MOVE (not undone)")


func test_undo_for_elements_finds_oldest_matching_when_newer_exists() -> void:
	## 複数コマンドがある場合、対象ユニットの最新コマンドをUndoする
	var artillery := ElementFactory.create_element_with_vehicle(
		"USA_M109A7_Paladin",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var supply := ElementFactory.create_element_with_vehicle(
		"JPN_Type73_Supply",
		GameEnums.Faction.BLUE,
		Vector2(200, 200)
	)
	world_model.add_element(artillery)
	world_model.add_element(supply)

	# 1. 砲兵にFireMissionCommand
	var arty_ids: Array[String] = [artillery.id]
	var arty_cmd = FireMissionCommandClass.new(arty_ids, Vector2(1000, 1000))
	command_queue.enqueue(arty_cmd)
	command_queue.process(world_model)

	# 2. 補給車にMoveCommand（後に実行）
	var supply_ids: Array[String] = [supply.id]
	var supply_cmd = MoveCommandClass.new(supply_ids, Vector2(600, 600), false)
	command_queue.enqueue(supply_cmd)
	command_queue.process(world_model)

	# 3. 補給車にさらにHaltCommand（最後に実行）
	var halt_cmd = HaltCommandClass.new(supply_ids)
	command_queue.enqueue(halt_cmd)
	command_queue.process(world_model)

	# 砲兵を選択してUndo
	assert_true(command_queue.undo_for_elements(world_model, arty_ids),
		"undo_for_elements should return true for artillery")

	# 砲兵のFireMissionがUndoされる
	assert_eq(artillery.current_order_type, GameEnums.OrderType.HOLD,
		"Artillery should be HOLD after undo (was FIRE_MISSION)")

	# 補給車は影響を受けない
	assert_eq(supply.current_order_type, GameEnums.OrderType.HOLD,
		"Supply should still be HOLD (halt command not undone)")


# =============================================================================
# コマンド履歴整合性テスト
# =============================================================================

func test_undo_for_elements_removes_command_from_history() -> void:
	## Undoされたコマンドは履歴から削除される
	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	# コマンドを実行
	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500), false)
	command_queue.enqueue(cmd)
	command_queue.process(world_model)

	var history_before: Array = command_queue.get_history()
	assert_eq(history_before.size(), 1, "History should have 1 command")

	# Undo
	command_queue.undo_for_elements(world_model, element_ids)

	var history_after: Array = command_queue.get_history()
	assert_eq(history_after.size(), 0, "History should be empty after undo")


func test_can_undo_returns_correct_state() -> void:
	## can_undoが正しい状態を返す
	assert_false(command_queue.can_undo(), "can_undo should be false initially")

	var element := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	world_model.add_element(element)

	var element_ids: Array[String] = [element.id]
	var cmd = MoveCommandClass.new(element_ids, Vector2(500, 500), false)
	command_queue.enqueue(cmd)
	command_queue.process(world_model)

	assert_true(command_queue.can_undo(), "can_undo should be true after execute")

	command_queue.undo_last(world_model)

	assert_false(command_queue.can_undo(), "can_undo should be false after undo")


# =============================================================================
# 複数ユニット選択時のテスト
# =============================================================================

func test_undo_for_elements_with_multiple_selected() -> void:
	## 複数ユニットを選択している場合、いずれかに関連するコマンドをUndoする
	var tank1 := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(100, 100)
	)
	var tank2 := ElementFactory.create_element_with_vehicle(
		"JPN_Type10",
		GameEnums.Faction.BLUE,
		Vector2(150, 100)
	)
	var supply := ElementFactory.create_element_with_vehicle(
		"JPN_Type73_Supply",
		GameEnums.Faction.BLUE,
		Vector2(200, 200)
	)
	world_model.add_element(tank1)
	world_model.add_element(tank2)
	world_model.add_element(supply)

	# 戦車2台に移動命令
	var tank_ids: Array[String] = [tank1.id, tank2.id]
	var tank_cmd = MoveCommandClass.new(tank_ids, Vector2(500, 500), false)
	command_queue.enqueue(tank_cmd)
	command_queue.process(world_model)

	# 補給車に移動命令（後に実行）
	var supply_ids: Array[String] = [supply.id]
	var supply_cmd = MoveCommandClass.new(supply_ids, Vector2(600, 600), false)
	command_queue.enqueue(supply_cmd)
	command_queue.process(world_model)

	# 戦車1だけを選択してUndo
	var selected_ids: Array[String] = [tank1.id]
	assert_true(command_queue.undo_for_elements(world_model, selected_ids),
		"undo_for_elements should return true")

	# 戦車1と戦車2の両方がUndoされる（同じコマンドだったため）
	assert_eq(tank1.current_order_type, GameEnums.OrderType.HOLD,
		"Tank1 should be HOLD after undo")
	assert_eq(tank2.current_order_type, GameEnums.OrderType.HOLD,
		"Tank2 should also be HOLD (same command)")

	# 補給車は影響を受けない
	assert_eq(supply.current_order_type, GameEnums.OrderType.MOVE,
		"Supply should still be MOVE")
