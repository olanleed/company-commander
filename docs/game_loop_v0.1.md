# ゲームループ・シーン構造 v0.1

---

## 1. メインループ設計方針

### 1.1 ゴール

- **シミュレーションは必ず 10Hz 固定（dt=0.1s）** で動く
- 描画はフレームレート依存で良い（30/60/144Hzでも同じ試合内容）
- 将来、リプレイ／AAR／マルチ（ロックステップ）に拡張できる

### 1.2 Godot側の前提（分離の基本）

Godotは「毎フレームの `_process()`」と「固定周期の `_physics_process()`」を分けて提供している。
ただし今回のゲームは物理が主役ではないので、**独自の10Hzシムを `_process()` で回す**のが扱いやすい（60Hz物理に引っ張られない）。

---

## 2. 10Hzシミュレーションと描画フレームの分離方法

### 2.1 コア：Fixed Timestep（蓄積器）方式

- `SIM_DT = 0.1`（固定）
- 実フレームの delta を蓄積し、蓄積が `SIM_DT` を超えた分だけシムを1tickずつ進める

#### 擬似コード（仕様）

```gdscript
# 毎フレーム（_process）で呼ぶ
accumulator += real_delta * sim_speed

steps = 0
while accumulator >= SIM_DT and steps < MAX_STEPS_PER_FRAME:
    tick_index += 1
    apply_orders_scheduled_for(tick_index)
    simulate_one_tick(SIM_DT)     # 10Hzの真実
    accumulator -= SIM_DT
    steps += 1

alpha = accumulator / SIM_DT      # 描画用の補間係数（0..1）
render_interpolate(alpha)
```

### 2.2 重要パラメータ（v0.1）

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `SIM_DT` | 0.1 | 10Hzシミュレーションの固定タイムステップ |
| `MAX_STEPS_PER_FRAME` | 8 | 1描画フレームで実行する最大シムステップ数 |

#### MAX_STEPS_PER_FRAMEの意図

- "処理落ちで無限に追いつこうとして破綻する"のを防止
- `steps == MAX_STEPS_PER_FRAME` が頻発した場合：
  - 見た目上はスローモーションになっても、**シムの正しさを優先**（＝結果が変わらないことを優先）

---

## 3. 描画の補間（10Hzでも滑らかに見せる）

10Hzのままだと位置がカクつくので、**描画だけ補間**する（シムは一切変えない）。

### 3.1 状態保持（各エンティティ）

| フィールド | 説明 |
|-----------|------|
| `state_prev` | 前tick確定状態 |
| `state_curr` | 現tick確定状態 |

### 3.2 描画用（Node2D側）

```gdscript
visual_pos = lerp(state_prev.pos, state_curr.pos, alpha)
visual_facing = slerp(state_prev.facing, state_curr.facing, alpha)  # 角度
```

> "結果は10Hzで厳密"、"見た目はフレームで滑らか" を両立。

---

## 4. 決定論（Determinism）規約（v0.1）

将来のリプレイ／AAR／マルチのため、最初から決めておく。

| ルール | 説明 |
|--------|------|
| シム時間 | `tick_index` で管理（浮動小数の累積誤差を避ける） |
| 乱数 | `match_seed` を1つ決め、tick順に消費する |
| 非決定論許可 | 描画補間やUIアニメは非決定論でもOK（ローカル表示だけ） |

---

## 5. 命令（C2遅延）と10Hzシムの接続

C2仕様（Queued→Ack→Exec）を、10Hzに確実に落とす。

### 5.1 命令の内部表現（確定）

| 段階 | 表現 |
|------|------|
| プレイヤー入力で生成 | `OrderIntent` |
| C2遅延計算後 | `Order`（実行tickが確定） |

#### Order が持つフィールド

| フィールド | 説明 |
|-----------|------|
| `issued_tick` | 発令したtick |
| `execute_tick` | 実行するtick |
| `unit_id(s)` | 対象ユニット |
| `command_type` | 命令種別 |
| `params` | 座標、半径、Facing等 |
| `cancelable_until_tick` | Undo用 |

### 5.2 命令キュー処理（確定）

```
各tick開始時に
execute_tick == tick_index のOrderを適用してからシムを進める
```

> 早送りしても遅延やSOPが破綻しない（tick駆動だから）。

---

## 6. シーン遷移

### 6.1 シーン構造（最小・確定）

以下の5シーンで固定（MVPで過不足がない）。

| シーン | 説明 |
|--------|------|
| `TitleScene` | タイトル画面 |
| `MatchSetupScene` | マッチ設定 |
| `LoadingScene` | ロードと初期化（短くても必ず挟む） |
| `GameScene` | ゲーム本編 |
| `ResultScene` | リザルト画面 |

> "一時停止メニュー"はシーンではなく **GameScene内のOverlay（UI）** にする。シーン遷移を増やさない方が事故が減る。

### 6.2 各シーンの責務

#### 6.2.1 TitleScene

- New Game / Load（将来）/ Settings / Quit
- 試合データを持たない

#### 6.2.2 MatchSetupScene

| 設定項目 | 説明 |
|---------|------|
| マップ選択 | 2km×2km |
| 陣営 | NATO/RU/CN |
| ドクトリン | Tank_Balancedなど |
| 初期RP/収入 | 試合設定 |
| 試合時間 | 制限時間 |
| 勝利条件 | チケット等 |
| シード | `match_seed`（ランダム or 固定入力） |

**出力**：`MatchConfig`（Resource/JSONどちらでも）

#### 6.2.3 LoadingScene

責務をここに隔離して、GameSceneは"開始済み"だけ受け取る。

| 処理 | 説明 |
|------|------|
| map背景PNGロード | マップ画像 |
| nav polygonロード | FOOT/WHEELED/TRACKED + ROUTE/ALL |
| 初期ユニット生成 | 配置 |
| match_seed初期化 | 乱数シード |
| SimRunner初期化 | tick=0, accumulator=0 |
| ロード進捗表示 | 任意 |

#### 6.2.4 GameScene（内部サブ構造）

| コンポーネント | 責務 |
|---------------|------|
| `SimRunner` | 10Hzシム本体（tick・accumulator・sim_speed管理） |
| `WorldModel` | 純データ（全ユニット状態、FoW、拠点状態） |
| `WorldView` | 描画専用（補間して表示、アイコン/線/煙幕） |
| `InputRouter` | 入力→OrderIntent |
| `HUD` | コマンド、選択パネル、ミニマップ、ログ |
| `EventBus` | シム→UI（交戦ログ、検知、拠点変化） |

> この分離で「AAR」「リプレイ」「ヘッドレス実行（テスト）」がやりやすくなる。

#### 6.2.5 ResultScene

- 勝敗、チケット推移、損耗、拠点占領推移
- （将来）AAR：タイムライン／リプレイへ

### 6.3 遷移フロー（確定）

```
Title → MatchSetup
MatchSetup → Loading（MatchConfigを渡す）
Loading → Game（初期化完了で遷移）
Game → Result（勝利条件達成 or 退出）
Result → MatchSetup（再戦） or Title
```

---

## 7. 一時停止・早送り（シングルプレイの時間操作）

### 7.1 方針（確定）

| モード | 時間操作 |
|--------|---------|
| シングルプレイ | あり（Pause/1x/2x/4x、＋デバッグ用Tick Step） |
| マルチ（将来） | なし（常に1x、Pauseはローカルメニューのみ） |

> ゲームは情報戦＋C2遅延があるので、シングルでは「考えるためのPause」が有効。マルチでは不公平と同期破綻の原因になる。

### 7.2 実装方式（Godotのpause/time_scaleに依存しない）

#### v0.1固定：シムだけ止める方式

| 状態 | 動作 |
|------|------|
| `sim_speed = 0` | SimRunnerのtickを進めない |
| UI／カメラ／メニュー | 通常通り `_process` で動く |
| ワールド描画 | `state_curr` を固定表示 |

> `Engine.time_scale` は Timer等が影響を受けるなど副作用が広いので、v0.1では使わない（UI・入力・アニメの一貫性優先）。

### 7.3 時間操作の仕様（確定）

#### 7.3.1 速度段階

| 段階 | 説明 |
|------|------|
| 0x（Pause） | シム停止 |
| 1x（通常） | 10 tick/sec |
| 2x | 20 tick/sec |
| 4x | 40 tick/sec |
| Step（デバッグ） | 1 tickだけ進める（dt=0.1固定） |

#### 7.3.2 操作（デフォルト案）

| キー | 機能 |
|------|------|
| `Space` | Pause/Unpause（トグル） |
| `+` / `-` | 速度段階の上下 |
| `.`（ピリオド） | Step（Pause中のみ有効） |

> キー割当はUI割当表と整合させて最終確定でOKだが、「段階と挙動」はここで固定。

#### 7.3.3 早送り時の安全策（スパイラル防止）

| ルール | 説明 |
|--------|------|
| MAX_STEPS_PER_FRAME超過 | "追いつこうとしない" |
| 補間省略 | 早送り時は `alpha` を使わず「最新stateを表示」でもOK（負荷軽減） |

### 7.4 Pause中に可能なこと（確定）

| 操作 | 可否 |
|------|------|
| カメラ移動／ズーム | ○ |
| ユニット選択 | ○ |
| 命令入力（OrderIntent作成） | ○（実行はUnpause後） |
| ツールチップ／ログ閲覧 | ○ |
| マップ注釈（ピン） | ○ |

> 司令官RTSとしての「考える時間」を作る。

---

## 8. まとめ（v0.1決定事項）

| 項目 | 決定内容 |
|------|---------|
| シミュレーション | 10Hz固定、蓄積器方式で描画と分離 |
| 描画補間 | 前後state補間で滑らか（シムの決定論は守る） |
| シーン構成 | Title → MatchSetup → Loading → Game → Result |
| 時間操作 | Pause/2x/4x/Stepを実装（シム速度で制御） |
| Godot依存 | `SceneTree.paused` や `Engine.time_scale` には依存しない |
| Pause方式 | "シム停止"方式で統一 |

---

## 9. 早見表

### 9.1 シム定数

| 定数 | 値 |
|------|-----|
| SIM_DT | 0.1 sec |
| SIM_HZ | 10 Hz |
| MAX_STEPS_PER_FRAME | 8 |

### 9.2 シーン一覧

| シーン | 入力 | 出力 |
|--------|------|------|
| TitleScene | - | 選択結果 |
| MatchSetupScene | - | MatchConfig |
| LoadingScene | MatchConfig | 初期化済みWorldModel |
| GameScene | 初期化済みWorldModel | 試合結果 |
| ResultScene | 試合結果 | 次の遷移先 |

### 9.3 GameScene内部構造

```
GameScene
├── SimRunner          # 10Hzシム本体
├── WorldModel         # 純データ
├── WorldView          # 描画
├── InputRouter        # 入力処理
├── HUD                # UI
│   ├── CommandBar
│   ├── SelectionPanel
│   ├── Minimap
│   └── EventLog
└── EventBus           # シム→UI通信
```

### 9.4 時間操作

| sim_speed | tick/sec | 用途 |
|-----------|----------|------|
| 0 | 0 | Pause |
| 1 | 10 | 通常 |
| 2 | 20 | 早送り |
| 4 | 40 | 高速早送り |

### 9.5 命令フロー

```
Player Input
    ↓
OrderIntent（即時）
    ↓
C2遅延計算
    ↓
Order（execute_tick確定）
    ↓
命令キュー
    ↓
tick_index == execute_tick で適用
    ↓
simulate_one_tick()
```
