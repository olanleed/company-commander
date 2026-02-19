extends GutTest

## RiskAssessmentのユニットテスト

var risk_assessment: RiskAssessment
var map_data: MapData
var vision_system: VisionSystem
var world_model: WorldModel

var _test_type: ElementData.ElementType
var _tank_type: ElementData.ElementType


func before_each() -> void:
	# WorldModelとMapDataのセットアップ
	world_model = WorldModel.new()
	map_data = _create_test_map_data()

	# VisionSystemのセットアップ
	vision_system = VisionSystem.new()
	vision_system.setup(world_model, map_data)

	# RiskAssessmentのセットアップ
	risk_assessment = RiskAssessment.new()
	risk_assessment.setup(map_data, vision_system)

	# テスト用ElementType
	_test_type = ElementData.ElementType.new()
	_test_type.id = "test_infantry"
	_test_type.display_name = "Test Infantry"
	_test_type.category = ElementData.Category.INF
	_test_type.mobility_class = GameEnums.MobilityType.FOOT
	_test_type.spot_range_base = 300.0
	_test_type.road_speed = 5.0
	_test_type.cross_speed = 3.0
	_test_type.max_strength = 10

	_tank_type = ElementData.ElementType.new()
	_tank_type.id = "test_tank"
	_tank_type.display_name = "Test Tank"
	_tank_type.category = ElementData.Category.VEH
	_tank_type.mobility_class = GameEnums.MobilityType.TRACKED
	_tank_type.spot_range_base = 500.0
	_tank_type.road_speed = 12.0
	_tank_type.cross_speed = 8.0
	_tank_type.max_strength = 4
	_tank_type.armor_class = 3


func _create_test_map_data() -> MapData:
	var data := MapData.new()
	data.map_id = "test_map"
	data.size_m = Vector2(2000, 2000)
	return data


# =============================================================================
# 基本テスト
# =============================================================================

func test_risk_assessment_initialization() -> void:
	assert_not_null(risk_assessment)


func test_risk_report_creation() -> void:
	var report := RiskAssessment.RiskReport.new()
	assert_eq(report.risk_total, 0)
	assert_eq(report.armor_threat, 0.0)
	assert_eq(report.at_threat, 0.0)
	assert_eq(report.open_exposure, 0.0)
	assert_eq(report.risk_flags.size(), 0)
	assert_eq(report.recommended_mitigations.size(), 0)


# =============================================================================
# ポイントリスク評価テスト
# =============================================================================

func test_evaluate_point_risk_no_threats() -> void:
	# 脅威なしの状況
	var report := risk_assessment.evaluate_point_risk(
		Vector2(500, 500),
		GameEnums.Faction.BLUE,
		ElementData.Category.INF,
		GameEnums.MobilityType.FOOT
	)

	assert_not_null(report)
	assert_eq(report.risk_total, 0, "脅威なしではリスク0")


func test_evaluate_point_risk_with_armor_threat() -> void:
	# 敵戦車を配置
	var enemy := world_model.create_test_element(_tank_type, GameEnums.Faction.RED, Vector2(800, 500))

	# 視界スキャンで敵を発見（CONF化）
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(500, 500))
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# リスク評価
	var report := risk_assessment.evaluate_point_risk(
		Vector2(500, 500),
		GameEnums.Faction.BLUE,
		ElementData.Category.VEH,
		GameEnums.MobilityType.TRACKED
	)

	assert_gt(report.armor_threat, 0.0, "近くに敵装甲がいればarmor_threatが発生")


func test_risk_flags_armor_near_conf() -> void:
	# 敵戦車を近くに配置（900m以内）
	var enemy := world_model.create_test_element(_tank_type, GameEnums.Faction.RED, Vector2(800, 500))

	# 視界スキャンで敵を発見
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(200, 500))
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# リスク評価
	var report := risk_assessment.evaluate_point_risk(
		Vector2(200, 500),
		GameEnums.Faction.BLUE,
		ElementData.Category.VEH,
		GameEnums.MobilityType.TRACKED
	)

	assert_true(
		GameEnums.RiskFlag.ARMOR_NEAR_CONF in report.risk_flags,
		"近くに確定敵装甲がいればARMOR_NEAR_CONFフラグが立つ"
	)


# =============================================================================
# ルートリスク評価テスト
# =============================================================================

func test_evaluate_route_risk_empty_path() -> void:
	var path: PackedVector2Array = []

	var report := risk_assessment.evaluate_route_risk(
		path,
		GameEnums.Faction.BLUE,
		ElementData.Category.INF,
		GameEnums.MobilityType.FOOT,
		3.0
	)

	assert_not_null(report)
	assert_eq(report.risk_total, 0, "空のパスではリスク0")


func test_evaluate_route_risk_simple_path() -> void:
	var path: PackedVector2Array = [
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(300, 100)
	]

	var report := risk_assessment.evaluate_route_risk(
		path,
		GameEnums.Faction.BLUE,
		ElementData.Category.INF,
		GameEnums.MobilityType.FOOT,
		3.0
	)

	assert_not_null(report)
	# 脅威なし、地形もOPENなのでopen_exposureのみ
	assert_gte(report.open_exposure, 0.0)


# =============================================================================
# リスクレベルテスト
# =============================================================================

func test_get_risk_level_green() -> void:
	var report := RiskAssessment.RiskReport.new()
	report.risk_total = 20

	assert_eq(report.get_risk_level(), 0, "0-24はGREEN（レベル0）")


func test_get_risk_level_yellow() -> void:
	var report := RiskAssessment.RiskReport.new()
	report.risk_total = 40

	assert_eq(report.get_risk_level(), 1, "25-49はYELLOW（レベル1）")


func test_get_risk_level_orange() -> void:
	var report := RiskAssessment.RiskReport.new()
	report.risk_total = 60

	assert_eq(report.get_risk_level(), 2, "50-74はORANGE（レベル2）")


func test_get_risk_level_red() -> void:
	var report := RiskAssessment.RiskReport.new()
	report.risk_total = 80

	assert_eq(report.get_risk_level(), 3, "75+はRED（レベル3）")


# =============================================================================
# 軽減策テスト
# =============================================================================

func test_mitigation_recommendation_smoke() -> void:
	# 開放地でのリスク評価
	var path: PackedVector2Array = [
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(300, 100),
		Vector2(400, 100)
	]

	# OPEN地形を長く通ると SMOKE が推奨される可能性
	var report := risk_assessment.evaluate_route_risk(
		path,
		GameEnums.Faction.BLUE,
		ElementData.Category.INF,
		GameEnums.MobilityType.FOOT,
		3.0
	)

	# open_exposureが一定以上あればSMOKEが推奨される
	if report.open_exposure > 0.5:
		assert_true(
			GameEnums.Mitigation.SMOKE in report.recommended_mitigations,
			"開放地横断ではSMOKEが推奨される"
		)


# =============================================================================
# 重み付けテスト
# =============================================================================

func test_role_weights_exist() -> void:
	# 各役割の重みが定義されているか確認
	assert_true(RiskAssessment.W_ARMOR_HEAVY.has(GameEnums.ElementRole.ASSAULT))
	assert_true(RiskAssessment.W_ARMOR_LIGHT.has(GameEnums.ElementRole.SUPPORT))
	assert_true(RiskAssessment.W_AT_SHORT.has(GameEnums.ElementRole.SCOUT))
	assert_true(RiskAssessment.W_OPEN.has(GameEnums.ElementRole.SECURITY))


func test_confidence_weight_function() -> void:
	# 確度別の重み（内部関数のテスト）
	# CONF: 1.0, SUS: 0.6, LOST: 0.2
	assert_eq(GameConstants.W_CONFIDENCE_CONF, 1.0)
	assert_eq(GameConstants.W_CONFIDENCE_SUS, 0.6)
	assert_eq(GameConstants.W_CONFIDENCE_LOST, 0.2)
