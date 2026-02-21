# データリンク（C4I）仕様 v0.1

---

## 0. 全体方針

**データリンクは「情報共有の範囲」を決定するシステム**

現代戦におけるC4I（Command, Control, Communications, Computers, and Intelligence）システムを簡略化してモデル化。
通信ハブ（指揮ユニット）を中心とした情報共有ネットワークを表現する。

| 項目 | 扱い |
|------|------|
| 目的 | 視覚情報（Contact）の共有範囲を決定 |
| 通信ハブ | 指揮ユニット（CMD_HQ）が担当 |
| 範囲 | ハブの `comm_range` 内のユニットがLINKED |
| 効果 | LINKEDユニット間でContactデータをリアルタイム共有 |

---

## 1. 用語

| 用語 | 意味 |
|------|------|
| **CommState** | 通信状態（LINKED / DEGRADED / ISOLATED） |
| **CommHub** | 通信ハブユニット（`is_comm_hub = true`） |
| **DataLink** | ユニット間の情報共有ネットワーク |
| **Contact** | VisionSystemが管理する敵情報（CONF/SUS/LOST） |

---

## 2. 通信状態（CommState）

### 2.1 状態定義

| 状態 | 値 | 意味 |
|------|-----|------|
| **LINKED** | 0 | 完全接続：リアルタイムで情報共有 |
| **DEGRADED** | 1 | 劣化：更新遅延あり（将来実装） |
| **ISOLATED** | 2 | 孤立：自分の視界のみ、情報共有不可 |

### 2.2 状態の効果

| 状態 | 視界情報 | 射撃可能対象 | 抑圧回復 |
|------|---------|-------------|---------|
| LINKED | 陣営全体のContactを共有 | 陣営内の誰かがCONFしていれば射撃可 | 通常（×1.0） |
| DEGRADED | 遅延あり（将来実装） | （将来実装） | 低下（×0.7） |
| ISOLATED | 自分の視界のみ | 自分がCONFしている敵のみ | 大幅低下（×0.4） |

---

## 3. 通信ハブ（CommHub）

### 3.1 概要

通信ハブは中隊の情報ネットワークの中心となるユニット。
`is_comm_hub = true` のユニットタイプが該当。

### 3.2 ElementTypeフィールド

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `is_comm_hub` | bool | false | 通信ハブかどうか |
| `comm_range` | float | 2000.0 | 通信距離（メートル） |

### 3.3 CMD_HQアーキタイプ

```gdscript
## CMD_HQ: 中隊本部（通信ハブ）
static func create_cmd_hq() -> ElementType:
    var t := ElementType.new()
    t.id = "CMD_HQ"
    t.display_name = "Company HQ"
    t.category = Category.HQ
    t.symbol_type = SymbolType.CMD_HQ
    t.armor_class = 0  # Soft
    t.mobility_class = GameEnums.MobilityType.WHEELED
    t.road_speed = 12.0
    t.cross_speed = 6.0
    t.base_strength = 4   # HQ要員4名
    t.max_strength = 4
    t.spot_range_base = 300.0
    t.spot_range_moving = 200.0
    # 通信ハブ設定
    t.is_comm_hub = true
    t.comm_range = 3000.0  # 3km通信範囲
    return t
```

---

## 4. 通信状態の決定ルール

### 4.1 判定フロー

```
for each element in faction_elements:
    if element.is_comm_hub:
        element.comm_state = LINKED
        element.comm_hub_id = element.id
    else:
        for each hub in faction_hubs:
            if distance(element, hub) <= hub.comm_range:
                element.comm_state = LINKED
                element.comm_hub_id = hub.id
                break
        else:
            element.comm_state = ISOLATED
            element.comm_hub_id = ""
```

### 4.2 判定タイミング

- 毎tick（10Hz）で更新
- ユニットの移動により動的に変化

### 4.3 ハブなしフォールバック

テスト/初期実装のため、陣営内にハブがない場合は全員をLINKEDとして扱う。

```gdscript
func update_comm_states_no_hub_fallback(elements):
    # ハブがいない陣営は全員LINKED（後方互換）
    if not has_hub:
        for element in faction_elements:
            element.comm_state = GameEnums.CommState.LINKED
```

---

## 5. VisionSystemとの連携

### 5.1 情報共有のルール

| シナリオ | 結果 |
|---------|------|
| LINKED同士 | 陣営全体のContactを共有 |
| ISOLATEDユニット | 自分の視界のみでContactを判定 |
| LINKED+ISOLATEDの混在 | ISOLATEDは共有から除外 |

### 5.2 射撃可能判定

```gdscript
## 指定ユニットからターゲットが射撃可能か（視界+DataLink考慮）
func can_engage_target(shooter, target_id) -> bool:
    var contact := get_contact_for_unit(shooter, target_id)
    if not contact:
        return false
    return contact.state == GameEnums.ContactState.CONFIRMED
```

### 5.3 get_contact_for_unit API

```gdscript
## 指定ユニットから見た敵のContact状態を取得（DataLink考慮）
func get_contact_for_unit(viewer, target_id) -> ContactRecord:
    # ISOLATEDの場合は自分の視界のみ
    if viewer.comm_state == GameEnums.CommState.ISOLATED:
        return _get_contact_from_single_observer(viewer, target_id)

    # LINKED（またはDEGRADED）の場合は陣営全体のContactを共有
    return get_contact(viewer.faction, target_id)
```

---

## 6. 抑圧回復への影響

通信状態は士気・抑圧の回復速度に影響する。

### 6.1 回復係数（GameConstants）

| 定数名 | 値 | 説明 |
|--------|-----|------|
| `COMM_RECOVERY_GOOD` | 1.0 | LINKED時の回復倍率 |
| `COMM_RECOVERY_DEGRADED` | 0.7 | DEGRADED時の回復倍率 |
| `COMM_RECOVERY_LOST` | 0.4 | ISOLATED時の回復倍率 |

### 6.2 回復計算式

```gdscript
var comm_mult := 1.0
match comm_state:
    GameEnums.CommState.LINKED:
        comm_mult = COMM_RECOVERY_GOOD      # 1.0
    GameEnums.CommState.DEGRADED:
        comm_mult = COMM_RECOVERY_DEGRADED  # 0.7
    GameEnums.CommState.ISOLATED:
        comm_mult = COMM_RECOVERY_LOST      # 0.4

recovery = base_recovery * comm_mult * posture_mult
```

---

## 7. HUD表示

### 7.1 RightPanel（選択詳細パネル）

選択ユニットの「DATA LINK」セクションに通信状態を表示。

| 状態 | 表示 | 色 |
|------|------|-----|
| LINKED | `LINKED` または `LINKED -> hub_id` | 緑（0.3, 0.9, 0.3） |
| DEGRADED | `DEGRADED` | 黄（0.9, 0.8, 0.2） |
| ISOLATED | `ISOLATED` | 赤（0.9, 0.3, 0.3） |

### 7.2 複数選択時

| 状態 | 表示 |
|------|------|
| 全員LINKED | `ALL LINKED` |
| 全員ISOLATED | `ALL ISOLATED` |
| 混在 | `MIXED (2/4)` （LINKED数/総数） |

---

## 8. ElementInstanceフィールド

### 8.1 通信関連フィールド

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `comm_state` | GameEnums.CommState | LINKED | 現在の通信状態 |
| `comm_hub_id` | String | "" | 接続先ハブID（空＝ハブなし） |

---

## 9. 将来拡張（TODO）

### 9.1 DEGRADED状態の実装

- 情報更新に遅延が発生
- 古いContact情報で射撃する可能性

### 9.2 地形による通信劣化

- 山岳・建物による電波遮蔽
- 距離による信号減衰

### 9.3 電子戦（EW）

- 敵のジャミングによる通信妨害
- ISOLATED状態の強制付与

### 9.4 通信中継

- 中継ユニットによるハブ範囲の拡張
- メッシュネットワーク

---

## 10. 定数一覧

```gdscript
# GameEnums.CommState
enum CommState {
    LINKED = 0,     # 完全接続
    DEGRADED = 1,   # 劣化（将来実装）
    ISOLATED = 2,   # 孤立
}

# ElementType デフォルト値
is_comm_hub = false
comm_range = 2000.0  # m

# CMD_HQ 設定
CMD_HQ.is_comm_hub = true
CMD_HQ.comm_range = 3000.0  # m

# 抑圧回復係数（GameConstants）
COMM_RECOVERY_GOOD = 1.0
COMM_RECOVERY_DEGRADED = 0.7
COMM_RECOVERY_LOST = 0.4
```

---

## 11. 実装ファイル

| ファイル | 役割 |
|---------|------|
| `scripts/core/game_enums.gd` | CommState enum定義 |
| `scripts/data/element_data.gd` | ElementType/ElementInstanceの通信フィールド |
| `scripts/systems/data_link_system.gd` | DataLinkSystemクラス |
| `scripts/systems/vision_system.gd` | VisionSystemとの連携 |
| `scripts/systems/combat_system.gd` | 抑圧回復への適用 |
| `scripts/ui/right_panel.gd` | HUD表示 |
| `tests/test_data_link.gd` | 単体テスト |

---

## 12. 参考：現実のC4Iシステム

### Link 16（NATO標準）

- 戦術データリンク規格
- 戦闘機、艦艇、地上部隊間で情報共有
- 最大256台の端末をサポート

### FBCB2/Blue Force Tracker

- 米軍の位置追跡・情報共有システム
- GPS + 衛星通信
- 味方位置のリアルタイム表示

### 本ゲームでの簡略化

- 単一ハブモデル（階層なし）
- 距離のみで接続判定（地形遮蔽は将来）
- 遅延なしリアルタイム共有（DEGRADEDは将来）
