class_name NavigationManager
extends Node

## NavigationServer2Dを使用した経路探索管理
## 仕様書: docs/navigation_v0.1.md
##
## 3つのNavigationMap × 2つのNavigationLayerで6パターンの経路探索を提供
## - FOOT/WHEELED/TRACKED (機動種別)
## - ALL/ROUTE (通常移動/道路縛り)

# =============================================================================
# シグナル
# =============================================================================

signal navigation_ready

# =============================================================================
# NavigationMap RID
# =============================================================================

var _map_foot: RID
var _map_wheeled: RID
var _map_tracked: RID

# =============================================================================
# NavigationRegion2D参照 (シーンから設定)
# =============================================================================

var _regions: Dictionary = {}  # "foot_terrain" -> NavigationRegion2D など

# =============================================================================
# 定数
# =============================================================================

const LAYER_ALL: int = 1
const LAYER_ROUTE: int = 2

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	_create_navigation_maps()


func _create_navigation_maps() -> void:
	var nav_server := NavigationServer2D

	# 3つのマップを作成
	_map_foot = nav_server.map_create()
	_map_wheeled = nav_server.map_create()
	_map_tracked = nav_server.map_create()

	# マップを有効化
	nav_server.map_set_active(_map_foot, true)
	nav_server.map_set_active(_map_wheeled, true)
	nav_server.map_set_active(_map_tracked, true)

	# パラメータ設定
	for map_rid in [_map_foot, _map_wheeled, _map_tracked]:
		nav_server.map_set_cell_size(map_rid, 10.0)
		nav_server.map_set_edge_connection_margin(map_rid, GameConstants.NAV_EDGE_CONNECTION_MARGIN)

	print("NavigationManager: 3 maps created")

# =============================================================================
# マップ構築
# =============================================================================

## マップデータからナビゲーションリージョンを構築
func build_from_map_data(map_data: MapData) -> void:
	if not map_data:
		push_error("NavigationManager: map_data is null")
		return

	# 各機動種別のリージョンを構築
	_build_foot_regions(map_data)
	_build_wheeled_regions(map_data)
	_build_tracked_regions(map_data)

	# 次のphysics frameで反映されるのを待つ
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("NavigationManager: Navigation regions built")
	navigation_ready.emit()


func _build_foot_regions(map_data: MapData) -> void:
	# FOOT: マップ全体を通行可能エリアとして設定
	var terrain_poly := _create_full_map_polygon(map_data)
	print("NavigationManager: FOOT terrain polygon: ", terrain_poly)

	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(terrain_poly)
	nav_poly.make_polygons_from_outlines()

	# デバッグ: ポリゴン数を確認
	print("NavigationManager: FOOT nav_poly polygon count: ", nav_poly.get_polygon_count())

	_add_region_to_map(_map_foot, nav_poly, LAYER_ALL, GameConstants.NAV_TERRAIN_TRAVEL_COST)


func _build_wheeled_regions(map_data: MapData) -> void:
	# WHEELED: マップ全体を通行可能エリアとして設定
	var terrain_poly := _create_full_map_polygon(map_data)

	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(terrain_poly)
	nav_poly.make_polygons_from_outlines()

	print("NavigationManager: WHEELED nav_poly polygon count: ", nav_poly.get_polygon_count())

	_add_region_to_map(_map_wheeled, nav_poly, LAYER_ALL, GameConstants.NAV_TERRAIN_TRAVEL_COST)


func _build_tracked_regions(map_data: MapData) -> void:
	# TRACKED: マップ全体を通行可能エリアとして設定
	var terrain_poly := _create_full_map_polygon(map_data)

	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(terrain_poly)
	nav_poly.make_polygons_from_outlines()

	print("NavigationManager: TRACKED nav_poly polygon count: ", nav_poly.get_polygon_count())

	_add_region_to_map(_map_tracked, nav_poly, LAYER_ALL, GameConstants.NAV_TERRAIN_TRAVEL_COST)

# =============================================================================
# ポリゴン生成ヘルパー
# =============================================================================

func _create_full_map_polygon(map_data: MapData) -> PackedVector2Array:
	# Godot 4 NavigationPolygon: 外周は反時計回り (CCW)
	# ただし、add_outline は反転を自動処理するので、単純な矩形でOK
	var poly := PackedVector2Array([
		Vector2(0, 0),
		Vector2(map_data.size_m.x, 0),
		Vector2(map_data.size_m.x, map_data.size_m.y),
		Vector2(0, map_data.size_m.y)
	])
	print("NavigationManager: Full map polygon: ", poly)
	return poly


func _get_water_polygons(map_data: MapData) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for zone in map_data.terrain_zones:
		if zone.terrain_type == GameEnums.TerrainType.WATER:
			result.append(zone.polygon)
	return result


func _get_hardblock_polygons(map_data: MapData) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for hb in map_data.hard_blocks:
		result.append(hb.polygon)
	return result


func _create_wheeled_passable_polygon(map_data: MapData) -> PackedVector2Array:
	# 簡易実装: マップ全体から FOREST, URBAN, WATER を除外
	# TODO: より正確なポリゴン演算
	return _create_full_map_polygon(map_data)


func _create_tracked_passable_polygon(map_data: MapData) -> PackedVector2Array:
	# 簡易実装: マップ全体から URBAN, WATER を除外
	return _create_full_map_polygon(map_data)


func _create_road_polygon(map_data: MapData) -> PackedVector2Array:
	# 道路ゾーンを結合
	for zone in map_data.terrain_zones:
		if zone.terrain_type == GameEnums.TerrainType.ROAD:
			return zone.polygon
	return PackedVector2Array()


func _create_nav_polygon_with_holes(outline: PackedVector2Array, holes: Array[PackedVector2Array]) -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(outline)

	for hole in holes:
		if hole.size() >= 3:
			nav_poly.add_outline(hole)

	nav_poly.make_polygons_from_outlines()
	return nav_poly


func _add_region_to_map(map_rid: RID, nav_poly: NavigationPolygon, layers: int, travel_cost: float) -> void:
	var region_rid := NavigationServer2D.region_create()
	NavigationServer2D.region_set_map(region_rid, map_rid)
	NavigationServer2D.region_set_navigation_polygon(region_rid, nav_poly)
	NavigationServer2D.region_set_navigation_layers(region_rid, layers)
	NavigationServer2D.region_set_travel_cost(region_rid, travel_cost)

# =============================================================================
# 経路探索
# =============================================================================

## 経路を取得
func find_path(from: Vector2, to: Vector2, mobility: GameEnums.MobilityType, use_route: bool = false) -> PackedVector2Array:
	var map_rid := _get_map_for_mobility(mobility)
	var layer := LAYER_ROUTE if use_route else LAYER_ALL

	var path := NavigationServer2D.map_get_path(map_rid, from, to, true, layer)

	# ROUTEでパスが取れなかったらALLにフォールバック
	if path.is_empty() and use_route:
		path = NavigationServer2D.map_get_path(map_rid, from, to, true, LAYER_ALL)

	return path


## 指定位置が通行可能か
func is_position_navigable(pos: Vector2, mobility: GameEnums.MobilityType) -> bool:
	var map_rid := _get_map_for_mobility(mobility)
	var closest := NavigationServer2D.map_get_closest_point(map_rid, pos)
	return pos.distance_to(closest) < 5.0


func _get_map_for_mobility(mobility: GameEnums.MobilityType) -> RID:
	match mobility:
		GameEnums.MobilityType.FOOT:
			return _map_foot
		GameEnums.MobilityType.WHEELED:
			return _map_wheeled
		GameEnums.MobilityType.TRACKED:
			return _map_tracked
		_:
			return _map_foot

# =============================================================================
# デバッグ
# =============================================================================

## デバッグ用: マップ情報を出力
func debug_print_info() -> void:
	print("=== NavigationManager Debug ===")
	print("Map FOOT: ", _map_foot)
	print("Map WHEELED: ", _map_wheeled)
	print("Map TRACKED: ", _map_tracked)
