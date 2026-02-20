extends GutTest

## CaptureSystem テスト
## 仕様書: docs/capture_v0.1.md

var capture_system: CaptureSystem
var world_model: WorldModel
var map_data: MapData


func before_each() -> void:
	capture_system = CaptureSystem.new()
	world_model = WorldModel.new()
	map_data = MapData.new()
	map_data.cp_radius_m = 40.0

	# テスト用CP作成
	var cp := MapData.CapturePoint.new()
	cp.id = "A"
	cp.position = Vector2(500, 500)
	cp.initial_owner = GameEnums.Faction.NONE
	cp.initialize_control()
	map_data.capture_points.append(cp)


func after_each() -> void:
	capture_system = null
	world_model = null
	map_data = null


# =============================================================================
# 基本テスト
# =============================================================================

func test_initial_neutral_cp() -> void:
	var cp := map_data.capture_points[0]
	assert_eq(cp.state, GameEnums.CPState.NEUTRAL, "初期状態はNEUTRAL")
	assert_eq(cp.control_milli, 0, "初期control_milliは0")


func test_initial_blue_controlled_cp() -> void:
	var cp := MapData.CapturePoint.new()
	cp.id = "B"
	cp.position = Vector2(100, 100)
	cp.initial_owner = GameEnums.Faction.BLUE
	cp.initialize_control()

	assert_eq(cp.state, GameEnums.CPState.CONTROLLED_BLUE, "Blue初期支配")
	assert_eq(cp.control_milli, GameConstants.CONTROL_MILLI_MAX, "control_milliは+100000")


func test_initial_red_controlled_cp() -> void:
	var cp := MapData.CapturePoint.new()
	cp.id = "C"
	cp.position = Vector2(900, 900)
	cp.initial_owner = GameEnums.Faction.RED
	cp.initialize_control()

	assert_eq(cp.state, GameEnums.CPState.CONTROLLED_RED, "Red初期支配")
	assert_eq(cp.control_milli, GameConstants.CONTROL_MILLI_MIN, "control_milliは-100000")


# =============================================================================
# 占領寄与テスト
# =============================================================================

func test_infantry_can_contribute() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	assert_true(capture_system.can_contribute_to_capture(element), "INFは占領に寄与可能")


func test_vehicle_can_contribute() -> void:
	var element := _create_test_element(ElementData.Category.VEH, GameEnums.Faction.BLUE)
	assert_true(capture_system.can_contribute_to_capture(element), "VEHは占領に寄与可能")


func test_weap_cannot_contribute() -> void:
	var element := _create_test_element(ElementData.Category.WEAP, GameEnums.Faction.BLUE)
	assert_false(capture_system.can_contribute_to_capture(element), "WEAPは占領に寄与不可")


func test_log_cannot_contribute() -> void:
	var element := _create_test_element(ElementData.Category.LOG, GameEnums.Faction.BLUE)
	assert_false(capture_system.can_contribute_to_capture(element), "LOGは占領に寄与不可")


func test_low_strength_cannot_contribute() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.current_strength = 10  # 15以下
	assert_false(capture_system.can_contribute_to_capture(element), "Strength<=15は占領に寄与不可")


func test_destroyed_cannot_contribute() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.state = GameEnums.UnitState.DESTROYED
	assert_false(capture_system.can_contribute_to_capture(element), "DESTROYEDは占領に寄与不可")


# =============================================================================
# パワー計算テスト
# =============================================================================

func test_infantry_full_power() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.current_strength = 100
	element.state = GameEnums.UnitState.ACTIVE

	var power := capture_system.get_element_power(element)

	assert_almost_eq(power.capture, 1.0, 0.01, "INFのcapture=1.0")
	assert_almost_eq(power.neutralize, 1.0, 0.01, "INFのneutralize=1.0")
	assert_almost_eq(power.contest, 1.0, 0.01, "INFのcontest=1.0")


func test_vehicle_no_capture_power() -> void:
	var element := _create_test_element(ElementData.Category.VEH, GameEnums.Faction.BLUE)
	element.current_strength = 100
	element.state = GameEnums.UnitState.ACTIVE

	var power := capture_system.get_element_power(element)

	assert_almost_eq(power.capture, 0.0, 0.01, "VEHのcapture=0.0")
	assert_almost_eq(power.neutralize, 0.40, 0.01, "VEHのneutralize=0.40")
	assert_almost_eq(power.contest, 0.80, 0.01, "VEHのcontest=0.80")


func test_suppressed_reduces_power() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.current_strength = 100
	element.state = GameEnums.UnitState.SUPPRESSED

	var power := capture_system.get_element_power(element)

	# SUPPRESSEDの倍率は0.50
	assert_almost_eq(power.capture, 0.50, 0.01, "SUPPRESSED時のcapture=0.50")


func test_broken_no_power() -> void:
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.current_strength = 100
	element.state = GameEnums.UnitState.BROKEN

	var power := capture_system.get_element_power(element)

	assert_almost_eq(power.capture, 0.0, 0.01, "BROKEN時のcapture=0.0")
	assert_almost_eq(power.contest, 0.0, 0.01, "BROKEN時のcontest=0.0")


# =============================================================================
# 占領進行テスト
# =============================================================================

func test_blue_captures_neutral_cp() -> void:
	var cp := map_data.capture_points[0]
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.position = cp.position  # ゾーン内
	world_model.add_element(element)

	# 複数tick更新
	for i in range(10):
		capture_system.update(world_model, map_data)

	assert_gt(cp.control_milli, 0, "Blueが占領開始でcontrol_milliが増加")
	assert_eq(cp.state, GameEnums.CPState.CAPTURING_BLUE, "状態はCAPTURING_BLUE")


func test_red_captures_neutral_cp() -> void:
	var cp := map_data.capture_points[0]
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.RED)
	element.position = cp.position
	world_model.add_element(element)

	for i in range(10):
		capture_system.update(world_model, map_data)

	assert_lt(cp.control_milli, 0, "Redが占領開始でcontrol_milliが減少")
	assert_eq(cp.state, GameEnums.CPState.CAPTURING_RED, "状態はCAPTURING_RED")


func test_contested_stops_progress() -> void:
	var cp := map_data.capture_points[0]

	var blue_inf := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	blue_inf.position = cp.position
	world_model.add_element(blue_inf)

	var red_inf := _create_test_element(ElementData.Category.INF, GameEnums.Faction.RED)
	red_inf.position = cp.position
	world_model.add_element(red_inf)

	capture_system.update(world_model, map_data)

	assert_eq(cp.state, GameEnums.CPState.CONTESTED, "両軍いるとCONTESTED")
	assert_eq(cp.control_milli, 0, "CONTESTEDではcontrol_milliは変化しない")


func test_vehicle_only_can_neutralize_but_not_capture() -> void:
	# Red支配のCPを作成
	var cp := map_data.capture_points[0]
	cp.control_milli = GameConstants.CONTROL_MILLI_MIN
	cp.state = GameEnums.CPState.CONTROLLED_RED

	var blue_vehicle := _create_test_element(ElementData.Category.VEH, GameEnums.Faction.BLUE)
	blue_vehicle.position = cp.position
	world_model.add_element(blue_vehicle)

	# 大量にtick進める（中和に必要: 100000 / (150 * 0.40) = 1667 ticks + 余裕）
	for i in range(2000):
		capture_system.update(world_model, map_data)

	# 車両はneutralizeできるが、captureは0なので0で止まる
	assert_eq(cp.control_milli, 0, "車両だけでは中立化止まり")
	assert_eq(cp.state, GameEnums.CPState.NEUTRAL, "状態はNEUTRAL")


func test_full_capture_time() -> void:
	# 歩兵1人（power=1.0）で0→100000にかかるtick数を確認
	# delta_milli/tick = 150 × 1.0 = 150
	# 100000 / 150 = 666.67 ticks = 約66.7秒
	var cp := map_data.capture_points[0]
	var element := _create_test_element(ElementData.Category.INF, GameEnums.Faction.BLUE)
	element.position = cp.position
	world_model.add_element(element)

	var ticks_to_capture := 0
	while cp.state != GameEnums.CPState.CONTROLLED_BLUE and ticks_to_capture < 1000:
		capture_system.update(world_model, map_data)
		ticks_to_capture += 1

	# 約667tick（66.7秒）
	assert_between(ticks_to_capture, 650, 700, "約66-70秒で完全制圧")


# =============================================================================
# ヘルパー
# =============================================================================

func _create_test_element(category: ElementData.Category, faction: GameEnums.Faction) -> ElementData.ElementInstance:
	var elem_type := ElementData.ElementType.new()
	elem_type.id = "test_" + str(category)
	elem_type.category = category
	elem_type.max_strength = 100

	var element := ElementData.ElementInstance.new(elem_type)
	element.id = "elem_" + str(randi())
	element.faction = faction
	element.current_strength = 100
	element.state = GameEnums.UnitState.ACTIVE
	element.current_order_type = GameEnums.OrderType.DEFEND
	element.position = Vector2(0, 0)  # デフォルトはゾーン外

	return element
