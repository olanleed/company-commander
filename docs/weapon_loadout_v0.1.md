# 武器ロードアウト規約 v0.1

---

## 1. 基本方針

### 1.1 ロードアウトは「火器（撃ち方）」と「弾薬（効果）」を分けて合成する

| レイヤー | 役割 |
|---------|------|
| **火器** | WeaponSystemProfile（照準・連射・移動射撃・誘導・発射サイクル） |
| **弾薬** | MunitionClass（効果機構）＋MunitionVariant（規格互換/Tier） |

実際に装備される"武器"は次で決まる：

```
ConcreteWeapon = MunitionClass × MunitionVariant × WeaponSystemProfile × Ruleset
```

**ロードアウト規約**は「この要素は、どのWeaponSystemProfileを何基持ち、どのMunitionClass（＝弾薬クラス）を装填可能にするか」を決めるルール。

---

## 2. ロードアウトの単位

### 2.1 ロードアウトは Element（要素）ごとに定義する

中隊は複数要素の集合なので、武器は**要素にぶら下げる**のが自然。

```
Company（中隊）＝Elementの集合
Element（要素）＝WeaponMountの集合
```

---

## 3. WeaponMount（搭載火器）モデル v0.1

### 3.1 要素が持てる WeaponMount の数（v0.1の上限）

**要素あたり最大2基**（これで現代戦の大半が表現でき、UIも破綻しない）

| Mount | 役割 |
|-------|------|
| **Mount A** | Primary（主） |
| **Mount B** | Secondary（副）／補助／専用火器（AT、同軸、追加武装など） |

> 迫撃（Mortar）はそれ自体が主装備なので Mount Aに置く。
> "自衛用小銃"はMVPでは要素の基礎火力に含める（Mountにしない）運用でもOK。

---

## 4. AmmoBin（弾薬枠）モデル v0.1

WeaponMountは「撃ち方」だけを持ち、弾薬は **AmmoBin** として管理する。

### 4.1 AmmoBinの基本

- AmmoBinは「MunitionClass（弾薬クラス）」に紐づく弾薬枠
- 同一Mountが複数種類の弾薬を撃てる場合は **AmmoBinを複数持つ**

#### 例：TankGun（Mount A）

| Bin | MunitionClass |
|-----|---------------|
| Bin1 | Tank_KE_Penetrator |
| Bin2 | Tank_HEAT_MultiPurpose |

#### 例：Mortar（Mount A）

| Bin | MunitionClass |
|-----|---------------|
| Bin1 | Mortar_HE_Frag |
| Bin2 | Mortar_Smoke_Obscurant |

---

## 5. 標準（NATO/RU/CN）と弾薬互換（LogisticsTag）

### 5.1 Standardは要素（または陣営）に付与

各Elementは `standard = NATO | RU | CN` を持つ。

### 5.2 弾薬のVariant解決ルール（規格差吸収の核）

AmmoBinは **MunitionClassだけを参照** し、実際に使う弾薬は standardに応じてVariantを自動選択する。

```
resolve_variant(munition_class, element.standard)
```

#### 例：SmallArms_Ball

| standard | 使用Variant |
|----------|-------------|
| NATO | NATO_SmallArms_Ball |
| RU | RU_SmallArms_Ball |
| CN | CN_SmallArms_Ball |

### 5.3 補給互換（LogisticsTag）

- Variantが持つ `logistics_tag` が補給の互換単位
- LOG/補給拠点はstockを `logistics_tag` 別に持つ（MVPでは"無限在庫"でもタグだけは保持する）

#### 規約（v0.1）

| ルール | 説明 |
|--------|------|
| 原則 | 同じlogistics_tagの在庫からしか補給できない |
| 例外（任意） | `cross_standard_resupply = true` をシナリオフラグで持ち、補給効率を大幅低下させる |

---

## 6. Ammo容量の抽象化

弾数を実数で持つと規格差・口径差で破綻しやすいので、v0.1では **AmmoCapacityTier** を使う。

### 6.1 AmmoCapacityTier

```
VeryLow / Low / Medium / High / VeryHigh
```

AmmoBinはこう持つ：

| フィールド | 説明 |
|-----------|------|
| `capacity_tier` | 上の段階 |
| `current_pct` | 0–100（UI・運用は％で統一） |

> "何発か"はRuleset側で必要になった段階で換算できるが、ロードアウト規約は段階の割り当てまでに留める。

---

## 7. AmmoMixPolicy（弾種配分ポリシー）

複数AmmoBinを持つMountは、初期配分を**比率（％）ではなくポリシー名**で指定する（抽象度維持）。

### 7.1 ポリシー語彙（v0.1固定）

#### TankGun用

| Policy | 説明 |
|--------|------|
| `Tank_Balanced` | 対装甲と対人の両睨み |
| `Tank_AntiArmorHeavy` | 対装甲重視 |
| `Tank_AntiInfantryHeavy` | 都市・歩兵戦想定 |

#### Mortar用

| Policy | 説明 |
|--------|------|
| `Mortar_Balanced` | HE/SMOKE均等 |
| `Mortar_HE_Heavy` | HE重視 |
| `Mortar_Smoke_Heavy` | SMOKE重視 |

#### Autocannon用（将来）

| Policy | 説明 |
|--------|------|
| `Auto_Balanced` | AP/HE半々 |
| `Auto_AP_Heavy` | AP重視 |
| `Auto_HE_Heavy` | HE重視 |

> 具体比率（例：55/45）はRulesetやUnitTypeで後から設定可能。ロードアウト規約では"名前"で留める。

---

## 8. 要素カテゴリ別 標準ロードアウト規約（テンプレ）

カテゴリに対する標準テンプレを定義。これがあると、ユニットを量産しても破綻しない。

### 8.1 INF（歩兵要素）

#### 基本形

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier |
|-------|---------------------|---------------|---------------|
| A (RIFLE) | Rifle_System | SmallArms_Ball | High |
| B (任意、いずれか1つ) | RPG_Launcher_System | Inf_AT_Rocket_HEAT | Low |
| | MG_HMG_System | MG_HMG_Ball | Medium |

#### 規約

- INFは必ず `SmallArms_Ball` を持つ（基礎戦闘力の核）
- INFがATとMGを**同時に持つのは禁止**（v0.1の"2Mount上限"の一貫性）

---

### 8.2 REC（偵察要素）

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier |
|-------|---------------------|---------------|---------------|
| A | Rifle_System | SmallArms_Ball | Medium〜High |
| B (任意) | RPG_Launcher_System | Inf_AT_Rocket_HEAT | VeryLow |

#### 規約

- RECの主価値はセンサー/報告。**火力を盛りすぎない**
- ATは自衛用のみ（VeryLow容量で抑制）

---

### 8.3 VEH（IFV/APC/軽装甲車）

v0.1では2Mountで表現を統一。

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier | Policy |
|-------|---------------------|---------------|---------------|--------|
| A (主武装) | Autocannon_System | Autocannon_AP + Autocannon_HE | Medium | Auto_Balanced |
| B (副武装、いずれか) | MG_HMG_System | MG_HMG_Ball | Medium | - |
| | ATGM_Launcher_System | ATGM_HEAT | Low | - |

#### 規約

- IFVを"万能"にしないため、Mount Bは **MGかATGMのどちらか**（v0.1）

---

### 8.4 TANK（戦車）

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier | Policy |
|-------|---------------------|---------------|---------------|--------|
| A (MAIN_GUN) | TankGun_System | Tank_KE_Penetrator + Tank_HEAT_MultiPurpose | Medium | Tank_Balanced |
| B (COAX_MG) | MG_HMG_System | MG_HMG_Ball | Medium | - |

#### 規約

- 戦車は **KEとHEAT/多目的の"複数弾種"を必須**（仕様例を自然に満たす）
- 対歩兵の"APは場合により無効"は、弾薬クラス側（DirectHitOnly）で保証済み

---

### 8.5 WEAP（迫撃要素）

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier | Policy |
|-------|---------------------|---------------|---------------|--------|
| A | Mortar_Tube_System | Mortar_HE_Frag + Mortar_Smoke_Obscurant | High | Mortar_Balanced |

#### 規約

- 迫撃は **HEとSMOKEの両方を原則持つ**
- 「観測の有無で強さが変わる」はMunitionClass側（RequiresObserver）とRuleset側（call_time/dispersion）で成立

---

### 8.6 LOG / HQ（兵站・指揮）

| Mount | WeaponSystemProfile | MunitionClass | capacity_tier |
|-------|---------------------|---------------|---------------|
| (原則なし) | - | - | - |
| A (任意、自衛用) | Rifle_System | SmallArms_Ball | VeryLow |

#### 規約

- 原則：武器は**持たない or 自衛程度**（MVPでは無装備でも可）

---

## 9. ロードアウトの"カスタム"を許す範囲（v0.1の決め）

ゲームがチープにならないよう、カスタムは制限する。

### v0.1では

- プレイヤーは**試合中にロードアウトを変えない**（補給で回復するだけ）
- ロードアウト差は **UnitTypeの固定値** または **シナリオのDoctrine** で決める

### 許可するのはこれだけ（おすすめ）

**ドクトリン選択（事前）：**

| カテゴリ | 選択肢 |
|---------|--------|
| Tank | Balanced / AntiArmorHeavy / AntiInfantryHeavy |
| Mortar | Balanced / HE_Heavy / Smoke_Heavy |
| IFV | Balanced / AP_Heavy / HE_Heavy |

---

## 10. データ雛形（抽象）

この規約がそのままデータに落ちる形（YAML例）。

```yaml
element_loadout_template_v0_1:

  # ===================
  # TANK
  # ===================
  - element_role: TANK
    standard_source: faction_standard
    mounts:
      - id: MAIN_GUN
        weapon_system_profile: TankGun_System
        ammo_mix_policy: Tank_Balanced
        ammo_bins:
          - munition_class: Tank_KE_Penetrator
            capacity_tier: Medium
          - munition_class: Tank_HEAT_MultiPurpose
            capacity_tier: Medium
      - id: COAX_MG
        weapon_system_profile: MG_HMG_System
        ammo_bins:
          - munition_class: MG_HMG_Ball
            capacity_tier: Medium

  # ===================
  # INF
  # ===================
  - element_role: INF
    standard_source: faction_standard
    mounts:
      - id: RIFLE
        weapon_system_profile: Rifle_System
        ammo_bins:
          - munition_class: SmallArms_Ball
            capacity_tier: High
      - id: AT_OR_MG
        choice_group: INF_SECONDARY
        options:
          - option_id: INF_AT
            weapon_system_profile: RPG_Launcher_System
            ammo_bins:
              - munition_class: Inf_AT_Rocket_HEAT
                capacity_tier: Low
          - option_id: INF_MG
            weapon_system_profile: MG_HMG_System
            ammo_bins:
              - munition_class: MG_HMG_Ball
                capacity_tier: Medium

  # ===================
  # REC
  # ===================
  - element_role: REC
    standard_source: faction_standard
    mounts:
      - id: RIFLE
        weapon_system_profile: Rifle_System
        ammo_bins:
          - munition_class: SmallArms_Ball
            capacity_tier: Medium
      - id: SELF_DEFENSE_AT
        optional: true
        weapon_system_profile: RPG_Launcher_System
        ammo_bins:
          - munition_class: Inf_AT_Rocket_HEAT
            capacity_tier: VeryLow

  # ===================
  # VEH (IFV)
  # ===================
  - element_role: VEH_IFV
    standard_source: faction_standard
    mounts:
      - id: MAIN_CANNON
        weapon_system_profile: Autocannon_System
        ammo_mix_policy: Auto_Balanced
        ammo_bins:
          - munition_class: Autocannon_AP
            capacity_tier: Medium
          - munition_class: Autocannon_HE
            capacity_tier: Medium
      - id: SECONDARY
        choice_group: VEH_SECONDARY
        options:
          - option_id: VEH_MG
            weapon_system_profile: MG_HMG_System
            ammo_bins:
              - munition_class: MG_HMG_Ball
                capacity_tier: Medium
          - option_id: VEH_ATGM
            weapon_system_profile: ATGM_Launcher_System
            ammo_bins:
              - munition_class: ATGM_HEAT
                capacity_tier: Low

  # ===================
  # WEAP (Mortar)
  # ===================
  - element_role: WEAP_MORTAR
    standard_source: faction_standard
    mounts:
      - id: MORTAR_TUBE
        weapon_system_profile: Mortar_Tube_System
        ammo_mix_policy: Mortar_Balanced
        ammo_bins:
          - munition_class: Mortar_HE_Frag
            capacity_tier: High
          - munition_class: Mortar_Smoke_Obscurant
            capacity_tier: Medium

  # ===================
  # LOG / HQ
  # ===================
  - element_role: LOG
    standard_source: faction_standard
    mounts:
      - id: SELF_DEFENSE
        optional: true
        weapon_system_profile: Rifle_System
        ammo_bins:
          - munition_class: SmallArms_Ball
            capacity_tier: VeryLow

  - element_role: HQ
    standard_source: faction_standard
    mounts:
      - id: SELF_DEFENSE
        optional: true
        weapon_system_profile: Rifle_System
        ammo_bins:
          - munition_class: SmallArms_Ball
            capacity_tier: VeryLow
```

---

## 11. ロードアウト規約の利点

| 利点 | 説明 |
|------|------|
| **規格差の閉じ込め** | NATO/RU/CNの規格差はMunitionVariantの差に閉じ込められる |
| **ロジック安定** | "武器の見た目や口径"を変えても、ゲームロジック（抑圧・貫徹・煙・観測）側は崩れない |
| **仕様保証** | 戦車の「KE/HEATを持つ」、迫撃の「HE/SMOKEを持つ」がロードアウト規約として保証される |
| **UI拡張性** | UIはAmmoBinの種類数だけ表示すれば良く、拡張しても破綻しにくい |

---

## 12. 早見表

### 12.1 カテゴリ別Mount構成

| カテゴリ | Mount A | Mount B |
|---------|---------|---------|
| INF | Rifle_System | RPG or MG（択一） |
| REC | Rifle_System | RPG（任意、自衛用） |
| VEH | Autocannon_System | MG or ATGM（択一） |
| TANK | TankGun_System | MG_HMG_System |
| WEAP | Mortar_Tube_System | なし |
| LOG/HQ | Rifle_System（任意） | なし |

### 12.2 カテゴリ別AmmoCapacityTier

| カテゴリ | 主武装 | 副武装 |
|---------|--------|--------|
| INF | High | Low (AT) / Medium (MG) |
| REC | Medium | VeryLow |
| VEH | Medium | Medium (MG) / Low (ATGM) |
| TANK | Medium | Medium |
| WEAP | High | - |
| LOG/HQ | VeryLow | - |

### 12.3 AmmoMixPolicy対応

| カテゴリ | Policy選択肢 |
|---------|--------------|
| TANK | Tank_Balanced / Tank_AntiArmorHeavy / Tank_AntiInfantryHeavy |
| VEH | Auto_Balanced / Auto_AP_Heavy / Auto_HE_Heavy |
| WEAP | Mortar_Balanced / Mortar_HE_Heavy / Mortar_Smoke_Heavy |
