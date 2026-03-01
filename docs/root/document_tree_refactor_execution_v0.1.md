# ドキュメントツリー リファクタリング実施計画 v0.1

**作成日**: 2026-02-25
**基準文書**: [document_tree_refactor_plan_v0.1.md](document_tree_refactor_plan_v0.1.md)

---

## Phase 0: インベントリ固定（完了）

### 0.1 ファイル一覧

#### docs/root/ (2 files)
| ファイル | 種別 | 役割 |
|---------|------|------|
| `military_equipment_2026_detailed.md` | Taxonomy | **装備知識のルート**。taxonomy親、語彙の正 |
| `document_tree_refactor_plan_v0.1.md` | Meta | 設計方針・リファクタリング計画 |

#### docs/vehicles_tree/ (2 files)
| ファイル | 種別 | Rootノード対応 | 役割 |
|---------|------|----------------|------|
| `military_vehicles_2026_detailed.md` | Taxonomy | `1_地上プラットフォーム` | 軍用車両の分類体系 |
| `armour_systems_2026_mainstream.md` | Taxonomy | `5_防護・生残性` | 装甲システムの分類体系 |

#### docs/weapons_tree/ (11 files)
| ファイル | 種別 | Rootノード対応 | 役割 |
|---------|------|----------------|------|
| `tank_guns_and_ammunition_2026_mainstream.md` | Taxonomy | `4-2_砲弾・弾薬` | 戦車砲・弾薬の分類体系 |
| `autocannons_2026_mainstream.md` | Taxonomy | `4-2_砲弾・弾薬` | 機関砲の分類体系 |
| `howitzers_2026_mainstream.md` | Taxonomy | `4-2_砲弾・弾薬` | 榴弾砲の分類体系 |
| `mortars_2026_mainstream.md` | Taxonomy | `4-2_砲弾・弾薬` | 迫撃砲の分類体系 |
| `rockets_and_rocket_artillery_2026_mainstream.md` | Taxonomy | `4-3_ロケット` | ロケット砲の分類体系 |
| `man_portable_anti_tank_weapons_2026_mainstream.md` | Taxonomy | `4-1_誘導兵器` | 携行対戦車火器の分類体系 |
| `missiles_guidance_tree.md` | Taxonomy | `4-1_誘導兵器` | ミサイル誘導方式の分類体系 |
| `us_army_weapons_2026.md` | **Detail** | 複数 | 米陸軍武装の具体値・ゲーム値 |
| `russian_army_weapons_2026.md` | **Detail** | 複数 | ロシア軍武装の具体値・ゲーム値 |
| `chinese_army_weapons_2026.md` | **Detail** | 複数 | 中国軍武装の具体値・ゲーム値 |
| `jgsdf_weapons_2026.md` | **Detail** | 複数 | 陸上自衛隊武装の具体値・ゲーム値 |

### 0.2 分類サマリ

| 種別 | ファイル数 | 説明 |
|------|-----------|------|
| Taxonomy | 9 | 分類のみ定義（構造・語彙）|
| Detail | 4 | 国別具体値・ゲーム値変換 |
| Meta | 1 | 設計方針・計画 |
| Index | 0 | **未設置（Phase 2で対応）** |

### 0.3 重複テーマの識別

| テーマ | 重複ファイル | 対応方針 |
|--------|-------------|----------|
| 戦車砲弾薬 | `tank_guns_and_ammunition_2026_mainstream.md` (taxonomy) + 国別Detail 4件 | taxonomyが構造、Detailが具体値。役割明確なので現状維持 |
| ATGM | `missiles_guidance_tree.md` (taxonomy) + `man_portable_anti_tank_weapons_2026_mainstream.md` (taxonomy) + 国別Detail | 誘導方式と携行火器で視点が異なる。相互参照を追加 |
| 装甲 | `armour_systems_2026_mainstream.md` (taxonomy) + 国別Detail内の防護システム記述 | taxonomyが構造、Detailが具体値。現状維持 |

---

## Phase 1: ルート確立

### 1.1 目標
- Root (`military_equipment_2026_detailed.md`) が Branch の親であることを文書上明確化
- `docs/README.md` から Root への導線を強化

### 1.2 作業内容

#### 1.2.1 Root更新
- [x] Branch への公式リンク追加（既存）
- [ ] 語彙の正であることの明示強化
- [ ] 各Branchの責務境界を明記

#### 1.2.2 README.md更新
- [x] Root中心の装備知識ツリーセクション（既存）
- [ ] 全weapons_treeファイルへのリンク追加
- [ ] Index Doc導線追加（Phase 2後）

### 1.3 ステータス: **部分完了**
- Root→Branchリンクは設置済み
- README.mdにRoot参照あり
- 詳細整備はPhase 2と同時に実施

---

## Phase 2: Branch正規化

### 2.1 目標
- 各Branch（vehicles_tree, weapons_tree）に Index Doc を配置
- Leaf文書に「所属Rootノード」と「関連catalog ID」を明記

### 2.2 作業内容

#### 2.2.1 Index Doc 新設

**vehicles_tree/README.md** (新規作成)
```markdown
# Vehicles Tree Index

## 概要
車両に関するドメイン知識サブツリー。

## 所属Rootノード
- `1_地上プラットフォーム（land_platforms）`
- `5_防護・生残性（protection_survivability）`

## ファイル一覧
| ファイル | 種別 | 内容 |
|---------|------|------|
| military_vehicles_2026_detailed.md | Taxonomy | 軍用車両分類体系 |
| armour_systems_2026_mainstream.md | Taxonomy | 装甲システム分類体系 |

## 関連カタログ
- `data/catalog/vehicles_usa.json`
- `data/catalog/vehicles_rus.json`
- `data/catalog/vehicles_chn.json`
- `data/catalog/vehicles_jpn.json`
```

**weapons_tree/README.md** (新規作成)
```markdown
# Weapons Tree Index

## 概要
武器システムに関するドメイン知識サブツリー。

## 所属Rootノード
- `4_兵器（weapons）`

## ファイル一覧

### Taxonomy（分類体系）
| ファイル | Rootノード | 内容 |
|---------|-----------|------|
| tank_guns_and_ammunition_2026_mainstream.md | 4-2 | 戦車砲・弾薬 |
| autocannons_2026_mainstream.md | 4-2 | 機関砲 |
| howitzers_2026_mainstream.md | 4-2 | 榴弾砲 |
| mortars_2026_mainstream.md | 4-2 | 迫撃砲 |
| rockets_and_rocket_artillery_2026_mainstream.md | 4-3 | ロケット砲 |
| man_portable_anti_tank_weapons_2026_mainstream.md | 4-1 | 携行対戦車火器 |
| missiles_guidance_tree.md | 4-1 | ミサイル誘導方式 |

### Detail（国別具体値）
| ファイル | 関連カタログ | 内容 |
|---------|-------------|------|
| us_army_weapons_2026.md | vehicles_usa.json | 米陸軍武装 |
| russian_army_weapons_2026.md | vehicles_rus.json | ロシア軍武装 |
| chinese_army_weapons_2026.md | vehicles_chn.json | 中国軍武装 |
| jgsdf_weapons_2026.md | vehicles_jpn.json | 陸自武装 |

## 関連スクリプト
- `scripts/data/weapon_data.gd`
```

#### 2.2.2 Detail Doc へのメタデータ追加

各国別Detail文書の冒頭に以下を追加:

```markdown
## Document Metadata

| Key | Value |
|-----|-------|
| Type | Detail |
| Root Node | `4_兵器（weapons）` |
| Related Catalog | `data/catalog/vehicles_XXX.json` |
| Related Script | `scripts/data/weapon_data.gd` |
```

### 2.3 ステータス: **未着手**

---

## Phase 3: データ連携

### 3.1 目標
- `data/catalog/*.json` の vehicle ID と docs の対応表を作成
- `weapon_data.gd` の weapon ID と docs の対応表を作成

### 3.2 作業内容

#### 3.2.1 Vehicle ID 対応表

**新規作成**: `docs/root/catalog_docs_mapping.md`

| Vehicle ID | Nation | Display Name | Detail Doc | Notes |
|------------|--------|--------------|------------|-------|
| USA_M1A2_SEPv3 | USA | M1A2 SEPv3 Abrams | us_army_weapons_2026.md | 1.1節 |
| USA_M1A2_SEPv2 | USA | M1A2 SEPv2 Abrams | us_army_weapons_2026.md | 1.2節 |
| USA_M2A4_Bradley | USA | M2A4 Bradley | us_army_weapons_2026.md | 2.1節 |
| RUS_T90M | RUS | T-90M | russian_army_weapons_2026.md | |
| RUS_T80BVM | RUS | T-80BVM | russian_army_weapons_2026.md | |
| CHN_Type99A | CHN | 99A式 | chinese_army_weapons_2026.md | 1節 |
| CHN_Type99 | CHN | 99式 | chinese_army_weapons_2026.md | |
| CHN_ZBD04A | CHN | 04A式 | chinese_army_weapons_2026.md | |
| JPN_Type10 | JPN | 10式 | jgsdf_weapons_2026.md | |
| JPN_Type90 | JPN | 90式 | jgsdf_weapons_2026.md | |
| ... | ... | ... | ... | |

#### 3.2.2 Weapon ID 対応表

| Weapon ID | Nation | Display Name | Detail Doc | Notes |
|-----------|--------|--------------|------------|-------|
| CW_TANK_KE_120_USA | USA | 120mm M256 (M829A4) | us_army_weapons_2026.md | 1.1節 |
| CW_TANK_KE_125_RUS | RUS | 125mm 2A46M-5 (3BM60) | russian_army_weapons_2026.md | |
| CW_TANK_KE_125_CHN | CHN | 125mm ZPT98 (DTC10-125) | chinese_army_weapons_2026.md | 1節 |
| CW_TANK_KE_125_CHN_STD | CHN | 125mm ZPT98 (DTW-125 II) | chinese_army_weapons_2026.md | |
| CW_ATGM_JAVELIN | USA | FGM-148 Javelin | us_army_weapons_2026.md | |
| CW_ATGM_KORNET | RUS | 9M133 Kornet | russian_army_weapons_2026.md | |
| CW_ATGM_HJ10 | CHN | HJ-10 Red Arrow | chinese_army_weapons_2026.md | 4節 |
| CW_QJC88_AA | CHN | 12.7mm QJC-88 | chinese_army_weapons_2026.md | 5節 |
| ... | ... | ... | ... | |

### 3.3 ステータス: **未着手**

---

## Phase 4: 重複統合（将来）

### 4.1 検討対象

| 候補 | 現状 | 統合方針 |
|------|------|----------|
| ATGM関連 | missiles_guidance_tree + man_portable両方にATGM言及 | 相互参照で解決。統合不要 |
| 装甲関連 | armour_systems + 各国Detailの防護記述 | 役割明確。統合不要 |

### 4.2 ステータス: **未着手（Phase 3完了後に再評価）**

---

## 次アクション

1. [ ] `docs/vehicles_tree/README.md` 新規作成
2. [ ] `docs/weapons_tree/README.md` 新規作成
3. [ ] 各国別Detail文書にメタデータセクション追加
4. [ ] `docs/root/catalog_docs_mapping.md` 新規作成（vehicle/weapon ID対応表）
5. [ ] `docs/README.md` 更新（Index Docへのリンク追加）

---

## 運用ルール（確認済み）

- 新規文書追加前に既存Branchへの追加可否を確認
- 新カテゴリ作成時はRoot更新を先行
- データ変更PRはdocs更新を同一PRで実施
- 数値根拠追加時は出典または推定理由を記載
