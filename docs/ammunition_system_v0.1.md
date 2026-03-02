# 残弾・補給システム仕様書 v0.1

## 概要

車両カタログの弾薬定義を活用した残弾管理システム。以下の機能を実装済み：

- 弾種別管理（APFSDS, HEAT-MP等）
- 即発弾/予備弾区分
- 装填時間（自動装填/手動装填）
- 時間回復補給
- 補給ユニットからの直接補給

---

## 1. データモデル

### 1.1 AmmoState (`scripts/data/ammo_state.gd`)

```gdscript
class AmmoSlot:
    var ammo_type_id: String       # 弾種ID (例: "10式APFSDS")
    var count_ready: int = 0       # 即発弾数 (ready rounds)
    var count_stowed: int = 0      # 予備弾数 (stowed rounds)
    var max_ready: int = 0
    var max_stowed: int = 0

class WeaponAmmoState:
    var weapon_id: String
    var ammo_slots: Array[AmmoSlot]
    var current_ammo_index: int = 0
    var is_reloading: bool = false
    var reload_progress_ticks: int = 0
    var reload_duration_ticks: int = 60  # 6秒@10Hz
    var has_autoloader: bool = false

class AmmoState:
    var main_gun: WeaponAmmoState    # 主砲
    var secondary: Array[WeaponAmmoState]  # 副武装
    var atgm: WeaponAmmoState        # ATGM
    var last_combat_tick: int = -1
    var last_move_tick: int = -1
    var supply_cooldown_ticks: int = 0
```

### 1.2 ElementInstanceへの追加

```gdscript
# element_data.gd
var ammo_state: AmmoState = null
var supply_remaining: int = 0      # 補給ユニット用
var supply_config: Dictionary = {} # 補給設定
```

### 1.3 車両カタログ連携

JSON定義から自動初期化：

```json
"main_gun": {
  "weapon_id": "W_JPN_120MM_L44",
  "ammo_capacity_total": 36,
  "ammo_capacity_ready": 14,
  "autoloader": true,
  "ammo_types": ["10式APFSDS", "10式HEAT-MP"]
}
```

ATGMの場合（`count`フィールドまたは`ready_count`/`reserve_count`）：

```json
"atgm": {
  "weapon_id": "W_JPN_ATGM_01LMAT",
  "count": 4
}
// または
"atgm": {
  "weapon_id": "W_CHN_ATGM_HJ8E",
  "ready_count": 2,
  "reserve_count": 4
}
```

---

## 2. 弾薬消費フロー

### 2.1 発射判定 (`CombatSystem`)

```gdscript
func can_fire_with_ammo(shooter, weapon_state) -> Dictionary:
    # 装填中 → { can_fire: false, reason: "RELOADING" }
    # 即発弾0 & 予備弾あり → { can_fire: false, reason: "NEED_RELOAD" }
    # 即発弾0 & 予備弾0 → { can_fire: false, reason: "OUT_OF_AMMO" }
    # 発射可能 → { can_fire: true }
```

### 2.2 弾薬消費

```gdscript
func consume_ammo(weapon_state, slot_index: int = 0, count: int = 1):
    var slot = weapon_state.ammo_slots[slot_index]
    slot.count_ready -= count

    # 即発弾が0になったら自動装填開始
    if slot.count_ready == 0 and slot.count_stowed > 0:
        weapon_state.start_reload()
```

### 2.3 装填処理

| 状態 | 装填時間 | Ticks (@10Hz) |
|------|---------|---------------|
| 自動装填装置あり | 4秒 | 40 |
| 手動装填 | 8秒 | 80 |
| 弾種切替 | 4秒 | 40 |

---

## 3. 補給システム (`ResupplySystem`)

### 3.1 時間回復補給（自動補給）

停止中に徐々に弾薬が回復する。

#### 補給レート

| 武器種 | 1発あたり時間 | Ticks (@10Hz) |
|--------|--------------|---------------|
| 戦車砲 | 30秒 | 300 |
| ATGM | 60秒 | 600 |
| 機関砲 | 0.5秒 | 5 |
| MG | 0.2秒 | 2 |

#### 補給条件・倍率

| 状態 | 倍率 | 説明 |
|------|------|------|
| 停止中 | 100% | 通常補給 |
| 抑圧中 (30%以上) | 50% | 補給速度半減 |
| 戦闘直後 | 25% | 30秒クールダウン |
| 移動中 | 0% | 補給不可 |
| 移動直後 | 0% | 5秒クールダウン |

#### 補給上限

自動補給では**最大容量の80%**まで回復。100%補給には補給ユニットが必要。

### 3.2 補給ユニットからの直接補給

補給トラック等の補給ユニットが近くにいると、100%まで補給可能。

#### 補給ユニット設定

```json
"supply_config": {
  "supply_range_m": 100.0,
  "ammo_resupply_rate": 2.0,
  "capacity": 100
}
```

#### 補給ユニットの動作

- 補給範囲内の味方ユニットを自動補給
- 補給ユニット自身が停止中のみ有効
- 補給対象が移動中は補給不可
- 補給容量（`supply_remaining`）を消費

#### ATGMの特別処理

ATGMは自動補給されず、補給ユニットからの直接補給のみで回復。

---

## 4. ミサイルシステム (`MissileSystem`)

### 4.1 概要

ATGMの飛翔・誘導を管理する独立システム。

### 4.2 誘導方式

| 方式 | 説明 | 射手拘束 | 代表例 |
|------|------|---------|--------|
| SACLOS_WIRE | 有線SACLOS | あり | TOW, HJ-73 |
| SACLOS_LASER_BEAM | レーザービームライディング | あり | Kornet, Bastion |
| IIR_HOMING | 画像式赤外線 | なし | Javelin, 01式LMAT |

### 4.3 攻撃プロファイル

| プロファイル | 説明 | 命中ゾーン |
|-------------|------|-----------|
| DIRECT | 直射 | FRONT/SIDE/REAR |
| TOP_ATTACK | トップアタック | TOP |

### 4.4 ミサイルプロファイル

`data/missiles/missile_profiles.json` で定義：

```json
{
  "id": "M_JPN_01LMAT",
  "display_name": "01 Shiki LMAT",
  "weapon_id": "W_JPN_ATGM_01LMAT",
  "guidance": {
    "type": "IIR_HOMING",
    "lock_mode": "LOBL",
    "lock_time_sec": 2.0
  },
  "flight": {
    "speed_mps": 150.0,
    "max_range_m": 2000.0,
    "min_range_m": 50.0
  },
  "attack_profile": {
    "default": "TOP_ATTACK",
    "selectable": ["DIRECT", "TOP_ATTACK"]
  },
  "warhead": {
    "type": "TANDEM_HEAT",
    "penetration_ce": 200,
    "defeats_era": true
  }
}
```

### 4.5 射手拘束

SACLOS誘導中の射手は以下の制約を受ける：

- 移動不可
- 他の武器使用不可
- 有線切断リスク（被弾/強制移動で誘導喪失）

---

## 5. 輸送システム (`TransportSystem`)

### 5.1 概要

IFV/APCへの歩兵乗車を管理。

### 5.2 主要機能

```gdscript
# 初期乗車（シナリオ開始時）
func embark_initial(transport: ElementInstance, infantry: ElementInstance)

# 乗車コマンド
func embark(transport: ElementInstance, infantry: ElementInstance)

# 下車コマンド
func disembark(transport: ElementInstance)
```

### 5.3 乗車状態

```gdscript
# ElementInstance
var embarked_infantry_id: String = ""  # 乗車中の歩兵ID
var is_embarked: bool = false          # 乗車中フラグ
var transport_vehicle_id: String = ""  # 乗車している車両ID
```

---

## 6. 対象ファイル

### データ定義

| ファイル | 説明 |
|---------|------|
| `scripts/data/ammo_state.gd` | 弾薬状態クラス |
| `data/missiles/missile_profiles.json` | ミサイルプロファイル |
| `data/vehicles/*.json` | 車両カタログ（弾薬定義含む） |
| `data/weapons/*.json` | 武器カタログ |

### システム

| ファイル | 説明 |
|---------|------|
| `scripts/systems/resupply_system.gd` | 補給システム |
| `scripts/systems/missile_system.gd` | ミサイル飛翔・誘導 |
| `scripts/systems/transport_system.gd` | 輸送システム |
| `scripts/systems/combat_system.gd` | 戦闘システム（弾薬消費統合） |

### エンティティ

| ファイル | 説明 |
|---------|------|
| `scripts/data/element_data.gd` | ユニットデータ（ammo_state含む） |
| `scripts/data/element_factory.gd` | ユニット生成（弾薬初期化） |
| `scripts/entities/projectile_manager.gd` | 砲弾・ミサイル表示 |

---

## 7. 国別対応状況

### 実装済み

| 国 | MBT | IFV/APC | 補給トラック |
|----|-----|---------|-------------|
| 日本 (JPN) | 10式, 90式, 74式 | 89FV, 96WPC | 73式 |
| アメリカ (USA) | M1A2 SEPv3 | M2A3, M1126 | M977 |
| ロシア (RUS) | T-90M, T-72B3 | BMP-3, BTR-82A | KAMAZ |
| 中国 (CHN) | 99A式, 15式 | 04A式, 09式 | SX2150, SX2300 |

### ミサイルプロファイル

| 国 | ATGM |
|----|------|
| JPN | 01式LMAT, 87式MAT |
| USA | Javelin, TOW-2B |
| RUS | Kornet, Konkurs, Bastion |
| CHN | HJ-10, HJ-8E, HJ-73, GP105 |

---

## 8. 既知の制限

### v0.1での制限

1. **弾薬庫誘爆**: 未実装（将来追加予定）
2. **弾種切替UI**: 未実装（自動選択のみ）
3. **APS連携**: 基本実装のみ
4. **煙幕妨害**: 未実装

### 将来の拡張

- 弾薬庫誘爆システム
- 弾種手動選択UI
- 補給ポイント（固定拠点）
- 空中投下補給

---

## 9. 関連ドキュメント

- [missile_system_v0.2.md](missile_system_v0.2.md) - ミサイルシステム詳細
- [munition_system_v0.1.md](munition_system_v0.1.md) - 弾薬分類体系
- [combat_v0.1.md](combat_v0.1.md) - 戦闘システム
- [vehicle_catalog_v0.1.md](vehicle_catalog_v0.1.md) - 車両カタログ
