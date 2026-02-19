# Company Commander ドキュメント一覧

Company Commander v0.1 の設計仕様書インデックスです。

---

## コア仕様

| ドキュメント | 内容 |
|-------------|------|
| [spec_v0.1.md](spec_v0.1.md) | ゲーム全体仕様（コンセプト、ターゲット、基本ルール） |
| [ruleset_v0.1.md](ruleset_v0.1.md) | ルールセットパラメータ（定数、係数、閾値） |
| [game_loop_v0.1.md](game_loop_v0.1.md) | ゲームループ（10Hz Sim Tick、Phase構成） |

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
| [damage_model_v0.1.md](damage_model_v0.1.md) | ダメージモデル（貫通判定、Wound/KIA、車両状態遷移） |
| [weapon_system_profile_v0.1.md](weapon_system_profile_v0.1.md) | 武器システムプロファイル（WSP構造、射撃モード） |
| [concrete_weapons_v0.1.md](concrete_weapons_v0.1.md) | 具体武器データ（M4、M240B、M2HB、Javelin等） |
| [weapon_loadout_v0.1.md](weapon_loadout_v0.1.md) | 武装構成（Elementごとの装備スロット） |
| [munition_system_v0.1.md](munition_system_v0.1.md) | 弾薬システム（MunitionClass、弾道計算） |
| [munition_classes_v0.1.md](munition_classes_v0.1.md) | 弾薬クラス詳細（BALL、AP、HE、HEAT、ATGM等） |

---

## 視界・索敵

| ドキュメント | 内容 |
|-------------|------|
| [vision_v0.1.md](vision_v0.1.md) | 視界システム（LoS、発見判定、CONF/SUS/LOST、煙幕、遮蔽） |

---

## AI・命令

| ドキュメント | 内容 |
|-------------|------|
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
├── spec_v0.1.md                 # ゲーム全体仕様
├── ruleset_v0.1.md              # ルールセットパラメータ
├── game_loop_v0.1.md            # ゲームループ
├── map_v0.1.md                  # マップ仕様
├── terrain_v0.1.md              # 地形詳細
├── navigation_v0.1.md           # ナビゲーション
├── units_v0.1.md                # ユニットデータモデル
├── spawn_v0.1.md                # スポーン・増援
├── combat_v0.1.md               # 戦闘システム
├── damage_model_v0.1.md         # ダメージモデル
├── weapon_system_profile_v0.1.md # 武器システム
├── concrete_weapons_v0.1.md     # 具体武器データ
├── weapon_loadout_v0.1.md       # 武装構成
├── munition_system_v0.1.md      # 弾薬システム
├── munition_classes_v0.1.md     # 弾薬クラス
├── vision_v0.1.md               # 視界システム
├── sop_v0.1.md                  # SOP
├── order_queue_v0.1.md          # 命令キュー
├── capture_v0.1.md              # 拠点キャプチャ
├── victory_conditions_v0.1.md   # 勝利条件
├── ui_design_v0.1.md            # UI設計
└── ui_input_v0.1.md             # 入力システム
```

---

## 統合履歴

v0.1 ドキュメント整理時に以下を統合:

| 統合先 | 統合元（削除済み） |
|--------|-------------------|
| map_v0.1.md | map_data_v0.1.md |
| vision_v0.1.md | fog_of_war_v0.1.md |
| units_v0.1.md | unit_data_v0.1.md |
