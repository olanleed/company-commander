# WeaponSystemProfile v0.1
## 火器システムの「撃ち方」定義

---

## 概要：ConcreteWeaponの合成

```
ConcreteWeapon = MunitionClass × MunitionVariant × WeaponSystemProfile × Ruleset
```

| レイヤー | 役割 |
|---------|------|
| **MunitionClass** | 何が起きるか（効果の型） |
| **MunitionVariant** | 規格互換（logistics_tag）＋Tier差 |
| **WeaponSystemProfile** | どう撃つか（照準・連射・移動射撃・誘導・発射サイクル） |
| **Ruleset** | Tierを具体数値へ |

---

## 1. WeaponSystemProfile スキーマ v0.1（抽象）

```yaml
weapon_system_profile_schema_v0_1:
  id: string
  mount_class: Infantry | Vehicle | Static | Variable

  supports_delivery_families: [SmallArmsRound | MG_HMG_Round | AutocannonShell | TankGunShell | Rocket_Unguided | Missile_Guided | MortarBomb]

  supported_fire_modes: [Continuous | Discrete | IndirectMission]

  fire_control_tier: Manual | Assisted | Stabilized | AdvancedFCS
  move_fire_capability: None | Limited | Full

  # 照準に関する"時間の帯"
  aim_time_tier: Instant | Short | Medium | Long | VeryLong
  reacquire_time_tier: Instant | Short | Medium | Long        # ターゲット変更・遮蔽で切れた後の再照準

  # 単発系（Discrete）のサイクル（装填・追尾・次弾）
  cycle_time_tier: VeryShort | Short | Medium | Long | VeryLong

  # 間接（IndirectMission）の設営/撤収
  setup_time_tier: Short | Medium | Long | VeryLong
  displace_time_tier: Short | Medium | Long | VeryLong
  mission_rate_tier: Low | Medium | High | VeryHigh           # 発射レートの目安（rpmをRulesetで引く）

  # "Tierを一段上下させる"補正（-1/0/+1）
  band_adjustments:
    velocity_band_adjust: -1 | 0 | +1                         # Munition側のVelocityBandを上下
    dispersion_band_adjust: -1 | 0 | +1                       # Munition側のDispersionBandを上下
    range_tier_adjust: -1 | 0 | +1                            # Munition側のRangeTierを上下

  # 直射のスナップ射撃（当たれば強いが外しやすい、等）
  snapshot_policy: Never | Allowed | Encouraged

  # 誘導（ミサイル等）
  guidance_profile: None | SACLOS | Command | FireAndForget
  guidance_requirements:
    requires_continuous_los: boolean                           # SACLOS/Commandでtrue
    operator_comm_required: boolean                            # C2/通信断で誘導が途切れる扱い

  # 被発見（射撃シグネチャ）＝情報戦に繋がる
  firing_signature_band: Low | Medium | High
```

---

## 2. Band調整のルール（共通）

WeaponSystemProfileの `band_adjustments` は、MunitionClass/Variantが持つTierを **一段上下させるだけ**（数値直書きを避ける）。

### 2.1 Bandの順序（固定）

| Band種 | 順序（左→右で増加） |
|--------|---------------------|
| VelocityBand | Low → Medium → High → VeryHigh |
| DispersionBand | Tight → Medium → Loose → VeryLoose |
| RangeTier | Close → Medium → Long → VeryLong |

- `+1` は右へ1段
- `-1` は左へ1段
- 端はクランプ（VeryHighの+1はVeryHighのまま）

---

## 3. 7つの WeaponSystemProfile v0.1（テンプレ）

"銃・砲・発射機の性格"だけを定義。

### 3.1 Rifle_System（小銃/分隊火器クラス）

```yaml
- id: Rifle_System
  mount_class: Infantry
  supports_delivery_families: [SmallArmsRound]
  supported_fire_modes: [Continuous]
  fire_control_tier: Manual
  move_fire_capability: Limited

  aim_time_tier: Short
  reacquire_time_tier: Short
  cycle_time_tier: Medium           # Continuousでは基本未使用（将来の発射バーストなどに）

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: 0
    range_tier_adjust: 0

  snapshot_policy: Encouraged
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: false, operator_comm_required: false }

  firing_signature_band: Medium
```

**使いどころ：**
- `SmallArms_Ball` と組むのが基本
- "止める"役（Suppression）として最頻出

---

### 3.2 MG_HMG_System（機関銃/重機関銃クラス：可変マウント）

```yaml
- id: MG_HMG_System
  mount_class: Variable
  supports_delivery_families: [MG_HMG_Round]
  supported_fire_modes: [Continuous]

  # 代表（車載/架台）を基準にする
  fire_control_tier: Assisted
  move_fire_capability: Limited

  aim_time_tier: Short
  reacquire_time_tier: Short

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: -1      # "据え付けでまとまりやすい"を抽象で表現
    range_tier_adjust: +1           # 一般に小銃より遠くまで"制圧"が届く

  snapshot_policy: Allowed
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: false, operator_comm_required: false }

  firing_signature_band: High
```

**使いどころ：**
- `MG_HMG_Ball` と組む
- 長距離抑圧・エリア支配を作る

> 「三脚HMG」「車載同軸」「RWS」などの差は、v0.2で `mount_variant` を追加してもOK（今はVariableで吸収）

---

### 3.3 Autocannon_System（機関砲クラス）

```yaml
- id: Autocannon_System
  mount_class: Vehicle
  supports_delivery_families: [AutocannonShell]
  supported_fire_modes: [Continuous]
  fire_control_tier: Stabilized
  move_fire_capability: Full

  aim_time_tier: Short
  reacquire_time_tier: Short

  band_adjustments:
    velocity_band_adjust: +1
    dispersion_band_adjust: -1
    range_tier_adjust: +1

  snapshot_policy: Allowed
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: true, operator_comm_required: false }

  firing_signature_band: High
```

**使いどころ：**
- `Autocannon_AP` / `Autocannon_HE` と組む
- 装甲車同士の制圧・軽装甲の無力化が作れる

---

### 3.4 TankGun_System（戦車砲クラス）

```yaml
- id: TankGun_System
  mount_class: Vehicle
  supports_delivery_families: [TankGunShell]
  supported_fire_modes: [Discrete]
  fire_control_tier: AdvancedFCS
  move_fire_capability: Full

  aim_time_tier: Medium
  reacquire_time_tier: Short
  cycle_time_tier: Medium           # "次弾まで"のテンポはここで調整

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: -1
    range_tier_adjust: +1

  snapshot_policy: Allowed
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: true, operator_comm_required: false }

  firing_signature_band: High
```

**使いどころ：**
- `Tank_KE_Penetrator` / `Tank_HEAT_MultiPurpose` と組む
- **APは直撃条件（DirectHitOnly）で対歩兵が"当たれば致命"** が成立する

---

### 3.5 RPG_Launcher_System（歩兵ATロケット：無誘導）

```yaml
- id: RPG_Launcher_System
  mount_class: Infantry
  supports_delivery_families: [Rocket_Unguided]
  supported_fire_modes: [Discrete]
  fire_control_tier: Manual
  move_fire_capability: None

  aim_time_tier: Medium
  reacquire_time_tier: Medium
  cycle_time_tier: Long              # 再装填・再照準込みのテンポ

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: +1       # "当たり所が出る"
    range_tier_adjust: 0

  snapshot_policy: Never
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: true, operator_comm_required: false }

  firing_signature_band: High
```

**使いどころ：**
- `Inf_AT_Rocket_HEAT` と組む
- **ZoneSensitive（正面/側背）** が戦術になる

---

### 3.6 ATGM_Launcher_System（対戦車誘導ミサイル）

```yaml
- id: ATGM_Launcher_System
  mount_class: Variable
  supports_delivery_families: [Missile_Guided]
  supported_fire_modes: [Discrete]
  fire_control_tier: Assisted
  move_fire_capability: None

  aim_time_tier: Long
  reacquire_time_tier: Long
  cycle_time_tier: VeryLong          # 連射は効きにくい（補給や再配置が重要）

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: -1
    range_tier_adjust: +1

  snapshot_policy: Never
  guidance_profile: SACLOS           # v0.1の既定。VariantでF&Fへ上書き可
  guidance_requirements:
    requires_continuous_los: true
    operator_comm_required: true     # 通信/統制が切れると誘導が難しくなる扱い

  firing_signature_band: High
```

**使いどころ：**
- `ATGM_HEAT` と組む
- **誘導＝強いが運用が重い（照準・通信・曝露）** を表現できる

---

### 3.7 Mortar_Tube_System（迫撃砲）

```yaml
- id: Mortar_Tube_System
  mount_class: Static
  supports_delivery_families: [MortarBomb]
  supported_fire_modes: [IndirectMission]
  fire_control_tier: Assisted
  move_fire_capability: None

  aim_time_tier: Long                # 直接照準ではなく"ミッション準備"の意味
  reacquire_time_tier: Medium

  setup_time_tier: Medium
  displace_time_tier: Medium
  mission_rate_tier: Medium          # デフォルト発射率はRulesetで引く（例：6rpm相当）

  band_adjustments:
    velocity_band_adjust: 0
    dispersion_band_adjust: 0
    range_tier_adjust: 0

  snapshot_policy: Never
  guidance_profile: None
  guidance_requirements: { requires_continuous_los: false, operator_comm_required: true }

  firing_signature_band: High
```

**使いどころ：**
- `Mortar_HE_Frag` / `Mortar_Smoke_Obscurant` と組む
- **観測リンク（RequiresObserver）** が価値を持つ（Ruleset側の call_time/sigma を使う）

---

## 4. Ruleset追補：WeaponSystem用Tier→数値テーブル

WeaponSystemProfileはTierしか持たないので、Tier→秒/rpmの変換が必要。
Ruleset v0.1への追記として定義。

```yaml
weapon_system_tier_tables_v0_1:

  aim_time_sec:
    Instant: 0.0
    Short: 1.0
    Medium: 2.5
    Long: 4.5
    VeryLong: 7.0

  reacquire_time_multiplier:          # 再照準は少し速い（係数）
    Instant: 1.0
    Short: 0.7
    Medium: 0.7
    Long: 0.8

  cycle_time_sec:                     # Discreteの「次弾まで」
    VeryShort: 3.0
    Short: 6.0
    Medium: 10.0
    Long: 15.0
    VeryLong: 25.0

  setup_time_sec:
    Short: 15
    Medium: 30
    Long: 60
    VeryLong: 120

  displace_time_sec:
    Short: 15
    Medium: 30
    Long: 60
    VeryLong: 90

  mission_rate_rpm:                   # IndirectMissionの標準発射率
    Low: 3
    Medium: 6
    High: 10
    VeryHigh: 15

  move_fire_penalties:                # 移動射撃のペナルティ（Tier→Band調整）
    None:
      aim_time_tier_increase: +1
      dispersion_band_adjust_extra: +2
    Limited:
      aim_time_tier_increase: +1
      dispersion_band_adjust_extra: +1
    Full:
      aim_time_tier_increase: 0
      dispersion_band_adjust_extra: 0
```

> 初期値なので、実装して触ってから簡単に調整可能。武器ごとの個別値を持たないので、抽象設計は崩れない。

---

## 5. 実装時の合成ルール

ConcreteWeapon生成時（または戦闘計算時）の合成手順：

### Step 1: Band取得

MunitionClass/Variantから以下を取得：
- VelocityBand
- DispersionBand
- RangeTier

### Step 2: Band調整適用

WeaponSystemProfileの `band_adjustments` と `move_fire_penalties` を適用して **有効Band** を決定。

```
effective_velocity_band = clamp(base_velocity_band + velocity_band_adjust)
effective_dispersion_band = clamp(base_dispersion_band + dispersion_band_adjust + move_penalty)
effective_range_tier = clamp(base_range_tier + range_tier_adjust)
```

### Step 3: Ruleset変換

| 項目 | 変換元 |
|------|--------|
| 射程（near/mid/max） | `range_tier_defaults_m[effective_range_tier]` |
| 散布（直射mil / 間接sigma） | `direct_dispersion_sigma_mil_1sigma[effective_dispersion_band]` |
| 代表速度/TOF | `kinematics_velocity_mps[effective_velocity_band]` |
| 効果レーティング（0–100） | `effect_level_to_rating[level]` |

### Step 4: 戦闘計算

戦闘仕様 v0.1 の式に流し込む。

---

## 6. WeaponSystemProfile 早見表

### 6.1 基本特性

| Profile | mount_class | fire_mode | fire_control | move_fire |
|---------|-------------|-----------|--------------|-----------|
| Rifle_System | Infantry | Continuous | Manual | Limited |
| MG_HMG_System | Variable | Continuous | Assisted | Limited |
| Autocannon_System | Vehicle | Continuous | Stabilized | Full |
| TankGun_System | Vehicle | Discrete | AdvancedFCS | Full |
| RPG_Launcher_System | Infantry | Discrete | Manual | None |
| ATGM_Launcher_System | Variable | Discrete | Assisted | None |
| Mortar_Tube_System | Static | IndirectMission | Assisted | None |

### 6.2 照準・サイクル時間Tier

| Profile | aim_time | reacquire | cycle_time |
|---------|----------|-----------|------------|
| Rifle_System | Short | Short | Medium |
| MG_HMG_System | Short | Short | - |
| Autocannon_System | Short | Short | - |
| TankGun_System | Medium | Short | Medium |
| RPG_Launcher_System | Medium | Medium | Long |
| ATGM_Launcher_System | Long | Long | VeryLong |
| Mortar_Tube_System | Long | Medium | - |

### 6.3 Band調整

| Profile | velocity | dispersion | range |
|---------|----------|------------|-------|
| Rifle_System | 0 | 0 | 0 |
| MG_HMG_System | 0 | -1 | +1 |
| Autocannon_System | +1 | -1 | +1 |
| TankGun_System | 0 | -1 | +1 |
| RPG_Launcher_System | 0 | +1 | 0 |
| ATGM_Launcher_System | 0 | -1 | +1 |
| Mortar_Tube_System | 0 | 0 | 0 |

### 6.4 誘導・シグネチャ

| Profile | guidance | continuous_los | comm_required | signature |
|---------|----------|----------------|---------------|-----------|
| Rifle_System | None | false | false | Medium |
| MG_HMG_System | None | false | false | High |
| Autocannon_System | None | true | false | High |
| TankGun_System | None | true | false | High |
| RPG_Launcher_System | None | true | false | High |
| ATGM_Launcher_System | SACLOS | true | true | High |
| Mortar_Tube_System | None | false | true | High |

---

## 7. Tier→数値 早見表（Ruleset追補）

### 7.1 aim_time_sec

| Tier | 秒 |
|------|-----|
| Instant | 0.0 |
| Short | 1.0 |
| Medium | 2.5 |
| Long | 4.5 |
| VeryLong | 7.0 |

### 7.2 reacquire_time_multiplier

| Tier | 係数 |
|------|------|
| Instant | 1.0 |
| Short | 0.7 |
| Medium | 0.7 |
| Long | 0.8 |

### 7.3 cycle_time_sec（Discrete）

| Tier | 秒 |
|------|-----|
| VeryShort | 3.0 |
| Short | 6.0 |
| Medium | 10.0 |
| Long | 15.0 |
| VeryLong | 25.0 |

### 7.4 setup_time_sec / displace_time_sec

| Tier | setup | displace |
|------|-------|----------|
| Short | 15 | 15 |
| Medium | 30 | 30 |
| Long | 60 | 60 |
| VeryLong | 120 | 90 |

### 7.5 mission_rate_rpm

| Tier | rpm |
|------|-----|
| Low | 3 |
| Medium | 6 |
| High | 10 |
| VeryHigh | 15 |

### 7.6 move_fire_penalties

| Capability | aim_time_increase | dispersion_adjust |
|------------|-------------------|-------------------|
| None | +1 | +2 |
| Limited | +1 | +1 |
| Full | 0 | 0 |

---

## 8. 組み合わせ例

### 例1: NATO歩兵小銃

```
MunitionClass: SmallArms_Ball
MunitionVariant: NATO_SmallArms_Ball (logistics_tag: RIFLE_INTERMEDIATE_NATO)
WeaponSystemProfile: Rifle_System

→ VelocityBand: High + 0 = High → 900 m/s
→ DispersionBand: Medium + 0 = Medium → 1.00 mil
→ RangeTier: Medium + 0 = Medium → max 1200m
→ terminal_effect.Soft.suppression: Medium → 50 rating
```

### 例2: 戦車AP vs 重装甲

```
MunitionClass: Tank_KE_Penetrator
MunitionVariant: NATO_Tank_KE (penetration_tier_ke: Extreme)
WeaponSystemProfile: TankGun_System

→ VelocityBand: VeryHigh + 0 = VeryHigh → 1600 m/s
→ DispersionBand: Tight + (-1) = Tight → 0.30 mil
→ RangeTier: VeryLong + (+1) = VeryLong → max 4000m
→ penetration_rating: 92
→ vs Heavy FRONT (armor_ke: 85): p_pen = sigmoid((92-85)/8) ≈ 0.71
```

### 例3: ATGM（SACLOS）

```
MunitionClass: ATGM_HEAT
MunitionVariant: (default)
WeaponSystemProfile: ATGM_Launcher_System

→ guidance_profile: SACLOS
→ requires_continuous_los: true
→ operator_comm_required: true
→ aim_time: Long → 4.5 sec
→ cycle_time: VeryLong → 25 sec
→ 通信断 → 誘導困難
```
