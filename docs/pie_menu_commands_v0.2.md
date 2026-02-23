# パイメニュー コマンド設計 v0.2

## 概要

ユニットタイプ別にパイメニュー（放射状コマンド）で出せる命令を整理する。
Wargame: Red Dragonを参考に、ユニットの役割に応じたコマンド体系を設計。

### 設計方針

1. **共通コマンドは位置固定** - 筋肉記憶を維持（Move, Stop, Attack等）
2. **ユニット固有コマンドは空きスロットに配置** - 使えないコマンドはグレーアウト
3. **8スロット厳守** - Hick's Law対策、選択肢が多すぎると遅くなる
4. **実用性重視** - 使わないコマンドは削除、頻度の高い操作を優先
5. **移動と射撃の分離** - 「動く」と「撃つ/撃たない」はSOPで分離制御
6. **AIロジックをシンプルに** - 複雑な状態遷移を避ける

---

## 1. ユニットカテゴリ分類

| カテゴリ | アーキタイプ例 | 主な特徴 |
|---------|--------------|---------|
| **戦車** | TANK_PLT, LIGHT_TANK | 直射火力、重装甲、機動力 |
| **装甲戦闘車** | IFV_PLT, APC_PLT | 歩兵輸送、中程度の火力 |
| **砲兵** | SP_ARTILLERY, SP_MORTAR, MLRS | 間接射撃、煙幕、照明 |
| **歩兵** | INF_LINE, INF_AT, INF_MG | 占領能力、対戦車、伏撃 |
| **偵察** | RECON_VEH, RECON_TEAM | 視界、隠密、情報収集 |
| **対空** | SPAAG, SAM_VEH | 対空射撃 |
| **支援** | LOG_TRUCK, COMMAND_VEH, MEDICAL_VEH | 補給、指揮、回収 |

---

## 2. 共通コマンド（全ユニット）

以下のコマンドは全ユニットで使用可能。位置は固定。

| 方向 | コマンド | 説明 | 備考 |
|------|---------|------|------|
| ↑ (N) | **Move** | 指定地点へ移動して停止 | 射撃はSOPに従う |
| → (E) | **Attack** | 指定した敵を攻撃 | 目標を追尾・射撃 |
| ↓ (S) | **Stop** | 即座に停止 | 現在の移動をキャンセル |
| ↖ (NW) | **Break Contact** | 戦闘離脱 | 煙幕＋後退 |

### Move + SOP による射撃制御

移動中の射撃はSOPで制御。現代戦車は走行間射撃が可能。

| SOP | Move中の挙動 |
|-----|-------------|
| **Hold Fire** | 撃たない（隠密移動） |
| **Return Fire** | 撃たれたら反撃 |
| **Fire at Will** | 視界内の敵を撃つ（走行間射撃） |

これにより**Attack Moveは不要**。Move + Fire at Will で同等の効果。

---

## 3. ユニットタイプ別コマンド

### 3.1 戦車（TANK_PLT, LIGHT_TANK）

主力として直射火力を提供。機動と火力のバランスが重要。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Fire Position** | 射撃陣地へ移動（Hull-down想定） | ★★☆ |
| → | Attack | 指定目標を攻撃 | ★★★ |
| ↘ | *(空き)* | - | - |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | **Reverse** | 後退（正面を維持したまま後退） | ★★★ |
| ← | **Smoke** | 発煙弾発射（装備車両のみ） | ★★☆ |
| ↖ | Break Contact | 離脱 | ★★★ |

**戦術メモ**:
- Reverse: 正面装甲を敵に向けたまま後退。戦車戦の基本
- Fire Position: 稜線射撃位置への移動（Hull-down）
- 走行間射撃: Move + SOP(Fire at Will) で実現

---

### 3.2 装甲戦闘車（IFV_PLT, APC_PLT）

歩兵輸送と火力支援。下車歩兵との連携が重要。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Unload** | 搭乗歩兵を下車（指定位置で下車） | ★★★ |
| → | Attack | 攻撃 | ★★★ |
| ↘ | *(空き)* | - | - |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | **Reverse** | 後退 | ★★☆ |
| ← | Smoke | 発煙弾発射 | ★★☆ |
| ↖ | Break Contact | 離脱 | ★★★ |

**IFV vs APC の違い**:

- IFV: 機関砲・ATGM装備 → Attackが有効
- APC: 火力貧弱 → 輸送に専念、Unloadが重要

**乗車について**:

- 歩兵がBoardコマンドで車両を指定して乗車する方式
- 車両側からLoadを発行する必要はない

---

### 3.3 砲兵（SP_ARTILLERY, SP_MORTAR, MLRS）

間接射撃による火力支援。直接戦闘は避ける。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Deploy** | 射撃陣地展開（展開完了まで射撃不可） | ★★★ |
| → | **Fire Mission HE** | 榴弾射撃（指定エリア） | ★★★ |
| ↘ | **Fire Mission Smoke** | 煙幕射撃（指定エリア） | ★★★ |
| ↓ | Stop | 即座に停止 | ★★☆ |
| ↙ | **Fire Mission Illum** | 照明弾射撃（夜間視界確保） | ★☆☆ |
| ← | **Cease Fire** | 射撃中止・移動準備 | ★★☆ |
| ↖ | Break Contact | 離脱 | ★★★ |

**戦術メモ**:
- 砲兵は脆弱なので位置変更（Shoot and Scoot）が重要
- 迫撃砲: 煙幕・照明弾が重要
- 自走砲: 長射程HEが主任務
- MLRS: 面制圧、再装填に時間がかかる

---

### 3.4 歩兵（INF_LINE, INF_AT, INF_MG）

占領能力と対戦車能力。地形利用と伏撃が重要。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Fast Move** | 急速移動（遮蔽無視、発見されやすい） | ★★☆ |
| → | Attack | 攻撃 | ★★★ |
| ↘ | **Ambush** | 待ち伏せ（SOP: Hold Fireで待機、近距離で射撃） | ★★★ |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | **Dig In** | 塹壕構築（防御力向上、時間がかかる） | ★☆☆ |
| ← | **Board** | 近くの車両に乗車 | ★★☆ |
| ↖ | Break Contact | 離脱 | ★★★ |

**ユニットサブタイプ別**:
- INF_LINE: 汎用、占領能力高
- INF_AT: Ambushが重要（ATGM/RPG伏撃）
- INF_MG: 制圧射撃が得意

---

### 3.5 偵察（RECON_VEH, RECON_TEAM）

情報収集と視界確保。戦闘は避ける。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Recon Move** | 偵察前進（慎重、SOP: Hold Fire推奨） | ★★★ |
| → | Attack | 攻撃（緊急時のみ） | ★★☆ |
| ↘ | **Observe** | 監視（移動停止、視界集中） | ★★★ |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | **Hide** | 隠蔽（発見されにくくなる） | ★★☆ |
| ← | Smoke | 煙幕（装備時） | ★☆☆ |
| ↖ | Break Contact | 離脱 | ★★★ |

**戦術メモ**:
- 偵察は「見つける」が最重要
- 戦闘に巻き込まれたら即離脱
- 良い視界位置の確保が勝敗を分ける

---

### 3.6 対空（SPAAG, SAM_VEH）

対空射撃。航空機の脅威から部隊を守る。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | *(空き)* | - | - |
| → | **Engage Air** | 対空射撃（航空機優先） | ★★★ |
| ↘ | **Engage Ground** | 対地射撃（SPAAGのみ） | ★★☆ |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | *(空き)* | - | - |
| ← | *(空き)* | - | - |
| ↖ | Break Contact | 離脱 | ★★★ |

**備考**:
- 現バージョンでは航空機未実装
- 将来の拡張に備えた設計

---

### 3.7 支援（LOG_TRUCK, COMMAND_VEH, MEDICAL_VEH）

後方支援。戦闘能力は低いが重要な役割。

| 方向 | コマンド | 説明 | 実装優先度 |
|------|---------|------|-----------|
| ↑ | Move | 移動して停止 | ★★★ |
| ↗ | **Follow** | 指定ユニットに追随 | ★★☆ |
| → | **Resupply** | 補給（LOG_TRUCKのみ） | ★★★ |
| ↘ | **Evacuate** | 負傷者回収（MEDICAL_VEHのみ） | ★☆☆ |
| ↓ | Stop | 即座に停止 | ★★★ |
| ↙ | *(空き)* | - | - |
| ← | *(空き)* | - | - |
| ↖ | Break Contact | 離脱 | ★★★ |

---

## 4. SOP（交戦規則）

パイメニューとは別に、SOPモードを切り替えられる仕組み。
**「動く」と「撃つ/撃たない」を分離**する設計の要。

| SOPモード | 説明 | 用途 |
|----------|------|------|
| **Hold Fire** | 射撃禁止 | 伏撃待機、隠密移動、位置秘匿 |
| **Return Fire** | 反撃のみ | 防御時、弾薬節約 |
| **Fire at Will** | 自由射撃 | 攻撃時、交戦中、走行間射撃 |

### 実装案

- ボトムバーにSOPトグルを追加
- Tab キーでSOP切り替え
- 選択中ユニットのSOP状態を右パネルに表示

### Move + SOP の組み合わせ例

| 目的 | コマンド | SOP |
|------|---------|-----|
| 隠密移動（撃たれても反撃しない） | Move | Hold Fire |
| 通常移動（撃たれたら反撃） | Move | Return Fire |
| 攻撃前進（走行間射撃） | Move | Fire at Will |
| 待ち伏せ位置へ移動 | Move → Ambush | Hold Fire |

---

## 5. 修飾キーとの組み合わせ

| 修飾キー | 効果 | 例 |
|---------|------|-----|
| **Shift** | キュー（ウェイポイント追加） | Shift + Move = 経由地追加 |
| **Ctrl** | 強制（SOP無視） | Ctrl + Move = 接敵しても停止しない |
| **Alt** | 道路優先 | Alt + Move = 道路移動 |

---

## 6. 実装優先度

### Phase 1（必須）

全ユニット共通：
- Move
- Stop
- Attack
- Break Contact

SOP：
- Hold Fire / Return Fire / Fire at Will

戦車追加：
- Reverse

砲兵追加：
- Fire Mission HE
- Fire Mission Smoke

歩兵追加：
- Ambush

### Phase 2（推奨）

- Unload（IFV/APC）
- Recon Move / Observe（偵察）
- Fast Move（歩兵）
- Smoke（発煙弾装備車両）
- Deploy / Cease Fire（砲兵）
- Resupply（LOG_TRUCK）

### Phase 3（将来）

- Fire Position（戦車）
- Dig In（歩兵）
- Hide（偵察）
- 対空関連コマンド
- 支援車両固有コマンド

---

## 7. UI実装メモ

### 7.1 コマンド可用性の判定

```gdscript
func get_available_commands(element: ElementData.ElementInstance) -> Array:
    var archetype := element.element_type.id
    var commands := []

    # 共通コマンド
    commands.append(OrderType.MOVE)
    commands.append(OrderType.STOP)
    commands.append(OrderType.ATTACK)
    commands.append(OrderType.BREAK_CONTACT)

    # アーキタイプ別
    match archetype:
        "TANK_PLT", "LIGHT_TANK":
            commands.append(OrderType.REVERSE)
            if _has_smoke_launcher(element):
                commands.append(OrderType.SMOKE)
        "IFV_PLT", "APC_PLT":
            commands.append(OrderType.UNLOAD)
            commands.append(OrderType.REVERSE)
        # ...

    return commands
```

### 7.2 グレーアウト表示

使用できないコマンドはグレーアウトして表示（位置は固定）。
完全に隠すと筋肉記憶が崩れる。

### 7.3 ツールチップ

ホバー時にコマンド詳細とホットキーを表示。

---

## 8. 変更履歴

- v0.2.4 (2026-02-23): 歩兵コマンド実装（Board/Fast Move/Ambush/Dig In）
- v0.2.3 (2026-02-23): IFVのLoadコマンド削除（歩兵Boardで代替）
- v0.2.2 (2026-02-23): Attack Move廃止、Move+SOPで射撃制御する設計に変更
- v0.2.1 (2026-02-23): DefendをStopに変更、SOPとの役割分離を明確化
- v0.2 (2026-02-23): 初版作成、ユニットタイプ別コマンド設計
