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

### Phase 2: VisionSystem（優先度: 中）✅ 完了

#### 対象関数一覧

| 現在の関数 | 純粋関数シグネチャ | 状態 |
| ---------- | ------------------ | ---- |
| `_calculate_forest_transmittance(...)` | `static func calc_forest_transmittance(forest_distance: float) -> float` | ✅ |
| `_check_line_of_sight(...)` | `static func calc_los_transmittance(forest_distance: float, smoke: float) -> float` | ✅ |
| `_get_concealment_modifier(terrain)` | `static func get_concealment_modifier(terrain: GameEnums.TerrainType) -> float` | ✅ |
| `_calculate_effective_range(...)` | `static func calc_effective_range(base_range: float, concealment: float) -> float` | ✅ |
| `_grow_position_error(...)` | `static func calc_position_error_growth(current: float, dt: float) -> float` | ✅ |

#### VisionCalc成果物

- `scripts/systems/vision_calc.gd` - 5つの純粋関数
- `tests/test_vision_calc.gd` - 26件のユニットテスト

---

### Phase 3: MissileSystem（優先度: 中）✅ 完了

#### MissileCalc対象関数一覧

| 現在の関数 | 純粋関数シグネチャ | 状態 |
| ---------- | ------------------ | ---- |
| `_normalize_angle(angle)` | `static func normalize_angle(angle: float) -> float` | ✅ |
| `get_effective_min_range(profile, attack_profile)` | `static func calc_effective_min_range(base_min: float, attack_profile) -> float` | ✅ |
| `get_aps_evasion_bonus(attack_profile)` | `static func get_aps_evasion_bonus(attack_profile) -> float` | ✅ |
| `calculate_top_attack_flight_time(profile, distance)` | `static func calc_top_attack_flight_time(speed: float, distance: float) -> float` | ✅ |
| `get_terminal_phase_distance(profile, attack_profile)` | `static func calc_terminal_phase_distance(profile, altitude, dive_angle) -> float` | ✅ |
| `determine_hit_zone(attack_profile, facing, shooter, target)` | `static func determine_hit_zone(...) -> HitZone` | ✅ |
| `_update_missile_position(...)` | `static func calc_missile_progress(time, total) -> float` | ✅ |
| - | `static func calc_missile_position(start, target, progress) -> Vector2` | ✅ |
| `attempt_aps_intercept(...)` | `static func calc_final_aps_intercept_prob(base, vuln, evasion) -> float` | ✅ |

#### MissileCalc成果物

- `scripts/systems/missile_calc.gd` - 9つの純粋関数
- `tests/test_missile_calc.gd` - 50件のユニットテスト

---

### Phase 4: ArtillerySystem（優先度: 中）✅ 完了

砲兵システムの間接射撃計算を純粋関数化。着弾効果、散布界、遮蔽計算などが対象。

#### ArtilleryCalc対象関数一覧

| 現在の関数 | 純粋関数シグネチャ | 状態 |
| ---------- | ------------------ | ---- |
| `get_cover_coefficient_if(terrain)` | `static func get_cover_coeff_if(terrain)` (CombatCalcに実装済) | ✅ |
| `calculate_indirect_impact_effect(...)` | `static func calc_indirect_falloff(distance, blast_radius, direct_hit_radius)` | ✅ |
| `_get_indirect_vulnerability_dmg(...)` | `static func get_indirect_vuln_dmg(armor_class, heavy_he_class, is_direct_hit)` | ✅ |
| `_get_indirect_vulnerability_supp(...)` | `static func get_indirect_vuln_supp(armor_class, heavy_he_class)` | ✅ |
| - | `static func get_dispersion_modifier(dispersion_mode)` | ✅ |
| - | `static func calc_indirect_suppression(supp_power, falloff, m_total, m_vuln)` | ✅ |
| - | `static func calc_indirect_damage(lethality, falloff, m_total, m_vuln)` | ✅ |
| `ArtilleryComponent.update_progress(...)` | `static func calc_deploy_progress(current, delta, duration)` | ✅ |

#### ArtilleryCalc成果物

- `scripts/systems/artillery_calc.gd` - 7つの純粋関数
- `tests/test_artillery_calc.gd` - 44件のユニットテスト

#### 実装パターン

```gdscript
# scripts/systems/artillery_calc.gd - 新規ファイル
class_name ArtilleryCalc
extends RefCounted

## 砲兵システムの純粋計算関数群
## 間接射撃の着弾効果、遮蔽、脆弱性計算


## 間接射撃の遮蔽係数を取得
## @param terrain 地形タイプ
## @return 遮蔽係数 (0.0-1.0)
static func get_cover_coeff_if(terrain: GameEnums.TerrainType) -> float:
    match terrain:
        GameEnums.TerrainType.OPEN:
            return 1.0
        GameEnums.TerrainType.ROAD:
            return 1.0
        GameEnums.TerrainType.FOREST:
            return GameConstants.COVER_IF_FOREST
        GameEnums.TerrainType.URBAN:
            return GameConstants.COVER_IF_URBAN
        _:
            return 1.0


## 距離減衰を計算
## @param distance 着弾点からの距離 (m)
## @param blast_radius 爆風半径 (m)
## @param direct_hit_radius 直撃半径 (m)
## @return 減衰係数 (0.0-1.0)
static func calc_indirect_falloff(
    distance: float,
    blast_radius: float,
    direct_hit_radius: float
) -> float:
    # 爆風半径外は影響なし
    if distance > blast_radius:
        return 0.0
    # 直撃半径内は最大効果
    if distance <= direct_hit_radius:
        return 1.0
    # 線形減衰
    return clampf(1.0 - distance / blast_radius, 0.0, 1.0)


## 分散モード係数を取得
## @param dispersion_mode 分散モード (0=Column, 1=Deployed, 2=Dispersed)
## @return 分散係数
static func get_dispersion_modifier(dispersion_mode: int) -> float:
    match dispersion_mode:
        0:  # Column - 密集、被害大
            return GameConstants.DISPERSION_IF_COLUMN
        1:  # Deployed - 標準
            return GameConstants.DISPERSION_IF_DEPLOYED
        2:  # Dispersed - 分散、被害小
            return GameConstants.DISPERSION_IF_DISPERSED
        _:
            return 1.0


## 間接火力に対するダメージ脆弱性を取得
## @param armor_class 装甲クラス (0=SOFT, 1=LIGHT, 2=MEDIUM, 3=HEAVY)
## @param heavy_he_class 大口径HEクラス (0=NONE, 1=HEAVY_HE)
## @param is_direct_hit 直撃か
## @return 脆弱性係数
static func get_indirect_vuln_dmg(
    armor_class: int,
    heavy_he_class: int,
    is_direct_hit: bool
) -> float:
    # 大口径HE（155mm等）は装甲にも効果
    if heavy_he_class == 1:  # HEAVY_HE
        if is_direct_hit:
            match armor_class:
                0: return GameConstants.HEAVY_HE_VULN_DMG_SOFT_DIRECT
                1: return GameConstants.HEAVY_HE_VULN_DMG_LIGHT_DIRECT
                2: return GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_DIRECT
                _: return GameConstants.HEAVY_HE_VULN_DMG_HEAVY_DIRECT
        else:
            match armor_class:
                0: return GameConstants.HEAVY_HE_VULN_DMG_SOFT_INDIRECT
                1: return GameConstants.HEAVY_HE_VULN_DMG_LIGHT_INDIRECT
                2: return GameConstants.HEAVY_HE_VULN_DMG_MEDIUM_INDIRECT
                _: return GameConstants.HEAVY_HE_VULN_DMG_HEAVY_INDIRECT

    # 通常HEは装甲車両にほぼ無効
    match armor_class:
        0: return 1.0   # SOFT
        1: return 0.2   # LIGHT
        2: return 0.05  # MEDIUM
        _: return 0.0   # HEAVY


## 間接火力に対する抑圧脆弱性を取得
## @param armor_class 装甲クラス
## @param heavy_he_class 大口径HEクラス
## @return 脆弱性係数
static func get_indirect_vuln_supp(
    armor_class: int,
    heavy_he_class: int
) -> float:
    # 大口径HEは装甲車両にも抑圧効果
    if heavy_he_class == 1:  # HEAVY_HE
        match armor_class:
            0: return GameConstants.HEAVY_HE_VULN_SUPP_SOFT
            1: return GameConstants.HEAVY_HE_VULN_SUPP_LIGHT
            2: return GameConstants.HEAVY_HE_VULN_SUPP_MEDIUM
            _: return GameConstants.HEAVY_HE_VULN_SUPP_HEAVY

    # 通常HEの抑圧は装甲で大幅減衰
    match armor_class:
        0: return 1.0
        1: return 0.5
        2: return 0.2
        _: return 0.1


## 間接射撃の抑圧値を計算
## @param supp_power 抑圧力 (0-100)
## @param falloff 距離減衰 (0.0-1.0)
## @param m_total 総合係数 (遮蔽*塹壕*分散)
## @param m_vuln 脆弱性係数
## @return 抑圧増加値
static func calc_indirect_suppression(
    supp_power: float,
    falloff: float,
    m_total: float,
    m_vuln: float
) -> float:
    return GameConstants.K_IF_SUPP * (supp_power / 100.0) * falloff * m_total * m_vuln


## 間接射撃のダメージを計算
## @param lethality 殺傷力 (0-100)
## @param falloff 距離減衰 (0.0-1.0)
## @param m_total 総合係数 (遮蔽*塹壕*分散)
## @param m_vuln 脆弱性係数
## @return ダメージ値
static func calc_indirect_damage(
    lethality: float,
    falloff: float,
    m_total: float,
    m_vuln: float
) -> float:
    return GameConstants.K_IF_DMG * (lethality / 100.0) * falloff * m_total * m_vuln


## 展開/撤収進捗を計算
## @param current_progress 現在の進捗 (0.0-1.0)
## @param delta_sec 経過秒数
## @param duration_sec 総所要時間
## @return 新しい進捗 (0.0-1.0)
static func calc_deploy_progress(
    current_progress: float,
    delta_sec: float,
    duration_sec: float
) -> float:
    if duration_sec <= 0:
        return 1.0
    return clampf(current_progress + delta_sec / duration_sec, 0.0, 1.0)
```

#### テストファイル

```gdscript
# tests/test_artillery_calc.gd
extends GutTest

## ArtilleryCalc純粋関数のユニットテスト

const AC = preload("res://scripts/systems/artillery_calc.gd")


# =============================================================================
# get_cover_coeff_if
# =============================================================================

func test_cover_coeff_if_open() -> void:
    var result := AC.get_cover_coeff_if(GameEnums.TerrainType.OPEN)
    assert_eq(result, 1.0)

func test_cover_coeff_if_forest() -> void:
    var result := AC.get_cover_coeff_if(GameEnums.TerrainType.FOREST)
    assert_eq(result, GameConstants.COVER_IF_FOREST)

func test_cover_coeff_if_urban() -> void:
    var result := AC.get_cover_coeff_if(GameEnums.TerrainType.URBAN)
    assert_eq(result, GameConstants.COVER_IF_URBAN)


# =============================================================================
# calc_indirect_falloff
# =============================================================================

func test_falloff_at_impact() -> void:
    var result := AC.calc_indirect_falloff(0.0, 50.0, 5.0)
    assert_eq(result, 1.0)

func test_falloff_direct_hit() -> void:
    var result := AC.calc_indirect_falloff(3.0, 50.0, 5.0)
    assert_eq(result, 1.0)

func test_falloff_outside_blast() -> void:
    var result := AC.calc_indirect_falloff(60.0, 50.0, 5.0)
    assert_eq(result, 0.0)

func test_falloff_linear_decay() -> void:
    var result := AC.calc_indirect_falloff(25.0, 50.0, 5.0)
    assert_almost_eq(result, 0.5, 0.05)


# =============================================================================
# get_dispersion_modifier
# =============================================================================

func test_dispersion_column() -> void:
    var result := AC.get_dispersion_modifier(0)
    assert_eq(result, GameConstants.DISPERSION_IF_COLUMN)

func test_dispersion_deployed() -> void:
    var result := AC.get_dispersion_modifier(1)
    assert_eq(result, GameConstants.DISPERSION_IF_DEPLOYED)

func test_dispersion_dispersed() -> void:
    var result := AC.get_dispersion_modifier(2)
    assert_eq(result, GameConstants.DISPERSION_IF_DISPERSED)

func test_dispersion_ordering() -> void:
    # 密集 > 展開 > 分散（被害の大きさ）
    var column := AC.get_dispersion_modifier(0)
    var deployed := AC.get_dispersion_modifier(1)
    var dispersed := AC.get_dispersion_modifier(2)
    assert_gt(column, deployed)
    assert_gt(deployed, dispersed)


# =============================================================================
# calc_deploy_progress
# =============================================================================

func test_deploy_progress_start() -> void:
    var result := AC.calc_deploy_progress(0.0, 5.0, 30.0)
    assert_almost_eq(result, 5.0 / 30.0, 0.001)

func test_deploy_progress_complete() -> void:
    var result := AC.calc_deploy_progress(0.9, 10.0, 30.0)
    assert_eq(result, 1.0)

func test_deploy_progress_zero_duration() -> void:
    var result := AC.calc_deploy_progress(0.0, 5.0, 0.0)
    assert_eq(result, 1.0)
```

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

## テスト実行方法

### 基本コマンド

```bash
# プロジェクトディレクトリで実行
cd /home/olanleed/work/github/company-commander

# 全テスト実行（-gexit必須：テスト後に自動終了）
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# 特定のテストファイルを実行
godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_artillery_calc.gd -gexit

# 複数のテストファイルを実行
godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_artillery_calc.gd,res://tests/test_combat_calc.gd -gexit
```

### 純粋関数テストのみ実行

```bash
# Phase 1-4 の純粋関数テスト（高速）
godot --headless --script addons/gut/gut_cmdln.gd \
  -gtest=res://tests/test_combat_calc.gd,res://tests/test_vision_calc.gd,res://tests/test_missile_calc.gd,res://tests/test_artillery_calc.gd \
  -gexit
```

### 注意事項

- **`-gexit`オプション必須**: このオプションがないとテスト完了後もGodotが終了せず、タイムアウトする
- **`--headless`**: GUIなしで実行（CI/CD向け）
- 全テスト（68ファイル、1100+テスト）は約0.4秒で完了

### テスト結果の見方

```text
---- Totals ----
Scripts           44      # テストファイル数
Tests             1120    # テスト数
  Passing         1116    # 成功
  Risky/Pending   4       # 未実装/保留
Asserts           3112    # アサーション数
Time              0.355s  # 実行時間

---- All tests passed! ----  # または失敗時はエラー詳細
```

---

## 関連ドキュメント

- [リファクタリング計画書](refactoring_plan_v1.md) - 全体計画
- [アーキテクチャ設計書](architecture_current_v1.md) - 現行設計
- [戦闘システム仕様](combat_v0.1.md) - 計算式の仕様
