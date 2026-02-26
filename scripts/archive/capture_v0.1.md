# CP占領仕様 v0.1

---

## 1. 目的と設計方針

- **占領は"その場に居ること"＋"戦闘力が維持されていること"** で進む
- 敵が現に居る（＝争奪）なら占領は進まない（CONTESTEDで停止）
- 装甲は"奪取（neutralize）"はできるが、"確保（capture）"は**歩兵が主役**
- ただしゲームが詰まらないように「装甲だけで敵支配を中立化」までは可能にする（リアリティとゲーム性の折衷）

---

## 2. CPデータモデル

### 2.1 マップ側（固定）

各CPは以下を持つ：

| フィールド | 説明 |
|-----------|------|
| `cp_id` | A〜E |
| `cp_type` | COM/LOG/OBS など（占領ルール自体には影響しない） |
| `zone` | 円（推奨） |
| `zone.center` | (x, y) |
| `zone.radius_m` | 40 |
| `arrival_points[]` | Forward Entry用（拠点に紐づくスポーン点） |

### 2.2 試合中状態（動的）

| フィールド | 説明 |
|-----------|------|
| `control_milli` | -100000 〜 +100000（整数） |

#### control_milliの意味

| 値 | 状態 |
|----|------|
| +100000 | Blueが完全支配 |
| 0 | 中立 |
| -100000 | Redが完全支配 |

#### state（表示・ロジック用）

| state | 説明 |
|-------|------|
| `CONTROLLED_BLUE` | Blue完全支配 |
| `CONTROLLED_RED` | Red完全支配 |
| `NEUTRAL` | 中立 |
| `CAPTURING_BLUE` | 0→+100へ進行中 |
| `CAPTURING_RED` | 0→-100へ進行中 |
| `NEUTRALIZING_BLUE` | -100→0へ進行中 |
| `NEUTRALIZING_RED` | +100→0へ進行中 |
| `CONTESTED` | 争奪中（進行停止） |

> チケット計算・Forward Entryの解放に使うのは **"CONTROLLED_*" のみ**。
> CONTESTEDや途中経過はカウントしない。

---

## 3. ゾーン内判定（誰が占領に関与するか）

### 3.1 ゾーン内（in_zone）

```
要素（Element）の代表点（中心）pos が
distance(pos, cp.center) <= cp.radius_m なら in_zone
```

### 3.2 占領寄与の対象外（v0.1固定）

以下はゾーン内に居ても占領・争奪に寄与しない：

| 除外対象 | 理由 |
|---------|------|
| LOG / HQ 役割 | captureもcontestも0 |
| WEAP（迫撃）役割 | captureもcontestも0 |
| Strength ≤ 15 | 壊滅/CI扱い |

---

## 4. 占領パワーの3種類分離（核心）

各要素はCPに対して**3つの力**を持つ：

| パワー | 役割 |
|--------|------|
| **CapturePower（確保）** | 0→自陣営支配へ進める力 |
| **NeutralizePower（奪取）** | 敵支配（±100）を0へ戻す力 |
| **ContestPower（争奪）** | 敵の占領進行を止める力（存在による拒否） |

> これにより「戦車だけで旗が取れるのは不自然」を避けつつ、
> 「戦車で拠点を掃除したのに永遠に赤のまま」も避けられる。

---

## 5. 役割ごとの基礎パワー（v0.1固定）

| 役割 | CapturePower_base | NeutralizePower_base | ContestPower_base |
|------|-------------------|---------------------|-------------------|
| **INF** | 1.00 | 1.00 | 1.00 |
| **REC** | 0.70 | 0.70 | 0.80 |
| **VEH**（IFV/APC等） | 0.00 | 0.40 | 0.80 |
| **TANK** | 0.00 | 0.60 | 1.00 |
| **WEAP**（迫撃等） | 0.00 | 0.00 | 0.00 |
| **LOG / HQ** | 0.00 | 0.00 | 0.00 |

---

## 6. 状態による倍率

### 6.1 Strength倍率

```
M_strength = Strength / 100
ただし Strength <= 15 のとき M_strength = 0
```

### 6.2 Suppression倍率

| 状態 | 倍率 |
|------|------|
| Normal | 1.00 |
| Suppressed | 0.50 |
| Pinned | 0.20 |
| Broken | 0.00 |

### 6.3 姿勢倍率（v0.1）

| 姿勢 | 倍率 |
|------|------|
| Defend / Dig-in | 1.00 |
| Attack | 0.90 |
| Move | 0.80 |
| Break Contact | 0.60 |

### 6.4 有効パワー計算

```
CapturePower = base_capture × M_strength × M_supp × M_posture
NeutralizePower = base_neutralize × M_strength × M_supp × M_posture
ContestPower = base_contest × M_strength × M_supp × M_posture
```

---

## 7. スタッキング上限（スタックゲー化防止）

拠点内に大量に重ねても速度が跳ね上がらないよう、サイドごとに上限を設ける。

| 上限 | 値 |
|------|-----|
| `CAPTURE_CAP` | 2.0 |
| `NEUTRALIZE_CAP` | 2.0 |
| `CONTEST_CAP` | 3.0 |

#### 集計（Blue側の例）

```
sum_capture_blue = Σ CapturePower (in_zone)
eff_capture_blue = min(sum_capture_blue, CAPTURE_CAP)
```

neutralize/contestも同様。

---

## 8. CONTESTEDの定義（占領停止の条件）

```
eff_contest_blue > 0.05 かつ eff_contest_red > 0.05
→ state = CONTESTED
→ control_milli は変化しない（完全停止）
```

- Pinnedの歩兵や車両でも「居るだけで争奪」にはなるが、倍率で弱くなる
- Brokenは0なので争奪から脱落する（押し出された扱い）

---

## 9. 占領進行（10Hz tickでの更新式）

### 9.1 進行速度の基準（v0.1固定）

| パラメータ | 値 |
|-----------|-----|
| `CAPTURE_RATE` | 1.5（controlポイント/秒/有効パワー） |

#### 内部計算（milli）

```
delta_milli = CAPTURE_RATE × eff_power × 1000 × dt
dt = 0.1 なので
delta_milli = 150 × eff_power（1tickあたり）
```

### 9.2 更新アルゴリズム（確定）

各tickの開始時に、CPごとに以下を実行：

#### Step 1: Contest判定

```
eff_contest_blue/red を計算
両方 > 0.05 → CONTESTED、終了（値は変えない）
```

#### Step 2: 片方だけ存在する場合

例：Blueのみ存在（eff_contest_blue > 0.05、eff_contest_red ≤ 0.05）

**(A) control_milli が負（Red寄り）なら：Neutralize**

```
eff_neutralize_blue を計算
control_milli += 150 × eff_neutralize_blue
control_milli = min(control_milli, 0)
→ 状態は NEUTRALIZING_BLUE
```

**(B) control_milli が 0以上なら：Capture**

```
eff_capture_blue を計算
control_milli += 150 × eff_capture_blue
control_milli = min(control_milli, +100000)
→ 状態は CAPTURING_BLUE
```

**装甲だけの場合（capture=0）**

- 0に到達後はそれ以上進まない（中立で止まる）

Redも同様に符号を反転して処理。

### 9.3 誰も居ない場合

```
eff_contest_blue <= 0.05 かつ eff_contest_red <= 0.05
→ control_milli は変化しない（途中経過は保持）
```

---

## 10. 状態の確定（CONTROLLED/NEUTRAL）

更新後に、stateを最終決定する（CONTESTED優先は既に処理済み）。

| 条件 | state |
|------|-------|
| control_milli == +100000 | CONTROLLED_BLUE |
| control_milli == -100000 | CONTROLLED_RED |
| control_milli == 0 かつ占領進行していない | NEUTRAL |
| それ以外 | CAPTURING_* / NEUTRALIZING_* を維持 |

---

## 11. チケット・Forward Entryとの接続

### 11.1 チケット計算に使う「保持数」

| state | カウント |
|-------|---------|
| CONTROLLED_BLUE | N_blueに+1 |
| CONTROLLED_RED | N_redに+1 |
| CONTESTED / NEUTRAL / 途中状態 | カウントしない |

### 11.2 Forward Entry（前進スポーン）の可否

| 条件 | Forward Entry |
|------|--------------|
| CONTROLLED_* かつ 非CONTESTED | **使用可** |
| CONTESTED または途中状態 | **使用不可**（Rearへリルート） |

---

## 12. UI表示

### 12.1 CPアイコン

- 周囲に**リング**（-100→+100のバー）
- 色：青＝Blue寄り、赤＝Red寄り、灰＝中立

### 12.2 状態ラベル

- CONTESTEDは明確に表示（例：⚠ CONTESTED）

### 12.3 ツールチップ（強く推奨）

```
Blue: capture 1.4 / contest 0.9
Red:  capture 0.0 / contest 0.3
```

eff_powerを表示（デバッグにも有用）。

---

## 13. バランス調整ノブ

v0.1で触るならここだけ：

| パラメータ | 説明 |
|-----------|------|
| `CAPTURE_RATE` | 占領速度の根幹 |
| `CAPTURE_CAP` / `NEUTRALIZE_CAP` / `CONTEST_CAP` | スタック効果 |
| 役割別 base_power | INF/VEH/TANKの"拠点価値" |
| Contest閾値 0.05 | Pinned車両1台で止まるのが嫌なら上げる |

---

## 14. 成立する戦術

この仕様で成立する戦術（設計意図）：

| 戦術 | 仕様上の根拠 |
|------|-------------|
| **歩兵が拠点の主役** | captureがあるのはINF/RECのみ |
| **装甲は拠点を"掃除して中立化"** | neutralizeは可能 |
| **敵が残っている限り占領は進まない** | CONTESTED停止＝火力で排除が必要 |
| **抑圧→前進→占領** | Suppressionが占領を止める（Pinned=0.2、Broken=0） |

---

## 15. 早見表

### 15.1 役割別基礎パワー

| 役割 | Capture | Neutralize | Contest |
|------|---------|------------|---------|
| INF | 1.00 | 1.00 | 1.00 |
| REC | 0.70 | 0.70 | 0.80 |
| VEH | 0.00 | 0.40 | 0.80 |
| TANK | 0.00 | 0.60 | 1.00 |
| WEAP | 0.00 | 0.00 | 0.00 |
| LOG/HQ | 0.00 | 0.00 | 0.00 |

### 15.2 倍率表

| Suppression | 倍率 |
|-------------|------|
| Normal | 1.00 |
| Suppressed | 0.50 |
| Pinned | 0.20 |
| Broken | 0.00 |

| 姿勢 | 倍率 |
|------|------|
| Defend/Dig-in | 1.00 |
| Attack | 0.90 |
| Move | 0.80 |
| Break Contact | 0.60 |

### 15.3 パラメータ

| パラメータ | 値 |
|-----------|-----|
| CAPTURE_RATE | 1.5 /sec/power |
| CAPTURE_CAP | 2.0 |
| NEUTRALIZE_CAP | 2.0 |
| CONTEST_CAP | 3.0 |
| Contest閾値 | 0.05 |
| control_milli範囲 | -100000 〜 +100000 |

### 15.4 占領時間の目安

| 状況 | eff_power | 時間（0→100） |
|------|-----------|--------------|
| INF×1（Normal） | 1.0 | 約67秒 |
| INF×2（Normal） | 2.0（CAP） | 約33秒 |
| INF×1（Suppressed） | 0.5 | 約133秒 |
| TANK×2（capture=0） | 0.0 | 中立化のみ（captureは進まない） |
