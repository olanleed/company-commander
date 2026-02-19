class_name RiskAssessment
extends RefCounted

## ルールベース・リスク評価システム
## 仕様書: docs/risk_assessment_v0.1.md
##
## 装甲脅威、AT脅威、OPEN横断コストを評価し、
## CompanyAIのテンプレート選択・フェーズ遷移・命令生成に使用

# =============================================================================
# RiskReport構造
# =============================================================================

class RiskReport:
	var risk_total: int = 0                      ## 総合リスク (0..100)
	var armor_threat: int = 0                    ## 装甲脅威 (0..100)
	var at_threat: int = 0                       ## AT脅威 (0..100)
	var open_exposure: int = 0                   ## OPEN横断コスト (0..100)
	var risk_flags: Array[GameEnums.RiskFlag] = []
	var recommended_mitigations: Array[GameEnums.Mitigation] = []
	var max_open_segment_m: float = 0.0          ## 最大OPEN連続長

	func has_flag(flag: GameEnums.RiskFlag) -> bool:
		return flag in risk_flags

	func add_flag(flag: GameEnums.RiskFlag) -> void:
		if flag not in risk_flags:
			risk_flags.append(flag)

	func add_mitigation(mit: GameEnums.Mitigation) -> void:
		if mit not in recommended_mitigations:
			recommended_mitigations.append(mit)

# =============================================================================
# 役割別重み（v0.1固定）
# =============================================================================

## 装甲脅威：役割別の危険度
const W_ARMOR_HEAVY: Dictionary = {
	ElementData.Category.INF: 70,
	ElementData.Category.REC: 80,
	ElementData.Category.VEH: 55,
	ElementData.Category.WEAP: 75,
	ElementData.Category.LOG: 90,
	ElementData.Category.HQ: 90,
}

const W_ARMOR_LIGHT: Dictionary = {
	ElementData.Category.INF: 40,
	ElementData.Category.REC: 50,
	ElementData.Category.VEH: 35,
	ElementData.Category.WEAP: 45,
	ElementData.Category.LOG: 60,
	ElementData.Category.HQ: 60,
}

## AT脅威（短距離）：役割別重み
const W_AT_SHORT: Dictionary = {
	ElementData.Category.VEH: 70,
	ElementData.Category.LOG: 85,
}

## AT脅威（長距離）：役割別重み
const W_AT_LONG: Dictionary = {
	ElementData.Category.VEH: 50,
	ElementData.Category.LOG: 70,
}

## OPEN横断：役割別重み
const W_OPEN: Dictionary = {
	GameEnums.MobilityType.FOOT: 35,
	GameEnums.MobilityType.WHEELED: 55,
	GameEnums.MobilityType.TRACKED: 55,
}

# =============================================================================
# 依存
# =============================================================================

var _vision_system: VisionSystem
var _map_data: MapData
var _world_model: WorldModel
var _current_tick: int = 0

## スムージング用の前回リスク値
var _smoothed_risks: Dictionary = {}  # element_id -> RiskReport

# =============================================================================
# 初期化
# =============================================================================

func setup(vision_system: VisionSystem, map_data: MapData, world_model: WorldModel) -> void:
	_vision_system = vision_system
	_map_data = map_data
	_world_model = world_model


func set_current_tick(tick: int) -> void:
	_current_tick = tick

# =============================================================================
# PointRisk評価
# =============================================================================

## 特定地点のリスクを評価
func evaluate_point_risk(
	pos: Vector2,
	evaluator_faction: GameEnums.Faction,
	evaluator_category: ElementData.Category,
	evaluator_mobility: GameEnums.MobilityType
) -> RiskReport:
	var report := RiskReport.new()

	# 装甲脅威の計算
	report.armor_threat = _calculate_armor_threat(pos, evaluator_faction, evaluator_category)

	# AT脅威の計算
	report.at_threat = _calculate_at_threat(pos, evaluator_faction, evaluator_category)

	# フラグ付与
	_apply_point_flags(report, pos, evaluator_faction)

	# 総合リスク（PointRiskはOPENなし）
	report.risk_total = clampi(maxi(report.armor_threat, report.at_threat), 0, 100)

	# ミティゲーション推奨
	_apply_mitigations(report, evaluator_category)

	return report

# =============================================================================
# RouteRisk評価
# =============================================================================

## 経路のリスクを評価
func evaluate_route_risk(
	path: PackedVector2Array,
	evaluator_faction: GameEnums.Faction,
	evaluator_category: ElementData.Category,
	evaluator_mobility: GameEnums.MobilityType,
	move_speed_mps: float = 5.0
) -> RiskReport:
	if path.size() < 2:
		return RiskReport.new()

	var report := RiskReport.new()

	# サンプリング
	var sample_points := _sample_path(path, GameConstants.RISK_SAMPLE_STEP_M)

	# 各サンプル点でPointRiskを計算
	var armor_values: Array[int] = []
	var at_values: Array[int] = []

	for sample_pos in sample_points:
		var point_report := evaluate_point_risk(sample_pos, evaluator_faction, evaluator_category, evaluator_mobility)
		armor_values.append(point_report.armor_threat)
		at_values.append(point_report.at_threat)

	# 最大値を取得
	var armor_max := 0
	var at_max := 0
	for v in armor_values:
		armor_max = maxi(armor_max, v)
	for v in at_values:
		at_max = maxi(at_max, v)

	report.armor_threat = armor_max
	report.at_threat = at_max

	# OPEN横断コスト
	report.open_exposure = _calculate_open_exposure(path, evaluator_faction, evaluator_mobility, move_speed_mps)
	report.max_open_segment_m = _calculate_max_open_segment(path)

	# ベース脅威
	var threat_base := clampi(
		int(0.6 * float(maxi(armor_max, at_max)) + 0.4 * float(armor_max + at_max) / 2.0),
		0, 100
	)

	# OPEN補正
	var open_multiplier := 1.0 + 0.7 * (float(report.open_exposure) / 100.0)
	report.risk_total = clampi(int(float(threat_base) * open_multiplier), 0, 100)

	# フラグ付与
	_apply_route_flags(report, path, evaluator_faction)

	# ミティゲーション推奨
	_apply_mitigations(report, evaluator_category)

	return report

# =============================================================================
# 装甲脅威計算
# =============================================================================

func _calculate_armor_threat(
	pos: Vector2,
	evaluator_faction: GameEnums.Faction,
	evaluator_category: ElementData.Category
) -> int:
	var contacts := _vision_system.get_contacts_for_faction(evaluator_faction)
	var contributions: Array[float] = []

	for contact in contacts:
		# 装甲タイプ判定
		var is_heavy := _is_armored_heavy(contact)
		var is_light := _is_armored_light(contact)

		if not is_heavy and not is_light:
			continue

		# 距離
		var distance := pos.distance_to(contact.pos_est_m)
		var r_class: float
		var w_class: int

		if is_heavy:
			r_class = GameConstants.R_HEAVY_M
			w_class = W_ARMOR_HEAVY.get(evaluator_category, 50)
		else:
			r_class = GameConstants.R_LIGHT_M
			w_class = W_ARMOR_LIGHT.get(evaluator_category, 30)

		# 距離係数
		var f_dist := _distance_falloff(distance, r_class)
		if f_dist <= 0:
			continue

		# Intel重み
		var w_intel := _get_intel_weight(contact)

		# LoS係数（簡易）
		var w_los := _get_los_weight(pos, contact.pos_est_m)

		# 寄与
		var contrib := float(w_class) * w_intel * w_los * f_dist
		contributions.append(contrib)

	# 上位2件の合計
	contributions.sort()
	contributions.reverse()

	var total := 0.0
	for i in range(mini(2, contributions.size())):
		total += contributions[i]

	return clampi(int(total), 0, 100)


func _is_armored_heavy(contact: VisionSystem.ContactRecord) -> bool:
	var hint := contact.type_hint.to_lower()
	return "tank" in hint or "heavy" in hint


func _is_armored_light(contact: VisionSystem.ContactRecord) -> bool:
	var hint := contact.type_hint.to_lower()
	return "ifv" in hint or "apc" in hint or "light" in hint


func _distance_falloff(distance: float, r_class: float) -> float:
	if distance >= r_class:
		return 0.0
	var ratio := 1.0 - distance / r_class
	return pow(ratio, GameConstants.DISTANCE_FALLOFF_POWER)


func _get_intel_weight(contact: VisionSystem.ContactRecord) -> float:
	var w_confidence: float
	match contact.state:
		GameEnums.ContactState.CONFIRMED:
			w_confidence = GameConstants.W_CONFIDENCE_CONF
		GameEnums.ContactState.SUSPECTED:
			w_confidence = GameConstants.W_CONFIDENCE_SUS
		GameEnums.ContactState.LOST:
			w_confidence = GameConstants.W_CONFIDENCE_LOST
		_:
			w_confidence = 0.0

	# 時間経過による減衰
	var ticks_since := _current_tick - contact.last_visible_tick
	var w_recency := 1.0

	match contact.state:
		GameEnums.ContactState.SUSPECTED:
			w_recency = clampf(1.0 - float(ticks_since) / float(GameConstants.SUS_RECENCY_WINDOW_TICKS), 0.0, 1.0)
		GameEnums.ContactState.LOST:
			w_recency = clampf(1.0 - float(ticks_since) / float(GameConstants.LOST_RECENCY_WINDOW_TICKS), 0.0, 1.0)

	return w_confidence * w_recency


func _get_los_weight(from_pos: Vector2, to_pos: Vector2) -> float:
	# 簡易実装：LoSチェックがあればそれを使用
	# TODO: VisionSystemのLoSチェックを利用
	return 1.0

# =============================================================================
# AT脅威計算
# =============================================================================

func _calculate_at_threat(
	pos: Vector2,
	evaluator_faction: GameEnums.Faction,
	evaluator_category: ElementData.Category
) -> int:
	# INF/RECはAT脅威を受けにくい
	if evaluator_category == ElementData.Category.INF or \
	   evaluator_category == ElementData.Category.REC:
		return 0

	var at_short := _calculate_at_short(pos, evaluator_faction, evaluator_category)
	var at_long := 0  # v0.1では確証がない限り0

	return clampi(at_short + at_long, 0, 100)


func _calculate_at_short(
	pos: Vector2,
	evaluator_faction: GameEnums.Faction,
	evaluator_category: ElementData.Category
) -> int:
	# (A) カバー密度
	var cover_density := _calculate_cover_density(pos)

	# (B) 敵存在重み
	var enemy_presence := _calculate_enemy_presence(pos, evaluator_faction)

	# (C) 進入角の悪さ
	var approach_penalty := _calculate_approach_penalty(pos)

	# 基礎重み
	var w_at_short: int = W_AT_SHORT.get(evaluator_category, 0)

	return int(float(w_at_short) * cover_density * enemy_presence * approach_penalty)


func _calculate_cover_density(pos: Vector2) -> float:
	if not _map_data:
		return 0.0

	# R_cover内のセルをカウント
	var cover_count := 0
	var total_count := 0
	var step := GameConstants.TERRAIN_GRID_CELL_M

	for dx in range(-15, 16):  # 150m / 10m = 15
		for dy in range(-15, 16):
			var check_pos := pos + Vector2(dx * step, dy * step)
			if check_pos.distance_to(pos) > GameConstants.R_COVER_M:
				continue

			total_count += 1
			var terrain := _map_data.get_terrain_at(check_pos)
			if terrain == GameEnums.TerrainType.URBAN or terrain == GameEnums.TerrainType.FOREST:
				cover_count += 1

	if total_count == 0:
		return 0.0

	return float(cover_count) / float(total_count)


func _calculate_enemy_presence(pos: Vector2, evaluator_faction: GameEnums.Faction) -> float:
	var contacts := _vision_system.get_contacts_for_faction(evaluator_faction)

	for contact in contacts:
		var distance := pos.distance_to(contact.pos_est_m)
		if distance > GameConstants.AT_SHORT_RANGE_M:
			continue

		# ソフト目標をチェック
		if _is_soft_target(contact):
			if contact.state == GameEnums.ContactState.CONFIRMED:
				return 1.0
			elif contact.state == GameEnums.ContactState.SUSPECTED:
				return 0.7

	# TODO: 敵CPが近くにあるかチェック

	return 0.2  # デフォルト（不確実だがゼロではない）


func _is_soft_target(contact: VisionSystem.ContactRecord) -> bool:
	var hint := contact.type_hint.to_lower()
	return "inf" in hint or "rifle" in hint or hint.is_empty()


func _calculate_approach_penalty(pos: Vector2) -> float:
	if not _map_data:
		return 0.3

	var terrain := _map_data.get_terrain_at(pos)

	match terrain:
		GameEnums.TerrainType.URBAN, GameEnums.TerrainType.FOREST:
			# 内部か縁かを簡易判定
			var is_edge := _is_terrain_edge(pos, terrain)
			return 0.7 if is_edge else 1.0
		_:
			return 0.3


func _is_terrain_edge(pos: Vector2, terrain_type: GameEnums.TerrainType) -> bool:
	var step := GameConstants.TERRAIN_GRID_CELL_M
	var different_count := 0

	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var check_pos: Vector2 = pos + dir * step * 2.0  # 20m先
		var check_terrain := _map_data.get_terrain_at(check_pos)
		if check_terrain != terrain_type:
			different_count += 1

	return different_count >= 2

# =============================================================================
# OPEN横断コスト計算
# =============================================================================

func _calculate_open_exposure(
	path: PackedVector2Array,
	evaluator_faction: GameEnums.Faction,
	evaluator_mobility: GameEnums.MobilityType,
	move_speed_mps: float
) -> int:
	if not _map_data or path.size() < 2:
		return 0

	# 曝露区間を計算
	var total_exposed_m := 0.0
	var exposed_strength := _get_exposed_strength(path, evaluator_faction)

	for i in range(path.size() - 1):
		var from_pos := path[i]
		var to_pos := path[i + 1]
		var segment_length := from_pos.distance_to(to_pos)

		# セグメントのサンプリング
		var sample_count := int(segment_length / 10.0) + 1
		for j in range(sample_count):
			var t := float(j) / float(sample_count)
			var sample_pos := from_pos.lerp(to_pos, t)
			var terrain := _map_data.get_terrain_at(sample_pos)

			var open_factor := 0.0
			match terrain:
				GameEnums.TerrainType.OPEN:
					open_factor = 1.0
				GameEnums.TerrainType.ROAD:
					open_factor = GameConstants.ROAD_OPEN_FACTOR

			total_exposed_m += open_factor * segment_length / float(sample_count)

	# 曝露時間
	var t_exposed := total_exposed_m / move_speed_mps

	# 役割別重み
	var w_open: int = W_OPEN.get(evaluator_mobility, 45)

	# スコア計算
	return clampi(int(float(w_open) * exposed_strength * t_exposed / GameConstants.OPEN_TIME_NORM_S), 0, 100)


func _get_exposed_strength(path: PackedVector2Array, evaluator_faction: GameEnums.Faction) -> float:
	var contacts := _vision_system.get_contacts_for_faction(evaluator_faction)

	# パスの中心点で簡易判定
	var center := path[path.size() / 2] if path.size() > 0 else Vector2.ZERO

	for contact in contacts:
		var distance := center.distance_to(contact.pos_est_m)
		if distance > 1200.0:
			continue

		if contact.state == GameEnums.ContactState.CONFIRMED and _is_armored_heavy(contact):
			return 1.0

	# SUS/Softだけ
	for contact in contacts:
		if contact.state in [GameEnums.ContactState.CONFIRMED, GameEnums.ContactState.SUSPECTED]:
			return 0.6

	return 0.2


func _calculate_max_open_segment(path: PackedVector2Array) -> float:
	if not _map_data or path.size() < 2:
		return 0.0

	var max_segment := 0.0
	var current_segment := 0.0
	var in_open := false

	for i in range(path.size() - 1):
		var from_pos := path[i]
		var to_pos := path[i + 1]
		var segment_length := from_pos.distance_to(to_pos)
		var mid_pos := from_pos.lerp(to_pos, 0.5)
		var terrain := _map_data.get_terrain_at(mid_pos)

		var is_open := terrain == GameEnums.TerrainType.OPEN or terrain == GameEnums.TerrainType.ROAD

		if is_open:
			if in_open:
				current_segment += segment_length
			else:
				in_open = true
				current_segment = segment_length
		else:
			if in_open:
				max_segment = maxf(max_segment, current_segment)
				in_open = false
				current_segment = 0.0

	# 最後の区間
	if in_open:
		max_segment = maxf(max_segment, current_segment)

	return max_segment

# =============================================================================
# パスサンプリング
# =============================================================================

func _sample_path(path: PackedVector2Array, step_m: float) -> PackedVector2Array:
	var result := PackedVector2Array()

	if path.size() < 2:
		return result

	var accumulated := 0.0

	for i in range(path.size() - 1):
		var from_pos := path[i]
		var to_pos := path[i + 1]
		var segment_length := from_pos.distance_to(to_pos)

		while accumulated < segment_length:
			var t := accumulated / segment_length
			result.append(from_pos.lerp(to_pos, t))
			accumulated += step_m

		accumulated -= segment_length

	# 最終点
	result.append(path[path.size() - 1])

	return result

# =============================================================================
# フラグ付与
# =============================================================================

func _apply_point_flags(report: RiskReport, pos: Vector2, evaluator_faction: GameEnums.Faction) -> void:
	var contacts := _vision_system.get_contacts_for_faction(evaluator_faction)

	for contact in contacts:
		if _is_armored_heavy(contact) and contact.state == GameEnums.ContactState.CONFIRMED:
			var distance := pos.distance_to(contact.pos_est_m)
			if distance <= GameConstants.ARMOR_NEAR_CONF_M:
				report.add_flag(GameEnums.RiskFlag.ARMOR_NEAR_CONF)
				break

	if report.armor_threat >= 50:
		report.add_flag(GameEnums.RiskFlag.ARMOR_PRESENT)

	if report.at_threat >= 60:
		var cover_density := _calculate_cover_density(pos)
		if cover_density >= 0.5:
			report.add_flag(GameEnums.RiskFlag.AT_AMBUSH_LIKELY)


func _apply_route_flags(report: RiskReport, path: PackedVector2Array, evaluator_faction: GameEnums.Faction) -> void:
	# まずPointフラグを適用
	if path.size() > 0:
		_apply_point_flags(report, path[path.size() / 2], evaluator_faction)

	# OPEN横断フラグ
	if report.max_open_segment_m > GameConstants.OPEN_CROSSING_LONG_M:
		report.add_flag(GameEnums.RiskFlag.OPEN_CROSSING_LONG)
	elif report.max_open_segment_m > GameConstants.OPEN_CROSSING_TRIGGER_M:
		report.add_flag(GameEnums.RiskFlag.OPEN_CROSSING_TRIGGER)

# =============================================================================
# ミティゲーション推奨
# =============================================================================

func _apply_mitigations(report: RiskReport, evaluator_category: ElementData.Category) -> void:
	# 装甲脅威への反応
	if report.has_flag(GameEnums.RiskFlag.ARMOR_NEAR_CONF):
		report.add_mitigation(GameEnums.Mitigation.STANDOFF)
		report.add_mitigation(GameEnums.Mitigation.SMOKE)
		report.add_mitigation(GameEnums.Mitigation.FLANK_ROUTE)

	if report.armor_threat >= 70:
		report.add_mitigation(GameEnums.Mitigation.RECON_FIRST)
		report.add_mitigation(GameEnums.Mitigation.STANDOFF)

	# AT脅威への反応（車両）
	if report.has_flag(GameEnums.RiskFlag.AT_AMBUSH_LIKELY):
		if evaluator_category in [ElementData.Category.VEH, ElementData.Category.LOG]:
			report.add_mitigation(GameEnums.Mitigation.STANDOFF)
			report.add_mitigation(GameEnums.Mitigation.RECON_FIRST)

	if report.at_threat >= 75:
		report.add_mitigation(GameEnums.Mitigation.FLANK_ROUTE)
		report.add_mitigation(GameEnums.Mitigation.SMOKE)
		report.add_mitigation(GameEnums.Mitigation.BOUNDING)

	# OPEN横断への反応
	var threat_base := maxi(report.armor_threat, report.at_threat)

	if report.has_flag(GameEnums.RiskFlag.OPEN_CROSSING_TRIGGER) and threat_base >= 50:
		report.add_mitigation(GameEnums.Mitigation.SMOKE)

	if report.has_flag(GameEnums.RiskFlag.OPEN_CROSSING_LONG) and threat_base >= 60:
		report.add_mitigation(GameEnums.Mitigation.SMOKE)
		report.add_mitigation(GameEnums.Mitigation.BOUNDING)

	if report.open_exposure >= 70:
		if evaluator_category == ElementData.Category.LOG:
			report.add_mitigation(GameEnums.Mitigation.FLANK_ROUTE)
			report.add_mitigation(GameEnums.Mitigation.DELAY)

	# 総合での離脱
	if report.risk_total >= 85:
		report.add_mitigation(GameEnums.Mitigation.BREAK_CONTACT)

# =============================================================================
# スムージング
# =============================================================================

func apply_smoothing(element_id: String, current_report: RiskReport, dt: float) -> RiskReport:
	if element_id not in _smoothed_risks:
		_smoothed_risks[element_id] = current_report
		return current_report

	var prev_report: RiskReport = _smoothed_risks[element_id]
	var decay := GameConstants.RISK_DECAY_DOWN_PER_SEC * dt

	# リスクが上がった場合は即反映、下がった場合は緩やかに
	var smoothed := RiskReport.new()
	smoothed.armor_threat = _smooth_value(prev_report.armor_threat, current_report.armor_threat, decay)
	smoothed.at_threat = _smooth_value(prev_report.at_threat, current_report.at_threat, decay)
	smoothed.open_exposure = _smooth_value(prev_report.open_exposure, current_report.open_exposure, decay)
	smoothed.risk_total = _smooth_value(prev_report.risk_total, current_report.risk_total, decay)
	smoothed.risk_flags = current_report.risk_flags
	smoothed.recommended_mitigations = current_report.recommended_mitigations
	smoothed.max_open_segment_m = current_report.max_open_segment_m

	_smoothed_risks[element_id] = smoothed
	return smoothed


func _smooth_value(prev: int, current: int, decay: float) -> int:
	if current >= prev:
		return current
	else:
		return maxi(current, int(float(prev) - decay))
