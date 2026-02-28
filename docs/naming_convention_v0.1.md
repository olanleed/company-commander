# 命名規則 v0.1

本ドキュメントでは、ゲーム内で使用するID・変数・関数・クラス等の命名規則を定義する。

---

# Part 1: コード命名規則（GDScript）

## 基本方針

- **GDScriptスタイルガイド準拠**: Godot公式スタイルに従う
- **snake_case**: 変数・関数・シグナル
- **PascalCase**: クラス・列挙型
- **SCREAMING_SNAKE_CASE**: 定数
- **意味のある名前**: 略語は最小限、文脈から意味が分かる名前

---

## 変数命名規則

### ローカル変数: `snake_case`

```gdscript
var current_tick: int = 0
var target_position: Vector2 = Vector2.ZERO
var is_destroyed: bool = false
var flight_time_sec: float = 0.0
```

### メンバ変数（プロパティ）: `snake_case`

```gdscript
var position: Vector2 = Vector2.ZERO
var facing: float = 0.0
var current_strength: int = 100
var suppression: float = 0.0
```

### プライベート変数: `_snake_case`（先頭アンダースコア）

```gdscript
var _projectiles: Array[Projectile] = []
var _next_id: int = 0
var _json_loaded: bool = false
```

### 定数: `SCREAMING_SNAKE_CASE`

```gdscript
const TICKS_PER_SEC: float = 10.0
const SIM_DT: float = 0.1
const MAX_RANGE_M: float = 5000.0
const PENETRATION_SIGMOID_SCALE: float = 8.0
```

### 列挙型値: `SCREAMING_SNAKE_CASE`

```gdscript
enum GuidanceType {
    NONE,
    SACLOS_WIRE,
    SACLOS_LASER_BEAM,
    IIR_HOMING,
    MMW_RADAR,
}

enum AttackProfile {
    DIRECT,
    TOP_ATTACK,
    DIVING,
}
```

---

## 関数命名規則

### 公開関数: `snake_case`（動詞で始める）

```gdscript
func calculate_penetration_probability(pen: int, armor: int) -> float:
func apply_damage(target: ElementInstance, d_supp: float, d_dmg: float) -> void:
func get_armor_at_aspect(target: ElementInstance, aspect: ArmorZone) -> int:
func is_in_range(distance_m: float) -> bool:
func launch_missile(shooter_id: String, target_id: String) -> String:
```

### プライベート関数: `_snake_case`（先頭アンダースコア）

```gdscript
func _update_missile_state(missile: InFlightMissile, tick: int) -> void:
func _calculate_visibility_coefficient(t_los: float) -> float:
func _get_target_class(target: ElementInstance) -> TargetClass:
func _check_aps_intercept(target: ElementInstance, weapon: WeaponType) -> bool:
```

### ゲッター/セッター: `get_`/`set_`プレフィックス

```gdscript
func get_penetration_probability(...) -> float:
func get_cover_coefficient_df(terrain: TerrainType) -> float:
func get_vulnerability_dmg(target: ElementInstance, threat: ThreatClass) -> float:
func set_attack_profile(profile: AttackProfile) -> void:
```

### 判定関数: `is_`/`has_`/`can_`プレフィックス

```gdscript
func is_destroyed() -> bool:
func is_armored_vehicle() -> bool:
func is_saclos() -> bool:
func has_lock() -> bool:
func can_fire() -> bool:
func can_use_profile(profile: AttackProfile) -> bool:
```

### 計算関数: `calculate_`プレフィックス

```gdscript
func calculate_flight_time(distance_m: float) -> float:
func calculate_hit_probability(exposure: float) -> float:
func calculate_aspect_v01r(shooter_pos: Vector2, target_pos: Vector2) -> ArmorZone:
```

### イベントハンドラ: `_on_`プレフィックス

```gdscript
func _on_missile_impact(missile_id: String, target_id: String) -> void:
func _on_tick_advanced(tick: int) -> void:
func _on_element_destroyed(element: ElementInstance) -> void:
```

---

## クラス命名規則

### クラス名: `PascalCase`

```gdscript
class_name MissileData
class_name CombatSystem
class_name ElementInstance
class_name ProjectileManager
```

### 内部クラス: `PascalCase`

```gdscript
class MissileProfile:
    var id: String = ""
    var display_name: String = ""

class InFlightMissile:
    var id: String = ""
    var state: MissileState = MissileState.LAUNCHING

class DirectFireResultV01R:
    var d_supp: float = 0.0
    var p_hit: float = 0.0
```

### 列挙型: `PascalCase`

```gdscript
enum GuidanceType { ... }
enum AttackProfile { ... }
enum MissileState { ... }
enum ArmorZone { ... }
```

---

## シグナル命名規則

### シグナル名: `snake_case`（過去分詞または名詞）

```gdscript
signal missile_launched(missile_id: String, shooter_id: String)
signal missile_impact(missile_id: String, target_id: String)
signal element_destroyed(element: ElementInstance)
signal tick_advanced(tick_index: int)
signal game_ended(winner: Faction, reason: String)
```

---

## 単位サフィックス

物理量を扱う変数には単位サフィックスを付ける。

| サフィックス | 単位 | 例 |
|-------------|------|-----|
| `_m` | メートル | `distance_m`, `range_m`, `altitude_m` |
| `_mm` | ミリメートル | `armor_mm`, `penetration_mm` |
| `_mps` | メートル毎秒 | `speed_mps`, `velocity_mps` |
| `_sec` | 秒 | `flight_time_sec`, `reload_time_sec` |
| `_ms` | ミリ秒 | `delay_ms`, `timeout_ms` |
| `_deg` | 度（角度） | `dive_angle_deg`, `facing_deg` |
| `_rad` | ラジアン | `angle_rad`, `facing_rad` |
| `_rpm` | 発射レート | `rof_rpm` |
| `_pct` | パーセント（0-100） | `probability_pct`, `health_pct` |

### 例

```gdscript
var max_range_m: float = 2500.0
var speed_mps: float = 140.0
var boost_duration_sec: float = 0.5
var dive_angle_deg: float = 45.0
var penetration_mm: int = 160
```

---

## 略語規則

### 許可される略語

| 略語 | 正式名 | 用途 |
|------|--------|------|
| `id` | identifier | 識別子 |
| `pos` | position | 位置 |
| `vel` | velocity | 速度 |
| `dir` | direction | 方向 |
| `dist` | distance | 距離 |
| `prev` | previous | 前回値 |
| `curr` / `current` | current | 現在値 |
| `max` | maximum | 最大値 |
| `min` | minimum | 最小値 |
| `num` | number | 数量 |
| `idx` | index | インデックス |
| `pen` | penetration | 貫通力 |
| `supp` | suppression | 抑圧 |
| `dmg` | damage | ダメージ |
| `src` | source | ソース |
| `dst` | destination | 宛先 |
| `dt` | delta time | 時間差分 |
| `los` | line of sight | 視線 |

### 軍事用語略語

| 略語 | 正式名 | 説明 |
|------|--------|------|
| `ATGM` | Anti-Tank Guided Missile | 対戦車誘導弾 |
| `SACLOS` | Semi-Automatic Command to Line of Sight | 半自動指令照準線一致誘導 |
| `LOBL` | Lock-On Before Launch | 発射前ロックオン |
| `LOAL` | Lock-On After Launch | 発射後ロックオン |
| `CE` | Chemical Energy | 化学エネルギー弾 |
| `KE` | Kinetic Energy | 運動エネルギー弾 |
| `ERA` | Explosive Reactive Armor | 爆発反応装甲 |
| `APS` | Active Protection System | アクティブ防護システム |
| `IFV` | Infantry Fighting Vehicle | 歩兵戦闘車 |
| `APC` | Armored Personnel Carrier | 装甲兵員輸送車 |
| `MBT` | Main Battle Tank | 主力戦車 |
| `ROF` | Rate of Fire | 発射レート |
| `CEP` | Circular Error Probable | 半数必中界 |

---

## バージョンサフィックス

API/仕様バージョンを示す場合:

```gdscript
class DirectFireResultV01R:    # v0.1 Revised
func calculate_aspect_v01r():  # v0.1 Revised
```

| サフィックス | 意味 |
|-------------|------|
| `V01` | バージョン0.1 |
| `V01R` | バージョン0.1 Revised |
| `V02` | バージョン0.2 |

---

## JSONキー命名規則

JSONファイル内のキーは`snake_case`を使用する。

```json
{
    "id": "M_USA_JAVELIN",
    "display_name": "FGM-148 Javelin",
    "guidance_type": "IIR_HOMING",
    "speed_mps": 140.0,
    "max_range_m": 2500.0,
    "top_attack_altitude_m": 80.0,
    "dive_angle_deg": 60.0
}
```

---

# Part 2: エンティティID命名規則

## 基本方針

- **1文字プレフィックス**: 種別を即座に判別可能
- **国籍コード（3文字）**: 検索・フィルタリングが容易
- **アンダースコア区切り**: 可読性を確保
- **大文字スネークケース**: 一貫性を維持

## ID構造

```
{ドメイン}_{国籍}_{カテゴリ}_{名称}
```

| 要素 | 説明 | 例 |
|------|------|-----|
| ドメイン | 1文字のエンティティ種別 | `W`, `M`, `U`, `A` |
| 国籍 | ISO 3166-1 alpha-3ベース | `USA`, `RUS`, `JPN`, `CHN` |
| カテゴリ | エンティティのサブタイプ | `ATGM`, `TANK`, `120` |
| 名称 | 固有名称または識別子 | `JAVELIN`, `M1A2`, `001` |

---

## ドメイン一覧

| プレフィックス | ドメイン | 説明 |
|---------------|----------|------|
| `W` | Weapon | 武器システム |
| `M` | Missile | ミサイルプロファイル |
| `U` | Unit | ユニット（インスタンス） |
| `A` | Ammo | 弾薬・砲弾 |
| `E` | Element | ユニットタイプ（アーキタイプ） |
| `V` | Vehicle | 車両カタログエントリ |

---

## 国籍コード

| コード | 国名 | 備考 |
|--------|------|------|
| `USA` | アメリカ合衆国 | |
| `RUS` | ロシア連邦 | 旧ソ連装備含む |
| `JPN` | 日本 | 陸上自衛隊 |
| `CHN` | 中華人民共和国 | |
| `GER` | ドイツ連邦共和国 | |
| `GBR` | イギリス | |
| `FRA` | フランス | |
| `KOR` | 大韓民国 | |
| `ISR` | イスラエル | |
| `GEN` | Generic | 汎用・架空 |

---

## 武器 (Weapon): `W_`

### 構造
```
W_{国籍}_{カテゴリ}_{名称}
```

### カテゴリ一覧

| カテゴリ | 説明 | 例 |
|----------|------|-----|
| `ATGM` | 対戦車誘導弾 | `W_USA_ATGM_JAVELIN` |
| `TANK` | 戦車砲 | `W_USA_TANK_120MM` |
| `AC` | 機関砲 (Autocannon) | `W_USA_AC_25MM` |
| `MG` | 機関銃 | `W_USA_MG_M240` |
| `HMG` | 重機関銃 | `W_USA_HMG_M2` |
| `GL` | 擲弾発射機 | `W_USA_GL_MK19` |
| `RCL` | 無反動砲 | `W_USA_RCL_CARLGUSTAV` |
| `RPG` | ロケット推進擲弾 | `W_RUS_RPG_7` |
| `LAW` | 軽対戦車火器 | `W_USA_LAW_M72` |
| `ATRL` | 対戦車ロケット | `W_USA_ATRL_AT4` |
| `HOW` | 榴弾砲 | `W_USA_HOW_155MM` |
| `MOR` | 迫撃砲 | `W_USA_MOR_120MM` |
| `SAM` | 地対空ミサイル | `W_USA_SAM_STINGER` |
| `AAG` | 対空機関砲 | `W_RUS_AAG_ZSU23` |

### 例

```
W_USA_ATGM_JAVELIN      # FGM-148 Javelin
W_USA_ATGM_TOW2B        # BGM-71 TOW-2B
W_RUS_ATGM_KORNET       # 9M133 Kornet
W_RUS_ATGM_KONKURS      # 9M113 Konkurs
W_JPN_ATGM_01LMAT       # 01式軽対戦車誘導弾
W_JPN_ATGM_MMPM         # 中距離多目的誘導弾
W_CHN_ATGM_HJ10         # 紅箭-10
W_USA_TANK_120MM        # M256 120mm滑腔砲
W_RUS_TANK_125MM        # 2A46M 125mm滑腔砲
W_JPN_TANK_120MM        # 日本製鋼所 120mm滑腔砲
W_USA_AC_25MM           # M242 Bushmaster
W_USA_MG_M240           # M240 7.62mm機関銃
```

---

## ミサイル (Missile): `M_`

### 構造
```
M_{国籍}_{名称}
```

ミサイルプロファイルは武器から参照され、誘導方式・飛翔特性・攻撃プロファイルを定義する。

### 例

```
M_USA_JAVELIN           # FGM-148 Javelin
M_USA_TOW2B             # BGM-71 TOW-2B
M_RUS_KORNET            # 9M133 Kornet
M_RUS_KONKURS           # 9M113 Konkurs
M_RUS_REFLEKS           # 9M119 Refleks
M_JPN_01LMAT            # 01式軽対戦車誘導弾
M_JPN_79MAT             # 79式対舟艇対戦車誘導弾
M_JPN_MMPM              # 中距離多目的誘導弾
M_CHN_HJ10              # 紅箭-10
M_CHN_HJ9               # 紅箭-9
```

---

## ユニット (Unit): `U_`

### 構造
```
U_{国籍}_{タイプ}_{番号}
```

ゲーム中に生成されるユニットインスタンスのID。

### タイプ一覧

| タイプ | 説明 |
|--------|------|
| `TANK` | 主力戦車 |
| `IFV` | 歩兵戦闘車 |
| `APC` | 装甲兵員輸送車 |
| `RECON` | 偵察車両 |
| `ATGM` | 対戦車ミサイル車両 |
| `INF` | 歩兵分隊 |
| `ENG` | 工兵分隊 |
| `SPG` | 自走砲 |
| `MLRS` | 多連装ロケット |

### 例

```
U_USA_TANK_001          # 米軍戦車1号車
U_USA_TANK_002          # 米軍戦車2号車
U_RUS_IFV_001           # ロシア軍IFV1号車
U_JPN_ATGM_001          # 陸自ATGM車両1号車
```

---

## 弾薬 (Ammo): `A_`

### 構造
```
A_{口径}_{種類}_{バリエーション}
```

### 種類一覧

| 種類 | 説明 |
|------|------|
| `APFSDS` | 装弾筒付翼安定徹甲弾 |
| `HEAT` | 対戦車榴弾 |
| `HESH` | 粘着榴弾 |
| `HE` | 榴弾 |
| `APHE` | 徹甲榴弾 |
| `FRAG` | 破片弾 |
| `SMOKE` | 発煙弾 |
| `ILLUM` | 照明弾 |
| `DPICM` | 二重目的改良型通常弾 |
| `BONUS` | 誘導砲弾 |

### 例

```
A_120_APFSDS_M829A4     # 120mm APFSDS M829A4
A_120_HEAT_M830A1       # 120mm HEAT M830A1
A_125_APFSDS_3BM60      # 125mm APFSDS 3BM60
A_125_HEAT_3BK31        # 125mm HEAT 3BK31
A_155_HE_M795           # 155mm HE M795
A_155_DPICM_M864        # 155mm DPICM M864
```

---

## エレメントタイプ (Element): `E_`

### 構造
```
E_{国籍}_{タイプ}_{名称}
```

ユニットのアーキタイプ（テンプレート）を定義する。

### 例

```
E_USA_TANK_M1A2SEP      # M1A2 SEP
E_USA_IFV_M2A3          # M2A3 Bradley
E_RUS_TANK_T90M         # T-90M
E_RUS_IFV_BMP3          # BMP-3
E_JPN_TANK_TYPE10       # 10式戦車
E_JPN_IFV_TYPE89        # 89式装甲戦闘車
E_CHN_TANK_ZTZ99A       # ZTZ-99A
```

---

## 車両カタログ (Vehicle): `V_`

### 構造
```
V_{国籍}_{名称}
```

車両のマスターデータエントリ。

### 例

```
V_USA_M1A2SEP           # M1A2 SEP Abrams
V_USA_M2A3              # M2A3 Bradley
V_RUS_T90M              # T-90M
V_RUS_BMP3              # BMP-3
V_JPN_TYPE10            # 10式戦車
V_JPN_TYPE89            # 89式装甲戦闘車
```

---

## 移行ガイド

### 旧命名 → 新命名

| 旧 | 新 | 備考 |
|----|-----|------|
| `CW_ATGM_JAVELIN` | `W_USA_ATGM_JAVELIN` | 武器 |
| `MSL_JAVELIN` | `M_USA_JAVELIN` | ミサイル |
| `TANK_PLT_001` | `U_USA_TANK_001` | ユニット |
| `CW_AUTOCANNON_25` | `W_GEN_AC_25MM` | 汎用武器 |

### 移行優先度

1. **ミサイル (`M_`)**: 新規作成のため即時適用
2. **武器 (`W_`)**: 次回リファクタリング時に適用
3. **ユニット (`U_`)**: 次回リファクタリング時に適用
4. **弾薬 (`A_`)**: 新規作成時に適用

---

## 補足ルール

### 数字を含む名称
- 口径は単位付き: `120MM`, `155MM`
- 型番はそのまま: `M1A2`, `T90M`, `TYPE10`
- シリーズ番号はハイフンなし: `TOW2B`, `HJ10`

### 汎用装備
- 国籍特定不能な場合: `GEN`（Generic）
- 例: `W_GEN_MG_762` （汎用7.62mm機関銃）

### バリエーション
- サフィックスで表現: `_V1`, `_V2`, `_LATE`, `_EARLY`
- 例: `A_120_APFSDS_M829A4` vs `A_120_APFSDS_M829A3`

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| v0.1 | 2026-02-28 | 初版作成（エンティティID命名規則） |
| v0.1 | 2026-02-28 | コード命名規則（変数・関数・クラス・シグナル）を追加 |
