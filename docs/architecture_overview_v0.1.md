# Company Commander アーキテクチャ概要 v0.1

本ドキュメントは Company Commander プロジェクトの全体像をまとめた設計・仕様概要です。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| **プロジェクト名** | Company Commander |
| **バージョン** | v0.1.0 (α段階) |
| **ジャンル** | 2D 現代戦リアルタイムストラテジー（RTS） |
| **ゲームエンジン** | Godot 4.6 (Forward Plus) |
| **解像度** | 1920×1080 |
| **主要言語** | GDScript |

### コンセプト

- **時代**: 2020年代の地上戦闘
- **スケール**: 中隊規模（50-200人、2-4要素）
- **視点**: 俯瞰2Dビュー、NATOミルシム風シンボル表示
- **リアリズム**: 抑圧・統制・通信摩擦といった現代戦のエッセンスを再現

---

## 2. ディレクトリ構成

```
company-commander/
├── project.godot           # Godot設定
├── CLAUDE.md               # TDD/品質ガイドライン
├── TODO.md                 # 開発TODOリスト
│
├── scenes/
│   └── Main.tscn           # メインシーン
│
├── scripts/                # GDScriptソース（約50ファイル、9000行）
│   ├── Main.gd             # エントリポイント
│   ├── core/               # コアシステム
│   ├── data/               # データモデル
│   ├── systems/            # ゲームシステム
│   ├── ai/                 # AIシステム
│   ├── ui/                 # UI/HUD
│   ├── entities/           # エンティティ表示
│   └── debug/              # デバッグツール
│
├── data/catalog/           # 国別車両カタログ（JSON）
├── assets/units/           # 軍事シンボルSVG（NATO標準）
├── maps/                   # マップデータ
├── tests/                  # テストファイル（Gut）
├── docs/                   # 設計仕様書（30+ドキュメント）
└── addons/gut/             # テストフレームワーク
```

---

## 3. コアアーキテクチャ

### 3.1 ゲームループ（10Hz固定タイムステップ）

```
┌─────────────────────────────────────────────────┐
│  _process(delta)                                │
│  ┌───────────────────────────────────────────┐  │
│  │ accumulator += delta                      │  │
│  │ while accumulator >= SIM_DT (0.1s):       │  │
│  │   ├─ VisionSystem.update()                │  │
│  │   ├─ CombatSystem.update()                │  │
│  │   ├─ MovementSystem.update()              │  │
│  │   ├─ CompanyControllerAI.update()         │  │
│  │   └─ CaptureSystem.update()               │  │
│  │   accumulator -= SIM_DT                   │  │
│  └───────────────────────────────────────────┘  │
│  描画補間: lerp(prev_pos, curr_pos, alpha)      │
└─────────────────────────────────────────────────┘
```

- **SIM_DT**: 0.1秒（10Hz）
- **MAX_STEPS_PER_FRAME**: 8（処理落ち対策）
- **描画補間**: 10Hz→滑らかな見た目

### 3.2 主要コンポーネント依存関係

```
┌─────────────┐
│   Main.gd   │
└──────┬──────┘
       │ setup
       ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ WorldModel  │◄────│  Systems    │────►│    AI       │
│ (純データ)   │     │ (ロジック)   │     │ (意思決定)   │
└──────┬──────┘     └──────┬──────┘     └─────────────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│  EventBus   │────►│     UI      │
│ (イベント)   │     │ (表示/入力)  │
└─────────────┘     └─────────────┘
```

---

## 4. システム一覧

### 4.1 コアシステム（scripts/core/）

| ファイル | 責務 |
|----------|------|
| game_constants.gd | 全ゲーム定数（618行） |
| game_enums.gd | 全列挙型（408行） |
| world_model.gd | ゲーム世界状態（ユニット、拠点等） |
| sim_runner.gd | 10Hzシミュレーション実行 |

### 4.2 データモデル（scripts/data/）

| ファイル | 責務 |
|----------|------|
| element_data.gd | ユニット定義（ElementType/Instance） |
| element_factory.gd | ユニット生成ファクトリ |
| weapon_data.gd | 武器データ構造 |
| ammunition_data.gd | 弾薬データ構造 |
| protection_data.gd | 装甲・防護データ |
| vehicle_catalog.gd | 車両カタログ管理 |
| map_data.gd | マップデータ |

### 4.3 ゲームシステム（scripts/systems/）

| ファイル | 責務 |
|----------|------|
| combat_system.gd | 戦闘効果計算（直射・間接） |
| movement_system.gd | ユニット移動・パス追従 |
| vision_system.gd | 視界・索敵・FoW |
| navigation_manager.gd | ナビゲーション（A*パス探索） |
| capture_system.gd | 拠点制圧 |
| transport_system.gd | IFV/APC輸送 |
| data_link_system.gd | 通信システム |
| combat_event_bus.gd | 戦闘イベント発行 |

### 4.4 AIシステム（scripts/ai/）

| ファイル | 責務 |
|----------|------|
| company_controller_ai.gd | 中隊AI制御 |
| tactical_template.gd | 戦術テンプレート基底 |
| risk_assessment.gd | リスク評価エンジン |
| templates/*.gd | 各戦術テンプレート実装 |

### 4.5 UIシステム（scripts/ui/）

| ファイル | 責務 |
|----------|------|
| hud_manager.gd | HUD管理 |
| input_controller.gd | 入力処理 |
| pie_menu.gd | 放射状コマンドメニュー |
| tactical_overlay.gd | 戦術情報オーバーレイ |
| minimap.gd | ミニマップ |
| left_panel.gd / right_panel.gd | サイドパネル |

---

## 5. データモデル詳細

### 5.1 ユニット（Element）

```
ElementType（固定仕様）
├─ id: String
├─ display_name: String
├─ category: UnitCategory (INF/VEH/TANK...)
├─ base_strength: int
├─ base_speed: float
├─ armor_class: int (0-3)
├─ armor_ke/ce: Dictionary (FRONT/SIDE/REAR/TOP)
├─ sensors: Dictionary
└─ weapons: Array[WeaponData]

ElementInstance（可変状態）
├─ id: String
├─ element_type: ElementType
├─ faction: Faction (BLUE/RED/NEUTRAL)
├─ position: Vector2
├─ rotation: float
├─ velocity: Vector2
├─ current_strength: int
├─ suppression: float (0.0-1.0)
├─ current_order: OrderType
├─ current_path: PackedVector2Array
├─ contact_state: ContactState (CONF/SUS/LOST)
├─ vehicle_subsystems: Dictionary (mobility_hp/firepower_hp/sensors_hp)
└─ is_destroyed: bool
```

### 5.2 武器（WeaponData）

```
WeaponData
├─ id: String
├─ display_name: String
├─ weapon_type: WeaponType (RIFLE/MG/CANNON/ATGM...)
├─ threat_class: ThreatClass (SMALLARMS/AUTOCANNON/AT...)
├─ fire_control: FireControl (DIRECT/INDIRECT)
├─ fire_rate: float (rpm)
├─ accuracy: float
├─ effective_range: float
└─ munition_ids: Array[String]
```

### 5.3 弾薬（AmmunitionData）

```
AmmunitionData
├─ id: String
├─ display_name: String
├─ munition_class: MunitionClass (BALL/AP/HE/HEAT/APFSDS...)
├─ caliber: String
├─ muzzle_velocity: float
├─ penetration: float (mm RHA)
├─ suppression_power: float
├─ lethality: float
└─ blast_radius: float (HE系のみ)
```

---

## 6. 主要メカニクス

### 6.1 戦闘システム

**直射戦闘**:
- 離散ヒットモデル: `p_hit = 1 - exp(-K × E)`
- 命中係数 K_DF_HIT = 0.50
- ダメージ係数 K_DF_DMG = 3.0（約40秒で全滅）
- 抑圧係数 K_DF_SUPP = 0.12

**抑圧状態**:
| 状態 | 閾値 | 速度 | 射撃力 |
|------|------|------|--------|
| NORMAL | <40% | 100% | 100% |
| SUPPRESSED | 40-70% | 85% | 70% |
| PINNED | 70-90% | 20% | 35% |
| BROKEN | >90% | 0% | 0% |

**装甲判定**:
- 4ゾーン: FRONT/SIDE/REAR/TOP
- 2種類: KE（運動エネルギー）/CE（成形炸薬）
- アスペクトアングルによる有効装甲変動

### 6.2 視界システム

```
視認状態遷移:
  UNKNOWN ──(視認)──► SUS ──(3秒継続)──► CONF
     ▲                                    │
     │                                    │
     └────(60秒)──── LOST ◄──(15秒)───────┘
                      ▲
                      │
                  (視界喪失)
```

- 位置誤差: 視認喪失後、毎秒6m増加（上限300m）

### 6.3 中隊AI

**戦術テンプレート**:
- MOVE: 目標地点への移動
- ATTACK_CP: 拠点攻撃
- DEFEND_CP: 拠点防御
- RECON: 偵察
- BREAK_CONTACT: 戦闘離脱

**更新周期**:
| 評価 | 周期 |
|------|------|
| 接触評価 | 0.5秒 |
| 戦術評価 | 1.0秒 |
| 大局評価 | 5.0秒 |

### 6.4 拠点制圧

- 制圧パワー: ユニット役割別（INF 1.0, REC 0.7, VEH 0.4, TANK 0.6）
- 制圧速度: 1.5 control/秒/有効パワー
- 状態: NEUTRAL → CAPTURING → CONTROLLED

---

## 7. 国別対応

### 対応国家

| コード | 国名 | 車両カタログ |
|--------|------|-------------|
| JPN | 日本（陸上自衛隊） | vehicles_jpn.json |
| USA | アメリカ | vehicles_usa.json |
| RUS | ロシア | vehicles_rus.json |
| CHN | 中国 | vehicles_chn.json |

### 軍事シンボル

NATOミルシム標準に準拠したSVGシンボル:
- ファイル形式: `{type}_{faction}_{state}.svg`
- Faction: friendly / hostile / unknown
- State: conf / sus

---

## 8. テスト構成

**フレームワーク**: Gut（Godot Unit Test）

**テストカテゴリ**:
- 戦闘システム（test_combat_system.gd）
- ユニットデータ（test_element_data.gd）
- 移動システム（test_movement_system.gd）
- 視界システム（test_vision_system.gd）
- AIシステム（test_company_controller_ai.gd）
- リスク評価（test_risk_assessment.gd）
- 拠点制圧（test_capture_system.gd）
- 戦車戦（test_tank_vs_tank.gd）

**テスト数**: 60+ファイル

---

## 9. 開発状況

### 実装完了

- [x] 10Hz固定タイムステップゲームループ
- [x] 直射戦闘システム
- [x] 視界・索敵システム
- [x] 中隊AIと戦術テンプレート
- [x] リスク評価エンジン
- [x] 拠点制圧システム
- [x] IFV/APC輸送システム
- [x] SOP（射撃管制）システム
- [x] パイメニューUI
- [x] 武器選択アルゴリズム（目標タイプ別）
- [x] 4ゾーン装甲モデル

### 開発中/未実装

| 優先度 | 項目 |
|--------|------|
| 高 | LAW貫徹力バランス調整 |
| 高 | サブシステムダメージHUD表示 |
| 高 | Catastrophic Kill実装 |
| 中 | 間接射撃（迫撃砲） |
| 中 | 煙幕システム |
| 中 | 弾薬管理システム |
| 低 | 勝利条件実装 |
| 低 | セーブ/ロード機能 |

---

## 10. 関連ドキュメント

詳細仕様は以下を参照:

| カテゴリ | ドキュメント |
|----------|-------------|
| ゲーム全体 | [spec_v0.1.md](spec_v0.1.md) |
| ルールセット | [ruleset_v0.1.md](ruleset_v0.1.md) |
| 戦闘システム | [combat_v0.1.md](combat_v0.1.md), [damage_model_v0.1.md](damage_model_v0.1.md) |
| 視界システム | [vision_v0.1.md](vision_v0.1.md) |
| 中隊AI | [company_ai_v0.1.md](company_ai_v0.1.md) |
| 拠点制圧 | [capture_v0.1.md](capture_v0.1.md) |
| UI/入力 | [ui_design_v0.1.md](ui_design_v0.1.md), [pie_menu_commands_v0.2.md](pie_menu_commands_v0.2.md) |

---

*最終更新: 2026-02-24*
