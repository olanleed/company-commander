class_name MapLoader
extends RefCounted

## GeoJSONからMapDataを読み込むローダー
## 仕様書: docs/map_v0.1.md

# =============================================================================
# 定数
# =============================================================================

const SCHEMA_VERSION := "map_v0.1"

# =============================================================================
# ロード
# =============================================================================

## マップをロードする
## map_path: "res://maps/<map_id>/" 形式のパス
static func load_map(map_path: String) -> MapData:
	var geojson_path := map_path.path_join("map.geojson")

	if not FileAccess.file_exists(geojson_path):
		push_error("MapLoader: map.geojson not found at " + geojson_path)
		return null

	var file := FileAccess.open(geojson_path, FileAccess.READ)
	if not file:
		push_error("MapLoader: Failed to open " + geojson_path)
		return null

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("MapLoader: JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return null

	var data: Dictionary = json.data
	return _parse_geojson(data, map_path)


## GeoJSONデータをパースしてMapDataを構築
static func _parse_geojson(data: Dictionary, map_path: String) -> MapData:
	var map := MapData.new()

	# メタ情報
	map.map_id = data.get("name", "unknown")

	var props: Dictionary = data.get("properties", {})

	# スキーマバージョンチェック
	var schema: String = props.get("schema", "")
	if schema != SCHEMA_VERSION:
		push_warning("MapLoader: Schema version mismatch. Expected " + SCHEMA_VERSION + ", got " + schema)

	# サイズ
	var size_arr: Array = props.get("size_m", [2000, 2000])
	map.size_m = Vector2(size_arr[0], size_arr[1])

	# 背景
	var bg: Dictionary = props.get("background", {})
	map.background_file = bg.get("file", "background.png")
	var bg_size: Array = bg.get("size_px", [2048, 2048])
	map.background_size_px = Vector2i(bg_size[0], bg_size[1])
	map.meters_per_pixel = bg.get("meters_per_pixel", map.size_m.x / bg_size[0])

	# 拠点半径
	map.cp_radius_m = props.get("cp_radius_m", 40.0)

	# 初期拠点制御
	var initial_cp_control: Dictionary = props.get("initial_cp_control", {})

	# 地形グリッド設定
	var tg: Dictionary = props.get("terrain_grid", {})
	map.terrain_grid_cell_m = tg.get("cell_m", 10.0)
	map.terrain_grid_size = Vector2i(
		int(map.size_m.x / map.terrain_grid_cell_m),
		int(map.size_m.y / map.terrain_grid_cell_m)
	)

	# Features をパース
	var features: Array = data.get("features", [])
	for feature in features:
		_parse_feature(feature, map, initial_cp_control)

	# TerrainGridを構築
	map.build_terrain_grid()

	return map


## 個別のFeatureをパース
static func _parse_feature(feature: Dictionary, map: MapData, initial_cp_control: Dictionary) -> void:
	var props: Dictionary = feature.get("properties", {})
	var kind: String = props.get("kind", "")
	var geometry: Dictionary = feature.get("geometry", {})
	var geom_type: String = geometry.get("type", "")
	var coords: Variant = geometry.get("coordinates", [])

	match kind:
		"cp":
			_parse_cp(props, coords, map, initial_cp_control)
		"arrival_point":
			_parse_arrival_point(props, coords, map)
		"entry_point":
			_parse_entry_point(props, coords, map)
		"deployment_region":
			_parse_deployment_region(props, coords, map)
		"terrain_zone":
			_parse_terrain_zone(props, coords, map)
		"hardblock":
			_parse_hardblock(props, coords, map)
		"road_centerline":
			_parse_road_centerline(props, coords, map)


## 拠点をパース
static func _parse_cp(props: Dictionary, coords: Variant, map: MapData, initial_cp_control: Dictionary) -> void:
	var cp := MapData.CapturePoint.new()
	cp.id = props.get("id", "")
	cp.position = _coords_to_vector2(coords)

	# 属性
	var attr_str: String = props.get("attribute", "COM")
	cp.attribute = _parse_cp_attribute(attr_str)

	# 初期所有者
	var owner_str: String = initial_cp_control.get(cp.id, "NEUTRAL")
	cp.initial_owner = _parse_faction(owner_str)

	map.capture_points.append(cp)


## 到着ポイントをパース
static func _parse_arrival_point(props: Dictionary, coords: Variant, map: MapData) -> void:
	var ap_id: String = props.get("id", "")
	var position := _coords_to_vector2(coords)
	var cp_id: String = props.get("cp_id", "")

	# 対応するCPを探してarrival_pointsに追加
	for cp in map.capture_points:
		if cp.id == cp_id:
			cp.arrival_points.append(position)
			break


## 初期スポーンポイントをパース
static func _parse_entry_point(props: Dictionary, coords: Variant, map: MapData) -> void:
	var ep := MapData.EntryPoint.new()
	ep.id = props.get("id", "")
	ep.position = _coords_to_vector2(coords)

	var faction_str: String = props.get("faction", "NONE")
	ep.faction = _parse_faction(faction_str)

	map.entry_points.append(ep)


## 配備エリアをパース
static func _parse_deployment_region(props: Dictionary, coords: Variant, map: MapData) -> void:
	var dr := MapData.DeploymentRegion.new()

	var faction_str: String = props.get("faction", "NONE")
	dr.faction = _parse_faction(faction_str)

	dr.polygon = _coords_to_polygon(coords)

	map.deployment_regions.append(dr)


## 地形ゾーンをパース
static func _parse_terrain_zone(props: Dictionary, coords: Variant, map: MapData) -> void:
	var zone := MapData.TerrainZone.new()

	var terrain_str: String = props.get("terrain_type", "OPEN")
	zone.terrain_type = _parse_terrain_type(terrain_str)

	zone.polygon = _coords_to_polygon(coords)

	map.terrain_zones.append(zone)


## ハードブロックをパース
static func _parse_hardblock(props: Dictionary, coords: Variant, map: MapData) -> void:
	var hb := MapData.HardBlock.new()
	hb.id = props.get("id", "")
	hb.block_type = props.get("block_type", "BUILDING")
	hb.polygon = _coords_to_polygon(coords)

	map.hard_blocks.append(hb)


## 道路中心線をパース
static func _parse_road_centerline(props: Dictionary, coords: Variant, map: MapData) -> void:
	var road := MapData.RoadCenterline.new()
	road.id = props.get("id", "")
	road.road_type = props.get("road_type", "ROAD")

	# LineStringの座標
	if coords is Array:
		for point in coords:
			if point is Array and point.size() >= 2:
				road.points.append(Vector2(point[0], point[1]))

	map.road_centerlines.append(road)

# =============================================================================
# ユーティリティ
# =============================================================================

## GeoJSON座標をVector2に変換
static func _coords_to_vector2(coords: Variant) -> Vector2:
	if coords is Array and coords.size() >= 2:
		return Vector2(coords[0], coords[1])
	return Vector2.ZERO


## GeoJSONポリゴン座標をPackedVector2Arrayに変換
static func _coords_to_polygon(coords: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()

	if not coords is Array:
		return result

	# Polygon: [[[x,y], [x,y], ...]]
	if coords.size() > 0 and coords[0] is Array:
		var ring: Array = coords[0]
		for point in ring:
			if point is Array and point.size() >= 2:
				result.append(Vector2(point[0], point[1]))

	return result


## 陣営文字列をパース
static func _parse_faction(faction_str: String) -> GameEnums.Faction:
	match faction_str.to_upper():
		"BLUE":
			return GameEnums.Faction.BLUE
		"RED":
			return GameEnums.Faction.RED
		_:
			return GameEnums.Faction.NONE


## 拠点属性文字列をパース
static func _parse_cp_attribute(attr_str: String) -> GameEnums.CPAttribute:
	match attr_str.to_upper():
		"COM":
			return GameEnums.CPAttribute.COM
		"LOG":
			return GameEnums.CPAttribute.LOG
		"OBS":
			return GameEnums.CPAttribute.OBS
		_:
			return GameEnums.CPAttribute.COM


## 地形タイプ文字列をパース
static func _parse_terrain_type(terrain_str: String) -> GameEnums.TerrainType:
	match terrain_str.to_upper():
		"OPEN":
			return GameEnums.TerrainType.OPEN
		"ROAD":
			return GameEnums.TerrainType.ROAD
		"FOREST":
			return GameEnums.TerrainType.FOREST
		"URBAN":
			return GameEnums.TerrainType.URBAN
		"WATER":
			return GameEnums.TerrainType.WATER
		_:
			return GameEnums.TerrainType.OPEN
