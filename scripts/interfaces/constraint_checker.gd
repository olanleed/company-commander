class_name IConstraintChecker
extends RefCounted

## IConstraintChecker - 移動・射撃制約チェッカーインターフェース
## フェーズ3: システム依存の整理
##
## 責務:
## - ユニットの移動/射撃可否を判定
## - 制約理由を提供
##
## 実装クラス:
## - MissileSystem (SACLOS射手拘束)
## - 将来的に他のシステムも実装可能

# =============================================================================
# インターフェースメソッド（サブクラスでオーバーライド）
# =============================================================================

## ユニットが移動可能かチェック
## @param element_id: チェック対象のユニットID
## @return: 移動可能ならtrue
func can_move(element_id: String) -> bool:
	# デフォルト実装: 常に許可
	return true


## ユニットが射撃可能かチェック
## @param element_id: チェック対象のユニットID
## @return: 射撃可能ならtrue
func can_fire(element_id: String) -> bool:
	# デフォルト実装: 常に許可
	return true


## 制約理由を取得
## @param element_id: チェック対象のユニットID
## @return: 制約理由（制約がなければ空文字）
func get_constraint_reason(element_id: String) -> String:
	# デフォルト実装: 制約なし
	return ""
