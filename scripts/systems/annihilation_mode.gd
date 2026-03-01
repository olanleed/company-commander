class_name AnnihilationMode
extends RefCounted

## 殲滅戦ゲームモード
## ルール:
## 1. ポイントを消費してユニットを召喚できる
## 2. ポイントが早く尽きた方が負け（ユニット撃破でポイント減少）
## 3. 先に相手のHQを破壊した方が勝ち

# =============================================================================
# シグナル
# =============================================================================

signal game_ended(winner: GameEnums.Faction, reason: String)
signal points_changed(faction: GameEnums.Faction, new_points: int)
signal hq_destroyed(faction: GameEnums.Faction)
signal unit_spawned(element: ElementData.ElementInstance, cost: int)

# =============================================================================
# 定数
# =============================================================================

## 初期ポイント
const INITIAL_POINTS: int = 1000

## ユニット召喚コスト
const SPAWN_COSTS: Dictionary = {
	"INF_LINE": 100,    # 歩兵小隊（30人）
	"INF_AT": 80,       # 対戦車チーム
	"INF_MG": 60,       # MG班
	"TANK_PLT": 400,    # 戦車小隊（4両）
	"RECON_VEH": 150,   # 偵察車両
	"RECON_TEAM": 50,   # 偵察チーム
	"MORTAR_SEC": 120,  # 迫撃砲班
	"LOG_TRUCK": 40,    # 補給トラック
	"CMD_HQ": 0,        # HQは召喚不可（初期配置のみ）
}

## ユニット撃破時のポイント損失（コストの一部）
const LOSS_RATE: float = 0.5  # 撃破されるとコストの50%を失う

## 勝利理由
const REASON_HQ_DESTROYED: String = "HQ Destroyed"
const REASON_POINTS_EXHAUSTED: String = "Points Exhausted"
const REASON_TIME_LIMIT: String = "Time Limit"

# =============================================================================
# 状態
# =============================================================================

var _points: Dictionary = {
	GameEnums.Faction.BLUE: INITIAL_POINTS,
	GameEnums.Faction.RED: INITIAL_POINTS,
}

var _hq_ids: Dictionary = {
	GameEnums.Faction.BLUE: "",
	GameEnums.Faction.RED: "",
}

var _game_active: bool = true
var _world_model: WorldModel

# =============================================================================
# 初期化
# =============================================================================

func setup(world_model: WorldModel) -> void:
	_world_model = world_model
	_game_active = true

	# HQを探して登録
	_register_hqs()


func _register_hqs() -> void:
	if not _world_model:
		return

	for element in _world_model.elements:
		if element.element_type and element.element_type.is_comm_hub:
			_hq_ids[element.faction] = element.id
			print("[AnnihilationMode] Registered HQ: %s (%s)" % [
				element.id,
				"BLUE" if element.faction == GameEnums.Faction.BLUE else "RED"
			])

# =============================================================================
# 更新
# =============================================================================

func update(tick: int, dt: float) -> void:
	if not _game_active:
		return

	# HQ破壊チェック
	_check_hq_status()


func _check_hq_status() -> void:
	for faction in [GameEnums.Faction.BLUE, GameEnums.Faction.RED]:
		var hq_id: String = _hq_ids[faction]
		if hq_id.is_empty():
			continue

		var hq := _world_model.get_element_by_id(hq_id)
		if not hq:
			continue

		# HQが破壊されたか
		if hq.state == GameEnums.UnitState.DESTROYED or hq.current_strength <= 0:
			_on_hq_destroyed(faction)

# =============================================================================
# イベントハンドラ
# =============================================================================

## HQが破壊された
func _on_hq_destroyed(faction: GameEnums.Faction) -> void:
	if not _game_active:
		return

	_game_active = false
	hq_destroyed.emit(faction)

	# 相手が勝利
	var winner := GameEnums.Faction.RED if faction == GameEnums.Faction.BLUE else GameEnums.Faction.BLUE
	game_ended.emit(winner, REASON_HQ_DESTROYED)

	print("[AnnihilationMode] %s HQ destroyed! %s wins!" % [
		"BLUE" if faction == GameEnums.Faction.BLUE else "RED",
		"RED" if faction == GameEnums.Faction.BLUE else "BLUE"
	])


## ユニットが撃破された（外部から呼び出し）
func on_unit_destroyed(element: ElementData.ElementInstance) -> void:
	if not _game_active:
		return

	if not element.element_type:
		return

	# HQの場合は別処理
	if element.element_type.is_comm_hub:
		return  # _check_hq_statusで処理

	# ポイント損失を計算
	var archetype_id := element.element_type.id
	var cost: int = SPAWN_COSTS.get(archetype_id, 0)
	var loss := int(cost * LOSS_RATE)

	if loss > 0:
		_points[element.faction] -= loss
		points_changed.emit(element.faction, _points[element.faction])

		print("[AnnihilationMode] %s lost %d points (unit: %s)" % [
			"BLUE" if element.faction == GameEnums.Faction.BLUE else "RED",
			loss,
			archetype_id
		])

		# ポイント0以下でゲーム終了
		if _points[element.faction] <= 0:
			_on_points_exhausted(element.faction)


func _on_points_exhausted(faction: GameEnums.Faction) -> void:
	if not _game_active:
		return

	_game_active = false

	# 相手が勝利
	var winner := GameEnums.Faction.RED if faction == GameEnums.Faction.BLUE else GameEnums.Faction.BLUE
	game_ended.emit(winner, REASON_POINTS_EXHAUSTED)

	print("[AnnihilationMode] %s points exhausted! %s wins!" % [
		"BLUE" if faction == GameEnums.Faction.BLUE else "RED",
		"RED" if faction == GameEnums.Faction.BLUE else "BLUE"
	])

# =============================================================================
# ユニット召喚
# =============================================================================

## ユニットを召喚可能か
func can_spawn_unit(faction: GameEnums.Faction, archetype_id: String) -> bool:
	if not _game_active:
		return false

	var cost: int = SPAWN_COSTS.get(archetype_id, -1)
	if cost < 0:
		return false  # 不明なアーキタイプ
	if cost == 0:
		return false  # 召喚不可（HQ等）

	return _points[faction] >= cost


## ユニット召喚コストを取得
func get_spawn_cost(archetype_id: String) -> int:
	return SPAWN_COSTS.get(archetype_id, -1)


## ユニットを召喚（ポイント消費）
## 成功したらtrue、失敗したらfalse
func spend_points_for_spawn(faction: GameEnums.Faction, archetype_id: String) -> bool:
	if not can_spawn_unit(faction, archetype_id):
		return false

	var cost: int = SPAWN_COSTS[archetype_id]
	_points[faction] -= cost
	points_changed.emit(faction, _points[faction])

	print("[AnnihilationMode] %s spent %d points for %s (remaining: %d)" % [
		"BLUE" if faction == GameEnums.Faction.BLUE else "RED",
		cost,
		archetype_id,
		_points[faction]
	])

	return true

# =============================================================================
# 公開API
# =============================================================================

## 現在のポイントを取得
func get_points(faction: GameEnums.Faction) -> int:
	return _points.get(faction, 0)


## ゲームがアクティブか
func is_game_active() -> bool:
	return _game_active


## HQ IDを取得
func get_hq_id(faction: GameEnums.Faction) -> String:
	return _hq_ids.get(faction, "")


## 召喚可能なユニット一覧を取得
func get_spawnable_units(faction: GameEnums.Faction) -> Array[String]:
	var result: Array[String] = []
	for archetype_id in SPAWN_COSTS:
		if can_spawn_unit(faction, archetype_id):
			result.append(archetype_id)
	return result
