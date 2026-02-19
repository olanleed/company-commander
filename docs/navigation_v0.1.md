# ナビゲーション実装 v0.1

---

## 1. Godot NavigationServer2Dの使用

### 1.1 採用（確定）

- 経路探索は **NavigationServer2D** を使う
- NavigationServer2D は「maps/regions/agents」を扱い、`map_get_path()` 等でパスを取得
- パス取得API：
  ```gdscript
  NavigationServer2D.map_get_path(map, from, to, optimize, navigation_layers)
  ```
- ナビレイヤはビットマスクで、クエリ側で「使うリージョン」をフィルタ可能

### 1.2 重要な注意（実装上の罠）

NavigationServer2Dの更新は **「次のphysics frame後に反映」** が基本（即時ではない）。
動的変更を入れるなら「反映タイミング」を仕様化しておく必要がある。

---

## 2. 6レイヤーの具体セットアップ（3マップ × 2レイヤ）

6分類は「通行可能領域の形が違う」ので、**機動種別ごとにNavigationMapを分ける**。

### 2.1 NavigationMap（3つ：機動種別）

| Map | 説明 |
|-----|------|
| `NAV_MAP_FOOT` | 歩兵用 |
| `NAV_MAP_WHEELED` | 装輪車両用 |
| `NAV_MAP_TRACKED` | 装軌車両用 |

- 作成：`NavigationServer2D.map_create()`
- 有効化：`map_set_active()`
- NavigationRegion2Dは `set_navigation_map(RID)` で所属マップを切り替え可能

### 2.2 NavigationLayer（2つ：ALL/ROUTE）

各マップ共通でレイヤ2本だけを使用。

| Layer | 説明 |
|-------|------|
| **Layer 1** | ALL（通常移動） |
| **Layer 2** | ROUTE（道路縛り/道路優先） |

NavigationLayerは「リージョン側が所属レイヤを持ち、クエリ側が使用レイヤを指定する」方式。

### 2.3 6パターンの対応表

| 目的 | NavigationMap | navigation_layers（クエリ） |
|------|--------------|---------------------------|
| FOOT × ALL | NAV_MAP_FOOT | Layer1 |
| FOOT × ROUTE | NAV_MAP_FOOT | Layer2 |
| WHEELED × ALL | NAV_MAP_WHEELED | Layer1 |
| WHEELED × ROUTE | NAV_MAP_WHEELED | Layer2 |
| TRACKED × ALL | NAV_MAP_TRACKED | Layer1 |
| TRACKED × ROUTE | NAV_MAP_TRACKED | Layer2 |

---

## 3. リージョン構成

### 3.1 各NavigationMapは "2リージョン"で構成（推奨・確定）

各機動種別について、最低限この2つを用意：

#### TerrainRegion（オフロード含む基本通行領域）

| 属性 | 値 |
|------|-----|
| `navigation_layers` | Layer1(ALL)のみ |
| `travel_cost` | 1.0（標準） |

#### RoadRegion（道路領域）

| 属性 | 値 |
|------|-----|
| `navigation_layers` | Layer1(ALL) + Layer2(ROUTE) |
| `travel_cost` | Terrainより低い |

> ALL移動でも道路は通れる / ROUTE移動では道路しか通らない

### 3.2 travel_cost 推奨値（v0.1既定）

| リージョン | travel_cost |
|-----------|-------------|
| Terrain | 1.0 |
| Road | 0.65 |

> 「ALL＝道路も使う（しかも道路優先になりやすい）」
> 「ROUTE＝道路のみ」の両方が成立。

### 3.3 接続の条件（重要）

NavigationRegion2D同士は **"重なっても繋がらない"**。
「似たエッジ」を共有する必要があり、距離閾値は `edge_connection_margin` で調整。

#### v0.1決定

| パラメータ | 値 |
|-----------|-----|
| `edge_connection_margin` | 2.0（1unit=1m前提なら2m） |

> RoadRegionとTerrainRegionの境界が「隣接」になるようにポリゴンを切るのが理想。
> ズレる場合はmarginを上げる。

---

## 4. パス検索の実行仕様

### 4.1 10Hzシムとの整合

- 10Hz tickごとに毎回パス再計算は**しない**（重いしブレる）
- v0.1では**次のときだけ** `map_get_path()` を呼ぶ（確定）

#### PathQueryトリガ

| トリガ | タイミング |
|--------|----------|
| Move系命令Exec | 最初の1回 |
| 定期再計算 | **1Hz（1秒ごと）** にスタック/大迂回/目標更新があれば |
| 動的トポロジ変化 | イベントを受けたら影響ユニットだけ再計算 |

### 4.2 ROUTE指示のフォールバック（確定）

ROUTE移動（道路縛り）でパスが取れなかった場合：

```
1. ROUTEで再試行 → path empty
2. ALLへ自動フォールバック
3. UIログに「ROUTE不可→ALLへ」表示
```

---

## 5. 動的障害物（煙、破壊地形）の扱い

### 5.1 煙（SMOKE）の扱い（確定：ナビには入れない）

| 決定 | 理由 |
|------|------|
| 煙幕はナビゲーションポリゴンを**変更しない** | 煙は"通れない壁"ではない |

煙の効果は既存仕様の範囲に限定：
- LoSブロック
- 発見距離係数
- 遮蔽係数

> 煙でナビを切り替えると再計算が増え、プレイ感が悪化しやすい。

### 5.2 破壊地形（確定：Link/小リージョン切替で対応）

v0.1で扱う破壊は **"地形トポロジが変わるもの"だけ** に限定。

#### (A) 橋・渡河点・道路封鎖：NavigationLink2D / LinkのON/OFF

| 方式 | 説明 |
|------|------|
| NavigationLink2D | 橋や渡河のような「接続」を表現 |
| 破壊 | リンク無効化 → 以後の `map_get_path()` で通れなくなる |

> 「巨大ポリゴンの再ベイク」が不要で、v0.1に非常に向いている。

#### (B) 道路上の瓦礫・崩落で"ROUTEだけ"潰す：小リージョンOFF

| 方式 | 説明 |
|------|------|
| RoadRegion | 道路セグメントごとに小リージョン化しておく |
| 崩落 | セグメントのリージョンを `enabled=false`（または Layer2を外す） |

結果：
- ROUTE移動は迂回（またはALLへフォールバック）
- ALL移動はオフロードで抜ける

#### (C) 建物破壊で"通れるようになる"：事前仕込みPassableRegionをON

| 方式 | 説明 |
|------|------|
| 初期状態 | 建物は「通れない」前提でTerrainRegionを切る |
| 破壊 | 建物フットプリント部分のPassableRegionを有効化 |
| 機動種別差 | FOOT/TRACKEDのみON、WHEELEDはOFF等が可能 |

> v0.1では「通れなくなる」方向の動的穴あけ（ポリゴンを削る）は**やらない**。
> 再ベイクや穴の扱いが重くなるため。

### 5.3 反映タイミング（重要）

NavigationServer2Dの変更は原則 **次のphysics frameで反映**。

#### v0.1決定（推奨運用）

| 状況 | 対応 |
|------|------|
| 通常 | physics frame反映を待つ（1フレーム遅延は許容） |
| 即時反映が必要 | `map_force_update(map_rid)` を使用 |

> `map_force_update()` はコマンドキューをフラッシュし得る等、強力で重いので**乱用しない**。

---

## 6. ノード構成（動く最小セット）

```
GameScene
└── Nav/
    ├── NavMapFootRoot (Node2D)
    │   ├── FootTerrainRegion (NavigationRegion2D)
    │   │   └── map=FOOT, layer=ALL
    │   ├── FootRoadRegion (NavigationRegion2D)
    │   │   └── map=FOOT, layer=ALL|ROUTE, travel_cost=0.65
    │   └── FootLinks (Node2D)
    │       └── 橋リンク等
    │
    ├── NavMapWheeledRoot (Node2D)
    │   ├── WheeledTerrainRegion (NavigationRegion2D)
    │   ├── WheeledRoadRegion (NavigationRegion2D)
    │   └── WheeledLinks (Node2D)
    │
    └── NavMapTrackedRoot (Node2D)
        ├── TrackedTerrainRegion (NavigationRegion2D)
        ├── TrackedRoadRegion (NavigationRegion2D)
        └── TrackedLinks (Node2D)
```

---

## 7. まとめ（確定事項）

| 項目 | 決定内容 |
|------|---------|
| 採用API | NavigationServer2D、`map_get_path()` |
| 6分類の表現 | 3つのNavigationMap × 2つのNavigationLayer |
| Road優先 | `travel_cost` を下げてALLでも自然に道路優先 |
| 煙 | ナビ変更なし |
| 破壊地形 | Link/小RegionのON/OFF |
| 即時反映 | `map_force_update()` は限定的に使用可 |

---

## 8. 早見表

### 8.1 NavigationMap一覧

| Map ID | 用途 |
|--------|------|
| NAV_MAP_FOOT | 歩兵 |
| NAV_MAP_WHEELED | 装輪車両 |
| NAV_MAP_TRACKED | 装軌車両 |

### 8.2 NavigationLayer一覧

| Layer | Bit | 用途 |
|-------|-----|------|
| ALL | 1 | 通常移動 |
| ROUTE | 2 | 道路縛り |

### 8.3 リージョン構成

| リージョン | layers | travel_cost |
|-----------|--------|-------------|
| TerrainRegion | ALL | 1.0 |
| RoadRegion | ALL + ROUTE | 0.65 |

### 8.4 パス検索タイミング

| トリガ | 頻度 |
|--------|------|
| 命令Exec時 | 1回 |
| 定期再計算 | 1Hz |
| トポロジ変化 | イベント駆動 |

### 8.5 動的障害物の扱い

| 種別 | ナビ変更 | 方式 |
|------|---------|------|
| 煙（SMOKE） | なし | LoS/発見/遮蔽のみ |
| 橋崩落 | あり | Link無効化 |
| 道路封鎖 | あり | 小RegionのLayer変更 |
| 建物破壊 | あり | PassableRegion有効化 |

### 8.6 パラメータ

| パラメータ | v0.1既定値 |
|-----------|-----------|
| edge_connection_margin | 2.0 |
| Terrain travel_cost | 1.0 |
| Road travel_cost | 0.65 |
| パス再計算周期 | 1Hz |
