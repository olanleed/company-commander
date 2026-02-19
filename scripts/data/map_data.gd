class_name MapData
extends RefCounted

## マップデータを保持するクラス
## 仕様書: docs/map_v0.1.md
##
## GeoJSONから読み込んだマップ情報を格納する。
## 実行時の高速参照用にTerrainGridも保持する。

# =============================================================================
# メタ情報
# =============================================================================

## マップID
var map_id: String = ""

## マップサイズ (メートル)
var size_m: Vector2 = Vector2(2000, 2000)

## 背景画像ファイル名
var background_file: String = "background.png"

## 背景画像サイズ (ピクセル)
var background_size_px: Vector2i = Vector2i(2048, 2048)

## メートル/ピクセル
var meters_per_pixel: float = 0.9765625

## 拠点半径 (メートル)
var cp_radius_m: float = 40.0

# =============================================================================
# 拠点 (Capture Points)
# =============================================================================

## 拠点データ
class CapturePoint:
	var id: String = ""
	var position: Vector2 = Vector2.ZERO
	var attribute: GameEnums.CPAttribute = GameEnums.CPAttribute.COM
	var initial_owner: GameEnums.Faction = GameEnums.Faction.NONE
	var arrival_points: Array[Vector2] = []

## 全拠点
var capture_points: Array[CapturePoint] = []

# =============================================================================
# スポーンポイント
# =============================================================================

## 初期配備スポーンポイント
class EntryPoint:
	var id: String = ""
	var position: Vector2 = Vector2.ZERO
	var faction: GameEnums.Faction = GameEnums.Faction.NONE

## 全初期スポーンポイント
var entry_points: Array[EntryPoint] = []

## 配備可能エリア (ポリゴン)
class DeploymentRegion:
	var faction: GameEnums.Faction = GameEnums.Faction.NONE
	var polygon: PackedVector2Array = PackedVector2Array()

## 全配備エリア
var deployment_regions: Array[DeploymentRegion] = []

# =============================================================================
# 地形
# =============================================================================

## 地形ゾーン
class TerrainZone:
	var terrain_type: GameEnums.TerrainType = GameEnums.TerrainType.OPEN
	var polygon: PackedVector2Array = PackedVector2Array()

## 全地形ゾーン
var terrain_zones: Array[TerrainZone] = []

## ハードブロック (建物、崖など)
class HardBlock:
	var id: String = ""
	var block_type: String = "BUILDING"  # BUILDING, CLIFF
	var polygon: PackedVector2Array = PackedVector2Array()

## 全ハードブロック
var hard_blocks: Array[HardBlock] = []

## 道路中心線
class RoadCenterline:
	var id: String = ""
	var road_type: String = "ROAD"  # TRAIL, ROAD, HIGHWAY
	var points: PackedVector2Array = PackedVector2Array()

## 全道路中心線
var road_centerlines: Array[RoadCenterline] = []

# =============================================================================
# TerrainGrid (高速参照用)
# =============================================================================

## セルサイズ (メートル)
var terrain_grid_cell_m: float = 10.0

## グリッドサイズ
var terrain_grid_size: Vector2i = Vector2i(200, 200)

## 地形グリッド (terrain_id の2次元配列)
## _terrain_grid[y][x] = terrain_id
var _terrain_grid: Array[Array] = []

# =============================================================================
# 地形参照
# =============================================================================

## 指定位置の地形タイプを取得
func get_terrain_at(world_pos: Vector2) -> GameEnums.TerrainType:
	var grid_x := int(world_pos.x / terrain_grid_cell_m)
	var grid_y := int(world_pos.y / terrain_grid_cell_m)

	if grid_x < 0 or grid_x >= terrain_grid_size.x:
		return GameEnums.TerrainType.OPEN
	if grid_y < 0 or grid_y >= terrain_grid_size.y:
		return GameEnums.TerrainType.OPEN

	if _terrain_grid.is_empty():
		return GameEnums.TerrainType.OPEN

	return _terrain_grid[grid_y][grid_x] as GameEnums.TerrainType


## 指定位置が通行可能かどうか
func is_passable(world_pos: Vector2, mobility: GameEnums.MobilityType) -> bool:
	var terrain := get_terrain_at(world_pos)

	match terrain:
		GameEnums.TerrainType.WATER:
			return false
		GameEnums.TerrainType.FOREST:
			return mobility != GameEnums.MobilityType.WHEELED
		GameEnums.TerrainType.URBAN:
			return mobility == GameEnums.MobilityType.FOOT
		_:
			return true


## 指定位置がハードブロック内かどうか
func is_in_hardblock(world_pos: Vector2) -> bool:
	for hb in hard_blocks:
		if Geometry2D.is_point_in_polygon(world_pos, hb.polygon):
			return true
	return false

# =============================================================================
# TerrainGrid構築
# =============================================================================

## 地形ゾーンからTerrainGridを構築する
func build_terrain_grid() -> void:
	_terrain_grid.clear()
	_terrain_grid.resize(terrain_grid_size.y)

	for y in range(terrain_grid_size.y):
		var row: Array = []
		row.resize(terrain_grid_size.x)
		row.fill(GameEnums.TerrainType.OPEN)
		_terrain_grid[y] = row

	# 各地形ゾーンをラスタライズ
	for zone in terrain_zones:
		_rasterize_zone(zone)


## 地形ゾーンをグリッドにラスタライズ
func _rasterize_zone(zone: TerrainZone) -> void:
	if zone.polygon.is_empty():
		return

	# バウンディングボックスを計算
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for p in zone.polygon:
		min_pos.x = min(min_pos.x, p.x)
		min_pos.y = min(min_pos.y, p.y)
		max_pos.x = max(max_pos.x, p.x)
		max_pos.y = max(max_pos.y, p.y)

	# グリッド座標に変換
	var min_grid := Vector2i(
		clampi(int(min_pos.x / terrain_grid_cell_m), 0, terrain_grid_size.x - 1),
		clampi(int(min_pos.y / terrain_grid_cell_m), 0, terrain_grid_size.y - 1)
	)
	var max_grid := Vector2i(
		clampi(int(max_pos.x / terrain_grid_cell_m), 0, terrain_grid_size.x - 1),
		clampi(int(max_pos.y / terrain_grid_cell_m), 0, terrain_grid_size.y - 1)
	)

	# 各セルをチェック
	for gy in range(min_grid.y, max_grid.y + 1):
		for gx in range(min_grid.x, max_grid.x + 1):
			var cell_center := Vector2(
				(gx + 0.5) * terrain_grid_cell_m,
				(gy + 0.5) * terrain_grid_cell_m
			)
			if Geometry2D.is_point_in_polygon(cell_center, zone.polygon):
				# 優先度: WATER > URBAN > FOREST > ROAD > OPEN
				var current: int = _terrain_grid[gy][gx]
				if zone.terrain_type > current:
					_terrain_grid[gy][gx] = zone.terrain_type

# =============================================================================
# 拠点検索
# =============================================================================

## IDで拠点を取得
func get_cp_by_id(cp_id: String) -> CapturePoint:
	for cp in capture_points:
		if cp.id == cp_id:
			return cp
	return null


## 位置から最も近い拠点を取得
func get_nearest_cp(world_pos: Vector2) -> CapturePoint:
	var nearest: CapturePoint = null
	var min_dist := INF
	for cp in capture_points:
		var dist := world_pos.distance_to(cp.position)
		if dist < min_dist:
			min_dist = dist
			nearest = cp
	return nearest


## 位置が拠点ゾーン内かどうか
func is_in_cp_zone(world_pos: Vector2, cp: CapturePoint) -> bool:
	return world_pos.distance_to(cp.position) <= cp_radius_m

# =============================================================================
# 陣営別データ取得
# =============================================================================

## 陣営の初期スポーンポイントを取得
func get_entry_points_for_faction(faction: GameEnums.Faction) -> Array[EntryPoint]:
	var result: Array[EntryPoint] = []
	for ep in entry_points:
		if ep.faction == faction:
			result.append(ep)
	return result


## 陣営の配備エリアを取得
func get_deployment_region_for_faction(faction: GameEnums.Faction) -> DeploymentRegion:
	for dr in deployment_regions:
		if dr.faction == faction:
			return dr
	return null
