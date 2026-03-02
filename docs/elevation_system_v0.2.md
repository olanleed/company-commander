# 標高システム仕様書 v0.2

## 概要

ハイトマップ方式による地形の起伏表現システム。グレースケール画像で標高データを保持し、等高線をUI上で動的に描画する。

---

## 1. 設計方針

### 1.1 目的

- 地形の起伏（丘陵、谷、尾根）を表現
- 高低差による視界・射撃・移動への影響を実装
- 等高線による視覚的フィードバック

### 1.2 スコープ

| 機能 | v0.2 | 将来 |
|------|------|------|
| ハイトマップ読み込み | ✓ | - |
| 標高グリッド構築 | ✓ | - |
| 等高線描画 | ✓ | - |
| 視界への影響（高所優位） | ✓ | - |
| 射撃への影響（俯角/仰角） | - | v0.3 |
| 移動への影響（勾配） | - | v0.3 |
| 崖・断崖の通行不可判定 | - | v0.3 |

### 1.3 既存システムとの関係

```
MapLoader
    ├── map.geojson (既存: CP, スポーン, 地形ゾーン)
    └── elevation.png (新規: ハイトマップ)
            ↓
        MapData
            ├── terrain_grid (既存: 地形タイプ)
            └── elevation_grid (新規: 標高データ)
                    ↓
                ElevationCalc (新規: 純粋関数)
                    ├── get_elevation_at()
                    ├── get_slope_between()
                    ├── get_los_elevation_advantage()
                    └── extract_contour_lines()
                            ↓
                        ContourRenderer (新規: UI描画)
```

---

## 2. データモデル

### 2.1 ハイトマップ仕様

**ファイル形式**: PNG（グレースケール、8bit）

```
maps/MAP_NAME/
    ├── map.geojson        # 既存
    └── elevation.png      # 新規: ハイトマップ
```

**画像仕様**:

| 項目 | 値 | 説明 |
|------|-----|------|
| フォーマット | PNG 8bit グレースケール | Godot Image で読み込み可能 |
| サイズ | マップサイズに依存 | 例: 2000m → 200x200px (10m/px) |
| 黒 (0) | elevation_min_m | 最低標高 |
| 白 (255) | elevation_max_m | 最高標高 |
| 解像度 | 10m/pixel 推奨 | terrain_grid_cell_m と同一 |

**標高変換式**:

```
elevation_m = elevation_min_m + (pixel_value / 255.0) * (elevation_max_m - elevation_min_m)
```

### 2.2 GeoJSON拡張

`map.geojson` の properties に標高メタ情報を追加:

```json
{
  "properties": {
    "schema": "map_v0.2",
    "size_m": [2000, 2000],
    "elevation": {
      "file": "elevation.png",
      "min_m": 0.0,
      "max_m": 100.0,
      "contour_interval_m": 10.0
    }
  }
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| file | String | ハイトマップファイル名 |
| min_m | float | 最低標高（メートル） |
| max_m | float | 最高標高（メートル） |
| contour_interval_m | float | 等高線間隔（メートル） |

### 2.3 MapData拡張

`scripts/data/map_data.gd` に追加:

```gdscript
## 標高データ
var has_elevation: bool = false
var elevation_min_m: float = 0.0
var elevation_max_m: float = 100.0
var elevation_grid_cell_m: float = 10.0
var elevation_grid_size: Vector2i = Vector2i.ZERO
var _elevation_grid: Array[Array] = []  # [y][x] = elevation_m

## 等高線設定
var contour_interval_m: float = 10.0
```

---

## 3. 標高グリッド

### 3.1 構築処理

```gdscript
## MapLoader に追加
func _load_elevation(map_dir: String, elevation_config: Dictionary) -> void:
    var file_path := map_dir + "/" + elevation_config.get("file", "elevation.png")
    if not FileAccess.file_exists(file_path):
        return

    var image := Image.load_from_file(file_path)
    if not image:
        push_error("Failed to load elevation map: %s" % file_path)
        return

    map_data.elevation_min_m = elevation_config.get("min_m", 0.0)
    map_data.elevation_max_m = elevation_config.get("max_m", 100.0)
    map_data.contour_interval_m = elevation_config.get("contour_interval_m", 10.0)

    _build_elevation_grid(image)
    map_data.has_elevation = true


func _build_elevation_grid(image: Image) -> void:
    var width := image.get_width()
    var height := image.get_height()

    map_data.elevation_grid_size = Vector2i(width, height)
    map_data.elevation_grid_cell_m = map_data.world_size.x / float(width)
    map_data._elevation_grid.clear()

    var elevation_range := map_data.elevation_max_m - map_data.elevation_min_m

    for y in range(height):
        var row: Array[float] = []
        for x in range(width):
            var pixel := image.get_pixel(x, y)
            var normalized := pixel.r  # グレースケールなのでR成分を使用
            var elevation := map_data.elevation_min_m + normalized * elevation_range
            row.append(elevation)
        map_data._elevation_grid.append(row)
```

### 3.2 標高取得

```gdscript
## MapData に追加
func get_elevation_at(world_pos: Vector2) -> float:
    if not has_elevation:
        return 0.0

    var grid_x := int(world_pos.x / elevation_grid_cell_m)
    var grid_y := int(world_pos.y / elevation_grid_cell_m)

    # 範囲チェック
    if grid_x < 0 or grid_x >= elevation_grid_size.x:
        return elevation_min_m
    if grid_y < 0 or grid_y >= elevation_grid_size.y:
        return elevation_min_m

    return _elevation_grid[grid_y][grid_x]


## バイリニア補間版（より滑らか）
func get_elevation_at_interpolated(world_pos: Vector2) -> float:
    if not has_elevation:
        return 0.0

    var fx := world_pos.x / elevation_grid_cell_m
    var fy := world_pos.y / elevation_grid_cell_m

    var x0 := int(floor(fx))
    var y0 := int(floor(fy))
    var x1 := x0 + 1
    var y1 := y0 + 1

    # 範囲クランプ
    x0 = clampi(x0, 0, elevation_grid_size.x - 1)
    x1 = clampi(x1, 0, elevation_grid_size.x - 1)
    y0 = clampi(y0, 0, elevation_grid_size.y - 1)
    y1 = clampi(y1, 0, elevation_grid_size.y - 1)

    var tx := fx - floor(fx)
    var ty := fy - floor(fy)

    var e00 := _elevation_grid[y0][x0]
    var e10 := _elevation_grid[y0][x1]
    var e01 := _elevation_grid[y1][x0]
    var e11 := _elevation_grid[y1][x1]

    var e0 := lerp(e00, e10, tx)
    var e1 := lerp(e01, e11, tx)

    return lerp(e0, e1, ty)
```

---

## 4. 純粋関数クラス: ElevationCalc

**ファイル**: `scripts/calc/elevation_calc.gd`

```gdscript
class_name ElevationCalc
extends RefCounted

## 標高計算の純粋関数群

## 2点間の勾配を計算（度）
static func get_slope_deg(
    pos_a: Vector2,
    elevation_a: float,
    pos_b: Vector2,
    elevation_b: float
) -> float:
    var horizontal_dist := pos_a.distance_to(pos_b)
    if horizontal_dist < 0.01:
        return 0.0

    var vertical_diff := elevation_b - elevation_a
    return rad_to_deg(atan2(vertical_diff, horizontal_dist))


## 2点間の勾配を計算（パーセント）
static func get_slope_percent(
    pos_a: Vector2,
    elevation_a: float,
    pos_b: Vector2,
    elevation_b: float
) -> float:
    var horizontal_dist := pos_a.distance_to(pos_b)
    if horizontal_dist < 0.01:
        return 0.0

    var vertical_diff := elevation_b - elevation_a
    return (vertical_diff / horizontal_dist) * 100.0


## 視界における標高優位性を計算
## 返り値: 正=観測者が高い、負=目標が高い
static func get_elevation_advantage(
    observer_elevation: float,
    target_elevation: float
) -> float:
    return observer_elevation - target_elevation


## 視認距離への標高修正係数を計算
## 高所から低所を見る場合は視認しやすい（係数 > 1.0）
## 低所から高所を見る場合は視認しにくい（係数 < 1.0）
static func get_vision_elevation_modifier(
    observer_elevation: float,
    target_elevation: float,
    horizontal_distance: float
) -> float:
    var elevation_diff := observer_elevation - target_elevation

    # 標高差がない場合は修正なし
    if absf(elevation_diff) < 1.0:
        return 1.0

    # 俯角（観測者が高い場合は正）
    var angle_deg := rad_to_deg(atan2(elevation_diff, horizontal_distance))

    # 高所優位: +10度で+10%視認距離、-10度で-10%
    # 係数範囲: 0.7 ~ 1.3
    var modifier := 1.0 + (angle_deg / 100.0)
    return clampf(modifier, 0.7, 1.3)


## 勾配による移動速度係数を計算
## 上り坂は遅く、下り坂は速い
static func get_slope_speed_modifier(slope_deg: float) -> float:
    # 平坦（±5度）
    if absf(slope_deg) < 5.0:
        return 1.0

    # 上り坂（正の勾配）
    if slope_deg > 0:
        # 10度で0.8、20度で0.6、30度で0.4
        return maxf(0.3, 1.0 - slope_deg * 0.02)

    # 下り坂（負の勾配）
    # -10度で1.1、-20度で1.0（急すぎると減速）
    var abs_slope := absf(slope_deg)
    if abs_slope < 15.0:
        return minf(1.15, 1.0 + abs_slope * 0.01)
    else:
        return maxf(0.7, 1.15 - (abs_slope - 15.0) * 0.03)


## 勾配が通行可能か判定
static func is_slope_passable(
    slope_deg: float,
    mobility: GameEnums.MobilityType
) -> bool:
    match mobility:
        GameEnums.MobilityType.FOOT:
            return absf(slope_deg) < 45.0  # 歩兵: 45度まで
        GameEnums.MobilityType.WHEELED:
            return absf(slope_deg) < 20.0  # 装輪: 20度まで
        GameEnums.MobilityType.TRACKED:
            return absf(slope_deg) < 30.0  # 装軌: 30度まで
        _:
            return absf(slope_deg) < 30.0
```

---

## 5. 等高線抽出: ContourExtractor

**ファイル**: `scripts/calc/contour_extractor.gd`

Marching Squares アルゴリズムで等高線を抽出:

```gdscript
class_name ContourExtractor
extends RefCounted

## 等高線データ
class ContourLine:
    var elevation_m: float = 0.0
    var points: PackedVector2Array = PackedVector2Array()
    var is_closed: bool = false

## 指定間隔で全等高線を抽出
static func extract_contours(
    elevation_grid: Array[Array],
    grid_cell_m: float,
    elevation_min: float,
    elevation_max: float,
    interval_m: float
) -> Array[ContourLine]:
    var contours: Array[ContourLine] = []

    # 等高線の標高リストを生成
    var elevation := ceili(elevation_min / interval_m) * interval_m
    while elevation < elevation_max:
        var lines := _extract_contour_at_elevation(
            elevation_grid, grid_cell_m, elevation
        )
        contours.append_array(lines)
        elevation += interval_m

    return contours


## 特定標高の等高線を抽出（Marching Squares）
static func _extract_contour_at_elevation(
    grid: Array[Array],
    cell_m: float,
    target_elevation: float
) -> Array[ContourLine]:
    var height := grid.size()
    if height == 0:
        return []
    var width: int = grid[0].size()

    var segments: Array[PackedVector2Array] = []

    # 各セルを走査
    for y in range(height - 1):
        for x in range(width - 1):
            var e00 := grid[y][x]
            var e10 := grid[y][x + 1]
            var e01 := grid[y + 1][x]
            var e11 := grid[y + 1][x + 1]

            # Marching Squares のケース番号を計算
            var case_index := 0
            if e00 >= target_elevation: case_index |= 1
            if e10 >= target_elevation: case_index |= 2
            if e11 >= target_elevation: case_index |= 4
            if e01 >= target_elevation: case_index |= 8

            # エッジを跨ぐ場合のみ処理
            if case_index == 0 or case_index == 15:
                continue

            var cell_origin := Vector2(x * cell_m, y * cell_m)
            var segment := _get_segment_for_case(
                case_index, cell_origin, cell_m,
                e00, e10, e01, e11, target_elevation
            )
            if segment.size() == 2:
                segments.append(segment)

    # セグメントを連結して等高線に
    return _connect_segments(segments, target_elevation)


## Marching Squares のケースに応じた線分を取得
static func _get_segment_for_case(
    case_index: int,
    origin: Vector2,
    cell_m: float,
    e00: float, e10: float, e01: float, e11: float,
    target: float
) -> PackedVector2Array:
    # 各辺の補間位置を計算
    var left := origin + Vector2(0, _interpolate(e00, e01, target) * cell_m)
    var right := origin + Vector2(cell_m, _interpolate(e10, e11, target) * cell_m)
    var top := origin + Vector2(_interpolate(e00, e10, target) * cell_m, 0)
    var bottom := origin + Vector2(_interpolate(e01, e11, target) * cell_m, cell_m)

    # ケースに応じた線分を返す
    match case_index:
        1, 14: return PackedVector2Array([left, top])
        2, 13: return PackedVector2Array([top, right])
        3, 12: return PackedVector2Array([left, right])
        4, 11: return PackedVector2Array([right, bottom])
        5:     return PackedVector2Array([left, top])  # サドルポイント（簡略化）
        6, 9:  return PackedVector2Array([top, bottom])
        7, 8:  return PackedVector2Array([left, bottom])
        10:    return PackedVector2Array([top, right])  # サドルポイント（簡略化）
        _:     return PackedVector2Array()


static func _interpolate(e0: float, e1: float, target: float) -> float:
    if absf(e1 - e0) < 0.001:
        return 0.5
    return (target - e0) / (e1 - e0)


## セグメントを連結して等高線ポリラインに
static func _connect_segments(
    segments: Array[PackedVector2Array],
    elevation: float
) -> Array[ContourLine]:
    var contours: Array[ContourLine] = []

    # 簡略化: 各セグメントを個別の等高線として扱う
    # TODO: 実際の連結処理を実装
    for segment in segments:
        var contour := ContourLine.new()
        contour.elevation_m = elevation
        contour.points = segment
        contour.is_closed = false
        contours.append(contour)

    return contours
```

---

## 6. 等高線描画: ContourRenderer

**ファイル**: `scripts/ui/contour_renderer.gd`

```gdscript
class_name ContourRenderer
extends Node2D

## 等高線の描画を担当

## 描画設定
@export var contour_color: Color = Color(0.6, 0.4, 0.2, 0.5)
@export var major_contour_color: Color = Color(0.5, 0.3, 0.1, 0.7)
@export var contour_width: float = 1.0
@export var major_contour_width: float = 2.0
@export var major_interval: int = 5  # 主曲線は5本ごと

## 等高線データ
var _contours: Array = []
var _contour_interval: float = 10.0

## MapDataから等高線を構築
func build_from_map_data(map_data) -> void:
    if not map_data.has_elevation:
        return

    _contour_interval = map_data.contour_interval_m

    _contours = ContourExtractor.extract_contours(
        map_data._elevation_grid,
        map_data.elevation_grid_cell_m,
        map_data.elevation_min_m,
        map_data.elevation_max_m,
        _contour_interval
    )

    queue_redraw()


func _draw() -> void:
    var contour_index := 0

    for contour in _contours:
        if contour.points.size() < 2:
            continue

        # 主曲線かどうか判定
        var elevation_index := int(contour.elevation_m / _contour_interval)
        var is_major := (elevation_index % major_interval) == 0

        var color := major_contour_color if is_major else contour_color
        var width := major_contour_width if is_major else contour_width

        # ポリラインを描画
        if contour.points.size() == 2:
            draw_line(contour.points[0], contour.points[1], color, width)
        else:
            draw_polyline(contour.points, color, width)

        contour_index += 1
```

---

## 7. VisionCalcへの統合

**ファイル**: `scripts/calc/vision_calc.gd` に追加

```gdscript
## 標高を考慮した視認距離修正
static func get_vision_distance_with_elevation(
    base_distance: float,
    observer_pos: Vector2,
    observer_elevation: float,
    target_pos: Vector2,
    target_elevation: float
) -> float:
    var horizontal_dist := observer_pos.distance_to(target_pos)
    var elevation_modifier := ElevationCalc.get_vision_elevation_modifier(
        observer_elevation,
        target_elevation,
        horizontal_dist
    )
    return base_distance * elevation_modifier


## LoS判定に標高を考慮（将来実装）
## 中間地点の標高が視線を遮るかチェック
static func check_los_with_elevation(
    observer_pos: Vector2,
    observer_elevation: float,
    target_pos: Vector2,
    target_elevation: float,
    map_data,
    sample_count: int = 10
) -> bool:
    # 視線の直線を計算
    var observer_height := observer_elevation + 2.0  # 観測者の目の高さ
    var target_height := target_elevation + 1.5      # 目標の高さ

    for i in range(1, sample_count):
        var t := float(i) / float(sample_count)
        var check_pos := observer_pos.lerp(target_pos, t)
        var check_elevation := map_data.get_elevation_at_interpolated(check_pos)

        # 視線上の高さを補間
        var line_height := lerp(observer_height, target_height, t)

        # 地形が視線を遮る場合
        if check_elevation > line_height:
            return false

    return true
```

---

## 8. 実装フェーズ

### Phase 1: データ層

1. `map_data.gd` に標高グリッド追加
2. `map_loader.gd` にハイトマップ読み込み追加
3. テストマップ用 `elevation.png` 作成
4. 単体テスト作成

### Phase 2: 計算層

1. `elevation_calc.gd` 作成
2. `contour_extractor.gd` 作成
3. 単体テスト作成

### Phase 3: 描画層

1. `contour_renderer.gd` 作成
2. Main.tscn にノード追加
3. 視覚確認

### Phase 4: ゲームプレイ統合

1. `vision_calc.gd` に標高修正を統合
2. 統合テスト
3. バランス調整

---

## 9. テストマップ作成

### 9.1 サンプルハイトマップ

200x200px のグレースケールPNGを作成:

```
中央に丘（標高50m）
  ↓
[黒い外周] → [灰色の斜面] → [白い頂上]
   0m             25m            50m
```

### 9.2 GIMP/Photoshopでの作成手順

1. 新規画像 200x200px、グレースケール
2. 黒で塗りつぶし（基準標高 0m）
3. 中央に白い円を描画（丘の頂上 50m）
4. ガウスぼかしを適用（滑らかな斜面）
5. PNG保存

---

## 10. パラメータ早見表

### 10.1 視界修正係数

| 俯角（度） | 修正係数 | 説明 |
|-----------|---------|------|
| +30 | 1.30 | 高所から見下ろす（最大ボーナス） |
| +10 | 1.10 | 軽い俯角 |
| 0 | 1.00 | 水平 |
| -10 | 0.90 | 軽い仰角 |
| -30 | 0.70 | 低所から見上げる（最大ペナルティ） |

### 10.2 勾配による移動速度

| 勾配（度） | 速度係数 | 説明 |
|-----------|---------|------|
| 0 | 1.00 | 平坦 |
| +10（上り） | 0.80 | 緩い上り坂 |
| +20（上り） | 0.60 | 急な上り坂 |
| +30（上り） | 0.40 | 非常に急な上り |
| -10（下り） | 1.10 | 緩い下り坂 |
| -20（下り） | 1.00 | 急な下り（減速開始） |

### 10.3 通行可能勾配

| 機動種別 | 最大勾配（度） |
|---------|---------------|
| FOOT | 45 |
| WHEELED | 20 |
| TRACKED | 30 |

---

## 11. 対象ファイル

### 新規作成

| ファイル | 説明 |
|---------|------|
| `scripts/calc/elevation_calc.gd` | 標高計算純粋関数 |
| `scripts/calc/contour_extractor.gd` | 等高線抽出 |
| `scripts/ui/contour_renderer.gd` | 等高線描画 |
| `tests/test_elevation_calc.gd` | テスト |
| `tests/test_contour_extractor.gd` | テスト |

### 修正

| ファイル | 変更内容 |
|---------|---------|
| `scripts/data/map_data.gd` | 標高グリッド追加 |
| `scripts/systems/map_loader.gd` | ハイトマップ読み込み |
| `scripts/calc/vision_calc.gd` | 標高修正統合 |

---

## 12. 関連ドキュメント

- [map_v0.1.md](map_v0.1.md) - マップ仕様
- [terrain_v0.1.md](terrain_v0.1.md) - 地形詳細
- [terrain_table_design_v0.1.md](terrain_table_design_v0.1.md) - 地形係数テーブル設計
- [vision_v0.1.md](vision_v0.1.md) - 視界システム
