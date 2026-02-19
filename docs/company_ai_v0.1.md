# 中隊AI仕様 v0.1

---

## 0. 目的とスコープ

### 0.1 目的

- プレイヤーが出す命令（Move/Attack/Defend/Recon…）を、中隊の内部要素（Element）へ"軍事的に自然な手順"で分解し、SOPに沿って実行させる。
- 射撃がまだ無くても成立するように、観測→判断→展開→火力要請（準備）→占領/退避までをルールで回す。
- 将来の射撃/抑圧実装後も、同じAI骨格に「被弾」「抑圧」「損耗」イベントを繋げるだけで成長できる。

### 0.2 スコープ（v0.1）

- **対象**：購入単位の「中隊ユニット（UnitCard）」を束ねる CompanyControllerAI
- **その配下**：既存の Element SOP（ROE/Autonomy/弾種選択/Break contact等）
- v0.1では「敵プレイヤーの戦略AI（デッキ/増援購入）」は別仕様（後で）。ここは **1中隊がどう動くか**。

---

## 1. アーキテクチャ（責務分離）

### 1.1 CompanyControllerAI の入出力

#### 入力

- **CompanyIntent**（プレイヤー命令 or 上位AI命令）
  - MoveRoute / AttackTarget / AttackArea / Defend / Recon/Observe / BreakContact / Resupply 等
- **味方要素状態**（位置・Strength・Suppression状態・ammo_pct・mobility・loadout・cohesion）
- **FoW ContactDB**（敵の CONF/SUS/LOST、推定位置・誤差）
- **地形/CP情報**（terrain_id、CP状態、ArrivalPoint、CONTESTED）
- **ナビ**（FOOT/WHEELED/TRACKED × ALL/ROUTE）パス取得

#### 出力

- **Element単位の OrderBatch**（命令キューへ投入）
- **Element単位のSOPパラメータ更新**（ROE、Autonomy、姿勢、AT使用許可など）
- **火力支援要求**（SupportFire/Smoke）＝ "誰に・どこへ・どれだけ" をルールで生成

> **重要**：CompanyAIは「戦闘計算」をしない。戦闘が起きる前の"配置・判断・意図"を作る。

### 1.2 階層（v0.1固定）

| 階層 | 責務 |
|------|------|
| **CompanyControllerAI** | 中隊全体の計画・役割配分・命令生成 |
| **ElementController (SOP)** | 個別要素の局地判断（遮蔽移動/射撃/退避/弾種選択） |

---

## 2. AIの更新タイミング（10Hzとの整合）

### 2.1 更新レート（確定）

| 頻度 | 処理内容 |
|------|---------|
| **10Hz（毎tick）** | 安全系（生存介入、衝突回避フラグ、Broken処理）／タイマー進行 |
| **2Hz（0.5秒）** | 接触（Contact）評価、脅威分類、ターゲット割当の見直し |
| **1Hz（1秒）** | 行動フェーズ（後述）の遷移、経路再計画、隊形更新、火力支援の再計画 |
| **0.2Hz（5秒）** | 大局の再評価（CP優先度、補給判断、再編） |

これで「安定していてチラつかない」＋「反応が遅すぎない」を両立します。

---

## 3. 中隊AIが扱う"軍事的プロセス"モデル（OODAを実装に落とす）

中隊AIは毎周期、次の4段階を回します（ルールベース）。

### 3.1 Observe（観測）

ContactDBから：
- **CONF**：敵の確定位置
- **SUS**：推定位置＋誤差
- **LOST**：記憶（薄い）

自中隊要素から：
- 生存可能性（Strength/ Suppression）
- 機動可能性（mobility/速度）
- 火力支援可能性（迫撃が居る、煙が撃てる）

### 3.2 Orient（状況把握）

**ThreatMap（脅威マップ）**を作る（v0.1は簡易）

| 脅威種別 | 危険円半径 | 備考 |
|---------|-----------|------|
| CONF装甲 | R_armor_threat（既定 900m） | フル強度 |
| SUS装甲 | R_armor_threat | 強度を半分 |
| 歩兵AT疑惑（市街/森林＋SUS密度） | 拠点周辺に追加 | |

Terrain advantage（地形優位）：
- **URBAN/FOREST**：遮蔽・発見補正がある（既存仕様）
- **OPEN**：危険

### 3.3 Decide（決心）

「現在のCompanyIntentを継続できるか」を判定し、必要なら **内部的な"戦術テンプレート"**に切り替える（後述：Attack/Defend/Recon等）

### 3.4 Act（行動）

- 役割分担（Assault / Support / Security / Scout）
- 経路（ROUTE/ALL）決定
- 位置（Phase Line/Support-by-fire line）決定
- Elementへの命令投入（Queued→Ack→Exec は既存仕様に従う）

---

## 4. CompanyIntent と戦術テンプレート（ルールベースの中核）

中隊AIは、受けた命令を "テンプレート" に落とします。

### 4.1 テンプレート種別（v0.1）

| テンプレート | 説明 |
|-------------|------|
| **TPL_MOVE** | 移動（安全優先） |
| **TPL_ATTACK_CP** | 拠点攻撃（奪取・確保） |
| **TPL_DEFEND_CP** | 拠点防御（射界・遮蔽） |
| **TPL_RECON** | 偵察（発見優先・交戦回避） |
| **TPL_ATTACK_AREA** | 面制圧（抑圧優先） |
| **TPL_BREAK_CONTACT** | 接触離脱（生存最優先） |
| **TPL_RESUPPLY** | 補給・再編 |

### 4.2 役割配分（Tasking）ルール（v0.1）

中隊タイプごとに、配下要素へ役割を割り当てます。

#### INF_COY（INF_LINE/INF_MG/INF_AT）

| 役割 | 要素 | 任務 |
|------|------|------|
| **Assault** | INF_LINE | CP内に入って確保する主役 |
| **Support** | INF_MG | Support-by-fire地点へ、抑圧担当 |
| **Security** | INF_AT | 側面警戒・装甲出現時の機会射撃 |

#### TANK_COY（TANK_PLT×2）

| 役割 | 要素 | 任務 |
|------|------|------|
| **Support/Overwatch** | 1個小隊 | 火力支援 |
| **Maneuver/Flank** | 1個小隊 | 機動 |

※CP"確保"はしない（capture=0）ので、歩兵が居ないなら Neutralize止まりが基本

#### RECON_PLT（RECON_VEH/RECON_TEAM）

| 役割 | 要素 | 任務 |
|------|------|------|
| **Scout** | RECON_TEAM | 前方観測、HoldFire |
| **Screen** | RECON_VEH | 素早く横移動し視界を取る、接敵したら退避 |

#### MORTAR_PLT（MORTAR_SEC）

| 役割 | 要素 | 任務 |
|------|------|------|
| **FireSupport** | MORTAR_SEC | 観測リンクが来たら火力任務、無ければ待機・位置保持 |

---

## 5. 各テンプレートのフェーズとルール（射撃実装前でも回る）

以下、テンプレートを **フェーズ状態機械**として定義します。
（CompanyAIはフェーズだけを見る。細部はSOPに委譲）

### 5.1 TPL_MOVE（移動）

#### フェーズ

1. PLAN_ROUTE
2. MOVE
3. REACT_CONTACT
4. ARRIVE / HOLD

#### ルール

**PLAN_ROUTE**：
- defaultは ALL（道路コストで自然に道路優先）
- Alt指定（Road move）なら ROUTE優先、不可ならALLへフォールバック

**MOVE**：
- 要素間隔（Spacing）を維持（後述）

**REACT_CONTACT**（接触が発生したら）：
- CONFが近い（<=600m）なら停止→遮蔽へ
- SUSだけなら「SUS地点を避ける迂回」or「偵察要素を前へ」

**ARRIVE**：
- 到着点で Defend（Facingは進行方向）を自動発行してよい

### 5.2 TPL_ATTACK_CP（拠点攻撃）

#### フェーズ

1. RECON_AND_SHAPE（偵察・形作り）
2. SET_SUPPORT_BY_FIRE（支援火力位置へ）
3. ASSAULT_MOVE（突入）
4. CAPTURE_AND_CONSOLIDATE（確保と再編）
5. HOLD_DEFEND

#### ルール（v0.1の"軍事っぽさ"の核）

**RECON_AND_SHAPE**：
- 目標CP半径 R_cp=40m の外側 R_standoff=250m に"観測点"を1つ設定
- RECONが居れば Observe命令（到達後12秒観測）
- 居なければ INF_MG を観測役に兼務

**SET_SUPPORT_BY_FIRE**：
- Support要素（INF_MG / TANKのOverwatch）を
  - 目標CP中心から 500〜800m
  - OPENを避け、FOREST/URBAN縁を優先
- する"支援射撃ライン"へ移動→Defend（Facing=CP方向）

**ASSAULT_MOVE**：
- Assault要素（INF_LINE）をCPへ Move（最後はCP中心でなく「CP円の縁」へ）
- CONTESTED が発生したら「Supportを維持しつつ、Assaultは遮蔽で停止」へ移行（突っ込まない）

**CAPTURE_AND_CONSOLIDATE**：
- CPが CONTROLLED になったら
  - AssaultはCP内でDefend
  - Supportは1段前進して扇形防御（Facing=敵側）

#### 煙幕ルール（まだ射撃未実装でも発動できる）

- AssaultがOPEN横断を強いられるとき（OPENセルが連続30m以上）
  → Smoke要求（目標：敵側の視線ライン上、CP手前 150m）

#### 迫撃HEルール（後で射撃実装に接続）

- CONTESTEDが10秒継続 かつ SupportFire available
  → SupportFire(HE) 要請（CP周辺をSuppress/Neutralize）

### 5.3 TPL_DEFEND_CP（拠点防御）

#### フェーズ

1. OCCUPY_POSITIONS
2. SET_SECTORS
3. HOLD_AND_COUNTER
4. REPOSITION

#### ルール

**OCCUPY**：
- CP中心ではなく「CP円の縁」へ分散配置（後述のSpacing）

**SECTORS**：
- 扇形防御（Facing）は「敵側（CPの反対方向の要点）」へ

**HOLD**：
- CONF敵が見えたら Engage/Suppress（SOPに任せる）
- SUSだけなら面制圧（AttackArea）を短時間（10秒）で実行

**REPOSITION**（防御が崩れそう）：
- Suppression平均が70超え or Strength合計が60%切り
  → BreakContactテンプレへ

### 5.4 TPL_RECON（偵察）

#### フェーズ

1. MOVE_IN_BOUNDS
2. OBSERVE
3. REPORT
4. EVADE

#### ルール

- **ROE**：HoldFire（既定）
- Moveは 小刻み（ウェイポイント間隔 150〜250m）
- 交戦はしない。CONF敵を得たら即Report（チーム共有contact更新）→EVADE

**EVADE**：
- 最寄り遮蔽（FOREST/URBAN）へ移動
- それでも危険なら後退点へ BreakContact

### 5.5 TPL_ATTACK_AREA（面制圧）

#### フェーズ

1. APPROACH
2. SUPPRESS
3. ASSESS
4. REPEAT / END

#### ルール

- SUSに対しても実行可（PID不要）
- "10秒抑圧"を1セットとして反復
- 迫撃があるなら優先して支援要請（HE/Smokeは状況で）

### 5.6 TPL_BREAK_CONTACT（接触離脱）

#### フェーズ

1. SMOKE_AND_COVER（可能なら）
2. DISENGAGE_MOVE
3. RALLY
4. HOLD

#### ルール

- BreakContactは **最優先**（SOP v0.1と一致）
- Smokeが撃てる/要請できるなら最初に実行（Danger close回避）
- 退避先は「敵のThreatMapから最も遠い遮蔽セル」へ
- Rally：suppression<40が5秒継続で終了

### 5.7 TPL_RESUPPLY（補給・再編）

#### フェーズ

1. MOVE_TO_SAFE
2. RESUPPLY
3. REJOIN

#### ルール（v0.1）

- Ammo<25% または 迫撃弾（HE/SMOKE）が<25% なら候補
- LOGが居ないv0.1では「補給ポイントへ移動して回復」でも良い（将来LOGに置換）
- RESUPPLY中はROE HoldFire

---

## 6. 編隊・間隔・分散（"それっぽさ"を出す最小ルール）

### 6.1 Spacing（要素間隔）既定（v0.1）

| 種別 | 間隔 |
|------|------|
| FOOT主体（INF/REC_TEAM） | 25m |
| WHEELED/TRACKED | 40m |
| "危険地帯（ThreatMap強）" | ×1.5（分散） |

### 6.2 フォーメーション（v0.1簡易）

| 隊形 | 使用場面 |
|------|---------|
| **Column**（縦隊） | ROUTE移動、道路上 |
| **Line**（横隊） | 攻撃時の展開（最後の200m） |
| **Wedge**（楔形） | 装甲の接敵移動（ALL） |

実装は「各要素に隊形スロットの目標オフセットを与える」だけでよい。

---

## 7. 接触（Contact）への反応ルール（射撃前の"意思決定"）

### 7.1 接触分類（v0.1）

ContactDBの type_hint（または推定）で分類：

| 分類 | 説明 |
|------|------|
| **Soft** | 歩兵 |
| **Armored_Light** | 軽装甲 |
| **Armored_Heavy** | 重装甲 |
| **Unknown** | SUSのみ等 |

### 7.2 反応の段階（Escalation）

| Stage | 条件 | 反応 |
|-------|------|------|
| 0 | 接触なし | 任務継続 |
| 1 | SUSのみ | 偵察/迂回/面制圧（状況次第） |
| 2 | CONFだが遠距離（>600m） | Support-by-fireへ移行（不用意に突っ込まない） |
| 3 | CONF近距離（<=600m） | 停止＋遮蔽＋BreakContact検討 |

### 7.3 "装甲脅威"へのルール（v0.1）

**INF主体が Armored_Heavy をCONFで得た場合**：
- INF_ATが射程内に入るまで **無理に戦わない**
- Smokeで視線を切って迂回 or 離脱

**TANKが Armored_Heavy をCONFで得た場合**：
- Overwatchを作ってからManeuver（2個小隊なら片方固定・片方迂回）

---

## 8. 火力支援（迫撃）を"射撃前"に仕様化する

### 8.1 支援要求生成の条件（v0.1）

CompanyAIは以下を満たすと FireSupportRequest を生成してよい：

**SmokeRequest**：
- AssaultがOPENを横断（連続30m以上）
- かつ敵のCONF/強SUS方向に対してLoSを切りたい

**HERequest**（Suppress/Neutralize）：
- CONTESTED が 10秒継続
- または防御側がPinnedが多い（平均Suppression>=70）
- または敵のCONF火点が拠点周辺に固定（後で射撃実装に接続）

### 8.2 要請の"形"

```
type: SMOKE / HE
target: point or area(radius)
priority: normal / urgent
duration_sec または rounds_tier（弾数はRulesetで具体化）
danger_close: true/false（味方距離から自動判定）
```

要請は既存の命令体系（SupportFire/Smoke）に変換して、迫撃要素へ投入。

---

## 9. 命令生成と命令キュー（既存仕様との接続）

### 9.1 CompanyAIが出す命令の原則（v0.1）

- **"命令スパム"禁止**：同じ要素に1秒以内に再命令しない（ヒステリシス）
  - `MIN_REORDER_INTERVAL_SEC = 1.0`
- 重要な切替のみ REPLACE、それ以外は APPEND
- MoveRouteは最大12点、命令キュー最大10（既存仕様）

### 9.2 重要：C2遅延の扱い

CompanyAIが命令を出しても、要素側で Ack まで遅延する。
そこで v0.1では：

- CompanyAIは「実行中の計画」を保持し、Ack/Execの進捗を監視する
- Ackが遅れている場合に "同じ命令を連投しない"
- 代わりに「次のフェーズへ移行しない」＝計画を待つ

---

## 10. 例：INF_COYが CPを攻撃する（ルールの具体例）

1. プレイヤーが CP C に Attack を出す

2. CompanyAIは **TPL_ATTACK_CP** を選択

3. 役割配分：
   - INF_LINE：Assault
   - INF_MG：Support
   - INF_AT：Security（側面警戒）

4. **フェーズ1 RECON_AND_SHAPE**：
   - RECONがいればObserve、いなければINF_MGを観測点へ

5. **フェーズ2 SET_SUPPORT_BY_FIRE**：
   - INF_MGを500〜800mの遮蔽縁へ→Defend facing CP

6. **フェーズ3 ASSAULT_MOVE**：
   - INF_LINEをCP縁へ
   - OPEN横断が必要なら Smoke要請
   - CPがCONTESTEDなら：Assault停止、Support維持、HE要請（10秒継続なら）
   - CONTROLLEDになったら Consolidate → Hold_Defend

この時点で、射撃が未実装でも
**"配置・煙・展開・占領" が動き、プレイが成立します。**

---

## 11. 実装のためのデータ（定数まとめ v0.1）

```yaml
AI_UPDATE:
  micro_tick_hz: 10
  contact_eval_hz: 2
  tactical_eval_hz: 1
  operational_eval_hz: 0.2

THRESHOLDS:
  standoff_recon_m: 250
  support_by_fire_min_m: 500
  support_by_fire_max_m: 800
  contact_near_m: 600
  armor_threat_m: 900

SPACING:
  foot_spacing_m: 25
  vehicle_spacing_m: 40
  threat_spacing_multiplier: 1.5

REORDER:
  min_reorder_interval_sec: 1.0

FIRE_SUPPORT_TRIGGERS:
  contested_he_trigger_sec: 10
  open_crossing_len_m: 30
```

---

## 12. デバッグ可視化（v0.1推奨：後で必ず役に立つ）

| 表示項目 | 説明 |
|---------|------|
| CompanyAIの現在テンプレートとフェーズ | 例：ATTACK_CP / SET_SUPPORT_BY_FIRE |
| 各要素の割当役割 | Assault/Support/Security/Scout |
| ThreatMapの危険円 | 簡易でOK |
| 生成した命令と Ack/Exec ETA | 命令の進捗状況 |

これがあると、射撃を入れた後も「AIが変になった」原因が追えます。
