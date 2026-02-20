# 戦闘仕様 v0.1

---

## 1. 前提とゴール

### 1.1 前提（既定仕様との整合）

| 項目 | 値 |
|------|-----|
| シミュレーション更新 | **10Hz（dt=0.1秒）** |
| 状態値 | Strength(0–100) / Suppression(0–100) / Cohesion(0–100) / Fatigue(0–100) / Ammo%(0–100) |

**抑圧閾値：**

| 閾値 | 状態 |
|------|------|
| 40 | Suppressed |
| 70 | Pinned |
| 90 | Broken |

**視界仕様 v0.1：**
- Hard Block（建物・崖）と Soft Occlusion（森林・煙）
- 透過率 `T_LoS`（森林と煙の合成）
- `T_LoS < 0.10` は視覚観測・直射とも実質不可

**遮蔽仕様 v0.1：**
- 地形別 `M_cover_DF` / `M_cover_IF`
- Dig-in係数（DF×0.70、IF×0.90）
- 分散モードのIF耐性（Column 1.15 / Deployed 1.00 / Dispersed 0.85）

### 1.2 戦闘の狙い（ゲームとしての"正しい勝ち方"）

- **撃破より先に抑圧で止める**のが基本
- "見えていない敵"には無理に突っ込まず、偵察・煙・間接で窓を作る
- 拠点戦は **歩兵が取る／車両は支援と妨害**（制圧仕様と整合）

---

## 2. 戦闘で使う固定パラメータ（UnitType側）

### 2.1 武器セット（v0.1は「要素あたり最大2系統」）

各要素（ElementType）は最大2つの武器プロファイルを持つ：

| 武器 | 対象 |
|------|------|
| **DirectWeapon**（直射） | 必須 |
| **IndirectWeapon**（間接） | WEAP等のみ（任意） |

**武器プロファイルの必須フィールド：**

```
min_range_m
max_range_m
range_band_thresholds_m     # Near/Mid/Farの境界（武器ごとでOK）
lethality[band][target_class]        # 0–100レーティング
suppression_power[band]              # 0–100レーティング
threat_class                # SmallArms / Autocannon / HEFrag / AT
ammo_endurance_min          # 連続交戦（強度1.0）で何分で弾切れ相当になるか

# WEAPのみ
setup_time_sec
displace_time_sec
requires_observer
```

### 2.2 ターゲットクラス（固定）

| クラス | 対象 |
|--------|------|
| **Soft** | 歩兵等 |
| **Light** | 装輪・軽装甲 |
| **Heavy** | 戦車等 |
| **Fortified** | 陣地・建物内扱い |

### 2.3 防護（target側）

```
vulnerability_vs[threat_class]    # 係数。1.0が基準、>1で脆い、<1で強い
```

---

## 3. シミュレーションの更新順（1 tick = 0.1秒）

同じ順序で処理するとデバッグ・リプレイ・AARが安定する。

```
1. 命令状態更新（Queued→Ack→Exec、通信状態反映）
2. ターゲット選定（命令/SOP/ROEにより決定）
3. LoS評価（Hard Block→Soft Occlusion、T_LoS算出）
4. 射撃解決（直射→間接の順、各種係数でdSupp/dDmg計算）
5. 状態更新
   - Suppression増減、Strength減少
   - Cohesion/Fatigue更新
   - Ammo消費
6. 閾値処理（Suppressed/Pinned/Brokenの遷移、Broken時SOP）
7. 情報更新（観測の確度更新、発砲シグネチャ反映）
```

---

## 4. 射程帯（Range Bands）v0.1

武器ごとに境界が違ってよいが、MVPでは以下を推奨：

| 帯域 | 距離 |
|------|------|
| **Near** | 0–200m |
| **Mid** | 200–800m |
| **Far** | 800–2000m |

> 武器の `min_range` / `max_range` が優先される（例：迫撃はminがある）。

---

## 5. 共通：戦闘効果の基準係数（MVP用の決め打ち）

レーティング（0–100）を「Strength / Suppression 変化量」に変換するための定数。

### 5.1 直射（Direct Fire）の基準

| 定数 | 値 | 意味 |
|------|-----|------|
| `K_DF_DMG` | **0.30** | レーティング100・条件最良時の Strength減少/秒 |
| `K_DF_SUPP` | **2.5** | レーティング100・条件最良時の Suppression増加/秒 |

> 撃破は抑圧より遅いが、視認可能なダメージが蓄積する（＝"止めてから削る"ゲームになる）
>
> **調整履歴**: 0.06→0.30 (レーティング40の直射で約1.4分/10strength減少に調整)

### 5.2 間接（Indirect Fire）の基準（1発あたり）

間接は"離散イベント（着弾）"で処理する（現代っぽさとAARに強い）。

| 定数 | 値 | 意味 |
|------|-----|------|
| `K_IF_DMG` | **5.0** | レーティング100・爆心地の Strength減少/発 |
| `K_IF_SUPP` | **25.0** | レーティング100・爆心地の Suppression増加/発 |
| `R_blast` | **40m** | 爆風半径（v0.1固定、武器差は後で） |

> 迫撃・榴弾が「溶かす」より「止めて崩す」方向に効く値。

---

## 6. 直射戦闘（Direct Fire）

### 6.1 直射の成立条件

直射で"撃てる"ために必要：

- 武器射程内（`min_range ≤ D ≤ max_range`）
- LoSが Hard Block されていない
- `T_LoS ≥ 0.10`（森林/煙で見通しが薄すぎない）

> `T_LoS < 0.10` は直射不可（撃つ意味がない扱い）

### 6.2 直射の有効度係数（掛け算モデル）

直射の1tick効果は、以下の係数を掛け合わせる。

#### A) 射手状態係数 M_shooter

抑圧状態により発射・照準が落ちる：

| 状態 | M_shooter |
|------|----------|
| Normal | 1.00 |
| Suppressed | 0.70 |
| Pinned | 0.35 |
| Broken | 0.15（基本は撤退SOPなので実質撃てない） |

さらに Cohesion / Fatigue を薄く効かせる（v0.1固定）：

```
M_cohesion = 0.6 + 0.4 × (Cohesion/100)
M_fatigue = 1.0 - 0.3 × (Fatigue/100)
M_shooter = M_shooter × M_cohesion × M_fatigue
```

#### B) 視認・射撃困難係数 M_visibility_fire

煙と森林は「当てにくい」係数として扱う（遮蔽とは別）。

```
M_smoke_fire = clamp(T_smoke, 0.25, 1.00)
M_foliage_fire = clamp(T_forest, 0.35, 1.00)
M_visibility_fire = M_smoke_fire × M_foliage_fire
```

> 煙は強く、森林は中程度に射撃を邪魔する（現実の体感に寄せた設計）

#### C) 被射撃側の遮蔽係数（視界仕様で確定済み）

- `M_cover_DF`（地形）
- `M_entrench_DF`（Dig-in進捗）

#### D) 目標回避係数 M_target_evasion

| 状態 | M_target_evasion |
|------|-----------------|
| 静止 | 1.00 |
| 移動中 | 0.85（当たりにくい） |

#### E) 脆弱性係数 M_vuln

```
M_vuln = target.vulnerability_vs[weapon.threat_class]
```

### 6.3 直射の効果計算（1 tick）

距離から band を決める。
直射武器レーティングを `L = lethality[band][target_class]`、`S = suppression_power[band]` とすると：

**抑圧増加：**

```
dSupp = K_DF_SUPP × (S/100) × M_shooter × M_visibility_fire × M_target_evasion × M_cover_DF × M_entrench_DF × dt
```

**Strength減少：**

```
dDmg = K_DF_DMG × (L/100) × M_shooter × M_visibility_fire × M_target_evasion × M_cover_DF × M_entrench_DF × M_vuln × dt
```

**適用：**

```
target.suppression += dSupp
target.strength -= dDmg
```

### 6.4 直射の「面制圧（Attack Area）」仕様

目標確度がSUSのときの右クリック行動とも整合させる。

| 項目 | 値 |
|------|-----|
| 入力 | 中心点＋半径（デフォルト半径：35m） |
| 成立条件 | 中心点へのLoSが Hard Block されない（T_LoSは評価する） |
| 対象 | 半径内にいる敵全員（見えていなくても内部的には影響する） |

**効果減衰（狙って撃たないため）：**

```
dDmg *= 0.35
dSupp *= 0.70
```

**距離減衰（中心からの距離）：**

```
falloff = clamp(1 - dist_to_center / radius, 0, 1)
dDmg *= falloff
dSupp *= falloff
```

> "見えない森へ撃ち込む""推定位置へ制圧射撃"が、運用として成立する。

---

## 7. 間接戦闘（Indirect Fire：WEAP）

### 7.1 WEAPの状態機械（必須）

WEAP要素は以下の状態を持つ：

```
MOVING
SETTING_UP       # setup_time_sec
READY
FIRING
DISPLACING       # displace_time_sec
```

**ルール：**
- **READY 以外は間接射撃不可**
- 移動命令が来たら `DISPLACING → MOVING`

### 7.2 砲撃ミッション（Fire Mission）

間接射撃は"ミッション"として扱う。

**各ミッションが持つ属性：**

```
mission_type     : HE / SMOKE
aim_point (x, y)
duration_sec     : デフォルト30秒
rate_rpm         : v0.1固定：6発/分＝1発/10秒
call_time_sec    : 着弾開始までの遅延
sigma_m          : 散布（ガウス偏差）
```

#### 観測リンク（Observer Link）の定義

Observer要素が以下を満たすと「観測リンクあり」：

- 目標点に対して LoS が Hard Block されず、`T_LoS ≥ 0.10`
- ObserverのCommStateが Lost でない
- WEAPとObserverが同じ陣営で、情報共有が成立（COM/HQ等の遅延は call_time に反映してOK）

#### call_time と sigma の決め打ち（v0.1）

| 条件 | call_time | sigma |
|------|----------|-------|
| 観測リンクあり & 目標CONF | 6秒 | 20m |
| 観測リンクあり & 目標SUS（推定点） | 10秒 | 35m |
| 観測リンクなし（地図射撃） | 18秒 | 80m |

> 観測があると「早い・当たる」、ないと「遅い・散る」。偵察の価値が確実に出る。

### 7.3 着弾イベント（Impact）の生成

ミッション中、`rate_rpm` に従い着弾を発生させる（v0.1は10秒に1発）。

各着弾点は、aim_pointからガウス散布：

```
impact_point = aim_point + (N(0, sigma), N(0, sigma))
```

> リプレイ/AARのため、乱数は**試合seed**で決定する（決定論的に再現可能）。

### 7.4 着弾効果（HE）

着弾ごとに、周囲の要素へ範囲効果を適用する。

| パラメータ | 値 |
|-----------|-----|
| 基準爆風半径 | `R_blast = 40m` |

**距離減衰：**

```
d = 要素中心からの距離
falloff = clamp(1 - d / R_blast, 0, 1)
```

**間接遮蔽係数（既定仕様）：**

```
M_total_IF = M_cover_IF × M_entrench_IF × M_dispersion_IF
```

**脆弱性：**

```
M_vuln = vulnerability_vs[HEFrag]
```

**武器レーティング：**

```
L = lethality[band][target_class]  # 間接はbandをMid固定でもOK
S = suppression_power[band]
```

**着弾1発あたり：**

```
addSupp = K_IF_SUPP × (S/100) × falloff × M_total_IF
addDmg = K_IF_DMG × (L/100) × falloff × M_total_IF × M_vuln
```

**適用：**

```
target.suppression += addSupp
target.strength -= addDmg
```

### 7.5 煙幕ミッション（SMOKE）

煙幕仕様 v0.1に合わせて、着弾ごとにSmokeScreenを生成。

**v0.1決め打ち：**

| 項目 | 値 |
|------|-----|
| 煙幕1発 | SmokeScreen 1個生成 |
| radius | 35m |
| density_max | 1.0 |
| 時間プロファイル | rise10 / sustain60 / fade20（既定） |

同一地点付近に複数発着弾したら密度が加算（上限1.5）：

```
density = min(1.5, Σ density_contrib)
```

> "点煙幕"でも十分ゲームになる。後で「煙幕線（ドラッグで複数点）」に拡張可能。

---

## 8. 抑圧（Suppression）の回復と副作用

### 8.1 抑圧回復（v0.1固定式）

抑圧は「非被弾」状態で回復する。回復率は通信と姿勢で変える。

| パラメータ | 値 |
|-----------|-----|
| 基本回復 | `R_base = 1.2 / sec` |

**通信補正：**

| CommState | 倍率 |
|-----------|------|
| Good | ×1.0 |
| Degraded | ×0.7 |
| Lost | ×0.4 |

**姿勢補正：**

| Posture | 倍率 |
|---------|------|
| Defend / Dig-in | ×1.2 |
| Move / Attack | ×0.8 |

**被弾中（直近2秒以内に抑圧増加があった）：** 回復0

**1 tick：**

```
suppression -= R_base × comm_mult × posture_mult × dt
```

### 8.2 抑圧が与える能力低下（強制）

（UI・制圧仕様と整合させるため固定）

**移動速度倍率：**

| 状態 | 倍率 |
|------|------|
| Normal | 1.00 |
| Suppressed | 0.85 |
| Pinned | 0.20 |
| Broken | 0.00（SOPで後退） |

**制圧（capture_power）倍率：**

| 状態 | 倍率 |
|------|------|
| Normal | 1.00 |
| Suppressed | 0.50 |
| Pinned | 0.20 |
| Broken | 0.00 |

**射撃倍率：** 6.2の `M_shooter` に準拠

---

## 9. Strength（損耗）と戦闘力の縮退

### 9.1 Strengthが戦闘能力に与える影響

Strengthは「残存戦闘力」。少なくなるほど火力と制圧力が落ちる。

```
火力倍率：M_strength_fire = 0.5 + 0.5 × (Strength/100)
制圧倍率：M_strength_cap = Strength/100
```

> 最小でも0.5残すのは"即ゼロ"を避けて、抑圧主体のゲーム性を守るため。

### 9.2 戦闘不能（Combat Ineffective）

| Strength | 状態 |
|----------|------|
| ≤ 0 | **撃破（除去）** |
| ≤ 15 | 原則、SOPで後退優先（命令受付が大きく遅れる） |
| ≤ 30 | 火力・制圧は大きく低下（押し込みにくくなる） |

---

## 10. 弾薬（Ammo）と射撃継続

### 10.1 Ammo消費（連続交戦で尽きる形にする）

武器の `ammo_endurance_min` を使う。

**連続交戦強度 I（0〜1）の定義：**

| 命令 | I |
|------|---|
| Attack Target | 1.0 |
| Attack Area | 0.8 |
| Defend | 0.6 |

> Suppressed/Pinned は I に `M_shooter` を掛けて自然に低下

**消費（1秒あたり）：**

```
ammo_pct -= (100 / ammo_endurance_min / 60) × I
```

**弾薬低下ペナルティ：**

| Ammo | 効果 |
|------|------|
| < 20% | 火力×0.85、抑圧×0.90 |
| < 5% | 火力×0.50、抑圧×0.70 |
| = 0% | **射撃不可**（ROEに関係なく停止） |

---

## 11. SOP（自律行動）最小セット

通信断や命令なしでも"それっぽく"動くための最低限。

| SOP | 発動条件 | 動作 |
|-----|---------|------|
| **Return Fire** | デフォルトON | 攻撃された場合、LoS成立する敵へ反撃（ただしPinned以上は弱い） |
| **Seek Cover** | Suppression ≥ 70 | 近傍の遮蔽が高い地形へ短距離移動（最大80m） |
| **Broken Retreat** | Suppression ≥ 90 | "射線から外れる方向"へ後退（最大120m）→ Defend姿勢 |

> これがあるとプレイヤーは"全部マイクロしなくて良い"＝司令官RTSになる。

---

## 12. チューニング用つまみ（最重要5つ）

遊び心地がズレたら、まずここをいじる。

| パラメータ | 調整対象 |
|-----------|---------|
| `K_DF_SUPP` | 抑圧が速すぎ/遅すぎ |
| `K_DF_DMG` | 溶ける/溶けない |
| 間接の `sigma` と `call_time` | 観測の価値、理不尽さ |
| `R_base` | 抑圧回復速度：戦闘テンポ |
| Cover / Dig-in / Dispersion係数 | 地形・陣地の強さ |
