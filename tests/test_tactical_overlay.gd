extends SceneTree

## TacticalOverlayのテスト
## godot --headless -s tests/test_tactical_overlay.gd


func _init() -> void:
	print("=== Tactical Overlay Tests ===")
	test_overlay_creation()
	test_view_range_colors()
	test_target_marker_color()
	test_element_view_range()
	print("=== All Tactical Overlay Tests Complete ===")
	quit()


## TacticalOverlay作成テスト
func test_overlay_creation() -> void:
	print("\n--- Test: TacticalOverlay Creation ---")

	var overlay := TacticalOverlay.new()
	assert(overlay != null, "TacticalOverlay should be created")

	# WorldModelを設定
	var world_model := WorldModel.new()
	overlay.setup(world_model)
	assert(overlay.world_model == world_model, "WorldModel should be set")

	# Nodeのfreeはツリー外なのでfree()を直接呼ぶ
	overlay.free()
	# WorldModelはRefCountedなのでfreeは不要（参照カウントで自動解放）
	print("PASS: TacticalOverlay creation correct")


## 視界範囲の色設定テスト
func test_view_range_colors() -> void:
	print("\n--- Test: View Range Colors ---")

	# 視界範囲の色が正しく設定されているか
	var fill_color := TacticalOverlay.COLOR_VIEW_RANGE_FRIENDLY
	var border_color := TacticalOverlay.COLOR_VIEW_RANGE_BORDER

	print("View range fill: R=%.2f G=%.2f B=%.2f A=%.2f" % [
		fill_color.r, fill_color.g, fill_color.b, fill_color.a
	])
	print("View range border: R=%.2f G=%.2f B=%.2f A=%.2f" % [
		border_color.r, border_color.g, border_color.b, border_color.a
	])

	# 塗りは半透明であるべき
	assert(fill_color.a < 0.5, "View range fill should be semi-transparent")

	# 境界線は塗りより目立つべき
	assert(border_color.a > fill_color.a, "Border should be more visible than fill")

	print("PASS: View range colors correct")


## ターゲットマーカーの色設定テスト
func test_target_marker_color() -> void:
	print("\n--- Test: Target Marker Color ---")

	var marker_color := TacticalOverlay.COLOR_TARGET_MARKER

	print("Target marker: R=%.2f G=%.2f B=%.2f A=%.2f" % [
		marker_color.r, marker_color.g, marker_color.b, marker_color.a
	])

	# オレンジ系（rが高い、gが中程度）
	assert(marker_color.r > 0.8, "Target marker should have high red")
	assert(marker_color.g > 0.3 and marker_color.g < 0.7, "Target marker should have medium green")

	# 不透明に近い（見えやすい）
	assert(marker_color.a >= 0.7, "Target marker should be fairly visible")

	print("PASS: Target marker color correct")


## ユニットの視界範囲テスト
func test_element_view_range() -> void:
	print("\n--- Test: Element View Range ---")

	# 戦車小隊を作成
	var tank_type := ElementData.ElementArchetypes.create_tank_plt()
	var tank := ElementData.ElementInstance.new(tank_type)
	tank.id = "test_tank_view"

	print("Tank spot_range_base: %.0fm" % tank_type.spot_range_base)
	print("Tank spot_range_moving: %.0fm" % tank_type.spot_range_moving)

	# 戦車は視界範囲を持つべき
	assert(tank_type.spot_range_base > 0, "Tank should have base spot range")
	assert(tank_type.spot_range_moving > 0, "Tank should have moving spot range")

	# 移動中は視界が狭くなる
	assert(tank_type.spot_range_moving <= tank_type.spot_range_base,
		"Moving spot range should be <= base range")

	# 歩兵を作成
	var inf_type := ElementData.ElementArchetypes.create_inf_line()
	var inf := ElementData.ElementInstance.new(inf_type)
	inf.id = "test_inf_view"

	print("Infantry spot_range_base: %.0fm" % inf_type.spot_range_base)
	print("Infantry spot_range_moving: %.0fm" % inf_type.spot_range_moving)

	assert(inf_type.spot_range_base > 0, "Infantry should have base spot range")

	print("PASS: Element view range correct")
