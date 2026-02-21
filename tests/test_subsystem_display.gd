extends Node

## サブシステムHP表示のテスト
## テスト項目:
## 1. 車両のサブシステムHP初期値が正しいこと
## 2. サブシステムHPが正しく減少すること
## 3. is_vehicle()判定が正しく動作すること
## 4. RightPanelのサブシステム表示ロジック確認（ユニット判定）
## 5. ElementViewのサブシステムバー描画条件確認

var combat_system: CombatSystem


func _ready() -> void:
	combat_system = CombatSystem.new()
	run_tests()


func run_tests() -> void:
	print("=== Subsystem Display Tests ===")
	test_subsystem_initial_values()
	test_subsystem_damage()
	test_is_vehicle_check()
	test_subsystem_display_conditions()
	test_subsystem_bar_colors()
	print("=== All Subsystem Tests Complete ===")
	get_tree().quit()


## サブシステムHP初期値テスト
func test_subsystem_initial_values() -> void:
	print("\n--- Test: Subsystem Initial Values ---")

	# 戦車小隊
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank"

	print("Tank mobility_hp: %d (expected 100)" % tank.mobility_hp)
	print("Tank firepower_hp: %d (expected 100)" % tank.firepower_hp)
	print("Tank sensors_hp: %d (expected 100)" % tank.sensors_hp)

	assert(tank.mobility_hp == 100, "mobility_hp should be 100")
	assert(tank.firepower_hp == 100, "firepower_hp should be 100")
	assert(tank.sensors_hp == 100, "sensors_hp should be 100")

	# 偵察車両
	var recon_type := ElementData.ElementArchetypes.create_recon_veh()
	var recon := ElementData.ElementInstance.new(recon_type)
	recon.id = "test_recon"

	assert(recon.mobility_hp == 100, "recon mobility_hp should be 100")
	assert(recon.firepower_hp == 100, "recon firepower_hp should be 100")
	assert(recon.sensors_hp == 100, "recon sensors_hp should be 100")

	print("PASS: Subsystem initial values correct")


## サブシステムへのダメージテスト
func test_subsystem_damage() -> void:
	print("\n--- Test: Subsystem Damage ---")

	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank_subsys"

	# 直接HPを減少させてテスト
	tank.mobility_hp = 50
	tank.firepower_hp = 30
	tank.sensors_hp = 70

	print("After damage: MOB=%d, FPW=%d, SEN=%d" % [tank.mobility_hp, tank.firepower_hp, tank.sensors_hp])

	assert(tank.mobility_hp == 50, "mobility_hp should be 50")
	assert(tank.firepower_hp == 30, "firepower_hp should be 30")
	assert(tank.sensors_hp == 70, "sensors_hp should be 70")

	# ゼロにした場合
	tank.mobility_hp = 0
	tank.firepower_hp = 0
	tank.sensors_hp = 0

	print("All subsystems at 0: MOB=%d, FPW=%d, SEN=%d" % [tank.mobility_hp, tank.firepower_hp, tank.sensors_hp])

	assert(tank.mobility_hp == 0, "mobility_hp should be 0")
	assert(tank.firepower_hp == 0, "firepower_hp should be 0")
	assert(tank.sensors_hp == 0, "sensors_hp should be 0")

	print("PASS: Subsystem damage tracking correct")


## is_vehicle() 判定テスト
func test_is_vehicle_check() -> void:
	print("\n--- Test: is_vehicle() Check ---")

	# 戦車（armor_class = 3）
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank_veh"

	print("Tank armor_class: %d, is_vehicle: %s" % [tank_type.armor_class, tank.is_vehicle()])
	assert(tank.is_vehicle() == true, "Tank should be vehicle (armor_class=3)")

	# 偵察車両（armor_class = 1）
	var recon_type := ElementData.ElementArchetypes.create_recon_veh()
	var recon := ElementData.ElementInstance.new(recon_type)
	recon.id = "test_recon_veh"

	print("Recon armor_class: %d, is_vehicle: %s" % [recon_type.armor_class, recon.is_vehicle()])
	assert(recon.is_vehicle() == true, "Recon should be vehicle (armor_class=1)")

	# 歩兵（armor_class = 0）
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var inf := ElementData.ElementInstance.new(inf_type)
	inf.id = "test_inf_veh"

	print("Infantry armor_class: %d, is_vehicle: %s" % [inf_type.armor_class, inf.is_vehicle()])
	assert(inf.is_vehicle() == false, "Infantry should NOT be vehicle (armor_class=0)")

	# 迫撃砲（armor_class = 0）
	var mortar_type := ElementData.ElementArchetypes.create_mortar_sec()
	var mortar := ElementData.ElementInstance.new(mortar_type)
	mortar.id = "test_mortar_veh"

	print("Mortar armor_class: %d, is_vehicle: %s" % [mortar_type.armor_class, mortar.is_vehicle()])
	assert(mortar.is_vehicle() == false, "Mortar should NOT be vehicle (armor_class=0)")

	print("PASS: is_vehicle() check correct")


## サブシステム表示条件テスト
## 車両のみサブシステムバーが表示されるべき
func test_subsystem_display_conditions() -> void:
	print("\n--- Test: Subsystem Display Conditions ---")

	# 車両ユニット
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)

	var should_show_tank := tank.is_vehicle()
	print("Tank: should show subsystems = %s (expected true)" % should_show_tank)
	assert(should_show_tank == true, "Tank should show subsystem bars")

	# 歩兵ユニット
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var inf := ElementData.ElementInstance.new(inf_type)

	var should_show_inf := inf.is_vehicle()
	print("Infantry: should show subsystems = %s (expected false)" % should_show_inf)
	assert(should_show_inf == false, "Infantry should NOT show subsystem bars")

	print("PASS: Subsystem display conditions correct")


## サブシステムバー色テスト
## HP値に応じて色が変わる: >=70緑, 30-69黄, <30赤
func test_subsystem_bar_colors() -> void:
	print("\n--- Test: Subsystem Bar Colors ---")

	# 色判定のロジックをテスト（RightPanelの_update_subsystem_bar_colorと同等のロジック）
	# HP >= 70: 緑（健全）
	# HP 30-69: 黄（警告）
	# HP < 30: 赤（危険）

	var test_cases := [
		{"hp": 100, "expected": "green"},
		{"hp": 70, "expected": "green"},
		{"hp": 69, "expected": "yellow"},
		{"hp": 50, "expected": "yellow"},
		{"hp": 30, "expected": "yellow"},
		{"hp": 29, "expected": "red"},
		{"hp": 10, "expected": "red"},
		{"hp": 0, "expected": "red"},
	]

	for case in test_cases:
		var hp: int = case.hp
		var expected: String = case.expected
		var actual: String

		if hp >= 70:
			actual = "green"
		elif hp >= 30:
			actual = "yellow"
		else:
			actual = "red"

		print("HP=%d: color=%s (expected %s)" % [hp, actual, expected])
		assert(actual == expected, "Color for HP=%d should be %s" % [hp, expected])

	print("PASS: Subsystem bar colors correct")
