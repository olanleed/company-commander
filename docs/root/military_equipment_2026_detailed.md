# Military Equipment Knowledge Root (2026)

このドキュメントは、軍事装備ドメイン知識の「親ツリー」です。  
`docs/vehicles_tree` と `docs/weapons_tree` は本ドキュメント配下のサブツリーとして運用します。

## 子ツリー（運用対象）

### vehicles_tree
- [military_vehicles_2026_detailed.md](../vehicles_tree/military_vehicles_2026_detailed.md)
- [armour_systems_2026_mainstream.md](../vehicles_tree/armour_systems_2026_mainstream.md)

### weapons_tree
- [tank_guns_and_ammunition_2026_mainstream.md](../weapons_tree/tank_guns_and_ammunition_2026_mainstream.md)
- [autocannons_2026_mainstream.md](../weapons_tree/autocannons_2026_mainstream.md)
- [mortars_2026_mainstream.md](../weapons_tree/mortars_2026_mainstream.md)
- [howitzers_2026_mainstream.md](../weapons_tree/howitzers_2026_mainstream.md)
- [rockets_and_rocket_artillery_2026_mainstream.md](../weapons_tree/rockets_and_rocket_artillery_2026_mainstream.md)
- [man_portable_anti_tank_weapons_2026_mainstream.md](../weapons_tree/man_portable_anti_tank_weapons_2026_mainstream.md)
- [missiles_guidance_tree.md](../weapons_tree/missiles_guidance_tree.md)
- [us_army_weapons_2026.md](../weapons_tree/us_army_weapons_2026.md)
- [russian_army_weapons_2026.md](../weapons_tree/russian_army_weapons_2026.md)
- [chinese_army_weapons_2026.md](../weapons_tree/chinese_army_weapons_2026.md)
- [jgsdf_weapons_2026.md](../weapons_tree/jgsdf_weapons_2026.md)

## ルート分類（taxonomy）

```
military_equipment_2026_detailed
├── 0_個人装備（individual_equipment）
│   ├── 小火器（small_arms）
│   │   ├── 拳銃
│   │   ├── 小銃（アサルトライフル/バトルライフル）
│   │   ├── 機関銃（分隊支援火器/汎用機関銃）
│   │   └── 狙撃銃（DMR/スナイパー）
│   ├── 携行火器（man_portable_weapons）
│   │   ├── 手榴弾（破片/閃光/発煙）
│   │   ├── 携帯対戦車（ロケット/無反動砲/ATGM）
│   │   ├── 携帯対空（MANPADS：限定的に）
│   │   └── 爆薬・破壊器材（ブリーチング等）
│   ├── 防護（personal_protection）
│   │   ├── ヘルメット（防弾/バンプ）
│   │   ├── 防弾ベスト/プレートキャリア
│   │   ├── NBC/CBRN防護（マスク/スーツ）
│   │   └── 眼・聴覚保護（ゴーグル/イヤプロ）
│   ├── 兵装付属品（weapon_accessories）
│   │   ├── 照準器（ドット/LPVO/スコープ）
│   │   ├── NVG/サーマル（照準・観測）
│   │   ├── LAM/ライト（レーザー/白色/IR）
│   │   └── サプレッサー（用途限定）
│   ├── 通信・測位（comms_navigation）
│   │   ├── 個人無線
│   │   ├── 位置共有端末（BFT系概念）
│   │   └── 測位（GNSS/慣性補助の端末）
│   └── 生活・携行品（field_gear）
│       ├── 被服（迷彩服/防寒/耐火）
│       ├── 携行装具（チェストリグ/バックパック）
│       ├── 医療（IFAK）
│       └── 電源（バッテリー/充電系）
├── 1_地上プラットフォーム（land_platforms）
│   ├── 軍用車両（military_vehicles）
│   │   ├── 戦闘車両（MBT/IFV/APC/偵察/対戦車/防空）
│   │   ├── 火力支援（自走砲/MLRS/迫撃砲キャリア）
│   │   ├── 工兵（架橋/地雷処理/装甲ブルドーザ）
│   │   ├── 兵站（輸送/給油/弾薬/整備回収/衛生）
│   │   └── 無人地上車両（UGV：偵察/支援）
│   ├── 砲兵・地上火力（ground_fires）
│   │   ├── 牽引榴弾砲
│   │   ├── 自走榴弾砲
│   │   ├── 迫撃砲（60/81/120mm）
│   │   └── ロケット砲（MLRS：誘導ロケット含む）
│   ├── 対空・防空（GBAD）
│   │   ├── SHORAD（砲/ミサイル/複合）
│   │   ├── 中距離SAM（国により）
│   │   └── レーダ/射撃管制（捜索/追尾/対砲迫）
│   ├── 工兵・EOD（engineer_EOD）
│   │   ├── 障害構成（地雷/ワイヤ/障害物）
│   │   ├── 障害処理（ラインチャージ/地雷処理車）
│   │   └── EOD装備（処理ロボ/妨害/探知）
│   └── 指揮統制・情報（C2ISR_land）
│       ├── 指揮所（CP）
│       ├── 通信（中継/衛星/データリンク）
│       ├── ISR（地上センサー/無人機管制）
│       └── 電子戦（EW：探知/妨害/欺瞞）
├── 2_航空プラットフォーム（air_platforms）
│   ├── 有人航空機（manned_aircraft）
│   │   ├── 戦闘機/マルチロール
│   │   ├── 攻撃/CAS
│   │   ├── 輸送機
│   │   ├── ISR（AEW/ELINT/MPA等）
│   │   └── 空中給油
│   ├── 回転翼（rotary_wing）
│   │   ├── 攻撃ヘリ
│   │   ├── 汎用/輸送ヘリ
│   │   └── 偵察/軽攻撃
│   ├── 無人航空機（UAV）
│   │   ├── 小型（分隊/中隊：ISR）
│   │   ├── 中大型（MALE/HALE：ISR/攻撃）
│   │   └── 徘徊弾（loitering munition：別カテゴリでも扱う）
│   └── 航空支援装備（air_support_equipment）
│       ├── 地上支援車両（牽引/給油/電源）
│       ├── 航空用センサー/ポッド（照準/偵察）
│       └── 航空基地防護（対UAS含む）
├── 3_海上プラットフォーム（maritime_platforms）
│   ├── 水上艦（surface_ships）
│   │   ├── 戦闘艦（駆逐/フリゲート/コルベット）
│   │   ├── 揚陸艦
│   │   ├── 哨戒艇
│   │   └── 支援艦（補給/救難/掃海支援）
│   ├── 潜水艦（submarines）
│   │   ├── 攻撃型
│   │   └── 戦略型（保有国のみ）
│   ├── 機雷戦（mine_warfare）
│   │   ├── 掃海艇/掃海支援
│   │   └── UUV/ROV（機雷対処）
│   └── 無人艇（USV/UUV）
│       ├── 監視/哨戒
│       ├── 機雷対処
│       └── 攻撃/囮（用途拡大）
├── 4_兵器（weapons）※「プラットフォーム横断の武器体系」
│   ├── 4-1_誘導兵器（guided_weapons）
│   │   ├── 対戦車（ATGM）
│   │   ├── 防空（SAM/AAM）
│   │   ├── 対艦（AShM）
│   │   ├── 対地（ASM/AGM/LACM）
│   │   ├── 対レーダ（ARM）
│   │   └── 弾道/迎撃（BM/ABM：保有国・用途限定）
│   ├── 4-2_砲弾・弾薬（gun_ammunition）
│   │   ├── 戦車砲弾（120/125/105：APFSDS/HE-MP等）
│   │   ├── 機関砲弾（20–40：APFSDS/ABM等）
│   │   ├── 榴弾砲弾（155/152：HE/誘導/射程延伸）
│   │   └── 迫撃砲弾（60/81/120：HE/誘導/煙幕）
│   ├── 4-3_ロケット（rockets）
│   │   ├── 携行ロケット（対戦車/多目的）
│   │   ├── 航空ロケット（無誘導〜簡易誘導）
│   │   └── MLRSロケット（誘導ロケット含む）
│   ├── 4-4_爆弾（air_dropped_munitions）
│   │   ├── 無誘導爆弾
│   │   ├── 誘導爆弾（GPS/レーザー等）
│   │   └── 滑空爆弾（スタンドオフ）
│   └── 4-5_徘徊弾/ドローン兵器（loitering_and_armed_uas）
│       ├── 徘徊弾（使い捨て攻撃）
│       ├── 改造UAS投下（戦域依存）
│       └── 対UAS迎撃ドローン（用途拡大中）
├── 5_防護・生残性（protection_survivability）
│   ├── 装甲（armour：鋼/複合/ERA/APS）
│   ├── 受動防護（スモーク/デコイ/遮蔽）
│   ├── CBRN防護（車両/個人）
│   ├── 対IED（妨害/探知/底部設計）
│   └── 救難・損害対処（消火/応急修理/回収）
└── 6_支援装備（support_and_enablers）
    ├── センサー（sensors）
    │   ├── EO/IR
    │   ├── レーダ（捜索/追尾/対砲迫）
    │   └── 音響/磁気（用途限定）
    ├── 通信・ネットワーク（communications_networking）
    │   ├── 戦術無線
    │   ├── 衛星通信
    │   └── データリンク/BMS
    ├── 電子戦（electronic_warfare）
    │   ├── 探知（ESM/ELINT）
    │   ├── 妨害（Jamming）
    │   └── 欺瞞（Deception）
    ├── 兵站（logistics_enablers）
    │   ├── 補給（燃料/弾薬/糧食/水）
    │   ├── 整備（工具/部品/野戦修理）
    │   └── 輸送（陸海空）
    └── 教育・訓練（training_simulation）
        ├── シミュレータ
        ├── 訓練弾/模擬
        └── 訓練支援システム（射撃統制・記録等）
```
