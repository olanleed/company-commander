class_name Command
extends RefCounted

## Command ベースクラス
## フェーズ5: コマンドパターン導入
##
## 責務:
## - 命令をオブジェクトとしてカプセル化
## - 実行・取り消し・検証のインターフェースを提供
## - シリアライズ（リプレイ用）
##
## サブクラス:
## - MoveCommand: 移動命令
## - AttackCommand: 攻撃命令
## - HaltCommand: 停止命令
## - DefendCommand: 防御命令

# =============================================================================
# 状態
# =============================================================================

var _timestamp: int = 0
var _element_ids: Array[String] = []
var _executed: bool = false

# =============================================================================
# 公開メソッド
# =============================================================================

## 命令を実行
## @param world_model: ワールドモデル
## @return: 実行成功ならtrue
func execute(world_model: WorldModel) -> bool:
	# サブクラスでオーバーライド
	push_warning("Command.execute() should be overridden")
	return false


## 命令を取り消し
## @param world_model: ワールドモデル
## @return: 取り消し成功ならtrue
func undo(world_model: WorldModel) -> bool:
	# サブクラスでオーバーライド
	push_warning("Command.undo() should be overridden")
	return false


## 命令が有効かチェック
## @param world_model: ワールドモデル
## @return: 有効ならtrue
func is_valid(world_model: WorldModel) -> bool:
	# 全ての対象ユニットが存在するかチェック
	for element_id in _element_ids:
		if not world_model.get_element_by_id(element_id):
			return false
	return true


## 命令の説明を取得（UI表示用）
## @return: 説明文字列
func get_description() -> String:
	return "Unknown Command"


## タイムスタンプを取得
func get_timestamp() -> int:
	return _timestamp


## 対象ユニットIDを取得
func get_element_ids() -> Array[String]:
	return _element_ids


## 実行済みかチェック
func is_executed() -> bool:
	return _executed

# =============================================================================
# シリアライズ
# =============================================================================

## 辞書形式にシリアライズ（リプレイ用）
func to_dict() -> Dictionary:
	return {
		"type": get_script().get_global_name(),
		"timestamp": _timestamp,
		"element_ids": _element_ids
	}


## 辞書形式からデシリアライズ
static func from_dict(_data: Dictionary) -> Command:
	# サブクラスで実装
	push_warning("Command.from_dict() should be implemented in subclass")
	return null
