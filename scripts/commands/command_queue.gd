class_name CommandQueue
extends RefCounted

## CommandQueue - コマンドキュー
## フェーズ5: コマンドパターン導入
##
## 責務:
## - コマンドのキューイング
## - バッチ実行（毎フレーム/Tick）
## - 実行履歴管理（Undo対応）
## - シリアライズ（リプレイ対応）

# =============================================================================
# シグナル
# =============================================================================

signal command_executed(command)
signal command_undone(command)
signal queue_changed()

# =============================================================================
# 状態
# =============================================================================

var _pending_commands: Array = []  # 実行待ちコマンド
var _executed_history: Array = []  # 実行済みコマンド（Undo用）

# =============================================================================
# キュー操作
# =============================================================================

## コマンドをキューに追加
func enqueue(command) -> void:
	_pending_commands.append(command)
	queue_changed.emit()


## 保留中のコマンド数を取得
func get_pending_count() -> int:
	return _pending_commands.size()


## 保留中のコマンドをすべてクリア
func clear_pending() -> void:
	_pending_commands.clear()
	queue_changed.emit()

# =============================================================================
# 実行
# =============================================================================

## 保留中のコマンドを実行
## @return 実行したコマンド数
func process(world_model: WorldModel) -> int:
	var executed_count := 0

	for command in _pending_commands:
		# 有効性チェック
		if not command.is_valid(world_model):
			continue

		# 実行
		if command.execute(world_model):
			_executed_history.append(command)
			command_executed.emit(command)
			executed_count += 1

	_pending_commands.clear()

	if executed_count > 0:
		queue_changed.emit()

	return executed_count

# =============================================================================
# Undo
# =============================================================================

## 最後のコマンドを取り消し
func undo_last(world_model: WorldModel) -> bool:
	if _executed_history.is_empty():
		return false

	var command = _executed_history.pop_back()
	var result = command.undo(world_model)

	if result:
		command_undone.emit(command)
		queue_changed.emit()

	return result


## Undo可能かどうか
func can_undo() -> bool:
	return not _executed_history.is_empty()


## Undo対象コマンドの説明を取得
func get_undo_description() -> String:
	if _executed_history.is_empty():
		return ""
	return _executed_history.back().get_description()

# =============================================================================
# 履歴
# =============================================================================

## 実行履歴を取得
func get_history() -> Array:
	return _executed_history.duplicate()


## 履歴をエクスポート（リプレイ用）
func export_history() -> Array:
	var result: Array = []
	for command in _executed_history:
		result.append(command.to_dict())
	return result
