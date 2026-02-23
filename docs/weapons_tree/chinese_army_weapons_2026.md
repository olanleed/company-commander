# Chinese Army Weapons System Documentation 2026

## Overview

This document defines the concrete weapon implementations for Chinese People's Liberation Army (PLA) Ground Force vehicles. All penetration values use the standard conversion scale: **100 = 500mm RHA** (pen_ke/pen_ce value = RHA mm / 5).

## Sources

- [Type 99 tank - Wikipedia](https://en.wikipedia.org/wiki/Type_99_tank)
- [ZTZ-99A Tank - Vermilion China](https://www.vermilionchina.com/p/pla-armor-the-ztz-99a-tank)
- [China DTC10-125 Tank Ammo - Tech ARP](https://www.techarp.com/military/china-dtc10-125-anti-tank/)
- [Type 15 tank - Wikipedia](https://en.wikipedia.org/wiki/Type_15_tank)
- [ZBD-04 - Wikipedia](https://en.wikipedia.org/wiki/ZBD-04)
- [HJ-8 - Wikipedia](https://en.wikipedia.org/wiki/HJ-8)
- [HJ-9 - Wikipedia](https://en.wikipedia.org/wiki/HJ-9)
- [HJ-10 - Wikipedia](https://en.wikipedia.org/wiki/HJ-10)
- [HJ-12 - Wikipedia](https://en.wikipedia.org/wiki/HJ-12)
- [PGZ-09 - Wikipedia](https://en.wikipedia.org/wiki/PGZ-09)
- [QJZ-89 Heavy Machine Gun - TRADOC](https://odin.tradoc.army.mil/WEG/Asset/QJZ-89_(Type_89)_Chinese_12.7mm_Heavy_Machine_Gun)

---

## 1. Tank Main Guns (125mm)

### CW_TANK_KE_125_CHN - 125mm ZPT-98 (DTC10-125 APFSDS)

**Platform**: Type 99A (ZTZ-99A)
**Ammunition**: DTC10-125 APFSDS (Tungsten alloy, self-sharpening)
**Muzzle Velocity**: 1780 m/s

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Tank gun APFSDS |
| Fire Model | DISCRETE | Single shot |
| Threat Class | AT | Anti-armor |
| Preferred Target | ARMOR | Primary anti-armor role |
| Min Range | 0m | |
| Max Range | 4000m | |
| Range Bands | [500, 2000] | NEAR < 500m < MID < 2000m < FAR |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 192 | 960mm @ 1000m | TRADOC / Norinco internal |
| MID | 160 | 800mm @ 2000m | Self-sharpening tungsten |
| FAR | 130 | 650mm @ 3000m | Estimated |

**Notes**:
- DTC10-125 uses self-sharpening tungsten carbide core
- Depleted uranium variant (DU) claims 960mm @ 2000m (pen_ke = 192 at MID)
- Highest penetration among 125mm systems worldwide

---

### CW_TANK_KE_125_CHN_STD - 125mm ZPT-98 (DTW-125 Type II)

**Platform**: Type 99 (ZTZ-99), Type 96A (ZTZ-96A)
**Ammunition**: DTW-125 Type II APFSDS (Standard tungsten)
**Muzzle Velocity**: 1700 m/s (estimated)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Tank gun APFSDS |
| Fire Model | DISCRETE | Single shot |
| Threat Class | AT | Anti-armor |
| Preferred Target | ARMOR | |
| Min Range | 0m | |
| Max Range | 4000m | |
| Range Bands | [500, 2000] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 150 | 750mm @ 500m | Estimated |
| MID | 140 | 700mm @ 1000m | TRADOC |
| FAR | 115 | 575mm @ 2000m | Estimated |

---

### CW_TANK_KE_125_CHN_OLD - 125mm ZPT-96 (DTW-125)

**Platform**: Type 96 (ZTZ-96)
**Ammunition**: DTW-125 APFSDS (First generation)
**Muzzle Velocity**: 1650 m/s (estimated)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Tank gun APFSDS |
| Fire Model | DISCRETE | Single shot |
| Threat Class | AT | Anti-armor |
| Preferred Target | ARMOR | |
| Min Range | 0m | |
| Max Range | 3500m | |
| Range Bands | [500, 2000] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 130 | 650mm @ 500m | Estimated |
| MID | 110 | 550mm @ 1000m | Early generation |
| FAR | 90 | 450mm @ 2000m | Estimated |

---

## 2. Light Tank Main Guns (105mm)

### CW_TANK_KE_105_CHN - 105mm ZPL-151 Rifled Gun

**Platform**: Type 15 (ZTQ-15) Light Tank
**Ammunition**: APFSDS (Tungsten alloy)
**Muzzle Velocity**: ~1500 m/s

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Rifled tank gun |
| Fire Model | DISCRETE | Single shot |
| Threat Class | AT | Anti-armor |
| Preferred Target | ARMOR | |
| Min Range | 0m | |
| Max Range | 3000m | |
| Range Bands | [400, 1500] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 110 | 550mm @ 500m | Estimated |
| MID | 100 | 500mm @ 2000m | Wikipedia |
| FAR | 85 | 425mm @ 3000m | Estimated |

**Notes**:
- New generation 105mm APFSDS with tungsten alloy core
- Can penetrate T-90S frontal hull armor at combat ranges
- Also fires gun-launched ATGM (GP105) with 700mm penetration

---

### CW_TANK_KE_105_CHN_OLD - 105mm Type 83 Rifled Gun

**Platform**: Type 63A, ZTL-11
**Ammunition**: Standard 105mm APFSDS (NATO compatible)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Rifled tank gun |
| Fire Model | DISCRETE | Single shot |
| Threat Class | AT | Anti-armor |
| Preferred Target | ARMOR | |
| Min Range | 0m | |
| Max Range | 2500m | |
| Range Bands | [400, 1500] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 90 | 450mm @ 500m | |
| MID | 80 | 400mm @ 1000m | |
| FAR | 65 | 325mm @ 2000m | |

---

## 3. Autocannons

### CW_AUTOCANNON_30_CHN - 30mm ZPT-99 Autocannon

**Platform**: ZBD-04A, ZBD-09, ZBD-03
**Ammunition**: DTC10-30 APFSDS, DTC041A-30 AP, DTB02-30 HE
**Rate of Fire**: 300 rpm

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Autocannon |
| Fire Model | CONTINUOUS | Burst fire |
| Threat Class | AUTOCANNON | |
| Preferred Target | ANY | Versatile |
| Min Range | 0m | |
| Max Range | 2000m | |
| Range Bands | [300, 1000] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 14 | 70mm @ 500m | APFSDS rounds |
| MID | 12 | 60mm @ 1000m | |
| FAR | 8 | 40mm @ 2000m | |

**Notes**:
- Chinese derivative of Soviet 2A72
- Licensed in early 1990s
- APFSDS variants significantly increase penetration

---

### CW_AUTOCANNON_35_CHN - 35mm Type 90 (PG99) Twin Autocannon

**Platform**: PGZ-09 SPAAG
**Ammunition**: HEI, AP, Tracer
**Rate of Fire**: 550 rpm per barrel (1100 rpm combined)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | KINETIC | Twin autocannon |
| Fire Model | CONTINUOUS | High ROF |
| Threat Class | AUTOCANNON | |
| Preferred Target | ANY | AA and ground |
| Min Range | 0m | |
| Max Range | 4000m | |
| Range Bands | [500, 2000] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 18 | 90mm | Based on Oerlikon KDA |
| MID | 14 | 70mm | |
| FAR | 10 | 50mm | |

**Notes**:
- Copy of Swiss GDF-002 with Oerlikon KDA autocannon
- Primary anti-aircraft role with secondary ground capability

---

### CW_AUTOCANNON_100_CHN - 100mm Gun/Missile Launcher

**Platform**: ZBD-04
**Ammunition**: HE-FRAG, ATGM (3UBK10 copy)
**Rate of Fire**: 10 rpm (HE-FRAG)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Gun-launcher |
| Fire Model | DISCRETE | Semi-automatic |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 100m | |
| Max Range | 4000m | |
| Range Bands | [500, 2000] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 120 | 600mm | 3UBK10 ATGM capability |
| MID | 120 | 600mm | Tandem warhead |
| FAR | 100 | 500mm | HE-FRAG reduced |

**Notes**:
- Similar to Russian 2A70 system
- Dual-purpose: HE-FRAG for soft targets, ATGM for armor
- 30 rounds capacity

---

## 4. ATGMs (Anti-Tank Guided Missiles)

### CW_ATGM_HJ10 - HJ-10 (Red Arrow-10) / AFT-10

**Platform**: ZBD-04A ATGM Carrier, Type 08 8x8
**Guidance**: Fiber-optic / Imaging IR (Fire-and-forget)
**Warhead**: Tandem HEAT

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Tandem HEAT |
| Fire Model | DISCRETE | Missile |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 3000m | Long minimum range |
| Max Range | 10000m | Very long range |
| Range Bands | [4000, 7000] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 280 | 1400mm | Post-ERA |
| MID | 280 | 1400mm | Consistent |
| FAR | 280 | 1400mm | Consistent |

**Notes**:
- Fire-and-forget with IR imaging seeker
- Fiber-optic guidance for NLOS capability
- Top-attack mode available
- Heaviest Chinese ATGM at 43kg
- Cruise speed 150 m/s, terminal 230 m/s

---

### CW_ATGM_HJ9 - HJ-9 (Red Arrow-9)

**Platform**: Vehicle-mounted, tripod
**Guidance**: SACLOS laser beam-riding
**Warhead**: Tandem HEAT

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Tandem HEAT |
| Fire Model | DISCRETE | Missile |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 100m | |
| Max Range | 5500m | |
| Range Bands | [1000, 3000] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 240 | 1200mm | Wikipedia |
| MID | 240 | 1200mm | |
| FAR | 240 | 1200mm | |

**Notes**:
- Third-generation ATGM
- 152mm diameter, 37kg launch container
- Comparable to Russian Kornet

---

### CW_ATGM_HJ8E - HJ-8E (Red Arrow-8E)

**Platform**: ZBD-04A, ZBD-09, vehicle/tripod mounted
**Guidance**: SACLOS wire-guided
**Warhead**: Tandem HEAT (anti-ERA)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Tandem HEAT |
| Fire Model | DISCRETE | Missile |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 100m | |
| Max Range | 4000m | |
| Range Bands | [500, 2000] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 200 | 1000mm | Post-ERA |
| MID | 200 | 1000mm | Wikipedia |
| FAR | 200 | 1000mm | |

**Notes**:
- Second-generation ATGM, improved version
- Tandem warhead defeats ERA
- Lightweight at 24.5kg total system
- HJ-8L variant reduces weight to 22.5kg

---

### CW_ATGM_HJ73 - HJ-73 (Red Arrow-73)

**Platform**: ZBD-04A (legacy), ZBD-09, ZBD-03
**Guidance**: SACLOS wire-guided
**Warhead**: Single HEAT

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Single HEAT |
| Fire Model | DISCRETE | Missile |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 100m | |
| Max Range | 3000m | |
| Range Bands | [500, 1500] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 85 | 425mm | vehicles_chn.json |
| MID | 85 | 425mm | Older design |
| FAR | 85 | 425mm | |

**Notes**:
- First-generation Chinese ATGM (AT-3 Sagger copy)
- Still in widespread use on older IFVs
- Limited effectiveness against modern armor

---

### CW_ATGM_GP105 - GP105 Gun-Launched ATGM

**Platform**: Type 15 (via 105mm gun), ZTL-11
**Guidance**: Laser beam-riding
**Warhead**: HEAT

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SHAPED_CHARGE | Gun-launched |
| Fire Model | DISCRETE | Missile |
| Threat Class | AT | |
| Preferred Target | ARMOR | |
| Min Range | 500m | |
| Max Range | 5200m | |
| Range Bands | [1000, 3000] | |

**Penetration (CE)**:
| Range Band | pen_ce | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 140 | 700mm | Wikipedia |
| MID | 140 | 700mm | |
| FAR | 140 | 700mm | |

**Notes**:
- Derived from Russian 9K116 Bastion (AT-10 Stabber)
- Fired from 105mm rifled gun
- Extends engagement range beyond standard ammunition

---

## 5. Machine Guns

### CW_QJZ89_AA - 12.7mm QJZ-89 (Type 89 HMG)

**Platform**: Type 99A, Type 99, Type 96A (AA mount)
**Ammunition**: 12.7x108mm (API, APIT, APDS)
**Rate of Fire**: 450-600 rpm

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SMALL_ARMS | Heavy machine gun |
| Fire Model | CONTINUOUS | |
| Threat Class | SMALL_ARMS | |
| Preferred Target | SOFT | |
| Min Range | 0m | |
| Max Range | 1800m | Effective range |
| Range Bands | [300, 800] | |

**Penetration (KE)**:
| Range Band | pen_ke | RHA Equivalent | Source |
|------------|--------|----------------|--------|
| NEAR | 5 | 25mm @ 100m | Type 54 API |
| MID | 4 | 20mm @ 500m | TRADOC |
| FAR | 3 | 15mm @ 1000m | |

**Notes**:
- Lightest 12.7mm HMG at 26kg (gun + tripod)
- Lighter than Russian Kord (32kg) or US M2 (38kg)
- APDS variants available for improved penetration

---

### CW_TYPE86_COAX - 7.62mm Type 86 Coaxial MG

**Platform**: Type 99A, Type 99, Type 96A, ZBD-04A, ZBD-09
**Ammunition**: 7.62x54mmR
**Rate of Fire**: 650-750 rpm

| Parameter | Value | Notes |
|-----------|-------|-------|
| Mechanism | SMALL_ARMS | Coaxial machine gun |
| Fire Model | CONTINUOUS | |
| Threat Class | SMALL_ARMS | |
| Preferred Target | SOFT | |
| Min Range | 0m | |
| Max Range | 1000m | |
| Range Bands | [200, 500] | |

**Lethality**:
| Range Band | Lethality (SOFT) | Lethality (LIGHT) |
|------------|------------------|-------------------|
| NEAR | 50 | 10 |
| MID | 40 | 5 |
| FAR | 25 | 0 |

**Notes**:
- Modified Type 80 (PKM derivative)
- Captured from Vietnamese forces during Sino-Vietnamese War
- Standard coaxial for PLA armored vehicles
- 2000 rounds typical capacity

---

## 6. Weapon Comparison Summary

### Tank Gun Penetration Hierarchy (MID range, pen_ke)

| Weapon | pen_ke | RHA (mm) | Platform |
|--------|--------|----------|----------|
| CW_TANK_KE_125_CHN (DTC10) | 160 | 800mm | Type 99A |
| CW_TANK_KE_125_CHN_STD | 140 | 700mm | Type 99, 96A |
| CW_TANK_KE_125_CHN_OLD | 110 | 550mm | Type 96 |
| CW_TANK_KE_105_CHN | 100 | 500mm | Type 15 |
| CW_TANK_KE_105_CHN_OLD | 80 | 400mm | Type 63A, ZTL-11 |

### ATGM Penetration Hierarchy (MID range, pen_ce)

| Weapon | pen_ce | RHA (mm) | Platform |
|--------|--------|----------|----------|
| CW_ATGM_HJ10 | 280 | 1400mm | AFT-10 Carrier |
| CW_ATGM_HJ9 | 240 | 1200mm | Vehicle/tripod |
| CW_ATGM_HJ8E | 200 | 1000mm | ZBD-04A, ZBD-09 |
| CW_ATGM_GP105 | 140 | 700mm | Type 15, ZTL-11 |
| CW_ATGM_HJ73 | 85 | 425mm | Legacy systems |

### International Comparison

| Chinese | vs US | vs Russian | Notes |
|---------|-------|------------|-------|
| DTC10-125 (160) | M829A4 (150) | 3BM60 (140) | China leads at MID |
| HJ-10 (280) | Javelin (180) | Kornet (240) | Highest ATGM pen |
| ZPT-99 30mm (12) | Bushmaster 25mm (10) | 2A42 30mm (12) | Comparable |

---

## 7. Vehicle-Weapon Assignments

| Vehicle | Main Gun | ATGM | Secondary |
|---------|----------|------|-----------|
| Type 99A | CW_TANK_KE_125_CHN | - | CW_TYPE86_COAX, CW_QJZ89_AA |
| Type 99 | CW_TANK_KE_125_CHN_STD | - | CW_TYPE86_COAX, CW_QJZ89_AA |
| Type 96A | CW_TANK_KE_125_CHN_STD | - | CW_TYPE86_COAX, CW_QJZ89_AA |
| Type 96 | CW_TANK_KE_125_CHN_OLD | - | CW_TYPE86_COAX, CW_QJZ89_AA |
| Type 15 | CW_TANK_KE_105_CHN | CW_ATGM_GP105 | CW_TYPE86_COAX, CW_QJZ89_AA |
| ZBD-04A | CW_AUTOCANNON_30_CHN | CW_ATGM_HJ8E | CW_TYPE86_COAX |
| ZBD-04 | CW_AUTOCANNON_100_CHN | - | CW_AUTOCANNON_30_CHN, CW_TYPE86_COAX |
| ZBD-09 | CW_AUTOCANNON_30_CHN | CW_ATGM_HJ73 | CW_TYPE86_COAX |
| ZBD-03 | CW_AUTOCANNON_30_CHN | CW_ATGM_HJ73 | CW_TYPE86_COAX |
| ZBL-08 | CW_QJZ89_AA | - | - |
| ZTL-11 | CW_TANK_KE_105_CHN_OLD | CW_ATGM_GP105 | CW_TYPE86_COAX |
| Type 63A | CW_TANK_KE_105_CHN_OLD | - | CW_TYPE86_COAX |
| CSK-181 | CW_QJZ89_AA | - | - |
| PGZ-09 | CW_AUTOCANNON_35_CHN | - | - |

---

## 8. Implementation Notes

### Weapon ID Convention
- `CW_` prefix = Concrete Weapon
- `_CHN` suffix = Chinese Army specific
- `_STD` = Standard version
- `_OLD` = Older/legacy version

### Penetration Conversion
- pen_ke/pen_ce value = RHA mm / 5
- Example: 800mm RHA = pen_ke 160

### Total Chinese Army Weapons: 13
1. CW_TANK_KE_125_CHN (DTC10-125)
2. CW_TANK_KE_125_CHN_STD (DTW-125 Type II)
3. CW_TANK_KE_125_CHN_OLD (DTW-125)
4. CW_TANK_KE_105_CHN (ZPL-151)
5. CW_TANK_KE_105_CHN_OLD (Type 83)
6. CW_AUTOCANNON_30_CHN (ZPT-99)
7. CW_AUTOCANNON_35_CHN (Type 90/PG99)
8. CW_AUTOCANNON_100_CHN (100mm gun-launcher)
9. CW_ATGM_HJ10 (Red Arrow-10)
10. CW_ATGM_HJ9 (Red Arrow-9)
11. CW_ATGM_HJ8E (Red Arrow-8E)
12. CW_ATGM_HJ73 (Red Arrow-73)
13. CW_ATGM_GP105 (Gun-launched)
14. CW_QJZ89_AA (12.7mm HMG)
15. CW_TYPE86_COAX (7.62mm coaxial)
