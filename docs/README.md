# Company Commander ドキュメント一覧

Company Commander v0.1 の設計仕様書インデックスです。

---

## コア仕様

| ドキュメント | 内容 |
|-------------|------|
| [architecture_overview_v0.1.md](architecture_overview_v0.1.md) | **アーキテクチャ概要（プロジェクト全体像、システム一覧、データモデル）** |
| [spec_v0.1.md](spec_v0.1.md) | ゲーム全体仕様（コンセプト、ターゲット、基本ルール） |
| [ruleset_v0.1.md](ruleset_v0.1.md) | ルールセットパラメータ（定数、係数、閾値） |
| [game_loop_v0.1.md](game_loop_v0.1.md) | ゲームループ（10Hz Sim Tick、Phase構成） |

---

## 装備知識ツリー（Root配下）

**Root**: [military_equipment_2026_detailed.md](root/military_equipment_2026_detailed.md) - 装備知識の親ツリー（taxonomy正）

### 設計・管理

| ドキュメント | 内容 |
|-------------|------|
| [root/document_tree_architecture_v0.1.md](root/document_tree_architecture_v0.1.md) | **アーキテクチャ図・データフロー・責務境界** |
| [root/document_tree_refactor_plan_v0.1.md](root/document_tree_refactor_plan_v0.1.md) | 設計方針・リファクタリング計画 |
| [root/document_tree_refactor_execution_v0.1.md](root/document_tree_refactor_execution_v0.1.md) | 実施計画・インベントリ |
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
| [navigation_v0.1.md](navigation_v0.1.md) | ナビゲーション（NavigationServer2D、6レイヤー、動的障害物） |

---

## ユニット・編成

| ドキュメント | 内容 |
|-------------|------|
| [units_v0.1.md](units_v0.1.md) | ユニットデータモデル（ElementArchetype、UnitCard、国別オーバーライド） |
| [spawn_v0.1.md](spawn_v0.1.md) | スポーン・増援システム（Initial Deploy、Forward Entry） |

---

## 戦闘システム

| ドキュメント | 内容 |
|-------------|------|
| [combat_v0.1.md](combat_v0.1.md) | 戦闘システム概要（射撃フロー、命中判定） |
| [combat_events_v0.1.md](combat_events_v0.1.md) | 戦闘イベント（イベント構造、状態遷移、エスカレーションルール） |
| [damage_model_v0.1.md](damage_model_v0.1.md) | ダメージモデル（貫通判定、Wound/KIA、車両状態遷移） |
| [weapon_system_profile_v0.1.md](weapon_system_profile_v0.1.md) | 武器システムプロファイル（WSP構造、射撃モード） |
| [concrete_weapons_v0.1.md](concrete_weapons_v0.1.md) | 具体武器データ（M4、M240B、M2HB、Javelin等） |
| [weapon_loadout_v0.1.md](weapon_loadout_v0.1.md) | 武装構成（Elementごとの装備スロット） |
| [munition_system_v0.1.md](munition_system_v0.1.md) | 弾薬システム（MunitionClass、弾道計算） |
| [munition_classes_v0.1.md](munition_classes_v0.1.md) | 弾薬クラス詳細（BALL、AP、HE、HEAT、ATGM等） |
| [missile_system_v0.2.md](missile_system_v0.2.md) | **ミサイルシステム（誘導方式、飛翔モデル、射手拘束、対抗手段）** |

---

## 視界・索敵

| ドキュメント | 内容 |
|-------------|------|
| [vision_v0.1.md](vision_v0.1.md) | 視界システム（LoS、発見判定、CONF/SUS/LOST、煙幕、遮蔽） |

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

---

## ドキュメント構成

```
docs/
├── README.md                    # このファイル（インデックス）
├── root/                        # 装備知識ルート
│   ├── military_equipment_2026_detailed.md  # Root（taxonomy親）
│   ├── document_tree_refactor_plan_v0.1.md  # 設計方針
│   ├── document_tree_refactor_execution_v0.1.md  # 実施計画
│   └── catalog_docs_mapping.md  # カタログ対応表
├── vehicles_tree/               # 車両知識サブツリー
│   ├── README.md                # Index Doc
│   ├── military_vehicles_2026_detailed.md
│   └── armour_systems_2026_mainstream.md
├── weapons_tree/                # 兵器知識サブツリー
│   ├── README.md                # Index Doc
│   ├── *_2026_mainstream.md     # Taxonomy（分類体系）
│   └── *_weapons_2026.md        # Detail（国別具体値）
├── spec_v0.1.md                 # ゲーム全体仕様
├── ruleset_v0.1.md              # ルールセットパラメータ
├── game_loop_v0.1.md            # ゲームループ
├── map_v0.1.md                  # マップ仕様
├── terrain_v0.1.md              # 地形詳細
├── navigation_v0.1.md           # ナビゲーション
├── units_v0.1.md                # ユニットデータモデル
├── spawn_v0.1.md                # スポーン・増援
├── combat_v0.1.md               # 戦闘システム
├── combat_events_v0.1.md        # 戦闘イベント
├── damage_model_v0.1.md         # ダメージモデル
├── weapon_system_profile_v0.1.md # 武器システム
├── concrete_weapons_v0.1.md     # 具体武器データ
├── weapon_loadout_v0.1.md       # 武装構成
├── munition_system_v0.1.md      # 弾薬システム
├── munition_classes_v0.1.md     # 弾薬クラス
├── vision_v0.1.md               # 視界システム
├── company_ai_v0.1.md           # 中隊AI
├── risk_assessment_v0.1.md      # リスク評価
├── sop_v0.1.md                  # SOP
├── order_queue_v0.1.md          # 命令キュー
├── capture_v0.1.md              # 拠点キャプチャ
├── victory_conditions_v0.1.md   # 勝利条件
├── ui_design_v0.1.md            # UI設計
└── ui_input_v0.1.md             # 入力システム
```

---

## データアーキテクチャ（SSoT）

ゲームデータは **Single Source of Truth (SSoT)** 原則に基づき、JSONファイルで一元管理されています。

### データディレクトリ構成

```
data/
├── weapons/                    # 武器データ (66種)
│   ├── weapons_usa.json        # 米軍武器
│   ├── weapons_rus.json        # ロシア軍武器
│   ├── weapons_chn.json        # 中国軍武器
│   ├── weapons_jpn.json        # 陸自武器
│   └── weapons_common.json     # 共通武器
├── ammunition/                 # 弾薬データ (33種)
│   └── ammunition_profiles.json
├── archetypes/                 # ユニットアーキタイプ (24種)
│   └── element_archetypes.json
├── protection/                 # 防護プロファイル (7種)
│   └── protection_profiles.json
└── catalog/                    # 車両カタログ
    ├── vehicles_usa.json       # 米軍車両
    ├── vehicles_rus.json       # ロシア軍車両
    ├── vehicles_chn.json       # 中国軍車両
    └── vehicles_jpn.json       # 陸自車両
```

### SSoT対応スクリプト

| スクリプト | JSONパス | データ件数 | 内容 |
|-----------|----------|-----------|------|
| `weapon_data.gd` | `data/weapons/*.json` | 66武器 | 武器性能（射程、発射速度、貫通力） |
| `ammunition_data.gd` | `data/ammunition/*.json` | 33弾薬 | 弾薬プロファイル（APFSDS、HEAT、HE等） |
| `element_data.gd` | `data/archetypes/*.json` | 24アーキタイプ | ユニット定義（歩兵、戦車、IFV等） |
| `protection_data.gd` | `data/protection/*.json` | 7プロファイル | 防護システム（ERA、APS、複合装甲） |
| `vehicle_catalog.gd` | `data/catalog/*.json` | 4国 | 車両カタログ（武装、装甲、性能） |

### エクスポートツール

`tools/` ディレクトリにJSONエクスポートスクリプトがあります：

```bash
# 武器データをエクスポート
godot --headless --script tools/export_weapons_to_json.gd

# 弾薬データをエクスポート
godot --headless --script tools/export_ammunition_to_json.gd

# アーキタイプをエクスポート
godot --headless --script tools/export_archetypes_to_json.gd

# 防護プロファイルをエクスポート
godot --headless --script tools/export_protection_to_json.gd
```

### アーカイブ

旧ハードコード実装は `scripts/archive/` に保存されています：

- `weapon_data_hardcoded.gd`
- `ammunition_data_hardcoded.gd`
- `element_data_hardcoded.gd`
- `protection_data_hardcoded.gd`

---

## 統合履歴

v0.1 ドキュメント整理時に以下を統合:

| 統合先 | 統合元（削除済み） |
|--------|-------------------|
| map_v0.1.md | map_data_v0.1.md |
| vision_v0.1.md | fog_of_war_v0.1.md |
| units_v0.1.md | unit_data_v0.1.md |
