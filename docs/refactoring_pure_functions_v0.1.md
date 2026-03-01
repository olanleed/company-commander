# 純粋関数化リファクタリング計画 v0.1

**作成日**: 2026-03-01
**目的**: 重要な計算ロジックを純粋関数化し、ユニットテストで保護する

---

## 概要

現在のコードベースでは、重要な戦闘計算ロジックがインスタンスメソッドとして実装されている。
これを純粋関数（static func）に切り出し、以下のメリットを得る：

1. **テスト容易性**: インスタンス生成不要、入力→出力のみをテスト
2. **副作用の排除**: 関数が外部状態を変更しないことを保証
3. **並列化可能**: 状態を持たないため安全に並列実行可能
4. **リファクタリング安全性**: テストが仕様として機能し、変更を検出

---

## 設計原則

### 純粋関数の定義

```gdscript
# ✅ 純粋関数（推奨）
static func calculate_hit_probability(exposure: float) -> float:
    return 1.0 - exp(-GameConstants.K_HIT * exposure)

# ❌ 非純粋関数（現状）
func calculate_hit_probability(exposure: float) -> float:
    # self への暗黙的な依存がある
    return 1.0 - exp(-GameConstants.K_HIT * exposure)
```

### 純粋関数の条件

1. **決定的**: 同じ入力には常に同じ出力
2. **副作用なし**: 外部状態を読み書きしない
3. **参照透過**: 関数呼び出しを結果で置換可能

### 許容される依存

| 依存先 | 許容 | 理由 |
|--------|------|------|
| GameConstants | ✅ | イミュータブルな定数 |
| GameEnums | ✅ | 列挙型定義 |
| 引数で渡されたデータ | ✅ | 明示的な依存 |
| self のフィールド | ❌ | 暗黙的な状態依存 |
| グローバル変数 | ❌ | 非決定的 |
| 乱数生成 | ❌ | 非決定的（シード注入で許容） |

---

## リファクタリング対象

### Phase 1: CombatSystem（優先度: 高）

戦闘計算は最も重要なゲームロジック。純粋関数化の効果が最大。

#### 対象関数一覧

| 現在の関数 | 純粋関数シグネチャ | テスト数目標 |
|-----------|-------------------|-------------|
| `calculate_shooter_coefficient(shooter)` | `static func calc_shooter_coeff(suppression: float) -> float` | 5 |
| `calculate_hit_probability(exposure)` | `static func calc_hit_prob(exposure: float) -> float` | 5 |
| `calculate_exposure_df(...)` | `static func calc_exposure_df(distance: float, m_shooter: float, m_target: float, m_cover: float, wp_base_acc: float) -> float` | 8 |
| `calculate_penetration_probability(...)` | `static func calc_pen_prob(penetration: float, armor: float, angle: float) -> float` | 10 |
| `calculate_aspect(...)` | `static func calc_aspect(shooter_pos: Vector2, target_pos: Vector2, target_facing: float) -> Aspect` | 6 |
| `calculate_soft_damage(category)` | `static func calc_soft_damage(category: GameEnums.DamageCategory) -> float` | 4 |
| `get_cover_coefficient_df(terrain)` | `static func get_cover_coeff(terrain: GameEnums.TerrainType) -> float` | 6 |

#### 実装パターン

```gdscript
# scripts/systems/combat_calc.gd - 新規ファイル
class_name CombatCalc
extends RefCounted

## 純粋な戦闘計算関数群
## CombatSystemから切り出した計算ロジック


## 射手の抑圧状態に応じた係数を計算
## @param suppression 抑圧レベル (0.0-1.0)
## @return 射撃能力係数 (0.15-1.0)
static func calc_shooter_coeff(suppression: float) -> float:
    if suppression >= GameConstants.SUPP_THRESHOLD_BROKEN:
        return GameConstants.M_SHOOTER_BROKEN
    elif suppression >= GameConstants.SUPP_THRESHOLD_PINNED:
        return GameConstants.M_SHOOTER_PINNED
    elif suppression >= GameConstants.SUPP_THRESHOLD_SUPPRESSED:
        return GameConstants.M_SHOOTER_SUPPRESSED
    else:
        return GameConstants.M_SHOOTER_NORMAL


## ヒット確率を計算（離散ヒットモデル）
## @param exposure 期待危険度 E
## @return ヒット確率 (0.0-1.0)
static func calc_hit_prob(exposure: float) -> float:
    if exposure <= 0.0:
        return 0.0
    return 1.0 - exp(-GameConstants.K_HIT * exposure)


## 遮蔽係数を取得
## @param terrain 地形タイプ
## @return 遮蔽係数 (0.0-1.0、低いほど防護効果大)
static func get_cover_coeff(terrain: GameEnums.TerrainType) -> float:
    match terrain:
        GameEnums.TerrainType.OPEN:
            return 1.0
        GameEnums.TerrainType.SPARSE:
            return 0.85
        GameEnums.TerrainType.FOREST:
            return 0.50
        GameEnums.TerrainType.URBAN:
            return 0.35
        GameEnums.TerrainType.FORTIFIED:
            return 0.20
        _:
            return 1.0


## アスペクトアングルを計算
## @param shooter_pos 射手位置
## @param target_pos 目標位置
## @param target_facing 目標の向き（ラジアン）
## @return アスペクト (FRONT/SIDE/REAR)
static func calc_aspect(
    shooter_pos: Vector2,
    target_pos: Vector2,
    target_facing: float
) -> GameEnums.Aspect:
    var to_shooter := (shooter_pos - target_pos).normalized()
    var facing_vec := Vector2.from_angle(target_facing)
    var dot := facing_vec.dot(to_shooter)

    if dot >= 0.5:  # 60度以内
        return GameEnums.Aspect.FRONT
    elif dot <= -0.5:  # 120度以上
        return GameEnums.Aspect.REAR
    else:
        return GameEnums.Aspect.SIDE


## 貫通確率を計算
## @param penetration 貫通力 (mm RHA)
## @param armor 装甲厚 (mm RHA)
## @param angle 入射角 (度)
## @return 貫通確率 (0.0-1.0)
static func calc_pen_prob(
    penetration: float,
    armor: float,
    angle: float = 0.0
) -> float:
    if armor <= 0.0:
        return 1.0
    if penetration <= 0.0:
        return 0.0

    # 傾斜装甲の実効厚
    var effective_armor := armor / cos(deg_to_rad(angle))

    # 貫通比
    var ratio := penetration / effective_armor

    # シグモイド関数で確率を計算
    # ratio=1.0で50%、ratio=1.2で約85%、ratio=0.8で約15%
    var k := 8.0  # 傾き係数
    return 1.0 / (1.0 + exp(-k * (ratio - 1.0)))
```

#### テストファイル

```gdscript
# tests/test_combat_calc.gd
extends GutTest

## CombatCalc純粋関数のユニットテスト


# =============================================================================
# calc_shooter_coeff
# =============================================================================

func test_shooter_coeff_normal() -> void:
    var result := CombatCalc.calc_shooter_coeff(0.0)
    assert_almost_eq(result, 1.0, 0.001)

func test_shooter_coeff_suppressed() -> void:
    var result := CombatCalc.calc_shooter_coeff(0.5)
    assert_almost_eq(result, GameConstants.M_SHOOTER_SUPPRESSED, 0.001)

func test_shooter_coeff_pinned() -> void:
    var result := CombatCalc.calc_shooter_coeff(0.75)
    assert_almost_eq(result, GameConstants.M_SHOOTER_PINNED, 0.001)

func test_shooter_coeff_broken() -> void:
    var result := CombatCalc.calc_shooter_coeff(0.95)
    assert_almost_eq(result, GameConstants.M_SHOOTER_BROKEN, 0.001)

func test_shooter_coeff_boundary_suppressed() -> void:
    # 閾値ちょうどの場合
    var result := CombatCalc.calc_shooter_coeff(GameConstants.SUPP_THRESHOLD_SUPPRESSED)
    assert_almost_eq(result, GameConstants.M_SHOOTER_SUPPRESSED, 0.001)


# =============================================================================
# calc_hit_prob
# =============================================================================

func test_hit_prob_zero_exposure() -> void:
    var result := CombatCalc.calc_hit_prob(0.0)
    assert_eq(result, 0.0)

func test_hit_prob_negative_exposure() -> void:
    var result := CombatCalc.calc_hit_prob(-1.0)
    assert_eq(result, 0.0)

func test_hit_prob_low_exposure() -> void:
    var result := CombatCalc.calc_hit_prob(0.1)
    assert_gt(result, 0.0)
    assert_lt(result, 0.5)

func test_hit_prob_high_exposure() -> void:
    var result := CombatCalc.calc_hit_prob(2.0)
    assert_gt(result, 0.8)
    assert_lte(result, 1.0)

func test_hit_prob_monotonic() -> void:
    # 期待危険度が増えるとヒット確率も増える
    var p1 := CombatCalc.calc_hit_prob(0.5)
    var p2 := CombatCalc.calc_hit_prob(1.0)
    var p3 := CombatCalc.calc_hit_prob(1.5)
    assert_lt(p1, p2)
    assert_lt(p2, p3)


# =============================================================================
# get_cover_coeff
# =============================================================================

func test_cover_coeff_open() -> void:
    var result := CombatCalc.get_cover_coeff(GameEnums.TerrainType.OPEN)
    assert_eq(result, 1.0)

func test_cover_coeff_forest() -> void:
    var result := CombatCalc.get_cover_coeff(GameEnums.TerrainType.FOREST)
    assert_eq(result, 0.5)

func test_cover_coeff_urban() -> void:
    var result := CombatCalc.get_cover_coeff(GameEnums.TerrainType.URBAN)
    assert_eq(result, 0.35)

func test_cover_coeff_fortified() -> void:
    var result := CombatCalc.get_cover_coeff(GameEnums.TerrainType.FORTIFIED)
    assert_eq(result, 0.2)

func test_cover_coeff_ordering() -> void:
    # 遮蔽効果: OPEN < SPARSE < FOREST < URBAN < FORTIFIED
    var open := CombatCalc.get_cover_coeff(GameEnums.TerrainType.OPEN)
    var sparse := CombatCalc.get_cover_coeff(GameEnums.TerrainType.SPARSE)
    var forest := CombatCalc.get_cover_coeff(GameEnums.TerrainType.FOREST)
    var urban := CombatCalc.get_cover_coeff(GameEnums.TerrainType.URBAN)
    var fortified := CombatCalc.get_cover_coeff(GameEnums.TerrainType.FORTIFIED)

    assert_gt(open, sparse)
    assert_gt(sparse, forest)
    assert_gt(forest, urban)
    assert_gt(urban, fortified)


# =============================================================================
# calc_aspect
# =============================================================================

func test_aspect_front() -> void:
    var shooter := Vector2(0, 100)
    var target := Vector2(0, 0)
    var facing := 0.0  # 上向き（Y-）
    var result := CombatCalc.calc_aspect(shooter, target, facing)
    # 射手は目標の正面にいる
    assert_eq(result, GameEnums.Aspect.FRONT)

func test_aspect_rear() -> void:
    var shooter := Vector2(0, -100)
    var target := Vector2(0, 0)
    var facing := 0.0  # 上向き（Y-）
    var result := CombatCalc.calc_aspect(shooter, target, facing)
    # 射手は目標の背後にいる
    assert_eq(result, GameEnums.Aspect.REAR)

func test_aspect_side_left() -> void:
    var shooter := Vector2(-100, 0)
    var target := Vector2(0, 0)
    var facing := 0.0  # 上向き（Y-）
    var result := CombatCalc.calc_aspect(shooter, target, facing)
    assert_eq(result, GameEnums.Aspect.SIDE)

func test_aspect_side_right() -> void:
    var shooter := Vector2(100, 0)
    var target := Vector2(0, 0)
    var facing := 0.0  # 上向き（Y-）
    var result := CombatCalc.calc_aspect(shooter, target, facing)
    assert_eq(result, GameEnums.Aspect.SIDE)


# =============================================================================
# calc_pen_prob
# =============================================================================

func test_pen_prob_zero_armor() -> void:
    var result := CombatCalc.calc_pen_prob(500.0, 0.0)
    assert_eq(result, 1.0)

func test_pen_prob_zero_penetration() -> void:
    var result := CombatCalc.calc_pen_prob(0.0, 500.0)
    assert_eq(result, 0.0)

func test_pen_prob_equal() -> void:
    # 貫通力 = 装甲厚 の場合、約50%
    var result := CombatCalc.calc_pen_prob(500.0, 500.0)
    assert_almost_eq(result, 0.5, 0.05)

func test_pen_prob_high_pen() -> void:
    # 貫通力 >> 装甲厚 の場合、高確率
    var result := CombatCalc.calc_pen_prob(800.0, 500.0)
    assert_gt(result, 0.9)

func test_pen_prob_low_pen() -> void:
    # 貫通力 << 装甲厚 の場合、低確率
    var result := CombatCalc.calc_pen_prob(300.0, 500.0)
    assert_lt(result, 0.1)

func test_pen_prob_angled_armor() -> void:
    # 傾斜装甲は実効的に厚くなる
    var result_0deg := CombatCalc.calc_pen_prob(500.0, 400.0, 0.0)
    var result_45deg := CombatCalc.calc_pen_prob(500.0, 400.0, 45.0)
    var result_60deg := CombatCalc.calc_pen_prob(500.0, 400.0, 60.0)

    assert_gt(result_0deg, result_45deg)
    assert_gt(result_45deg, result_60deg)

func test_pen_prob_monotonic() -> void:
    # 貫通力が増えると貫通確率も増える
    var p1 := CombatCalc.calc_pen_prob(400.0, 500.0)
    var p2 := CombatCalc.calc_pen_prob(500.0, 500.0)
    var p3 := CombatCalc.calc_pen_prob(600.0, 500.0)

    assert_lt(p1, p2)
    assert_lt(p2, p3)
```

---

### Phase 2: VisionSystem（優先度: 中）

#### 対象関数一覧

| 現在の関数 | 純粋関数シグネチャ |
|-----------|-------------------|
| `calculate_detection_probability(...)` | `static func calc_detection_prob(distance: float, observer_range: float, target_signature: float, cover_factor: float) -> float` |
| `get_suppression_modifier(suppression)` | `static func get_suppression_mod(suppression: float) -> float` |
| `calculate_los_blocked(...)` | `static func is_los_blocked(from: Vector2, to: Vector2, obstacles: Array) -> bool` |

---

### Phase 3: MissileSystem（優先度: 中）

#### 対象関数一覧

| 現在の関数 | 純粋関数シグネチャ |
|-----------|-------------------|
| `calculate_missile_position(...)` | `static func calc_missile_pos(start: Vector2, target: Vector2, speed: float, elapsed: float, profile: MissileProfile) -> Vector2` |
| `calculate_intercept_probability(...)` | `static func calc_intercept_prob(aps_level: int, missile_type: String) -> float` |

---

## 移行戦略

### Step 1: 純粋関数クラスを作成

1. `scripts/systems/combat_calc.gd` を新規作成
2. 対象関数をstatic funcとして実装
3. テストファイル `tests/test_combat_calc.gd` を作成
4. 全テストがパスすることを確認

### Step 2: CombatSystemを委譲パターンに変更

```gdscript
# combat_system.gd（変更後）
func calculate_shooter_coefficient(shooter: ElementData.ElementInstance) -> float:
    # 純粋関数に委譲
    return CombatCalc.calc_shooter_coeff(shooter.suppression)

func calculate_hit_probability(exposure: float) -> float:
    return CombatCalc.calc_hit_prob(exposure)
```

### Step 3: 既存テストの確認

既存の`test_combat_system.gd`のテストが全てパスすることを確認。
純粋関数への委譲が正しく行われていることを検証。

### Step 4: 段階的な直接呼び出しへの移行

呼び出し側を段階的に`CombatCalc.xxx()`直接呼び出しに変更。
最終的に`CombatSystem`の委譲メソッドを`@deprecated`マーク。

---

## 成功指標

| 指標 | 目標値 |
|------|--------|
| 純粋関数のテストカバレッジ | 100% |
| 純粋関数のテスト数 | 50+ |
| CombatCalcの関数数 | 10+ |
| 既存テストの破損 | 0件 |

---

## リスクと対策

### リスク1: 乱数を使う関数

**問題**: `randf()`を使う関数は非決定的

**対策**: シード注入パターンを使用
```gdscript
static func calc_hit_with_rng(exposure: float, rng: RandomNumberGenerator) -> bool:
    var p := calc_hit_prob(exposure)
    return rng.randf() < p
```

### リスク2: 大きな関数の分解

**問題**: `calculate_direct_fire_effect()`のような大きな関数

**対策**:
- まず内部の純粋な部分を切り出す
- 非純粋な部分（状態更新）は元の関数に残す
- 段階的にリファクタリング

### リスク3: パフォーマンス

**問題**: static呼び出しのオーバーヘッド

**対策**:
- GDScriptではstatic呼び出しは十分高速
- 必要ならインライン化を検討
- プロファイリングで確認

---

## 関連ドキュメント

- [リファクタリング計画書](refactoring_plan_v1.md) - 全体計画
- [アーキテクチャ設計書](architecture_current_v1.md) - 現行設計
- [戦闘システム仕様](combat_v0.1.md) - 計算式の仕様
