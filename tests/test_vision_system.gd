extends GutTest

## VisionSystemのユニットテスト

var vision_system: VisionSystem
var world_model: WorldModel
var map_data: MapData

# テスト用のElementType
var _test_type: ElementData.ElementType


func before_each() -> void:
	# WorldModelとMapDataのセットアップ
	world_model = WorldModel.new()
	map_data = _create_test_map_data()

	# VisionSystemのセットアップ
	vision_system = VisionSystem.new()
	vision_system.setup(world_model, map_data)

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


func _create_test_map_data() -> MapData:
	var data := MapData.new()
	data.map_id = "test_map"
	data.size_m = Vector2(2000, 2000)
	return data


# =============================================================================
# 基本テスト
# =============================================================================

func test_vision_system_initialization() -> void:
	assert_not_null(vision_system)
	var contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.BLUE)
	assert_eq(contacts.size(), 0, "初期状態ではContactは空")


func test_contact_record_creation() -> void:
	var contact := VisionSystem.ContactRecord.new("test_element")
	assert_eq(contact.element_id, "test_element")
	assert_eq(contact.state, GameEnums.ContactState.UNKNOWN)
	assert_eq(contact.pos_error_m, 0.0)


# =============================================================================
# 視認テスト
# =============================================================================

func test_element_detection_within_range() -> void:
	# BLUEとREDのユニットを近くに配置
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 視認スキャン実行（複数回でCONF確定）
	vision_system.update(0, 0.1)
	vision_system.update(2, 0.1)  # 2tick後（CONF_ACQUIRE_STREAK=2）
	vision_system.update(4, 0.1)

	# BLUEからREDが見えているか
	var contact := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_not_null(contact, "Contactが作成されている")
	assert_eq(contact.state, GameEnums.ContactState.CONFIRMED, "近距離では CONF になる")


func test_element_not_detected_out_of_range() -> void:
	# 遠くに配置（spot_range_base=300m より遠い）
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(500, 100))

	# 視認スキャン実行
	vision_system.update(0, 0.1)
	vision_system.update(2, 0.1)

	# BLUEからREDが見えていないか
	var contact := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_null(contact, "遠距離ではContactが作成されない")


# =============================================================================
# 状態遷移テスト
# =============================================================================

func test_conf_to_sus_transition() -> void:
	# 近くに配置してCONF化
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	var contact := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_eq(contact.state, GameEnums.ContactState.CONFIRMED)
	var last_tick := 10

	# REDを視界外に移動
	red.position = Vector2(1000, 1000)

	# T_CONF_TO_SUS_TICKS (30tick = 3秒) 経過させる
	for i in range(35):
		vision_system.update(last_tick + i * 2, 0.1)

	contact = vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_not_null(contact)
	assert_eq(contact.state, GameEnums.ContactState.SUSPECTED, "視界外で3秒後にSUSになる")


func test_position_error_growth() -> void:
	# CONFからSUSに移行させる
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# REDを視界外に移動
	red.position = Vector2(1000, 1000)

	# SUSに移行後、誤差が成長するか確認
	for i in range(50):
		vision_system.update(10 + i * 2, 0.1)

	var contact := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_not_null(contact)
	assert_gt(contact.pos_error_m, 0.0, "位置誤差が成長している")


# =============================================================================
# 発見距離係数テスト
# =============================================================================

func test_moving_target_easier_to_detect() -> void:
	# 移動中のユニットは見つかりやすい（m_activity = 1.15）
	# spot_range_base = 300m
	# 静止目標: 300m まで見える
	# 移動目標: 300 * 1.15 = 345m まで見える

	# 330m地点に配置（静止なら見えない、移動なら見える距離）
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(430, 100))  # 330m away

	# 静止状態では見えない
	red.is_moving = false
	vision_system.update(0, 0.1)
	vision_system.update(2, 0.1)
	vision_system.update(4, 0.1)

	var contact_stationary := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_null(contact_stationary, "静止目標330mは視界外")

	# REDを移動状態にする
	red.is_moving = true
	red.velocity = Vector2(5, 0)

	# 再スキャン
	vision_system.mark_dirty()
	vision_system.update(6, 0.1)
	vision_system.update(8, 0.1)
	vision_system.update(10, 0.1)

	var contact_moving := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	assert_not_null(contact_moving, "移動目標330mは視界内（m_activity=1.15）")


# =============================================================================
# API テスト
# =============================================================================

func test_is_element_visible() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化前
	assert_false(vision_system.is_element_visible(GameEnums.Faction.BLUE, red.id))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	assert_true(vision_system.is_element_visible(GameEnums.Faction.BLUE, red.id))


func test_get_element_visibility_state() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 初期状態
	assert_eq(
		vision_system.get_element_visibility_state(GameEnums.Faction.BLUE, red.id),
		GameEnums.ContactState.UNKNOWN
	)

	# CONF化後
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	assert_eq(
		vision_system.get_element_visibility_state(GameEnums.Faction.BLUE, red.id),
		GameEnums.ContactState.CONFIRMED
	)


# =============================================================================
# 統合API テスト（射撃可能判定のSingle Source of Truth）
# =============================================================================

func test_is_visible_now_within_range() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 近距離では即座に見える
	assert_true(vision_system.is_visible_now(blue, red), "近距離ではis_visible_now=true")
	assert_true(vision_system.is_visible_now(red, blue), "双方から見える")


func test_is_visible_now_out_of_range() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(500, 100))

	# 遠距離では見えない
	assert_false(vision_system.is_visible_now(blue, red), "遠距離ではis_visible_now=false")


func test_is_visible_now_destroyed_unit() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# 破壊されたユニットは見えない
	red.state = GameEnums.UnitState.DESTROYED
	assert_false(vision_system.is_visible_now(blue, red), "破壊されたユニットは見えない")


func test_can_fire_at_requires_confirmed_contact() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# Contact未確定では射撃不可
	assert_false(vision_system.can_fire_at(blue, red.id), "Contact未確定では射撃不可")

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# CONF確定後は射撃可能
	assert_true(vision_system.can_fire_at(blue, red.id), "CONF確定後は射撃可能")


func test_can_fire_at_out_of_range() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 射程内→射撃可能
	assert_true(vision_system.can_fire_at(blue, red.id))

	# REDを遠くに移動
	red.position = Vector2(500, 100)

	# 視界外→射撃不可（Contactは残っているが今は見えない）
	assert_false(vision_system.can_fire_at(blue, red.id), "視界外では射撃不可")


func test_get_fireable_targets() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red1 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))
	var red2 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(250, 100))
	var red3 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(500, 100))  # 遠い

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 射撃可能な目標を取得
	var targets := vision_system.get_fireable_targets(blue)

	# red1とred2は射程内、red3は射程外
	assert_eq(targets.size(), 2, "2体が射撃可能")
	assert_true(targets.has(red1), "red1は射撃可能")
	assert_true(targets.has(red2), "red2は射撃可能")
	assert_false(targets.has(red3), "red3は射程外")


func test_get_nearest_fireable_target() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red1 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(250, 100))  # 150m
	var red2 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))  # 100m（近い）

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 最も近い目標を取得
	var nearest := vision_system.get_nearest_fireable_target(blue)

	assert_not_null(nearest)
	assert_eq(nearest.id, red2.id, "最も近いred2が返される")


func test_get_base_view_range() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))

	var range := vision_system.get_base_view_range(blue)
	assert_eq(range, 300.0, "基本視界範囲はspot_range_base")


func test_get_effective_view_range_no_suppression() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	blue.suppression = 0.0

	var view_range: float = vision_system.get_effective_view_range(blue)
	assert_eq(view_range, 300.0, "抑圧なしでは実効視界=基本視界")


func test_get_effective_view_range_suppressed() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	blue.suppression = 0.50  # SUPPRESSEDレベル → m_observer=0.75

	var view_range: float = vision_system.get_effective_view_range(blue)
	# 300 * 0.75 = 225
	assert_almost_eq(view_range, 225.0, 1.0, "抑圧されると視界が狭まる")


# =============================================================================
# 双方向視認テスト（RED->BLUE, BLUE->RED）
# =============================================================================

func test_destroyed_observer_cannot_see() -> void:
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var _red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# BLUEをDESTROYEDにする
	blue.state = GameEnums.UnitState.DESTROYED

	# スキャン実行
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 破壊されたBLUEはREDを見れない
	var blue_contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.BLUE)
	assert_eq(blue_contacts.size(), 0, "破壊されたユニットはContactを作成しない")

	# 破壊されたBLUEはREDからも視認対象にならない（目標として無効）
	var red_contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.RED)
	assert_eq(red_contacts.size(), 0, "破壊されたユニットはContactの目標にならない")


func test_multiple_enemies_detection() -> void:
	var _blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var _red1 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))
	var _red2 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(150, 150))
	var _red3 := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(180, 80))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	var contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.BLUE)
	assert_eq(contacts.size(), 3, "3体のREDユニットを認識")

	# 全てがCONFIRMED
	for contact in contacts:
		assert_eq(contact.state, GameEnums.ContactState.CONFIRMED)


func test_friendly_not_detected_as_enemy() -> void:
	var _blue1 := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var _blue2 := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(200, 100))

	# スキャン実行
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# 味方はContactとして検出されない
	var contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.BLUE)
	assert_eq(contacts.size(), 0, "味方ユニットはContactに含まれない")


func test_bidirectional_contact_creation() -> void:
	# BLUEとREDを近くに配置
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# BLUE->RED のContact
	var blue_contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.BLUE)
	assert_eq(blue_contacts.size(), 1, "BLUEは1つのContactを持つ")
	assert_eq(blue_contacts[0].element_id, red.id, "BLUEはREDを認識")
	assert_eq(blue_contacts[0].state, GameEnums.ContactState.CONFIRMED, "BLUEからREDはCONF")

	# RED->BLUE のContact
	var red_contacts := vision_system.get_contacts_for_faction(GameEnums.Faction.RED)
	assert_eq(red_contacts.size(), 1, "REDは1つのContactを持つ")
	assert_eq(red_contacts[0].element_id, blue.id, "REDはBLUEを認識")
	assert_eq(red_contacts[0].state, GameEnums.ContactState.CONFIRMED, "REDからBLUEはCONF")


func test_bidirectional_fireable_targets() -> void:
	# BLUEとREDを近くに配置
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(200, 100))

	# CONF化
	for i in range(5):
		vision_system.update(i * 2, 0.1)

	# BLUE->RED の射撃可能判定
	var blue_targets := vision_system.get_fireable_targets(blue)
	assert_eq(blue_targets.size(), 1, "BLUEは1体を射撃可能")
	assert_eq(blue_targets[0].id, red.id, "BLUEはREDを射撃可能")

	# RED->BLUE の射撃可能判定
	var red_targets := vision_system.get_fireable_targets(red)
	assert_eq(red_targets.size(), 1, "REDは1体を射撃可能")
	assert_eq(red_targets[0].id, blue.id, "REDはBLUEを射撃可能")


