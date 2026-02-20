# 戦闘仕様 v0.1R（リアリティ強化）

---

## 1. 追加の前提（v0.1からの差分）

### 1.1 「抑圧」と「損耗」は別レイヤ

- **抑圧**：近接弾・被弾・爆発・火力密度で上がる（心理/行動の劣化）
- **損耗**：ヒット（命中）イベントや爆風イベントで離散的に発生する（死傷・破壊）

これで「止まるだけ」ではなく「普通に減る」「車両も壊れる」が入ります。

---

## 2. 状態値（追加・拡張）

### 2.1 既存（そのまま）

- Strength(0–100) / Suppression(0–100) / Cohesion(0–100) / Fatigue(0–100) / Ammo%(0–100)

### 2.2 車両（ARMORED）専用：サブシステムHP（units_v0.1と整合）

| サブシステム | 範囲 |
|-------------|------|
| `mobility_hp` | 0..100 |
| `firepower_hp` | 0..100 |
| `sensors_hp` | 0..100 |

### 2.3 車両の派生状態（HPから自動判定）

#### Mobility状態

| mobility_hp | 状態 | 効果 |
|-------------|------|------|
| > 50 | Normal | - |
| 25..50 | Damaged | 速度×0.70 |
| 1..25 | Critical | 速度×0.35 |
| 0 | Immobilized | 移動不可 |

#### Firepower状態

| firepower_hp | 状態 | 効果 |
|--------------|------|------|
| > 50 | Normal | - |
| 25..50 | Damaged | 直射のL/S×0.80 |
| 1..25 | Critical | L/S×0.50、射撃頻度低下 |
| 0 | WeaponDisabled | 主武装不可 |

#### Sensors状態

| sensors_hp | 状態 | 効果 |
|------------|------|------|
| > 50 | Normal | - |
| 25..50 | Damaged | visual_range×0.80、id_speed×0.75 |
| 1..25 | Critical | visual_range×0.60、id_speed×0.55 |
| 0 | SensorsDown | visual_range×0.40、識別ほぼ不可 |

---

## 3. 防護側パラメータを分離（重要：戦車が小銃で"抑圧され過ぎる"問題を解消）

### 3.1 target側に2つ持たせる（v0.1R確定）

```gdscript
vulnerability_dmg_vs[threat_class]   # 損耗（Strength/HP）への脆弱性
vulnerability_supp_vs[threat_class]  # 抑圧への脆弱性
```

例（デフォルト案：後で国・車種で上書き可能）：

**Heavy（戦車）**

| threat_class | dmg | supp |
|--------------|-----|------|
| smallarms | 0.00 | 0.10 |
| autocannon | 0.15 | 0.35 |
| HEFrag | 0.10 | 0.50 |
| AT | 1.00 | 1.00 |

**Soft（歩兵）**

| threat_class | dmg | supp |
|--------------|-----|------|
| smallarms | 1.00 | 1.00 |
| HEFrag | 1.40 | 1.30 |

これで「歩兵が戦車に撃っても止められない／でも無視できるほどでもない」が作れます。

---

## 4. 更新順（10Hz、ほぼ同じだが"ヒットイベント生成"を追加）

```
1. 命令状態更新（Queued→Ack→Exec）
2. ターゲット選定（命令/SOP/ROE）
3. LoS評価（Hard→Soft、T_LoS）
4. 射撃パッケージ生成（1秒スライスで安定化）
5. ヒット/至近弾/爆発イベント生成（確率・決定論RNG）
6. 効果適用
   - Strength/サブシステムHPの減少（離散）
   - Suppression増加（連続＋イベント）
   - Cohesion/Fatigue更新
   - Ammo消費
7. 閾値処理（Suppressed/Pinned/Broken）
8. 情報更新（発砲シグネチャ、contact更新）
```

---

## 5. 射撃を「火力密度」と「離散イベント」に分離する（v0.1Rの核心）

### 5.1 FirePackage（1秒単位、内部で10tickに分配してもよい）

直射は毎tickで処理しても良いが、**確率がブレにくいように"1秒あたりの期待値"**で組むのが安定します。

**1秒あたりの基礎（bandで決める）：**

- `L = lethality[band][target_class]`（0–100）
- `S = suppression_power[band]`（0–100）

**係数（v0.1のものを継承）：**

- M_shooter（suppression/cohesion/fatigue）
- M_visibility_fire（煙・森林）
- M_target_evasion（移動）
- M_cover_* / M_entrench_*

ここまでは同じ。ただし **出力が変わる**：

- **抑圧**：連続量（dSupp）
- **損耗**：ヒットイベント確率（p_hit）＋ヒット時の被害分布

---

## 6. 直射（Direct Fire）— リアリティ強化版

### 6.1 直射の成立条件（同じ）

- 射程内
- HardBlockなし
- T_LoS >= 0.10

### 6.2 抑圧（連続）— ただし "脆弱性_supp" を使う

**1秒あたりの抑圧増加：**

```
dSupp/sec = K_DF_SUPP × (S/100) × M_shooter × M_visibility_fire × M_target_evasion
            × M_cover_DF × M_entrench_DF × M_vuln_supp
```

- `M_vuln_supp = vulnerability_supp_vs[threat_class]`

**適用**：tickなら `dSupp = (dSupp/sec) * dt`

旧v0.1の式をほぼ踏襲しつつ、戦車が小銃で"過剰に止まる"のを防止できます。

**v0.1R 既定（抑圧基準）**

| 定数 | 値 | 説明 |
|------|-----|------|
| `K_DF_SUPP` | 2.2 | 少し下げる：損耗が入る分、抑圧だけで決め過ぎない |

### 6.3 損耗（離散）— "ヒットイベント"で発生させる

#### 6.3.1 ヒットイベント確率（1秒あたり）

まず「この1秒に"有効ヒット（被害が出るヒット）"が起きる確率」を作る。

```
E = (L/100) × M_shooter × M_visibility_fire × M_target_evasion
    × M_cover_DF × M_entrench_DF × M_vuln_dmg
```

- `M_vuln_dmg = vulnerability_dmg_vs[threat_class]`

期待危険度 E（0..だいたい1）を、確率過程に変換：

```
p_hit_1s = 1 - exp(-K_DF_HIT × E)
```

**v0.1R 既定：**

| 定数 | 値 | 説明 |
|------|-----|------|
| `K_DF_HIT` | 0.25 | E=1 なら 1秒に約22%で"被害ヒット"が出る |

旧v0.1の「毎秒0.30減る」みたいな連続モデルを、イベント確率に置き換えたものです。

#### 6.3.2 ヒット発生時の被害（SoftとVehicleで分ける）

##### A) Soft（歩兵等）の被害分布（v0.1R確定）

ヒットが起きたら、**"死傷イベント"**として Strength を離散減少させる。

**被害カテゴリ（確率はEで傾く）：**

| カテゴリ | ΔStrength | 平均 |
|----------|-----------|------|
| Minor | 0.8〜2.0 | 1.2 |
| Major | 2.0〜5.0 | 3.2 |
| Critical | 5.0〜12.0 | 7.5（稀） |

**カテゴリ確率（v0.1R・決め打ち、Eで補正）：**

| 条件 | Minor | Major | Critical |
|------|-------|-------|----------|
| base | 0.75 | 0.22 | 0.03 |
| E >= 0.7 | - | - | +0.02（=0.05まで） |
| E <= 0.2 | - | -0.10（=0.12へ） | - |

**適用：**

```gdscript
target.strength -= delta_strength
```

**副作用（リアリティ用・確定）：**

```gdscript
target.cohesion -= 0.6 * delta_strength  # 即座に崩れる
target.suppression += 6 + 2*delta_strength  # 被害は強いショック
```

**イベント生成：**

- `EV_CASUALTY_TAKEN(delta_strength)`
- `EV_SUPPRESSION_STATE_CHANGED`（閾値跨ぎ時）

##### B) Vehicle（Light/Heavy）の被害分布（v0.1R確定）

車両は Strength を直接削るのではなく、サブシステムHPを削る（＝装備損傷が"普通に起きる"）。

###### 6.3.2-B1 角度（アスペクト）で効果を変える（簡易hit location）

射手→目標ベクトルと目標の facing から、4分類：

- **Front / Side / Rear / Top**（間接・爆風はTop）

**アスペクト倍率（armor_presetごと・v0.1R既定）：**

| preset | Front | Side | Rear | Top |
|--------|-------|------|------|-----|
| Heavy | 0.70 | 1.00 | 1.25 | 1.10 |
| Light | 0.95 | 1.10 | 1.20 | 1.10 |

```
E_vehicle = E * aspect_mult
```

###### 6.3.2-B2 "損傷の重さ"カテゴリ

E_vehicle に応じてカテゴリを選ぶ（確率は決め打ち）：

| E_vehicle | Minor | Major | Critical |
|-----------|-------|-------|----------|
| < 0.25 | 85% | 14% | 1% |
| 0.25..0.60 | 60% | 33% | 7% |
| >= 0.60 | 35% | 40% | 25% |

###### 6.3.2-B3 サブシステムへの割り振り（threat_classで傾ける）

| threat_class | Sensors | Mobility | Firepower |
|--------------|---------|----------|-----------|
| SmallArms | 70% | 25% | 5% |
| Autocannon | 20% | 40% | 40% |
| HEFrag | 35% | 35% | 30% |
| AT | 20% | 35% | 45% |

###### 6.3.2-B4 実ダメージ量（v0.1R）

| カテゴリ | ダメージ | 平均 |
|----------|----------|------|
| Minor | -8..-18 | 12 |
| Major | -18..-35 | 26 |
| Critical | 特殊処理 | - |

**Critical時の処理：**

AT もしくは E_vehicle>=0.8 の場合：

| 結果 | 確率 | 効果 |
|------|------|------|
| Catastrophic | 40% | 車両破壊：全HP=0、ユニット除去 |
| Mission Kill | 60% | Mobility=0 or Firepower=0 を強制 |

それ以外：

- Major相当×1.2（= 30前後）＋追加で別サブシステムに小ダメージ（-8）

適用後、派生状態（Immobilized等）を更新。

**イベント生成（v0.1R追加）：**

- `EV_VEHICLE_SUBSYSTEM_DAMAGED(subsystem, delta_hp)`
- `EV_VEHICLE_MISSION_KILL(type=IMMOBILIZED/WEAPON_DISABLED)`
- `EV_VEHICLE_DESTROYED`（Catastrophic時）

これで「装輪が止まる」「砲塔が死ぬ」「センサーが死ぬ」が普通に出ます。戦闘が"抑圧だけ"に見えません。

### 6.4 Attack Area（面制圧）のリアリティ補正

面制圧は「命中させる」より「頭を上げさせない」が主。
よって：

- **抑圧**：旧仕様どおり強め
- **損耗**：ヒット確率を大幅に下げる（ゼロにはしない）

**v0.1R確定：**

| 項目 | 値 | 説明 |
|------|-----|------|
| dSupp | ×0.80 | 旧0.70より少し上げて"制圧射撃らしさ" |
| p_hit_1s | ×0.25 | 旧dDmg*0.35よりさらに「当たらない」寄り |

中心距離falloffはそのまま適用（p_hitにもdSuppにも掛ける）

---

## 7. 間接（Indirect Fire）— "爆風は死ぬし壊れる"版

### 7.1 砲撃ミッション（call_time / sigma）は旧仕様を踏襲

（観測リンクで早い・当たる、地図射撃は遅い・散る、はリアルで正しい）

| 条件 | call_time | sigma |
|------|----------|-------|
| 観測リンクあり & 目標CONF | 6秒 | 20m |
| 観測リンクあり & 目標SUS（推定点） | 10秒 | 35m |
| 観測リンクなし（地図射撃） | 18秒 | 80m |

### 7.2 着弾ごとの効果（HE）

間接は「離散イベント」なので、各Impactで 抑圧＋損耗イベントを生成する。

#### 7.2.1 抑圧（衝撃）

```
addSupp = K_IF_SUPP × (S/100) × falloff × M_total_IF × M_vuln_supp
```

**v0.1R 既定：**

| 定数 | 値 |
|------|-----|
| `K_IF_SUPP` | 24（ほぼ据え置き） |

#### 7.2.2 損耗（爆風は"イベント"で出す）

直射と同じく「イベント」で処理。ただし間接はfalloffが強いので、爆心ほど"被害イベント"が出やすい。

**Soft（歩兵）：**

```
E_if_soft = (L/100) × falloff × M_total_IF × M_vuln_dmg
p_hit = clamp( K_IF_HIT × E_if_soft, 0, 0.85 )
```

**v0.1R既定：**

| 定数 | 値 | 説明 |
|------|-----|------|
| `K_IF_HIT` | 0.65 | 爆心なら高確率で死傷が出る |

ヒット時のStrength減少は直射と同じ分布だが、Major/Criticalの比率を少し上げる：

| カテゴリ | 確率 | 説明 |
|----------|------|------|
| Minor | 0.60 | - |
| Major | 0.33 | - |
| Critical | 0.07 | 爆風は一撃が重い |

**Vehicle（軽装甲/戦車）：**

- E_if_vehicle を作ってサブシステムへ（Top扱いで aspect=Top）
- ただし Heavy への脆弱性_dmg_vs[HEFrag] を小さめにしておく（戦車が迫撃で溶けない）

これで「迫撃が歩兵に痛い」「軽装甲は壊れうる」「戦車は"止まる/視界が死ぬ"ことはあるが溶けにくい」が出ます。

---

## 8. Suppression（抑圧）— "死傷と結び付く"ようにする

### 8.1 抑圧は3つの入力で増える（v0.1R）

| 入力 | 説明 |
|------|------|
| 火力密度（連続） | dSupp（直射/間接の式） |
| 至近弾・爆発（イベント） | NEAR_MISS / EXPLOSION_NEAR |
| 死傷・損傷（イベント） | CASUALTY_TAKEN / SUBSYSTEM_DAMAGED |

**イベント加算（v0.1R既定）：**

| イベント | Soft | Vehicle |
|----------|------|---------|
| EV_NEAR_MISS | +10 | +6 |
| EV_EXPLOSION_NEAR | +18 | +12 |
| EV_CASUALTY_TAKEN | + (6 + 2*delta_strength) | - |
| EV_VEHICLE_SUBSYSTEM_DAMAGED | - | +8（軽）/+6（重） |

「被害が出たのに平然としている」が無くなります。

### 8.2 抑圧回復（基本は旧仕様、ただし"被害直後"を厳しく）

- 「直近2秒以内に抑圧増があったら回復0」は継続
- **追加**：直近10秒以内に死傷/損傷イベントがあったら回復×0.5

---

## 9. Cohesion / Fatigue — "損耗が部隊を壊す"を明確化

### 9.1 Cohesionの更新（v0.1R確定）

**被害イベントで下がる**（上で定義）

**抑圧が高いほどじわじわ下がる：**

```
cohesion -= 0.15 * (suppression/100) * dt  # 戦闘中の摩耗
```

**回復は「戦闘終息」後のみ（簡易）**

- combat_clear（イベント仕様で20秒無イベント）後：
- `cohesion += 0.6/sec`（上限は初期値まで）

### 9.2 Fatigueの更新（簡易維持）

- 移動・戦闘で増加、静止で回復（旧v0.1の枠でOK）
- Fatigueは命中（E）を薄く下げる（既存の M_fatigue を維持）

---

## 10. Strength（損耗）— "連続減少"をやめ、イベントで減る

- **Soft**は 死傷イベントでStrengthが離散減少（6.3.2-A）
- **Vehicle**は サブシステムHPが減る（6.3.2-B）

ただし勝利条件や全滅判定が Strength を参照しているので、Vehicleにも表示用Strengthが必要なら：

### 10.1 Vehicleの表示Strength（任意・v0.1R推奨）

```gdscript
strength = clamp( (mobility_hp + firepower_hp + sensors_hp)/3 , 0..100 )
```

破壊なら strength=0

これで全滅判定・UI表示と整合します。

---

## 11. "現実感"を上げるが破綻しないための制約（v0.1R）

1. **1秒内に同一ペア（射手→同一目標）で発生できる "被害ヒットイベント" は最大1回**
   - 期待値は確率で表現し、イベントスパムを防ぐ

2. **間接1発で同一要素に発生できる被害イベントも最大1回**
   - ただし複数発着弾すれば複数回起きる

---

## 12. チューニングつまみ（v0.1Rで本当に効く5つ）

抑圧だけでなく損耗が入ったので、ノブも更新します。

| パラメータ | 調整対象 |
|-----------|---------|
| `K_DF_HIT` | 直射の"被害が出る頻度" |
| Softの被害分布 | Minor/Major/Criticalの比率と幅 |
| VehicleのCritical内訳 | Catastrophic vs MissionKill の比率 |
| `vulnerability_dmg_vs` / `vulnerability_supp_vs` | 兵科・装甲のらしさ |
| `K_IF_HIT` | 間接の"殺傷感"と理不尽さ |

---

## 13. 既存の「戦闘開始イベント」との接続（破綻しないポイント）

この v0.1R は、既に決めたイベント定義に自然に繋がります。

| 射撃結果 | イベント |
|----------|----------|
| ヒット（Soft） | EV_CASUALTY_TAKEN |
| ヒット（Vehicle） | EV_VEHICLE_SUBSYSTEM_DAMAGED / MISSION_KILL / DESTROYED |
| 爆発近傍 | EV_EXPLOSION_NEAR |
| 抑圧状態跨ぎ | EV_SUPPRESSION_STATE_CHANGED |

AI側（Company/SOP）は「イベントを受けて動く」設計なので、射撃の中身を作り込むほど "軍事的プロセス"が強くなる構造になります。

---

## 14. ここで確認：何が"リアルになったか"

| 改善点 | 説明 |
|--------|------|
| 抑圧だけでなく死傷が普通に出る | Strengthの離散減少 |
| 車両の段階的劣化 | 止まる・撃てなくなる・目が死ぬが頻繁に出る（=現代戦っぽい） |
| 戦車が小銃で止まり過ぎる問題を解消 | suppとdmgの脆弱性分離 |
| レーティング駆動維持 | NATO/RU/CN差し替えと相性が良い |

---

## 15. パラメータ早見表

### 15.1 直射パラメータ

| 定数 | 値 | 説明 |
|------|-----|------|
| `K_DF_SUPP` | 2.2 | 抑圧係数 |
| `K_DF_HIT` | 0.25 | ヒット確率係数 |

### 15.2 間接パラメータ

| 定数 | 値 | 説明 |
|------|-----|------|
| `K_IF_SUPP` | 24 | 抑圧係数 |
| `K_IF_HIT` | 0.65 | ヒット確率係数 |
| `R_blast` | 40m | 爆風半径 |

### 15.3 面制圧補正

| 項目 | 倍率 |
|------|------|
| dSupp | ×0.80 |
| p_hit | ×0.25 |

### 15.4 抑圧閾値（既存）

| 閾値 | 状態 |
|------|------|
| 40 | Suppressed |
| 70 | Pinned |
| 90 | Broken |

### 15.5 射手状態係数（既存）

| 状態 | M_shooter |
|------|----------|
| Normal | 1.00 |
| Suppressed | 0.70 |
| Pinned | 0.35 |
| Broken | 0.15 |

### 15.6 アスペクト倍率

| preset | Front | Side | Rear | Top |
|--------|-------|------|------|-----|
| Heavy | 0.70 | 1.00 | 1.25 | 1.10 |
| Light | 0.95 | 1.10 | 1.20 | 1.10 |

### 15.7 脆弱性（デフォルト）

**Heavy（戦車）**

| threat_class | dmg | supp |
|--------------|-----|------|
| smallarms | 0.00 | 0.10 |
| autocannon | 0.15 | 0.35 |
| HEFrag | 0.10 | 0.50 |
| AT | 1.00 | 1.00 |

**Soft（歩兵）**

| threat_class | dmg | supp |
|--------------|-----|------|
| smallarms | 1.00 | 1.00 |
| HEFrag | 1.40 | 1.30 |
