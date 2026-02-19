# 弾種・ダメージモデル仕様 v0.1

---

## 1) 目標

- 弾種×目標で効果が変わる（無効/有効/条件付き）
- 装甲目標は「命中部位（ゾーン）」で貫徹が変わる
- 戦車砲APの対歩兵は「当たれば致命、外れればほぼ無効」を再現
- かつ実装が破綻しない（中隊規模・10Hzシム前提）

---

## 2) 武器は「弾頭メカニズム」と「射撃モデル」を持つ

各WeaponTypeは必ず以下を持つ。

### 2.1 弾頭メカニズム `mechanism`

| 値 | 説明 |
|----|------|
| `SMALL_ARMS` | 小銃・LMG/HMG |
| `KINETIC` | AP/APFSDS/機関砲AP：運動エネルギー |
| `SHAPED_CHARGE` | HEAT/RPG/ATGM：成形炸薬 |
| `BLAST_FRAG` | HE/迫撃/榴弾：爆風・破片 |

### 2.2 射撃モデル `fire_model`

| 値 | 説明 | 処理 |
|----|------|------|
| `CONTINUOUS` | 連続火力（小銃、MG、機関砲など） | 10Hz tickでレート計算（既存のdSupp/dDmg式が使える） |
| `DISCRETE` | 単発/少数弾（戦車砲、RPG、ATGMなど） | 「発射イベント → 着弾点（散布）→ 直撃/至近弾 → 効果」で処理 |

> **ポイント：** "APが歩兵に場合によっては無効"を作るには、**DISCRETE（着弾点）**がほぼ必須。

---

## 3) 目標（Target）は「防護モデル」を持つ

Target（要素）は `protection_model` を持つ。

| 値 | 説明 |
|----|------|
| `SOFT` | 歩兵・非装甲 |
| `ARMORED` | 装甲車・戦車 |
| `FORTIFIED` | 陣地・建物内扱い（v0.1では簡略でOK） |

---

## 4) 装甲目標は「ゾーン別装甲」を持つ（命中部位モデル）

`ARMORED` にはゾーン別の装甲値を持たせる。単位はmmではなく **0–100レーティング** でOK（後で調整しやすい）。

### 4.1 ゾーン定義（固定）

| ゾーン |
|--------|
| `FRONT` |
| `SIDE` |
| `REAR` |
| `TOP` |

### 4.2 装甲テーブル（固定フィールド）

```
armor_ke[zone]    # KINETICに対する装甲（0–100）
armor_ce[zone]    # SHAPED_CHARGEに対する装甲（0–100）
```

---

## 5) 命中部位（ゾーン）の決定（2Dで成立する方法）

### 5.1 基本（直射・DIRECT）

目標の**向き（facing）**と、射手→目標のベクトルで相対角 θ を計算。

**アークでゾーンを決定（v0.1固定）：**

| 条件 | ゾーン |
|------|--------|
| \|θ\| ≤ 60° | FRONT |
| \|θ\| ≥ 150° | REAR |
| それ以外 | SIDE |

### 5.2 上面（TOP）の扱い（v0.1）

| 条件 | 扱い |
|------|------|
| `attack_profile = TOP_ATTACK` の武器（将来追加） | TOP固定 |
| 間接（迫撃/榴弾：BLAST_FRAGのIndirect） | v0.1は**「間接はゾーン無視」**でOK（重くなるので、まずは"装甲への効果が低い"で表現する） |

---

## 6) 貫徹（Penetration）判定

### 6.1 武器側パラメータ

`ARMORED` に対して意味を持つのは `KINETIC` / `SHAPED_CHARGE`。

```
pen_ke[range_band]    # 0–100
pen_ce[range_band]    # 0–100
```

### 6.2 貫徹確率（「たまに抜ける」を作る）

貫徹を0/1の断定にすると極端になるので、v0.1は**確率（期待値）**で扱う。

**有効貫徹 P：**

| mechanism | P |
|-----------|---|
| KINETIC | `pen_ke[band]` |
| SHAPED_CHARGE | `pen_ce[band]` |

**有効装甲 A：**

| mechanism | A |
|-----------|---|
| KINETIC | `armor_ke[zone]` |
| SHAPED_CHARGE | `armor_ce[zone]` |

**貫徹確率：**

```
p_pen = sigmoid((P - A) / 8)
sigmoid(x) = 1 / (1 + e^(-x))
```

> 8は"ふらつき幅"（後で調整ノブ）

これで「正面は通らないが側面は通る」「たまに運悪く抜ける」も表現できる。

---

## 7) 効果（Damage）は「3層」に分ける

| 層 | 意味 | 対応 |
|----|------|------|
| **Crew Shock** | 乗員ショック | Suppression |
| **Mission Effect** | 機能損傷 | サブシステムHP |
| **Kill** | 撃破 | Strength=0 or Catastrophic |

> `ARMORED` は「Strength一本」だけだとリアルさが出にくいので、最小限のサブシステムを持たせる（v0.1でここまでやると一気に"それっぽい"）。

### 7.1 車両サブシステム（ARMOREDのみ）

```
mobility_hp (0–100)   # 走行（履帯/エンジン）
firepower_hp (0–100)  # 主武装/砲塔
sensors_hp (0–100)    # 光学/通信/状況把握
```

**車両Strengthは合成値：**

```
Strength_vehicle = 0.4 × firepower_hp + 0.35 × mobility_hp + 0.25 × sensors_hp
```

**サブシステム閾値（v0.1固定）：**

| サブシステム | 閾値 | 効果 |
|-------------|------|------|
| mobility_hp | < 30 | 移動速度 -40% |
| mobility_hp | < 10 | **Immobilized**（移動不能） |
| firepower_hp | < 30 | 命中/発射速度低下（-40%） |
| firepower_hp | < 10 | **Main weapon disabled** |
| sensors_hp | < 30 | 発見距離 -40% / 同定時間 +50% |
| sensors_hp | < 10 | ほぼ盲目（観測能力極小） |

> これがあるだけで「撃破できなくても"止める・黙らせる"」が成立する。

---

## 8) 弾種ごとの効果ルール

### 8.1 SMALL_ARMS（小銃弾・MG）

#### 対 SOFT（歩兵）

- **有効**（既存の直射式：dDmg + dSupp）
- Cover/Dig-in/Smokeの係数が効く

#### 対 ARMORED（装甲車・戦車）

- **Strengthダメージ：0固定**（原則）
- Suppression（Crew Shock）は入るが**上限を設ける**：
  ```
  suppression_vehicle = min(suppression_vehicle, 20)
  ```
  > "小銃で戦車がPinnedで止まる"みたいな不自然を防ぐ

- 追加：近距離（≤200m）で射撃を受け続けると `sensors_hp` がじわじわ低下（任意だが雰囲気が出る）
  ```
  sensors_hp -= 0.02/秒（遮蔽なし・撃たれ続け時）
  ```

> ✅ 歩兵→歩兵（小銃、有効）/ 歩兵→戦車（小銃、無効）が成立

### 8.2 SHAPED_CHARGE（RPG/HEAT/ATGM）

射撃モデルは基本 **DISCRETE**（着弾点が出る）にする。

#### 対 ARMORED：条件付き有効（部位依存）

発射イベントごとに：

1. **直撃判定**（着弾点が目標の当たり半径内ならHit）
2. ヒットしたら**ゾーン決定**（FRONT/SIDE/REAR）
3. `p_pen` を計算
4. 効果は期待値で適用（または乱数ならseed固定）

**期待値適用（v0.1推奨）：**

"貫徹した場合の基礎ダメージ"を `D_pen` とする（武器のlethalityから作る）

**サブシステムに与えるダメージ：**

```
Δmobility = D_pen × p_pen × W_zone_mobility
Δfirepower = D_pen × p_pen × W_zone_firepower
Δsensors = D_pen × p_pen × W_zone_sensors
```

**Crew Shock：**

```
Δsupp = base_supp × (0.4 + 0.6 × p_pen)
```

> 抜けなくても"ショック"はある

**ゾーン別のサブシステム重み（v0.1固定）：**

| ゾーン | mobility | firepower | sensors |
|--------|----------|-----------|---------|
| FRONT | 0.20 | 0.45 | 0.35 |
| SIDE | 0.45 | 0.35 | 0.20 |
| REAR | 0.55 | 0.20 | 0.25 |

> ✅ 歩兵→戦車/装甲車（RPG、当たる場所によっては有効）が成立（側背は刺さりやすい、正面は刺さりにくい）

#### 対 SOFT：直撃・至近弾は強い

HEAT/RPGは「爆風・破片」がHEより小さいが、直撃が強い。

| 範囲 | 効果 |
|------|------|
| 直撃 | 大ダメージ（SOFTに対するdDmg大） |
| 至近（半径5–10m） | 中ダメージ＋大抑圧 |
| それ以上 | 抑圧のみ小 |

> ✅ 戦車→歩兵（HEAT、大ダメージ）も表現可能（"直撃なら"がポイント）

### 8.3 KINETIC（AP/APFSDS/機関砲AP）

#### 対 ARMORED：貫徹すれば強い

SHAPED_CHARGEと同様にゾーン → `p_pen`

ただし**抜けない時の効果は小さめ**（"弾かれた"）：

```
Δsupp = base_supp × (0.2 + 0.8 × p_pen)
```

サブシステム損傷は `p_pen` に強く依存

#### 対 SOFT：「当たれば致命、外れれば無効」をDISCRETEで再現

KINETICの対歩兵を連続DPSにすると"いつも少しずつ死ぬ"になりがちなので、**直撃モデル**でいく。

**DISCRETE武器の1発ごとに：**

| 半径 | 名称 |
|------|------|
| `R_direct = 2m` | 直撃半径（AP系） |
| `R_shock = 20m` | ショック半径 |

**効果：**

| 範囲 | 効果 |
|------|------|
| 直撃（≤2m） | 大ダメージ（SOFT Strengthに大） |
| ショック（≤20m） | Suppression増（ダメージほぼ無し） |
| それ以外 | ほぼ無し |

> ✅ 戦車→歩兵（AP、場合によっては無効）が仕様として再現できる

### 8.4 BLAST_FRAG（HE/迫撃/榴弾）

#### 対 SOFT：最も安定して強い

- 既存の間接モデル（着弾点＋半径＋falloff）を流用
- Cover/Dig-in/Dispersion（分散）が効く

#### 対 ARMORED：基本は"止める"、稀に"壊す"

爆風・破片は重装甲を抜きにくいので、v0.1はこうする：

| 効果 | 値 |
|------|-----|
| Strength（貫徹系） | 基本0〜小 |
| Suppression（Crew Shock） | 中 |
| mobility_hp | 小ダメージ（至近弾のみ） |

> 例：爆心距離 ≤10m のときだけ mobility にダメージが入る

これで「榴弾で戦車がすぐ爆散」は避けつつ、「砲撃で動きが鈍る」は作れる。

---

## 9) DISCRETE（単発）射撃の共通仕様（命中・散布）

### 9.1 発射間隔

```
rof_rpm    # 例：戦車砲 6rpm、RPG 2rpm、ATGM 1rpm など
```

次弾発射まで `60 / rof_rpm` 秒

### 9.2 着弾点（散布）

- 目標の"狙点" `aim_point` は目標中心（またはAttack Area中心）
- 散布 `sigma_hit`（m）は武器ごとに持つ

**射手状態と視認で悪化：**

```
sigma_eff = sigma_hit / clamp(M_shooter × M_visibility_fire, 0.25, 1.0)
```

**着弾点：**

```
impact = aim_point + (N(0, sigma_eff), N(0, sigma_eff))
```

### 9.3 直撃判定

- 目標の当たり半径 `R_target`（m）を持つ（要素サイズ）
- `distance(impact, target_center) ≤ R_target` なら**直撃**

---

## 10) "無効"を仕様で保証するルール

バランス調整でブレないように明文化する。

| ケース | ルール |
|--------|--------|
| SMALL_ARMS → ARMORED | `dStrength = 0`（常に） |
| KINETIC(AP) → SOFT | 直撃半径外は `dStrength ≈ 0` |
| SHAPED_CHARGE → ARMORED | `p_pen` が低いゾーン（正面）では期待値が小さい |

> これで「調整したらいつの間にか小銃で戦車が死ぬ」みたいな事故を防げる。

---

## 11) 例：ケース別処理

| ケース | 処理 |
|--------|------|
| **歩兵→歩兵（小銃、有効）** | SMALL_ARMS + CONTINUOUS → LoS/煙/遮蔽係数を掛けて dSupp と dStr が入る |
| **歩兵→戦車/装甲車（小銃、無効）** | SMALL_ARMS vs ARMORED → dStr=0、suppressionは最大20まで（乗員ショック止まり） |
| **歩兵→戦車/装甲車（RPG、部位で有効）** | SHAPED_CHARGE + DISCRETE → 当たりさえすればゾーン判定 → SIDE/REARなら p_pen↑ → mobility/firepowerが落ちる / FRONTなら p_pen↓ → "当たったのに効かない"が起きる |
| **戦車→歩兵（HEAT）** | DISCRETE、直撃/至近弾で大ダメージ＋大抑圧 |
| **戦車→歩兵（AP）** | DISCRETE、直撃半径が小さい → 当たらない限りほぼ抑圧だけ |

---

## 12) 最低限決めるデータ項目

この仕様を実装に落とすため、ユニット表を作る前でも最低限これだけは決める。

### 武器ごとに必要

```
mechanism           # SMALL_ARMS / KINETIC / SHAPED_CHARGE / BLAST_FRAG
fire_model          # CONTINUOUS / DISCRETE
rof_rpm             # DISCRETE用
sigma_hit           # DISCRETE用
pen_ke / pen_ce     # 必要なメカニズムのみ
blast_radius        # 爆発系のみ（HE/HEAT/迫撃等）
direct_hit_radius   # KINETIC対SOFT用
shock_radius        # KINETIC対SOFT用
```

### 装甲目標ごとに必要

```
armor_ke[FRONT/SIDE/REAR/TOP]
armor_ce[FRONT/SIDE/REAR/TOP]
初期 sub HP: mobility / firepower / sensors
```
