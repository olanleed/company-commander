extends GutTest

## WeaponDataのユニットテスト

var WeaponDataClass: GDScript


func before_all() -> void:
	WeaponDataClass = load("res://scripts/data/weapon_data.gd")


func test_weapon_type_creation() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.id = "rifle_m4"
	weapon.display_name = "M4A1 Carbine"
	weapon.mechanism = WeaponDataClass.Mechanism.SMALL_ARMS
	weapon.fire_model = WeaponDataClass.FireModel.CONTINUOUS
	weapon.min_range_m = 0.0
	weapon.max_range_m = 500.0

	assert_eq(weapon.id, "rifle_m4")
	assert_eq(weapon.mechanism, WeaponDataClass.Mechanism.SMALL_ARMS)
	assert_eq(weapon.fire_model, WeaponDataClass.FireModel.CONTINUOUS)
	assert_eq(weapon.max_range_m, 500.0)


func test_range_band_determination() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.range_band_thresholds_m = [200.0, 800.0]  # Near < 200 < Mid < 800 < Far

	# Near範囲
	assert_eq(weapon.get_range_band(100.0), WeaponDataClass.RangeBand.NEAR)
	assert_eq(weapon.get_range_band(199.0), WeaponDataClass.RangeBand.NEAR)

	# Mid範囲
	assert_eq(weapon.get_range_band(200.0), WeaponDataClass.RangeBand.MID)
	assert_eq(weapon.get_range_band(500.0), WeaponDataClass.RangeBand.MID)
	assert_eq(weapon.get_range_band(799.0), WeaponDataClass.RangeBand.MID)

	# Far範囲
	assert_eq(weapon.get_range_band(800.0), WeaponDataClass.RangeBand.FAR)
	assert_eq(weapon.get_range_band(1500.0), WeaponDataClass.RangeBand.FAR)


func test_lethality_rating_retrieval() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.range_band_thresholds_m = [200.0, 800.0]

	# lethalityはband×target_classで設定
	weapon.lethality = {
		WeaponDataClass.RangeBand.NEAR: {
			WeaponDataClass.TargetClass.SOFT: 60,
			WeaponDataClass.TargetClass.LIGHT: 20,
			WeaponDataClass.TargetClass.HEAVY: 0,
		},
		WeaponDataClass.RangeBand.MID: {
			WeaponDataClass.TargetClass.SOFT: 45,
			WeaponDataClass.TargetClass.LIGHT: 15,
			WeaponDataClass.TargetClass.HEAVY: 0,
		},
		WeaponDataClass.RangeBand.FAR: {
			WeaponDataClass.TargetClass.SOFT: 25,
			WeaponDataClass.TargetClass.LIGHT: 5,
			WeaponDataClass.TargetClass.HEAVY: 0,
		},
	}

	# Near範囲でSoft目標
	var rating := weapon.get_lethality(100.0, WeaponDataClass.TargetClass.SOFT)
	assert_eq(rating, 60)

	# Mid範囲でLight目標
	rating = weapon.get_lethality(400.0, WeaponDataClass.TargetClass.LIGHT)
	assert_eq(rating, 15)

	# Far範囲でHeavy目標
	rating = weapon.get_lethality(1000.0, WeaponDataClass.TargetClass.HEAVY)
	assert_eq(rating, 0)


func test_suppression_power_retrieval() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.range_band_thresholds_m = [200.0, 800.0]
	weapon.suppression_power = {
		WeaponDataClass.RangeBand.NEAR: 70,
		WeaponDataClass.RangeBand.MID: 50,
		WeaponDataClass.RangeBand.FAR: 30,
	}

	assert_eq(weapon.get_suppression_power(100.0), 70)
	assert_eq(weapon.get_suppression_power(500.0), 50)
	assert_eq(weapon.get_suppression_power(1000.0), 30)


func test_weapon_in_range() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.min_range_m = 50.0
	weapon.max_range_m = 800.0

	assert_false(weapon.is_in_range(40.0), "Should be out of min range")
	assert_true(weapon.is_in_range(50.0), "Should be at min range")
	assert_true(weapon.is_in_range(400.0), "Should be in range")
	assert_true(weapon.is_in_range(800.0), "Should be at max range")
	assert_false(weapon.is_in_range(801.0), "Should be out of max range")


func test_threat_class() -> void:
	var weapon := WeaponDataClass.WeaponType.new()
	weapon.threat_class = WeaponDataClass.ThreatClass.SMALL_ARMS

	assert_eq(weapon.threat_class, WeaponDataClass.ThreatClass.SMALL_ARMS)

	weapon.threat_class = WeaponDataClass.ThreatClass.AUTOCANNON
	assert_eq(weapon.threat_class, WeaponDataClass.ThreatClass.AUTOCANNON)
