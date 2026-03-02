# テーブル駆動設計: 地形係数システム (v0.1)

## 概要
現在の地形係数は複数のファイルに散在するmatch文で管理されており、新しい地形タイプの追加時に5箇所以上の修正が必要。
本ドキュメントでは現状の仕様を整理し、テーブル駆動設計への移行計画を提案する。

---

## 1. 現状分析

### 1.1 地形タイプ定義
**ファイル**: `scripts/core/game_enums.gd:31-37`

```gdscript
enum TerrainType {
    OPEN = 0,    ## 基本（畑/草地）
    ROAD = 1,    ## 道路
    FOREST = 2,  ## 森林
    URBAN = 3,   ## 市街
    WATER = 4,   ## 水域
}
```

### 1.2 地形係数の分散状況

| ファイル | 関数/処理 | 係数種別 |
|---------|----------|---------|
| `game_constants.gd:368-378` | 定数定義 | 遮蔽係数（直射/間接） |
| `combat_calc.gd:50-78` | `get_cover_coeff_df/if()` | 遮蔽係数 |
| `vision_calc.gd:41-54` | `get_concealment_modifier()` | 隠蔽係数 |
| `element_data.gd:578-595` | `get_speed()` | 移動速度係数 |
| `map_data.gd:190-201` | `is_passable()` | 通行可否 |
| `map_loader.gd:262-275` | `_parse_terrain_type()` | 文字列パース |
| `navigation_manager.gd:149,175` | ナビゲーション構築 | 通行コスト |

---

## 2. 現行仕様: 地形係数一覧

### 2.1 遮蔽係数（直射）
**用途**: 直射攻撃時のダメージ軽減
**定義**: `game_constants.gd` → `combat_calc.gd:get_cover_coeff_df()`

| TerrainType | 係数 | 説明 |
|-------------|------|-----|
| OPEN | 1.0 | 遮蔽なし |
| ROAD | 1.0 | 遮蔽なし |
| FOREST | 0.50 | 樹木で半減 |
| URBAN | 0.35 | 建物で大幅軽減 |
| WATER | 1.0* | (デフォルト=OPEN) |

### 2.2 遮蔽係数（間接）
**用途**: 間接射撃（砲撃）時のダメージ軽減
**定義**: `game_constants.gd` → `combat_calc.gd:get_cover_coeff_if()`

| TerrainType | 係数 | 説明 |
|-------------|------|-----|
| OPEN | 1.0 | 遮蔽なし |
| ROAD | 0.95 | ほぼ遮蔽なし |
| FOREST | 0.50 | 樹木が破片吸収 |
| URBAN | 0.35 | 建物が大幅防護 |
| WATER | 1.0* | (デフォルト=OPEN) |

### 2.3 隠蔽係数
**用途**: 視認距離の修正（低いほど発見されにくい）
**定義**: `vision_calc.gd:get_concealment_modifier()`

| TerrainType | 係数 | 説明 |
|-------------|------|-----|
| OPEN | 1.0 | 隠蔽なし |
| ROAD | 1.0 | 隠蔽なし |
| FOREST | 0.6 | 樹木で隠蔽 |
| URBAN | 0.7 | 建物で隠蔽 |
| WATER | 1.0 | 隠蔽なし |

### 2.4 移動速度係数
**用途**: 地形による速度修正
**定義**: `element_data.gd:get_speed()`

| TerrainType | FOOT | WHEELED | TRACKED |
|-------------|------|---------|---------|
| OPEN | 1.0 (cross_speed) | 1.0 | 1.0 |
| ROAD | road_speed | road_speed | road_speed |
| FOREST | 0.6 | 0.4 | 0.4 |
| URBAN | 0.5 | 0.5 | 0.5 |
| WATER | 1.0* | 1.0* | 1.0* |

### 2.5 通行可否
**用途**: ナビゲーション・経路計算
**定義**: `map_data.gd:is_passable()`

| TerrainType | FOOT | WHEELED | TRACKED |
|-------------|------|---------|---------|
| OPEN | ✓ | ✓ | ✓ |
| ROAD | ✓ | ✓ | ✓ |
| FOREST | ✓ | ✗ | ✓ |
| URBAN | ✓ | ✗ | ✗ |
| WATER | ✗ | ✗ | ✗ |

### 2.6 ナビゲーションコスト
**用途**: 経路探索の重み付け
**定義**: `game_constants.gd`, `navigation_manager.gd`

| TerrainType | travel_cost |
|-------------|-------------|
| ROAD | 0.65 |
| その他 | 1.0 |

---

## 3. 問題点

### 3.1 新地形追加時の修正箇所（例: SWAMP追加）

1. `game_enums.gd` - enum定義追加
2. `game_constants.gd` - 遮蔽定数追加
3. `combat_calc.gd` - `get_cover_coeff_df()`, `get_cover_coeff_if()` のmatch追加
4. `vision_calc.gd` - `get_concealment_modifier()` のmatch追加
5. `element_data.gd` - `get_speed()` のmatch追加
6. `map_data.gd` - `is_passable()` のmatch追加
7. `map_loader.gd` - `_parse_terrain_type()` のmatch追加
8. `navigation_manager.gd` - 通行判定追加

**合計: 8ファイル、10箇所以上のmatch文修正**

### 3.2 リスク
- 修正漏れによる不整合
- デフォルト値による意図しない挙動
- テスト網羅性の低下

---

## 4. テーブル駆動設計

### 4.1 新規クラス: TerrainData

**ファイル**: `scripts/data/terrain_data.gd`

```gdscript
class_name TerrainData
extends RefCounted

## 地形タイプごとの全係数を一元管理

class TerrainProperties extends RefCounted:
    var id: GameEnums.TerrainType
    var name: String
    var name_jp: String

    ## 遮蔽係数
    var cover_df: float = 1.0       # 直射遮蔽
    var cover_if: float = 1.0       # 間接遮蔽

    ## 隠蔽係数
    var concealment: float = 1.0    # 視認距離修正

    ## 移動係数 (mobility_class別)
    var speed_mult_foot: float = 1.0
    var speed_mult_wheeled: float = 1.0
    var speed_mult_tracked: float = 1.0

    ## 通行可否 (mobility_class別)
    var passable_foot: bool = true
    var passable_wheeled: bool = true
    var passable_tracked: bool = true

    ## ナビゲーション
    var travel_cost: float = 1.0

    ## 特殊フラグ
    var blocks_los: bool = false    # LoSブロック（将来用）
    var provides_cover: bool = false # 遮蔽提供

## 全地形のプロパティテーブル
static var _terrain_table: Dictionary = {}

## 初期化（アプリ起動時に1回呼び出し）
static func initialize() -> void:
    _terrain_table.clear()
    _register_terrain(
        GameEnums.TerrainType.OPEN,
        "OPEN", "開地",
        1.0, 1.0, 1.0,          # cover_df, cover_if, concealment
        1.0, 1.0, 1.0,          # speed_mult (foot, wheeled, tracked)
        true, true, true,        # passable
        1.0                      # travel_cost
    )
    _register_terrain(
        GameEnums.TerrainType.ROAD,
        "ROAD", "道路",
        1.0, 0.95, 1.0,
        1.0, 1.0, 1.0,          # road_speedはElementTypeで定義
        true, true, true,
        0.65
    )
    _register_terrain(
        GameEnums.TerrainType.FOREST,
        "FOREST", "森林",
        0.50, 0.50, 0.6,
        0.6, 0.4, 0.4,
        true, false, true,
        1.0
    )
    _register_terrain(
        GameEnums.TerrainType.URBAN,
        "URBAN", "市街",
        0.35, 0.35, 0.7,
        0.5, 0.5, 0.5,
        true, false, false,
        1.0
    )
    _register_terrain(
        GameEnums.TerrainType.WATER,
        "WATER", "水域",
        1.0, 1.0, 1.0,
        0.0, 0.0, 0.0,          # 移動不可
        false, false, false,
        INF
    )

static func _register_terrain(
    id: GameEnums.TerrainType,
    name: String,
    name_jp: String,
    cover_df: float,
    cover_if: float,
    concealment: float,
    speed_foot: float,
    speed_wheeled: float,
    speed_tracked: float,
    pass_foot: bool,
    pass_wheeled: bool,
    pass_tracked: bool,
    travel_cost: float
) -> void:
    var props := TerrainProperties.new()
    props.id = id
    props.name = name
    props.name_jp = name_jp
    props.cover_df = cover_df
    props.cover_if = cover_if
    props.concealment = concealment
    props.speed_mult_foot = speed_foot
    props.speed_mult_wheeled = speed_wheeled
    props.speed_mult_tracked = speed_tracked
    props.passable_foot = pass_foot
    props.passable_wheeled = pass_wheeled
    props.passable_tracked = pass_tracked
    props.travel_cost = travel_cost
    _terrain_table[id] = props

## 地形プロパティを取得
static func get_properties(terrain: GameEnums.TerrainType) -> TerrainProperties:
    if _terrain_table.has(terrain):
        return _terrain_table[terrain]
    return _terrain_table[GameEnums.TerrainType.OPEN]  # フォールバック

## 便利メソッド
static func get_cover_df(terrain: GameEnums.TerrainType) -> float:
    return get_properties(terrain).cover_df

static func get_cover_if(terrain: GameEnums.TerrainType) -> float:
    return get_properties(terrain).cover_if

static func get_concealment(terrain: GameEnums.TerrainType) -> float:
    return get_properties(terrain).concealment

static func get_speed_mult(terrain: GameEnums.TerrainType, mobility: GameEnums.MobilityType) -> float:
    var props := get_properties(terrain)
    match mobility:
        GameEnums.MobilityType.FOOT:
            return props.speed_mult_foot
        GameEnums.MobilityType.WHEELED:
            return props.speed_mult_wheeled
        GameEnums.MobilityType.TRACKED:
            return props.speed_mult_tracked
        _:
            return 1.0

static func is_passable(terrain: GameEnums.TerrainType, mobility: GameEnums.MobilityType) -> bool:
    var props := get_properties(terrain)
    match mobility:
        GameEnums.MobilityType.FOOT:
            return props.passable_foot
        GameEnums.MobilityType.WHEELED:
            return props.passable_wheeled
        GameEnums.MobilityType.TRACKED:
            return props.passable_tracked
        _:
            return false

static func get_travel_cost(terrain: GameEnums.TerrainType) -> float:
    return get_properties(terrain).travel_cost
```

### 4.2 純粋関数クラス: TerrainCalc

**ファイル**: `scripts/systems/terrain_calc.gd`

```gdscript
class_name TerrainCalc
extends RefCounted

## 地形計算の純粋関数群
## TerrainDataのテーブルを参照して値を返す

static func get_cover_coeff_df(terrain: GameEnums.TerrainType) -> float:
    return TerrainData.get_cover_df(terrain)

static func get_cover_coeff_if(terrain: GameEnums.TerrainType) -> float:
    return TerrainData.get_cover_if(terrain)

static func get_concealment_modifier(terrain: GameEnums.TerrainType) -> float:
    return TerrainData.get_concealment(terrain)

static func get_speed_mult(
    terrain: GameEnums.TerrainType,
    mobility: GameEnums.MobilityType
) -> float:
    return TerrainData.get_speed_mult(terrain, mobility)

static func is_passable(
    terrain: GameEnums.TerrainType,
    mobility: GameEnums.MobilityType
) -> bool:
    return TerrainData.is_passable(terrain, mobility)
```

---

## 5. 移行計画

### Phase 1: データ層構築（非破壊）
1. `scripts/data/terrain_data.gd` を新規作成
2. `TerrainData.initialize()` を `Main._ready()` で呼び出し
3. 単体テスト `tests/test_terrain_data.gd` を作成
4. 全テスト通過を確認

### Phase 2: 純粋関数クラス追加
1. `scripts/systems/terrain_calc.gd` を新規作成
2. 単体テスト `tests/test_terrain_calc.gd` を作成
3. TerrainCalcがTerrainDataを正しく参照することを確認

### Phase 3: 既存コードの委譲（段階的）
以下のファイルを順次修正:

| 順序 | ファイル | 変更内容 |
|------|---------|---------|
| 3-1 | `combat_calc.gd` | `get_cover_coeff_df/if()` → `TerrainCalc` に委譲 |
| 3-2 | `vision_calc.gd` | `get_concealment_modifier()` → `TerrainCalc` に委譲 |
| 3-3 | `element_data.gd` | `get_speed()` → `TerrainCalc` に委譲 |
| 3-4 | `map_data.gd` | `is_passable()` → `TerrainCalc` に委譲 |
| 3-5 | `navigation_manager.gd` | 通行判定 → `TerrainCalc` に委譲 |

各ステップで全テスト実行、回帰なしを確認。

### Phase 4: 定数整理
1. `game_constants.gd` から `COVER_DF_*`, `COVER_IF_*` 定数を削除（TerrainDataに移行済み）
2. 全テスト実行、回帰なしを確認

### Phase 5: map_loaderパース改善
1. `_parse_terrain_type()` をTerrainDataに移動
2. 文字列→enum変換テーブルを追加

---

## 6. 新地形追加手順（移行後）

**例: SWAMP（湿地）追加**

### 修正箇所: 2ファイルのみ

1. **game_enums.gd**
```gdscript
enum TerrainType {
    ...
    SWAMP = 5,  ## 湿地
}
```

2. **terrain_data.gd**
```gdscript
static func initialize() -> void:
    ...
    _register_terrain(
        GameEnums.TerrainType.SWAMP,
        "SWAMP", "湿地",
        0.7, 0.8, 0.8,          # cover_df, cover_if, concealment
        0.4, 0.0, 0.3,          # speed_mult (foot, wheeled=不可, tracked)
        true, false, true,       # passable
        1.5                      # travel_cost
    )
```

**効果**: 8ファイル10箇所 → 2ファイル2箇所（80%削減）

---

## 7. テスト計画

### 7.1 新規テスト
- `tests/test_terrain_data.gd` - TerrainDataの全プロパティ検証
- `tests/test_terrain_calc.gd` - TerrainCalcの全関数検証

### 7.2 回帰テスト
既存の以下のテストが変更なく通過すること:
- `tests/test_combat_calc.gd`
- `tests/test_vision_calc.gd`
- `tests/test_map_data.gd`

### 7.3 テスト実行
```bash
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

---

## 8. 検証方法

### 8.1 現行値との一致確認
移行前後で以下の値が一致することを確認:

```gdscript
# Phase 3完了後のテスト
func test_migration_cover_df():
    for terrain in GameEnums.TerrainType.values():
        var old_value := _get_old_cover_df(terrain)  # 旧実装
        var new_value := TerrainCalc.get_cover_coeff_df(terrain)
        assert_eq(old_value, new_value, "cover_df mismatch for %s" % terrain)
```

### 8.2 性能確認
テーブル参照がmatch文より遅くないことを確認（Dictionary参照はO(1)）。

---

## 9. まとめ

| 項目 | 現状 | 移行後 |
|------|------|--------|
| 新地形追加の修正箇所 | 8ファイル10箇所 | 2ファイル2箇所 |
| 係数の一覧性 | 散在 | 1テーブル |
| テスト容易性 | 各Calcクラス個別 | TerrainData集中 |
| デフォルト値管理 | 各match文のワイルドカード | フォールバック統一 |

---

## 付録: 現行コードの抜粋

### A. combat_calc.gd:get_cover_coeff_df()
```gdscript
static func get_cover_coeff_df(terrain: GameEnums.TerrainType) -> float:
    match terrain:
        GameEnums.TerrainType.OPEN:
            return GameConstants.COVER_DF_OPEN
        GameEnums.TerrainType.ROAD:
            return GameConstants.COVER_DF_ROAD
        GameEnums.TerrainType.FOREST:
            return GameConstants.COVER_DF_FOREST
        GameEnums.TerrainType.URBAN:
            return GameConstants.COVER_DF_URBAN
        _:
            return GameConstants.COVER_DF_OPEN
```

### B. vision_calc.gd:get_concealment_modifier()
```gdscript
static func get_concealment_modifier(terrain: GameEnums.TerrainType) -> float:
    match terrain:
        GameEnums.TerrainType.OPEN:
            return 1.0
        GameEnums.TerrainType.ROAD:
            return 1.0
        GameEnums.TerrainType.FOREST:
            return 0.6
        GameEnums.TerrainType.URBAN:
            return 0.7
        GameEnums.TerrainType.WATER:
            return 1.0
        _:
            return 1.0
```

### C. element_data.gd:get_speed()
```gdscript
func get_speed(terrain: GameEnums.TerrainType) -> float:
    if not element_type:
        return 3.0

    match terrain:
        GameEnums.TerrainType.ROAD:
            return element_type.road_speed
        GameEnums.TerrainType.OPEN:
            return element_type.cross_speed
        GameEnums.TerrainType.FOREST:
            if element_type.mobility_class == GameEnums.MobilityType.FOOT:
                return element_type.cross_speed * 0.6
            else:
                return element_type.cross_speed * 0.4
        GameEnums.TerrainType.URBAN:
            return element_type.cross_speed * 0.5
        _:
            return element_type.cross_speed
```
