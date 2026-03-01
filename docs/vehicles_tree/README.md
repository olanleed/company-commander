# Vehicles Tree Index

車両に関するドメイン知識サブツリー。

## 所属Rootノード

このサブツリーは以下のRootノードに対応:

- `1_地上プラットフォーム（land_platforms）` → 軍用車両
- `5_防護・生残性（protection_survivability）` → 装甲システム

**Root文書**: [military_equipment_2026_detailed.md](../root/military_equipment_2026_detailed.md)

---

## ファイル一覧

| ファイル | 種別 | 内容 |
|---------|------|------|
| [military_vehicles_2026_detailed.md](military_vehicles_2026_detailed.md) | Taxonomy | 軍用車両の分類体系（MBT/IFV/APC/砲兵/工兵/兵站など） |
| [armour_systems_2026_mainstream.md](armour_systems_2026_mainstream.md) | Taxonomy | 装甲システムの分類体系（複合装甲/ERA/APS/防護設計） |

---

## 関連カタログ

車両カタログ（具体的なゲーム値）:

| ファイル | 国 | 車両数 |
|---------|-----|--------|
| `data/catalog/vehicles_usa.json` | 米国 | M1A2, Bradley, Stryker等 |
| `data/catalog/vehicles_rus.json` | ロシア | T-90M, T-80BVM, BMP-3等 |
| `data/catalog/vehicles_chn.json` | 中国 | Type99A, ZBD-04A, PLZ-07等 |
| `data/catalog/vehicles_jpn.json` | 日本 | 10式, 16式, 89式等 |

---

## 関連スクリプト

| ファイル | 役割 |
|---------|------|
| `scripts/data/vehicle_catalog.gd` | 車両カタログローダー |
| `scripts/data/vehicle_config.gd` | 車両設定データ構造 |

---

## 武装情報

車両の武装詳細は [weapons_tree](../weapons_tree/README.md) を参照:

- 国別武装: `*_weapons_2026.md`
- 武器分類: `*_2026_mainstream.md`
