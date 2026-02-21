extends SceneTree

## DataLinkSystemのテスト
## godot --headless -s tests/test_data_link.gd

const DataLinkSystemClass = preload("res://scripts/systems/data_link_system.gd")


func _init() -> void:
	print("=== DataLink System Tests ===")
	test_comm_state_enum()
	test_element_type_comm_fields()
	test_hq_archetype()
	test_data_link_system_basic()
	test_data_link_system_no_hub_fallback()
	test_data_link_system_hub_range()
	print("=== All DataLink Tests Complete ===")
	quit()


## CommState enumのテスト
func test_comm_state_enum() -> void:
	print("\n--- Test: CommState Enum ---")

	# 3つの状態が定義されているか
	assert(GameEnums.CommState.LINKED == 0, "LINKED should be 0")
	assert(GameEnums.CommState.DEGRADED == 1, "DEGRADED should be 1")
	assert(GameEnums.CommState.ISOLATED == 2, "ISOLATED should be 2")

	print("PASS: CommState enum correct")


## ElementTypeの通信関連フィールドのテスト
func test_element_type_comm_fields() -> void:
	print("\n--- Test: ElementType Comm Fields ---")

	var element_type := ElementData.ElementType.new()

	# デフォルト値
	assert(element_type.is_comm_hub == false, "Default is_comm_hub should be false")
	assert(element_type.comm_range == 2000.0, "Default comm_range should be 2000")

	# 設定可能か
	element_type.is_comm_hub = true
	element_type.comm_range = 3000.0
	assert(element_type.is_comm_hub == true, "is_comm_hub should be settable")
	assert(element_type.comm_range == 3000.0, "comm_range should be settable")

	print("PASS: ElementType comm fields correct")


## HQアーキタイプのテスト
func test_hq_archetype() -> void:
	print("\n--- Test: HQ Archetype ---")

	var hq_type := ElementData.ElementArchetypes.create_cmd_hq()

	assert(hq_type.id == "CMD_HQ", "HQ id should be CMD_HQ")
	assert(hq_type.category == ElementData.Category.HQ, "HQ category should be HQ")
	assert(hq_type.is_comm_hub == true, "HQ should be comm hub")
	assert(hq_type.comm_range == 3000.0, "HQ comm_range should be 3000m")

	print("HQ type:")
	print("  id: %s" % hq_type.id)
	print("  is_comm_hub: %s" % hq_type.is_comm_hub)
	print("  comm_range: %.0fm" % hq_type.comm_range)

	print("PASS: HQ archetype correct")


## DataLinkSystemの基本テスト
func test_data_link_system_basic() -> void:
	print("\n--- Test: DataLinkSystem Basic ---")

	var dls := DataLinkSystemClass.new()
	assert(dls != null, "DataLinkSystem should be created")

	# ElementInstanceの通信状態フィールド
	var element_type := ElementData.ElementArchetypes.create_inf_line()
	var element := ElementData.ElementInstance.new(element_type)
	element.id = "test_inf"
	element.faction = GameEnums.Faction.BLUE

	# デフォルトはLINKED
	assert(element.comm_state == GameEnums.CommState.LINKED, "Default comm_state should be LINKED")
	assert(element.comm_hub_id == "", "Default comm_hub_id should be empty")

	print("PASS: DataLinkSystem basic correct")


## ハブなしフォールバックのテスト
func test_data_link_system_no_hub_fallback() -> void:
	print("\n--- Test: DataLinkSystem No Hub Fallback ---")

	var dls := DataLinkSystemClass.new()

	# ハブなしの陣営を作成
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()

	var inf1 := ElementData.ElementInstance.new(inf_type)
	inf1.id = "blue_inf_1"
	inf1.faction = GameEnums.Faction.BLUE
	inf1.position = Vector2(100, 100)

	var inf2 := ElementData.ElementInstance.new(inf_type)
	inf2.id = "blue_inf_2"
	inf2.faction = GameEnums.Faction.BLUE
	inf2.position = Vector2(200, 100)

	var tank1 := ElementData.ElementInstance.new(tank_type)
	tank1.id = "red_tank_1"
	tank1.faction = GameEnums.Faction.RED
	tank1.position = Vector2(500, 500)

	var elements: Array[ElementData.ElementInstance] = [inf1, inf2, tank1]

	# ハブなしフォールバック：全員LINKED
	dls.update_comm_states_no_hub_fallback(elements)

	assert(inf1.comm_state == GameEnums.CommState.LINKED, "No hub fallback: inf1 should be LINKED")
	assert(inf2.comm_state == GameEnums.CommState.LINKED, "No hub fallback: inf2 should be LINKED")
	assert(tank1.comm_state == GameEnums.CommState.LINKED, "No hub fallback: tank1 should be LINKED")

	print("PASS: DataLinkSystem no hub fallback correct")


## ハブ範囲のテスト
func test_data_link_system_hub_range() -> void:
	print("\n--- Test: DataLinkSystem Hub Range ---")

	var dls := DataLinkSystemClass.new()

	# HQユニットを作成（comm_range = 3000m）
	var hq_type := ElementData.ElementArchetypes.create_cmd_hq()
	var hq := ElementData.ElementInstance.new(hq_type)
	hq.id = "blue_hq"
	hq.faction = GameEnums.Faction.BLUE
	hq.position = Vector2(1000, 1000)

	# 範囲内のユニット（2500m < 3000m）
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var inf_near := ElementData.ElementInstance.new(inf_type)
	inf_near.id = "blue_inf_near"
	inf_near.faction = GameEnums.Faction.BLUE
	inf_near.position = Vector2(3500, 1000)  # HQから2500m

	# 範囲外のユニット（3500m > 3000m）
	var inf_far := ElementData.ElementInstance.new(inf_type)
	inf_far.id = "blue_inf_far"
	inf_far.faction = GameEnums.Faction.BLUE
	inf_far.position = Vector2(4600, 1000)  # HQから3600m

	var elements: Array[ElementData.ElementInstance] = [hq, inf_near, inf_far]

	# 通常の通信状態更新（ハブありモード）
	dls.update_comm_states(elements)

	print("HQ position: %s" % hq.position)
	print("inf_near position: %s (dist=%.0fm)" % [inf_near.position, hq.position.distance_to(inf_near.position)])
	print("inf_far position: %s (dist=%.0fm)" % [inf_far.position, hq.position.distance_to(inf_far.position)])
	print("HQ comm_state: %s" % hq.comm_state)
	print("inf_near comm_state: %s" % inf_near.comm_state)
	print("inf_far comm_state: %s" % inf_far.comm_state)

	# HQ自身はLINKED
	assert(hq.comm_state == GameEnums.CommState.LINKED, "HQ should be LINKED")

	# 範囲内はLINKED
	assert(inf_near.comm_state == GameEnums.CommState.LINKED, "inf_near should be LINKED (in range)")
	assert(inf_near.comm_hub_id == "blue_hq", "inf_near should be connected to HQ")

	# 範囲外はISOLATED
	assert(inf_far.comm_state == GameEnums.CommState.ISOLATED, "inf_far should be ISOLATED (out of range)")
	assert(inf_far.comm_hub_id == "", "inf_far should not be connected to any hub")

	print("PASS: DataLinkSystem hub range correct")
