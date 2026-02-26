# ミサイルシステム仕様 v0.2

---

## 1. 概要

### 1.1 目的

現行の戦闘システムでは、ATGMは即着弾の直射武器として処理されている。
本仕様では、ミサイル特有の挙動を導入し、よりリアリスティックな対戦車戦闘を実現する。

### 1.2 スコープ

| 対象 | 含む | 含まない（v0.2） |
|------|------|------------------|
| ATGM（対戦車誘導弾） | Javelin, TOW, Kornet等 | - |
| MANPADS（携行SAM） | - | 対空戦闘は将来 |
| 巡航ミサイル | - | マップスケール外 |
| 砲発射ATGM | 9M119 Refleks等 | - |

### 1.3 既存システムとの関係

```
combat_system.gd
    ├── 直射（CONTINUOUS/DISCRETE） ... 既存、変更なし
    ├── 間接射撃 ... 既存、変更なし
    └── ミサイル射撃 ... 新規、missile_system.gdに委譲
            ↓
        missile_system.gd
            ├── 発射処理
            ├── 飛翔管理（in-flight missiles）
            ├── 誘導処理
            └── 着弾処理 → combat_system.gd の効果適用を呼び出し
```

---

## 2. 誘導方式分類

### 2.1 GuidanceType（拡張）

現行の `ammunition_data.gd` を拡張する。

```gdscript
enum GuidanceType {
    NONE,                    # 無誘導（RPG等）

    # 指令誘導（Command Guidance）
    SACLOS_WIRE,             # 有線SACLOS（TOW, Konkurs）
    SACLOS_RADIO,            # 無線SACLOS
    SACLOS_LASER_BEAM,       # レーザービームライディング（Kornet）

    # 自律誘導（Autonomous Homing）
    IR_HOMING,               # 赤外線ホーミング（Javelin）
    IIR_HOMING,              # 画像式赤外線（Javelin CLU）
    MMW_RADAR,               # ミリ波レーダー（Hellfire Longbow）
    SALH,                    # 半自動レーザー誘導（Hellfire, Krasnopol）

    # 航法誘導（砲弾向け）
    GPS_INS,                 # GPS/INS（Excalibur）
    LASER_GUIDED,            # レーザー誘導（Krasnopol）
}
```

### 2.2 ロックオンモード

```gdscript
enum LockMode {
    NONE,                    # 無誘導
    LOBL,                    # Lock-On Before Launch（発射前ロック）
    LOAL_HI,                 # Lock-On After Launch - High（高弾道後ロック）
    LOAL_LO,                 # Lock-On After Launch - Low（低弾道後ロック）
    CONTINUOUS_TRACK,        # 継続追尾（SACLOS）
}
```

### 2.3 攻撃プロファイル

```gdscript
enum AttackProfile {
    DIRECT,                  # 直射（ダイレクトアタック）
    TOP_ATTACK,              # トップアタック（上面攻撃）
    DIVING,                  # ダイビング（急降下）
    OVERFLY_TOP,             # オーバーフライトップアタック（BILL等）
}
```

---

## 3. ミサイルプロファイル

### 3.1 データ構造

`data/missiles/missile_profiles.json` として定義。

```json
{
    "id": "MSL_JAVELIN",
    "display_name": "FGM-148 Javelin",
    "weapon_id": "CW_ATGM_JAVELIN",

    "guidance": {
        "type": "IIR_HOMING",
        "lock_mode": "LOBL",
        "lock_time_sec": 3.0,
        "can_loal": true,
        "loal_acquisition_range_m": 500.0
    },

    "flight": {
        "speed_mps": 140.0,
        "max_speed_mps": 290.0,
        "boost_duration_sec": 0.5,
        "cruise_duration_sec": 14.0,
        "max_range_m": 2500.0,
        "min_range_m": 65.0
    },

    "attack_profile": {
        "default": "TOP_ATTACK",
        "selectable": ["DIRECT", "TOP_ATTACK"],
        "top_attack_altitude_m": 150.0,
        "dive_angle_deg": 45.0
    },

    "warhead": {
        "type": "TANDEM_HEAT",
        "penetration_ce": 160,
        "defeats_era": true,
        "blast_radius_m": 3.0
    },

    "countermeasures": {
        "aps_vulnerability": 0.85,
        "smoke_vulnerability": 0.1,
        "ecm_vulnerability": 0.0
    },

    "constraints": {
        "requires_target_lock": true,
        "shooter_immobile_during_flight": false,
        "wire_max_range_m": 0
    }
}
```

### 3.2 具体的なミサイル例

#### FGM-148 Javelin (USA)

| 項目 | 値 |
|------|-----|
| 誘導方式 | IIR_HOMING |
| ロックモード | LOBL (LOALも可) |
| 攻撃プロファイル | TOP_ATTACK / DIRECT 選択可 |
| 射程 | 65m - 2,500m |
| 飛翔速度 | 140 m/s (巡航) |
| 弾頭 | タンデムHEAT |
| 貫通力 | 750mm RHA (CE) |
| Fire-and-Forget | Yes |
| 射手拘束 | なし |

#### BGM-71 TOW-2B (USA)

| 項目 | 値 |
|------|-----|
| 誘導方式 | SACLOS_WIRE |
| ロックモード | CONTINUOUS_TRACK |
| 攻撃プロファイル | DIRECT / OVERFLY_TOP (TOW-2B) |
| 射程 | 65m - 3,750m |
| 飛翔速度 | 278 m/s |
| 弾頭 | タンデムHEAT / EFP (2B) |
| 貫通力 | 900mm RHA |
| Fire-and-Forget | No |
| 射手拘束 | あり（飛翔中は移動・射撃不可）|

#### 9M133 Kornet (RUS)

| 項目 | 値 |
|------|-----|
| 誘導方式 | SACLOS_LASER_BEAM |
| ロックモード | CONTINUOUS_TRACK |
| 攻撃プロファイル | DIRECT |
| 射程 | 100m - 5,500m |
| 飛翔速度 | 250 m/s |
| 弾頭 | タンデムHEAT |
| 貫通力 | 1,200mm RHA |
| Fire-and-Forget | No |
| 射手拘束 | あり |

#### 01式軽対戦車誘導弾 (JPN)

| 項目 | 値 |
|------|-----|
| 誘導方式 | IIR_HOMING |
| ロックモード | LOBL |
| 攻撃プロファイル | TOP_ATTACK / DIRECT |
| 射程 | - 2,000m |
| 飛翔速度 | 〜150 m/s |
| 弾頭 | タンデムHEAT |
| Fire-and-Forget | Yes |
| 射手拘束 | なし |

---

## 4. 飛翔モデル

### 4.1 ミサイル状態

```gdscript
enum MissileState {
    LAUNCHING,          # 発射中（ブースト段階）
    IN_FLIGHT,          # 飛翔中
    TERMINAL,           # 終末段階（ロックオン/ダイブ中）
    IMPACT,             # 着弾
    LOST,               # 誘導喪失（煙幕、妨害等）
    INTERCEPTED,        # APS迎撃
}
```

### 4.2 飛翔フェーズ

```
[発射] → [ブースト] → [巡航/上昇] → [終末] → [着弾]
   |         |              |           |
   0s      0.5s          〜10s       〜15s
```

#### 4.2.1 ブースト段階

- 発射直後の加速フェーズ
- 最小射程距離の根拠（Javelinの65m等）

#### 4.2.2 巡航段階

- SACLOS: 射手が継続追尾
- Fire-and-Forget: 自律飛翔

#### 4.2.3 終末段階

- TOP_ATTACK: 目標上空で急降下
- DIRECT: 直線的に接近

### 4.3 飛翔時間計算

```gdscript
func calculate_flight_time(distance_m: float, profile: MissileProfile) -> float:
    var boost_dist := profile.speed_mps * profile.boost_duration_sec * 0.5
    var remaining_dist := distance_m - boost_dist

    if profile.attack_profile == AttackProfile.TOP_ATTACK:
        # 上昇 + 水平 + 降下 の概算
        var climb_dist := profile.top_attack_altitude_m / sin(deg_to_rad(30))
        var dive_dist := profile.top_attack_altitude_m / sin(deg_to_rad(profile.dive_angle_deg))
        var horizontal_dist := remaining_dist - climb_dist - dive_dist
        return profile.boost_duration_sec + (climb_dist + horizontal_dist + dive_dist) / profile.speed_mps
    else:
        return profile.boost_duration_sec + remaining_dist / profile.speed_mps
```

---

## 5. 射手拘束システム

### 5.1 SACLOS射手拘束

SACLOS誘導中、射手は以下の制約を受ける：

| 制約 | 効果 |
|------|------|
| 移動不可 | 飛翔中は移動コマンド無効 |
| 射撃不可 | 他の武器も使用不可 |
| 目標変更不可 | 誘導中のミサイルは再ロック不可 |
| 有線切断リスク | 射手が被弾/強制移動で誘導喪失 |

```gdscript
class ShooterConstraint:
    var shooter_id: String
    var missile_id: String
    var start_tick: int
    var guidance_type: GuidanceType

    func is_constrained() -> bool:
        return guidance_type in [
            GuidanceType.SACLOS_WIRE,
            GuidanceType.SACLOS_RADIO,
            GuidanceType.SACLOS_LASER_BEAM,
            GuidanceType.SALH,
        ]
```

### 5.2 有線切断条件

```gdscript
func check_wire_integrity(shooter: ElementInstance, missile: InFlightMissile) -> bool:
    # 射手が移動した
    if shooter.is_moving:
        return false

    # 射手が抑圧状態でPinned以上
    if shooter.suppression >= GameConstants.SUPPRESSION_PINNED:
        return false

    # 射手が被弾した
    if shooter.last_hit_tick > missile.launch_tick:
        return false

    # 射手-ミサイル間にHardBlock
    # (簡略化: 省略可)

    return true
```

---

## 6. 対抗手段との連携

### 6.1 APS（Active Protection System）

既存の `protection_data.gd` のAPS定義と連携。

```gdscript
func attempt_aps_intercept(target: ElementInstance, missile: InFlightMissile) -> bool:
    var protection := target.get_protection_profile()
    if not protection.has_aps():
        return false

    # 誘導方式による迎撃確率修正
    var base_prob := protection.get_aps_intercept_probability("atgm")
    var guidance_mult := get_guidance_aps_modifier(missile.guidance_type)
    var final_prob := base_prob * guidance_mult * missile.aps_vulnerability

    return randf() < final_prob

func get_guidance_aps_modifier(guidance: GuidanceType) -> float:
    match guidance:
        GuidanceType.SACLOS_WIRE:
            return 1.0      # 低速、予測しやすい
        GuidanceType.IIR_HOMING:
            return 0.9      # 高速終末機動
        GuidanceType.MMW_RADAR:
            return 0.85     # 高速、低RCS
        _:
            return 1.0
```

### 6.2 煙幕妨害

```gdscript
func check_smoke_disruption(missile: InFlightMissile, smoke_zones: Array) -> bool:
    match missile.guidance_type:
        GuidanceType.IIR_HOMING, GuidanceType.IR_HOMING:
            # IR誘導は煙幕で大幅に妨害される
            for zone in smoke_zones:
                if is_los_through_smoke(missile.position, missile.target_position, zone):
                    return randf() < 0.7  # 70%で誘導喪失

        GuidanceType.SACLOS_LASER_BEAM, GuidanceType.SALH:
            # レーザー誘導も煙幕で妨害
            for zone in smoke_zones:
                if is_los_through_smoke(missile.position, missile.target_position, zone):
                    return randf() < 0.5  # 50%で誘導喪失

        GuidanceType.SACLOS_WIRE:
            # 有線SACLOSは煙幕の影響を受けにくい（射手の照準が問題）
            return false

        GuidanceType.MMW_RADAR:
            # ミリ波レーダーは煙幕貫通
            return false

    return false
```

### 6.3 ECM/ECCM（将来拡張）

レーダー誘導に対するECMは将来実装。

---

## 7. ゲームプレイへの影響

### 7.1 戦術的意味

| ミサイルタイプ | 戦術的特徴 |
|----------------|-----------|
| Fire-and-Forget (Javelin) | 射撃後即移動可、複数目標対応、高価 |
| SACLOS (TOW/Kornet) | 射手露出、長射程、安価、大量配備可能 |
| トップアタック | MBT正面でも有効、APS回避しやすい |
| ダイレクト | 低空障害物に強い、ERA効果受けやすい |

### 7.2 プレイヤーの意思決定

- **攻撃プロファイル選択**: 地形、目標装甲、APS有無を考慮
- **SACLOS運用**: 射点選定、援護射撃の必要性
- **煙幕使用**: IR誘導への対抗、撤退支援
- **目標優先度**: ATGM射手の早期排除

---

## 8. システム設計

### 8.1 新規ファイル

```
scripts/
├── data/
│   └── missile_data.gd          # ミサイルデータモデル
└── systems/
    └── missile_system.gd        # ミサイル飛翔・誘導処理

data/
└── missiles/
    ├── missile_profiles.json    # ミサイルプロファイル（SSoT）
    └── README.md                # データ形式説明
```

### 8.2 missile_data.gd

```gdscript
class_name MissileData
extends RefCounted

# Enums
enum GuidanceType { ... }
enum LockMode { ... }
enum AttackProfile { ... }
enum MissileState { ... }

# MissileProfile class
class MissileProfile:
    var id: String
    var weapon_id: String  # WeaponData.WeaponType への参照
    var guidance_type: GuidanceType
    var lock_mode: LockMode
    var attack_profiles: Array[AttackProfile]
    var default_attack_profile: AttackProfile
    # ... flight params, warhead, countermeasures

# InFlightMissile class (飛翔中ミサイルインスタンス)
class InFlightMissile:
    var id: String
    var profile: MissileProfile
    var shooter_id: String
    var target_id: String
    var state: MissileState
    var position: Vector2
    var velocity: Vector2
    var launch_tick: int
    var attack_profile: AttackProfile
    # ...
```

### 8.3 missile_system.gd

```gdscript
class_name MissileSystem
extends RefCounted

var in_flight_missiles: Dictionary = {}  # id -> InFlightMissile
var shooter_constraints: Dictionary = {}  # shooter_id -> ShooterConstraint

func launch_missile(shooter: ElementInstance, target: ElementInstance,
                    profile: MissileProfile, attack_profile: AttackProfile) -> void:
    # 1. ロックオン判定（LOBLの場合）
    # 2. ミサイル生成
    # 3. 射手拘束設定（SACLOSの場合）
    # 4. 飛翔開始
    pass

func update(delta: float, current_tick: int) -> void:
    # 全飛翔中ミサイルを更新
    for missile in in_flight_missiles.values():
        _update_missile(missile, delta, current_tick)

func _update_missile(missile: InFlightMissile, delta: float, tick: int) -> void:
    # 1. 有線/誘導チェック（SACLOSの場合）
    # 2. 位置更新
    # 3. 煙幕妨害チェック
    # 4. 終末段階判定
    # 5. APS迎撃判定
    # 6. 着弾判定
    pass
```

### 8.4 combat_system.gd との連携

```gdscript
# combat_system.gd に追加
var missile_system: MissileSystem

func process_atgm_fire(shooter: ElementInstance, target: ElementInstance,
                       weapon: WeaponData.WeaponType) -> void:
    var missile_profile := MissileData.get_profile_for_weapon(weapon.id)
    if missile_profile:
        # ミサイルシステムに委譲
        var attack_profile := _select_attack_profile(shooter, target, missile_profile)
        missile_system.launch_missile(shooter, target, missile_profile, attack_profile)
    else:
        # フォールバック: 既存の即着弾処理
        _process_discrete_fire(shooter, target, weapon)
```

---

## 9. 実装フェーズ

### Phase 1: 基盤実装（優先）

- [ ] `missile_data.gd` - データモデル・enum定義
- [ ] `data/missiles/missile_profiles.json` - 主要ATGMのプロファイル
- [ ] `missile_system.gd` - 基本的な飛翔・着弾処理
- [ ] 飛翔時間の導入（即着弾→遅延着弾）

### Phase 2: 誘導システム

- [ ] SACLOS射手拘束
- [ ] 有線切断判定
- [ ] Fire-and-Forget自律追尾

### Phase 3: 攻撃プロファイル

- [ ] TOP_ATTACK軌道計算
- [ ] DIRECT/TOP_ATTACK選択UI
- [ ] 命中部位（ゾーン）への影響

### Phase 4: 対抗手段

- [ ] APS迎撃との連携強化
- [ ] 煙幕によるIR誘導妨害
- [ ] 射手被弾による誘導喪失

### Phase 5: 可視化

- [ ] ミサイル飛翔のビジュアル表示
- [ ] 軌跡表示（煙、炎）
- [ ] 着弾エフェクト

---

## 10. パラメータ早見表

### 10.1 誘導方式別特性

| 誘導方式 | 射手拘束 | 煙幕耐性 | APS迎撃係数 | 代表例 |
|----------|---------|---------|------------|--------|
| SACLOS_WIRE | あり | 高 | 1.0 | TOW, Konkurs |
| SACLOS_LASER_BEAM | あり | 低 | 1.0 | Kornet |
| IIR_HOMING | なし | 低 | 0.9 | Javelin |
| MMW_RADAR | なし | 高 | 0.85 | Hellfire Longbow |
| SALH | あり* | 低 | 0.95 | Hellfire, Krasnopol |

*SALH: 照射側が拘束される

### 10.2 攻撃プロファイル別効果

| プロファイル | 命中ゾーン | APS回避 | 最小射程影響 |
|-------------|-----------|---------|-------------|
| DIRECT | FRONT/SIDE/REAR | なし | なし |
| TOP_ATTACK | TOP | +20% | +50m |
| DIVING | TOP/REAR | +10% | なし |
| OVERFLY_TOP | TOP | +30% | +100m |

### 10.3 飛翔パラメータ（参考値）

| ミサイル | 速度(m/s) | 射程(m) | 飛翔時間(2km) |
|----------|----------|---------|--------------|
| Javelin | 140 | 2,500 | 〜14秒 |
| TOW-2B | 278 | 3,750 | 〜7秒 |
| Kornet | 250 | 5,500 | 〜8秒 |
| 01式LMAT | 150 | 2,000 | 〜13秒 |

---

## 11. 関連ドキュメント

- [missiles_guidance_tree.md](weapons_tree/missiles_guidance_tree.md) - 誘導方式分類
- [man_portable_anti_tank_weapons_2026_mainstream.md](weapons_tree/man_portable_anti_tank_weapons_2026_mainstream.md) - 携行AT火器
- [combat_v0.1.md](combat_v0.1.md) - 戦闘システム基盤
- [damage_model_v0.1.md](damage_model_v0.1.md) - ダメージモデル
- [protection_data.gd](../scripts/data/protection_data.gd) - APS定義
