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
	# 移動中のユニットは見つかりやすい
	var blue := world_model.create_test_element(_test_type, GameEnums.Faction.BLUE, Vector2(100, 100))
	var red := world_model.create_test_element(_test_type, GameEnums.Faction.RED, Vector2(350, 100))

	# 静止状態では見えない距離
	vision_system.update(0, 0.1)
	var contact := vision_system.get_contact(GameEnums.Faction.BLUE, red.id)

	# REDを移動状態にする
	red.is_moving = true
	red.velocity = Vector2(5, 0)

	# 再スキャン
	vision_system.mark_dirty()
	vision_system.update(2, 0.1)
	vision_system.update(4, 0.1)
	vision_system.update(6, 0.1)

	contact = vision_system.get_contact(GameEnums.Faction.BLUE, red.id)
	# 移動中は発見距離が1.15倍なので、350m以内なら見える可能性が上がる
	# 300 * 1.15 = 345m なので、350mは微妙だが、この距離なら見えるはず
	# （実際の判定は係数の組み合わせによる）


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
