# Unit Archetypes v0.1

## 概要

本ドキュメントは、Company Commanderで使用するユニットアーキタイプと武器システムの仕様を定義する。

---

## 1. アーキタイプ一覧

### 1.1 歩兵系

| ID | 名称 | カテゴリ | 装甲 | 人数 | 主武装 | 特徴 |
|---|---|---|---|---|---|---|
| INF_LINE | Rifle Squad | INF | Soft(0) | 9 | CW_RIFLE_STD | 標準歩兵分隊 |
| INF_AT | AT Team | INF | Soft(0) | 4 | CW_RIFLE_STD, CW_RPG_HEAT | 対戦車能力 |
| INF_MG | MG Team | WEAP | Soft(0) | 3 | CW_MG_STD | 高い制圧力 |

### 1.2 車両系

| ID | 名称 | カテゴリ | 装甲 | 速度(道路/野外) | 主武装 | 特徴 |
|---|---|---|---|---|---|---|
| TANK_PLT | Tank Platoon | VEH | Heavy(3) | 12/8 m/s | CW_TANK_KE, CW_TANK_HEATMP | 最強の火力と装甲 |
| RECON_VEH | Recon Vehicle | REC | Light(1) | 18/10 m/s | CW_RIFLE_STD | 高機動・長視程 |

### 1.3 支援系

| ID | 名称 | カテゴリ | 装甲 | 人数 | 主武装 | 特徴 |
|---|---|---|---|---|---|---|
| RECON_TEAM | Recon Team | REC | Soft(0) | 4 | CW_RIFLE_STD | 隠密偵察 |
| MORTAR_SEC | Mortar Section | WEAP | Soft(0) | 6 | CW_MORTAR_HE, CW_MORTAR_SMOKE | 間接射撃 |
| LOG_TRUCK | Supply Truck | LOG | Soft(0) | 2 | なし | 補給輸送 |

---

## 2. 武器システム (ConcreteWeaponSet)

### 2.1 小火器

| ID | 名称 | 有効射程 | 脅威クラス | 用途 |
|---|---|---|---|---|
| CW_RIFLE_STD | Standard Rifle | 300m | SMALL_ARMS | 対ソフトターゲット |
| CW_MG_STD | Standard MG | 800m | SMALL_ARMS | 制圧射撃・対ソフト |

### 2.2 対戦車

| ID | 名称 | 有効射程 | 脅威クラス | 用途 |
|---|---|---|---|---|
| CW_RPG_HEAT | AT Rocket | 20-200m | AT | 対装甲（近距離） |
| CW_TANK_KE | Tank APFSDS | 50-2000m | AT | 対装甲（主砲） |
| CW_TANK_HEATMP | Tank HEAT-MP | 0-1500m | AT | 多目的（同軸MG含む） |

### 2.3 間接射撃

| ID | 名称 | 有効射程 | 脅威クラス | 用途 |
|---|---|---|---|---|
| CW_MORTAR_HE | Mortar HE | 100-2000m | HE_FRAG | 面制圧・対ソフト |
| CW_MORTAR_SMOKE | Mortar Smoke | 100-2000m | HE_FRAG | 煙幕展開 |

---

## 3. 装甲クラス

| クラス | 値 | 対象 | 特性 |
|---|---|---|---|
| Soft | 0 | 歩兵・トラック | 小火器に脆弱 |
| Light | 1 | 偵察車両・APC | 小火器に耐性、AT/機関砲に脆弱 |
| Medium | 2 | IFV | 機関砲に部分耐性 |
| Heavy | 3 | MBT | AT以外に高耐性 |

---

## 4. 殺傷力/抑圧力テーブル

### 4.1 CW_RIFLE_STD

| 射程帯 | 距離 | L(Soft) | L(Light) | L(Heavy) | S |
|---|---|---|---|---|---|
| Near | 0-100m | 60 | 10 | 0 | 70 |
| Mid | 100-200m | 45 | 5 | 0 | 55 |
| Far | 200-300m | 25 | 0 | 0 | 35 |

### 4.2 CW_RPG_HEAT

| 射程帯 | 距離 | L(Soft) | L(Light) | L(Heavy) | S | Pen(CE) |
|---|---|---|---|---|---|---|
| Near | 20-50m | 70 | 95 | 80 | 60 | 75 |
| Mid | 50-150m | 50 | 90 | 75 | 50 | 70 |
| Far | 150-200m | 30 | 80 | 65 | 40 | 60 |

### 4.3 CW_TANK_KE

| 射程帯 | 距離 | L(Soft) | L(Light) | L(Heavy) | S | Pen(KE) |
|---|---|---|---|---|---|---|
| Near | 50-500m | 60 | 100 | 95 | 50 | 100 |
| Mid | 500-1500m | 50 | 100 | 90 | 45 | 95 |
| Far | 1500-2000m | 40 | 95 | 80 | 40 | 85 |

### 4.4 CW_MORTAR_HE

| 射程帯 | 距離 | L(Soft) | L(Light) | L(Heavy) | S |
|---|---|---|---|---|---|
| Near | 100-500m | 80 | 40 | 10 | 95 |
| Mid | 500-1500m | 75 | 35 | 10 | 90 |
| Far | 1500-2000m | 70 | 30 | 5 | 85 |

---

## 5. ダメージモデル

### 5.1 歩兵ダメージ

```
Strength = 分隊人数（例: INF_LINE = 9）
破壊時間 = 約30-60秒（K_DF_DMG = 3.0）
```

- ダメージは`accumulated_damage`に蓄積
- 1.0超過ごとに`current_strength -= 1`
- `current_strength <= 0`で破壊

### 5.2 車両ダメージ

```
サブシステムHP:
- mobility_hp (0-100): 機動力
- firepower_hp (0-100): 火力
- sensors_hp (0-100): センサー
```

被害カテゴリ:
- **MINOR (75%)**: サブシステムに5-15ダメージ
- **MAJOR (22%)**: サブシステムに25-50ダメージ
- **CRITICAL (3%)**:
  - 40%: Catastrophic Kill（爆発・即時破壊）
  - 60%: Mission Kill（mobility/firepower = 0）

### 5.3 破壊処理

1. `is_destroyed = true`
2. `destroy_tick`記録
3. 3秒間フェードアウト
4. WorldModelから削除

---

## 6. ElementFactory使用例

```gdscript
# 単体ユニット生成
var tank := ElementFactory.create_element(
    "TANK_PLT",
    GameEnums.Faction.BLUE,
    Vector2(500, 300)
)

# 歩兵中隊生成（5ユニット）
var company := ElementFactory.create_infantry_company(
    GameEnums.Faction.BLUE,
    Vector2(200, 200),
    "alpha_company"
)

# 偵察チーム生成
var recon := ElementFactory.create_recon_element(
    GameEnums.Faction.RED,
    Vector2(800, 400),
    true  # use_vehicle
)
```

---

## 7. ファイル構成

```
scripts/data/
├── element_data.gd      # ElementType, ElementInstance, ElementArchetypes
├── element_factory.gd   # ユニット生成ファクトリ
└── weapon_data.gd       # WeaponType, ConcreteWeaponSet
```

---

## 8. 今後の拡張予定

1. **弾薬管理**: 武器ごとの残弾追跡
2. **乗員負傷**: 車両乗員の負傷による能力低下
3. **装備変更**: 動的な武装の追加/除去
4. **経験値**: ユニットの熟練度システム
