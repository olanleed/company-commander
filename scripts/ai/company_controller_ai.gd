class_name CompanyControllerAI
extends RefCounted

## 中隊AI コントローラ
## 仕様書: docs/company_ai_v0.1.md
##
## 責務:
## - プレイヤー命令を戦術テンプレートに変換
## - 配下ElementへのOrderBatch生成
## - AIの更新サイクル管理（10Hz/2Hz/1Hz/0.2Hz）

# =============================================================================
# シグナル
# =============================================================================

signal template_changed(old_type: GameEnums.TacticalTemplate, new_type: GameEnums.TacticalTemplate)
signal combat_state_changed(old_state: GameEnums.CombatState, new_state: GameEnums.CombatState)
signal order_issued(element_id: String, order: Dictionary)

# =============================================================================
# プロパティ
# =============================================================================

var company_id: String = ""
var faction: GameEnums.Faction = GameEnums.Faction.NONE

## 現在の戦術テンプレート
var current_template: TacticalTemplate = null
var current_template_type: GameEnums.TacticalTemplate = GameEnums.TacticalTemplate.TPL_NONE

## 戦闘状態
var combat_state: GameEnums.CombatState = GameEnums.CombatState.QUIET

## 配下要素
var element_ids: Array[String] = []

## 更新タイミング管理
var _last_contact_eval_tick: int = 0
var _last_tactical_eval_tick: int = 0
var _last_operational_eval_tick: int = 0

## 戦闘終息タイマー
var _combat_clear_timer_ticks: int = 0

# =============================================================================
# 依存
# =============================================================================

var _world_model: WorldModel
var _map_data: MapData
var _vision_system: VisionSystem
var _risk_assessment: RiskAssessment
var _movement_system: MovementSystem
var _event_bus: CombatEventBus

## テンプレートインスタンス（キャッシュ）
var _template_cache: Dictionary = {}

# =============================================================================
# 初期化
# =============================================================================

func _init(id: String = "") -> void:
	company_id = id if not id.is_empty() else _generate_id()


func setup(
	world_model: WorldModel,
	map_data: MapData,
	vision_system: VisionSystem,
	movement_system: MovementSystem,
	event_bus: CombatEventBus = null
) -> void:
	_world_model = world_model
	_map_data = map_data
	_vision_system = vision_system
	_movement_system = movement_system
	_event_bus = event_bus if event_bus else CombatEventBus.new()

	# RiskAssessment をセットアップ
	_risk_assessment = RiskAssessment.new()
	_risk_assessment.setup(_vision_system, _map_data, _world_model)

	# イベントバス接続
	_event_bus.event_emitted.connect(_on_combat_event)


## 要素を追加
func add_element(element_id: String) -> void:
	if element_id not in element_ids:
		element_ids.append(element_id)


## 要素を削除
func remove_element(element_id: String) -> void:
	element_ids.erase(element_id)


## 全要素を設定
func set_elements(ids: Array[String]) -> void:
	element_ids = ids.duplicate()

# =============================================================================
# 命令受信（CompanyIntent）
# =============================================================================

## 移動命令
func order_move(target_pos: Vector2, use_road: bool = false) -> void:
	_activate_template(GameEnums.TacticalTemplate.TPL_MOVE, target_pos, "", {"use_road": use_road})


## 拠点攻撃命令
func order_attack_cp(cp_id: String) -> void:
	var cp := _get_capture_point(cp_id)
	if cp:
		_activate_template(GameEnums.TacticalTemplate.TPL_ATTACK_CP, cp.position, cp_id)
	else:
		push_warning("CompanyAI: CP not found: " + cp_id)


## 拠点防御命令
func order_defend_cp(cp_id: String) -> void:
	var cp := _get_capture_point(cp_id)
	if cp:
		_activate_template(GameEnums.TacticalTemplate.TPL_DEFEND_CP, cp.position, cp_id)
	else:
		push_warning("CompanyAI: CP not found: " + cp_id)


## 偵察命令
func order_recon(target_pos: Vector2) -> void:
	_activate_template(GameEnums.TacticalTemplate.TPL_RECON, target_pos)


## 接触離脱命令
func order_break_contact(rally_point: Vector2 = Vector2.ZERO) -> void:
	_activate_template(GameEnums.TacticalTemplate.TPL_BREAK_CONTACT, rally_point)


## 停止命令
func order_hold() -> void:
	_stop_current_template()

	var current_tick := _get_current_tick()
	for element in _get_elements():
		element.current_order_type = GameEnums.OrderType.HOLD
		element.current_path.clear()
		element.is_moving = false

# =============================================================================
# AI更新サイクル
# =============================================================================

## 毎tick更新（10Hz）- 安全系、タイマー
func update_micro(current_tick: int, dt: float) -> void:
	# 戦闘状態タイマー更新
	_update_combat_state_timer(current_tick)

	# テンプレートの毎tick更新
	if current_template and current_template.is_active:
		current_template.update_micro(current_tick, dt)


## 接触評価（2Hz / 5tick）
func update_contact_eval(current_tick: int) -> void:
	if current_tick - _last_contact_eval_tick < GameConstants.AI_CONTACT_EVAL_TICKS:
		return
	_last_contact_eval_tick = current_tick

	# 接触状況を評価
	_evaluate_contacts(current_tick)

	# テンプレートの接触評価
	if current_template and current_template.is_active:
		current_template.update_contact_eval(current_tick)


## 戦術評価（1Hz / 10tick）
func update_tactical(current_tick: int) -> void:
	if current_tick - _last_tactical_eval_tick < GameConstants.AI_TACTICAL_EVAL_TICKS:
		return
	_last_tactical_eval_tick = current_tick

	# テンプレートの戦術評価
	if current_template and current_template.is_active:
		current_template.update_tactical(current_tick)


## 大局評価（0.2Hz / 50tick）
func update_operational(current_tick: int) -> void:
	if current_tick - _last_operational_eval_tick < GameConstants.AI_OPERATIONAL_EVAL_TICKS:
		return
	_last_operational_eval_tick = current_tick

	# 補給判断、再編判断（v0.1では簡易）
	_evaluate_operational(current_tick)

# =============================================================================
# テンプレート管理
# =============================================================================

func _activate_template(
	template_type: GameEnums.TacticalTemplate,
	target_pos: Vector2 = Vector2.ZERO,
	cp_id: String = "",
	options: Dictionary = {}
) -> void:
	var current_tick := _get_current_tick()
	var old_type := current_template_type

	# 現在のテンプレートを停止
	_stop_current_template()

	# テンプレート取得または作成
	current_template = _get_or_create_template(template_type)
	current_template_type = template_type

	# テンプレートにオプションを設定
	if options.has("use_road") and current_template is TemplateMove:
		(current_template as TemplateMove).use_road_priority = options["use_road"]

	# テンプレート開始
	var elements := _get_elements()
	current_template.start(current_tick, elements, target_pos, cp_id)

	# デバッグ出力
	var faction_name := "BLUE" if faction == GameEnums.Faction.BLUE else "RED"
	var template_name := _get_template_name(template_type)
	print("[CompanyAI] %s: Template activated -> %s (cp=%s, pos=%s, elements=%d)" % [
		faction_name, template_name, cp_id, target_pos, elements.size()
	])

	# シグナル
	template_changed.emit(old_type, template_type)


func _get_template_name(tpl: GameEnums.TacticalTemplate) -> String:
	match tpl:
		GameEnums.TacticalTemplate.TPL_NONE: return "NONE"
		GameEnums.TacticalTemplate.TPL_MOVE: return "MOVE"
		GameEnums.TacticalTemplate.TPL_ATTACK_CP: return "ATTACK_CP"
		GameEnums.TacticalTemplate.TPL_DEFEND_CP: return "DEFEND_CP"
		GameEnums.TacticalTemplate.TPL_RECON: return "RECON"
		GameEnums.TacticalTemplate.TPL_ATTACK_AREA: return "ATTACK_AREA"
		GameEnums.TacticalTemplate.TPL_BREAK_CONTACT: return "BREAK_CONTACT"
		GameEnums.TacticalTemplate.TPL_RESUPPLY: return "RESUPPLY"
		_: return "UNKNOWN"


func _stop_current_template() -> void:
	if current_template:
		current_template.stop()
		current_template = null
	current_template_type = GameEnums.TacticalTemplate.TPL_NONE


func _get_or_create_template(template_type: GameEnums.TacticalTemplate) -> TacticalTemplate:
	if template_type in _template_cache:
		return _template_cache[template_type]

	var template: TacticalTemplate = null

	match template_type:
		GameEnums.TacticalTemplate.TPL_MOVE:
			template = TemplateMove.new()
		GameEnums.TacticalTemplate.TPL_ATTACK_CP:
			template = TemplateAttackCP.new()
		GameEnums.TacticalTemplate.TPL_DEFEND_CP:
			template = TemplateDefendCP.new()
		GameEnums.TacticalTemplate.TPL_RECON:
			template = TemplateRecon.new()
		GameEnums.TacticalTemplate.TPL_BREAK_CONTACT:
			template = TemplateBreakContact.new()
		_:
			# デフォルトは基底クラス
			template = TacticalTemplate.new()

	# セットアップ
	template.setup(
		self,
		_world_model,
		_map_data,
		_vision_system,
		_risk_assessment,
		_movement_system,
		_event_bus
	)

	# シグナル接続
	template.order_generated.connect(_on_template_order_generated)
	template.template_completed.connect(_on_template_completed)

	_template_cache[template_type] = template
	return template

# =============================================================================
# 接触評価
# =============================================================================

func _evaluate_contacts(current_tick: int) -> void:
	if not _vision_system:
		return

	var contacts := _vision_system.get_contacts_for_faction(faction)

	var has_conf_contact := false
	var has_sus_contact := false
	var nearest_conf_dist := INF

	# 自中隊の中心位置を計算
	var elements := _get_elements()
	if elements.size() == 0:
		return

	var center := Vector2.ZERO
	for element in elements:
		center += element.position
	center /= elements.size()

	# 接触を分析
	for contact in contacts:
		match contact.state:
			GameEnums.ContactState.CONFIRMED:
				has_conf_contact = true
				var dist := center.distance_to(contact.pos_est_m)
				if dist < nearest_conf_dist:
					nearest_conf_dist = dist
			GameEnums.ContactState.SUSPECTED:
				has_sus_contact = true

	# 戦闘状態を更新
	var new_state := combat_state

	if has_conf_contact and nearest_conf_dist <= GameConstants.CONTACT_NEAR_M:
		new_state = GameEnums.CombatState.ENGAGED
		_combat_clear_timer_ticks = 0
	elif has_conf_contact:
		new_state = GameEnums.CombatState.ALERT
		_combat_clear_timer_ticks = 0
	elif has_sus_contact:
		if combat_state == GameEnums.CombatState.ENGAGED:
			new_state = GameEnums.CombatState.ALERT
		elif combat_state == GameEnums.CombatState.QUIET:
			new_state = GameEnums.CombatState.ALERT
		_combat_clear_timer_ticks = 0

	if new_state != combat_state:
		_set_combat_state(new_state, current_tick)


func _update_combat_state_timer(current_tick: int) -> void:
	if combat_state == GameEnums.CombatState.QUIET:
		return

	# 脅威がなければカウント
	if not _has_active_threats():
		_combat_clear_timer_ticks += 1

		if combat_state == GameEnums.CombatState.ENGAGED:
			if _combat_clear_timer_ticks >= GameConstants.COMBAT_RECOVERY_TICKS:
				_set_combat_state(GameEnums.CombatState.RECOVERING, current_tick)
		elif combat_state == GameEnums.CombatState.RECOVERING:
			if _combat_clear_timer_ticks >= GameConstants.COMBAT_CLEAR_TIMEOUT_TICKS:
				_set_combat_state(GameEnums.CombatState.QUIET, current_tick)
		elif combat_state == GameEnums.CombatState.ALERT:
			if _combat_clear_timer_ticks >= GameConstants.COMBAT_CLEAR_TIMEOUT_TICKS:
				_set_combat_state(GameEnums.CombatState.QUIET, current_tick)


func _has_active_threats() -> bool:
	if not _vision_system:
		return false

	var contacts := _vision_system.get_contacts_for_faction(faction)
	for contact in contacts:
		if contact.state in [GameEnums.ContactState.CONFIRMED, GameEnums.ContactState.SUSPECTED]:
			return true
	return false


func _set_combat_state(new_state: GameEnums.CombatState, current_tick: int) -> void:
	var old_state := combat_state
	combat_state = new_state

	if _event_bus and element_ids.size() > 0:
		_event_bus.emit_combat_state_changed(faction, current_tick, element_ids[0], old_state, new_state)

	combat_state_changed.emit(old_state, new_state)

# =============================================================================
# 大局評価
# =============================================================================

func _evaluate_operational(_current_tick: int) -> void:
	# v0.1 では簡易的な実装
	# - 補給判断
	# - 再編判断

	var elements := _get_elements()
	if elements.size() == 0:
		return

	# 平均suppression をチェック
	var avg_suppression := 0.0
	var total_strength := 0.0
	var max_strength := 0.0

	for element in elements:
		avg_suppression += element.suppression
		total_strength += element.current_strength
		max_strength += element.element_type.max_strength if element.element_type else 10

	avg_suppression /= elements.size()

	# 危機的状況: 平均 suppression >= 70 or strength < 60%
	var strength_ratio := total_strength / max_strength if max_strength > 0 else 1.0

	if avg_suppression >= 0.7 or strength_ratio < 0.6:
		# BreakContact を検討（現在のテンプレートがDefendならReposition）
		if current_template_type == GameEnums.TacticalTemplate.TPL_DEFEND_CP:
			# Repositionフェーズへ遷移（テンプレート内で処理）
			pass

# =============================================================================
# イベントハンドラ
# =============================================================================

func _on_combat_event(event: CombatEventBus.CombatEvent) -> void:
	# 自陣営のイベントのみ処理
	if event.team != faction:
		return

	# イベント種別に応じた処理
	match event.type:
		GameEnums.CombatEventType.EV_CONTACT_CONF_ACQUIRED:
			# 確定接触を得た
			pass
		GameEnums.CombatEventType.EV_UNDER_FIRE:
			# 被弾した
			pass
		GameEnums.CombatEventType.EV_CASUALTY_TAKEN:
			# 損耗発生
			pass


func _on_template_order_generated(element_id: String, order: Dictionary) -> void:
	order_issued.emit(element_id, order)


func _on_template_completed() -> void:
	# テンプレート完了後は HOLD
	_stop_current_template()

# =============================================================================
# ヘルパー
# =============================================================================

func _get_elements() -> Array[ElementData.ElementInstance]:
	var result: Array[ElementData.ElementInstance] = []

	if not _world_model:
		return result

	for element_id in element_ids:
		var element := _world_model.get_element_by_id(element_id)
		if element:
			result.append(element)

	return result


func _get_capture_point(cp_id: String) -> MapData.CapturePoint:
	if not _map_data:
		return null

	for cp in _map_data.capture_points:
		if cp.id == cp_id:
			return cp

	return null


func _get_current_tick() -> int:
	# SimRunnerから取得する想定だが、外部から渡す必要がある
	# v0.1 では update 関数で渡される tick を使用
	return 0


func _generate_id() -> String:
	return "company_%d" % randi()

# =============================================================================
# クエリ
# =============================================================================

## 現在のテンプレートタイプを取得
func get_current_template_type() -> GameEnums.TacticalTemplate:
	return current_template_type


## 現在のフェーズを取得
func get_current_phase() -> int:
	if current_template:
		return current_template.current_phase
	return 0


## 現在の戦闘状態を取得
func get_combat_state() -> GameEnums.CombatState:
	return combat_state


## 要素の役割を取得
func get_element_role(element_id: String) -> GameEnums.ElementRole:
	if current_template and element_id in current_template.element_roles:
		return current_template.element_roles[element_id]
	return GameEnums.ElementRole.ASSAULT


## リスク評価を取得
func get_risk_at_position(pos: Vector2, category: ElementData.Category = ElementData.Category.INF, mobility: GameEnums.MobilityType = GameEnums.MobilityType.FOOT) -> RiskAssessment.RiskReport:
	if _risk_assessment:
		return _risk_assessment.evaluate_point_risk(pos, faction, category, mobility)
	return RiskAssessment.RiskReport.new()


## イベントバスを取得
func get_event_bus() -> CombatEventBus:
	return _event_bus
