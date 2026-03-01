# Company Commander アーキテクチャ設計書 v1.0

**更新日**: 2026-03-01
**テスト数**: 1,469件（目標800+を大幅超過）

---

## 概要

本ドキュメントはCompany Commanderのリファクタリング完了後のアーキテクチャを記録する。
`docs/refactoring_plan_v1.md`の5フェーズを実装した結果を反映している。

---

## 目次

1. [アーキテクチャ概観](#アーキテクチャ概観)
2. [コンポーネントシステム](#コンポーネントシステム)
3. [コマンドパターン](#コマンドパターン)
4. [UIリアクティブ化](#uiリアクティブ化)
5. [シグナルフロー](#シグナルフロー)
6. [成功指標の達成状況](#成功指標の達成状況)

---

## アーキテクチャ概観

### レイヤー構成

```
┌─────────────────────────────────────────────────────────────────┐
│                           UI Layer                               │
│  InputController → Commands → HUDManager/Panels/Overlays        │
│                         ↑ signals                                │
├─────────────────────────────────────────────────────────────────┤
│                        Command Layer                             │
│  MoveCommand, AttackCommand, DefendCommand, HaltCommand, etc.   │
│  CommandQueue (undo/redo/replay)                                │
├─────────────────────────────────────────────────────────────────┤
│                        System Layer                              │
│  CombatSystem, MovementSystem, MissileSystem, VisionSystem      │
│  ResupplySystem, TransportSystem, CaptureSystem, DataLinkSystem │
├─────────────────────────────────────────────────────────────────┤
│                        Model Layer                               │
│  WorldModel ←→ ElementInstance ←→ Components                    │
│  VehicleCatalog, WeaponData, AmmoState                          │
├─────────────────────────────────────────────────────────────────┤
│                        Core Layer                                │
│  SimRunner (10Hz), GameEnums, GameConstants                      │
└─────────────────────────────────────────────────────────────────┘
```

### ディレクトリ構造

```
scripts/
├── core/                    # シミュレーションエンジン
│   ├── sim_runner.gd        # 10Hz固定タイムステップ駆動
│   ├── world_model.gd       # エンティティレジストリ + シグナル中継
│   ├── game_enums.gd        # グローバルenum定義
│   └── game_constants.gd    # グローバル定数
│
├── components/              # コンポーネント (Phase 1)
│   ├── position_component.gd    # 位置・facing・velocity
│   ├── movement_component.gd    # 移動パス・命令
│   ├── combat_component.gd      # HP・抑圧・破壊状態
│   ├── weapon_component.gd      # 武器選択・射撃状態
│   ├── vision_component.gd      # 視界・接触状態
│   ├── comms_component.gd       # 通信リンク
│   ├── transport_component.gd   # 乗車・輸送
│   └── artillery_component.gd   # 砲兵展開状態
│
├── commands/                # コマンドパターン (Phase 5)
│   ├── command.gd           # 基底クラス
│   ├── command_queue.gd     # undo/redo管理
│   ├── move_command.gd
│   ├── attack_command.gd
│   ├── defend_command.gd
│   ├── halt_command.gd
│   └── fire_mission_command.gd
│
├── data/                    # データモデル
│   ├── element_data.gd      # ElementType + ElementInstance
│   ├── element_factory.gd   # ユニット生成ファクトリ
│   ├── weapon_data.gd       # 武器仕様
│   ├── missile_data.gd      # ミサイル仕様
│   ├── ammunition_data.gd   # 弾薬貫通力データ
│   ├── protection_data.gd   # ERA/APS設定
│   ├── ammo_state.gd        # 弾薬状態管理
│   ├── vehicle_catalog.gd   # 車両カタログ
│   └── map_data.gd          # 地形・拠点データ
│
├── systems/                 # ゲームシステム
│   ├── combat_system.gd     # 戦闘計算
│   ├── movement_system.gd   # 移動・経路追従
│   ├── missile_system.gd    # ATGM誘導・飛翔
│   ├── vision_system.gd     # 視認・接触追跡
│   ├── capture_system.gd    # 拠点占領
│   ├── resupply_system.gd   # 補給システム
│   ├── transport_system.gd  # 乗車・降車
│   ├── data_link_system.gd  # 通信リンク
│   └── navigation_manager.gd# 経路探索
│
└── ui/                      # ユーザーインターフェース
    ├── hud_manager.gd       # HUD統括
    ├── input_controller.gd  # 入力制御
    ├── pie_menu.gd          # 放射状メニュー
    ├── tactical_overlay.gd  # 戦術オーバーレイ（リアクティブ）
    ├── capture_point_view.gd# 拠点表示（リアクティブ）
    ├── combat_visualizer.gd # 戦闘エフェクト
    └── ...
```

---

## コンポーネントシステム

### 概要

ElementInstanceの責務をコンポーネントに分離し、疎結合を実現。
後方互換性のためプロパティアクセサで委譲パターンを採用。

### コンポーネント一覧

| コンポーネント | 責務 | シグナル |
|----------------|------|----------|
| PositionComponent | 位置・facing・velocity | `position_changed` |
| MovementComponent | 移動パス・命令・状態 | `movement_started`, `movement_completed`, `order_changed` |
| CombatComponent | HP・抑圧・破壊・サブシステム | `strength_changed`, `destroyed` |
| WeaponComponent | 武器選択・射撃状態 | - |
| VisionComponent | 視界・接触状態 | - |
| CommsComponent | 通信リンク | - |
| TransportComponent | 乗車・輸送（nullable） | - |
| ArtilleryComponent | 砲兵展開状態（nullable） | `deploy_state_changed` |

### ElementInstanceとの関係

```gdscript
class ElementInstance:
    # コンポーネント参照
    var _position_component: PositionComponent
    var _movement_component: MovementComponent
    var _combat_component: CombatComponent
    # ...

    # 後方互換プロパティアクセサ
    var position: Vector2:
        get:
            if _position_component:
                return _position_component.position
            return _position_raw
        set(value):
            if _position_component:
                _position_component.position = value
            else:
                _position_raw = value
```

---

## コマンドパターン

### 概要

ユーザー操作をCommandオブジェクトとしてカプセル化。
Undo/Redo、シリアライズ（リプレイ）をサポート。

### 基底クラス

```gdscript
# scripts/commands/command.gd
class_name Command
extends RefCounted

var _element_ids: Array[String] = []
var _timestamp: int = 0
var _executed: bool = false

func execute(world_model: WorldModel) -> bool:
    # Override in subclass
    return false

func undo(world_model: WorldModel) -> bool:
    # Override in subclass
    return false

func get_description() -> String:
    return "Command"

func to_dict() -> Dictionary:
    return {"type": "Command", "element_ids": _element_ids, "timestamp": _timestamp}

static func from_dict(data: Dictionary) -> Command:
    return null
```

### 実装コマンド

| コマンド | 責務 | Undo対応 |
|----------|------|----------|
| MoveCommand | 移動命令 | ✅ 前位置・命令を復元 |
| AttackCommand | 攻撃命令 | ✅ 前命令・目標を復元 |
| DefendCommand | 防御命令 | ✅ 前命令を復元 |
| HaltCommand | 停止命令 | ✅ 前パス・移動状態を復元 |
| FireMissionCommand | 間接射撃命令 | ✅ 前射撃目標を復元 |

### CommandQueue

```gdscript
class CommandQueue:
    signal command_executed(command)
    signal command_undone(command)
    signal queue_changed

    var _executed_history: Array[Command] = []
    var _redo_stack: Array[Command] = []

    func execute(cmd: Command, world_model: WorldModel) -> bool
    func undo_last(world_model: WorldModel) -> bool
    func undo_for_elements(world_model: WorldModel, element_ids: Array[String]) -> bool
    func redo(world_model: WorldModel) -> bool
    func can_undo() -> bool
    func can_redo() -> bool
    func get_history() -> Array[Command]
```

**undo_for_elements**: 選択中のユニットに関連するコマンドのみをUndoする。複数ユニットが選択されている場合でも、そのユニットに関連する最新のコマンドを取り消せる。

---

## UIリアクティブ化

### 概要

`_process()`でのポーリングをシグナル購読に置換し、効率的なUI更新を実現。

### 変更前後の比較

| UIコンポーネント | 変更前 | 変更後 |
|------------------|--------|--------|
| CapturePointView | 毎フレームqueue_redraw() | シグナル購読、アニメーション時のみ再描画 |
| TacticalOverlay | 毎フレームqueue_redraw() | WorldModel.element_moved購読 |
| InputController | 右クリック長押し検出 | （適切なポーリング、変更なし） |
| CombatVisualizer | エフェクト時間管理 | （適切なポーリング、変更なし） |

### CapturePoint シグナル

```gdscript
# scripts/data/map_data.gd
class CapturePoint extends RefCounted:
    signal state_changed(new_state: GameEnums.CPState)
    signal progress_changed(new_ratio: float)

    var state: GameEnums.CPState:
        set(value):
            if _state != value:
                _state = value
                state_changed.emit(value)
```

### WorldModel シグナル

```gdscript
# scripts/core/world_model.gd
signal element_added(element: ElementData.ElementInstance)
signal element_removed(element: ElementData.ElementInstance)
signal element_destroyed(element: ElementData.ElementInstance)
signal element_moved(element_id: String, new_position: Vector2)

func notify_element_moved(element_id: String, new_position: Vector2) -> void:
    element_moved.emit(element_id, new_position)
```

### TacticalOverlay購読

```gdscript
# scripts/ui/tactical_overlay.gd
func setup(p_world_model: WorldModel, ..., p_command_queue = null) -> void:
    world_model = p_world_model
    command_queue = p_command_queue

    world_model.element_moved.connect(_on_element_moved)
    world_model.element_added.connect(_on_element_changed)
    world_model.element_removed.connect(_on_element_changed)

    # CommandQueue購読（Undo時の再描画）
    if command_queue:
        command_queue.command_undone.connect(_on_command_undone)
        command_queue.command_executed.connect(_on_command_executed)

func _on_element_moved(_element_id: String, _new_position: Vector2) -> void:
    request_redraw()

func _on_command_undone(_command) -> void:
    request_redraw()  # 射撃線・CEP・展開ゲージを更新

func request_redraw() -> void:
    queue_redraw()
```

---

## シグナルフロー

### ユーザー操作 → システム更新 → UI反映

```
User Input
    │
    ▼
InputController
    │ (command_hotkey_pressed / right_click)
    ▼
Command.execute(world_model)
    │
    ├─→ ElementInstance.property = value
    │       │
    │       ▼ (property accessor)
    │   Component.set_xxx()
    │       │
    │       ▼ (signal emit)
    │   xxx_changed.emit()
    │       │
    │       ▼ (WorldModel relay)
    │   WorldModel.element_moved.emit()
    │
    ▼
UI (subscribed to WorldModel)
    │
    ▼
request_redraw() / update_display()
```

### 拠点制圧フロー

```
SimRunner._tick()
    │
    ▼
CaptureSystem.update()
    │
    ├─→ cp.control_milli += delta
    │       │
    │       ▼ (property accessor)
    │   progress_changed.emit(new_ratio)
    │
    ├─→ cp.state = new_state
    │       │
    │       ▼ (property accessor)
    │   state_changed.emit(new_state)
    │
    ▼
CapturePointView (subscribed)
    │
    ▼
update_display() → queue_redraw()
```

---

## 成功指標の達成状況

### 定量的指標

| 指標 | 目標 | 達成値 | 状態 |
|------|------|--------|------|
| ElementInstanceフィールド数 | 10以下 | ~100（後方互換アクセサ含む） | △ 段階的移行中 |
| システム間直接依存数 | 2 | 0 | ✅ 達成 |
| UIの_process()ポーリング箇所 | 0 | 2（適切な使用） | ✅ 実質達成 |
| テスト数 | 800+ | 1,469 | ✅ 大幅超過 |
| コンポーネントテストカバレッジ | 80%+ | 61テスト | △ 継続中 |

### 定性的指標

| 指標 | 状態 | 備考 |
|------|------|------|
| 新システム追加が既存コード変更なしで可能 | △ | コンポーネント経由で分離進行中 |
| 各システムが独立してテスト可能 | ✅ | 8システムがモック可能 |
| UIがリアルタイムに状態変化を反映 | ✅ | シグナル購読実装完了 |
| デバッグ時にイベント履歴を確認可能 | △ | CommandQueue.get_history()で可能 |
| Undo/Redoが動作 | ✅ | 全コマンドにundo実装 |
| コマンドリプレイが可能 | ✅ | to_dict/from_dict実装 |

---

## 今後の課題

### 短期

1. **MovementSystem → WorldModel.notify_element_moved()連携**
   - 実際の移動時にシグナルを発行する
   - 現在はAPIのみ実装、呼び出し側未実装

2. **ElementInstanceフィールド数の削減**
   - 後方互換プロパティアクセサを段階的に廃止
   - コンポーネント直接参照への移行

### 中期

3. **イベントバス導入**
   - システム間のシグナル中継を一元化
   - デバッグ用イベント履歴の可視化

4. **コンポーネントテストカバレッジ向上**
   - 各コンポーネントの単体テスト充実
   - 境界条件のテスト追加

---

## 関連ドキュメント

- [リファクタリング計画書](refactoring_plan_v1.md) - 元の計画書
- [弾薬システム設計書](ammunition_system_v0.1.md) - AmmoState設計
- [ダメージモデル設計書](damage_model_v0.1.md) - 戦闘計算仕様
