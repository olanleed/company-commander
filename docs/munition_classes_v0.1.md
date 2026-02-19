# 弾薬クラス・規格派生仕様書 v0.1
## MunitionClass / MunitionVariant / WeaponSystemProfile

---

## 0. 方針（抽象→具体の分業）

| レイヤー | 役割 |
|---------|------|
| **MunitionClass（弾薬クラス）** | 「何が起きるか（効果機構）」を定義。規格に依存しない |
| **MunitionVariant（規格別派生）** | NATO/RU/CNなどの規格差を LogisticsTag（補給互換）＋Tier差として上書き |
| **WeaponSystemProfile（発射体側）** | 発射速度帯・精度帯・連射/単発・誘導方式など「撃ち方」を定義 |

> 弾速は"弾薬だけ"では決まらないので、弾薬と火器を分離する。これが規格差吸収に強い。

---

## 1. MVP用弾薬クラス（10種）

### 1.1 Direct（直射）

| ID | 説明 |
|----|------|
| `SmallArms_Ball` | 小銃・LMG相当の通常弾 |
| `MG_HMG_Ball` | MG/HMG通常弾 |
| `Autocannon_AP` | 機関砲 徹甲（運動エネルギー） |
| `Autocannon_HE` | 機関砲 榴弾（爆風/破片 or 空中炸裂の入口） |
| `Tank_KE_Penetrator` | 戦車砲AP（運動エネルギー徹甲） |
| `Tank_HEAT_MultiPurpose` | 戦車砲HEAT/多目的（成形炸薬） |
| `Inf_AT_Rocket_HEAT` | 歩兵ATロケット（RPG系） |

### 1.2 Guided（誘導）

| ID | 説明 |
|----|------|
| `ATGM_HEAT` | 対戦車誘導（成形炸薬、トップアタック等は派生で） |

### 1.3 Indirect（間接）

| ID | 説明 |
|----|------|
| `Mortar_HE_Frag` | 迫撃HE（榴弾/破片） |
| `Mortar_Smoke_Obscurant` | 迫撃煙 |

---

## 2. Tier/Tag 辞書（数値を置かないための語彙）

### 2.1 Tier（段階）

| カテゴリ | 値 |
|---------|-----|
| **EffectLevel** | `None` / `Low` / `Medium` / `High` / `Extreme` |
| **RangeTier** | `Close` / `Medium` / `Long` / `VeryLong` |
| **VelocityBand** | `Low` / `Medium` / `High` / `VeryHigh` |
| **DispersionBand** | `Tight` / `Medium` / `Loose` / `VeryLoose` |
| **SmokeTier** | `Thin` / `Standard` / `Thick` |
| **DurationTier** | `Short` / `Standard` / `Long` |

### 2.2 TargetClass（既存仕様と一致）

| ID | 説明 |
|----|------|
| `Soft` | 軟目標（歩兵等） |
| `Armored_Light` | 軽装甲 |
| `Armored_Heavy` | 重装甲 |
| `Fortified` | 掩体・陣地 |

### 2.3 条件（"場合によっては無効"を抽象で表す）

| ID | 説明 |
|----|------|
| `DirectHitOnly` | 直撃でのみ大ダメージ（例：AP→歩兵） |
| `NearMissShock` | 近傍弾は抑圧中心 |
| `ZoneSensitive` | 命中ゾーンで貫徹が変わる（FRONT/SIDE/REAR/TOP） |
| `RequiresObserver` | 観測リンク必須（間接） |
| `ObscuresLoS` | 煙幕のように視界を落とす |

### 2.4 LogisticsTag（規格差＝互換性の箱）

口径を固定せず「互換ファミリー」だけをタグ化する。

| タグ | 説明 |
|-----|------|
| `RIFLE_INTERMEDIATE_<STD>` | 中間弾クラス（STD: NATO/RU/CN等） |
| `RIFLE_FULLPOWER_<STD>` | フルパワー弾クラス |
| `HMG_CLASS_<STD>` | 重機関銃弾クラス |
| `AUTOCANNON_CLASS_<STD>` | 機関砲弾クラス |
| `TANK_GUN_CLASS_<STD>` | 戦車砲弾クラス |
| `MORTAR_CLASS_<STD>` | 迫撃砲弾クラス |
| `AT_ROCKET_CLASS_<STD>` | 対戦車ロケットクラス |
| `ATGM_CLASS_<STD>` | 対戦車誘導ミサイルクラス |

> 「補給互換」「陣営ごとの弾薬供給」を繋げられる。性能差がなくても、互換が違うだけでゲーム上の意味が出る。

---

## 3. MunitionClass 定義（抽象雛形データ）

各クラスは **"効果の型"** を持ち、数値は持たない。
実数値は Ruleset（Tier→数値）と WeaponSystemProfile（撃ち方）で具体化する。

```yaml
munition_classes_v0_1:

  - id: SmallArms_Ball
    delivery_family: SmallArmsRound
    warhead_type: KE_Ball
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Continuous
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: High
      range_tier: Medium
    accuracy_profile:
      dispersion_band: Medium
      moving_target_penalty: Medium
      aiming_time_sensitivity: Medium
    terminal_effect:
      Soft:          { strength: Medium, suppression: Medium }
      Armored_Light: { strength: None,   suppression: Low,  conditions: [ "suppression_cap_low" ] }
      Armored_Heavy: { strength: None,   suppression: Low,  conditions: [ "suppression_cap_low" ] }
      Fortified:     { strength: Low,    suppression: Low }

  - id: MG_HMG_Ball
    delivery_family: MG_HMG_Round
    warhead_type: KE_Ball
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Continuous
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: High
      range_tier: Long
    accuracy_profile:
      dispersion_band: Medium
      moving_target_penalty: Medium
      aiming_time_sensitivity: High
    terminal_effect:
      Soft:          { strength: Medium, suppression: High }
      Armored_Light: { strength: None,   suppression: Low,  conditions: [ "suppression_cap_low" ] }
      Armored_Heavy: { strength: None,   suppression: Low,  conditions: [ "suppression_cap_low" ] }
      Fortified:     { strength: Low,    suppression: Medium }

  - id: Autocannon_AP
    delivery_family: AutocannonShell
    warhead_type: KE_AP
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Continuous
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: VeryHigh
      range_tier: Long
    accuracy_profile:
      dispersion_band: Tight
      moving_target_penalty: Low
      aiming_time_sensitivity: Medium
    armor_interaction: ZoneSensitive
    terminal_effect:
      Soft:          { strength: Medium, suppression: High, conditions: [ NearMissShock ] }
      Armored_Light: { subsystem: High,  suppression: High, conditions: [ ZoneSensitive ] }
      Armored_Heavy: { subsystem: Medium, suppression: High, conditions: [ ZoneSensitive ] }
      Fortified:     { strength: Medium, suppression: High }

  - id: Autocannon_HE
    delivery_family: AutocannonShell
    warhead_type: HE_Frag
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Continuous
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: High
      range_tier: Long
    accuracy_profile:
      dispersion_band: Medium
      moving_target_penalty: Medium
      aiming_time_sensitivity: Medium
    terminal_effect:
      Soft:          { strength: High,   suppression: High }
      Armored_Light: { strength: Low,    suppression: Medium }
      Armored_Heavy: { strength: None,   suppression: Low }
      Fortified:     { strength: Medium, suppression: High }
    optional_extensions:
      - warhead_type: HE_Airburst        # v0.2以降：信管をProgrammableにして拡張可能

  - id: Tank_KE_Penetrator
    delivery_family: TankGunShell
    warhead_type: KE_AP
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Discrete
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: VeryHigh
      range_tier: VeryLong
    accuracy_profile:
      dispersion_band: Tight
      moving_target_penalty: Low
      aiming_time_sensitivity: Medium
    armor_interaction: ZoneSensitive
    terminal_effect:
      Soft:          { strength: Extreme, suppression: Medium, conditions: [ DirectHitOnly, NearMissShock ] }
      Armored_Light: { subsystem: Extreme, suppression: High,  conditions: [ ZoneSensitive ] }
      Armored_Heavy: { subsystem: Extreme, suppression: High,  conditions: [ ZoneSensitive ] }
      Fortified:     { strength: High,    suppression: High }

  - id: Tank_HEAT_MultiPurpose
    delivery_family: TankGunShell
    warhead_type: CE_HEAT
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Discrete
    kinematics_profile:
      flight_model: Direct_Ballistic
      velocity_band: High
      range_tier: Long
    accuracy_profile:
      dispersion_band: Tight
      moving_target_penalty: Low
      aiming_time_sensitivity: Medium
    armor_interaction: ZoneSensitive
    terminal_effect:
      Soft:          { strength: High,  suppression: Extreme, conditions: [ NearMissShock ] }
      Armored_Light: { subsystem: High, suppression: High,    conditions: [ ZoneSensitive ] }
      Armored_Heavy: { subsystem: Medium, suppression: High,  conditions: [ ZoneSensitive ] }
      Fortified:     { strength: High,  suppression: High }

  - id: Inf_AT_Rocket_HEAT
    delivery_family: Rocket_Unguided
    warhead_type: CE_HEAT
    fuze_type: Impact
    guidance_type: Unguided
    fire_mode: Discrete
    kinematics_profile:
      flight_model: BoostThenCoast
      velocity_band: Medium
      range_tier: Medium
    accuracy_profile:
      dispersion_band: Loose
      moving_target_penalty: High
      aiming_time_sensitivity: High
    armor_interaction: ZoneSensitive
    terminal_effect:
      Soft:          { strength: Medium, suppression: High,    conditions: [ NearMissShock ] }
      Armored_Light: { subsystem: High,  suppression: High,    conditions: [ ZoneSensitive ] }
      Armored_Heavy: { subsystem: Medium, suppression: High,   conditions: [ ZoneSensitive ] }
      Fortified:     { strength: Medium, suppression: High }

  - id: ATGM_HEAT
    delivery_family: Missile_Guided
    warhead_type: CE_HEAT
    fuze_type: Impact
    guidance_type: Guided
    fire_mode: Discrete
    kinematics_profile:
      flight_model: Guided_Cruise
      velocity_band: Medium
      range_tier: VeryLong
    accuracy_profile:
      dispersion_band: Tight
      moving_target_penalty: Low
      aiming_time_sensitivity: Medium
    armor_interaction: ZoneSensitive
    terminal_effect:
      Soft:          { strength: High, suppression: High,      conditions: [ NearMissShock ] }
      Armored_Light: { subsystem: Extreme, suppression: High,  conditions: [ ZoneSensitive ] }
      Armored_Heavy: { subsystem: High, suppression: High,     conditions: [ ZoneSensitive ] }
      Fortified:     { strength: High, suppression: High }
    optional_extensions:
      - attack_profile: TopAttackProfile   # v0.2以降：TopAttackをVariantで付与可能

  - id: Mortar_HE_Frag
    delivery_family: MortarBomb
    warhead_type: HE_Frag
    fuze_type: ImpactOrTime
    guidance_type: Unguided
    fire_mode: IndirectMission
    kinematics_profile:
      flight_model: Arced_Ballistic
      velocity_band: Low
      range_tier: Long
    accuracy_profile:
      dispersion_band: VeryLoose
      moving_target_penalty: High
      aiming_time_sensitivity: Medium
    terminal_effect:
      Soft:          { strength: High,    suppression: Extreme }
      Armored_Light: { strength: Low,     suppression: High }
      Armored_Heavy: { strength: None,    suppression: Medium }
      Fortified:     { strength: Medium,  suppression: High }
    conditions:
      - RequiresObserver   # 観測リンクで「反応/散布」が改善（数値化はRuleset側）

  - id: Mortar_Smoke_Obscurant
    delivery_family: MortarBomb
    warhead_type: Smoke_Obscurant
    fuze_type: Time
    guidance_type: Unguided
    fire_mode: IndirectMission
    kinematics_profile:
      flight_model: Arced_Ballistic
      velocity_band: Low
      range_tier: Long
    accuracy_profile:
      dispersion_band: VeryLoose
      moving_target_penalty: High
      aiming_time_sensitivity: Medium
    terminal_effect:
      Soft:          { strength: None, suppression: None, special: { smoke: Standard, duration: Long, conditions: [ ObscuresLoS ] } }
      Armored_Light: { strength: None, suppression: None, special: { smoke: Standard, duration: Long, conditions: [ ObscuresLoS ] } }
      Armored_Heavy: { strength: None, suppression: None, special: { smoke: Standard, duration: Long, conditions: [ ObscuresLoS ] } }
      Fortified:     { strength: None, suppression: None, special: { smoke: Standard, duration: Long, conditions: [ ObscuresLoS ] } }
```

---

## 4. MunitionVariant（規格別派生）の雛形

Variantは「同じ弾薬クラスの派生」。ここでNATO/RU/CN差を吸収する。

### 4.1 スキーマ定義

```yaml
variant_schema_v0_1:
  - id: <string>
    base_class_id: <MunitionClass.id>
    standard: NATO | RU | CN
    logistics_tag: <string>                # 互換の箱
    overrides:
      range_tier: <RangeTier?>
      velocity_band: <VelocityBand?>
      dispersion_band: <DispersionBand?>
      penetration_tier_ke: <EffectLevel?>  # KE_APの"貫徹Tier"として扱う（数値はRuleset）
      penetration_tier_ce: <EffectLevel?>  # CE_HEATの"貫徹Tier"
      blast_tier: <EffectLevel?>           # HE_Frag等の"爆風/破片Tier"
      smoke_tier: <SmokeTier?>
      duration_tier: <DurationTier?>
      guidance_profile: <optional>         # SACLOS / F&F / TopAttack等（必要なら）
    reference:
      label: <optional>                    # UI/ログ用（例："intermediate rifle standard"）
```

> 数値は入れない。Tier→数値は Ruleset によって決まる設計。

---

## 5. 規格別Variant例（NATO/RU/CN × 各2つ）

規格差＝互換性（logistics_tag）の違いを成立させる最小例。
性能差は必要になった段階でTier差を入れる。

### 5.1 NATO

```yaml
variants_example:
  - id: NATO_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: NATO
    logistics_tag: RIFLE_INTERMEDIATE_NATO
    overrides:
      velocity_band: High
      dispersion_band: Medium
      range_tier: Medium
    reference: { label: "NATO intermediate rifle standard" }

  - id: NATO_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: NATO
    logistics_tag: TANK_GUN_CLASS_NATO
    overrides:
      velocity_band: VeryHigh
      dispersion_band: Tight
      range_tier: VeryLong
      penetration_tier_ke: Extreme
    reference: { label: "NATO tank KE standard" }
```

### 5.2 ロシア

```yaml
  - id: RU_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: RU
    logistics_tag: RIFLE_INTERMEDIATE_RU
    overrides:
      velocity_band: High
      dispersion_band: Medium
      range_tier: Medium
    reference: { label: "RU intermediate rifle standard" }

  - id: RU_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: RU
    logistics_tag: TANK_GUN_CLASS_RU
    overrides:
      velocity_band: VeryHigh
      dispersion_band: Tight
      range_tier: VeryLong
      penetration_tier_ke: Extreme
    reference: { label: "RU tank KE standard" }
```

### 5.3 中国

```yaml
  - id: CN_SmallArms_Ball
    base_class_id: SmallArms_Ball
    standard: CN
    logistics_tag: RIFLE_INTERMEDIATE_CN
    overrides:
      velocity_band: High
      dispersion_band: Medium
      range_tier: Medium
    reference: { label: "CN intermediate rifle standard" }

  - id: CN_Tank_KE
    base_class_id: Tank_KE_Penetrator
    standard: CN
    logistics_tag: TANK_GUN_CLASS_CN
    overrides:
      velocity_band: VeryHigh
      dispersion_band: Tight
      range_tier: VeryLong
      penetration_tier_ke: Extreme
    reference: { label: "CN tank KE standard" }
```

---

## 6. WeaponSystemProfile（火器テンプレ）

弾薬と火器を分離することで規格差を綺麗に扱う。

### 6.1 火器システムの分類

| ID | 説明 |
|----|------|
| `Rifle_System` | 小銃/分隊火器 |
| `HMG_System` | 重機関銃 |
| `Autocannon_System` | 機関砲 |
| `TankGun_System` | 戦車砲 |
| `RPG_Launcher_System` | 無誘導AT |
| `ATGM_Launcher_System` | 誘導AT |
| `Mortar_Tube_System` | 迫撃砲 |

### 6.2 WeaponSystemProfileが持つもの

| フィールド | 説明 |
|-----------|------|
| `rate_of_fire_band` | 発射速度帯 |
| `aim_time_band` | 照準時間帯 |
| `dispersion_modifier_band` | 散布補正帯 |
| `muzzle_velocity_modifier_band` | 弾速補正帯 |
| `guidance_profile` | SACLOS / F&F / TopAttack等 |

> 数値は後でRulesetに入れる。

---

## 7. ConcreteWeapon の合成

ゲームで実際に撃つ武器の構成：

```
ConcreteWeapon = MunitionClass × MunitionVariant × WeaponSystemProfile
```

| レイヤー | 役割 |
|---------|------|
| **MunitionClass** | 何が起きるか（効果機構） |
| **MunitionVariant** | 互換とTier |
| **WeaponSystemProfile** | 撃ち方（弾速/精度/連射/誘導） |

### 規格差の吸収

| 差異 | 吸収先 |
|------|--------|
| 互換（補給） | Variant の `logistics_tag` |
| 性能差 | Variant Tier + WeaponSystem補正 |

---

## 8. terminal_effect 早見表

### 8.1 対Soft（歩兵等）

| 弾薬クラス | strength | suppression | 条件 |
|-----------|----------|-------------|------|
| SmallArms_Ball | Medium | Medium | - |
| MG_HMG_Ball | Medium | High | - |
| Autocannon_AP | Medium | High | NearMissShock |
| Autocannon_HE | High | High | - |
| Tank_KE_Penetrator | Extreme | Medium | DirectHitOnly, NearMissShock |
| Tank_HEAT_MultiPurpose | High | Extreme | NearMissShock |
| Inf_AT_Rocket_HEAT | Medium | High | NearMissShock |
| ATGM_HEAT | High | High | NearMissShock |
| Mortar_HE_Frag | High | Extreme | RequiresObserver |
| Mortar_Smoke_Obscurant | None | None | ObscuresLoS |

### 8.2 対Armored_Heavy（重装甲）

| 弾薬クラス | subsystem/strength | suppression | 条件 |
|-----------|-------------------|-------------|------|
| SmallArms_Ball | None | Low | suppression_cap_low |
| MG_HMG_Ball | None | Low | suppression_cap_low |
| Autocannon_AP | subsystem: Medium | High | ZoneSensitive |
| Autocannon_HE | None | Low | - |
| Tank_KE_Penetrator | subsystem: Extreme | High | ZoneSensitive |
| Tank_HEAT_MultiPurpose | subsystem: Medium | High | ZoneSensitive |
| Inf_AT_Rocket_HEAT | subsystem: Medium | High | ZoneSensitive |
| ATGM_HEAT | subsystem: High | High | ZoneSensitive |
| Mortar_HE_Frag | None | Medium | - |
| Mortar_Smoke_Obscurant | None | None | ObscuresLoS |

---

## 9. 拡張ポイント

| 拡張 | 追加方法 |
|------|---------|
| 空中炸裂 | `Autocannon_HE` に `HE_Airburst` + `Programmable` fuze を追加 |
| トップアタック | `ATGM_HEAT` Variant に `TopAttackProfile` を付与 |
| 新規格 | 新しい `logistics_tag` と Variant を追加 |
| 砲兵 | `ArtilleryShell` delivery + 火力支援システム |
| 照明弾 | `Illumination` warhead + 夜戦システム |
