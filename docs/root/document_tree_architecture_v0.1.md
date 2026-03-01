# ドキュメントツリー アーキテクチャ v0.2

**作成日**: 2026-02-26
**更新日**: 2026-02-26
**ステータス**: Phase 2 完了 → **v0.2: 変更容易性設計を追加**

---

## 0. 設計原則：装備の追加・変更に強い構造

### 0.1 現状の課題

| 課題 | 影響 | 例 |
|------|------|-----|
| **ハードコード武器** | 新武器追加に68箇所以上の関数追加が必要 | weapon_data.gd の create_cw_* |
| **手動同期** | docs/catalog/code の3箇所を手動で整合 | ID追加漏れ、数値不整合 |
| **散在する根拠** | 数値変更時に根拠を探すのが困難 | pen_ke値の出典不明 |
| **テスト追加忘れ** | 新武器のテストが漏れやすい | 未検証の武器が混入 |

### 0.2 設計原則

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Single Source of Truth (SSoT)                    │
│                                                                     │
│   1. 各データには唯一の正（Source of Truth）がある                   │
│   2. 他の場所は正を参照するか、自動生成される                         │
│   3. 変更は正のみに行い、派生は自動で追従する                         │
└─────────────────────────────────────────────────────────────────────┘
```

**具体的な正の配置:**

| データ種別 | Source of Truth | 参照/派生 |
|-----------|-----------------|-----------|
| 武器ID・基本属性 | `data/weapons/*.json` (将来) | weapon_data.gd は読み込み |
| 車両ID・構成 | `data/catalog/vehicles_*.json` | vehicle_catalog.gd は読み込み |
| 数値根拠・出典 | `docs/weapons_tree/*_weapons.md` | JSONのコメント欄にリンク |
| 分類体系・語彙 | `docs/root/military_equipment.md` | 全docsが参照 |

### 0.3 理想的なデータフロー（将来像）

```
                    ┌─────────────────────────────────┐
                    │   docs/weapons_tree/            │
                    │   (根拠・出典・計算式)           │
                    └───────────────┬─────────────────┘
                                    │ 人が参照して
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     data/weapons/*.json                             │
│                     (武器の Single Source of Truth)                 │
│                                                                     │
│   {                                                                 │
│     "id": "CW_TANK_KE_125_CHN",                                    │
│     "display_name": "125mm ZPT98 (DTC10-125)",                     │
│     "source_doc": "chinese_army_weapons_2026.md#section-1",        │
│     "mechanism": "KINETIC",                                         │
│     "pen_ke": { "NEAR": 192, "MID": 160, "FAR": 130 },             │
│     ...                                                             │
│   }                                                                 │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │ 自動読み込み
                                    ▼
                    ┌─────────────────────────────────┐
                    │   scripts/data/weapon_data.gd   │
                    │   (JSONローダー + enum定義のみ)  │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
        ┌───────────────────┐           ┌───────────────────┐
        │ vehicles_*.json   │           │ テスト自動生成     │
        │ (武器IDを参照)     │           │ (JSONから期待値)   │
        └───────────────────┘           └───────────────────┘
```

### 0.4 段階的移行計画

| Phase | 内容 | 効果 |
|-------|------|------|
| **現在** | ハードコード (weapon_data.gd) | 動作確認済み |
| **Phase A** | JSONに武器定義を外出し | 新武器追加がJSON編集のみに |
| **Phase B** | docs→JSON参照リンク整備 | 根拠への到達が容易に |
| **Phase C** | テスト自動生成 | JSONから期待値テスト生成 |
| **Phase D** | CI整合チェック | docs/JSON/code の不整合検出 |

---

## 1. 全体構造

```
                    ┌─────────────────────────────────────┐
                    │           docs/README.md            │
                    │         （プロジェクト入口）          │
                    └─────────────────┬───────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────┐
│   コア仕様       │      │   装備知識ツリー     │      │  システム仕様    │
│  (Game Design)  │      │  (Domain Knowledge) │      │   (Systems)     │
├─────────────────┤      ├─────────────────────┤      ├─────────────────┤
│ spec            │      │ root/ ◀━━ 正       │      │ combat          │
│ ruleset         │      │   └─ Root Doc       │      │ vision          │
│ game_loop       │      │ vehicles_tree/      │      │ damage_model    │
│ architecture    │      │   └─ Index + Leaf   │      │ navigation      │
└─────────────────┘      │ weapons_tree/       │      │ spawn           │
                         │   └─ Index + Leaf   │      │ capture         │
                         └─────────────────────┘      └─────────────────┘
```

---

## 2. 装備知識ツリー 詳細構造

```
docs/root/military_equipment_2026_detailed.md  ◀━━ Taxonomy Root（語彙の正）
    │
    ├── 1_地上プラットフォーム ──────────────────┐
    ├── 4_兵器 ─────────────────────────────────┼──┐
    └── 5_防護・生残性 ─────────────────────────┘  │
                                                    │
    ┌───────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        サブツリー (Branch)                          │
├────────────────────────────────┬────────────────────────────────────┤
│       vehicles_tree/           │         weapons_tree/              │
│       (車両・装甲)              │         (武器システム)              │
├────────────────────────────────┼────────────────────────────────────┤
│                                │                                    │
│  README.md ◀━ Index Doc        │  README.md ◀━ Index Doc           │
│      │                         │      │                             │
│      ├── Taxonomy              │      ├── Taxonomy (7 files)        │
│      │   ├── military_vehicles │      │   ├── tank_guns_ammunition  │
│      │   └── armour_systems    │      │   ├── autocannons           │
│      │                         │      │   ├── howitzers             │
│      └── (車両カタログ参照)     │      │   ├── mortars               │
│           → data/catalog/      │      │   ├── rockets               │
│                                │      │   ├── man_portable_at       │
│                                │      │   └── missiles_guidance     │
│                                │      │                             │
│                                │      └── Detail (4 files)          │
│                                │          ├── us_army_weapons       │
│                                │          ├── russian_army_weapons  │
│                                │          ├── chinese_army_weapons  │
│                                │          └── jgsdf_weapons         │
└────────────────────────────────┴────────────────────────────────────┘
```

---

## 3. ドキュメント種別

### 3.1 種別定義

| 種別 | 目的 | 数値含有 | 例 |
|------|------|----------|-----|
| **Root** | 全体のtaxonomy親、語彙の正 | No | military_equipment_2026_detailed.md |
| **Index** | サブツリー入口、ナビゲーション | No | vehicles_tree/README.md |
| **Taxonomy** | 分類構造・語彙定義 | No | tank_guns_ammunition_2026.md |
| **Detail** | 国別具体値、ゲーム値変換 | Yes | chinese_army_weapons_2026.md |
| **Meta** | 設計方針・管理文書 | No | document_tree_refactor_plan.md |

### 3.2 ファイル分類マトリクス

```
                     Root    Index   Taxonomy   Detail   Meta
                     ────    ─────   ────────   ──────   ────
root/
  military_equipment   ●
  refactor_plan                                            ●
  refactor_execution                                       ●
  catalog_mapping                                          ●

vehicles_tree/
  README                       ●
  military_vehicles                      ●
  armour_systems                         ●

weapons_tree/
  README                       ●
  tank_guns_ammunition                   ●
  autocannons                            ●
  howitzers                              ●
  mortars                                ●
  rockets                                ●
  man_portable_at                        ●
  missiles_guidance                      ●
  us_army_weapons                                  ●
  russian_army_weapons                             ●
  chinese_army_weapons                             ●
  jgsdf_weapons                                    ●
```

---

## 4. データフロー

### 4.1 知識からゲームデータへの変換

```
┌─────────────────────────────────────────────────────────────────────┐
│                       ドメイン知識層                                 │
│                                                                     │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │  Taxonomy    │ ──▶  │   Detail     │ ──▶  │  Mapping     │      │
│  │  (分類体系)   │      │  (国別具体値) │      │  (対応表)    │      │
│  └──────────────┘      └──────────────┘      └──────────────┘      │
│         │                     │                     │              │
└─────────┼─────────────────────┼─────────────────────┼──────────────┘
          │                     │                     │
          │ 語彙参照            │ 数値参照            │ ID参照
          ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       ゲームデータ層                                 │
│                                                                     │
│  ┌──────────────────┐              ┌──────────────────┐            │
│  │  weapon_data.gd  │◀─────────────│ catalog_docs_    │            │
│  │  (武器定義)       │              │ mapping.md       │            │
│  └──────────────────┘              └──────────────────┘            │
│           │                                │                        │
│           ▼                                ▼                        │
│  ┌──────────────────┐              ┌──────────────────┐            │
│  │ vehicles_*.json  │◀─────────────│  ID対応表        │            │
│  │ (車両カタログ)    │              │  (vehicle/weapon)│            │
│  └──────────────────┘              └──────────────────┘            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 変更時のデータフロー

```
新規武器追加の例:

1. Taxonomy確認
   └─▶ weapons_tree/tank_guns_ammunition.md に分類存在？
       ├─ Yes → 2へ
       └─ No  → Root更新 → Taxonomy追加 → 2へ

2. Detail追加
   └─▶ weapons_tree/<nation>_army_weapons.md に具体値追加

3. 対応表更新
   └─▶ root/catalog_docs_mapping.md に Weapon ID 行追加

4. 実装
   └─▶ scripts/data/weapon_data.gd に WeaponType 追加

5. カタログ更新
   └─▶ data/catalog/vehicles_<nation>.json の武装欄更新

6. テスト
   └─▶ tests/test_<nation>_army_weapons.gd にテスト追加
```

---

## 5. ナビゲーションパス

### 5.1 ドキュメント間の参照関係

```
docs/README.md
    │
    ├──▶ root/military_equipment_2026_detailed.md (Root)
    │        │
    │        └──▶ 語彙定義（MBT, IFV, APFSDS, ATGM...）
    │
    ├──▶ root/catalog_docs_mapping.md
    │        │
    │        ├──▶ Vehicle ID → Detail Doc
    │        └──▶ Weapon ID → Detail Doc
    │
    ├──▶ vehicles_tree/README.md (Index)
    │        │
    │        ├──▶ military_vehicles_2026.md (Taxonomy)
    │        ├──▶ armour_systems_2026.md (Taxonomy)
    │        └──▶ data/catalog/vehicles_*.json
    │
    └──▶ weapons_tree/README.md (Index)
             │
             ├──▶ *_2026_mainstream.md (Taxonomy × 7)
             ├──▶ *_army_weapons_2026.md (Detail × 4)
             └──▶ scripts/data/weapon_data.gd
```

### 5.2 逆引きパス（データから根拠へ）

```
CW_TANK_KE_125_CHN (武器ID)
    │
    ├─[1]─▶ catalog_docs_mapping.md で検索
    │           └─▶ "chinese_army_weapons_2026.md Section 1"
    │
    ├─[2]─▶ chinese_army_weapons_2026.md
    │           └─▶ 具体値・出典・計算根拠
    │
    └─[3]─▶ tank_guns_ammunition_2026.md
                └─▶ 分類上の位置づけ（125mm APFSDS）
```

---

## 6. 責務境界

### 6.1 各層の責務

| 層 | 責務 | やること | やらないこと |
|----|------|----------|--------------|
| **Root** | 語彙統一 | 分類体系の定義 | 具体数値の記載 |
| **Index** | ナビゲーション | ファイル一覧・関連リンク | 詳細内容の記載 |
| **Taxonomy** | 構造定義 | カテゴリ・属性の定義 | 国別の実装詳細 |
| **Detail** | 具体値提供 | 数値・出典・変換式 | 分類の再定義 |
| **Mapping** | 対応管理 | ID⇔Doc参照 | 内容の解説 |

### 6.2 変更時の影響範囲

```
変更タイプ別の更新対象:

┌────────────────────┬────────┬────────┬──────────┬────────┬─────────┐
│ 変更タイプ         │ Root   │ Index  │ Taxonomy │ Detail │ Mapping │
├────────────────────┼────────┼────────┼──────────┼────────┼─────────┤
│ 新カテゴリ追加     │   ●    │   ○    │    ●     │   ○    │    ○    │
│ 新武器追加（既存分類）│       │        │          │   ●    │    ●    │
│ 数値修正           │        │        │          │   ●    │         │
│ 新国追加           │        │   ●    │          │   ●    │    ●    │
│ ファイル名変更     │        │   ●    │          │        │    ●    │
└────────────────────┴────────┴────────┴──────────┴────────┴─────────┘

● = 必須更新, ○ = 状況により更新
```

---

## 7. 変更パターン別ガイド

### 7.1 パターン一覧

| パターン | 頻度 | 難度 | 更新箇所 |
|---------|------|------|----------|
| A. 数値修正（既存武器） | 高 | 低 | Detail + weapon_data.gd |
| B. 新武器追加（既存分類） | 中 | 中 | Detail + weapon_data.gd + catalog + test |
| C. 新車両追加 | 中 | 中 | catalog + (必要なら B) |
| D. 新分類追加 | 低 | 高 | Root + Taxonomy + 以降は B |
| E. 新国追加 | 低 | 高 | 複数ファイル新規作成 |

### 7.2 パターン A: 数値修正（既存武器）

**例**: DTC10-125の貫通力を800mm→820mmに修正

```
手順:
1. docs/weapons_tree/chinese_army_weapons_2026.md
   └─ 該当セクションの数値と出典を更新

2. scripts/data/weapon_data.gd
   └─ create_cw_tank_ke_125_chn() の pen_ke 値を更新
      pen_ke = { RangeBand.NEAR: 192, ... }
                                 ↓
      pen_ke = { RangeBand.NEAR: 196, ... }  # 980mm/5=196

3. tests/test_chinese_army_weapons.gd
   └─ 期待値を更新（必要な場合）

チェック:
□ 出典URLまたは推定理由を記載したか
□ テストが通るか
```

### 7.3 パターン B: 新武器追加（既存分類）

**例**: 中国軍の新型ATGM「HJ-12」を追加

```
手順:
1. Taxonomy確認
   └─ docs/weapons_tree/missiles_guidance_tree.md
      ATGMの分類に「Fire-and-Forget」が存在 → OK

2. Detail追加
   └─ docs/weapons_tree/chinese_army_weapons_2026.md
      新セクション「## CW_ATGM_HJ12」を追加
      - 貫通力、射程、誘導方式、出典を記載

3. 対応表更新
   └─ docs/root/catalog_docs_mapping.md
      Weapon ID表に行追加:
      | CW_ATGM_HJ12 | CHN | HJ-12 | chinese_army_weapons_2026.md | 新規 |

4. weapon_data.gd
   └─ static func create_cw_atgm_hj12() を追加
   └─ get_all_concrete_weapons() に追加

5. vehicles_*.json
   └─ 搭載車両の atgm または secondary_weapons に追加

6. テスト追加
   └─ tests/test_chinese_army_weapons.gd に検証追加

チェック:
□ IDが命名規則に従っているか (CW_<TYPE>_<NAME>)
□ 出典が明記されているか
□ 類似武器との整合性（貫通力の相対関係）
□ テストが通るか
```

### 7.4 パターン C: 新車両追加

**例**: 中国軍の新型IFV「ZBD-09A」を追加

```
手順:
1. 武装確認
   └─ 搭載武器が既存か確認
      - 30mm機関砲 → CW_AUTOCANNON_30_CHN 存在
      - HJ-73 ATGM → CW_ATGM_HJ73 存在
      → 新規武器不要

2. catalog追加
   └─ data/catalog/vehicles_chn.json
      {
        "id": "CHN_ZBD09A",
        "display_name": "ZBD-09A",
        "main_gun": { "weapon_id": "CW_AUTOCANNON_30_CHN" },
        "atgm": { "weapon_id": "CW_ATGM_HJ73", "count": 4 },
        ...
      }

3. 対応表更新
   └─ docs/root/catalog_docs_mapping.md
      Vehicle ID表に行追加

4. Detail更新（任意）
   └─ docs/weapons_tree/chinese_army_weapons_2026.md
      搭載車両リストにZBD-09Aを追加

チェック:
□ vehicle_idが命名規則に従っているか (<NATION>_<Name>)
□ 武装IDが正しいか（存在するIDを参照）
□ 装甲値・速度等の数値に出典があるか
```

### 7.5 パターン D: 新分類追加

**例**: 「対ドローン兵器」カテゴリを新設

```
手順:
1. Root更新
   └─ docs/root/military_equipment_2026_detailed.md
      「4_兵器」配下に「4-5_対UAS（counter-UAS）」を追加

2. Taxonomy新設
   └─ docs/weapons_tree/counter_uas_2026_mainstream.md
      分類体系を定義（ジャマー、迎撃弾、レーザー等）

3. Index更新
   └─ docs/weapons_tree/README.md
      Taxonomy表に行追加

4. 以降はパターンBに従う

チェック:
□ 既存分類で表現できないか再検討したか
□ Rootの語彙が他と整合するか
□ 命名規則に従っているか
```

### 7.6 パターン E: 新国追加

**例**: 韓国軍（ROK）を追加

```
手順:
1. catalog新規作成
   └─ data/catalog/vehicles_rok.json

2. Detail新規作成
   └─ docs/weapons_tree/rok_army_weapons_2026.md

3. Index更新
   └─ docs/vehicles_tree/README.md - 関連カタログ追加
   └─ docs/weapons_tree/README.md - Detail表追加

4. 対応表更新
   └─ docs/root/catalog_docs_mapping.md
      新セクション「### 1.5 ROK」を追加

5. テスト新規作成
   └─ tests/test_rok_army_weapons.gd

6. weapon_data.gd
   └─ ROK固有の武器を追加（K2戦車砲、K21機関砲等）

チェック:
□ 国コード（3文字）が一意か
□ 既存国との武器共有を検討したか（米国系武器等）
□ 全テストが通るか
```

---

## 8. 品質ゲート

### 8.1 PR前チェックリスト（必須）

```
■ 全変更パターン共通
□ 変更理由・出典がdocsに記載されている
□ IDが命名規則に従っている
□ catalog_docs_mapping.md が更新されている
□ 関連テストが存在し、パスする

■ 武器追加時
□ pen_ke/pen_ce値が類似武器と整合している
  - 同口径の他国武器と比較
  - 新型＞旧型の関係が維持されている
□ 射程・発射速度が現実的な値である

■ 車両追加時
□ 参照する武器IDが全て存在する
□ 装甲値が類似車両と整合している
```

### 8.2 整合性チェックコマンド（将来自動化）

```bash
# 全weapon_idがweapon_data.gdに存在するか
tools/check_weapon_ids.sh

# 全vehicle_idがcatalog_docs_mapping.mdに存在するか
tools/check_vehicle_mapping.sh

# docsのリンク切れチェック
tools/check_doc_links.sh

# 数値整合チェック（docs内の数値とJSONの一致）
tools/check_value_consistency.sh
```

### 8.3 CI統合（将来）

```yaml
# .github/workflows/docs-check.yml
on: [pull_request]
jobs:
  check-docs:
    steps:
      - run: tools/check_weapon_ids.sh
      - run: tools/check_vehicle_mapping.sh
      - run: tools/check_doc_links.sh
```

---

## 9. ID命名規則

### 9.1 Vehicle ID

```
<NATION>_<Name>

NATION: USA, RUS, CHN, JPN, ROK, ...（3文字大文字）
Name:   型式名（アンダースコア区切り）

例:
  USA_M1A2_SEPv3
  CHN_Type99A
  JPN_Type10
  RUS_T90M
```

### 9.2 Weapon ID

```
CW_<TYPE>_<DETAIL>

CW:     Concrete Weapon（具体武器）の接頭辞
TYPE:   武器種別
DETAIL: 口径、国、バリエーション等

武器種別:
  TANK_KE_*      戦車砲APFSDS
  TANK_CE_*      戦車砲HEAT/HE
  AUTOCANNON_*   機関砲
  ATGM_*         対戦車ミサイル
  HOWITZER_*     榴弾砲
  MORTAR_*       迫撃砲
  *_COAX         同軸機銃
  *_AA           対空機銃

例:
  CW_TANK_KE_125_CHN      125mm APFSDS（中国）
  CW_ATGM_JAVELIN         FGM-148 Javelin
  CW_AUTOCANNON_30_RUS    30mm 2A42
  CW_M240_COAX            M240C同軸機銃
  CW_QJC88_AA             QJC-88対空機銃
```

---

## 10. 関連ドキュメント

| ドキュメント | 役割 |
|-------------|------|
| [document_tree_refactor_plan_v0.1.md](document_tree_refactor_plan_v0.1.md) | 設計方針・目的 |
| [document_tree_refactor_execution_v0.1.md](document_tree_refactor_execution_v0.1.md) | 実施計画・インベントリ |
| [catalog_docs_mapping.md](catalog_docs_mapping.md) | ID対応表 |
| [../vehicles_tree/README.md](../vehicles_tree/README.md) | 車両サブツリーIndex |
| [../weapons_tree/README.md](../weapons_tree/README.md) | 武器サブツリーIndex |

---

## 変更履歴

| バージョン | 日付 | 内容 |
|-----------|------|------|
| v0.1 | 2026-02-26 | 初版作成（全体構造、データフロー、責務境界） |
| v0.2 | 2026-02-26 | 変更容易性設計を追加（設計原則、変更パターン別ガイド、ID命名規則） |
