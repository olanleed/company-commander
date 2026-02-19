# 戦闘開始イベント定義 v0.1

---

## 0. 位置づけ

- この仕様は **CompanyAI（中隊AI）**と SOP（要素AI） が参照する「イベント」の定義。
- "戦闘開始"は1回の出来事ではなく、現実同様に **警戒→交戦→沈静化**という状態遷移として扱う。
- v0.1では「イベント＝決定論（tick）で再現可能」な設計にする。

---

## 1. イベントモデル（共通フォーマット）

### 1.1 CombatEvent 構造（v0.1必須フィールド）

各tickで生成されるイベントは以下を持つ：

| フィールド | 説明 |
|-----------|------|
| `event_id` | 連番（試合内ユニーク） |
| `tick` | 発生tick（10Hz） |
| `type` | イベント種別（enum） |
| `severity` | 重要度（後述） |
| `team` | どちらの陣営の視点イベントか（Blue/Red） |
| `subject_unit_ids[]` | 影響を受ける味方ユニット（0..n） |
| `source_unit_id` | 原因側ユニット（分かる場合のみ。敵の場合はUnknown可） |
| `pos_m` | 発生地点（地図座標） |
| `radius_m` | 影響半径（0なら点） |
| `confidence` | 確度（CONF/SUS/LOST、または0..1でも可） |
| `tags` | 任意タグ（target_class、munition_class、cp_id、etc） |

### 1.2 severity（重要度）定義

| レベル | 説明 |
|--------|------|
| **S0_INFO** | 通知のみ（戦闘状態に影響しない） |
| **S1_ALERT** | 警戒開始の候補（戦闘開始：弱） |
| **S2_ENGAGE** | 交戦開始の候補（戦闘開始：強） |
| **S3_EMERGENCY** | 緊急（即座の生存行動・離脱を誘発） |

---

## 2. "戦闘状態"の定義（イベントが何を起こすか）

イベントを受けたとき、各要素（Element）と中隊（Company）は以下の状態を持つ。

### 2.1 ElementCombatState（要素ごと）

| 状態 | 説明 |
|------|------|
| **QUIET** | 戦闘外 |
| **ALERT** | 接触・脅威あり（警戒・展開段階） |
| **ENGAGED** | 交戦中（射撃/被弾/爆発近接/損耗など） |
| **DISENGAGING** | 離脱中（BreakContact/撤退フェーズ） |
| **RECOVERING** | 沈静化（一定時間でQUIETへ） |

**保持値：**
- `combat_since_tick`
- `last_combat_event_tick`
- `last_alert_event_tick`

### 2.2 CompanyCombatState（中隊ごと）

| 状態 | 説明 |
|------|------|
| QUIET / ALERT / ENGAGED / DISENGAGING | 要素の最大状態を採用 |

**ルール**：配下要素の最大状態を中隊状態とする（例：要素が1つでもENGAGEDなら中隊ENGAGED）

### 2.3 "戦闘開始"の定義（v0.1）

| 種別 | 遷移 |
|------|------|
| **戦闘開始（警戒開始）** | QUIET → ALERT へ遷移するイベントが発生した瞬間 |
| **戦闘開始（交戦開始）** | QUIET/ALERT → ENGAGED へ遷移するイベントが発生した瞬間 |

---

## 3. イベント生成タイミング（いつ計算するか）

### 3.1 生成パイプライン（v0.1確定）

1. **10Hz tick開始時**：命令適用（Queued→Ack/Execなど）
2. **10Hz tick中**：各サブシステムが raw event を生成
3. **tick終了時**：raw event を集約・重複抑制して CombatEvent を確定 → EventBusへ投入
4. **CompanyAI / SOP** は、指定レート（10Hz/2Hz/1Hz）で EventBus を参照

### 3.2 生成レート（既存仕様と整合）

- 視認（LoS+距離）そのものは vision_v0.1 どおり **5Hzでスキャン**し、接触状態が変化したらイベントを出す
- イベントの状態遷移は **10Hzで管理**（tick基準）

---

## 4. 戦闘開始イベント "カタログ" v0.1

ここからが本体です。
**「何が起きたら戦闘が始まったとみなすか」**を、射撃実装前でも動くもの／射撃実装後に繋ぐものに分けて定義します。

### 4.1 視認・接触（Vision/Contact）起因の戦闘開始

#### EV_CONTACT_SUS_ACQUIRED（疑似接触）

| 項目 | 内容 |
|------|------|
| type | EV_CONTACT_SUS_ACQUIRED |
| severity | S1_ALERT |

**発生条件：**
- visionスキャンで、敵が visible_now=true だが CONF獲得条件（連続2回）に未達
- または「瞬間的に見えたが遮蔽に隠れた」等でSUSが生成された瞬間

**payload：**
- `pos_m` = 接触推定位置
- `confidence` = SUS
- `tags.target_class` = Unknown（確定できない場合）

**戦闘開始への寄与：**
- QUIET → ALERT の候補（※距離フィルタは後述）

> **目的**："何かいる"で中隊が展開を始める。射撃が無くても軍事的に成立。

#### EV_CONTACT_CONF_ACQUIRED（確定接触）

| 項目 | 内容 |
|------|------|
| type | EV_CONTACT_CONF_ACQUIRED |
| severity | S1_ALERT（ただし近距離/装甲ならS2に昇格可） |

**発生条件：**
- vision_v0.1 のCONF獲得（連続視認 0.4秒相当）が成立し、ContactがCONFに遷移した瞬間

**payload：**
- `pos_m` = 敵の確定位置
- `confidence` = CONF
- `tags.target_class` = Soft/Armored_Light/Armored_Heavy/Fortified（分かる範囲）

**戦闘開始への寄与：**
- 原則 QUIET → ALERT
- ただし **「近距離」または「装甲脅威」**なら S2_ENGAGE 相当に扱って ENGAGED 開始して良い（下の昇格ルール）

#### EV_CONTACT_TYPE_REFINED（識別進展）

| 項目 | 内容 |
|------|------|
| type | EV_CONTACT_TYPE_REFINED |
| severity | S0_INFO（通常）／S1_ALERT（Unknown→Armored_Heavy 等の昇格時） |

**発生条件：**
- 既存Contact（SUS/CONF）の type_hint が更新された瞬間（例：UNKNOWN→ARMORED_HEAVY）

**戦闘開始への寄与：**
- 既にALERT/ENGAGEDなら更新情報として扱う
- QUIETに対しては「脅威が高い更新」の場合にALERT開始の候補になり得る

### 4.2 拠点・戦線（CP/Operational）起因の戦闘開始

#### EV_CP_CONTESTED_ENTER（拠点が争奪状態になった）

| 項目 | 内容 |
|------|------|
| type | EV_CP_CONTESTED_ENTER |
| severity | S2_ENGAGE（拠点内は交戦開始扱い） |

**発生条件：**
- CP状態が CONTESTED に遷移した瞬間（CP占領仕様v0.1に従う）

**payload：**
- `pos_m` = CP center
- `tags.cp_id`

**戦闘開始への寄与：**
- CP周辺にいる要素を ENGAGED に上げるトリガ
- CompanyAIは即「支援火力要請」「Assault停止/展開」等の反応が可能

> 射撃未実装でも「争奪＝戦闘開始」はゲーム上も分かりやすい。

#### EV_CP_CONTESTED_EXIT（争奪が解消した）

| 項目 | 内容 |
|------|------|
| type | EV_CP_CONTESTED_EXIT |
| severity | S0_INFO |

**発生条件：**
- CONTESTED から他状態へ遷移した瞬間

**寄与：**
- 戦闘終息判定（後述）に使えるが、開始イベントではない

### 4.3 火力支援・間接（Support Fire）起因の戦闘開始

（射撃未実装でも「要請」「着弾予定」は先に出せる）

#### EV_FIRE_SUPPORT_REQUESTED（火力支援要請が出た）

| 項目 | 内容 |
|------|------|
| type | EV_FIRE_SUPPORT_REQUESTED |
| severity | S1_ALERT |

**発生条件：**
- CompanyAI/SOPが SupportFire/Smoke の要請を生成し、命令キューに投入した瞬間

**寄与：**
- "戦闘準備が始まった"イベントとしてAAR/ログに残す（開始判定としては弱）

#### EV_FIRE_MISSION_INBOUND（着弾予告）

| 項目 | 内容 |
|------|------|
| type | EV_FIRE_MISSION_INBOUND |
| severity | S2_ENGAGE（その地点では交戦相当） |

**発生条件：**
- 迫撃/支援火力の execute_tick と ETA が確定し、着弾地点が決まった瞬間
- （自軍要請は必ず分かる。敵の間接は将来の観測で検出できるがv0.1は自軍のみでOK）

**payload：**
- `pos_m` = 目標点
- `radius_m` = 予想危険半径（BlastTierから引く or 既定値）
- `tags.mission_type` = HE/SMOKE

**寄与：**
- その半径内にいる要素は ALERT もしくは ENGAGED（最低でもALERT）へ
- CompanyAIは「Danger Close → 中止/退避」判断に使える

### 4.4 射撃・被弾（Direct Fire）起因の戦闘開始

※ここは「弾道/命中」実装後に自然に繋ぐため、今の段階で"イベントだけ"先に定義します。

#### EV_SHOT_FIRED（発砲）

| 項目 | 内容 |
|------|------|
| type | EV_SHOT_FIRED |
| severity | S2_ENGAGE |

**発生条件：**
- 任意の武器が射撃を開始した瞬間（単発でも連射でも「開始」）

**payload：**
- `source_unit_id`
- `pos_m` = 射手位置
- `tags.weapon` = ConcreteWeaponId
- `tags.fire_mode` = Direct/Indirect

**寄与：**
- 発砲した側の要素は ENGAGED へ

#### EV_UNDER_FIRE（被射撃判定：命中でなくてもよい）

| 項目 | 内容 |
|------|------|
| type | EV_UNDER_FIRE |
| severity | S2_ENGAGE（重い場合はS3） |

**発生条件（v0.1で規定する"最小"）：**
- 直射弾の"危険域"が要素の周辺を通過した
- または要素の近傍で爆発が発生した（後述のEV_EXPLOSION_NEAR）

**payload：**
- `pos_m` = 被射撃要素の位置（または最近傍の通過点）
- `radius_m` = danger_radius

**寄与：**
- 対象要素は ENGAGED へ
- CompanyAIは即座に BreakContact / Smoke / SeekCover の判断材料にする

> **重要**：命中判定が無くても **「弾が飛んできた」**だけで戦闘開始として十分軍事的。

#### EV_NEAR_MISS（至近弾）

| 項目 | 内容 |
|------|------|
| type | EV_NEAR_MISS |
| severity | S2_ENGAGE（多発ならS3） |

**発生条件（実装後に使う閾値だけ先に決める）：**
- 直射弾の最近傍距離が R_nearmiss 未満
- 既定：`R_nearmiss = 15m`（歩兵基準）
- 車両は `R_nearmiss_vehicle = 25m`

**寄与：**
- ENGAGED開始・維持に使う
- 抑圧実装後は suppression増加の入力にもなる

#### EV_EXPLOSION_NEAR（近傍爆発）

| 項目 | 内容 |
|------|------|
| type | EV_EXPLOSION_NEAR |
| severity | S2_ENGAGE（danger closeならS3） |

**発生条件：**
- 爆発（HE/HEATの対人効果含む）が発生し、要素が R_shock 内
- R_shock は Ruleset の blast_tier_geometry から取得

**寄与：**
- ENGAGED開始・維持

### 4.5 損耗・抑圧（Effects）起因の戦闘開始

※これも「ダメージ/抑圧の中身」実装後に繋ぐが、イベント定義は先に固める。

#### EV_CASUALTY_TAKEN（損耗発生）

| 項目 | 内容 |
|------|------|
| type | EV_CASUALTY_TAKEN |
| severity | S3_EMERGENCY（原則） |

**発生条件：**
- Strengthが前tickより減少した（ΔStrength < 0）

**payload：**
- `tags.delta_strength`

**寄与：**
- 対象要素は即 ENGAGED（またはDISENGAGINGへ遷移判断）
- CompanyAIは「任務継続可否」を再評価

#### EV_SUPPRESSION_STATE_CHANGED（抑圧状態遷移）

| 項目 | 内容 |
|------|------|
| type | EV_SUPPRESSION_STATE_CHANGED |
| severity | Normal→Suppressed：S2_ENGAGE / Suppressed→Pinned：S3_EMERGENCY / Pinned→Broken：S3_EMERGENCY |

**発生条件：**
- suppression状態が閾値を跨いで変化した瞬間

**寄与：**
- ENGAGED開始（または離脱開始）に直結

---

## 5. "戦闘開始イベント"の適用範囲（誰が影響を受けるか）

イベントは発生しただけでは全員に影響させず、距離と役割でスコープを切ります（AIが過敏にならないため）。

### 5.1 影響半径（既定）

イベントごとに「誰に通知するか」の半径を持つ。

**v0.1既定：**

| イベント種別 | 影響半径 |
|-------------|---------|
| Contact（SUS/CONF） | R_alert_contact = 800m |
| UnderFire / Explosion / Casualty | R_alert_fire = 400m |
| CP_CONTESTED | R_alert_cp = 600m |
| FireMissionInbound（自軍） | R_alert_inbound = mission.radius + 200m |

※subject_unit_ids が明確なイベント（UnderFire/Casualty等）は半径に関係なく本人へ必ず通知。

### 5.2 役割フィルタ（既定）

| 役割 | ルール |
|------|--------|
| **REC** | 「接触イベント」を重く扱う（Alertに上がりやすい） |
| **LOG/HQ** | 「接触イベント」で即ALERT（退避判断へ）しやすい |
| **WEAP（迫撃）** | 「接触」だけでは戦闘開始にしない（位置保持が基本）。UnderFire/Explosionは別。 |

---

## 6. 昇格ルール（CONF接触＝即ENGAGEDにしないため）

EV_CONTACT_CONF_ACQUIRED は通常S1ですが、下記の場合は S2へ昇格し、交戦開始扱いにします。

### 6.1 近距離昇格

- 敵CONFが `distance <= 600m` のとき → **S2_ENGAGE**

### 6.2 装甲脅威昇格

- `target_class == Armored_Heavy` かつ `distance <= 900m` → **S2_ENGAGE**

（この2つの距離は、中隊AIの定数 `contact_near_m=600`、`armor_threat_m=900` と一致させます）

---

## 7. "戦闘開始"と"戦闘終息"のルール（イベント駆動で状態機械を閉じる）

### 7.1 戦闘開始（状態遷移）

**QUIET の要素が以下のいずれかを受けたら ALERT：**
- S1_ALERT 以上のイベント

**QUIET/ALERT の要素が以下を受けたら ENGAGED：**
- S2_ENGAGE 以上のイベント

**遷移時に、派生イベントを1つ生成する（AI/UIが扱いやすい）：**
- `EV_COMBAT_STATE_CHANGED`（old_state/new_state を持つ）

### 7.2 戦闘終息（沈静化）

戦闘が永遠に続くのを防ぐため、無イベントで沈静化させます。

**v0.1既定：**
```
COMBAT_CLEAR_SEC = 20.0s（=200tick）
```

**条件：**
- `current_tick - last_combat_event_tick >= 200`
- かつ 近距離(CONF/SUS)接触が無い（<=800mにcontactが無い）

**満たしたら：**
- ENGAGED → RECOVERING → QUIET（RECOVERINGは5秒固定でも良い）

---

## 8. 重複抑制（イベントスパム防止）v0.1

同じイベントが多発するとAIが不安定になるのでクールダウンを固定します。

| イベント種別 | クールダウン |
|-------------|-------------|
| EV_CONTACT_* | 同一敵IDにつき 2秒 |
| EV_UNDER_FIRE / EV_NEAR_MISS / EV_EXPLOSION_NEAR | 同一subjectにつき 1秒 |
| EV_CP_CONTESTED_ENTER | 状態遷移なので重複なし |
| EV_CASUALTY_TAKEN | 毎回通す（重要） |

---

## 9. v0.1で"今すぐ実装できる"戦闘開始イベント（射撃なしで動く）

### 射撃前でも確実に実装でき、CompanyAIのフェーズ遷移に効くもの：

- EV_CONTACT_SUS_ACQUIRED
- EV_CONTACT_CONF_ACQUIRED
- EV_CONTACT_TYPE_REFINED
- EV_CP_CONTESTED_ENTER
- EV_FIRE_SUPPORT_REQUESTED
- EV_FIRE_MISSION_INBOUND（自軍のみ）

### 射撃実装後に差し込むもの：

- EV_SHOT_FIRED
- EV_UNDER_FIRE
- EV_NEAR_MISS
- EV_EXPLOSION_NEAR
- EV_CASUALTY_TAKEN
- EV_SUPPRESSION_STATE_CHANGED

---

## 10. 早見表

### 10.1 イベント種別一覧

| イベント | severity | 射撃前実装 | 用途 |
|---------|----------|-----------|------|
| EV_CONTACT_SUS_ACQUIRED | S1 | Yes | 疑似接触 |
| EV_CONTACT_CONF_ACQUIRED | S1/S2 | Yes | 確定接触 |
| EV_CONTACT_TYPE_REFINED | S0/S1 | Yes | 識別進展 |
| EV_CP_CONTESTED_ENTER | S2 | Yes | 拠点争奪開始 |
| EV_CP_CONTESTED_EXIT | S0 | Yes | 拠点争奪解消 |
| EV_FIRE_SUPPORT_REQUESTED | S1 | Yes | 火力支援要請 |
| EV_FIRE_MISSION_INBOUND | S2 | Yes | 着弾予告 |
| EV_SHOT_FIRED | S2 | No | 発砲 |
| EV_UNDER_FIRE | S2/S3 | No | 被射撃 |
| EV_NEAR_MISS | S2/S3 | No | 至近弾 |
| EV_EXPLOSION_NEAR | S2/S3 | No | 近傍爆発 |
| EV_CASUALTY_TAKEN | S3 | No | 損耗発生 |
| EV_SUPPRESSION_STATE_CHANGED | S2/S3 | No | 抑圧状態遷移 |

### 10.2 定数一覧

```yaml
ESCALATION:
  contact_near_m: 600
  armor_threat_m: 900

ALERT_RADIUS:
  contact_m: 800
  fire_m: 400
  cp_m: 600

NEAR_MISS:
  infantry_m: 15
  vehicle_m: 25

COOLDOWN:
  contact_sec: 2.0
  fire_sec: 1.0

COMBAT_CLEAR:
  timeout_sec: 20.0
  recovery_sec: 5.0
```
