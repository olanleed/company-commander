# SOP仕様 v0.1
## Standard Operating Procedures（自律行動規定）

---

## 0. 目的

- プレイヤーは **意図（Intent）** を出すだけで戦える（Move/Defend/Attack/Recon/Resupply…）
- 部隊は **生存・指揮・火力・持続** を自律的に最適化する
- 規格差（NATO/RU/CN）は弾薬Variantに閉じ込め、SOPは **共通ロジック** で動く

---

## 1. SOPと命令の関係（優先順位ルール）

### 1.1 命令は「目的」、SOPは「手段」

| 種別 | 役割 |
|------|------|
| **命令** | 何を達成するか（拠点を守れ、ここへ移動しろ、ここを制圧しろ） |
| **SOP** | どうやって達成するか（遮蔽へ移動、火力選択、撃ち方、分散、撤退） |

### 1.2 SOPが命令を上書きできる範囲（Autonomy Level）

各要素は `autonomy_level` を持つ（v0.1で固定語彙）。

| Level | 名称 | 説明 |
|-------|------|------|
| A0 | Strict | 基本的に命令優先。例外：Broken時の退避だけは必ず発動 |
| **A1** | SelfPreserve（既定） | 命令を遂行しつつ、Pinned/Brokenなど生存に直結する行動はSOPで介入 |
| A2 | SemiAutonomous | 命令の範囲内で、経路・停止・火力配分・遮蔽移動などを積極的に自律最適化 |

> v0.1既定は **A1**。プレイヤーは右パネル（SOP設定）で個別に変更可能。

### 1.3 命令状態（Queued/Ack/Exec）との整合

| 状態 | SOP動作 |
|------|---------|
| Queued | 部隊は直近の命令（またはアイドルSOP）を継続 |
| Ack | 次の切替タイミング（停止点・経路節など）を計画 |
| Exec | 以後は命令の意図に沿ってSOPが動く |

---

## 2. SOPエンジン構造（実装指針）

### 2.1 優先度スタックで解く（Behavior Priority）

SOPは毎tick全評価ではなく、**イベント＋周期評価** で十分。

| 周期 | 処理内容 |
|------|---------|
| 10Hz（dt=0.1） | 抑圧・被弾・移動・射撃などの連続処理 |
| 2Hz（0.5秒） | ターゲット選定、武器選択の再評価（チラつき防止） |
| 1Hz（1秒） | 経路再計画、遮蔽選定、分散モード変更など重い処理 |

### 優先順位（高→低）

1. **Immediate Survival** - Broken退避／Pinned遮蔽／Danger Close
2. **Return Fire / Self Defense** - ROE範囲
3. **Mission Intent Execution** - 命令の主目的
4. **Housekeeping** - 補給・再編・隊形

---

## 3. ROE（交戦規定）と発砲許可

SOPは勝手に撃ち過ぎると"偵察が死ぬ"ので、ROEを明確化する。

### 3.1 ROE語彙

| ROE | 説明 |
|-----|------|
| `ROE_HoldFire` | 撃たない（ただしBroken退避中の近距離自衛は別扱い可） |
| `ROE_ReturnFire`（既定） | 攻撃を受けた時のみ交戦 |
| `ROE_FreeFire` | 交戦可能目標に自動交戦（ただし命令の意図に従う） |

### 3.2 PID（同定要求）

```yaml
pid_required_for_direct_fire: true  # 既定
```

- 直射で「狙って撃つ」は **CONF目標** が原則
- SUSは **Attack Area（面制圧）** に自動変換して扱う

---

## 4. ターゲット選定SOP（誰を撃つか）

ターゲット候補を点数化し、最大スコアを選ぶ。

### 4.1 候補の生成

| 確度 | 候補化ルール |
|------|-------------|
| CONF | 候補に入れる |
| SUS | 命令が Attack Area / Defend Sector の場合は候補に入れる（面制圧）。それ以外は優先度低 |

### 4.2 スコア関数（v0.1固定構造）

```
score = ThreatWeight(role, target_class) × Visibility × Proximity × MissionRelevance × Feasibility
```

| 要素 | 説明 |
|------|------|
| ThreatWeight | 役割×目標種別の危険度 |
| Visibility | LoS透過 T_LoS と確度（CONFが高い） |
| Proximity | 近いほど高い（ただし"危険に近すぎる"は別ルール） |
| MissionRelevance | 命令目標（拠点/防御セクター/指定ターゲット）に近いほど高い |
| Feasibility | 射程内・武器有効・弾薬あり・ROE許可 |

### 4.3 役割別 ThreatWeight（抽象表）

#### TANK / VEH（対装甲）

| TargetClass | Weight |
|-------------|--------|
| Armored_Heavy | High |
| Armored_Light | High |
| Soft | Med（ただし近距離ATはHigh扱いしてよい） |
| Fortified | Med |

#### INF

| TargetClass | Weight |
|-------------|--------|
| Soft | High |
| Fortified | Med |
| Armored_Light | Med（AT装備がある場合） |
| Armored_Heavy | Low（AT装備があっても"機会"のみ狙う） |

#### REC

交戦を避ける（基本Low、ReturnFireのみ）

#### WEAP（迫撃）

| TargetClass | Weight |
|-------------|--------|
| Soft（集結/拠点周辺） | High |
| Fortified | High（抑圧の価値が大） |
| Armored | Low〜Med（"止める"が目的ならMed） |

---

## 5. 武器・弾種選択SOP（何で撃つか）

弾薬規格差はVariantに閉じ込め、SOPは **TargetClass/Range/Certainty/Ammo状態** だけを見る。

### 5.1 共通ルール（全役割）

| ルール | 説明 |
|--------|------|
| **無効弾は選ばない** | SmallArms_Ball → Armored_* は strength=None（仕様で固定） |
| **CONF優先** | 直射の「狙って撃つ」はCONFが基本。SUSは Attack Area（面制圧）で扱う |
| **弾薬節約（Sustain）** | AmmoLow（<25%）で高価弾抑制、AmmoCritical（<10%）で原則交戦回避 |

### 5.2 戦車（TANK）弾種選択

#### Mount A：TankGun

| 目標 | 第一選択 | 代替 |
|------|---------|------|
| Armored_Heavy（CONF） | Tank_KE_Penetrator | Tank_HEAT_MultiPurpose（KEが無い/射界悪い/弾切れ） |
| Armored_Light（CONF） | KE優先 | 状況によりHEATで統一（ドクトリン差） |
| Soft（CONF） | 同軸/車載MG（Mount B） | 掩体/市街/密集、または突破意図ならHEAT |
| Fortified（CONF） | HEAT | - |
| SUS | MGで面制圧 | KE/HEATは基本使わない（弾薬節約＋PID） |

> KEは DirectHitOnly前提なので、Soft目標には通常選ばない（例外：非常近距離の確実直撃）

### 5.3 IFV/装甲車（VEH）弾種選択

| 目標 | 弾種 |
|------|------|
| Armored_Light | Autocannon_AP優先 |
| Armored_Heavy | AP（足止め狙い、ZoneSensitive） |
| Soft/Fortified/市街縁 | Autocannon_HE |
| SUS | HEで面制圧（APでSUSを追うのは無駄） |

### 5.4 歩兵（INF）武器選択

| 目標 | 武器選択 |
|------|---------|
| Soft（CONF） | SmallArms_Ball（基本） |
| Armored（CONF） | Inf_AT_Rocket_HEAT（射程内×LoS良好×露出許容）。それ以外は隠蔽・報告・誘導火力要求 |
| Fortified（CONF） | SmallArmsで抑圧、可能なら迫撃/戦車火力を要求（要素単独で突入しない） |

### 5.5 迫撃（WEAP）弾種選択

迫撃は「敵を殺す」より **窓を作る** のが主目的。

#### HEを使う状況（優先）

- 味方が突入する拠点周辺に敵SoftがCONF（またはSUSが濃い）
- 敵が防御で固着しており、味方の前進がPinned/Brokenで止まっている
- 敵の火点（MG/HMG等）が判明（CONF）している

#### SMOKEを使う状況（優先）

- 味方がOPENを横切って前進する必要がある（Move/Attack命令下）
- 敵の優位射線（観測/直射）が強く、遮蔽移動だけでは突破できない
- 味方の退避（Broken Retreat / Break Contact）を隠す必要がある

#### 観測リンクが無い場合

| 弾種 | 効果 |
|------|------|
| HE | 散布が悪くなるので、基本は抑圧目的の"広め面"のみ（命中期待は低い） |
| SMOKE | 観測無しでも価値が高い（「見えない」を作るだけでよい） |

---

## 6. 命令タイプ別 SOP（ミッション遂行ロジック）

命令が違えばSOPも変わる。

### 6.1 Move（移動）

| 状況 | SOP動作 |
|------|---------|
| 基本 | 経路追従（ナビ） |
| 接敵（A1/A2） | ReturnFireしつつ遮蔽へ一時停止→再計画（突っ込まない） |
| Suppression≥70 | Seek Cover（遮蔽移動） |
| Suppression≥90 | Broken Retreat（後退→停止→再編） |

### 6.2 Defend（防御：ポイント/セクター）

| 状況 | SOP動作 |
|------|---------|
| 基本 | "射界（扇形）"を優先する（UIで指定した向き） |
| 交戦 | CONF優先で狙撃／SUSは面制圧 |
| Pinned | 射界を保てる範囲で遮蔽へ（完全離脱はしない） |
| Dig-in | 可能なら自動開始（敵が近いと中断して交戦） |

### 6.3 Attack Target（目標攻撃）

| 状況 | SOP動作 |
|------|---------|
| 目標CONF | 指定目標を優先 |
| 目標SUS | 面制圧（Attack Area）に自動変換、偵察要素へ"観測優先"を要求 |
| Suppressed | 速度低下＋射撃優先 |
| Pinned | 停止＋遮蔽 |
| Broken | 退避（命令は"維持"されるが、回復後に再開） |

### 6.4 Attack Area（面制圧）

| 特性 | 説明 |
|------|------|
| PID | 不要（SUSでも実行可能） |
| 目的 | Suppression最大化（損耗は副次） |
| 弾薬節約 | 高価弾（戦車KE等）は原則使わない（例外：ArmoredがCONFで入ってきた） |

### 6.5 Recon Route / Observe（偵察）

| 状況 | SOP動作 |
|------|---------|
| 既定ROE | HoldFire（またはReturnFire） |
| 接敵 | 交戦より報告（確度更新）を優先 |
| Pinned以上 | 即退避（偵察の価値＝生存） |

### 6.6 Break Contact（接触離脱）

優先度が最上位に近い命令（手動の安全弁）。

| ルール | 説明 |
|--------|------|
| Smoke | 利用可能なら、退避方向の遮蔽に煙幕（迫撃があれば要請） |
| 移動 | 最短ではなく遮蔽連結を優先 |
| 交戦 | ReturnFireのみ（止まらない） |

### 6.7 Resupply / Reorg（補給・再編）

| 条件 | SOP動作 |
|------|---------|
| AmmoLow / Strength低下 / Cohesion低下 | 自動提案 |
| A1/A2 | 戦闘が落ち着いたと判断したら自律で短距離後退して補給も可 |
| Strict | 手動命令のみ |

---

## 7. 機械化歩兵SOP（Dismount/Remount/リンク）

"分割操作"を、SOPで破綻しない形にする。

### 7.1 既定：Mechanized要素は「リンク（Tether）」を持つ

- INF と VEH は分離しても **相互支援距離** を保とうとする（例：100–200m帯）
- リンクが切れすぎたら、片方は停止して再リンクを優先

### 7.2 Dismount（降車）自律条件（A1/A2で有効）

- 目的地が URBANまたはFOREST縁で、徒歩の方が有利
- 目標（拠点・防御点）まで近いが、車両が危険（AT脅威が高い）
- 進路が狭隘（市街道路・森林小道）で、車両が停滞しやすい

### 7.3 Remount（再乗車）自律条件

- 長距離再配置（Move命令で距離が長い）
- 接敵が薄い／視界優勢で安全
- Break Contact中で"離脱速度"が必要（ただし車両が生きている場合）

> **v0.1の重要ルール**：降車した歩兵は拠点制圧の主役、車両は支援火力と遮蔽提供に寄せる。

---

## 8. 迫撃SOP（ミッション運用の簡略規約）

WEAP（迫撃）は、火力要請が乱発されるとゲームが壊れるので、発射許可の枠を決める。

### 8.1 ミッション種別

| 種別 | 弾種 | 目的 |
|------|------|------|
| Suppress | HE | 抑圧優先 |
| Neutralize | HE | 損耗も狙うが長時間は撃たない |
| Screen | SMOKE | 視界遮断 |

### 8.2 自動発射の許可フラグ（v0.1）

| フラグ | 説明 |
|--------|------|
| `Off` | 手動命令のみ |
| `DefensiveOnly`（既定推奨） | 味方がPinned/Brokenで止まった時だけ自動提案・自動実行 |
| `Full` | 条件を満たせば自動で撃つ |

### 8.3 Danger Close（味方近接）制限

| 弾種 | 味方が効果半径内の場合 |
|------|----------------------|
| HE | 自動で抑制（または確認要求） |
| SMOKE | 許可（危険が少ない） |

> 半径の具体値はRulesetのBlastTierから引ける。

---

## 9. SOPプロファイル（役割別の既定セット）

| 役割 | Autonomy | ROE | 特記 |
|------|----------|-----|------|
| **INF** | A1 | ROE_ReturnFire | PID必要、ATは機会攻撃、遮蔽優先 |
| **REC** | A2 | ROE_HoldFire | 接敵したら報告→退避 |
| **VEH** | A1 | ROE_ReturnFire | SUSはHE面制圧、装甲にはAP |
| **TANK** | A1 | ROE_ReturnFire | 装甲にはKE、歩兵はMG、掩体はHEAT |
| **WEAP** | A1 | - | auto_fire_support=DefensiveOnly、HE/SMOKEは状況で切替 |
| **LOG/HQ** | A1 | - | 交戦回避、補給優先 |

---

## 10. データ雛形（抽象）

```yaml
sop_profile_v0_1:

  - role: INF
    autonomy_level: A1
    roe: ROE_ReturnFire
    pid_required_for_direct_fire: true
    target_priorities:
      - { target_class: Soft, weight: High }
      - { target_class: Fortified, weight: Med }
      - { target_class: Armored_Light, weight: Med, condition: has_at }
      - { target_class: Armored_Heavy, weight: Low }
    weapon_selection:
      default: SmallArms_Ball
      anti_armor: Inf_AT_Rocket_HEAT
      anti_armor_policy: opportunity_only
    movement_policy:
      prefer_cover: true
      suppress_threshold_seek_cover: 40
      pinned_threshold: 70
      broken_threshold: 90

  - role: REC
    autonomy_level: A2
    roe: ROE_HoldFire
    pid_required_for_direct_fire: true
    target_priorities:
      - { target_class: "*", weight: Low }
    behavior_on_contact:
      priority: report_then_evade
      engage: return_fire_only
    movement_policy:
      prefer_cover: true
      evade_on_pinned: true

  - role: VEH
    autonomy_level: A1
    roe: ROE_ReturnFire
    pid_required_for_direct_fire: true
    target_priorities:
      - { target_class: Armored_Heavy, weight: High }
      - { target_class: Armored_Light, weight: High }
      - { target_class: Soft, weight: Med }
      - { target_class: Fortified, weight: Med }
    weapon_selection:
      vs_armored: Autocannon_AP
      vs_soft: Autocannon_HE
      vs_sus: Autocannon_HE  # 面制圧

  - role: TANK
    autonomy_level: A1
    roe: ROE_ReturnFire
    pid_required_for_direct_fire: true
    target_priorities:
      - { target_class: Armored_Heavy, weight: High }
      - { target_class: Armored_Light, weight: High }
      - { target_class: Soft, weight: Med }
      - { target_class: Fortified, weight: Med }
    weapon_selection:
      vs_armored_heavy: Tank_KE_Penetrator
      vs_armored_light: Tank_KE_Penetrator
      vs_soft: MG_HMG_Ball  # Mount B
      vs_fortified: Tank_HEAT_MultiPurpose
      vs_sus: MG_HMG_Ball  # 面制圧

  - role: WEAP
    autonomy_level: A1
    roe: null  # 間接火力なのでROEは別扱い
    auto_fire_support: DefensiveOnly
    mission_types:
      - Suppress
      - Neutralize
      - Screen
    ammo_selection:
      vs_soft_conf: Mortar_HE_Frag
      vs_fortified: Mortar_HE_Frag
      screen_request: Mortar_Smoke_Obscurant
    danger_close_policy:
      he: require_confirmation
      smoke: allowed

  - role: LOG
    autonomy_level: A1
    roe: ROE_HoldFire
    behavior:
      priority: resupply
      engage: avoid
      retreat_on_contact: true

  - role: HQ
    autonomy_level: A1
    roe: ROE_HoldFire
    behavior:
      priority: command_link
      engage: avoid
      retreat_on_contact: true
```

---

## 11. SOP v0.1の達成項目

| 達成項目 | 説明 |
|---------|------|
| **規格差に依存しない** | Variantに閉じ込めた |
| **無効弾を撃つ事故が起きない** | 武器選択SOPで保証 |
| **CONF/SUSの不確実性を活かす** | 面制圧・偵察・煙が自然に出る |
| **司令官視点で意図だけ出すプレイ** | 命令タイプ別SOPで成立 |

---

## 12. 早見表

### 12.1 Autonomy Level

| Level | 命令優先度 | SOP介入 |
|-------|----------|---------|
| A0 (Strict) | 最高 | Broken退避のみ |
| A1 (SelfPreserve) | 高 | 生存に直結する行動 |
| A2 (SemiAutonomous) | 中 | 積極的自律最適化 |

### 12.2 ROE

| ROE | 発砲許可 |
|-----|---------|
| HoldFire | 撃たない |
| ReturnFire | 被攻撃時のみ |
| FreeFire | 自動交戦 |

### 12.3 抑圧閾値と行動

| Suppression | 状態 | SOP行動 |
|-------------|------|---------|
| 0–39 | Normal | 通常行動 |
| 40–69 | Suppressed | 速度低下、射撃優先 |
| 70–89 | Pinned | 停止、遮蔽移動 |
| 90–100 | Broken | 退避、再編 |

### 12.4 弾種選択早見表（TANK）

| 目標 | 弾種 |
|------|------|
| Armored_Heavy | KE → HEAT |
| Armored_Light | KE |
| Soft | MG → HEAT（状況） |
| Fortified | HEAT |
| SUS | MG（面制圧） |

### 12.5 迫撃自動発射許可

| フラグ | 発射条件 |
|--------|---------|
| Off | 手動のみ |
| DefensiveOnly | 味方Pinned/Broken時 |
| Full | 条件充足で自動 |
