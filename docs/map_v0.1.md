# マップ仕様 v0.1

---

## 1. 概要と前提

### 1.1 基本方針

- **2D**（GodotのNavigationPolygon / NavigationRegion2D）
- **マップ実寸**：2km × 2km
- **背景はPNG1枚**（地図風）
- **真上俯瞰**（地形を立体で作り込まない）
- **等高線**（地形図っぽさ）

> 「見た目は地図」「ロジックはナビ＋レイヤー」で成立させる。

### 1.2 座標系とスケール

| 項目 | 値 |
|------|-----|
| ワールド単位 | 1.0 unit = 1.0 m |
| X範囲 | 0 … 2000 |
| Y範囲 | 0 … 2000 |
| 原点 | マップ左上を (0, 0) |
| X方向 | 右が＋ |
| Y方向 | 下が＋（Godot 2Dに合わせる） |

### 1.3 背景PNGの解像度

| 項目 | 値 |
|------|-----|
| 推奨解像度 | **2048 × 2048**（または4096 × 4096） |
| 表示サイズ | ワールド上で 2000m × 2000m |
| meters_per_pixel | `2000 / image_width_px` |

> PNGは"見た目"なので解像度は変更可能。ロジックは常にメートル基準。

---

## 2. レイヤー構造（見た目とロジックを分離）

### 2.1 見た目レイヤー（Rendering）

**background.png**：地図風の1枚絵

含める要素：
- 土地被覆（草地/森林/市街/湿地/水域）
- 道路（TRAIL/ROAD/HIGHWAYの見た目）
- 河川・湖沼
- 等高線（見た目）
- 任意：座標グリッド（100m格子など）、地名ラベル、凡例

> 見た目はゲームロジックに影響しない。

### 2.2 ロジックレイヤー（Gameplay）

ベクタ（ポリゴン/ライン）として持つ。

| レイヤー | 内容 |
|---------|------|
| **TerrainZones** | 地形タイプごとのポリゴン |
| **Routes** | 道路回廊（道路優先移動用） |
| **HardBlocks** | 建物ブロック、崖など侵入不可・LoSブロック |
| **WaterCrossings** | 浅瀬（徒渉/渡渉）など |

---

## 3. 地形タイプ（5種＋障害物）

「TileMapを全面採用」ではなく、**地形タイプIDを持つ"地形データ"**として定義。
（見た目はPNG、移動はNavPolygon、戦闘修正は地形タイプ参照）

### 3.1 地形タイプ一覧

| terrain_id | name | 用途 |
|------------|------|------|
| 0 | OPEN | 基本（畑/草地） |
| 1 | ROAD | 道路（ROUTE優先、ALLでも好む） |
| 2 | FOREST | 森林（LoS/発見/遮蔽に影響） |
| 3 | URBAN | 市街（遮蔽大、HardBlockは別で定義） |
| 4 | WATER | 水域（v0.1は全機動で通行不可） |

### 3.2 障害物（HardBlock）

| 種別 | 説明 |
|------|------|
| HARD_BLOCK_BUILDING | 建物フットプリント（LoS Hard Block、Nav障害） |
| HARD_BLOCK_CLIFF | 崖・岩壁（必要なら） |

> URBANは"市街地ゾーン（遮蔽/発見/LoS係数）"、建物はHardBlockポリゴンで分ける。

### 3.3 通行規約

#### URBAN（道路以外の市街ブロック）

| モビリティ | 通行 |
|-----------|------|
| FOOT | 可 |
| WHEELED | **不可** |
| TRACKED | **不可** |

> 車両は URBAN内の道路回廊（ROUTE）のみ通行可能。

#### FOREST（オフロード）

| モビリティ | 通行 |
|-----------|------|
| FOOT | 可 |
| TRACKED | 可 |
| WHEELED | **不可** |

> 森林内に道路回廊があれば `WHEELED_ROUTE` で通行可。

#### WATER

| 地形 | FOOT | WHEELED | TRACKED |
|------|------|---------|---------|
| `WATER_DEEP` | 不可 | 不可 | 不可 |
| `WATER_SHALLOW`（渡渉点） | 可 | **不可** | 可 |

---

## 4. ナビゲーション仕様

### 4.1 ナビレイヤー設計（6レイヤー）

「普段の移動」と「道路優先移動（Follow Route）」を両立させるため、モビリティ別に **ALL** と **ROUTE** を分けた **6レイヤー** を固定。

| レイヤー | 用途 |
|---------|------|
| `FOOT_ALL` | 歩兵の全通行可能領域 |
| `FOOT_ROUTE` | 歩兵の道路回廊 |
| `WHEELED_ALL` | 装輪の全通行可能領域 |
| `WHEELED_ROUTE` | 装輪の道路回廊 |
| `TRACKED_ALL` | 装軌の全通行可能領域 |
| `TRACKED_ROUTE` | 装軌の道路回廊 |

**原則：**
- **通常移動**：`*_ALL` でパスを取る
- **道路優先**：`*_ROUTE` でパス取得を試み、失敗したら `*_ALL` にフォールバック

### 4.2 travel_cost（v0.1既定）

| リージョン | travel_cost |
|-----------|-------------|
| Terrain | 1.0 |
| Road | 0.65 |

---

## 5. データ形式

### 5.1 公式フォーマット

**GeoJSON（FeatureCollection）を正式採用（確定）**

#### 採用理由

- 背景が地図で、地形が"面"や"線"として自然
- QGIS等で編集しやすい
- 将来、実地図データからの流用が楽

### 5.2 実行時の高速化（TerrainGrid）

10Hzシムで大量に「地形参照」をすると重いので、ロード時に GeoJSON → TerrainGrid（タイル状の参照表）へラスタライズする。

| パラメータ | 値 |
|-----------|-----|
| `terrain_grid_cell_m` | 10m |
| グリッドサイズ | 200 × 200（2km / 10m） |
| セル値 | terrain_id（0〜4） |

#### 保存方法

| 方式 | 説明 |
|------|------|
| `terrain_mask.png` | 200×200、8-bit、画素値=terrain_id |
| `terrain_grid.bin/json` | 単純配列 |

---

## 6. MapBundle（ファイル構成）

```
res://maps/<map_id>/
  background.png
  map.geojson
  terrain_mask.png           (任意：無ければ起動時生成)
  nav/
    foot_terrain.tres
    foot_road.tres
    wheeled_terrain.tres
    wheeled_road.tres
    tracked_terrain.tres
    tracked_road.tres
  notes.md                   (任意：作成メモ)
```

| ファイル | 説明 |
|----------|------|
| `nav/*.tres` | NavigationRegion2D用のNavigationPolygon（3map×2layerに対応） |
| `map.geojson` | 論理マップ（CP、スポーン、地形ゾーン、建物ポリゴン、道路線など） |

---

## 7. GeoJSON フォーマット

### 7.1 トップレベル（FeatureCollection + meta）

```json
{
  "type": "FeatureCollection",
  "name": "<map_id>",
  "properties": {
    "schema": "map_v0.1",
    "size_m": [2000, 2000],
    "coord": { "origin": "top_left", "units": "m", "axis": "x_east_y_south" },
    "background": { "file": "background.png", "size_px": [2048, 2048], "meters_per_pixel": 0.9765625 },
    "cp_radius_m": 40,
    "initial_cp_control": { "A": "BLUE", "B": "NEUTRAL", ... },
    "terrain_defs": [...],
    "terrain_grid": { "cell_m": 10, "mask_file": "terrain_mask.png" },
    "nav_resources": {...}
  },
  "features": []
}
```

### 7.2 Feature kinds

| kind | geometry | 用途 |
|------|----------|------|
| `cp` | Point | 拠点 |
| `arrival_point` | Point | Forward Entry用 |
| `deployment_region` | Polygon | 初期配備エリア |
| `entry_point` | Point | 初期スポーン点 |
| `terrain_zone` | Polygon | 地形ゾーン |
| `hardblock` | Polygon | 建物・障害物 |
| `road_centerline` | LineString | 道路中心線 |

---

## 8. ゲームプレイ配置

### 8.1 拠点（Capture Points）

| 項目 | 値 |
|------|-----|
| 拠点数 | 5（A〜E） |
| 拠点属性 | COM / LOG / OBS（最低1つずつ配置） |
| 拠点ゾーン | 円（推奨：半径40m） |

### 8.2 増援到着スポーン（Arrival Points）

| 項目 | 値 |
|------|-----|
| 各拠点のスポーン点 | 2〜4個 |
| 配置位置 | 原則 **道路回廊上（ROUTE）** |

---

## 9. テストマップ MVP_01_CROSSROADS

### 9.1 基本情報

| 項目 | 値 |
|------|-----|
| `map_id` | MVP_01_CROSSROADS |
| サイズ | 2000m × 2000m |
| 背景 | background.png（2048×2048 px） |
| meters_per_pixel | 0.9765625 |

### 9.2 CP配置（十字配置）

| CP | 種別 | center(x, y) | 初期 | 備考 |
|----|------|--------------|------|------|
| A | COM | (350, 1000) | Blue | 西側ホーム |
| B | LOG | (1000, 450) | Neutral | 北側 |
| C | OBS | (1000, 1000) | Neutral | 中央 |
| D | LOG | (1000, 1550) | Neutral | 南側 |
| E | COM | (1650, 1000) | Red | 東側ホーム |

> 開始時の保持数差は0、チケット出血は発生せず、中央取り合いが自然に始まる。

### 9.3 Arrival Points

#### CP A（3点）
| ID | 座標 |
|----|------|
| A1 | (280, 1000) |
| A2 | (350, 930) |
| A3 | (350, 1070) |

#### CP B（3点）
| ID | 座標 |
|----|------|
| B1 | (930, 450) |
| B2 | (1070, 450) |
| B3 | (1000, 520) |

#### CP C（4点）
| ID | 座標 |
|----|------|
| C1 | (930, 1000) |
| C2 | (1070, 1000) |
| C3 | (1000, 930) |
| C4 | (1000, 1070) |

#### CP D（3点）
| ID | 座標 |
|----|------|
| D1 | (930, 1550) |
| D2 | (1070, 1550) |
| D3 | (1000, 1480) |

#### CP E（3点）
| ID | 座標 |
|----|------|
| E1 | (1720, 1000) |
| E2 | (1650, 930) |
| E3 | (1650, 1070) |

### 9.4 DeploymentRegion

| 陣営 | 範囲 |
|------|------|
| Blue | 西端帯（x=0〜220） |
| Red | 東端帯（x=1780〜2000） |

### 9.5 EntryPoints（初期スポーン）

| 陣営 | ID | 座標 |
|------|----|------|
| Blue | BLUE_N | (120, 450) |
| Blue | BLUE_C | (120, 1000) |
| Blue | BLUE_S | (120, 1550) |
| Red | RED_N | (1880, 450) |
| Red | RED_C | (1880, 1000) |
| Red | RED_S | (1880, 1550) |

### 9.6 地形配置（最低限）

| 地形 | 配置 |
|------|------|
| ROAD | 東西（y=1000）と南北（x=1000）の十字 |
| URBANゾーン | CP C周辺（x=850–1150、y=850–1150） |
| BUILDING hardblock | URBAN内に数個 |
| FORESTゾーン | CP B周辺とCP D周辺に1つずつ |
| WATER | v0.2でOK |

---

## 10. 制作ガイドライン

| ルール | 理由 |
|--------|------|
| **URBAN**ブロックは車両進入不可（道路回廊だけ通す） | 市街戦の歩兵優位 |
| **森林・湿地**には「道（回廊）」を通す箇所を作る | 待ち伏せ/迂回の読み合い |
| **川（深水）**は必ず橋 or 渡渉点を複数用意 | 橋の価値を保つ |
| **拠点**は「地形差」が出る位置へ（市街/橋/高地） | ゲームプレイの多様性 |
| **スポーン点**は必ず「道路上」に置く | 到着計画の納得感 |

---

## 11. 早見表

### 11.1 地形タイプ

| ID | 名前 | FOOT | WHEELED | TRACKED |
|----|------|------|---------|---------|
| 0 | OPEN | ○ | ○ | ○ |
| 1 | ROAD | ○ | ○ | ○ |
| 2 | FOREST | ○ | × | ○ |
| 3 | URBAN | ○ | ×（ROUTE可） | ×（ROUTE可） |
| 4 | WATER | × | × | × |

### 11.2 ナビレイヤー

| Map | Layer | 用途 |
|-----|-------|------|
| FOOT | ALL | 歩兵全域 |
| FOOT | ROUTE | 歩兵道路 |
| WHEELED | ALL | 装輪全域 |
| WHEELED | ROUTE | 装輪道路 |
| TRACKED | ALL | 装軌全域 |
| TRACKED | ROUTE | 装軌道路 |

### 11.3 GeoJSON Feature kinds

| kind | geometry | 用途 |
|------|----------|------|
| cp | Point | 拠点 |
| arrival_point | Point | Forward Entry |
| deployment_region | Polygon | 配備エリア |
| entry_point | Point | スポーン点 |
| terrain_zone | Polygon | 地形ゾーン |
| hardblock | Polygon | 障害物 |
| road_centerline | LineString | 道路中心線 |

### 11.4 パラメータ

| パラメータ | v0.1既定値 |
|-----------|-----------|
| CP radius_m | 40 |
| terrain_grid_cell_m | 10 |
| Terrain travel_cost | 1.0 |
| Road travel_cost | 0.65 |
