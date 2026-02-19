# 命令キュー実装詳細 v0.1

---

## 0. 用語と前提

| 項目 | 値 |
|------|-----|
| `SIM_DT` | 0.1s（10Hz） |
| `TICKS_PER_SEC` | 10 |

### 命令の扱い

- 命令は「プレイヤー入力の1回」を **OrderBatch** として扱い、複数ユニットに同時適用されることがある

### 命令の状態

| 状態 | 説明 |
|------|------|
| **Queued** | 司令部側に保持（まだ当該ユニットに届いていない） |
| **Ack** | ユニットが受領（次に実行できる状態で待機） |
| **Exec** | 実行中（その命令がアクティブ） |

> **重要**：Undoは"時間巻き戻し"ではない。あくまで「まだ届いていない命令を取り消す」or「キュー内容を戻す」だけ。

---

## 1. ウェイポイント最大数（確定）

### 1.1 ウェイポイントの扱い（v0.1の実装方針）

Shiftで連続指定する「移動ウェイポイント列」は、**複数のMove命令ではなく 1つの MoveRoute命令（waypoints配列）**として保持する。

→ キューが膨れず、表示も分かりやすい

### 1.2 最大数（ハード上限）

| 上限 | 値 |
|------|-----|
| 1つの MoveRoute が持てるウェイポイント最大数 | **12** |
| 1ユニットが保持できる命令キュー最大数 | **10** |

```
MAX_WAYPOINTS_PER_ROUTE = 12
MAX_ORDERS_PER_UNIT = 10
```

**例**：MoveRoute(最大12点) → Defend → Smoke → … といった複合が可能。
それ以上は入力を拒否し、HUDに短いトーストで通知（例：「Waypoint limit 12」「Queue limit 10」）。

### 1.3 追加規約（ルートのマージ）

「最後のキュー要素がMoveRoute」かつ「ShiftでMove指定」なら：
- その MoveRoute の waypoints に追加（上限12まで）

それ以外は：
- 新しい MoveRoute をキュー末尾に追加（上限10まで）

---

## 2. 命令の Queued→Ack→Exec 遷移

### 2.1 2段構成（確定）

実装を迷わないよう、責務を分ける。

#### OrderNetwork（司令部〜部隊の伝達）

- **Queued → Ack** を担当（「届く」）
- tick駆動で配送する

#### UnitOrderQueue（各ユニットの実行）

- **Ack → Exec** を担当（「実行開始」）
- "先頭の命令だけ"がExecに上がる（順次実行）

### 2.2 Queued → Ack（伝達遅延）の計算式（確定）

各ユニットには `comm_quality` (0..100) がある（units_v0.1で定義済み）。

#### 伝達遅延（秒）

```
comm_delay_sec = clamp(15 - 0.10 * comm_quality, 5, 20)
```

| comm_quality | 遅延 |
|--------------|------|
| 0 | 15s |
| 100 | 5s（最短） |

#### tick換算

```
comm_delay_ticks = ceil(comm_delay_sec * TICKS_PER_SEC)
```

#### Ack tick

```
ack_tick = issued_tick + comm_delay_ticks
```

#### 通信状態による条件

| 条件 | 挙動 |
|------|------|
| `comms_connected == true` | 通常どおり進む |
| `comms_connected == false` | 命令は Queuedのまま停止、UIに「NO COMMS」表示（ETA不明） |

通信復旧tickを `t_restore` とすると：
```
ack_tick = t_restore + comm_delay_ticks（復旧後に配送開始）
```

> v0.1ではジャミング等は未実装でもOK。まず `comms_connected` は常にtrueで回し、後で拡張可能。

### 2.3 Ack → Exec（反応・準備）の既定値（確定）

命令を受領しても、部隊が「動き始める」までに反応遅延を入れる。

#### 2.3.1 基本反応時間（秒）

| 命令タイプ | base_reaction_sec |
|-----------|-------------------|
| Engage / Attack | 1.0 |
| Suppress Area | 1.0 |
| MoveRoute | 2.0 |
| Recon/Observe | 2.0 |
| Defend | 2.5 |
| Support Fire（迫撃HE要請/自部隊迫撃） | 2.0 |
| Smoke（迫撃煙要請/自部隊迫撃） | 2.0 |
| Break Contact | 0.5 |
| Resupply/Reorg | 2.5 |

#### 2.3.2 状態倍率（抑圧の影響）

| 状態 | 倍率 |
|------|------|
| Normal | ×1.0 |
| Suppressed | ×1.5 |
| Pinned | ×2.0 |
| Broken | ×∞（Exec不可） |

**例外**：Break Contact は Broken でも Exec 可（生存行動）

#### 2.3.3 autonomy（自律）補正

| 自律レベル | 補正 |
|-----------|------|
| A0 Strict | +0.5s（慎重で遅い） |
| A1 SelfPreserve | +0.0s |
| A2 SemiAutonomous | -0.3s（素早い） |

#### planned exec tick

```
reaction_sec = (base_reaction_sec * M_supp) + autonomy_bonus_sec
exec_tick_earliest = ack_tick + ceil(reaction_sec * TICKS_PER_SEC)
```

### 2.4 Execの開始条件（順序実行の条件）（確定）

命令が Ack していても、実行は「そのユニットの先頭命令」だけ。

#### 命令 order_i が Exec に上がる条件

1. `order_i` が ユニットのローカルキュー先頭
2. `current_tick >= order_i.exec_tick_earliest`
3. `order_i.preconditions_met == true`

#### preconditions_met のv0.1既定

| 命令 | 条件 |
|------|------|
| Move/Defend/BreakContact/Resupply | 常にtrue（到達できないときはナビ側がフォールバック） |
| Engage | ターゲットがCONF（SUSなら自動でSuppressAreaに変換） |
| SupportFire/Smoke | 呼び出し先（迫撃）が存在しない場合は「要請失敗」で完了扱い（ログに残す） |

### 2.5 "置換（REPLACE）" と "追加（APPEND）" の規約

入力操作と一致させる。

#### Shiftなし：REPLACE

- 司令部側で「まだQueuedの旧命令」は破棄
- 新命令は `priority = Immediate` として配送（Ackしたら先頭に入る）
- 既にAck済み/Exec中の旧命令は、新命令が到着した時点でプリエンプト可能（下記）

#### Shiftあり：APPEND

- 新命令を「末尾に追加」（MoveRouteは前述のマージ規則あり）

#### プリエンプト規約（v0.1）

REPLACE で到着した Immediate命令は：

| 命令タイプ | プリエンプト |
|-----------|-------------|
| 移動系（Move/BreakContact） | 即プリエンプト（次tickで切替） |
| 射撃系（Engage/Suppress） | 0.5秒以内に切替（"射撃バースト中断"の違和感を減らす） |
| Defend | 移動完了後に姿勢へ（Exec切替は即） |

---

## 3. 命令の完了条件

キュー実装のために必要な最小限をv0.1で確定。

| 命令 | 完了条件 |
|------|---------|
| **MoveRoute** | 最終ウェイポイントに到達（距離 ≤ 5m）で完了 |
| **Engage/Attack** | ターゲット撃破 または LOSTが5秒継続で完了（SOPに戻る） |
| **Suppress Area** | 既定 duration_sec = 10 で完了（長押し指定で延長はv0.2） |
| **Recon/Observe** | 到達後 observe_sec = 12 観測して完了（完了後はHold姿勢） |
| **Defend** | 完了しない（常駐）→ キューの最後に置く運用が基本 |
| **SupportFire/Smoke** | ミッション弾数（または時間）消化で完了 |
| **Break Contact** | 退避点到達、かつ suppression < 40 が5秒継続で完了（その後はHold） |
| **Resupply/Reorg** | 補給完了で完了 |

---

## 4. 命令取り消し（Undo）の巻き戻し範囲（確定）

### 4.1 Undoは「巻き戻し」ではなく「未配送命令の撤回」

- シムの状態（位置・被害・弾薬・拠点占領など）は**一切巻き戻さない**
- Undoが触れるのは：
  - **Queued 状態の命令**（＝まだ部隊に届いてない命令）
  - と、その命令によって書き換えられた "司令部側キュー" のみ

### 4.2 Undo可能な範囲（時間と深さ）

| パラメータ | 値 |
|-----------|-----|
| Undoウィンドウ | 30 tick（= 3.0秒） |
| Undoスタック深さ | 20バッチ |

```
UNDO_WINDOW_TICKS = 30
UNDO_STACK_MAX = 20
```

#### Undo成功条件（v0.1で明確化）

Undo対象の OrderBatch に含まれる命令が、影響ユニットすべてで **まだ Queued** の場合のみ「完全巻き戻し」可能。

> 伝達遅延の最短が 5秒（50tick）なので、通常は「3秒以内＝まだQueued」で、Undoは確実に効く。
> つまり **Undoは"HQで撤回できる現実的な猶予"**として成立。

### 4.3 部分Undo規約（Ack 済みが混ざっていた場合）

現実にも「届いた命令は取り消せない」ため：

バッチ内に Ack/Exec の命令が1つでもある場合：
- Queuedの分だけは撤回（取り消し）
- Ack/Exec分は撤回不可（ログに「UNDO PARTIAL：order already acknowledged」）
- プレイヤーは新規命令（REPLACE）で上書きするしかない

### 4.4 取り消し時に復元するもの

OrderBatchは発行時に 各ユニットの司令部側キューのスナップショットを持つ。

#### Undo実行時

- 司令部側キューをそのスナップショットに戻す（Queuedのみ対象）
- UI上のプレビュー線/ウェイポイント表示も即更新
- RPや弾薬などゲーム資源は変化しない（命令は無料）

---

## 5. デバッグ/表示（v0.1推奨）

ユニット選択時、命令キューを次の形で表示（HUDの小パネルで十分）：

各命令に：
- `state`: Q / A / E
- `ETA_to_ack_sec`
- `ETA_to_exec_sec`
- MoveRouteは waypoints数も表示（例：MoveRoute(7)）

> これがあると、C2遅延が「理不尽」ではなく「理解できる仕様」に変わる。

---

## 6. 早見表

### 6.1 上限値

| パラメータ | 値 |
|-----------|-----|
| MAX_WAYPOINTS_PER_ROUTE | 12 |
| MAX_ORDERS_PER_UNIT | 10 |

### 6.2 伝達遅延

```
comm_delay_sec = clamp(15 - 0.10 * comm_quality, 5, 20)
```

| comm_quality | 遅延 |
|--------------|------|
| 0 | 15s |
| 50 | 10s |
| 100 | 5s |

### 6.3 基本反応時間

| 命令 | 秒 |
|------|-----|
| Engage/Attack | 1.0 |
| Suppress Area | 1.0 |
| MoveRoute | 2.0 |
| Recon/Observe | 2.0 |
| Defend | 2.5 |
| SupportFire/Smoke | 2.0 |
| Break Contact | 0.5 |
| Resupply/Reorg | 2.5 |

### 6.4 抑圧による反応倍率

| 状態 | 倍率 |
|------|------|
| Normal | ×1.0 |
| Suppressed | ×1.5 |
| Pinned | ×2.0 |
| Broken | ×∞ |

### 6.5 自律補正

| レベル | 補正 |
|--------|------|
| A0 Strict | +0.5s |
| A1 SelfPreserve | +0.0s |
| A2 SemiAutonomous | -0.3s |

### 6.6 Undo

| パラメータ | 値 |
|-----------|-----|
| UNDO_WINDOW_TICKS | 30（=3秒） |
| UNDO_STACK_MAX | 20 |

### 6.7 命令状態遷移

```
Queued ──(comm_delay)──> Ack ──(reaction_time)──> Exec ──(completion)──> Done
```

### 6.8 確定事項まとめ

| 項目 | 決定内容 |
|------|---------|
| ウェイポイント | 1 MoveRoute に最大12点、キュー最大10命令 |
| 伝達遅延 | comm_quality依存、5〜15秒 |
| 反応遅延 | 命令タイプ×抑圧倍率×自律補正 |
| Undo | Queuedのみ完全復元、Ack/Execは撤回不可 |
| プリエンプト | REPLACE時、移動系は即、射撃系は0.5秒以内 |
