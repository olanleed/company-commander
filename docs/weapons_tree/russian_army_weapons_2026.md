# ロシア陸軍 武装システム仕様書 (2026年版)

## 概要

本ドキュメントはロシア連邦陸軍の主要車両に搭載される武器システムの詳細仕様をまとめたものである。
ゲーム内パラメータへの変換基準を含む。

---

## RHA換算スケール

ゲーム内貫徹力は以下の基準で換算:

```
ゲーム値 100 = 500mm RHA
ゲーム値 1 = 5mm RHA
```

---

## 1. 主力戦車 (MBT)

### 1.1 T-90M プロルィフ (Proryv)

**主砲**: 2A46M-5 125mm滑腔砲

| 弾種 | 貫徹力 (mm RHA) | 射程 | ゲーム値 (pen_ke/ce) |
|------|-----------------|------|---------------------|
| 3BM60 Svinets-2 APFSDS | 650-740mm @ 2km | 3000m+ | 130-140 |
| 3BM59 Svinets-1 APFSDS | 600-650mm @ 2km | 3000m+ | 120-130 |
| 3BM44 Mango APFSDS | 500-520mm @ 2km | 3000m+ | 100-105 |
| 3BK31 Start HEAT-FS | 700mm | 2000m | 140 |
| 3OF26M HE-FRAG | - | 4000m | - |

**砲発射式ATGM**: 9M119M Refleks
- 射程: 75-5000m
- 貫徹力: 700-900mm (タンデムHEAT)
- ゲーム値: pen_ce = 140-180

**防護システム**:
- Relikt ERA: KE +50mm RHA相当、CE +200mm RHA相当
- Arena-M APS: ATGM/RPG 70-80%迎撃率

**副武装**:
- PKTM 7.62mm同軸機関銃
- NSVT/Kord 12.7mm対空機関銃

---

### 1.2 T-80BVM

**主砲**: 2A46M-4 125mm滑腔砲

| 弾種 | 貫徹力 (mm RHA) | ゲーム値 |
|------|-----------------|---------|
| 3BM60 Svinets-2 APFSDS | 650-740mm @ 2km | 130-140 |
| 3BM59 Svinets-1 APFSDS | 600-650mm @ 2km | 120-130 |
| 3BM42 Mango APFSDS | 500-520mm @ 2km | 100-105 |

**砲発射式ATGM**: 9M119M Refleks
- 貫徹力: 700-900mm
- ゲーム値: pen_ce = 140-180

**防護システム**:
- Relikt ERA

---

### 1.3 T-72B3/T-72B3M (Obr. 2016)

**主砲**: 2A46M-5 125mm滑腔砲

| 弾種 | 貫徹力 (mm RHA) | ゲーム値 |
|------|-----------------|---------|
| 3BM60 Svinets-2 APFSDS | 650-740mm @ 2km | 130-140 |
| 3BM44 Mango APFSDS | 500-520mm @ 2km | 100-105 |
| 3BM42 Mango (旧型) | 450-470mm @ 2km | 90-95 |

**砲発射式ATGM**: 9M119 Svir/Refleks
- 射程: 75-4000m (Svir) / 75-5000m (Refleks)
- 貫徹力: 700-900mm
- ゲーム値: pen_ce = 140-180

**防護システム**:
- Kontakt-5 ERA (T-72B3): KE +150-200mm相当
- Relikt ERA (T-72B3M側面): KE +300-400mm相当

---

### 1.4 T-14 アルマータ (Armata) ※参考

**主砲**: 2A82-1M 125mm滑腔砲

| 弾種 | 貫徹力 (mm RHA) | ゲーム値 |
|------|-----------------|---------|
| 3BM69 Vacuum-1 APFSDS | 900-1000mm @ 2km | 180-200 |
| 3BM70 Vacuum-2 APFSDS (DU) | 1000mm+ | 200+ |

**砲発射式ATGM**: 9M119M1 Refleks-M
- 射程: 5000m+
- 貫徹力: 900mm+

**防護システム**:
- Malachit ERA
- Afghanit APS (ハードキル)

※T-14は2026年時点で限定配備のため参考値

---

## 2. 歩兵戦闘車 (IFV)

### 2.1 BMP-3

**主砲**: 2A70 100mm低圧砲 + 2A72 30mm機関砲（同軸）

| 武装 | 弾種 | 貫徹力 | ゲーム値 |
|------|------|--------|---------|
| 2A70 100mm | 3UOF17 HE-FRAG | - | - |
| 2A70 100mm | 3UBK10-3 HEAT | 500mm | pen_ce = 100 |
| 2A72 30mm | 3UBR8 APDS | 25mm @ 1.5km (60°) | pen_ke = 16-18 |
| 2A72 30mm | 3UOR6 HEI-T | - | - |

**ATGM**: 9M117 Bastion（砲発射式）
- 射程: 100-4000m
- 貫徹力: 550mm (タンデムHEAT)
- ゲーム値: pen_ce = 110

**副武装**:
- PKT 7.62mm同軸機関銃 ×3

---

### 2.2 BMP-3M ドラグーン

**主砲**: 2A70 100mm + 2A72 30mm

**ATGM**: 9M117M1 Arkan
- 射程: 100-5500m
- 貫徹力: 750mm
- ゲーム値: pen_ce = 150

**防護システム**:
- ERA装備

---

### 2.3 BMP-2

**主砲**: 2A42 30mm機関砲

| 弾種 | 貫徹力 (mm RHA) | ゲーム値 |
|------|-----------------|---------|
| 3UBR6 APBC-T | 18mm @ 1.5km | pen_ke = 4-6 |
| 3UBR8 APDS | 25mm @ 1.5km (60°) | pen_ke = 14-16 |
| 3UOR6 HEI-T | - | - |

**ATGM**: 9M113 Konkurs / 9M113M Konkurs-M
- 射程: 75-4000m
- 貫徹力: 600mm (9M113) / 750-800mm (9M113M タンデム)
- ゲーム値: pen_ce = 120 (9M113) / 150-160 (9M113M)

**副武装**:
- PKT 7.62mm同軸機関銃

---

### 2.4 BRM-3K リース

**主砲**: 2A72 30mm機関砲

偵察車両、BMP-3ベース。高性能センサー搭載。

---

## 3. 装甲兵員輸送車 (APC/IFV)

### 3.1 BTR-82A

**主砲**: 2A72 30mm機関砲

| 弾種 | 貫徹力 | ゲーム値 |
|------|--------|---------|
| 3UBR6 APBC-T | 18mm @ 1.5km | pen_ke = 4-6 |
| 3UBR8 APDS | 25mm @ 1.5km | pen_ke = 14-16 |

**副武装**:
- PKTM 7.62mm同軸機関銃

---

### 3.2 BTR-80

**主砲**: KPVT 14.5mm重機関銃

| 弾種 | 貫徹力 | ゲーム値 |
|------|--------|---------|
| B-32 API | 32mm @ 500m | pen_ke = 6-8 |
| BS-41 APIH | 20mm @ 100m | pen_ke = 4-5 |

**副武装**:
- PKT 7.62mm同軸機関銃

---

## 4. 対戦車ミサイル (ATGM)

### 4.1 9M133 コルネット (Kornet)

ロシア軍最新の対戦車ミサイル。レーザービームライディング誘導。

| バリアント | 射程 | 貫徹力 (ERA後) | ゲーム値 |
|-----------|------|----------------|---------|
| 9M133 Kornet | 100-5500m | 1000-1200mm | pen_ce = 200-240 |
| 9M133-1 Kornet-E | 100-5500m | 1200mm | pen_ce = 240 |
| 9M133M-2 Kornet-EM | 150-8000m | 1300mm | pen_ce = 260 |

**特徴**:
- タンデムHEAT弾頭（ERA無効化）
- SACLOS レーザービームライディング誘導
- 対建造物用サーモバリック弾頭オプション

---

### 4.2 9M119 スヴィール/レフレクス

砲発射式ATGM。125mm砲から発射。

| バリアント | 射程 | 貫徹力 | ゲーム値 |
|-----------|------|--------|---------|
| 9M119 Svir | 75-4000m | 700mm | pen_ce = 140 |
| 9M119M Refleks | 75-5000m | 900mm | pen_ce = 180 |
| 9M119M1 Refleks-M | 75-5000m+ | 900mm+ | pen_ce = 180+ |

---

### 4.3 9M113 コンクルス (Konkurs)

BMP-2等に搭載されるATGM。

| バリアント | 射程 | 貫徹力 | ゲーム値 |
|-----------|------|--------|---------|
| 9M113 | 75-4000m | 600mm | pen_ce = 120 |
| 9M113M (タンデム) | 75-4000m | 800mm (ERA後) | pen_ce = 160 |

---

### 4.4 9M117 バスティオン

BMP-3の100mm砲から発射される砲発射式ATGM。

| バリアント | 射程 | 貫徹力 | ゲーム値 |
|-----------|------|--------|---------|
| 9M117 Bastion | 100-4000m | 550mm | pen_ce = 110 |
| 9M117M1 Arkan | 100-5500m | 750mm | pen_ce = 150 |

---

### 4.5 9M120 アターカ (Ataka)

ヘリコプター搭載型ATGM。Mi-28、Ka-52等に搭載。

| バリアント | 射程 | 貫徹力 (ERA後) | ゲーム値 |
|-----------|------|----------------|---------|
| 9M120 | 400-6000m | 800mm | pen_ce = 160 |
| 9M120M | 400-8000m | 950mm | pen_ce = 190 |

---

## 5. 機関砲

### 5.1 2A42 30mm機関砲

BMP-2、BMD-2等に搭載。

| 項目 | 仕様 |
|------|------|
| 口径 | 30×165mm |
| 発射速度 | 200-300 rpm (低速) / 550-800 rpm (高速) |
| 有効射程 | 1500m (装甲目標) / 4000m (ソフトターゲット) |
| 初速 | 960-970 m/s (APBC) / 1120 m/s (APDS) |

---

### 5.2 2A72 30mm機関砲

BMP-3、BTR-82A等に搭載。2A42より軽量・シンプル。

| 項目 | 仕様 |
|------|------|
| 口径 | 30×165mm |
| 発射速度 | 300-330 rpm |
| 有効射程 | 1500m (装甲目標) / 4000m (ソフトターゲット) |
| 重量 | 84 kg (2A42より軽量) |

---

### 5.3 KPVT 14.5mm重機関銃

BTR-80、BRDM-2等に搭載。

| 項目 | 仕様 |
|------|------|
| 口径 | 14.5×114mm |
| 発射速度 | 550-600 rpm |
| 有効射程 | 2000m (地上) / 1500m (対空) |
| 貫徹力 | 32mm @ 500m (B-32 API) |
| ゲーム値 | pen_ke = 6-8 |

---

## 6. 機関銃

### 6.1 PKT/PKTM 7.62mm同軸機関銃

ほぼ全てのロシア戦闘車両に搭載。

| 項目 | 仕様 |
|------|------|
| 口径 | 7.62×54mmR |
| 発射速度 | 700-800 rpm |
| 有効射程 | 1000-1500m |
| 初速 | 855 m/s |

---

### 6.2 NSVT/Kord 12.7mm重機関銃

戦車等の対空機関銃として搭載。

| 項目 | 仕様 |
|------|------|
| 口径 | 12.7×108mm |
| 発射速度 | 650-750 rpm (Kord) / 700-800 rpm (NSV) |
| 有効射程 | 1500-2000m |
| 貫徹力 | 20mm @ 100m (B-32 API) |
| ゲーム値 | pen_ke = 4-5 |

---

## 7. 自動擲弾銃

### 7.1 AGS-17 プラーミャ / AGS-30 アトラント

| 項目 | AGS-17 | AGS-30 |
|------|--------|--------|
| 口径 | 30×29mm | 30×29mm |
| 発射速度 | 350-400 rpm | 400 rpm |
| 有効射程 | 1700m | 2100m |
| 弾頭 | VOG-17M HE-FRAG | GPD-30 HE-FRAG |
| 殺傷半径 | 7m | 7m |
| 貫徹力 | 5mm未満 | 5mm未満 |

---

## 8. 自走砲

### 8.1 2S19 ムスタ-S

| 項目 | 仕様 |
|------|------|
| 口径 | 152mm |
| 射程 | 24.7km (通常) / 29km (BB弾) / 36km (RAP) |
| 発射速度 | 8発/分 |

---

### 8.2 2S35 コアリツィヤ-SV

| 項目 | 仕様 |
|------|------|
| 口径 | 152mm |
| 射程 | 40km (通常) / 80km (誘導弾) |
| 発射速度 | 16発/分 |

---

## 9. ゲームパラメータ変換表

### 9.1 戦車砲APFSDS

| 弾種 | 貫徹力 (mm) | ゲーム pen_ke |
|------|-------------|---------------|
| 3BM69 Vacuum-1 | 1000 | 200 |
| 3BM60 Svinets-2 | 700 | 140 |
| 3BM59 Svinets-1 | 650 | 130 |
| 3BM44/42 Mango | 500 | 100 |

### 9.2 ATGM

| ミサイル | 貫徹力 (mm) | ゲーム pen_ce |
|----------|-------------|---------------|
| 9M133M-2 Kornet-EM | 1300 | 260 |
| 9M133 Kornet | 1200 | 240 |
| 9M119M Refleks | 900 | 180 |
| 9M117M1 Arkan | 750 | 150 |
| 9M113M Konkurs-M | 800 | 160 |
| 9M113 Konkurs | 600 | 120 |

### 9.3 機関砲

| 武装 | 弾種 | 貫徹力 (mm) | ゲーム pen_ke |
|------|------|-------------|---------------|
| 2A42/2A72 30mm | 3UBR8 APDS | 60-70mm @ 1km | 12-14 |
| 2A42/2A72 30mm | 3UBR6 APBC | 18mm @ 1.5km | 4-6 |
| KPVT 14.5mm | B-32 API | 32mm @ 500m | 6-8 |

### 9.4 機関銃

| 武装 | ゲーム pen_ke |
|------|---------------|
| Kord 12.7mm | 4-5 |
| NSVT 12.7mm | 4-5 |
| PKT/PKTM 7.62mm | 0 (SMALL_ARMS) |

---

## 10. 実装武器ID

| 武器ID | 説明 | 搭載車両 |
|--------|------|----------|
| CW_TANK_KE_125_RUS | 125mm 2A46M (3BM60) | T-90M, T-80BVM |
| CW_TANK_KE_125_MANGO | 125mm 2A46 (3BM42) | T-72B3, T-90A |
| CW_AUTOCANNON_30_RUS | 30mm 2A42/2A72 | BMP-2, BTR-82A |
| CW_AUTOCANNON_100_RUS | 100mm 2A70 | BMP-3 |
| CW_ATGM_KORNET | 9M133 Kornet | 歩兵ATGM |
| CW_ATGM_REFLEKS | 9M119M Refleks | T-90M, T-80BVM |
| CW_ATGM_KONKURS | 9M113M Konkurs-M | BMP-2 |
| CW_ATGM_BASTION | 9M117 Bastion | BMP-3 |
| CW_HMG_KPVT | KPVT 14.5mm | BTR-80, BRDM-2 |
| CW_PKT_COAX | PKT 7.62mm | 全戦闘車両 |
| CW_KORD_AA | Kord 12.7mm | T-90M, T-80BVM |

---

## 参考文献

- [125 mm smoothbore ammunition - Wikipedia](https://en.wikipedia.org/wiki/125_mm_smoothbore_ammunition)
- [2A46 125 mm gun - Wikipedia](https://en.wikipedia.org/wiki/2A46_125_mm_gun)
- [T-14 Armata - Wikipedia](https://en.wikipedia.org/wiki/T-14_Armata)
- [9M133 Kornet - Wikipedia](https://en.wikipedia.org/wiki/9M133_Kornet)
- [9M119 Svir/Refleks - Wikipedia](https://en.wikipedia.org/wiki/9M119_Svir/Refleks)
- [9M113 Konkurs - Wikipedia](https://en.wikipedia.org/wiki/9M113_Konkurs)
- [Shipunov 2A42 - Wikipedia](https://en.wikipedia.org/wiki/Shipunov_2A42)
- [BMP-3 - Wikipedia](https://en.wikipedia.org/wiki/BMP-3)
- [Kontakt-5 - Wikipedia](https://en.wikipedia.org/wiki/Kontakt-5)
- [Reactive armour - Wikipedia](https://en.wikipedia.org/wiki/Reactive_armour)
- [PK machine gun - Wikipedia](https://en.wikipedia.org/wiki/PK_machine_gun)
- [Kord machine gun - Wikipedia](https://en.wikipedia.org/wiki/Kord_machine_gun)
- [ODIN - 2A72 Russian 30mm Autocannon](https://odin.tradoc.army.mil/WEG/Asset/2A72_Russian_30mm_Autocannon)
- [ODIN - 9M133 Kornet](https://odin.tradoc.army.mil/WEG/Asset/9M133_Kornet_)
