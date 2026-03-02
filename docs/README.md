# Company Commander ドキュメント一覧

Company Commander v0.1 の設計仕様書インデックスです。

**最終更新**: 2026-03-02
**コード行数**: 約75,000行（GDScript）
**テスト数**: 1,469件

---

## コア仕様

| ドキュメント | 内容 |
|-------------|------|
| [architecture_current_v1.md](architecture_current_v1.md) | **★ 現行アーキテクチャ設計書（リファクタリング後）** |
| [architecture_overview_v0.1.md](architecture_overview_v0.1.md) | アーキテクチャ概要（プロジェクト全体像、システム一覧） |
| [refactoring_pure_functions_v0.1.md](refactoring_pure_functions_v0.1.md) | **純粋関数化計画（計算ロジックのstatic化）** |
| [spec_v0.1.md](spec_v0.1.md) | ゲーム全体仕様（コンセプト、ターゲット、基本ルール） |
| [game_loop_v0.1.md](game_loop_v0.1.md) | ゲームループ（10Hz Sim Tick、Phase構成） |
| [naming_convention_v0.1.md](naming_convention_v0.1.md) | 命名規則（コード・データID命名ルール） |

---

## 装備知識ツリー（Root配下）

**Root**: [military_equipment_2026_detailed.md](root/military_equipment_2026_detailed.md) - 装備知識の親ツリー（taxonomy正）

### 設計・管理

| ドキュメント | 内容 |
|-------------|------|
| [root/document_tree_architecture_v0.1.md](root/document_tree_architecture_v0.1.md) | **アーキテクチャ図・データフロー・責務境界** |
| [root/catalog_docs_mapping.md](root/catalog_docs_mapping.md) | **カタログID⇔ドキュメント対応表** |

### サブツリー

| サブツリー | Index Doc | 内容 |
|-----------|-----------|------|
| **vehicles_tree** | [README.md](vehicles_tree/README.md) | 車両分類・装甲システム |
| **weapons_tree** | [README.md](weapons_tree/README.md) | 武器分類・国別武装詳細 |

### 主要ファイル（vehicles_tree）

| ドキュメント | 種別 | 内容 |
|-------------|------|------|
| [military_vehicles_2026_detailed.md](vehicles_tree/military_vehicles_2026_detailed.md) | Taxonomy | 軍用車両分類 |
| [armour_systems_2026_mainstream.md](vehicles_tree/armour_systems_2026_mainstream.md) | Taxonomy | 装甲システム分類 |

### 主要ファイル（weapons_tree）

| ドキュメント | 種別 | 内容 |
|-------------|------|------|
| [tank_guns_and_ammunition_2026_mainstream.md](weapons_tree/tank_guns_and_ammunition_2026_mainstream.md) | Taxonomy | 戦車砲・弾薬 |
| [autocannons_2026_mainstream.md](weapons_tree/autocannons_2026_mainstream.md) | Taxonomy | 機関砲 |
| [howitzers_2026_mainstream.md](weapons_tree/howitzers_2026_mainstream.md) | Taxonomy | 榴弾砲 |
| [mortars_2026_mainstream.md](weapons_tree/mortars_2026_mainstream.md) | Taxonomy | 迫撃砲 |
| [rockets_and_rocket_artillery_2026_mainstream.md](weapons_tree/rockets_and_rocket_artillery_2026_mainstream.md) | Taxonomy | ロケット砲 |
| [man_portable_anti_tank_weapons_2026_mainstream.md](weapons_tree/man_portable_anti_tank_weapons_2026_mainstream.md) | Taxonomy | 携行対戦車火器 |
| [missiles_guidance_tree.md](weapons_tree/missiles_guidance_tree.md) | Taxonomy | ミサイル誘導体系 |
| [us_army_weapons_2026.md](weapons_tree/us_army_weapons_2026.md) | Detail | 米陸軍武装 |
| [russian_army_weapons_2026.md](weapons_tree/russian_army_weapons_2026.md) | Detail | ロシア軍武装 |
| [chinese_army_weapons_2026.md](weapons_tree/chinese_army_weapons_2026.md) | Detail | 中国軍武装 |
| [jgsdf_weapons_2026.md](weapons_tree/jgsdf_weapons_2026.md) | Detail | 陸自武装 |

---

## マップ・ナビゲーション

| ドキュメント | 内容 |
|-------------|------|
| [map_v0.1.md](map_v0.1.md) | マップ仕様（座標系、地形タイプ、GeoJSON、MVP_01_CROSSROADS） |
| [terrain_v0.1.md](terrain_v0.1.md) | 地形詳細（移動コスト、遮蔽、発見係数） |
| [terrain_table_design_v0.1.md](terrain_table_design_v0.1.md) | 地形テーブル設計（地形属性と効果値） |
| [navigation_v0.1.md](navigation_v0.1.md) | ナビゲーション（NavigationServer2D、6レイヤー、動的障害物） |

---

## ユニット・編成

| ドキュメント | 内容 |
|-------------|------|
| [units_v0.1.md](units_v0.1.md) | ユニットデータモデル（ElementArchetype、UnitCard、国別オーバーライド） |
| [unit_archetypes_v0.1.md](unit_archetypes_v0.1.md) | ユニットアーキタイプ一覧（歩兵・車両・砲兵の分類） |
| [vehicle_catalog_v0.1.md](vehicle_catalog_v0.1.md) | 兵器カタログシステム（各国の車両・武装定義） |
| [spawn_v0.1.md](spawn_v0.1.md) | スポーン・増援システム（Initial Deploy、Forward Entry） |

---

## 戦闘システム

| ドキュメント | 内容 |
|-------------|------|
| [combat_v0.1.md](combat_v0.1.md) | 戦闘システム概要（射撃フロー、命中判定） |
| [combat_events_v0.1.md](combat_events_v0.1.md) | 戦闘イベント（イベント構造、状態遷移、エスカレーションルール） |
| [damage_model_v0.1.md](damage_model_v0.1.md) | ダメージモデル（貫通判定、Wound/KIA、車両状態遷移） |
| [weapon_loadout_v0.1.md](weapon_loadout_v0.1.md) | 武装構成（Elementごとの装備スロット） |
| [munition_system_v0.1.md](munition_system_v0.1.md) | 弾薬分類体系（MunitionClass、弾頭タイプ） |
| [ammunition_system_v0.1.md](ammunition_system_v0.1.md) | **残弾・補給システム（弾薬管理、装填、補給ユニット）** |
| [missile_system_v0.2.md](missile_system_v0.2.md) | **ミサイルシステム（誘導方式、飛翔モデル、射手拘束、対抗手段）** |
| [indirect_fire_v0.2.md](indirect_fire_v0.2.md) | **間接射撃システム（榴弾砲・迫撃砲、CEP、着弾効果）** |

---

## 輸送システム

| ドキュメント | 内容 |
|-------------|------|
| [transport_system_v0.1.md](transport_system_v0.1.md) | **輸送システム（乗車/下車、IFV/APC）** |

---

## 視界・索敵

| ドキュメント | 内容 |
|-------------|------|
| [vision_v0.1.md](vision_v0.1.md) | 視界システム（LoS、発見判定、CONF/SUS/LOST、煙幕、遮蔽） |
| [data_link_v0.1.md](data_link_v0.1.md) | データリンク・C4I（通信ハブ、情報共有範囲、LINKED/ISOLATED） |

---

## AI・命令

| ドキュメント | 内容 |
|-------------|------|
| [company_ai_v0.1.md](company_ai_v0.1.md) | 中隊AI（CompanyControllerAI、戦術テンプレート、役割配分） |
| [risk_assessment_v0.1.md](risk_assessment_v0.1.md) | リスク評価（装甲脅威、AT脅威、OPEN横断コスト、ミティゲーション） |
| [sop_v0.1.md](sop_v0.1.md) | SOP（Standard Operating Procedure、Element自律行動） |
| [order_queue_v0.1.md](order_queue_v0.1.md) | 命令キュー（コマンド構造、実行フロー） |

---

## 拠点・勝利条件

| ドキュメント | 内容 |
|-------------|------|
| [capture_v0.1.md](capture_v0.1.md) | 拠点キャプチャ（CP属性、占領ルール） |
| [victory_conditions_v0.1.md](victory_conditions_v0.1.md) | 勝利条件（チケット、出血ルール、勝敗判定） |

---

## UI・入力

| ドキュメント | 内容 |
|-------------|------|
| [ui_design_v0.1.md](ui_design_v0.1.md) | UI設計（レイアウト、パネル構成） |
| [ui_input_v0.1.md](ui_input_v0.1.md) | 入力システム（マウス、キーボード、選択操作） |
| [controls.md](controls.md) | 操作方法クイックリファレンス |
| [pie_menu_commands_v0.2.md](pie_menu_commands_v0.2.md) | パイメニューコマンド設計（ユニット別コマンド体系） |

---

## データアーキテクチャ（SSoT）

ゲームデータは **Single Source of Truth (SSoT)** 原則に基づき、JSONファイルで一元管理されています。

### データディレクトリ構成

```
data/
├── weapons/                    # 武器データ
│   ├── weapons_usa.json        # 米軍武器
│   ├── weapons_rus.json        # ロシア軍武器
│   ├── weapons_chn.json        # 中国軍武器
│   ├── weapons_jpn.json        # 陸自武器
│   └── weapons_common.json     # 共通武器
├── ammunition/                 # 弾薬データ
│   └── ammunition_profiles.json
├── archetypes/                 # ユニットアーキタイプ
│   └── element_archetypes.json
├── protection/                 # 防護プロファイル
│   └── protection_profiles.json
├── missiles/                   # ミサイルプロファイル
│   └── missile_profiles.json
└── vehicles/                   # 車両カタログ
    ├── vehicles_usa.json       # 米軍車両
    ├── vehicles_rus.json       # ロシア軍車両
    ├── vehicles_chn.json       # 中国軍車両
    └── vehicles_jpn.json       # 陸自車両
```

### SSoT対応スクリプト

| スクリプト | JSONパス | 内容 |
|-----------|----------|------|
| `weapon_data.gd` | `data/weapons/*.json` | 武器性能（射程、発射速度、貫通力） |
| `ammunition_data.gd` | `data/ammunition/*.json` | 弾薬プロファイル（APFSDS、HEAT、HE等） |
| `element_data.gd` | `data/archetypes/*.json` | ユニット定義（歩兵、戦車、IFV等） |
| `protection_data.gd` | `data/protection/*.json` | 防護システム（ERA、APS、複合装甲） |
| `vehicle_catalog.gd` | `data/vehicles/*.json` | 車両カタログ（武装、装甲、性能） |
| `missile_data.gd` | `data/missiles/*.json` | ミサイルプロファイル（誘導方式、飛翔性能） |

---

## アーカイブ

旧ハードコード実装は `scripts/archive/` に保存されています：

- `weapon_data_hardcoded.gd`
- `ammunition_data_hardcoded.gd`
- `element_data_hardcoded.gd`
- `protection_data_hardcoded.gd`
