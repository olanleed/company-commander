# リファクタリング計画書 v1.0

## 概要

Company Commander のコードベースをデザインパターンとオブジェクト指向の原則に基づいて改善する計画書。
段階的に実施し、各フェーズで動作するテストを維持しながら進める。

**作成日**: 2026-02-28
**対象バージョン**: v0.1（弾薬システム実装完了時点）
**テスト数**: 714件

---

## 目次

1. [現状分析](#現状分析)
2. [問題点の詳細](#問題点の詳細)
3. [改善方針](#改善方針)
4. [フェーズ1: コンポーネント分離](#フェーズ1-コンポーネント分離)
5. [フェーズ2: イベント駆動への移行](#フェーズ2-イベント駆動への移行)
6. [フェーズ3: システム依存の整理](#フェーズ3-システム依存の整理)
7. [フェーズ4: UIリアクティブ化](#フェーズ4-uiリアクティブ化)
8. [フェーズ5: コマンドパターン導入](#フェーズ5-コマンドパターン導入)
9. [成功指標](#成功指標)
10. [リスクと対策](#リスクと対策)
11. [付録: 現状ファイル一覧](#付録-現状ファイル一覧)

---

## 現状分析

### ディレクトリ構造

```
scripts/
├── core/                    # シミュレーションエンジン (4ファイル)
│   ├── sim_runner.gd        # 10Hz固定タイムステップ駆動
│   ├── world_model.gd       # エンティティレジストリ
│   ├── game_enums.gd        # グローバルenum定義
│   └── game_constants.gd    # グローバル定数
│
├── data/                    # データモデル (9ファイル)
│   ├── element_data.gd      # ElementType + ElementInstance (523行)
│   ├── element_factory.gd   # ユニット生成ファクトリ
│   ├── weapon_data.gd       # 武器仕様
│   ├── missile_data.gd      # ミサイル仕様
│   ├── ammunition_data.gd   # 弾薬貫通力データ
│   ├── protection_data.gd   # ERA/APS設定
│   ├── ammo_state.gd        # 弾薬状態 (434行)
│   ├── vehicle_catalog.gd   # 車両カタログ
│   └── map_data.gd          # 地形・拠点データ
│
├── systems/                 # ゲームシステム (12ファイル)
│   ├── combat_system.gd     # 戦闘計算
│   ├── movement_system.gd   # 移動・経路追従
│   ├── missile_system.gd    # ATGM誘導・飛翔
│   ├── vision_system.gd     # 視認・接触追跡
│   ├── capture_system.gd    # 拠点占領
│   ├── resupply_system.gd   # 補給システム
│   ├── transport_system.gd  # 乗車・降車
│   ├── data_link_system.gd  # 通信リンク
│   ├── navigation_manager.gd# 経路探索
│   ├── symbol_manager.gd    # シンボルキャッシュ
│   ├── map_loader.gd        # マップ読み込み
│   └── annihilation_mode.gd # 殲滅モード
│
└── ui/                      # ユーザーインターフェース (12ファイル)
    ├── hud_manager.gd       # HUD統括
    ├── top_panel.gd         # 上部パネル
    ├── left_panel.gd        # 左パネル（ユニット一覧）
    ├── right_panel.gd       # 右パネル（詳細表示）
    ├── bottom_bar.gd        # 下部コマンドバー
    ├── minimap.gd           # ミニマップ
    ├── pie_menu.gd          # 放射状メニュー
    ├── input_controller.gd  # 入力制御
    ├── combat_visualizer.gd # 戦闘エフェクト
    ├── tactical_overlay.gd  # 戦術オーバーレイ
    ├── order_preview.gd     # 命令プレビュー
    └── game_result_screen.gd# 結果画面
```

### 依存関係図

```
┌─────────────────────────────────────────────────────────────┐
│                         CORE                                 │
│  SimRunner ─────→ WorldModel ←───── GameEnums, Constants    │
└──────────────────────────┬──────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ↓                 ↓                 ↓
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   SYSTEMS   │    │    DATA     │    │     UI      │
│ CombatSystem│←───│ElementData  │───→│ HUDManager  │
│ MoveSystem  │    │ AmmoState   │    │ RightPanel  │
│ MissileSystem←──→│ WeaponData  │    │ LeftPanel   │
│ VisionSystem│    │ MapData     │    │ Minimap     │
└─────────────┘    └─────────────┘    └─────────────┘
      │                   │
      └───────┬───────────┘
              ↓
    ┌─────────────────────┐
    │ 問題: 双方向依存     │
    │ MoveSystem ↔ Missile│
    │ Combat ↔ AmmoState  │
    └─────────────────────┘
```

---

## 問題点の詳細

### 1. ElementInstance の肥大化（God Object）

**場所**: `scripts/data/element_data.gd:118-219`

**現状のフィールド数**: **48フィールド**

| カテゴリ | フィールド数 | フィールド例 |
|----------|-------------|-------------|
| 基本情報 | 4 | id, element_type, faction, company_id |
| 位置・移動 | 11 | position, facing, velocity, prev_position, current_path, is_moving, ... |
| 戦闘状態 | 13 | current_strength, suppression, weapons, current_target_id, sop_mode, ... |
| 車両サブシステム | 3 | mobility_hp, firepower_hp, sensors_hp |
| 破壊関連 | 3 | is_destroyed, destroy_tick, catastrophic_kill |
| 通信状態 | 2 | comm_state, comm_hub_id |
| 弾薬・補給 | 3 | ammo_state, supply_config, supply_remaining |
| 輸送関連 | 6 | embarked_infantry_id, transport_vehicle_id, is_embarked, ... |
| 砲兵展開 | 5 | artillery_deploy_state, artillery_deploy_progress, ... |

**違反原則**: Single Responsibility Principle (SRP)

```gdscript
# 現状: ElementInstanceに全ての状態が混在（48フィールド）
class ElementInstance:
    # 位置系
    var position: Vector2
    var facing: float
    var velocity: Vector2
    var prev_position: Vector2
    var prev_facing: float
    var current_path: PackedVector2Array
    var path_index: int
    var is_moving: bool
    var use_road_only: bool
    var is_reversing: bool
    var break_contact_smoke_requested: bool

    # 戦闘系
    var current_strength: int
    var suppression: float
    var weapons: Array[WeaponData.WeaponType]
    var current_weapon: WeaponData.WeaponType
    var current_target_id: String
    var forced_target_id: String
    var atgm_guided_target_id: String
    var last_fire_tick: int
    var last_hit_tick: int
    var sop_mode: GameEnums.SOPMode
    var accumulated_damage: float
    var accumulated_armor_damage: float
    # ... 他36フィールド
```

### 2. 直接フィールド変更パターン

**影響箇所**: 全システム

**問題**:
- システムがElementInstanceのフィールドを直接変更
- 変更の監査証跡がない
- UIがポーリングで変更を検出する必要がある
- デバッグ・リプレイが困難

**違反原則**: Tell, Don't Ask / Information Expert

```gdscript
# CombatSystemでの直接変更例
element.current_strength -= damage
element.suppression = clamp(element.suppression + supp_delta, 0.0, 100.0)
element.accumulated_damage += residual_damage
element.last_hit_tick = current_tick

# VisionSystemでの直接変更例
element.contact_state = GameEnums.ContactState.CONFIRMED
element.last_seen_tick = current_tick
element.last_known_position = element.position

# ResupplySystemでの直接変更例
slot.count_stowed += 1
element.ammo_state.last_combat_tick = current_tick
```

### 3. システム間の双方向依存

**場所**:
- `scripts/systems/movement_system.gd`
- `scripts/systems/missile_system.gd`
- `scripts/systems/combat_system.gd`

**依存関係**:
```
MovementSystem ──────→ MissileSystem (SACLOS制約チェック)
                  ↑
MissileSystem ────┴──→ CombatSystem (ダメージ計算)
                  ↑
CombatSystem ─────────→ AmmoState (弾薬消費)
```

**問題**:
- MovementSystemがMissileSystemを直接参照
- テスト時にモックが困難
- 責務の境界が不明確

**違反原則**: Dependency Inversion Principle (DIP)

```gdscript
# MovementSystem内のMissileSystem直接参照
func _is_shooter_constrained(shooter_id: String) -> bool:
    # MissileSystemへの直接依存
    return missile_system.is_shooter_constrained(shooter_id)

func _can_move(element) -> bool:
    # SACLOS制約をMovementSystemが知りすぎている
    if _is_shooter_constrained(element.id):
        return false
```

### 4. UIポーリングパターン

**場所**: `scripts/ui/` 全般

**問題コード例**:
```gdscript
# RightPanel._process() - 毎フレーム更新
func _process(_delta: float) -> void:
    # 60FPSで毎フレーム呼ばれる（非効率）
    if _selected_elements.size() > 0:
        # 状態が変わっていなくても全UI更新
        _update_strength_bar()
        _update_suppression_bar()
        _update_ammo_display()
```

**問題**:
- 60FPSで不要な更新処理
- WorldModelのシグナルを活用していない
- バッテリー消費、CPU負荷

**違反原則**: Observer Pattern の不使用

### 5. 選択状態の重複管理

**場所**:
- `scripts/ui/hud_manager.gd` - `_selected_elements: Array`
- `scripts/ui/left_panel.gd` - `_highlighted_ids: Array`
- `scripts/ui/right_panel.gd` - `_selected_elements: Array`（パラメータ受け取り）

**問題**:
- 3箇所で選択状態を管理
- 同期漏れの可能性
- 選択変更時に3箇所を更新する必要

**違反原則**: Single Source of Truth

### 6. 武器タイプ判定の文字列依存

**場所**: `scripts/ui/right_panel.gd:843-852`

```gdscript
# 現状: 武器IDの文字列パターンマッチング
func _element_has_gun_weapon(element: ElementData.ElementInstance) -> bool:
    for weapon in element.weapons:
        if weapon.id.contains("TANK") or weapon.id.contains("AUTOCANNON"):
            return true
        if weapon.id.contains("30MM") or weapon.id.contains("35MM"):
            return true
        if weapon.id.contains("120MM") or weapon.id.contains("105MM"):
            return true
    return false
```

**問題**:
- マジック文字列によるタイプ判定
- 新武器追加時に修正漏れリスク
- 武器データに`weapon_category`フィールドがあるべき

**違反原則**: Open/Closed Principle (OCP)

---

## 改善方針

### SOLID原則の適用

| 原則 | 適用方法 |
|------|----------|
| **SRP** | ElementInstanceをコンポーネントに分割 |
| **OCP** | 武器カテゴリをenumで定義、拡張可能に |
| **LSP** | インターフェースによる抽象化 |
| **ISP** | 必要なメソッドのみを持つ小さなインターフェース |
| **DIP** | システム間依存を抽象化、Coordinator導入 |

### デザインパターン適用マップ

| 問題 | 適用パターン | 効果 |
|------|-------------|------|
| ElementInstance肥大化 | **Componentパターン** | 責務分離、テスト容易化 |
| 直接フィールド変更 | **Observer/Signalパターン** | 変更追跡、リアクティブUI |
| システム間依存 | **Mediator/Coordinatorパターン** | 疎結合、テスト容易化 |
| UIポーリング | **Reactive/Observerパターン** | 効率化、即時反映 |
| 選択状態重複 | **Single Source of Truth** | 一貫性、同期不要 |
| 文字列判定 | **Strategyパターン** | 型安全、拡張容易 |
| 命令処理 | **Commandパターン** | Undo/Redo、リプレイ |

---

## フェーズ1: コンポーネント分離

### 目標
ElementInstanceを責務ごとのコンポーネントに分割し、SRPを達成する。

### タスク分解

#### 1.1 コンポーネントクラス作成

**新規ディレクトリ**: `scripts/components/`

| ファイル | 責務 | 元フィールド数 |
|----------|------|--------------|
| `position_component.gd` | 位置・向き・速度 | 5 |
| `movement_component.gd` | パス・移動状態・命令 | 6 |
| `combat_component.gd` | 戦力・抑圧・ダメージ蓄積 | 6 |
| `weapon_component.gd` | 武器リスト・射撃状態 | 7 |
| `vision_component.gd` | 視認状態・接触記録 | 3 |
| `comms_component.gd` | 通信状態・データリンク | 2 |
| `transport_component.gd` | 搭乗・降車状態 | 6 |
| `artillery_component.gd` | 砲兵展開状態 | 5 |
| `subsystem_component.gd` | 車両サブシステムHP | 3 |

#### 1.2 PositionComponent 詳細設計

```gdscript
# scripts/components/position_component.gd
class_name PositionComponent
extends RefCounted

## シグナル: 位置変更を通知
signal position_changed(old_pos: Vector2, new_pos: Vector2)
signal facing_changed(old_facing: float, new_facing: float)
signal velocity_changed(old_vel: Vector2, new_vel: Vector2)

## 内部状態（直接アクセス禁止）
var _position: Vector2 = Vector2.ZERO
var _prev_position: Vector2 = Vector2.ZERO
var _facing: float = 0.0
var _prev_facing: float = 0.0
var _velocity: Vector2 = Vector2.ZERO

## プロパティアクセサ（シグナル発火付き）
var position: Vector2:
    get: return _position
    set(value):
        if _position != value:
            var old = _position
            _position = value
            position_changed.emit(old, value)

var facing: float:
    get: return _facing
    set(value):
        if not is_equal_approx(_facing, value):
            var old = _facing
            _facing = value
            facing_changed.emit(old, value)

var velocity: Vector2:
    get: return _velocity
    set(value):
        if _velocity != value:
            var old = _velocity
            _velocity = value
            velocity_changed.emit(old, value)

## 前tick状態を保存（補間用）
func save_prev_state() -> void:
    _prev_position = _position
    _prev_facing = _facing

## 補間位置を取得
func get_interpolated_position(alpha: float) -> Vector2:
    return _prev_position.lerp(_position, alpha)

## 補間角度を取得
func get_interpolated_facing(alpha: float) -> float:
    return lerp_angle(_prev_facing, _facing, alpha)
```

#### 1.3 CombatComponent 詳細設計

```gdscript
# scripts/components/combat_component.gd
class_name CombatComponent
extends RefCounted

## シグナル
signal strength_changed(element_id: String, old_value: int, new_value: int)
signal suppression_changed(element_id: String, old_value: float, new_value: float)
signal unit_destroyed(element_id: String, catastrophic: bool)
signal damage_accumulated(element_id: String, damage: float, total: float)

## 参照
var _element_id: String

## 状態
var _max_strength: int = 100
var _current_strength: int = 100
var _suppression: float = 0.0
var _accumulated_damage: float = 0.0
var _accumulated_armor_damage: float = 0.0
var _is_destroyed: bool = false
var _catastrophic_kill: bool = false
var _destroy_tick: int = -1

## 読み取り専用プロパティ
var current_strength: int:
    get: return _current_strength

var max_strength: int:
    get: return _max_strength

var suppression: float:
    get: return _suppression

var is_destroyed: bool:
    get: return _is_destroyed

var catastrophic_kill: bool:
    get: return _catastrophic_kill

func _init(element_id: String, max_str: int) -> void:
    _element_id = element_id
    _max_strength = max_str
    _current_strength = max_str

## ダメージ適用（外部から呼び出し）
func apply_damage(damage: int, is_catastrophic: bool = false) -> void:
    var old = _current_strength
    _current_strength = maxi(0, _current_strength - damage)

    if old != _current_strength:
        strength_changed.emit(_element_id, old, _current_strength)

    if _current_strength <= 0 and not _is_destroyed:
        _is_destroyed = true
        _catastrophic_kill = is_catastrophic
        unit_destroyed.emit(_element_id, is_catastrophic)

## 抑圧適用
func apply_suppression(delta: float) -> void:
    var old = _suppression
    _suppression = clampf(_suppression + delta, 0.0, 100.0)

    if absf(old - _suppression) > 0.01:
        suppression_changed.emit(_element_id, old, _suppression)

## 抑圧回復（毎tick呼び出し）
func recover_suppression(rate: float) -> void:
    if _suppression > 0:
        apply_suppression(-rate)

## ダメージ蓄積（浮動小数点ダメージ用）
func accumulate_damage(damage: float) -> int:
    _accumulated_damage += damage
    damage_accumulated.emit(_element_id, damage, _accumulated_damage)

    var applied := 0
    while _accumulated_damage >= 1.0:
        _accumulated_damage -= 1.0
        applied += 1

    if applied > 0:
        apply_damage(applied)

    return applied
```

#### 1.4 MovementComponent 詳細設計

```gdscript
# scripts/components/movement_component.gd
class_name MovementComponent
extends RefCounted

## シグナル
signal movement_started(element_id: String, destination: Vector2)
signal movement_completed(element_id: String)
signal path_changed(element_id: String, new_path: PackedVector2Array)
signal order_changed(element_id: String, order_type: GameEnums.OrderType)

## 参照
var _element_id: String

## 状態
var _current_path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _is_moving: bool = false
var _use_road_only: bool = false
var _is_reversing: bool = false
var _break_contact_smoke_requested: bool = false

## 命令
var _current_order_type: GameEnums.OrderType = GameEnums.OrderType.HOLD
var _order_target_position: Vector2 = Vector2.ZERO
var _order_target_id: String = ""
var _pending_move_order: Dictionary = {}

## 読み取り専用プロパティ
var is_moving: bool:
    get: return _is_moving

var current_path: PackedVector2Array:
    get: return _current_path

var current_order_type: GameEnums.OrderType:
    get: return _current_order_type

func _init(element_id: String) -> void:
    _element_id = element_id

## 移動開始
func start_movement(path: PackedVector2Array, use_road: bool = false) -> void:
    _current_path = path
    _path_index = 0
    _is_moving = true
    _use_road_only = use_road

    path_changed.emit(_element_id, path)
    if path.size() > 0:
        movement_started.emit(_element_id, path[path.size() - 1])

## 移動停止
func stop_movement() -> void:
    if _is_moving:
        _is_moving = false
        _current_path = PackedVector2Array()
        _path_index = 0
        movement_completed.emit(_element_id)

## 命令設定
func set_order(order_type: GameEnums.OrderType, target_pos: Vector2 = Vector2.ZERO, target_id: String = "") -> void:
    _current_order_type = order_type
    _order_target_position = target_pos
    _order_target_id = target_id
    order_changed.emit(_element_id, order_type)

## 次のウェイポイント取得
func get_next_waypoint() -> Vector2:
    if _path_index < _current_path.size():
        return _current_path[_path_index]
    return Vector2.ZERO

## ウェイポイント進行
func advance_waypoint() -> bool:
    _path_index += 1
    return _path_index < _current_path.size()
```

#### 1.5 ElementInstance 変更後の構造

```gdscript
# scripts/data/element_data.gd (変更後)
class ElementInstance:
    ## 識別
    var id: String = ""
    var element_type: ElementType
    var faction: GameEnums.Faction = GameEnums.Faction.NONE
    var company_id: String = ""
    var vehicle_id: String = ""

    ## コンポーネント参照（責務分離）
    var position_comp: PositionComponent
    var movement_comp: MovementComponent
    var combat_comp: CombatComponent
    var weapon_comp: WeaponComponent
    var vision_comp: VisionComponent
    var comms_comp: CommsComponent
    var transport_comp: TransportComponent  # nullable
    var artillery_comp: ArtilleryComponent  # nullable
    var subsystem_comp: SubsystemComponent  # nullable (装甲車両のみ)

    ## 弾薬・補給（既存）
    var ammo_state = null
    var supply_config: Dictionary = {}
    var supply_remaining: int = 0

    func _init(p_type: ElementType = null) -> void:
        if p_type:
            element_type = p_type
            _init_components()

    func _init_components() -> void:
        position_comp = PositionComponent.new()
        movement_comp = MovementComponent.new(id)
        combat_comp = CombatComponent.new(id, element_type.max_strength)
        weapon_comp = WeaponComponent.new(id)
        vision_comp = VisionComponent.new(id)
        comms_comp = CommsComponent.new(id)

        # 輸送能力があれば
        if element_type.can_transport_infantry:
            transport_comp = TransportComponent.new(id, element_type.transport_capacity)

        # 装甲車両であれば
        if element_type.armor_class >= 1:
            subsystem_comp = SubsystemComponent.new(id)

    ## 後方互換プロパティ（段階的移行用）
    var position: Vector2:
        get: return position_comp.position if position_comp else Vector2.ZERO
        set(value):
            if position_comp:
                position_comp.position = value

    var current_strength: int:
        get: return combat_comp.current_strength if combat_comp else 0

    var is_moving: bool:
        get: return movement_comp.is_moving if movement_comp else false
```

#### 1.6 修正が必要なファイル一覧

| ファイル | 変更内容 | 優先度 |
|----------|----------|--------|
| `scripts/data/element_data.gd` | コンポーネント参照追加 | 高 |
| `scripts/data/element_factory.gd` | コンポーネント初期化 | 高 |
| `scripts/systems/combat_system.gd` | `combat_comp.apply_damage()` 使用 | 高 |
| `scripts/systems/movement_system.gd` | `position_comp`, `movement_comp` 使用 | 高 |
| `scripts/systems/vision_system.gd` | `vision_comp` 使用 | 中 |
| `scripts/systems/missile_system.gd` | `weapon_comp` 使用 | 中 |
| `scripts/systems/transport_system.gd` | `transport_comp` 使用 | 低 |
| `scripts/ui/right_panel.gd` | コンポーネント経由でアクセス | 中 |

#### 1.7 テスト計画

```gdscript
# tests/test_position_component.gd
extends GutTest

func test_position_change_emits_signal():
    var comp = PositionComponent.new()
    var signal_received = false
    var old_pos: Vector2
    var new_pos: Vector2

    comp.position_changed.connect(func(old, new):
        signal_received = true
        old_pos = old
        new_pos = new
    )

    comp.position = Vector2(100, 200)

    assert_true(signal_received, "Signal should be emitted")
    assert_eq(old_pos, Vector2.ZERO, "Old position should be ZERO")
    assert_eq(new_pos, Vector2(100, 200), "New position should be (100, 200)")


func test_same_position_does_not_emit_signal():
    var comp = PositionComponent.new()
    comp.position = Vector2(50, 50)

    var signal_count = 0
    comp.position_changed.connect(func(_old, _new): signal_count += 1)

    comp.position = Vector2(50, 50)  # 同じ値

    assert_eq(signal_count, 0, "Signal should not be emitted for same value")


func test_interpolation():
    var comp = PositionComponent.new()
    comp.position = Vector2(0, 0)
    comp.save_prev_state()
    comp.position = Vector2(100, 100)

    var mid = comp.get_interpolated_position(0.5)

    assert_eq(mid, Vector2(50, 50), "Midpoint should be (50, 50)")
```

```gdscript
# tests/test_combat_component.gd
extends GutTest

func test_apply_damage_emits_signal():
    var comp = CombatComponent.new("test_unit", 100)
    var events: Array = []

    comp.strength_changed.connect(func(id, old, new):
        events.append({"id": id, "old": old, "new": new})
    )

    comp.apply_damage(30)

    assert_eq(events.size(), 1)
    assert_eq(events[0].old, 100)
    assert_eq(events[0].new, 70)
    assert_eq(comp.current_strength, 70)


func test_destruction_signal():
    var comp = CombatComponent.new("test_unit", 10)
    var destroyed = false
    var was_catastrophic = false

    comp.unit_destroyed.connect(func(id, catastrophic):
        destroyed = true
        was_catastrophic = catastrophic
    )

    comp.apply_damage(15, true)

    assert_true(destroyed)
    assert_true(was_catastrophic)
    assert_true(comp.is_destroyed)


func test_suppression_clamped():
    var comp = CombatComponent.new("test_unit", 100)

    comp.apply_suppression(150.0)  # 100を超える

    assert_eq(comp.suppression, 100.0, "Suppression should be clamped to 100")

    comp.apply_suppression(-200.0)  # 0を下回る

    assert_eq(comp.suppression, 0.0, "Suppression should be clamped to 0")
```

#### 1.8 完了条件

- [ ] 8コンポーネントクラス作成
- [ ] ElementInstanceをコンポーネント参照に変更
- [ ] 後方互換プロパティ実装（移行期間用）
- [ ] ElementFactoryでコンポーネント初期化
- [ ] 全システムをコンポーネント経由に変更
- [ ] 既存テスト714件がパス
- [ ] 新規コンポーネントテスト40件以上作成

---

## フェーズ2: イベント駆動への移行

### 目標
状態変更を直接変更からシグナル通知に移行し、監査証跡とリアクティブUIを実現。

### 2.1 イベントシステム設計

```gdscript
# scripts/events/game_events.gd
class_name GameEvents
extends RefCounted

## 戦闘イベント
signal damage_applied(event: DamageEvent)
signal suppression_applied(event: SuppressionEvent)
signal unit_destroyed(event: DestroyedEvent)

## 移動イベント
signal movement_started(element_id: String, destination: Vector2)
signal movement_completed(element_id: String)
signal order_issued(event: OrderEvent)

## 視認イベント
signal contact_established(observer_id: String, target_id: String, state: GameEnums.ContactState)
signal contact_lost(observer_id: String, target_id: String)
signal contact_updated(observer_id: String, target_id: String, new_state: GameEnums.ContactState)

## 弾薬イベント
signal ammunition_consumed(element_id: String, weapon_id: String, count: int)
signal reload_started(element_id: String, weapon_id: String)
signal reload_completed(element_id: String, weapon_id: String)
signal ammo_depleted(element_id: String, weapon_id: String)

## 補給イベント
signal resupply_received(element_id: String, supply_unit_id: String, amount: int)
signal resupply_completed(element_id: String)

## ミサイルイベント
signal missile_launched(event: MissileLaunchEvent)
signal missile_impact(event: MissileImpactEvent)
signal wire_cut(element_id: String, missile_id: String)

## 拠点イベント
signal capture_point_contested(cp_id: String, attacker_faction: GameEnums.Faction)
signal capture_point_captured(cp_id: String, new_owner: GameEnums.Faction)

## イベント履歴（デバッグ/リプレイ用）
var _event_log: Array[Dictionary] = []
var _max_log_size: int = 1000
var _current_tick: int = 0

func set_tick(tick: int) -> void:
    _current_tick = tick

func log_event(event_type: String, data: Dictionary) -> void:
    _event_log.append({
        "tick": _current_tick,
        "type": event_type,
        "data": data,
        "timestamp": Time.get_ticks_msec()
    })
    if _event_log.size() > _max_log_size:
        _event_log.pop_front()

func get_recent_events(count: int = 100) -> Array[Dictionary]:
    var start = maxi(0, _event_log.size() - count)
    return _event_log.slice(start)

func get_events_for_element(element_id: String, count: int = 50) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for i in range(_event_log.size() - 1, -1, -1):
        var event = _event_log[i]
        if event.data.get("element_id") == element_id or \
           event.data.get("target_id") == element_id or \
           event.data.get("shooter_id") == element_id:
            result.append(event)
            if result.size() >= count:
                break
    result.reverse()
    return result
```

### 2.2 イベントクラス

```gdscript
# scripts/events/damage_event.gd
class_name DamageEvent
extends RefCounted

var tick: int
var target_id: String
var shooter_id: String
var weapon_id: String
var damage: int
var penetration_result: String  # "FULL_PEN", "PARTIAL_PEN", "NO_PEN", "RICOCHET"
var hit_zone: String  # "FRONT", "SIDE", "REAR", "TOP"
var armor_damage: float  # 装甲ダメージ蓄積値
var subsystem_hit: String  # "MOBILITY", "FIREPOWER", "SENSORS", "NONE"

func to_dict() -> Dictionary:
    return {
        "tick": tick,
        "target_id": target_id,
        "shooter_id": shooter_id,
        "weapon_id": weapon_id,
        "damage": damage,
        "penetration_result": penetration_result,
        "hit_zone": hit_zone,
        "armor_damage": armor_damage,
        "subsystem_hit": subsystem_hit
    }

static func from_dict(data: Dictionary) -> DamageEvent:
    var event = DamageEvent.new()
    event.tick = data.get("tick", 0)
    event.target_id = data.get("target_id", "")
    event.shooter_id = data.get("shooter_id", "")
    event.weapon_id = data.get("weapon_id", "")
    event.damage = data.get("damage", 0)
    event.penetration_result = data.get("penetration_result", "")
    event.hit_zone = data.get("hit_zone", "")
    event.armor_damage = data.get("armor_damage", 0.0)
    event.subsystem_hit = data.get("subsystem_hit", "NONE")
    return event
```

```gdscript
# scripts/events/missile_launch_event.gd
class_name MissileLaunchEvent
extends RefCounted

var tick: int
var missile_id: String
var shooter_id: String
var target_id: String
var weapon_id: String
var launch_position: Vector2
var target_position: Vector2
var guidance_type: String  # "SACLOS", "FIRE_AND_FORGET", "TOP_ATTACK"

func to_dict() -> Dictionary:
    return {
        "tick": tick,
        "missile_id": missile_id,
        "shooter_id": shooter_id,
        "target_id": target_id,
        "weapon_id": weapon_id,
        "launch_position": {"x": launch_position.x, "y": launch_position.y},
        "target_position": {"x": target_position.x, "y": target_position.y},
        "guidance_type": guidance_type
    }
```

### 2.3 システム変更例

```gdscript
# scripts/systems/combat_system.gd (変更後)
class CombatSystem:
    var _world_model: WorldModel
    var _game_events: GameEvents

    func _init(world_model: WorldModel, game_events: GameEvents) -> void:
        _world_model = world_model
        _game_events = game_events

    func apply_damage(target: ElementData.ElementInstance, damage: int,
                      shooter_id: String, weapon_id: String,
                      hit_zone: String, pen_result: String) -> void:
        # コンポーネント経由で変更（内部でシグナル発火）
        target.combat_comp.apply_damage(damage)

        # グローバルイベント作成・発火
        var event = DamageEvent.new()
        event.tick = _game_events._current_tick
        event.target_id = target.id
        event.shooter_id = shooter_id
        event.weapon_id = weapon_id
        event.damage = damage
        event.hit_zone = hit_zone
        event.penetration_result = pen_result

        _game_events.damage_applied.emit(event)
        _game_events.log_event("DAMAGE", event.to_dict())
```

### 2.4 完了条件

- [ ] GameEventsクラス作成
- [ ] 全イベントクラス作成（8種類以上）
- [ ] CombatSystemのイベント発火実装
- [ ] MissileSystemのイベント発火実装
- [ ] VisionSystemのイベント発火実装
- [ ] イベントログ機能実装
- [ ] デバッグUI（イベント履歴表示）
- [ ] 既存テスト714件がパス

---

## フェーズ3: システム依存の整理

### 目標
システム間の依存をMediatorパターンで整理し、テスタビリティを向上。

### 3.1 SystemCoordinator 設計

```gdscript
# scripts/core/system_coordinator.gd
class_name SystemCoordinator
extends RefCounted

## システム参照
var combat_system: CombatSystem
var movement_system: MovementSystem
var missile_system: MissileSystem
var vision_system: VisionSystem
var capture_system: CaptureSystem
var resupply_system: ResupplySystem
var transport_system: TransportSystem
var data_link_system: DataLinkSystem

## 共有依存
var world_model: WorldModel
var map_data: MapData
var game_events: GameEvents
var navigation_manager: NavigationManager

## 初期化
func _init(p_world_model: WorldModel, p_map_data: MapData) -> void:
    world_model = p_world_model
    map_data = p_map_data
    game_events = GameEvents.new()

func setup_systems(nav_manager: NavigationManager) -> void:
    navigation_manager = nav_manager

    # 依存関係を考慮した初期化順序
    # 1. 依存のないシステム
    data_link_system = DataLinkSystem.new(world_model, game_events)
    capture_system = CaptureSystem.new(world_model, map_data, game_events)
    resupply_system = ResupplySystem.new(game_events)

    # 2. 視認システム（データリンクに依存）
    vision_system = VisionSystem.new(world_model, map_data, data_link_system, game_events)

    # 3. 戦闘システム
    combat_system = CombatSystem.new(world_model, game_events)

    # 4. ミサイルシステム（戦闘システムに依存）
    missile_system = MissileSystem.new(world_model, combat_system, game_events)

    # 5. 移動システム（制約チェッカーを注入）
    movement_system = MovementSystem.new(world_model, map_data, navigation_manager, game_events)
    movement_system.set_constraint_checker(missile_system)

    # 6. 輸送システム
    transport_system = TransportSystem.new(world_model, game_events)

func update_tick(current_tick: int) -> void:
    game_events.set_tick(current_tick)

    # 正しい順序でシステム更新
    # 1. 視認（敵位置を更新）
    vision_system.update(current_tick)

    # 2. データリンク（通信状態を更新）
    data_link_system.update(current_tick)

    # 3. 戦闘（射撃判定）
    combat_system.update(current_tick)

    # 4. ミサイル（飛翔・着弾）
    missile_system.update(current_tick)

    # 5. 移動（経路追従）
    movement_system.update(current_tick)

    # 6. 輸送（乗降処理）
    transport_system.update(current_tick)

    # 7. 拠点占領
    capture_system.update(current_tick)

    # 8. 補給
    var elements = world_model.get_all_elements()
    resupply_system.update(elements, current_tick)
    resupply_system.process_supply_unit_resupply(elements, current_tick)
```

### 3.2 制約チェッカーインターフェース

```gdscript
# scripts/interfaces/constraint_checker.gd
class_name IConstraintChecker
extends RefCounted

## 移動可能かチェック
## @param element_id: チェック対象のユニットID
## @return: 移動可能ならtrue
func can_move(element_id: String) -> bool:
    push_error("IConstraintChecker.can_move() must be overridden")
    return true

## 射撃可能かチェック
## @param element_id: チェック対象のユニットID
## @return: 射撃可能ならtrue
func can_fire(element_id: String) -> bool:
    push_error("IConstraintChecker.can_fire() must be overridden")
    return true

## 制約理由を取得
## @param element_id: チェック対象のユニットID
## @return: 制約理由（制約がなければ空文字）
func get_constraint_reason(element_id: String) -> String:
    return ""
```

```gdscript
# scripts/systems/missile_system.gd (インターフェース実装)
class_name MissileSystem
extends IConstraintChecker

var _in_flight_missiles: Dictionary = {}  # shooter_id -> missile_data

func can_move(element_id: String) -> bool:
    # SACLOS誘導中は移動不可
    return not _is_guiding_saclos_missile(element_id)

func can_fire(element_id: String) -> bool:
    # SACLOS誘導中は他の武器も使用不可
    return not _is_guiding_saclos_missile(element_id)

func get_constraint_reason(element_id: String) -> String:
    if _is_guiding_saclos_missile(element_id):
        return "SACLOS_GUIDANCE"
    return ""

func _is_guiding_saclos_missile(shooter_id: String) -> bool:
    if shooter_id not in _in_flight_missiles:
        return false
    var missile_data = _in_flight_missiles[shooter_id]
    return missile_data.guidance_type == "SACLOS"
```

### 3.3 SimRunner変更

```gdscript
# scripts/core/sim_runner.gd (変更後)
class_name SimRunner
extends RefCounted

var _system_coordinator: SystemCoordinator
var _current_tick: int = 0

func setup(world_model: WorldModel, map_data: MapData, nav_manager: NavigationManager) -> void:
    _system_coordinator = SystemCoordinator.new(world_model, map_data)
    _system_coordinator.setup_systems(nav_manager)

func advance_tick() -> void:
    _current_tick += 1
    _system_coordinator.update_tick(_current_tick)
    tick_advanced.emit(_current_tick)

## システムへのアクセス（読み取り用）
func get_game_events() -> GameEvents:
    return _system_coordinator.game_events

func get_missile_system() -> MissileSystem:
    return _system_coordinator.missile_system
```

### 3.4 完了条件

- [ ] SystemCoordinator作成
- [ ] IConstraintCheckerインターフェース作成
- [ ] MissileSystemにインターフェース実装
- [ ] MovementSystemの依存を注入に変更
- [ ] SimRunnerをSystemCoordinator経由に変更
- [ ] 全システムの初期化順序を明確化
- [ ] 既存テスト714件がパス

---

## フェーズ4: UIリアクティブ化

### 目標
UIをポーリングからシグナル購読型に変更し、効率とレスポンスを向上。

### 4.1 SelectionManager 設計

```gdscript
# scripts/ui/selection_manager.gd
class_name SelectionManager
extends RefCounted

signal selection_changed(elements: Array[ElementData.ElementInstance])
signal selection_cleared()
signal primary_selection_changed(element: ElementData.ElementInstance)

var _selected_elements: Array[ElementData.ElementInstance] = []
var _primary_selection: ElementData.ElementInstance = null
var _world_model: WorldModel

func _init(world_model: WorldModel) -> void:
    _world_model = world_model
    # ユニット破壊時に選択から除外
    _world_model.element_removed.connect(_on_element_removed)

func select(elements: Array[ElementData.ElementInstance]) -> void:
    _selected_elements = elements.duplicate()

    if elements.size() > 0:
        _primary_selection = elements[0]
    else:
        _primary_selection = null

    selection_changed.emit(_selected_elements)

func select_single(element: ElementData.ElementInstance) -> void:
    _selected_elements = [element]
    _primary_selection = element
    selection_changed.emit(_selected_elements)
    primary_selection_changed.emit(element)

func add_to_selection(element: ElementData.ElementInstance) -> void:
    if element not in _selected_elements:
        _selected_elements.append(element)
        selection_changed.emit(_selected_elements)

func remove_from_selection(element: ElementData.ElementInstance) -> void:
    var idx = _selected_elements.find(element)
    if idx >= 0:
        _selected_elements.remove_at(idx)
        if _primary_selection == element:
            _primary_selection = _selected_elements[0] if _selected_elements.size() > 0 else null
        selection_changed.emit(_selected_elements)

func clear_selection() -> void:
    _selected_elements.clear()
    _primary_selection = null
    selection_cleared.emit()

func get_selected() -> Array[ElementData.ElementInstance]:
    return _selected_elements

func get_primary() -> ElementData.ElementInstance:
    return _primary_selection

func is_selected(element: ElementData.ElementInstance) -> bool:
    return element in _selected_elements

func _on_element_removed(element_id: String) -> void:
    var filtered: Array[ElementData.ElementInstance] = []
    for e in _selected_elements:
        if e.id != element_id:
            filtered.append(e)

    if filtered.size() != _selected_elements.size():
        _selected_elements = filtered
        if _primary_selection and _primary_selection.id == element_id:
            _primary_selection = filtered[0] if filtered.size() > 0 else null
        selection_changed.emit(_selected_elements)
```

### 4.2 RightPanel リアクティブ化

```gdscript
# scripts/ui/right_panel.gd (変更後)
class_name RightPanel
extends PanelContainer

var _selection_manager: SelectionManager
var _game_events: GameEvents
var _subscribed_element_ids: Array[String] = []

func setup(selection_manager: SelectionManager, game_events: GameEvents) -> void:
    _selection_manager = selection_manager
    _game_events = game_events

    # シグナル購読
    _selection_manager.selection_changed.connect(_on_selection_changed)

    # ゲームイベント購読
    _game_events.damage_applied.connect(_on_damage_applied)
    _game_events.suppression_applied.connect(_on_suppression_applied)
    _game_events.ammunition_consumed.connect(_on_ammo_consumed)
    _game_events.reload_completed.connect(_on_reload_completed)
    _game_events.resupply_received.connect(_on_resupply_received)

func _on_selection_changed(elements: Array) -> void:
    _unsubscribe_element_signals()
    _subscribe_element_signals(elements)
    _update_display(elements)

func _subscribe_element_signals(elements: Array) -> void:
    _subscribed_element_ids.clear()
    for element in elements:
        _subscribed_element_ids.append(element.id)

        # コンポーネントシグナルを購読
        if element.combat_comp:
            element.combat_comp.strength_changed.connect(_on_element_strength_changed)
            element.combat_comp.suppression_changed.connect(_on_element_suppression_changed)

func _unsubscribe_element_signals() -> void:
    # 前回の購読を解除
    # (Godotでは自動解除されないため明示的に切断)
    _subscribed_element_ids.clear()

func _on_damage_applied(event: DamageEvent) -> void:
    if event.target_id in _subscribed_element_ids:
        _update_strength_display_for(event.target_id)

func _on_suppression_applied(event: SuppressionEvent) -> void:
    if event.element_id in _subscribed_element_ids:
        _update_suppression_display_for(event.element_id)

func _on_ammo_consumed(element_id: String, _weapon_id: String, _count: int) -> void:
    if element_id in _subscribed_element_ids:
        _update_ammo_display_for(element_id)

# _process()は不要に（ポーリング廃止）
```

### 4.3 LeftPanel リアクティブ化

```gdscript
# scripts/ui/left_panel.gd (変更後)
class_name LeftPanel
extends PanelContainer

var _world_model: WorldModel
var _selection_manager: SelectionManager
var _game_events: GameEvents

func setup(world_model: WorldModel, selection_manager: SelectionManager, game_events: GameEvents) -> void:
    _world_model = world_model
    _selection_manager = selection_manager
    _game_events = game_events

    # WorldModelシグナル購読
    _world_model.element_added.connect(_on_element_added)
    _world_model.element_removed.connect(_on_element_removed)

    # 選択シグナル購読
    _selection_manager.selection_changed.connect(_on_selection_changed)

    # ゲームイベント購読（ユニット状態変化）
    _game_events.unit_destroyed.connect(_on_unit_destroyed)

    # 初期リスト構築
    _rebuild_unit_list()

func _on_element_added(element: ElementData.ElementInstance) -> void:
    _add_unit_to_list(element)

func _on_element_removed(element_id: String) -> void:
    _remove_unit_from_list(element_id)

func _on_selection_changed(elements: Array) -> void:
    _update_highlight(elements)

func _on_unit_destroyed(event: DestroyedEvent) -> void:
    _update_unit_status(event.element_id, "DESTROYED")

# _process()は不要に
```

### 4.4 完了条件

- [ ] SelectionManager作成
- [ ] HUDManagerの選択ロジックをSelectionManagerに移行
- [ ] RightPanelをシグナル購読に変更
- [ ] LeftPanelをシグナル購読に変更
- [ ] Minimapをシグナル購読に変更
- [ ] 全UIから_process()内ポーリングを削除
- [ ] 既存テスト714件がパス

---

## フェーズ5: コマンドパターン導入

### 目標
命令をオブジェクト化し、キュー管理・取り消し・リプレイを可能に。

### 5.1 Commandベースクラス

```gdscript
# scripts/commands/command.gd
class_name Command
extends RefCounted

var _timestamp: int
var _element_ids: Array[String]
var _executed: bool = false

## 命令を実行
func execute(world_model: WorldModel) -> bool:
    push_error("Command.execute() must be overridden")
    return false

## 命令を取り消し
func undo(world_model: WorldModel) -> bool:
    push_error("Command.undo() must be overridden")
    return false

## 命令が有効かチェック
func is_valid(world_model: WorldModel) -> bool:
    for element_id in _element_ids:
        if not world_model.get_element(element_id):
            return false
    return true

## 命令の説明を取得（UI表示用）
func get_description() -> String:
    return "Unknown Command"

## シリアライズ（リプレイ用）
func to_dict() -> Dictionary:
    return {
        "type": get_class(),
        "timestamp": _timestamp,
        "element_ids": _element_ids
    }
```

### 5.2 具体的なコマンド

```gdscript
# scripts/commands/move_command.gd
class_name MoveCommand
extends Command

var _destination: Vector2
var _use_road: bool
var _previous_states: Dictionary = {}  # element_id -> {position, path, order}

func _init(element_ids: Array[String], destination: Vector2, use_road: bool = false) -> void:
    _element_ids = element_ids
    _destination = destination
    _use_road = use_road

func execute(world_model: WorldModel) -> bool:
    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        # 状態を保存（undo用）
        _previous_states[element_id] = {
            "position": element.position_comp.position,
            "path": element.movement_comp.current_path.duplicate(),
            "order_type": element.movement_comp.current_order_type,
            "order_target": element.movement_comp._order_target_position
        }

        # 移動命令を設定
        element.movement_comp.set_order(
            GameEnums.OrderType.MOVE,
            _destination
        )

    _executed = true
    return true

func undo(world_model: WorldModel) -> bool:
    if not _executed:
        return false

    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        var prev = _previous_states.get(element_id, {})
        if prev.is_empty():
            continue

        element.position_comp.position = prev.position
        element.movement_comp._current_path = prev.path
        element.movement_comp.set_order(prev.order_type, prev.order_target)
        element.movement_comp.stop_movement()

    return true

func get_description() -> String:
    return "Move to (%d, %d)" % [int(_destination.x), int(_destination.y)]

func to_dict() -> Dictionary:
    var base = super.to_dict()
    base["destination"] = {"x": _destination.x, "y": _destination.y}
    base["use_road"] = _use_road
    return base
```

```gdscript
# scripts/commands/attack_command.gd
class_name AttackCommand
extends Command

var _target_id: String
var _previous_targets: Dictionary = {}  # element_id -> previous_target_id

func _init(element_ids: Array[String], target_id: String) -> void:
    _element_ids = element_ids
    _target_id = target_id

func execute(world_model: WorldModel) -> bool:
    var target := world_model.get_element(_target_id)
    if not target:
        return false

    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        # 状態を保存
        _previous_targets[element_id] = element.weapon_comp.forced_target_id

        # 攻撃命令を設定
        element.weapon_comp.set_forced_target(_target_id)
        element.movement_comp.set_order(
            GameEnums.OrderType.ATTACK,
            target.position_comp.position,
            _target_id
        )

    _executed = true
    return true

func undo(world_model: WorldModel) -> bool:
    if not _executed:
        return false

    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        var prev_target = _previous_targets.get(element_id, "")
        element.weapon_comp.set_forced_target(prev_target)

    return true

func get_description() -> String:
    return "Attack target %s" % _target_id
```

```gdscript
# scripts/commands/halt_command.gd
class_name HaltCommand
extends Command

var _previous_states: Dictionary = {}

func _init(element_ids: Array[String]) -> void:
    _element_ids = element_ids

func execute(world_model: WorldModel) -> bool:
    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        # 状態を保存
        _previous_states[element_id] = {
            "path": element.movement_comp.current_path.duplicate(),
            "order_type": element.movement_comp.current_order_type,
            "order_target": element.movement_comp._order_target_position
        }

        # 停止
        element.movement_comp.stop_movement()
        element.movement_comp.set_order(GameEnums.OrderType.HOLD)

    _executed = true
    return true

func undo(world_model: WorldModel) -> bool:
    if not _executed:
        return false

    for element_id in _element_ids:
        var element := world_model.get_element(element_id)
        if not element:
            continue

        var prev = _previous_states.get(element_id, {})
        if prev.is_empty():
            continue

        element.movement_comp._current_path = prev.path
        element.movement_comp.set_order(prev.order_type, prev.order_target)
        if prev.path.size() > 0:
            element.movement_comp._is_moving = true

    return true

func get_description() -> String:
    return "Halt"
```

### 5.3 CommandQueue

```gdscript
# scripts/commands/command_queue.gd
class_name CommandQueue
extends RefCounted

signal command_executed(command: Command)
signal command_undone(command: Command)
signal queue_changed()

var _pending: Array[Command] = []
var _executed: Array[Command] = []
var _max_history: int = 100

func enqueue(command: Command) -> void:
    _pending.append(command)
    queue_changed.emit()

func process(world_model: WorldModel) -> int:
    var processed := 0

    while _pending.size() > 0:
        var cmd := _pending.pop_front() as Command

        if cmd.is_valid(world_model):
            if cmd.execute(world_model):
                _executed.append(cmd)
                command_executed.emit(cmd)
                processed += 1

                if _executed.size() > _max_history:
                    _executed.pop_front()

    if processed > 0:
        queue_changed.emit()

    return processed

func undo_last(world_model: WorldModel) -> bool:
    if _executed.size() == 0:
        return false

    var cmd := _executed.pop_back() as Command
    var success := cmd.undo(world_model)

    if success:
        command_undone.emit(cmd)
        queue_changed.emit()

    return success

func can_undo() -> bool:
    return _executed.size() > 0

func get_undo_description() -> String:
    if _executed.size() == 0:
        return ""
    return _executed[_executed.size() - 1].get_description()

func get_pending_count() -> int:
    return _pending.size()

func get_history() -> Array[Command]:
    return _executed

func clear_pending() -> void:
    _pending.clear()
    queue_changed.emit()

## リプレイ用: コマンド履歴をエクスポート
func export_history() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for cmd in _executed:
        result.append(cmd.to_dict())
    return result
```

### 5.4 InputController統合

```gdscript
# scripts/ui/input_controller.gd (変更後)
class_name InputController
extends Node

var _command_queue: CommandQueue
var _selection_manager: SelectionManager
var _world_model: WorldModel

func setup(command_queue: CommandQueue, selection_manager: SelectionManager, world_model: WorldModel) -> void:
    _command_queue = command_queue
    _selection_manager = selection_manager
    _world_model = world_model

func _on_move_command(destination: Vector2, use_road: bool) -> void:
    var selected := _selection_manager.get_selected()
    if selected.size() == 0:
        return

    var element_ids: Array[String] = []
    for element in selected:
        element_ids.append(element.id)

    var cmd := MoveCommand.new(element_ids, destination, use_road)
    _command_queue.enqueue(cmd)

func _on_attack_command(target_id: String) -> void:
    var selected := _selection_manager.get_selected()
    if selected.size() == 0:
        return

    var element_ids: Array[String] = []
    for element in selected:
        element_ids.append(element.id)

    var cmd := AttackCommand.new(element_ids, target_id)
    _command_queue.enqueue(cmd)

func _on_halt_command() -> void:
    var selected := _selection_manager.get_selected()
    if selected.size() == 0:
        return

    var element_ids: Array[String] = []
    for element in selected:
        element_ids.append(element.id)

    var cmd := HaltCommand.new(element_ids)
    _command_queue.enqueue(cmd)

func _input(event: InputEvent) -> void:
    # Ctrl+Z: Undo
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_Z and event.ctrl_pressed:
            _command_queue.undo_last(_world_model)
            get_viewport().set_input_as_handled()
```

### 5.5 完了条件

- [ ] Commandベースクラス作成
- [ ] MoveCommand作成
- [ ] AttackCommand作成
- [ ] HaltCommand作成
- [ ] その他コマンド作成（DefendCommand, RetreатCommand等）
- [ ] CommandQueue作成
- [ ] InputControllerからCommandQueue経由に変更
- [ ] Undo機能実装（Ctrl+Z）
- [ ] コマンド履歴UI
- [ ] 既存テスト714件がパス

---

## 成功指標

### 定量的指標

| 指標 | 現状 | 目標 |
|------|------|------|
| ElementInstanceフィールド数 | 48 | 10以下（コンポーネント参照のみ） |
| システム間直接依存数 | 6 | 2（Coordinator経由） |
| UIの_process()ポーリング箇所 | 5 | 0 |
| テスト数 | 714 | 800+ |
| コンポーネントテストカバレッジ | 0% | 80%+ |

### 定性的指標

- [ ] 新システム追加が既存コード変更なしで可能
- [ ] 各システムが独立してテスト可能
- [ ] UIがリアルタイムに状態変化を反映
- [ ] デバッグ時にイベント履歴を確認可能
- [ ] Undo/Redoが動作
- [ ] コマンドリプレイが可能

---

## リスクと対策

| リスク | 影響 | 発生確率 | 対策 |
|--------|------|----------|------|
| 既存テスト破損 | 高 | 中 | 各変更後にテスト実行、後方互換プロパティで移行期間確保 |
| パフォーマンス低下 | 中 | 低 | シグナル呼び出しオーバーヘッドを計測、必要なら最適化 |
| 移行中のバグ | 中 | 中 | フィーチャーフラグで新旧切り替え可能に |
| スコープ拡大 | 中 | 高 | フェーズごとに完了判定、追加作業は次フェーズへ |
| 学習コスト | 低 | 中 | ドキュメント整備、サンプルコード提供 |

---

## 付録: 現状ファイル一覧

### scripts/data/ (9ファイル)

| ファイル | 行数 | 責務 |
|----------|------|------|
| element_data.gd | 523 | ElementType + ElementInstance + Archetypes |
| element_factory.gd | ~400 | ユニット生成、武器装備、弾薬初期化 |
| weapon_data.gd | ~350 | 武器仕様定義 |
| missile_data.gd | ~200 | ミサイル仕様定義 |
| ammunition_data.gd | ~300 | 弾薬貫通力データ |
| protection_data.gd | ~150 | ERA/APS設定 |
| ammo_state.gd | 434 | 弾薬状態管理 |
| vehicle_catalog.gd | ~400 | 車両カタログ、modifier適用 |
| map_data.gd | ~200 | 地形・拠点データ |

### scripts/systems/ (12ファイル)

| ファイル | 行数 | 責務 |
|----------|------|------|
| combat_system.gd | ~600 | 戦闘計算、ダメージ適用 |
| movement_system.gd | ~500 | 移動、経路追従、衝突回避 |
| missile_system.gd | ~800 | ATGM誘導、SACLOS、着弾処理 |
| vision_system.gd | ~400 | 視認、接触状態管理 |
| capture_system.gd | ~200 | 拠点占領進捗 |
| resupply_system.gd | 420 | 補給、弾薬回復 |
| transport_system.gd | ~300 | 乗車・降車処理 |
| data_link_system.gd | ~200 | 通信リンク状態 |
| navigation_manager.gd | ~300 | 経路探索 |
| symbol_manager.gd | ~150 | シンボルキャッシュ |
| map_loader.gd | ~150 | マップJSON読み込み |
| annihilation_mode.gd | ~100 | 殲滅モード判定 |

### scripts/ui/ (12ファイル)

| ファイル | 行数 | 責務 |
|----------|------|------|
| hud_manager.gd | ~250 | HUD統括 |
| right_panel.gd | ~1000 | 詳細表示（Str/Sup/Order/Ammo/Supply） |
| left_panel.gd | ~300 | ユニット一覧 |
| top_panel.gd | ~200 | 時間、チケット、拠点状況 |
| bottom_bar.gd | ~200 | コマンドバー |
| minimap.gd | ~300 | ミニマップ |
| pie_menu.gd | ~200 | 放射状メニュー |
| input_controller.gd | ~500 | 入力処理 |
| combat_visualizer.gd | ~400 | 戦闘エフェクト |
| tactical_overlay.gd | ~300 | 射程表示 |
| order_preview.gd | ~200 | 命令プレビュー |
| game_result_screen.gd | ~100 | 結果画面 |

---

## 参考資料

- [Game Programming Patterns](https://gameprogrammingpatterns.com/) - Component, Observer, Command パターン
- [Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/) - シグナル、依存注入
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - 依存の方向性
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID) - オブジェクト指向設計原則
- [Refactoring.Guru](https://refactoring.guru/design-patterns) - デザインパターンカタログ
