# ConcreteWeapon v0.1
## 6セット抽象合成表

---

## 概要

ConcreteWeaponは以下の合成で生成される：

```
ConcreteWeapon = WeaponSystemProfile × MunitionClass × MunitionVariant
```

本仕様書ではMVP用の6セットを定義する。

---

## 1. 合成一覧（6セット）

| セットID | 用途 | WeaponSystemProfile | MunitionClass | 規格別Variant |
|---------|------|---------------------|---------------|---------------|
| `CW_RIFLE_STD` | 歩兵→歩兵（有効）、装甲へは原則無効 | Rifle_System | SmallArms_Ball | NATO/RU/CN_SmallArms_Ball |
| `CW_RPG_HEAT` | 歩兵AT（ゾーン依存で有効） | RPG_Launcher_System | Inf_AT_Rocket_HEAT | NATO/RU/CN_InfAT_Rocket_HEAT |
| `CW_TANK_KE` | 戦車AP（対装甲の主力、対歩兵は直撃条件） | TankGun_System | Tank_KE_Penetrator | NATO/RU/CN_Tank_KE |
| `CW_TANK_HEATMP` | 戦車HEAT/多目的（対歩兵/掩体にも） | TankGun_System | Tank_HEAT_MultiPurpose | NATO/RU/CN_Tank_HEATMP |
| `CW_MORTAR_HE` | 迫撃HE（抑圧＋損耗、観測で強化） | Mortar_Tube_System | Mortar_HE_Frag | NATO/RU/CN_Mortar_HE |
| `CW_MORTAR_SMOKE` | 迫撃煙（LoS阻害・隠蔽、観測/制圧の窓作り） | Mortar_Tube_System | Mortar_Smoke_Obscurant | NATO/RU/CN_Mortar_SMOKE |

---

## 2. 戦術シナリオの対応

「あなたの例」がこの6セットでどう成立するか：

| シナリオ | ConcreteWeapon | 仕様上の根拠 |
|---------|----------------|-------------|
| 歩兵→歩兵（小銃 有効） | `CW_RIFLE_STD` | Softに strength/suppression が入る |
| 歩兵→装甲（小銃 無効） | `CW_RIFLE_STD` | Armoredへ strength=None + suppression_cap |
| 歩兵→装甲（RPG 部位で有効） | `CW_RPG_HEAT` | ZoneSensitive + 貫徹Tier |
| 戦車→歩兵（HEAT 大ダメージ） | `CW_TANK_HEATMP` | Softへ High/Extreme |
| 戦車→歩兵（AP 場合によって無効） | `CW_TANK_KE` | Softへ DirectHitOnly + NearMissShock |

---

## 3. ConcreteWeapon マニフェスト（YAML定義）

```yaml
concrete_weapons_v0_1:

  - id: CW_RIFLE_STD
    weapon_system_profile_id: Rifle_System
    munition_class_id: SmallArms_Ball
    variants_by_standard:
      NATO: NATO_SmallArms_Ball
      RU:   RU_SmallArms_Ball
      CN:   CN_SmallArms_Ball

  - id: CW_RPG_HEAT
    weapon_system_profile_id: RPG_Launcher_System
    munition_class_id: Inf_AT_Rocket_HEAT
    variants_by_standard:
      NATO: NATO_InfAT_Rocket_HEAT
      RU:   RU_InfAT_Rocket_HEAT
      CN:   CN_InfAT_Rocket_HEAT

  - id: CW_TANK_KE
    weapon_system_profile_id: TankGun_System
    munition_class_id: Tank_KE_Penetrator
    variants_by_standard:
      NATO: NATO_Tank_KE
      RU:   RU_Tank_KE
      CN:   CN_Tank_KE

  - id: CW_TANK_HEATMP
    weapon_system_profile_id: TankGun_System
    munition_class_id: Tank_HEAT_MultiPurpose
    variants_by_standard:
      NATO: NATO_Tank_HEATMP
      RU:   RU_Tank_HEATMP
      CN:   CN_Tank_HEATMP

  - id: CW_MORTAR_HE
    weapon_system_profile_id: Mortar_Tube_System
    munition_class_id: Mortar_HE_Frag
    variants_by_standard:
      NATO: NATO_Mortar_HE
      RU:   RU_Mortar_HE
      CN:   CN_Mortar_HE

  - id: CW_MORTAR_SMOKE
    weapon_system_profile_id: Mortar_Tube_System
    munition_class_id: Mortar_Smoke_Obscurant
    variants_by_standard:
      NATO: NATO_Mortar_SMOKE
      RU:   RU_Mortar_SMOKE
      CN:   CN_Mortar_SMOKE
```

---

## 4. MunitionVariant 定義（最小セット）

6セットを回すために必要なVariant定義。
**性能差は付けず、互換性（logistics_tag）を分けることで規格差対応を成立させる。**

```yaml
munition_variants_v0_1_minimal:

  # ===================
  # Small Arms
  # ===================
  - id: NATO_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: NATO
    logistics_tag: RIFLE_INTERMEDIATE_NATO
    overrides: { }

  - id: RU_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: RU
    logistics_tag: RIFLE_INTERMEDIATE_RU
    overrides: { }

  - id: CN_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: CN
    logistics_tag: RIFLE_INTERMEDIATE_CN
    overrides: { }

  # ===================
  # Infantry AT (RPG/unguided HEAT rocket)
  # ===================
  - id: NATO_InfAT_Rocket_HEAT
    base_class_id: Inf_AT_Rocket_HEAT
    standard: NATO
    logistics_tag: AT_ROCKET_CLASS_NATO
    overrides:
      penetration_tier_ce: Medium
      blast_tier: Low

  - id: RU_InfAT_Rocket_HEAT
    base_class_id: Inf_AT_Rocket_HEAT
    standard: RU
    logistics_tag: AT_ROCKET_CLASS_RU
    overrides:
      penetration_tier_ce: Medium
      blast_tier: Low

  - id: CN_InfAT_Rocket_HEAT
    base_class_id: Inf_AT_Rocket_HEAT
    standard: CN
    logistics_tag: AT_ROCKET_CLASS_CN
    overrides:
      penetration_tier_ce: Medium
      blast_tier: Low

  # ===================
  # Tank KE (AP)
  # ===================
  - id: NATO_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: NATO
    logistics_tag: TANK_GUN_CLASS_NATO
    overrides:
      penetration_tier_ke: Extreme

  - id: RU_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: RU
    logistics_tag: TANK_GUN_CLASS_RU
    overrides:
      penetration_tier_ke: Extreme

  - id: CN_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: CN
    logistics_tag: TANK_GUN_CLASS_CN
    overrides:
      penetration_tier_ke: Extreme

  # ===================
  # Tank HEAT-MP
  # ===================
  - id: NATO_Tank_HEATMP
    base_class_id: Tank_HEAT_MultiPurpose
    standard: NATO
    logistics_tag: TANK_GUN_CLASS_NATO
    overrides:
      penetration_tier_ce: High
      blast_tier: Medium
      range_tier: Medium    # HEATはKEより射程Tierを一段短く

  - id: RU_Tank_HEATMP
    base_class_id: Tank_HEAT_MultiPurpose
    standard: RU
    logistics_tag: TANK_GUN_CLASS_RU
    overrides:
      penetration_tier_ce: High
      blast_tier: Medium
      range_tier: Medium

  - id: CN_Tank_HEATMP
    base_class_id: Tank_HEAT_MultiPurpose
    standard: CN
    logistics_tag: TANK_GUN_CLASS_CN
    overrides:
      penetration_tier_ce: High
      blast_tier: Medium
      range_tier: Medium

  # ===================
  # Mortar HE
  # ===================
  - id: NATO_Mortar_HE
    base_class_id: Mortar_HE_Frag
    standard: NATO
    logistics_tag: MORTAR_CLASS_NATO
    overrides:
      blast_tier: High

  - id: RU_Mortar_HE
    base_class_id: Mortar_HE_Frag
    standard: RU
    logistics_tag: MORTAR_CLASS_RU
    overrides:
      blast_tier: High

  - id: CN_Mortar_HE
    base_class_id: Mortar_HE_Frag
    standard: CN
    logistics_tag: MORTAR_CLASS_CN
    overrides:
      blast_tier: High

  # ===================
  # Mortar Smoke
  # ===================
  - id: NATO_Mortar_SMOKE
    base_class_id: Mortar_Smoke_Obscurant
    standard: NATO
    logistics_tag: MORTAR_CLASS_NATO
    overrides:
      smoke_tier: Standard
      duration_tier: Long

  - id: RU_Mortar_SMOKE
    base_class_id: Mortar_Smoke_Obscurant
    standard: RU
    logistics_tag: MORTAR_CLASS_RU
    overrides:
      smoke_tier: Standard
      duration_tier: Long

  - id: CN_Mortar_SMOKE
    base_class_id: Mortar_Smoke_Obscurant
    standard: CN
    logistics_tag: MORTAR_CLASS_CN
    overrides:
      smoke_tier: Standard
      duration_tier: Long
```

---

## 5. Variant overrides 早見表

### 5.1 Small Arms（全規格共通）

| Variant | logistics_tag | overrides |
|---------|---------------|-----------|
| NATO_SmallArms_Ball | RIFLE_INTERMEDIATE_NATO | なし |
| RU_SmallArms_Ball | RIFLE_INTERMEDIATE_RU | なし |
| CN_SmallArms_Ball | RIFLE_INTERMEDIATE_CN | なし |

### 5.2 Infantry AT Rocket

| Variant | logistics_tag | penetration_tier_ce | blast_tier |
|---------|---------------|---------------------|------------|
| NATO_InfAT_Rocket_HEAT | AT_ROCKET_CLASS_NATO | Medium | Low |
| RU_InfAT_Rocket_HEAT | AT_ROCKET_CLASS_RU | Medium | Low |
| CN_InfAT_Rocket_HEAT | AT_ROCKET_CLASS_CN | Medium | Low |

### 5.3 Tank KE

| Variant | logistics_tag | penetration_tier_ke |
|---------|---------------|---------------------|
| NATO_Tank_KE | TANK_GUN_CLASS_NATO | Extreme |
| RU_Tank_KE | TANK_GUN_CLASS_RU | Extreme |
| CN_Tank_KE | TANK_GUN_CLASS_CN | Extreme |

### 5.4 Tank HEAT-MP

| Variant | logistics_tag | penetration_tier_ce | blast_tier | range_tier |
|---------|---------------|---------------------|------------|------------|
| NATO_Tank_HEATMP | TANK_GUN_CLASS_NATO | High | Medium | Medium |
| RU_Tank_HEATMP | TANK_GUN_CLASS_RU | High | Medium | Medium |
| CN_Tank_HEATMP | TANK_GUN_CLASS_CN | High | Medium | Medium |

### 5.5 Mortar HE

| Variant | logistics_tag | blast_tier |
|---------|---------------|------------|
| NATO_Mortar_HE | MORTAR_CLASS_NATO | High |
| RU_Mortar_HE | MORTAR_CLASS_RU | High |
| CN_Mortar_HE | MORTAR_CLASS_CN | High |

### 5.6 Mortar Smoke

| Variant | logistics_tag | smoke_tier | duration_tier |
|---------|---------------|------------|---------------|
| NATO_Mortar_SMOKE | MORTAR_CLASS_NATO | Standard | Long |
| RU_Mortar_SMOKE | MORTAR_CLASS_RU | Standard | Long |
| CN_Mortar_SMOKE | MORTAR_CLASS_CN | Standard | Long |

---

## 6. logistics_tag 一覧（補給互換グループ）

| Tag | 用途 | 対応ConcreteWeapon |
|-----|------|-------------------|
| `RIFLE_INTERMEDIATE_NATO` | NATO中間弾 | CW_RIFLE_STD (NATO) |
| `RIFLE_INTERMEDIATE_RU` | RU中間弾 | CW_RIFLE_STD (RU) |
| `RIFLE_INTERMEDIATE_CN` | CN中間弾 | CW_RIFLE_STD (CN) |
| `AT_ROCKET_CLASS_NATO` | NATO歩兵ATロケット | CW_RPG_HEAT (NATO) |
| `AT_ROCKET_CLASS_RU` | RU歩兵ATロケット | CW_RPG_HEAT (RU) |
| `AT_ROCKET_CLASS_CN` | CN歩兵ATロケット | CW_RPG_HEAT (CN) |
| `TANK_GUN_CLASS_NATO` | NATO戦車砲弾 | CW_TANK_KE, CW_TANK_HEATMP (NATO) |
| `TANK_GUN_CLASS_RU` | RU戦車砲弾 | CW_TANK_KE, CW_TANK_HEATMP (RU) |
| `TANK_GUN_CLASS_CN` | CN戦車砲弾 | CW_TANK_KE, CW_TANK_HEATMP (CN) |
| `MORTAR_CLASS_NATO` | NATO迫撃砲弾 | CW_MORTAR_HE, CW_MORTAR_SMOKE (NATO) |
| `MORTAR_CLASS_RU` | RU迫撃砲弾 | CW_MORTAR_HE, CW_MORTAR_SMOKE (RU) |
| `MORTAR_CLASS_CN` | CN迫撃砲弾 | CW_MORTAR_HE, CW_MORTAR_SMOKE (CN) |

---

## 7. 合成後の有効Band/Tier（計算例）

### 7.1 CW_RIFLE_STD (NATO)

```
MunitionClass: SmallArms_Ball
  - VelocityBand: High
  - DispersionBand: Medium
  - RangeTier: Medium

WeaponSystemProfile: Rifle_System
  - velocity_band_adjust: 0
  - dispersion_band_adjust: 0
  - range_tier_adjust: 0

Variant: NATO_SmallArms_Ball
  - overrides: なし

→ 有効Band:
  - VelocityBand: High → 900 m/s
  - DispersionBand: Medium → 1.00 mil
  - RangeTier: Medium → max 1200m
```

### 7.2 CW_RPG_HEAT (NATO)

```
MunitionClass: Inf_AT_Rocket_HEAT
  - VelocityBand: Medium
  - DispersionBand: Loose
  - RangeTier: Medium

WeaponSystemProfile: RPG_Launcher_System
  - velocity_band_adjust: 0
  - dispersion_band_adjust: +1  → VeryLoose
  - range_tier_adjust: 0

Variant: NATO_InfAT_Rocket_HEAT
  - penetration_tier_ce: Medium → 65 rating

→ 有効Band:
  - VelocityBand: Medium → 700 m/s (BoostThenCoast)
  - DispersionBand: VeryLoose → 8.00 mil
  - RangeTier: Medium → max 1200m
  - penetration_rating: 65
```

### 7.3 CW_TANK_KE (NATO)

```
MunitionClass: Tank_KE_Penetrator
  - VelocityBand: VeryHigh
  - DispersionBand: Tight
  - RangeTier: VeryLong

WeaponSystemProfile: TankGun_System
  - velocity_band_adjust: 0
  - dispersion_band_adjust: -1  → Tight (clamp)
  - range_tier_adjust: +1       → VeryLong (clamp)

Variant: NATO_Tank_KE
  - penetration_tier_ke: Extreme → 92 rating

→ 有効Band:
  - VelocityBand: VeryHigh → 1600 m/s
  - DispersionBand: Tight → 0.30 mil
  - RangeTier: VeryLong → max 4000m
  - penetration_rating: 92
```

### 7.4 CW_MORTAR_HE (NATO)

```
MunitionClass: Mortar_HE_Frag
  - VelocityBand: Low
  - DispersionBand: VeryLoose
  - RangeTier: Long
  - conditions: RequiresObserver

WeaponSystemProfile: Mortar_Tube_System
  - band_adjustments: 全て0

Variant: NATO_Mortar_HE
  - blast_tier: High → blast_radius 35m, shock_radius 45m

→ 有効Band:
  - VelocityBand: Low → TOF coeff 0.50
  - DispersionBand: VeryLoose → sigma_base 60m @1km
  - RangeTier: Long → max 2500m
  - blast_radius: 35m
```

---

## 8. 拡張ポイント

| 拡張 | 追加方法 |
|------|---------|
| 機関銃 | `CW_MG_STD` = MG_HMG_System × MG_HMG_Ball |
| 機関砲 | `CW_AUTOCANNON_AP/HE` = Autocannon_System × Autocannon_AP/HE |
| ATGM | `CW_ATGM_HEAT` = ATGM_Launcher_System × ATGM_HEAT |
| 照明弾 | `CW_MORTAR_ILLUM` = Mortar_Tube_System × Mortar_Illumination |
| 新規格 | 新しいlogistics_tagとVariantを追加 |
| 性能差 | Variantのoverridesでpenetration_tier等を変更 |
