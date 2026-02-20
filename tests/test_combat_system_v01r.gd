extends GutTest

## CombatSystem v0.1R のユニットテスト
## 仕様書: docs/combat_v0.1.md (v0.1R)
##
## 主な変更点:
## - 抑圧と損耗の脆弱性分離 (vulnerability_dmg_vs / vulnerability_supp_vs)
## - 離散ヒットイベントモデル (p_hit = 1 - exp(-K × E))
## - 車両サブシステムHP (mobility_hp, firepower_hp, sensors_hp)
## - アスペクトアングル (Front/Side/Rear/Top)

var combat_system: CombatSystem


func before_each() -> void:
	combat_system = CombatSystem.new()


# =============================================================================
# 定数テスト (v0.1R)
# =============================================================================

func test_v01r_constants_exist() -> void:
	# v0.1R定数が存在することを確認
	assert_eq(GameConstants.K_DF_SUPP, 2.2, "K_DF_SUPP should be 2.2")
	assert_eq(GameConstants.K_DF_HIT, 0.25, "K_DF_HIT should be 0.25")
	assert_eq(GameConstants.K_IF_SUPP, 24.0, "K_IF_SUPP should be 24")
	assert_eq(GameConstants.K_IF_HIT, 0.65, "K_IF_HIT should be 0.65")


# =============================================================================
# 脆弱性分離テスト
# =============================================================================

func test_vulnerability_dmg_vs_soft_smallarms() -> void:
	# Soft(歩兵)はsmallarms dmg脆弱性 = 1.0
	var target: ElementData.ElementInstance = _create_soft_element()
	var vuln: float = combat_system.get_vulnerability_dmg(target, WeaponData.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln, 1.0, 0.01)


func test_vulnerability_supp_vs_soft_smallarms() -> void:
	# Soft(歩兵)はsmallarms supp脆弱性 = 1.0
	var target: ElementData.ElementInstance = _create_soft_element()
	var vuln: float = combat_system.get_vulnerability_supp(target, WeaponData.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln, 1.0, 0.01)


func test_vulnerability_dmg_vs_heavy_smallarms() -> void:
	# Heavy(戦車)はsmallarms dmg脆弱性 = 0.0
	var target: ElementData.ElementInstance = _create_heavy_element()
	var vuln: float = combat_system.get_vulnerability_dmg(target, WeaponData.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln, 0.0, 0.01)


func test_vulnerability_supp_vs_heavy_smallarms() -> void:
	# Heavy(戦車)はsmallarms supp脆弱性 = 0.10（小銃でも少しは抑圧される）
	var target: ElementData.ElementInstance = _create_heavy_element()
	var vuln: float = combat_system.get_vulnerability_supp(target, WeaponData.ThreatClass.SMALL_ARMS)
	assert_almost_eq(vuln, 0.10, 0.01)


func test_vulnerability_dmg_vs_heavy_at() -> void:
	# Heavy(戦車)はAT dmg脆弱性 = 1.0
	var target: ElementData.ElementInstance = _create_heavy_element()
	var vuln: float = combat_system.get_vulnerability_dmg(target, WeaponData.ThreatClass.AT)
	assert_almost_eq(vuln, 1.0, 0.01)


func test_vulnerability_supp_vs_heavy_at() -> void:
	# Heavy(戦車)はAT supp脆弱性 = 1.0
	var target: ElementData.ElementInstance = _create_heavy_element()
	var vuln: float = combat_system.get_vulnerability_supp(target, WeaponData.ThreatClass.AT)
	assert_almost_eq(vuln, 1.0, 0.01)


# =============================================================================
# 離散ヒットイベントテスト
# =============================================================================

func test_hit_probability_calculation() -> void:
	# p_hit = 1 - exp(-K_DF_HIT × E)
	# E = 1.0 の場合: p_hit = 1 - exp(-0.25) ≈ 0.221
	var p_hit: float = combat_system.calculate_hit_probability(1.0)
	var expected: float = 1.0 - exp(-GameConstants.K_DF_HIT * 1.0)
	assert_almost_eq(p_hit, expected, 0.001)


func test_hit_probability_zero_exposure() -> void:
	# E = 0 の場合: p_hit = 0
	var p_hit: float = combat_system.calculate_hit_probability(0.0)
	assert_almost_eq(p_hit, 0.0, 0.001)


func test_hit_probability_high_exposure() -> void:
	# E = 2.0 の場合: p_hit = 1 - exp(-0.5) ≈ 0.393
	var p_hit: float = combat_system.calculate_hit_probability(2.0)
	var expected: float = 1.0 - exp(-GameConstants.K_DF_HIT * 2.0)
	assert_almost_eq(p_hit, expected, 0.001)


func test_calculate_exposure_df() -> void:
	# 直射の期待危険度 E を計算
	var shooter: ElementData.ElementInstance = _create_soft_element()
	var target: ElementData.ElementInstance = _create_soft_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0  # Mid範囲

	var exposure: float = combat_system.calculate_exposure_df(
		shooter, target, weapon, distance,
		1.0,  # t_los
		GameEnums.TerrainType.OPEN,
		false  # not entrenched
	)

	# 正の値であること
	assert_gt(exposure, 0.0, "Exposure should be positive")
	# 1.0を超えることも可能（高L、好条件）
	# だが中距離・ライフルなので1未満のはず
	assert_lt(exposure, 1.5, "Exposure should be reasonable for rifle at mid range")


# =============================================================================
# 車両サブシステムHPテスト
# =============================================================================

func test_vehicle_subsystem_hp_initial() -> void:
	# 車両の初期サブシステムHPは100
	var vehicle: ElementData.ElementInstance = _create_heavy_element()
	assert_eq(vehicle.mobility_hp, 100)
	assert_eq(vehicle.firepower_hp, 100)
	assert_eq(vehicle.sensors_hp, 100)


func test_vehicle_mobility_state_normal() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()
	vehicle.mobility_hp = 60
	var state: GameEnums.VehicleMobilityState = combat_system.get_mobility_state(vehicle)
	assert_eq(state, GameEnums.VehicleMobilityState.NORMAL)


func test_vehicle_mobility_state_damaged() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()
	vehicle.mobility_hp = 40
	var state: GameEnums.VehicleMobilityState = combat_system.get_mobility_state(vehicle)
	assert_eq(state, GameEnums.VehicleMobilityState.DAMAGED)


func test_vehicle_mobility_state_critical() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()
	vehicle.mobility_hp = 15
	var state: GameEnums.VehicleMobilityState = combat_system.get_mobility_state(vehicle)
	assert_eq(state, GameEnums.VehicleMobilityState.CRITICAL)


func test_vehicle_mobility_state_immobilized() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()
	vehicle.mobility_hp = 0
	var state: GameEnums.VehicleMobilityState = combat_system.get_mobility_state(vehicle)
	assert_eq(state, GameEnums.VehicleMobilityState.IMMOBILIZED)


func test_vehicle_mobility_speed_multiplier() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()

	# Normal: ×1.0
	vehicle.mobility_hp = 60
	assert_almost_eq(combat_system.get_vehicle_speed_multiplier(vehicle), 1.0, 0.01)

	# Damaged: ×0.70
	vehicle.mobility_hp = 40
	assert_almost_eq(combat_system.get_vehicle_speed_multiplier(vehicle), 0.70, 0.01)

	# Critical: ×0.35
	vehicle.mobility_hp = 15
	assert_almost_eq(combat_system.get_vehicle_speed_multiplier(vehicle), 0.35, 0.01)

	# Immobilized: ×0
	vehicle.mobility_hp = 0
	assert_almost_eq(combat_system.get_vehicle_speed_multiplier(vehicle), 0.0, 0.01)


func test_vehicle_firepower_state() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()

	# Normal (>50)
	vehicle.firepower_hp = 60
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.NORMAL)

	# Damaged (25-50)
	vehicle.firepower_hp = 40
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.DAMAGED)

	# Critical (1-25)
	vehicle.firepower_hp = 15
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.CRITICAL)

	# WeaponDisabled (0)
	vehicle.firepower_hp = 0
	assert_eq(combat_system.get_firepower_state(vehicle), GameEnums.VehicleFirepowerState.WEAPON_DISABLED)


func test_vehicle_sensors_state() -> void:
	var vehicle: ElementData.ElementInstance = _create_heavy_element()

	# Normal (>50)
	vehicle.sensors_hp = 60
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.NORMAL)

	# Damaged (25-50)
	vehicle.sensors_hp = 40
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.DAMAGED)

	# Critical (1-25)
	vehicle.sensors_hp = 15
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.CRITICAL)

	# SensorsDown (0)
	vehicle.sensors_hp = 0
	assert_eq(combat_system.get_sensors_state(vehicle), GameEnums.VehicleSensorsState.SENSORS_DOWN)


# =============================================================================
# アスペクトアングルテスト
# =============================================================================

func test_aspect_angle_front() -> void:
	# 射手が目標の正面にいる場合
	var shooter_pos: Vector2 = Vector2(0, 0)
	var target_pos: Vector2 = Vector2(100, 0)
	# 目標が射手の方を向いている（=東向き、PI）
	var target_facing: float = PI

	var aspect: WeaponData.ArmorZone = combat_system.calculate_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, WeaponData.ArmorZone.FRONT)


func test_aspect_angle_rear() -> void:
	# 射手が目標の背後にいる場合
	var shooter_pos: Vector2 = Vector2(200, 0)
	var target_pos: Vector2 = Vector2(100, 0)
	var target_facing: float = PI  # 東向き（左側を向いている）→ 射手は後方

	var aspect: WeaponData.ArmorZone = combat_system.calculate_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, WeaponData.ArmorZone.REAR)


func test_aspect_angle_side() -> void:
	# 射手が目標の側面にいる場合
	var shooter_pos: Vector2 = Vector2(100, 100)
	var target_pos: Vector2 = Vector2(100, 0)
	var target_facing: float = PI  # 東向き → 射手は南側（side）

	var aspect: WeaponData.ArmorZone = combat_system.calculate_aspect(shooter_pos, target_pos, target_facing)
	assert_eq(aspect, WeaponData.ArmorZone.SIDE)


func test_aspect_multiplier_heavy() -> void:
	# Heavy車両のアスペクト倍率
	var target: ElementData.ElementInstance = _create_heavy_element()

	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.FRONT), 0.70, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.SIDE), 1.00, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.REAR), 1.25, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.TOP), 1.10, 0.01)


func test_aspect_multiplier_light() -> void:
	# Light車両のアスペクト倍率
	var target: ElementData.ElementInstance = _create_light_element()

	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.FRONT), 0.95, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.SIDE), 1.10, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.REAR), 1.20, 0.01)
	assert_almost_eq(combat_system.get_aspect_multiplier(target, WeaponData.ArmorZone.TOP), 1.10, 0.01)


# =============================================================================
# 被害分布テスト
# =============================================================================

func test_damage_category_distribution() -> void:
	# ダメージカテゴリの分布確認（統計的テスト）
	var categories: Dictionary = {
		GameEnums.DamageCategory.MINOR: 0,
		GameEnums.DamageCategory.MAJOR: 0,
		GameEnums.DamageCategory.CRITICAL: 0,
	}

	var iterations: int = 1000
	for i: int in iterations:
		var cat: GameEnums.DamageCategory = combat_system.roll_damage_category(0.5)  # 中程度のE
		categories[cat] += 1

	# Minor が最も多いはず（base: 0.75 または 0.60 depending on E）
	assert_gt(categories[GameEnums.DamageCategory.MINOR], categories[GameEnums.DamageCategory.MAJOR])
	# Critical は最も少ないはず
	assert_lt(categories[GameEnums.DamageCategory.CRITICAL], categories[GameEnums.DamageCategory.MAJOR])


func test_soft_damage_amount() -> void:
	# Soft（歩兵）へのダメージ量が仕様範囲内
	var damage_minor: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.MINOR)
	assert_true(damage_minor >= 0.8, "Minor damage should be >= 0.8")
	assert_true(damage_minor <= 2.0, "Minor damage should be <= 2.0")

	var damage_major: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.MAJOR)
	assert_true(damage_major >= 2.0, "Major damage should be >= 2.0")
	assert_true(damage_major <= 5.0, "Major damage should be <= 5.0")

	var damage_critical: float = combat_system.calculate_soft_damage(GameEnums.DamageCategory.CRITICAL)
	assert_true(damage_critical >= 5.0, "Critical damage should be >= 5.0")
	assert_true(damage_critical <= 12.0, "Critical damage should be <= 12.0")


# =============================================================================
# v0.1R直射効果テスト（統合）
# =============================================================================

func test_direct_fire_v01r_returns_suppression_and_hit_chance() -> void:
	var shooter: ElementData.ElementInstance = _create_soft_element()
	var target: ElementData.ElementInstance = _create_soft_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0

	# v0.1Rの直射効果を計算
	var result: RefCounted = combat_system.calculate_direct_fire_effect_v01r(
		shooter, target, weapon, distance, 1.0,  # dt=1.0秒
		1.0,  # t_los
		GameEnums.TerrainType.OPEN,
		false  # not entrenched
	)

	# 抑圧増加が正の値
	assert_gt(result.d_supp, 0.0, "Suppression should increase")

	# ヒット確率が0-1の範囲
	assert_true(result.p_hit >= 0.0, "Hit probability should be >= 0")
	assert_true(result.p_hit <= 1.0, "Hit probability should be <= 1")


func test_direct_fire_v01r_tank_vs_rifle() -> void:
	# 戦車に小銃で撃った場合
	var shooter: ElementData.ElementInstance = _create_soft_element()
	var target: ElementData.ElementInstance = _create_heavy_element()
	var weapon: WeaponData.WeaponType = WeaponData.create_rifle()
	var distance: float = 300.0

	var result: RefCounted = combat_system.calculate_direct_fire_effect_v01r(
		shooter, target, weapon, distance, 1.0,
		1.0, GameEnums.TerrainType.OPEN, false
	)

	# 抑圧は少し入る（vulnerability_supp = 0.10）
	assert_gt(result.d_supp, 0.0, "Some suppression even on tank")

	# ヒット確率は0（vulnerability_dmg = 0.0）
	assert_almost_eq(result.p_hit, 0.0, 0.001, "No hit chance for rifle vs tank")


# =============================================================================
# ヘルパー
# =============================================================================

func _create_soft_element() -> ElementData.ElementInstance:
	var element_type: ElementData.ElementType = ElementData.ElementType.new()
	element_type.id = "test_infantry"
	element_type.max_strength = 100
	element_type.armor_class = 0  # Soft

	var element: ElementData.ElementInstance = ElementData.ElementInstance.new(element_type)
	element.id = "test_soft_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 100
	element.is_moving = false

	return element


func _create_light_element() -> ElementData.ElementInstance:
	var element_type: ElementData.ElementType = ElementData.ElementType.new()
	element_type.id = "test_light_armor"
	element_type.max_strength = 100
	element_type.armor_class = 1  # Light

	var element: ElementData.ElementInstance = ElementData.ElementInstance.new(element_type)
	element.id = "test_light_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 100
	element.is_moving = false

	return element


func _create_heavy_element() -> ElementData.ElementInstance:
	var element_type: ElementData.ElementType = ElementData.ElementType.new()
	element_type.id = "test_heavy_armor"
	element_type.max_strength = 100
	element_type.armor_class = 3  # Heavy

	var element: ElementData.ElementInstance = ElementData.ElementInstance.new(element_type)
	element.id = "test_heavy_" + str(randi())
	element.faction = GameEnums.Faction.BLUE
	element.position = Vector2(500, 500)
	element.suppression = 0.0
	element.current_strength = 100
	element.is_moving = false

	return element
