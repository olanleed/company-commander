class_name DataLinkSystem
extends RefCounted

## データリンク（C4I）システム
## 仕様:
## - LINKED: 通信ハブ範囲内、リアルタイム情報共有
## - DEGRADED: 劣化（将来実装、現在は未使用）
## - ISOLATED: 孤立、自分の視界のみ
##
## 通信ハブ（is_comm_hub=true）の範囲内にいるユニットはLINKED状態
## 範囲外のユニットはISOLATED状態
## LINKEDユニット間ではContactデータを共有


## 通信状態を更新
## 全ユニットのcomm_stateとcomm_hub_idを更新
func update_comm_states(elements: Array[ElementData.ElementInstance]) -> void:
	# 陣営ごとに処理
	var by_faction: Dictionary = {}
	for element in elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue
		var faction := element.faction
		if not by_faction.has(faction):
			by_faction[faction] = []
		by_faction[faction].append(element)

	for faction in by_faction:
		_update_faction_comm_states(by_faction[faction])


## 陣営内の通信状態を更新
func _update_faction_comm_states(faction_elements: Array) -> void:
	# 通信ハブを見つける
	var hubs: Array = []
	for element in faction_elements:
		if element.element_type and element.element_type.is_comm_hub:
			hubs.append(element)

	# 各ユニットの通信状態を判定
	for element in faction_elements:
		element.comm_state = GameEnums.CommState.ISOLATED
		element.comm_hub_id = ""

		# ハブ自身はLINKED
		if element.element_type and element.element_type.is_comm_hub:
			element.comm_state = GameEnums.CommState.LINKED
			element.comm_hub_id = element.id
			continue

		# 最も近いハブとの距離を確認
		for i in range(hubs.size()):
			var hub: ElementData.ElementInstance = hubs[i]
			var dist: float = element.position.distance_to(hub.position)
			if dist <= hub.element_type.comm_range:
				element.comm_state = GameEnums.CommState.LINKED
				element.comm_hub_id = hub.id
				break  # 最初に見つかったハブに接続


## 指定ユニットがデータリンクでContact情報を受け取れるか
func can_receive_contacts(element: ElementData.ElementInstance) -> bool:
	return element.comm_state == GameEnums.CommState.LINKED


## 同じ陣営でLINKED状態のユニット一覧を取得
func get_linked_elements(faction: GameEnums.Faction,
						  elements: Array[ElementData.ElementInstance]) -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []
	for element in elements:
		if element.faction == faction and element.comm_state == GameEnums.CommState.LINKED:
			if element.state != GameEnums.UnitState.DESTROYED:
				result.append(element)
	return result


## ハブのない陣営（現状のテスト用）では全員LINKEDとして扱う
## 本番ではハブがいないと孤立状態になる
func update_comm_states_no_hub_fallback(elements: Array[ElementData.ElementInstance]) -> void:
	var by_faction: Dictionary = {}
	for element in elements:
		if element.state == GameEnums.UnitState.DESTROYED:
			continue
		var faction := element.faction
		if not by_faction.has(faction):
			by_faction[faction] = []
		by_faction[faction].append(element)

	for faction in by_faction:
		var faction_elements: Array = by_faction[faction]

		# ハブがいるか確認
		var has_hub := false
		for element in faction_elements:
			if element.element_type and element.element_type.is_comm_hub:
				has_hub = true
				break

		if has_hub:
			# ハブがいれば通常処理
			_update_faction_comm_states(faction_elements)
		else:
			# ハブがいなければ全員LINKED（後方互換）
			for element in faction_elements:
				element.comm_state = GameEnums.CommState.LINKED
				element.comm_hub_id = ""
