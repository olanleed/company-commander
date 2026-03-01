# Weapons Tree Index

武器システムに関するドメイン知識サブツリー。

## 所属Rootノード

このサブツリーは以下のRootノードに対応:

- `4_兵器（weapons）` → 砲弾・ミサイル・ロケット

**Root文書**: [military_equipment_2026_detailed.md](../root/military_equipment_2026_detailed.md)

---

## ファイル一覧

### Taxonomy（分類体系）

| ファイル | Rootノード | 内容 |
|---------|-----------|------|
| [tank_guns_and_ammunition_2026_mainstream.md](tank_guns_and_ammunition_2026_mainstream.md) | 4-2 | 戦車砲・弾薬（120/125/105mm、APFSDS/HEAT/HE） |
| [autocannons_2026_mainstream.md](autocannons_2026_mainstream.md) | 4-2 | 機関砲（20-40mm、ABM/APFSDS） |
| [howitzers_2026_mainstream.md](howitzers_2026_mainstream.md) | 4-2 | 榴弾砲（155/152mm、誘導砲弾） |
| [mortars_2026_mainstream.md](mortars_2026_mainstream.md) | 4-2 | 迫撃砲（60/81/120mm） |
| [rockets_and_rocket_artillery_2026_mainstream.md](rockets_and_rocket_artillery_2026_mainstream.md) | 4-3 | ロケット砲（MLRS、誘導ロケット） |
| [man_portable_anti_tank_weapons_2026_mainstream.md](man_portable_anti_tank_weapons_2026_mainstream.md) | 4-1 | 携行対戦車火器（RPG/LAW/ATGM） |
| [missiles_guidance_tree.md](missiles_guidance_tree.md) | 4-1 | ミサイル誘導方式（SACLOS/Fire-and-Forget/TOF） |

### Detail（国別具体値）

| ファイル | 関連カタログ | 内容 |
|---------|-------------|------|
| [us_army_weapons_2026.md](us_army_weapons_2026.md) | vehicles_usa.json | 米陸軍武装（M829A4, TOW-2B, Javelin等） |
| [russian_army_weapons_2026.md](russian_army_weapons_2026.md) | vehicles_rus.json | ロシア軍武装（3BM60, Kornet, Refleks等） |
| [chinese_army_weapons_2026.md](chinese_army_weapons_2026.md) | vehicles_chn.json | 中国軍武装（DTC10-125, HJ-10, QJC-88等） |
| [jgsdf_weapons_2026.md](jgsdf_weapons_2026.md) | vehicles_jpn.json | 陸自武装（10式APFSDS, 01式LMAT, 中MAT等） |

---

## Taxonomy vs Detail

| 種別 | 内容 | 数値 | 役割 |
|------|------|------|------|
| **Taxonomy** | 分類構造・語彙定義 | なし | 「何があるか」の体系 |
| **Detail** | 国別の具体的パラメータ | あり | ゲーム値への変換根拠 |

新規武器追加時:
1. 該当Taxonomyに分類が存在するか確認
2. なければRoot/Taxonomyに語彙追加
3. Detail文書に具体値追加
4. `weapon_data.gd` に実装

---

## 関連スクリプト

| ファイル | 役割 |
|---------|------|
| `scripts/data/weapon_data.gd` | 武器データ定義（get_all_concrete_weapons） |
| `scripts/data/weapon_type.gd` | 武器タイプデータ構造 |

---

## ペネトレーション換算式

全Detail文書で共通:

```
pen_ke / pen_ce = RHA換算値(mm) / 5

例: 800mm RHA → pen_ke = 160
```

---

## 車両情報

車両本体の情報は [vehicles_tree](../vehicles_tree/README.md) を参照。
