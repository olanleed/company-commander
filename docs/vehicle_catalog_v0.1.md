# 兵器カタログシステム設計 v0.1

## 概要

各国の兵器（戦車、IFV等）の特性をJSONで定義し、小隊ユニットの性能を変化させるシステム。

---

## 1. 設計方針

### 1.1 レイヤー構造

```
┌─────────────────────────────────────────────────────────┐
│  VehicleCatalog (JSON)                                  │
│  - 実在兵器のカタログスペック                            │
│  - 国別・年代別に整理                                    │
│  - 例: Type10, M1A2, T-90M, Type89, M2A3, BMP-3         │
└─────────────────────────────────────────────────────────┘
                          ↓ 適用
┌─────────────────────────────────────────────────────────┐
│  ElementType (GDScript)                                 │
│  - 抽象的なユニットタイプ (TANK_PLT, IFV_PLT等)          │
│  - カタログから性能値を上書き                            │
└─────────────────────────────────────────────────────────┘
                          ↓ 生成
┌─────────────────────────────────────────────────────────┐
│  ElementInstance                                        │
│  - 実際のゲーム内ユニット                                │
│  - 「10式戦車小隊」「M1A2小隊」として区別可能             │
└─────────────────────────────────────────────────────────┘
```

### 1.2 現状のElementType → 拡張

現在の `TANK_PLT` は「汎用第3世代MBT」として定義されている。
これを**ベースライン**として、各国兵器は**差分（modifier）で表現**する。

```
TANK_PLT (base)
├── JPN_Type10    : 装甲+5%, 命中+10%, 速度-5%
├── JPN_Type90    : 装甲+0%, 命中+5%, 速度+0%
├── USA_M1A2SEPv3 : 装甲+10%, 命中+5%, 速度-10%
├── RUS_T90M      : 装甲-5%, 命中+0%, 速度+10%
└── GER_Leopard2A7: 装甲+5%, 命中+10%, 速度+0%
```

---

## 2. JSONスキーマ

### 2.1 ファイル構成

```
data/
└── catalog/
    ├── vehicles_jpn.json    # 日本
    ├── vehicles_usa.json    # アメリカ
    ├── vehicles_rus.json    # ロシア
    ├── vehicles_ger.json    # ドイツ
    └── vehicles_chn.json    # 中国
```

### 2.2 車両カタログ構造

```json
{
  "catalog_version": "0.1",
  "nation": "JPN",
  "nation_name": "Japan",
  "vehicles": [
    {
      "id": "JPN_Type10",
      "display_name": "10式戦車",
      "display_name_en": "Type 10",
      "base_archetype": "TANK_PLT",
      "era": "2010s",
      "unit_count": 4,

      "modifiers": {
        "armor_ke_front": 1.05,
        "armor_ke_side": 1.00,
        "armor_ce_front": 1.10,
        "armor_ce_side": 1.00,
        "spot_range": 1.05,
        "road_speed": 1.00,
        "cross_speed": 0.95
      },

      "main_gun": {
        "caliber_mm": 120,
        "type": "smoothbore",
        "autoloader": false,
        "pen_ke_modifier": 1.10,
        "pen_ce_modifier": 1.00,
        "rof_modifier": 1.00,
        "accuracy_modifier": 1.10
      },

      "protection": {
        "era_equipped": false,
        "aps_equipped": false,
        "composite_gen": 4
      },

      "notes": "世界最高クラスのFCS、軽量で機動性重視"
    },
    {
      "id": "JPN_Type90",
      "display_name": "90式戦車",
      "display_name_en": "Type 90",
      "base_archetype": "TANK_PLT",
      "era": "1990s",
      "unit_count": 4,

      "modifiers": {
        "armor_ke_front": 1.00,
        "armor_ke_side": 0.95,
        "armor_ce_front": 1.00,
        "armor_ce_side": 0.95,
        "spot_range": 1.00,
        "road_speed": 1.05,
        "cross_speed": 1.00
      },

      "main_gun": {
        "caliber_mm": 120,
        "type": "smoothbore",
        "autoloader": true,
        "pen_ke_modifier": 1.00,
        "pen_ce_modifier": 1.00,
        "rof_modifier": 1.15,
        "accuracy_modifier": 1.00
      },

      "protection": {
        "era_equipped": false,
        "aps_equipped": false,
        "composite_gen": 3
      },

      "notes": "自動装填装置、高い発射レート"
    }
  ]
}
```

### 2.3 IFV/APCカタログ構造

```json
{
  "id": "JPN_Type89",
  "display_name": "89式装甲戦闘車",
  "display_name_en": "Type 89 IFV",
  "base_archetype": "IFV_PLT",
  "era": "1990s",
  "unit_count": 4,

  "modifiers": {
    "armor_ke_front": 1.00,
    "armor_ke_side": 0.90,
    "road_speed": 1.00,
    "cross_speed": 1.00,
    "infantry_capacity": 7
  },

  "main_weapon": {
    "type": "autocannon",
    "caliber_mm": 35,
    "dual_feed": true,
    "pen_modifier": 1.05,
    "rof_modifier": 1.00
  },

  "atgm": {
    "type": "Type 79",
    "range_m": 4000,
    "pen_ce": 85,
    "count": 2
  },

  "notes": "79式対舟艇対戦車誘導弾搭載"
}
```

---

## 3. 適用フロー

### 3.1 初期化時

```gdscript
# VehicleCatalog をロード
var catalog := VehicleCatalog.new()
catalog.load_all()

# 陣営に車両を設定
var jpn_faction := FactionConfig.new()
jpn_faction.tank = catalog.get_vehicle("JPN_Type10")
jpn_faction.ifv = catalog.get_vehicle("JPN_Type89")
```

### 3.2 ユニット生成時

```gdscript
# ElementFactory で生成
var tank_plt := ElementFactory.create_element_with_vehicle(
    "TANK_PLT",
    faction,
    position,
    vehicle_config  # JPN_Type10 の設定
)
# ElementType の値が vehicle_config.modifiers で調整される
```

### 3.3 武器の適用

```gdscript
# ベース武器 CW_TANK_KE に modifier を適用
var base_weapon := WeaponData.create_cw_tank_ke()
var modified_weapon := apply_vehicle_modifiers(base_weapon, vehicle_config.main_gun)
# pen_ke が 140 → 154 (×1.10) に
# accuracy が向上
```

---

## 4. Modifierの詳細

### 4.1 装甲系 (0.5〜1.5)

| キー | 説明 | 基準値 |
|------|------|--------|
| `armor_ke_front` | 正面KE装甲倍率 | 1.0 |
| `armor_ke_side` | 側面KE装甲倍率 | 1.0 |
| `armor_ke_rear` | 後部KE装甲倍率 | 1.0 |
| `armor_ce_front` | 正面CE装甲倍率 | 1.0 |
| `armor_ce_side` | 側面CE装甲倍率 | 1.0 |
| `armor_ce_rear` | 後部CE装甲倍率 | 1.0 |

### 4.2 火力系 (0.5〜1.5)

| キー | 説明 | 基準値 |
|------|------|--------|
| `pen_ke_modifier` | KE貫徹力倍率 | 1.0 |
| `pen_ce_modifier` | CE貫徹力倍率 | 1.0 |
| `rof_modifier` | 発射レート倍率 | 1.0 |
| `accuracy_modifier` | 命中精度倍率 (sigma_hit_m の逆数) | 1.0 |

### 4.3 機動系 (0.5〜1.5)

| キー | 説明 | 基準値 |
|------|------|--------|
| `road_speed` | 路上速度倍率 | 1.0 |
| `cross_speed` | 不整地速度倍率 | 1.0 |

### 4.4 センサー系 (0.5〜1.5)

| キー | 説明 | 基準値 |
|------|------|--------|
| `spot_range` | 視認距離倍率 | 1.0 |
| `spot_range_moving` | 移動中視認距離倍率 | 1.0 |

---

## 5. サンプル兵器データ

### 5.1 戦車 (MBT)

| 国 | ID | 名称 | 装甲 | 火力 | 機動 | 特徴 |
|----|-----|------|------|------|------|------|
| 日本 | JPN_Type10 | 10式 | +5% | +10% | -5% | 高精度FCS、C4I |
| 日本 | JPN_Type90 | 90式 | ±0% | +5% ROF | +5% | 自動装填 |
| 米国 | USA_M1A2SEPv3 | M1A2 | +10% | +5% | -10% | 重装甲、高火力 |
| 露国 | RUS_T90M | T-90M | -5% | ±0% | +10% | APS搭載 |
| 独国 | GER_Leopard2A7 | Leo2A7 | +5% | +10% | ±0% | バランス型 |

### 5.2 IFV

| 国 | ID | 名称 | 装甲 | 火力 | 歩兵 | 特徴 |
|----|-----|------|------|------|------|------|
| 日本 | JPN_Type89 | 89式 | ±0% | 35mm | 7名 | ATGM搭載 |
| 米国 | USA_M2A3 | Bradley | +10% | 25mm | 6名 | TOW搭載 |
| 露国 | RUS_BMP3 | BMP-3 | -10% | 100mm+30mm | 7名 | 高火力 |

---

## 6. 実装ファイル

### 6.1 新規作成

| ファイル | 説明 |
|---------|------|
| `scripts/data/vehicle_catalog.gd` | カタログ管理クラス |
| `data/catalog/vehicles_jpn.json` | 日本兵器データ |
| `data/catalog/vehicles_usa.json` | 米国兵器データ |
| `data/catalog/vehicles_rus.json` | 露国兵器データ |

### 6.2 修正

| ファイル | 変更内容 |
|---------|---------|
| `scripts/data/element_data.gd` | VehicleConfigを受け取るメソッド追加 |
| `scripts/data/element_factory.gd` | カタログ適用ロジック追加 |
| `scripts/data/weapon_data.gd` | modifier適用メソッド追加 |

---

## 7. 今後の拡張

### 7.1 Phase 1 (本設計)
- 戦車・IFVのカタログ化
- 日米露の主要車両

### 7.2 Phase 2 (将来)
- 偵察車両・APC
- 砲兵・防空

### 7.3 Phase 3 (将来)
- 歩兵武器のカタログ化
- 国別の標準装備セット

---

## 8. 実装上の注意

### 8.1 バランス
- modifier は **0.8〜1.2** の範囲を推奨
- 極端な差は避ける（ゲームバランス優先）

### 8.2 リアリズム vs ゲーム性
- 実際のスペック差を反映しつつ、ゲームとして楽しめる範囲に収める
- 「10式は最強」ではなく「10式はFCSが優秀で命中率が高い」という特徴付け

### 8.3 拡張性
- JSONで定義することで、MOD対応が容易
- ユーザーが独自の車両を追加可能
