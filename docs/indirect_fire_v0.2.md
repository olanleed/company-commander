# 間接射撃システム仕様 v0.2

## 概要

本仕様は間接射撃（迫撃砲・榴弾砲）の着弾効果と装甲への影響を定義する。
現行の `combat_system.gd` の `calculate_indirect_impact_effect()` を拡張する形で実装する。

---

## 1. 着弾メカニクス

### 1.1 CEP（Circular Error Probable）

着弾位置は狙点からの誤差を持つ。`sigma_hit_m` をガウス分布の標準偏差として使用。

```
着弾位置 = 狙点 + (ガウス乱数 × sigma_hit_m)
CEP ≈ sigma_hit_m × 1.18  （50%の弾がこの半径内に落ちる）
```

| 武器 | sigma_hit_m | CEP (参考) | 備考 |
|------|------------|------------|------|
| 60mm迫撃砲 | 30.0m | 35m | 携帯型、精度低 |
| 81mm迫撃砲 | 25.0m | 30m | 標準迫撃砲 |
| 120mm迫撃砲 | 20.0m | 24m | 自走型、精度良 |
| 155mm榴弾砲 | 30.0m | 35m | 長射程、CEP大 |
| 155mm誘導砲弾 | 10.0m | 12m | GPS/レーザー誘導 |
| 152mm榴弾砲 | 35.0m | 41m | ロシア砲 |

### 1.2 観測リンクによる精度補正

```gdscript
# 観測リンクがある場合
effective_sigma = sigma_hit_m × 0.7

# 観測リンクがない場合（地図射撃）
effective_sigma = sigma_hit_m × 1.5

# requires_observer = true の武器は観測なしで射撃不可
```

---

## 2. 効果半径

### 2.1 半径の種類

| 半径 | 変数名 | 説明 |
|------|--------|------|
| **直撃半径** | direct_hit_radius_m | この範囲内は直撃判定（最大効果） |
| **衝撃半径** | shock_radius_m | 強い抑圧効果（100%→減衰） |
| **爆風半径** | blast_radius_m | 殺傷・ダメージ効果（100%→減衰） |

### 2.2 口径別の効果半径

| 武器 | 直撃半径 | 衝撃半径 | 爆風半径 |
|------|---------|---------|---------|
| 60mm迫撃砲 | 1.5m | 15m | 10m |
| 81mm迫撃砲 | 2.5m | 25m | 18m |
| 120mm迫撃砲 | 3.0m | 30m | 25m |
| 155mm榴弾砲 | 5.0m | 50m | 35m |
| 152mm榴弾砲 | 5.0m | 48m | 32m |

---

## 3. 効果計算

### 3.1 距離減衰（Falloff）

```gdscript
# 線形減衰
falloff = clamp(1.0 - distance_from_impact / blast_radius, 0.0, 1.0)

# 直撃半径内は最大効果
if distance_from_impact <= direct_hit_radius_m:
    falloff = 1.0
```

### 3.2 抑圧効果

```gdscript
d_supp = K_IF_SUPP × (supp_power / 100) × falloff × M_cover × M_entrench × M_dispersion
```

| 定数/係数 | 値 | 説明 |
|----------|-----|------|
| K_IF_SUPP | 3.0 | 間接射撃抑圧係数 |
| supp_power | 武器定義 | 抑圧力（0-100） |
| M_cover | 地形依存 | 遮蔽係数 |
| M_entrench | 0.90 | 塹壕係数 |
| M_dispersion | 0.85-1.15 | 分散モード |

**抑圧力（supp_power）の目安**:

| 口径 | supp_power | 1発中心での抑圧 |
|------|-----------|----------------|
| 60mm | 70 | 21% |
| 81mm | 90 | 27% |
| 120mm | 95 | 29% |
| 155mm | 100 | 30% |

### 3.3 殺傷効果（Lethality）

```gdscript
d_dmg = K_IF_DMG × (lethality / 100) × falloff × M_cover × M_entrench × M_dispersion × M_vuln
```

| 定数/係数 | 値 | 説明 |
|----------|-----|------|
| K_IF_DMG | 2.0 | 間接射撃ダメージ係数 |
| lethality | 武器定義 | 殺傷力（0-100、目標クラス別） |
| M_vuln | 後述 | 装甲脆弱性 |

---

## 4. 装甲への効果（v0.2拡張）

### 4.1 効果メカニズムの分類

大口径HE（155mm/152mm）は以下の2つのメカニズムで装甲目標に影響を与える：

1. **衝撃効果（Concussion）**: 直接的な爆風圧力
   - センサー・電子機器への影響
   - 乗員への衝撃（抑圧）

2. **破片効果（Fragmentation）**: 高速破片による貫通
   - 軽装甲・TOP装甲への貫通
   - サブシステムダメージ

### 4.2 口径別の装甲効果

#### 従来の脆弱性（BLAST_FRAG共通）

```gdscript
# 現行実装: 爆風・破片は装甲に弱い
match armor_class:
    0: return 1.0    # ソフトスキン → 100%
    1: return 0.4    # 軽装甲 → 40%
    2: return 0.15   # 中装甲 → 15%
    3: return 0.05   # 重装甲 → 5%
```

#### 大口径HE（155mm/152mm）の追加効果

新しい `HeavyMechanism` を導入：

```gdscript
enum HeavyMechanism {
    NONE,           # 通常の爆風・破片
    HEAVY_HE,       # 大口径HE（155mm/152mm）
}
```

**大口径HE専用の脆弱性テーブル**:

```gdscript
# heavy_mechanism == HEAVY_HE の場合
func _get_heavy_he_vulnerability(armor_class: int, distance: float, blast_radius: float) -> Dictionary:
    var proximity = 1.0 - (distance / blast_radius)  # 近いほど高い

    # 直撃判定（direct_hit_radius_m以内）
    var is_direct_hit = distance <= direct_hit_radius_m

    match armor_class:
        0:  # ソフトスキン
            return {
                "dmg_mult": 1.0,
                "supp_mult": 1.0,
                "subsystem_dmg": 0.0,
            }
        1:  # 軽装甲（APC、RECON）
            return {
                "dmg_mult": 0.6 if is_direct_hit else 0.3,   # 直撃で貫通の可能性
                "supp_mult": 0.8,                            # 抑圧は効く
                "subsystem_dmg": 0.15 * proximity,           # サブシステム損傷
            }
        2:  # 中装甲（IFV）
            return {
                "dmg_mult": 0.35 if is_direct_hit else 0.15, # 直撃でTOP貫通の可能性
                "supp_mult": 0.6,                            # 抑圧はやや効く
                "subsystem_dmg": 0.10 * proximity,
            }
        3:  # 重装甲（MBT）
            return {
                "dmg_mult": 0.15 if is_direct_hit else 0.05, # 直撃でもほぼ無効
                "supp_mult": 0.4,                            # それでも抑圧は与える
                "subsystem_dmg": 0.08 * proximity,           # センサー等に損傷
            }
```

### 4.3 サブシステムダメージ

大口径HEの直撃・至近弾は装甲車両のサブシステムに損傷を与える：

```gdscript
# 155mm直撃による効果（MBT相手）
subsystem_damage = {
    "sensors_hp": -8,      # 照準器・センサー損傷（衝撃）
    "mobility_hp": -5,     # 履帯・転輪損傷（破片）
    "firepower_hp": -3,    # 砲身・装填機構（低確率）
}
```

**適用条件**:
- distance <= shock_radius_m（衝撃半径内）
- 確率判定: `randf() < subsystem_dmg × falloff`

### 4.4 抑圧効果の維持

大口径HEは装甲目標にも抑圧を与える（乗員への心理的影響）：

```gdscript
# 装甲車両への抑圧は別係数
vehicle_supp = d_supp × supp_mult  # supp_mult は装甲クラス依存

# MBT（armor_class=3）でも 155mm直撃で 30% × 0.4 = 12% 抑圧
```

---

## 5. 煙幕（SMOKE）

### 5.1 煙幕の効果

煙幕弾は殺傷力を持たないが、視界遮断効果を持つ。

```gdscript
# 煙幕弾の特性
lethality = 0            # ダメージなし
suppression_power = 20   # 弱い抑圧（驚き効果）
smoke_radius = 50.0      # 煙幕半径
smoke_duration = 60.0    # 持続時間（秒）
```

### 5.2 視界への影響

```gdscript
# 煙幕内のLoS判定
if is_in_smoke(observer_pos) or is_in_smoke(target_pos):
    los_result = LosResult.BLOCKED

# 煙幕を通過するLoS
if los_passes_through_smoke(observer_pos, target_pos):
    los_result = LosResult.PARTIAL  # 部分遮蔽
    vision_range *= 0.3             # 視界30%
```

---

## 6. 定数まとめ

### 6.1 game_constants.gd への追加

```gdscript
## 間接射撃（大口径HE）
const HEAVY_HE_CALIBER_THRESHOLD: float = 120.0  # mm、この口径以上で大口径扱い

## 大口径HE装甲効果
const HEAVY_HE_VULN_SOFT: float = 1.0
const HEAVY_HE_VULN_LIGHT: float = 0.6
const HEAVY_HE_VULN_LIGHT_INDIRECT: float = 0.3
const HEAVY_HE_VULN_MEDIUM: float = 0.35
const HEAVY_HE_VULN_MEDIUM_INDIRECT: float = 0.15
const HEAVY_HE_VULN_HEAVY: float = 0.15
const HEAVY_HE_VULN_HEAVY_INDIRECT: float = 0.05

## 大口径HE抑圧効果（装甲車両）
const HEAVY_HE_SUPP_MULT_LIGHT: float = 0.8
const HEAVY_HE_SUPP_MULT_MEDIUM: float = 0.6
const HEAVY_HE_SUPP_MULT_HEAVY: float = 0.4

## サブシステムダメージ確率（大口径HE直撃時）
const HEAVY_HE_SUBSYS_PROB_LIGHT: float = 0.15
const HEAVY_HE_SUBSYS_PROB_MEDIUM: float = 0.10
const HEAVY_HE_SUBSYS_PROB_HEAVY: float = 0.08

## 煙幕
const SMOKE_DEFAULT_RADIUS: float = 50.0
const SMOKE_DEFAULT_DURATION: float = 60.0
const SMOKE_VISION_MULT: float = 0.3
```

---

## 7. 武器データ更新

### 7.1 155mm榴弾砲（修正案）

```gdscript
static func create_cw_howitzer_155() -> WeaponType:
    var w := WeaponType.new()
    w.id = "CW_HOWITZER_155"
    w.display_name = "155mm Howitzer"
    w.mechanism = Mechanism.BLAST_FRAG
    w.heavy_mechanism = HeavyMechanism.HEAVY_HE  # 追加
    w.fire_model = FireModel.INDIRECT
    w.caliber_mm = 155.0  # 追加: 口径
    w.min_range_m = 2000.0
    w.max_range_m = 30000.0
    w.sigma_hit_m = 30.0
    w.direct_hit_radius_m = 5.0
    w.shock_radius_m = 50.0
    w.blast_radius_m = 35.0  # 30→35に拡大

    # 装甲目標へのlethality引き上げ（直撃時効果）
    w.lethality = {
        RangeBand.NEAR: {
            TargetClass.SOFT: 95,
            TargetClass.LIGHT: 75,      # 70→75
            TargetClass.HEAVY: 40,      # 20→40（大口径HE効果）
            TargetClass.FORTIFIED: 85,  # 80→85
        },
        # MID, FAR も同様に調整
    }
```

### 7.2 152mm榴弾砲（ロシア）

```gdscript
w.id = "CW_HOWITZER_152"
w.heavy_mechanism = HeavyMechanism.HEAVY_HE
w.caliber_mm = 152.0
w.sigma_hit_m = 35.0      # ロシア砲はやや散布大
w.blast_radius_m = 32.0
w.lethality[RangeBand.NEAR][TargetClass.HEAVY] = 35  # 155mmよりやや低い
```

---

## 8. 実装優先度

### Phase 1（必須）
- [ ] `heavy_mechanism` フィールド追加
- [ ] `_get_heavy_he_vulnerability()` 実装
- [ ] 155mm/152mm の lethality 調整

### Phase 2（推奨）
- [ ] サブシステムダメージ判定
- [ ] 観測リンクによるCEP補正
- [ ] 煙幕の視界遮蔽効果

### Phase 3（将来）
- [ ] 誘導砲弾（Excalibur等）
- [ ] エアバースト信管
- [ ] 照明弾

---

## 9. バランス目標

### 9.1 155mm vs MBT（T-90等）

| 状況 | 効果 |
|------|------|
| 直撃（5m以内） | 12-15%ダメージ、12%抑圧、サブシステム損傷8% |
| 至近弾（10m） | 5-8%ダメージ、8%抑圧 |
| 爆風内（20m） | 2-3%ダメージ、5%抑圧 |
| 爆風外（35m+） | 効果なし |

**想定シナリオ**: 155mm砲兵中隊（6門）が3発ずつ射撃（18発）した場合
- CEP 30mで平均2-3発が直撃・至近弾
- MBTに累計30-50%ダメージ、50-70%抑圧
- → 1個中隊の集中砲撃で1両のMBTを行動不能にできる

### 9.2 155mm vs IFV（BMP-3等）

| 状況 | 効果 |
|------|------|
| 直撃 | 35-40%ダメージ、18%抑圧、サブシステム損傷10% |
| 至近弾 | 15-20%ダメージ、12%抑圧 |

→ 直撃2-3発で撃破可能

### 9.3 81mm迫撃砲 vs 歩兵

| 状況 | 効果 |
|------|------|
| 直撃 | 18-20%ダメージ、27%抑圧 |
| 爆風内（10m） | 8-10%ダメージ、15%抑圧 |

→ 6発でPINNED状態、継続射撃で壊滅

---

## 関連ドキュメント

- [combat_v0.1.md](combat_v0.1.md) - 戦闘システム全体
- [munition_system_v0.1.md](munition_system_v0.1.md) - 弾薬システム
- [damage_model_v0.1.md](damage_model_v0.1.md) - ダメージモデル
- [concrete_weapons_v0.1.md](concrete_weapons_v0.1.md) - 具体武器データ

---

*作成: 2026-02-24*
*バージョン: v0.2（大口径HE装甲効果追加）*
