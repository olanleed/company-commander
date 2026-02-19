# ユニット仕様 v0.1

---

## 1. 用語と階層

| 用語 | 意味 |
|------|------|
| **Company**（中隊） | プレイヤーがRPで召喚する最小単位。通常は1アイコンで表示。 |
| **Element**（要素） | 中隊の内部構成要素。必要な時だけ画面に分離表示される。 |
| **UnitType**（固定仕様） | 中隊/要素の"カタログ"。戦闘中は変化しない。 |
| **UnitInstance**（可変状態） | 戦闘中に変化する状態（抑圧・損耗・補給・通信など）。 |
| **ElementCategory** | 要素の役割クラス：`INF / VEH / REC / WEAP / ENG / LOG / HQ` |

---

## 2. 設計原則（ブレ止め）

- 制圧の主役は歩兵系（INF/REC/ENG）
- 車両（VEH）は制圧を進めない（妨害はできる）
- 情報は確定ではなく、観測→報告→共有→陳腐化する
- 命令は摩擦（遅延/途絶）を伴う
- 現代戦のリアリティは"摩擦（抑圧・統制・持続）"で出す
- 中隊は原則1アイコン、必要時のみ分割（**2要素モデルを基本**）

---

## 3. 国差し替えに強いデータ構造

「国ごとに違う」のは主に次の3層なので、分離する。

| 層 | 役割 |
|----|------|
| **ElementArchetype（要素）** | Strength / 速度 / センサー / 通信 / 防護 / ロードアウト |
| **UnitCard（購入単位）** | "何要素で構成されるか"＋RPコスト＋スポーン挙動 |
| **CountryOverride（国別差分）** | 上の2層を部分的に上書き |

### 3.1 差分適用のルール（Deep Merge）

1. `base_units.json` を読み込み
2. `countries/USA.json` など国別パッチを上からディープマージ
3. 値がある項目は上書き、オブジェクトは再帰的にマージ
4. `null` を指定したキーは削除（置換でなく削除を表現）

### 3.2 「標準」と「国」の二段構え

| 階層 | 説明 | 例 |
|------|------|-----|
| `standard_group` | 弾薬互換の大枠 | NATO / RU / CN |
| `country_id` | 国別の微差と差し替え | USA / RUS / CHN / JPN / GBR … |

#### MunitionVariant 解決順

1. `(munition_class, country_id)` があればそれを使う
2. 無ければ `(munition_class, standard_group)` を使う
3. それも無ければ `generic` を使う

---

## 4. データモデル

### 4.1 CompanyType（中隊：固定）

召喚・経済・編制・分割可能性を定義する。

```
id
display_name
role               : Inf / MechInf / Armor / Recon / Engineer / Mortar / Log / HQ など
elements[]         : 内包する ElementType 参照

economy
  rp_cost
  slot_weight      : 輸送枠（1 or 2）
  cooldown_sec
  availability_cap

arrival_profile
  arrival_delay_class : Light / Medium / Heavy（20/35/50秒）

c2_profile
  order_delay_base_sec
  cohesion_rating
  autonomy
  max_detachments
  split_penalty_multiplier

frontage_profile
  preferred_frontage
  dispersion_modes : Column/Deployed/Dispersed の基本係数
```

### 4.2 CompanyInstance（中隊：可変）

統合表示（1アイコン）時にプレイヤーが見る"総合状態"。

```
company_strength     : 要素の加重合算
company_suppression  : 最大値または加重
company_cohesion
company_fatigue
company_sustain      : Ammo/Fuel を統合した表示用%
comm_state           : Good / Degraded / Lost
current_order        : 中隊命令
elements_state[]     : 内部の ElementInstance 群
```

**合算ルール：**

| フィールド | 合算方法 |
|-----------|---------|
| Strength | INF/VEH など"戦闘寄与"で加重平均 |
| Suppression | **最大値寄り**（どこかがPinnedなら中隊全体の行動も鈍る） |
| Sustain | **最も低い要素**に引っ張られる |

### 4.3 ElementType（要素：固定）

移動・戦闘・観測・制圧・持続の"共通フォーマット"。

#### A) Mobility

```
mobility_class     : Foot / Wheeled / Tracked
road_speed
cross_speed
terrain_mods       : 市街/森林/泥濘/傾斜など係数
deploy_time_sec    : Column→Deployed の移行コスト
```

#### B) Fire

```
lethality[range_band][target_class]
suppression_power[range_band]

range_band  : Near / Mid / Far
target_class: Soft / Light / Heavy / Fortified
```

#### C) Protection

```
vulnerability_vs   : SmallArms / Autocannon / HEFrag / AT（係数）
cover_effectiveness: 遮蔽でどれだけ被害/抑圧が軽減されるか
entrench_cap       : 陣地化の最大効果
```

#### D) Sensors

```
detect_range_table : 目標種別×移動/停止×昼夜
classify_time_sec  : 同定にかかる時間
track_persistence_sec : 見失い耐性
```

#### E) Signature

```
signature_visual / thermal / acoustic / EM  （0–100）
move_multiplier
fire_multiplier
```

#### F) Terrain Control（制圧関連）

```
capture_power  : 制圧を進める力
contest_power  : 拠点を膠着させる/妨害する力
```

#### G) Sustain

```
ammo_endurance_min  : 標準交戦強度で何分
fuel_endurance_min
resupply_rate       : 補給での回復速度
```

### 4.4 ElementInstance（要素：可変）

```
strength          (0–100)
suppression       (0–100)
cohesion          (0–100)
fatigue           (0–100)
ammo_pct          (0–100)
fuel_pct          (0–100)
comm_state        : Good / Degraded / Lost
posture           : Move / Attack / Defend / Recon / Resupply / Dig-in / Work
dispersion_mode   : Column / Deployed / Dispersed
entrench_progress (0–100)
current_order
last_report_time  : 情報陳腐化と AAR に使用
```

---

## 5. カテゴリ規約

カテゴリは「値の傾向」ではなく、**破ってはいけないルール**を持つ。

### 5.1 カテゴリ別：制圧の強制ルール

| Category | capture_power | contest_power | 備考 |
|---------|-------------|-------------|------|
| INF | **> 0（高）** | 中〜高 | 制圧の主役 |
| REC | **> 0（低〜中）** | 低 | 情報の主役 |
| ENG | **> 0（中）** | 中 | 作業しながら関与 |
| VEH | **0 固定** | 高 | 取れないが妨害は強い |
| WEAP | 0（推奨） | 低 | 支援火器 |
| LOG | **0 固定** | 低 | 補給 |
| HQ | **0 固定** | 低 | 指揮 |

### 5.2 INF（降車歩兵）

**追加フィールド：**
```
dig_rate
urban_bonus
portable_AT_rating  （任意）
```

**規約：**
- 遮蔽の恩恵が大きい（`cover_effectiveness` 高）
- signature は低め（止まれば特に見つかりにくい）
- AT/HE には弱い（回避と分散が生存手段）

### 5.3 VEH（戦闘車両：IFV/APC/戦車）

**追加フィールド：**
```
armor_class         : Light / Medium / Heavy
stabilized_fire     : 移動射撃の得意不得意
transport_capacity  : 機械化の核
```

**規約：**
- `capture_power = 0`
- thermal/acoustic signature が高い
- AT の脅威を無視できない

### 5.4 REC（偵察）

**追加フィールド：**
```
report_rate       : 報告更新頻度
classify_bonus
mark_target       : 観測リンク強化
```

**規約：**
- fire は自衛レベルに抑える
- sensors（detect/classify/track）は最上位
- 止まっていると見つかりにくい設計

### 5.5 WEAP（支援火器：迫撃砲/重火器/ATGM等）

**追加フィールド：**
```
setup_time_sec
displace_time_sec
min_range / max_range  （必要なら）
requires_observer      : 基本 ON 推奨
smoke_mission          : 煙幕可否
```

**規約：**
- capture は基本 0
- 設置/撤収の摩擦が必須
- 観測リンクがないと性能が落ちる

### 5.6 ENG（工兵）

**追加フィールド：**
```
work_rate
task_set     : dig / obstacle_create / breach / repair
work_risk    : 作業中被害係数
```

### 5.7 LOG（補給/回収）

**追加フィールド：**
```
supply_output_per_min
supply_radius
recovery_capability  : 回収/修理
supply_stock         （任意）
```

**規約：**
- `capture = 0`
- 戦闘力が低い（護衛が必要）
- sustain 回復が主目的

### 5.8 HQ（指揮通信）

**追加フィールド：**
```
command_radius
order_delay_reduction
share_latency_reduction
relay_capability
```

**規約：**
- `capture = 0`
- 前線で殴る存在にしない

---

## 6. ElementArchetype 一覧（ベース値）

### 6.1 INF_LINE（歩兵分隊群要素：一般）

```json
{
  "id": "INF_LINE",
  "role": "INF",
  "mobility": "FOOT",
  "state_init": { "strength": 100, "cohesion": 80, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 2.0, "speed_route_mps": 2.7, "turn_rate_deg_s": 180 },
  "sensors": { "visual_range_m": 900, "sensor_quality": 60, "id_speed": 55 },
  "comms": { "comm_quality": 60 },
  "protection": { "model": "SOFT" },
  "loadout_refs": ["CW_RIFLE_STD"]
}
```

### 6.2 INF_AT（歩兵AT要素：RPG/AT枠）

```json
{
  "id": "INF_AT",
  "inherits": "INF_LINE",
  "sensors": { "visual_range_m": 900, "sensor_quality": 60, "id_speed": 55 },
  "loadout_refs": ["CW_RIFLE_STD", "CW_RPG_HEAT"],
  "note": "AT弾はAmmoMix/Ammo容量で抑制"
}
```

### 6.3 INF_MG（歩兵火力要素：MG/HMG枠）

```json
{
  "id": "INF_MG",
  "inherits": "INF_LINE",
  "loadout_refs": ["CW_RIFLE_STD", "CW_MG_STD"],
  "sensors": { "visual_range_m": 900, "sensor_quality": 60, "id_speed": 55 }
}
```

### 6.4 TANK_PLT（戦車小隊要素）

```json
{
  "id": "TANK_PLT",
  "role": "TANK",
  "mobility": "TRACKED",
  "state_init": { "strength": 100, "cohesion": 85, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 8.0, "speed_route_mps": 14.0, "turn_rate_deg_s": 90 },
  "sensors": { "visual_range_m": 1800, "sensor_quality": 75, "id_speed": 75 },
  "comms": { "comm_quality": 70 },
  "protection": { "model": "ARMORED", "armor_preset": "Heavy" },
  "vehicle_subsystems_init": { "mobility_hp": 100, "firepower_hp": 100, "sensors_hp": 100 },
  "loadout_refs": ["CW_TANK_KE", "CW_TANK_HEATMP", "CW_MG_STD"]
}
```

### 6.5 RECON_VEH（偵察車両要素：wheeled）

```json
{
  "id": "RECON_VEH",
  "role": "REC",
  "mobility": "WHEELED",
  "state_init": { "strength": 90, "cohesion": 85, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 9.0, "speed_route_mps": 16.0, "turn_rate_deg_s": 120 },
  "sensors": { "visual_range_m": 1400, "sensor_quality": 80, "id_speed": 85 },
  "comms": { "comm_quality": 75 },
  "protection": { "model": "ARMORED", "armor_preset": "Light" },
  "vehicle_subsystems_init": { "mobility_hp": 100, "firepower_hp": 70, "sensors_hp": 100 },
  "loadout_refs": ["CW_RIFLE_STD"]
}
```

### 6.6 RECON_TEAM（徒歩偵察要素）

```json
{
  "id": "RECON_TEAM",
  "role": "REC",
  "mobility": "FOOT",
  "state_init": { "strength": 70, "cohesion": 85, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 2.2, "speed_route_mps": 2.9, "turn_rate_deg_s": 200 },
  "sensors": { "visual_range_m": 1100, "sensor_quality": 85, "id_speed": 90 },
  "comms": { "comm_quality": 70 },
  "protection": { "model": "SOFT" },
  "loadout_refs": ["CW_RIFLE_STD"]
}
```

### 6.7 MORTAR_SEC（迫撃要素）

```json
{
  "id": "MORTAR_SEC",
  "role": "WEAP",
  "mobility": "FOOT",
  "state_init": { "strength": 80, "cohesion": 75, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 1.6, "speed_route_mps": 2.3, "turn_rate_deg_s": 160 },
  "sensors": { "visual_range_m": 700, "sensor_quality": 55, "id_speed": 50 },
  "comms": { "comm_quality": 65 },
  "protection": { "model": "SOFT" },
  "loadout_refs": ["CW_MORTAR_HE", "CW_MORTAR_SMOKE"]
}
```

### 6.8 LOG_TRUCK（補給要素）

```json
{
  "id": "LOG_TRUCK",
  "role": "LOG",
  "mobility": "WHEELED",
  "state_init": { "strength": 60, "cohesion": 70, "fatigue": 0, "suppression": 0, "ammo_pct": 100 },
  "movement": { "speed_all_mps": 8.0, "speed_route_mps": 16.0, "turn_rate_deg_s": 120 },
  "sensors": { "visual_range_m": 600, "sensor_quality": 45, "id_speed": 40 },
  "comms": { "comm_quality": 60 },
  "protection": { "model": "ARMORED", "armor_preset": "Light" },
  "vehicle_subsystems_init": { "mobility_hp": 100, "firepower_hp": 0, "sensors_hp": 70 },
  "loadout_refs": []
}
```

---

## 7. UnitCard（中隊カード）v0.1

MVPは5枚。

### 7.1 INF_COY（歩兵中隊）

構成：INF_LINE ×1、INF_MG ×1、INF_AT ×1（計3要素）

```json
{
  "id": "INF_COY",
  "category": "MANEUVER",
  "rp_cost": 55,
  "spawn_group": ["INF_LINE", "INF_MG", "INF_AT"],
  "default_roE": "ROE_ReturnFire",
  "autonomy_level": "A1"
}
```

### 7.2 TANK_COY（戦車中隊）

構成：TANK_PLT ×2（計2要素）

```json
{
  "id": "TANK_COY",
  "category": "ARMOR",
  "rp_cost": 95,
  "spawn_group": ["TANK_PLT", "TANK_PLT"],
  "default_roE": "ROE_ReturnFire",
  "autonomy_level": "A1"
}
```

### 7.3 RECON_PLT（偵察小隊）

構成：RECON_VEH ×1、RECON_TEAM ×1（計2要素）

```json
{
  "id": "RECON_PLT",
  "category": "RECON",
  "rp_cost": 35,
  "spawn_group": ["RECON_VEH", "RECON_TEAM"],
  "default_roE": "ROE_HoldFire",
  "autonomy_level": "A2"
}
```

### 7.4 MORTAR_PLT（迫撃小隊）

構成：MORTAR_SEC ×1（計1要素）

```json
{
  "id": "MORTAR_PLT",
  "category": "FIRE_SUPPORT",
  "rp_cost": 45,
  "spawn_group": ["MORTAR_SEC"],
  "default_roE": "ROE_HoldFire",
  "autonomy_level": "A1"
}
```

### 7.5 LOG_PLT（補給小隊：任意）

構成：LOG_TRUCK ×1（計1要素）

```json
{
  "id": "LOG_PLT",
  "category": "SUPPORT",
  "rp_cost": 30,
  "spawn_group": ["LOG_TRUCK"],
  "default_roE": "ROE_HoldFire",
  "autonomy_level": "A1"
}
```

---

## 8. 分割（Detach）と機械化（Mounted/Dismounted）仕様

### 8.1 分割の基本

中隊は通常「統合表示（1アイコン）」。

`max_detachments = 1` の場合、同時に独立表示できる要素は最大2つ（INF + VEH 等）。

### 8.2 機械化：降車/再乗車（DISMOUNT / REMOUNT）

**DISMOUNT**（統合中隊 → INF要素とVEH要素を分離表示）
- 実行条件例：`suppression < 70`、一定速度以下など
- 実行後：cohesion 低下（混乱）、VEH は初期SOP で Overwatch へ

**REMOUNT**（INFがVEHに再合流）
- 条件：距離・suppression・敵接触など
- 時間がかかる（撤退時に"間に合うか"が発生）

### 8.3 Tether（リンク）ルール

INF と VEH（または分割した要素）はリンク線で結ばれる。

`tether_range` を超えるとペナルティ：
- 命令遅延増加
- 情報共有遅延
- REMOUNT/合流が不可または困難

---

## 9. 戦闘と状態（共通ルール）

### 9.1 抑圧（Suppression）

| 閾値 | 状態 | 効果 |
|------|------|------|
| 40 | **Suppressed** | 移動/命中/制圧が低下 |
| 70 | **Pinned** | 移動ほぼ不可、制圧ほぼ停止 |
| 90 | **Broken** | 後退SOP、戦闘効率極小 |

抑圧回復は「非被弾」「通信良好」「HQ近傍」等で加速。

### 9.2 分散モード（Column / Deployed / Dispersed）

全カテゴリ共通。モードは以下に影響：

| 影響項目 |
|---------|
| signature（被発見） |
| HEへの脆弱性（榴弾片被害） |
| 火力集中効率 |
| cohesion（統制） |
| 速度 |

---

## 10. 国別差し替え設計

### 10.1 国別ファイルの最小構成

| フィールド | 説明 |
|-----------|------|
| `country_id` | USA / RUS / CHN / JPN / GBR … |
| `standard_group` | NATO / RU / CN |
| `unit_cost_multiplier` | コスト係数（任意） |
| `element_overrides` | 要素の部分上書き |
| `unitcard_overrides` | カードの部分上書き |
| `munition_variant_overrides` | 弾薬Variant差 |

### 10.2 例：USA（NATO系、センサー強め）

```json
{
  "country_id": "USA",
  "standard_group": "NATO",
  "unit_cost_multiplier": 1.00,
  "element_overrides": {
    "RECON_VEH": { "sensors": { "sensor_quality": 85 } },
    "TANK_PLT":  { "sensors": { "sensor_quality": 78 } }
  },
  "unitcard_overrides": {
    "TANK_COY": { "rp_cost": 98 }
  }
}
```

### 10.3 例：RUS（RU系、編成差し替え）

```json
{
  "country_id": "RUS",
  "standard_group": "RU",
  "unit_cost_multiplier": 1.00,
  "unitcard_overrides": {
    "INF_COY": {
      "spawn_group": ["INF_LINE", "INF_AT", "INF_AT"]
    }
  }
}
```

---

## 11. OpeningTemplate（開幕テンプレ）

```json
{
  "id": "OPENING_MINIMAL",
  "items": [
    { "unit_card_id": "INF_COY", "count": 2 },
    { "unit_card_id": "TANK_COY", "count": 1 },
    { "unit_card_id": "MORTAR_PLT", "count": 1 },
    { "unit_card_id": "RECON_PLT", "count": 1 }
  ],
  "recommended_start_rp": 300
}
```

### RPコスト計算

| ユニット | コスト | 数 | 小計 |
|---------|--------|-----|------|
| INF_COY | 55 | 2 | 110 |
| TANK_COY | 95 | 1 | 95 |
| MORTAR_PLT | 45 | 1 | 45 |
| RECON_PLT | 35 | 1 | 35 |
| **合計** | | | **285** |

> StartRP=300で開幕が成立。

---

## 12. 早見表

### 12.1 ElementArchetype一覧

| ID | role | mobility | strength | speed_all | visual_range |
|----|------|----------|----------|-----------|--------------|
| INF_LINE | INF | FOOT | 100 | 2.0 | 900 |
| INF_AT | INF | FOOT | 100 | 2.0 | 900 |
| INF_MG | INF | FOOT | 100 | 2.0 | 900 |
| TANK_PLT | TANK | TRACKED | 100 | 8.0 | 1800 |
| RECON_VEH | REC | WHEELED | 90 | 9.0 | 1400 |
| RECON_TEAM | REC | FOOT | 70 | 2.2 | 1100 |
| MORTAR_SEC | WEAP | FOOT | 80 | 1.6 | 700 |
| LOG_TRUCK | LOG | WHEELED | 60 | 8.0 | 600 |

### 12.2 UnitCard一覧

| ID | 構成 | rp_cost | 要素数 |
|----|------|---------|--------|
| INF_COY | INF_LINE + INF_MG + INF_AT | 55 | 3 |
| TANK_COY | TANK_PLT × 2 | 95 | 2 |
| RECON_PLT | RECON_VEH + RECON_TEAM | 35 | 2 |
| MORTAR_PLT | MORTAR_SEC | 45 | 1 |
| LOG_PLT | LOG_TRUCK | 30 | 1 |

### 12.3 ConcreteWeapon（MVP 7セット）

| ID | 用途 |
|----|------|
| CW_RIFLE_STD | 歩兵基本 |
| CW_RPG_HEAT | 歩兵AT |
| CW_MG_STD | MG/HMG |
| CW_TANK_KE | 戦車AP |
| CW_TANK_HEATMP | 戦車HEAT |
| CW_MORTAR_HE | 迫撃HE |
| CW_MORTAR_SMOKE | 迫撃煙 |

### 12.4 抑圧閾値

| 値 | 状態 |
|----|------|
| 40 | Suppressed |
| 70 | Pinned |
| 90 | Broken |

### 12.5 カテゴリ別制圧ルール

| Category | capture | contest |
|----------|---------|---------|
| INF | 高 | 高 |
| REC | 低〜中 | 低 |
| VEH/TANK | 0 | 高 |
| WEAP | 0 | 低 |
| LOG/HQ | 0 | 低 |
