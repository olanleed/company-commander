# Ruleset v0.1
## Tier→数値変換ルール

---

## 1. 役割

### 入力

- MunitionClass の抽象属性（EffectLevel / RangeTier / VelocityBand / DispersionBand / SmokeTier / DurationTier …）
- MunitionVariant の上書き（Tier差・誘導プロファイル差）

### 出力（ゲームが使う具体値）

| 出力 | 説明 |
|------|------|
| 効果レーティング（0–100） | lethality / suppression / subsystem_damage など |
| 射程の既定値（m） | Near/Mid/Far帯の境界や最大射程の既定 |
| 弾道・時間（秒） | TOF（弾の到達時間）に使う代表速度・係数 |
| 散布（mil or m） | 直射の角度散布、間接の着弾散布 |
| 爆発幾何（m） | blast半径、DirectHitOnlyの直撃半径、NearMissShock半径 |
| 煙幕パラメータ（m/秒/密度） | 半径、立ち上がり・維持・消散、濃度 |

---

## 2. グローバル定数（戦闘仕様v0.1と整合）

シム全体の前提としてRulesetに置く。

```yaml
global:
  sim_tick_hz: 10
  dt_sec: 0.1

  # 抑圧閾値（既定）
  suppression_thresholds:
    suppressed: 40
    pinned: 70
    broken: 90

  # 視界の実質ブロック閾値（既定）
  los_transmittance_block_threshold: 0.10

  # 貫徹確率（p_pen）に使うシグモイドの"なだらかさ"
  penetration_sigmoid_width: 8

  # 連続直射の基準係数（既定：抑圧主導）
  direct_fire_constants:
    K_DF_DMG: 0.06     # rating=100, 最良条件でのStrength減少/秒
    K_DF_SUPP: 2.5     # rating=100, 最良条件でのSuppression増加/秒

  # 間接（着弾1発）の基準係数
  indirect_fire_constants:
    K_IF_DMG: 5.0      # rating=100, 爆心のStrength減少/発
    K_IF_SUPP: 25.0    # rating=100, 爆心のSuppression増加/発
```

---

## 3. EffectLevel → レーティング（0–100）変換

MunitionClass の terminal_effect は None/Low/Medium/High/Extreme の段階。
Rulesetでは、これを **"チャンネル別レーティング"** に変換する。

同じ "High" でも、suppressionは強め、strengthは控えめ、など調整可能。

```yaml
effect_level_to_rating:
  # 直射/直撃などの「損耗（Strength）」寄与
  strength:
    None: 0
    Low: 15
    Medium: 35
    High: 60
    Extreme: 85

  # 抑圧（Suppression）寄与：ゲーム性の核なので強め
  suppression:
    None: 0
    Low: 25
    Medium: 50
    High: 75
    Extreme: 95

  # 車両サブシステム損傷（mobility/firepower/sensors）：貫徹時の"効き"を表す
  subsystem:
    None: 0
    Low: 20
    Medium: 45
    High: 70
    Extreme: 90
```

### 3.1 「条件付き」効果のルール（抽象→具体の橋）

MunitionClass側で指定した条件（DirectHitOnly / NearMissShock 等）に対する既定値。

```yaml
conditional_effect_defaults:
  # 小火器が装甲に与える抑圧が不自然に大きくならないための上限
  suppression_caps:
    suppression_cap_low: 20     # 小銃/MG → 装甲の乗員ショック上限（既定）
    suppression_cap_medium: 40  # 機関砲など"より強い威圧"に使う余地（v0.1は未使用でもOK）

  # DirectHitOnly（例：Tank KE→Soft）を成立させるための幾何
  direct_hit_only_geometry:
    direct_hit_radius_m: 2      # 直撃判定半径（既定）
    near_miss_shock_radius_m: 20  # 近傍弾ショック半径（抑圧のみ）（既定）
```

---

## 4. RangeTier → 射程帯（m）既定値

個別WeaponSystemが上書きしない場合に使う「標準の距離帯」。
マップ2km×2kmに合わせて、Longは2.5km程度、VeryLongは4kmまで確保。

```yaml
range_tier_defaults_m:
  Close:
    near_end: 150
    mid_end: 300
    max: 500

  Medium:
    near_end: 200
    mid_end: 600
    max: 1200

  Long:
    near_end: 300
    mid_end: 1000
    max: 2500

  VeryLong:
    near_end: 400
    mid_end: 1600
    max: 4000
```

---

## 5. VelocityBand → 代表速度／TOF係数（抽象弾道）

弾速を「規格」ではなく「帯」で持つための表。
WeaponSystemProfileができたら、ここに倍率や上書きを掛けられる。

### 5.1 直射に近い弾道（Direct_Ballistic）

```yaml
kinematics_velocity_mps:
  Direct_Ballistic:
    Low: 400
    Medium: 700
    High: 900
    VeryHigh: 1600
```

### 5.2 山なり弾道（Arced_Ballistic：迫撃など）

迫撃・榴弾は「初速」よりも TOFが長いことがゲーム性に効く。
v0.1は簡易近似式で固定。

```
tof_sec = tof_coeff * sqrt(distance_m)
```

```yaml
arced_ballistic_tof:
  # tof_sec = coeff * sqrt(distance_m)
  tof_coeff_by_velocity_band:
    Low: 0.50
    Medium: 0.42
    High: 0.36
```

### 5.3 ブースト→惰性（BoostThenCoast：RPG系）

数値を固定せず、2フェーズだけ定義（後でWeaponSystemが倍率上書き）。

```yaml
boost_then_coast_profile:
  Medium:
    boost_distance_m: 10
    boost_velocity_mps: 120
    coast_velocity_mps: 280
  High:
    boost_distance_m: 10
    boost_velocity_mps: 140
    coast_velocity_mps: 320
```

### 5.4 誘導巡航（Guided_Cruise：ATGM系）

```yaml
guided_cruise_velocity_mps:
  Medium: 220
  High: 300
```

---

## 6. DispersionBand → 散布（直射/間接）

### 6.1 直射：角度散布（1σ、mil）

直射DISCRETEの `sigma_m = distance_m * (sigma_mil / 1000)` に使う既定値。

```yaml
direct_dispersion_sigma_mil_1sigma:
  Tight: 0.30
  Medium: 1.00
  Loose: 3.00
  VeryLoose: 8.00
```

### 6.2 間接：距離依存の散布（1σ、m）

間接は距離で散布が増えるのが自然なので、v0.1はこれで固定：

```
sigma_m = sigma_base_at_1km * sqrt(distance_m / 1000)
```

```yaml
indirect_dispersion_sigma_base_m_at_1km:
  Tight: 12
  Medium: 20
  Loose: 35
  VeryLoose: 60
```

---

## 7. 間接射撃：観測リンクで反応と散布が変わる（Tier→数値）

MunitionClass側の `RequiresObserver` を実用化するための変換規約。

### 7.1 反応時間（call_time：秒）

```yaml
indirect_call_time_sec:
  Fast: 6
  Medium: 10
  Slow: 18
```

### 7.2 ルール：どのTierを使うか

```yaml
indirect_observer_rule:
  # 観測リンクあり＆目標CONF → Fast & Tight
  observed_conf:
    call_time_tier: Fast
    dispersion_band: Tight

  # 観測リンクあり＆目標SUS → Medium & Medium
  observed_sus:
    call_time_tier: Medium
    dispersion_band: Medium

  # 観測リンクなし（地図射撃） → Slow & VeryLoose
  unobserved:
    call_time_tier: Slow
    dispersion_band: VeryLoose
```

### 実装

```
call_time = call_time_sec[tier]
sigma = indirect_sigma(distance, band)
着弾開始時刻 = now + call_time + tof
```

---

## 8. 貫徹Tier → 侵徹レーティング（0–100）

MunitionVariantが上書きする `penetration_tier_ke/ce` を、p_pen計算に使う「P（貫徹レーティング）」へ変換。

```yaml
penetration_tier_to_pen_rating:
  KE:   # 運動エネルギー徹甲
    Low: 45
    Medium: 60
    High: 75
    Extreme: 92

  CE:   # 成形炸薬（HEAT）
    Low: 50
    Medium: 65
    High: 80
    Extreme: 92
```

### p_pen計算（既定）

```
p_pen = sigmoid((P - A) / width)
width = global.penetration_sigmoid_width
```

---

## 9. BlastTier → 爆風半径（m）と「近傍弾ショック」既定

爆発系（HE_Frag / HEATの対人効果 / サーモバリック等）に共通の幾何の既定。

```yaml
blast_tier_geometry:
  Low:
    blast_radius_m: 10
    shock_radius_m: 20

  Medium:
    blast_radius_m: 18
    shock_radius_m: 30

  High:
    blast_radius_m: 35
    shock_radius_m: 45

  Extreme:
    blast_radius_m: 45
    shock_radius_m: 60
```

> 迫撃HEがHighに乗ると、R_blast=40mと自然に整合。WeaponSystem側で `blast_radius_m` を明示してもOK。

---

## 10. SmokeTier / DurationTier → 煙幕パラメータ

LoS仕様 v0.1の煙透過（T_smoke）と矛盾しないよう、密度（density）と時間を決定。

```yaml
smoke_defaults:
  radius_m_by_smoke_tier:
    Thin: 25
    Standard: 35
    Thick: 45

  density_max_by_smoke_tier:
    Thin: 0.7
    Standard: 1.0
    Thick: 1.3

  duration_by_duration_tier_sec:
    Short:   { rise: 5,  sustain: 40,  fade: 15 }
    Standard:{ rise: 10, sustain: 60,  fade: 20 }
    Long:    { rise: 10, sustain: 180, fade: 60 }

  stacking_density_cap: 1.5
```

> 同じ「Mortar_Smoke」でも NATO/RU/CN Variantで SmokeTier や DurationTier を変えるだけで"規格差"を表現可能。

---

## 11. 装甲（ARMORED）側の初期プリセット

貫徹モデルを動かすには、少なくとも **装甲レーティングA（0–100）** が必要。
クラス差（APC/IFV/MBT）で初期プリセットを用意。

```yaml
armored_presets_rating_0_100:
  # 軽装甲（APC/装輪装甲などの初期値）
  Light:
    armor_ke: { FRONT: 35, SIDE: 25, REAR: 15, TOP: 10 }
    armor_ce: { FRONT: 25, SIDE: 20, REAR: 15, TOP: 10 }

  # 中装甲（IFV級の初期値）
  Medium:
    armor_ke: { FRONT: 55, SIDE: 40, REAR: 25, TOP: 15 }
    armor_ce: { FRONT: 45, SIDE: 35, REAR: 25, TOP: 15 }

  # 重装甲（MBT級の初期値）
  Heavy:
    armor_ke: { FRONT: 85, SIDE: 55, REAR: 35, TOP: 20 }
    armor_ce: { FRONT: 75, SIDE: 55, REAR: 40, TOP: 25 }
```

> 「国差」ではなく「車種クラス差」。NATO/RU/CNの違いを出したければ、VehicleVariant側でこのプリセットを微調整。

---

## 12. 命中ゾーン（FRONT/SIDE/REAR）の角度区分

Rulesetとして固定。全装甲弾薬で一貫。

```yaml
hit_zone_by_relative_angle_deg:
  FRONT: { max_abs_deg: 60 }
  REAR:  { min_abs_deg: 150 }
  SIDE:  { otherwise: true }
```

| ゾーン | 角度条件 |
|--------|---------|
| FRONT | \|θ\| ≤ 60° |
| REAR | \|θ\| ≥ 150° |
| SIDE | それ以外 |

---

## 13. ConcreteWeaponへの変換手順（運用規約）

Rulesetを使って抽象クラスから実用値を作る手順。

### 13.1 terminal_effect → 0–100へ

```
strength_effect_level → effect_level_to_rating.strength[level]
suppression_effect_level → effect_level_to_rating.suppression[level]
subsystem_effect_level → effect_level_to_rating.subsystem[level]
```

### 13.2 射程・散布・弾道

| 項目 | 変換元 |
|------|--------|
| 射程帯 | `range_tier_defaults_m[range_tier]` を既定採用（WeaponSystemが上書き可） |
| 直射散布 | `direct_dispersion_sigma_mil_1sigma[dispersion_band]` |
| 間接散布 | `indirect_dispersion_sigma_base_m_at_1km[dispersion_band]` を距離でスケール |

### 13.3 貫徹

1. Variantの `penetration_tier_ke/ce` を `penetration_tier_to_pen_rating` でPへ
2. Targetの装甲プリセットからAを取得
3. `p_pen = sigmoid((P - A) / width)` を計算

### 13.4 煙幕

SmokeTier と DurationTier を `smoke_defaults` で具体化。

---

## 14. 早見表：Tier→数値変換サマリー

### 14.1 EffectLevel → Rating

| Level | strength | suppression | subsystem |
|-------|----------|-------------|-----------|
| None | 0 | 0 | 0 |
| Low | 15 | 25 | 20 |
| Medium | 35 | 50 | 45 |
| High | 60 | 75 | 70 |
| Extreme | 85 | 95 | 90 |

### 14.2 RangeTier → 射程（m）

| Tier | near_end | mid_end | max |
|------|----------|---------|-----|
| Close | 150 | 300 | 500 |
| Medium | 200 | 600 | 1200 |
| Long | 300 | 1000 | 2500 |
| VeryLong | 400 | 1600 | 4000 |

### 14.3 VelocityBand → 速度（m/s）- Direct_Ballistic

| Band | velocity (m/s) |
|------|----------------|
| Low | 400 |
| Medium | 700 |
| High | 900 |
| VeryHigh | 1600 |

### 14.4 DispersionBand → 直射散布（mil, 1σ）

| Band | sigma (mil) |
|------|-------------|
| Tight | 0.30 |
| Medium | 1.00 |
| Loose | 3.00 |
| VeryLoose | 8.00 |

### 14.5 DispersionBand → 間接散布（m @1km, 1σ）

| Band | sigma_base (m) |
|------|----------------|
| Tight | 12 |
| Medium | 20 |
| Loose | 35 |
| VeryLoose | 60 |

### 14.6 PenetrationTier → Rating

| Tier | KE | CE |
|------|----|----|
| Low | 45 | 50 |
| Medium | 60 | 65 |
| High | 75 | 80 |
| Extreme | 92 | 92 |

### 14.7 BlastTier → 半径（m）

| Tier | blast_radius | shock_radius |
|------|--------------|--------------|
| Low | 10 | 20 |
| Medium | 18 | 30 |
| High | 35 | 45 |
| Extreme | 45 | 60 |

### 14.8 SmokeTier → 半径・密度

| Tier | radius (m) | density_max |
|------|------------|-------------|
| Thin | 25 | 0.7 |
| Standard | 35 | 1.0 |
| Thick | 45 | 1.3 |

### 14.9 DurationTier → 時間（秒）

| Tier | rise | sustain | fade |
|------|------|---------|------|
| Short | 5 | 40 | 15 |
| Standard | 10 | 60 | 20 |
| Long | 10 | 180 | 60 |
