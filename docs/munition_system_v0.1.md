# 弾薬システム仕様書 v0.1
## 規格非依存の抽象弾薬分類

---

## 設計思想

弾薬を"口径"で分類すると規格差で崩れるため、**Delivery（運び方）× Warhead（効果機構）× Fuze/Guidance（信管/誘導）** の3軸で分類する。

継承ツリーを深くすると規格差で破綻しやすいので、**コンポジション（合成）** で設計する。

---

## 1. 弾薬の3軸分類

### 1.1 Delivery（運び方）ファミリー

| ID | 説明 |
|----|------|
| `SmallArmsRound` | 小銃・分隊火器の弾（単発・連射） |
| `MG_HMG_Round` | 機関銃・重機関銃の弾 |
| `AutocannonShell` | 機関砲（20–30mm級を含む概念） |
| `TankGunShell` | 戦車砲/大口径直射砲 |
| `Rocket_Unguided` | 無誘導ロケット（RPG等） |
| `Missile_Guided` | 誘導ミサイル（ATGM等） |
| `Grenade_HandOrLauncher` | 手榴弾/グレラン弾 |
| `MortarBomb` | 迫撃砲弾 |
| `ArtilleryShell` | 榴弾砲/ロケット砲弾（将来） |
| `Mine` | 対人/対戦車地雷（将来） |

> 「何mmか」は一切決めない。規格差は"派生バリアント"側に押し込む。

### 1.2 Warhead（効果機構）タイプ

| ID | 説明 |
|----|------|
| `KE_Ball` | 運動エネルギー弾（通常弾・ボール） |
| `KE_AP` | 運動エネルギー徹甲（AP/APDS/APFSDSを含む概念） |
| `CE_HEAT` | 成形炸薬（HEAT/RPG/ATGM弾頭） |
| `CE_EFP` | EFP/成形破片（対装甲の別系統。将来追加でもOK） |
| `HE_Frag` | 榴弾・破片（爆風＋破片） |
| `HE_Airburst` | 空中炸裂（近接信管・時限・プログラマブル含む概念） |
| `Thermobaric` | サーモバリック（閉鎖空間・掩体に強い） |
| `Incendiary` | 焼夷（継続効果用） |
| `Smoke_Obscurant` | 煙幕（可視遮断/隠蔽） |
| `Illumination` | 照明弾（夜戦拡張用） |

### 1.3 Fuze / Guidance（信管・誘導）タイプ

#### 信管（Fuze）

| ID | 説明 |
|----|------|
| `Impact` | 着発 |
| `Delay` | 遅延信管（壁抜き/掩体内効果） |
| `Time` | 時限 |
| `Proximity` | 近接 |
| `Programmable` | 空中炸裂など任意設定 |

#### 誘導（Guidance）

| ID | 説明 |
|----|------|
| `Unguided` | 無誘導 |
| `Command_SACLOS` | 指令誘導（有線/無線） |
| `SemiActive` | レーザー等の半能動 |
| `FireAndForget` | 自己誘導 |
| `TopAttackProfile` | トップアタック（弾頭の当たり方プロファイル） |

> 「戦車AP」「戦車HEAT」「迫撃HE」などは、これらの組み合わせで表現する。
> 規格が違ってもクラスは同じで済むのが狙い。

---

## 2. 抽象クラス設計（コンポジション）

### 2.1 MunitionClass（最上位）

`MunitionClass` は「ゲーム内の弾薬種（概念）」で、口径や型式名は持たない。

#### 必須フィールド

| フィールド | 説明 |
|-----------|------|
| `delivery_family` | 1.1のDeliveryファミリー |
| `warhead_type` | 1.2のWarheadタイプ |
| `fuze_type` | 1.3のFuzeタイプ |
| `guidance_type` | 1.3のGuidanceタイプ |
| `fire_mode` | `Continuous` / `Discrete` / `IndirectMission` |
| `kinematics_profile` | 弾速やTOFの段階プロファイル |
| `accuracy_profile` | 散布の段階プロファイル |
| `terminal_effect_profile` | Soft/Armoredなどへの効果の型 |

> これが"規格に依存しない"コア。NATO/ロシア/中国でも同じMunitionClassを使える。

### 2.2 KinematicsProfile（弾速など：段階プロファイル）

数値を固定せず、速度帯・弾道の性質を段階で持つ。

| フィールド | 値 |
|-----------|-----|
| `velocity_band` | `Low` / `Medium` / `High` / `VeryHigh` |
| `flight_model` | `Direct_Ballistic` / `Arced_Ballistic` / `BoostThenCoast` / `Guided_Cruise` |

| flight_model | 説明 |
|-------------|------|
| `Direct_Ballistic` | 直射に近い |
| `Arced_Ballistic` | 迫撃・榴弾の山なり |
| `BoostThenCoast` | RPG系（初速→巡航） |
| `Guided_Cruise` | ATGM系 |

> 各規格が「代表値」を持つVariantで数値を上書き可能。

### 2.3 AccuracyProfile（散布：段階プロファイル）

| フィールド | 値 |
|-----------|-----|
| `dispersion_band` | `Tight` / `Medium` / `Loose` / `VeryLoose` |
| `moving_target_penalty_band` | `Low` / `Medium` / `High` |
| `aiming_time_sensitivity` | `Low` / `Medium` / `High` |

> `aiming_time_sensitivity`：急いで撃つと散る、の強さ。

### 2.4 TerminalEffectProfile（効果）

弾薬の効果は「何が起きるか」を抽象化して持つ。

#### 目標クラス

| ID | 説明 |
|----|------|
| `Soft` | 軟目標（歩兵等） |
| `Armored_Light` | 軽装甲 |
| `Armored_Heavy` | 重装甲 |
| `Fortified` | 掩体・陣地 |

#### 効果チャンネル

| チャンネル | 説明 |
|-----------|------|
| `strength_damage` | 損耗 |
| `suppression` | 抑圧 |
| `subsystem_damage` | ARMOREDのみ（mobility / firepower / sensors） |
| `special` | 煙、照明、焼夷、地形効果 |

#### 効果レベル（数値ではなく段階）

```
None / Low / Medium / High / Extreme
```

#### 効果例

| 弾薬 | 対Soft | 対Armored | 抑圧 |
|------|--------|-----------|------|
| 小銃 | strength=Medium | strength=None | Low |
| RPG | blast=Medium | subsystem=High | High |
| 戦車AP | DirectHitのみHigh | subsystem=Extreme | Medium |

---

## 3. 派生の作法（弾薬カタログからクラスを具体化）

### 手順A：抽象クラスを作る（国を意識しない）

| クラス名 | 構成 |
|---------|------|
| `SmallArms_Ball` | SmallArmsRound × KE_Ball × Impact × Unguided |
| `Inf_AT_Rocket_HEAT` | Rocket_Unguided × CE_HEAT × Impact × Unguided |
| `Tank_KE_Penetrator` | TankGunShell × KE_AP × Impact × Unguided |
| `Tank_HEAT_MultiPurpose` | TankGunShell × CE_HEAT × Impact × Unguided |
| `Mortar_HE_Frag` | MortarBomb × HE_Frag × Time/Impact × Unguided |
| `Mortar_Smoke` | MortarBomb × Smoke_Obscurant × Time × Unguided |

> ここまでが「ゲームのロジックが知るべき弾薬」。

### 手順B：規格差は "Variant" で表現する

`MunitionVariant`（国/規格/装備系統ごとの派生）を、MunitionClassにぶら下げる。
Variantは「同じ弾薬クラスだが、性能プロファイルが違う」だけ。

#### Variantが上書きできる項目

| 項目 | 説明 |
|------|------|
| `velocity_band` | 同じクラスでも速い/遅い |
| `dispersion_band` | 散布の違い |
| `range_band_profile` | 射程帯の段階 |
| `penetration_tier` | KE/CEの貫徹段階 |
| `blast_tier` | 爆風・破片の段階 |
| `smoke_tier` | 煙の濃さ・持続の段階 |
| `logistics_tag` | 補給上の規格（ここに"口径ファミリー"を持たせる） |

> NATO/ロシア/中国で"規格が違う"ことは `logistics_tag`（補給）と性能Tierの違いとして自然に表現できる。
> コアの戦闘ロジックは一切変えずに済む。

---

## 4. MVP用弾薬クラスセット

現代陸戦・中隊規模・迫撃と装甲戦がある範囲で最低限必要なクラス。

### 4.1 直射（Direct / Continuous or Discrete）

| クラス | 説明 |
|--------|------|
| `SmallArms_Ball` | 小銃/LMGの通常弾 |
| `MG_HMG_Ball` | 機関銃/重機の通常弾 |
| `Autocannon_AP` | 機関砲徹甲（KE_AP） |
| `Autocannon_HE` | 機関砲榴弾（HE_Frag/HE_Airburstの入口） |
| `Tank_KE_Penetrator` | 戦車AP系（KE_AP） |
| `Tank_HEAT_MultiPurpose` | 戦車HEAT/多目的（CE_HEAT） |
| `Inf_AT_Rocket_HEAT` | RPG系（CE_HEAT） |
| `ATGM_HEAT` | 誘導対戦車（CE_HEAT、Guided） |

### 4.2 間接（Indirect Mission）

| クラス | 説明 |
|--------|------|
| `Mortar_HE_Frag` | 迫撃HE |
| `Mortar_Smoke` | 迫撃煙 |

> これが弾薬クラスの最低ライン。必要に応じて照明、空中炸裂、サーモバリック等を追加。

---

## 5. 具体例：抽象クラスでの表現

### 歩兵 → 歩兵（小銃弾、有効）

`SmallArms_Ball` の TerminalEffect：

| 目標 | strength_damage | suppression |
|------|-----------------|-------------|
| Soft | Medium | Medium |
| Armored | None | Low（上限設定） |

### 歩兵 → 戦車・装甲車（小銃弾、無効）

同じく `SmallArms_Ball`：Armoredへの `strength_damage=None` を仕様として固定。

### 歩兵 → 戦車・装甲車（対戦車ロケット、被弾箇所により有効）

`Inf_AT_Rocket_HEAT`：

- Armoredに対して `penetration_tier` を持つ
- **HitZone（FRONT/SIDE/REAR/TOP）** で `p_pen` が変わる
- 抜けたら `subsystem_damage`（mobility/firepower/sensors）が High

### 戦車 → 歩兵（HEAT vs AP）

**Tank_HEAT_MultiPurpose：**
- Softに対して `blast_tier=High`（近接で強い）

**Tank_KE_Penetrator：**
- Softに対して **「DirectHit条件」** のみ `strength_damage=High`
- 外れは `suppression` 中心
- "APは当たると強いが、外れると無効寄り"が抽象で表現できる

---

## 6. データ構造例（疑似コード）

```gdscript
# MunitionClass定義
class_name MunitionClass
extends Resource

@export var id: String
@export var delivery_family: String  # SmallArmsRound, TankGunShell, etc.
@export var warhead_type: String     # KE_Ball, CE_HEAT, HE_Frag, etc.
@export var fuze_type: String        # Impact, Delay, Time, etc.
@export var guidance_type: String    # Unguided, Command_SACLOS, etc.
@export var fire_mode: String        # Continuous, Discrete, IndirectMission

@export var kinematics: KinematicsProfile
@export var accuracy: AccuracyProfile
@export var terminal_effects: Dictionary  # target_class -> EffectProfile
```

```gdscript
# KinematicsProfile
class_name KinematicsProfile
extends Resource

@export var velocity_band: String    # Low, Medium, High, VeryHigh
@export var flight_model: String     # Direct_Ballistic, Arced_Ballistic, etc.
```

```gdscript
# AccuracyProfile
class_name AccuracyProfile
extends Resource

@export var dispersion_band: String           # Tight, Medium, Loose, VeryLoose
@export var moving_target_penalty_band: String # Low, Medium, High
@export var aiming_time_sensitivity: String    # Low, Medium, High
```

```gdscript
# TerminalEffectProfile（目標クラスごと）
class_name TerminalEffectProfile
extends Resource

@export var strength_damage: String   # None, Low, Medium, High, Extreme
@export var suppression: String       # None, Low, Medium, High, Extreme
@export var subsystem_damage: String  # None, Low, Medium, High, Extreme
@export var special: String           # smoke, illumination, incendiary, etc.
```

```gdscript
# MunitionVariant（規格派生）
class_name MunitionVariant
extends Resource

@export var base_class: MunitionClass
@export var variant_id: String
@export var logistics_tag: String     # 補給上の規格（例：5.56x45_NATO）

# 上書き可能なプロファイル
@export var velocity_band_override: String
@export var dispersion_band_override: String
@export var penetration_tier: String
@export var blast_tier: String
@export var range_band_profile: Array[String]
```

---

## 7. 拡張ポイント

| 拡張 | 追加するもの |
|------|-------------|
| 空中炸裂 | `HE_Airburst` + `Programmable` fuze |
| サーモバリック | `Thermobaric` warhead |
| 照明弾 | `Illumination` warhead + 夜戦システム |
| 地雷 | `Mine` delivery + 設置/起爆システム |
| 砲兵 | `ArtilleryShell` + 火力支援システム |
| トップアタック | `TopAttackProfile` guidance |
