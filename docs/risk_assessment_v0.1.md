# ルールベース・リスク評価仕様 v0.1

Company Commander におけるルールベースのリスク評価システム仕様です。
CompanyAI がテンプレート選択、フェーズ遷移、命令生成に使用します。

---

## 0. 出力（CompanyAI が欲しいもの）

### 0.1 RiskReport（点・ルート・エリア共通）

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `risk_total` | `int (0..100)` | 総合リスクスコア |
| `risk_components` | `Dictionary` | 内訳 |
| `risk_flags` | `Array[String]` | リスクフラグ |
| `recommended_mitigations` | `Array[String]` | 推奨対策 |

#### risk_components

| キー | 型 | 説明 |
|-----|-----|------|
| `armor_threat` | `int (0..100)` | 装甲脅威 |
| `at_threat` | `int (0..100)` | 対戦車脅威 |
| `open_exposure` | `int (0..100)` | OPEN横断コスト |

#### risk_flags 例

- `ARMOR_NEAR_CONF`
- `AT_AMBUSH_LIKELY`
- `OPEN_CROSSING_LONG`

#### recommended_mitigations 例

- `SMOKE`
- `RECON_FIRST`
- `STANDOFF`
- `FLANK_ROUTE`
- `BOUNDING`
- `BREAK_CONTACT`

### 0.2 評価対象（3種類）

| 種類 | 説明 | v0.1 |
|-----|------|------|
| `PointRisk` | 特定地点（支援射撃位置、集合点、CP突入点など） | 必須 |
| `RouteRisk` | from→to の経路（Navパス） | 必須 |
| `AreaRisk` | 円/多角形（CP周辺の"突入エリア"など） | Pointの集合で代替可 |

---

## 1. 入力データ

### 1.1 入力ソース

| 入力 | 説明 |
|-----|------|
| FoW ContactDB | 敵コンタクト（CONF/SUS/LOST、推定位置、誤差、type_hint） |
| TerrainGrid | 10mセル推奨：OPEN/ROAD/FOREST/URBAN/WATER |
| HardBlock | 建物等（LoSブロック） |
| SmokeField | 煙幕（LoS透過に影響、ナビには影響なし） |
| CP状態 | CONTROLLED/CONTESTED等（敵が居そうな"重み"の材料） |
| 味方要素 | role/mobility/posture：誰のリスクかで重みが変わる |

### 1.2 更新タイミング

| 頻度 | トリガー |
|-----|---------|
| 1Hz（毎1秒） | CompanyAI用のRouteRisk/PointRiskを定期再計算 |
| イベント駆動（即時） | `EV_CONTACT_CONF_ACQUIRED` / `EV_CONTACT_TYPE_REFINED`（脅威が急変） |
| イベント駆動（即時） | `EV_CP_CONTESTED_ENTER` |
| イベント駆動（即時） | Smoke生成/消滅、HardBlock変化 |

---

## 2. リスクの基本設計

### 2.1 正規化

- 各コンポーネントは `0..100` で出力（上限クランプ）

### 2.2 ヒステリシス（チラつき抑制）

| 条件 | 挙動 |
|-----|------|
| リスクが上がった場合 | 即反映 |
| リスクが下がった場合 | 3秒かけて滑らかに低下（過剰な蛇行を防ぐ） |

```gdscript
risk_smoothed = max(risk_current, risk_prev - decay_per_sec * dt)
# decay_per_sec = 20（3〜5秒で大きく下がる程度）
```

---

## 3. コンポーネント1：装甲脅威（Armor Threat）

装甲脅威は「敵装甲火力の存在・距離・確度」で評価します。
射撃実装前でも ContactDB があれば成立します。

### 3.1 対象となる敵コンタクト

| type_hint | 対象 |
|-----------|------|
| `Armored_Heavy` | ○ |
| `Armored_Light` | ○ |
| `Unknown` | ✕（AT脅威に回す） |

### 3.2 確度重み（v0.1固定）

| ContactState | w_confidence |
|--------------|--------------|
| CONF | 1.0 |
| SUS | 0.6 |
| LOST | 0.2 |

#### 時間経過による減衰

| 状態 | w_recency |
|-----|-----------|
| SUS | `clamp(1 - t_since_seen / 15s, 0, 1)` |
| LOST | `clamp(1 - t_since_seen / 60s, 0, 1)` |

最終：`w_intel = w_confidence * w_recency`

### 3.3 役割別の危険度（v0.1固定）

装甲は誰にとってどれだけ危険かを、重みで表現します。

| friendly_role | W_heavy | W_light |
|--------------|---------|---------|
| INF | 70 | 40 |
| REC | 80 | 50 |
| VEH | 55 | 35 |
| TANK | 60 | 30 |
| WEAP | 75 | 45 |
| LOG/HQ | 90 | 60 |

### 3.4 距離減衰（v0.1固定）

敵装甲1つが与える脅威は距離で減衰。

| クラス | 有効距離 |
|-------|---------|
| Heavy | R_heavy = 1200m |
| Light | R_light = 900m |

距離係数：

```
f(d, R) = clamp(1 - d/R, 0, 1)^2  # 二乗で近距離を強調
```

### 3.5 LoS係数（v0.1簡易）

| 条件 | w_los |
|-----|-------|
| LoSが明確に遮断 | 0.35 |
| LoSが通る/不明 | 1.0 |

※ 煙は LoS透過で自然に効く（煙越しLoSは遮断扱いになりやすい）

### 3.6 装甲脅威の合成（v0.1）

敵コンタクト i ごとに寄与を計算：

```
contrib_i = W_class(role) * w_intel_i * w_los_i * f(d_i, R_class)
```

合成は「足しすぎ」を防ぐため、**上位2件の合計**にする（v0.1の安定策）：

```
# contribを降順に並べ c1 + c2 を採用（無ければ0）
armor_threat = clamp(c1 + c2, 0, 100)
```

---

## 4. コンポーネント2：AT脅威（Anti-Tank Threat）

AT脅威は v0.1 では「敵歩兵の対戦車火器の存在が不確実」なので、環境要因＋接触要因で"待ち伏せ確率"を推定します。

### 4.1 AT脅威の対象（誰が評価するか）

| 対象 | 説明 |
|-----|------|
| VEH / TANK / LOG | 主に評価対象 |
| INF / REC | ATの標的になりにくい（v0.1は重み0でも可） |

### 4.2 AT脅威は2層

| 層 | 射程 | 備考 |
|---|------|------|
| AT_SHORT（RPG/LAW等） | 0〜450m | v0.1の主対象 |
| AT_LONG（ATGM等） | 450〜1200m | イベントや識別が入った時だけ強くする |

### 4.3 近距離AT（AT_SHORT）の推定式

候補点 p について：

#### (A) カバー密度（CoverDensity）

URBAN/FORESTが近いほど待ち伏せ成立。

```
R_cover = 150m
CoverDensity = (#(terrain in {URBAN,FOREST} within R_cover)) / (total cells within R_cover)
# → 0..1
```

#### (B) 敵存在重み（EnemyPresence）

| 条件 | 重み |
|-----|------|
| 敵 CONF Soft が 450m以内 | 1.0 |
| 敵 SUS Soft が 450m以内 | 0.7 |
| 敵 CONTROLLED CP が 450m以内 | 0.6 |
| それ以外 | 0.2（不確実だがゼロにはしない） |

※ Softは「歩兵が居そう」を意味。Unknownは0.4程度にしても良い

#### (C) 進入角の悪さ（ApproachPenalty）

市街・森林の"縁"へ突っ込むほど危険。

| 条件 | 値 |
|-----|-----|
| URBAN/FOREST の内部 | 1.0 |
| URBAN/FOREST の縁 | 0.7 |
| OPEN | 0.3 |

#### (D) 計算

役割別の基礎重み（v0.1固定）：

| 役割 | W_AT_SHORT |
|-----|------------|
| TANK | 80 |
| VEH | 70 |
| LOG | 85 |

```
at_short = W_AT_SHORT * CoverDensity * EnemyPresence * ApproachPenalty
```

### 4.4 遠距離AT（AT_LONG）の扱い（v0.1）

v0.1は「確証がある時だけ」強くします。

#### ATGM確証がある条件（どれか）

- `EV_CONTACT_TYPE_REFINED` で type_hint == ATGM 相当が入った（将来）
- `EV_SHOT_FIRED` / `EV_UNDER_FIRE` で tags.weapon_family == Missile_Guided（将来）

それが無い場合、**AT_LONG = 0**（v0.1既定）

#### 確証がある場合

```
R_atgm = 1200m
at_long = W_AT_LONG * w_intel * f(d, R_atgm)
```

| 役割 | W_AT_LONG |
|-----|-----------|
| TANK | 60 |
| VEH | 50 |
| LOG | 70 |

### 4.5 AT脅威の合成

```
at_threat = clamp(at_short + at_long, 0, 100)
```

---

## 5. コンポーネント3：OPEN横断コスト（Open Exposure Cost）

これは「危険そのもの」ではなく、危険に晒される時間／長さをコスト化して、ルート比較と"煙・迂回"判断に使います。

### 5.1 OPEN横断の定義

候補ルートをサンプルし、OPENセルが連続する区間を抽出する。

| terrain_id | 扱い |
|------------|------|
| OPEN（0） | OPENセル |
| ROAD | "半分OPEN"として扱う（後述） |

### 5.2 "曝露（exposed）"判定（v0.1簡易）

OPEN区間でも敵が居なければコストは低い。
区間ごとに「曝露係数」を付ける：

#### 曝露条件

ルートサンプル点が、いずれかの敵コンタクト（CONF/SUS）と：
- `distance <= 1200m` かつ
- LoSが概ね通る
- → `exposed = true`

#### exposed_strength

| 条件 | 値 |
|-----|-----|
| CONF装甲が近い | 1.0 |
| SUS/Softだけ | 0.6 |
| 敵情報ほぼ無し | 0.2 |

### 5.3 ROADの扱い

ROADセルは open_exposure の計算において **OPENの0.5倍**としてカウント

"道路は速いが目立つ"を両立

### 5.4 区間スコア

連続曝露区間の長さ `L_exposed_m` と移動速度 `v_mps` から時間を推定：

```
t_exposed = L_exposed_m / v_mps
```

役割別重み（v0.1固定）：

| 役割 | W_OPEN |
|-----|--------|
| FOOT | 35 |
| VEH/TANK | 55 |
| LOG | 65 |
| REC | 45 |

スコア（0..100）：

```
open_exposure = clamp(W_OPEN * exposed_strength * (t_exposed / 20s), 0, 100)
```

20秒以上晒されると "危険"が強く出る設計。
これで「短いOPEN横断は許容」「長いOPEN横断は煙や迂回が必要」が自然に出ます。

---

## 6. RouteRisk の作り方（経路比較の核心）

### 6.1 サンプリング（v0.1固定）

```
RISK_SAMPLE_STEP_M = 25m
```

Navパス上を25mおきに点列化し、各点で PointRisk を計算。
ルート全体は「最大値」と「累積」のハイブリッドで評価。

### 6.2 ルート合成（v0.1）

```
armor_max = max(armor_threat at samples)
at_max = max(at_threat at samples)
open_cost = open_exposure computed by segment method
```

#### ベース脅威

```
threat_base = clamp(0.6 * max(armor_max, at_max) + 0.4 * (armor_max + at_max) / 2, 0, 100)
```

#### OPEN補正（OPENは"脅威の倍率"として作用）

```
open_multiplier = 1 + 0.7 * (open_cost / 100)  # 1.0〜1.7
risk_total = clamp(threat_base * open_multiplier, 0, 100)
```

---

## 7. フラグ（risk_flags）の付与ルール

判断を単純化するため、スコアに加えてフラグを立てます。

| フラグ | 条件 |
|-------|------|
| `ARMOR_NEAR_CONF` | Armored_Heavy(CONF) が 900m以内に存在 |
| `ARMOR_PRESENT` | armor_threat >= 50 |
| `AT_AMBUSH_LIKELY` | at_threat >= 60 かつ CoverDensity >= 0.5 |
| `OPEN_CROSSING_LONG` | 曝露OPEN区間の最大連続長 > 80m |
| `OPEN_CROSSING_TRIGGER` | 曝露OPEN区間の最大連続長 > 30m（※既存の煙トリガと一致） |
| `ROUTE_FORCED` | ROUTE指定で迂回不能（ALLフォールバック不可 or 迂回が極端） |

---

## 8. 推奨ミティゲーション（recommended_mitigations）

リスクに対して"何をすべきか"を固定のルールで出します。
（CompanyAIがテンプレートのフェーズで使う）

### 8.1 ミティゲーション一覧（語彙固定）

| ミティゲーション | 説明 |
|----------------|------|
| `RECON_FIRST` | 偵察（Observe）を先に入れる |
| `STANDOFF` | 支援射撃線に止まる（Support-by-fire） |
| `SMOKE` | 煙幕要請（遮蔽線を作る） |
| `FLANK_ROUTE` | 別ルートへ（RouteRiskが低い方を選ぶ） |
| `BOUNDING` | バウンディング（片方移動・片方支援） |
| `DELAY` | 待機（情報更新待ち） |
| `BREAK_CONTACT` | 離脱テンプレへ |

### 8.2 ルール（v0.1）

#### 装甲脅威への反応

| 条件 | 推奨 |
|-----|------|
| `ARMOR_NEAR_CONF` かつ（friendlyにTANKなし、またはAT要素が居ない） | `STANDOFF` + `SMOKE`（可能なら） + `FLANK_ROUTE`（代替があるなら） |
| armor_threat >= 70 | `RECON_FIRST`（SUSなら確定化） + `STANDOFF` |

#### AT脅威への反応（車両）

| 条件 | 推奨 |
|-----|------|
| `AT_AMBUSH_LIKELY` かつ TANK/VEH が URBAN/FOREST 内へ入る計画 | `STANDOFF`（車両は縁に止める） + `RECON_FIRST`（歩兵/偵察を前へ） |
| at_threat >= 75 | `FLANK_ROUTE`（可能なら）、代替なしなら `SMOKE` + `BOUNDING` |

#### OPEN横断への反応

| 条件 | 推奨 |
|-----|------|
| `OPEN_CROSSING_TRIGGER` かつ threat_base >= 50 | `SMOKE`（第一） |
| `OPEN_CROSSING_LONG` かつ threat_base >= 60 | `SMOKE` + `BOUNDING`（支援要素を先に配置） |
| open_cost >= 70（特にLOG） | `FLANK_ROUTE` or `DELAY`（安全になるまで待つ） |

#### 総合での離脱

| 条件 | 推奨 |
|-----|------|
| risk_total >= 85 かつ "任務がMove/Recon" | `BREAK_CONTACT`（または任務中止） |
| risk_total >= 85 かつ "任務がAttack" | `DELAY` + `RECON_FIRST`（情報確定）→それでも高ければ `FLANK_ROUTE` |

---

## 9. テンプレート別「許容リスク閾値」

同じリスクでも任務によって許容度は違うため、テンプレートごとに閾値を固定します。

| Template | Green | Yellow | Orange | Red |
|----------|-------|--------|--------|-----|
| `TPL_RECON` | <=20 | <=35 | <=50 | >50 |
| `TPL_MOVE` | <=25 | <=45 | <=65 | >65 |
| `TPL_ATTACK_CP` | <=30 | <=55 | <=75 | >75 |
| `TPL_DEFEND_CP` | <=35 | <=60 | <=80 | >80 |
| `TPL_BREAK_CONTACT` | 常に許容（ただしSmoke優先） | - | - | - |

- **Orange以上**：ミティゲーション必須
- **Red**：原則、別プラン（迂回/延期/離脱）

---

## 10. デバッグ表示（v0.1強推奨）

実装したら必ず可視化してください（AI調整が地獄から天国になります）。

- ルート上サンプル点の `risk_total` を色で描画（緑→黄→橙→赤）
- `armor_threat` / `at_threat` / `open_cost` をツールチップで表示
- `risk_flags` と `recommended_mitigations` をCompanyAIパネルに表示

---

## 11. v0.1 定数まとめ

```gdscript
# =============================================================================
# Intel weights
# =============================================================================
const W_CONFIDENCE_CONF: float = 1.0
const W_CONFIDENCE_SUS: float = 0.6
const W_CONFIDENCE_LOST: float = 0.2
const SUS_RECENCY_WINDOW_S: float = 15.0
const LOST_RECENCY_WINDOW_S: float = 60.0

# =============================================================================
# Armor threat
# =============================================================================
const R_HEAVY_M: float = 1200.0
const R_LIGHT_M: float = 900.0
const DISTANCE_FALLOFF_POWER: float = 2.0
const LOS_BLOCK_WEIGHT: float = 0.35

# =============================================================================
# AT threat (short)
# =============================================================================
const R_COVER_M: float = 150.0
const AT_SHORT_RANGE_M: float = 450.0
# AT long only if confirmed
const AT_LONG_RANGE_M: float = 1200.0

# =============================================================================
# Open exposure
# =============================================================================
const RISK_SAMPLE_STEP_M: float = 25.0
const OPEN_TIME_NORM_S: float = 20.0
const ROAD_OPEN_FACTOR: float = 0.5

# =============================================================================
# Thresholds
# =============================================================================
const ARMOR_NEAR_CONF_M: float = 900.0
const OPEN_CROSSING_TRIGGER_M: float = 30.0
const OPEN_CROSSING_LONG_M: float = 80.0

# =============================================================================
# Smoothing
# =============================================================================
const RISK_DECAY_DOWN_PER_SEC: float = 20.0
```

---

## ここまでで何ができるようになるか

射撃が無くても CompanyAI は：

1. **中央へ突っ込む前に偵察する**
2. **OPENを横断する時だけ煙を焚く**
3. **装甲脅威やAT待ち伏せが高い都市縁を避ける**
4. **支援射撃線（standoff）を自然に作る**
5. **リスクが高すぎるなら離脱・迂回する**

という "軍事的にそれっぽい" プロセスをルールベースで実行できます。
