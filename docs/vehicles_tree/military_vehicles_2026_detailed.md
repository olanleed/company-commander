```
military_vehicles_2026_detailed
├── 0_地上車両（land_vehicles）
│   ├── 0-1_戦闘車両（combat）
│   │   ├── 主力戦車（MBT）
│   │   │   ├── 役割：突破/対機甲戦の中核
│   │   │   ├── 砲：120mm級（NATO）/125mm級（旧ソ連系）
│   │   │   └── 防護：複合装甲＋（ERA/APSは採用拡大）
│   │   ├── 軽戦車/火力支援車（light_tank / assault_gun）
│   │   │   ├── 砲：105mm級〜120mm級（車重・国で差）
│   │   │   └── 用途：空挺/機動部隊/偵察打撃
│   │   ├── 歩兵戦闘車（IFV）
│   │   │   ├── 兵装：20–40mm機関砲＋ATGM（国により）
│   │   │   ├── 目的：歩兵輸送＋戦闘同伴
│   │   │   └── 形態：履帯/装輪
│   │   ├── 装甲兵員輸送車（APC）
│   │   │   ├── 兵装：RWS/重機関銃/自動擲弾銃が多い
│   │   │   └── 重点：輸送・防護（IFVより火力控えめ）
│   │   ├── 装甲偵察車（recon_vehicle）
│   │   │   ├── センサー：光学/IR/レーダ/通信中継
│   │   │   └── 形態：装輪が多い（戦域で履帯も）
│   │   ├── 対戦車車両（anti_tank_vehicle）
│   │   │   ├── 車載ATGM（発射機搭載）
│   │   │   └── 砲搭載対戦車（軽戦車/突撃砲と重複）
│   │   ├── 自走砲兵（artillery_combat）
│   │   │   ├── 自走榴弾砲（SPH：155mm/152mm）
│   │   │   ├── 自走迫撃砲（SP_mortar：120mm級中心）
│   │   │   └── 多連装ロケット（MLRS：誘導/無誘導ロケット）
│   │   ├── 防空車両（SHORAD/GBAD_vehicle）
│   │   │   ├── 砲型（30–40mm＋ABM等）
│   │   │   ├── ミサイル型（MANPADS車載〜中距離）
│   │   │   └── 複合型（砲＋ミサイル＋捜索/追尾レーダ）
│   │   ├── 工兵戦闘車両（engineer_combat）
│   │   │   ├── 装甲ブルドーザ/地雷処理（MICLIC等含む）
│   │   │   ├── 架橋戦車（AVLB）
│   │   │   └── 障害処理/突破支援（ラインチャージ等）
│   │   └── 無人戦闘/支援車両（UGV_combat_support）
│   │       ├── 遠隔操縦（tele-operated）
│   │       └── 半自律（route-follow / auto-assist）
│   ├── 0-2_戦闘支援・戦闘勤務支援（combat_support / CSS）
│   │   ├── 指揮通信車（C2 / command_post）
│   │   │   ├── 指揮所車（CP）
│   │   │   ├── 通信中継車（relay）
│   │   │   └── 電子戦車（EW：妨害/探知/位置標定）
│   │   ├── ISR/センサー車（ISR_vehicle）
│   │   │   ├── 地上監視レーダ車（GSR）
│   │   │   ├── SIGINT/ELINT車
│   │   │   └── UAV管制/発射回収支援車
│   │   ├── 工兵支援車（engineer_support）
│   │   │   ├── 修理・回収支援（工兵器材搭載）
│   │   │   └── EOD/対IED（処理ロボ・妨害装置搭載）
│   │   ├── 兵站（logistics）
│   │   │   ├── 輸送トラック（cargo）
│   │   │   ├── 燃料給油車（fueler）
│   │   │   ├── 弾薬車（ammo carrier）
│   │   │   └── 水/補給（water/field_supply）
│   │   ├── 整備・回収（maintenance_recovery）
│   │   │   ├── 装甲回収車（ARV）
│   │   │   ├── 野戦整備車（workshop）
│   │   │   └── クレーン/レッカー（重装備搬送）
│   │   ├── 医療（medical）
│   │   │   ├── 装甲救急車（armored_ambulance）
│   │   │   └── 野戦病院車（field_hospital_module）
│   │   ├── 化学・放射線（CBRN）
│   │   │   ├── 偵察車（CBRN recon）
│   │   │   └── 除染車（decon）
│   │   └── 憲兵/治安・警護（MP/security）
│   │       ├── パトロール車（armored_patrol）
│   │       └── 施設警備/車列護衛（convoy_security）
│   ├── 0-3_機動・シャシ分類（mobility / chassis）
│   │   ├── 履帯（tracked）
│   │   │   ├── 強み：不整地機動・搭載重量
│   │   │   └── 弱み：整備負担・路上機動/燃費
│   │   ├── 装輪（wheeled）
│   │   │   ├── 4×4 / 6×6 / 8×8
│   │   │   └── 強み：戦略機動・コスト・整備性
│   │   ├── MRAP系（mine_protected）
│   │   │   └── Vハル等：地雷/IED耐性優先
│   │   └── 特殊機動
│   │       ├── 水陸両用（amphibious）
│   │       ├── 雪上/極地（snow/over-snow）
│   │       └── 高機動バギー（HMTV/buggy：空挺等）
│   └── 0-4_防護レベル（protection）
│       ├── 非装甲（soft-skin）
│       ├── 軽装甲（small_arms/fragment）
│       ├── 中装甲（機関砲の一部まで想定）
│       └── 重装甲（MBT/重IFV：対KE/対HEAT重視）
├── 1_航空車両（air_vehicles）※「車両」扱いでの分類
│   ├── 回転翼（helicopter）
│   │   ├── 攻撃（attack）
│   │   ├── 汎用/輸送（utility/transport）
│   │   └── 偵察/軽攻撃（recon/light_attack）
│   ├── 固定翼（fixed_wing）
│   │   ├── 戦闘機/マルチロール（fighter）
│   │   ├── 攻撃機（strike/CAS）
│   │   ├── 輸送機（transport）
│   │   ├── ISR（AEW/MPA/ELINTなど）
│   │   └── 空中給油（tanker）
│   └── 無人機（UAV）
│       ├── 小型（ISR/徘徊含む）
│       ├── 中大型（MALE/HALE）
│       └── 兵装搭載（UCAV：国・用途で差）
├── 2_海上車両（maritime_vehicles）※「車両」扱いでの分類
│   ├── 水上艦（surface）
│   │   ├── 戦闘艦（destroyer/frigate/corvette）
│   │   ├── 揚陸（amphibious）
│   │   ├── 哨戒（patrol）
│   │   └── 支援（auxiliary：補給/救難/掃海支援）
│   ├── 潜水艦（submarine）
│   │   ├── 攻撃（SSN/SSK）
│   │   └── 戦略（SSBN：保有国のみ）
│   └── 無人艇（USV/UUV）
│       ├── 監視/哨戒
│       ├── 機雷対処
│       └── 攻撃/囮（用途拡大中）
└── 3_横断的な“装備カテゴリ”（vehicle_subsystems）
    ├── 武装搭載
    │   ├── RWS（遠隔武器ステーション）
    │   ├── 砲塔（有人/無人）
    │   └── ミサイルランチャ（対戦車/防空）
    ├── センサー
    │   ├── EO/IR
    │   ├── レーダ（捜索/追尾/対砲迫レーダ等）
    │   └── SIGINT/EW（受信・妨害）
    ├── 防護
    │   ├── 追加装甲（モジュール）
    │   ├── スラット/ケージ
    │   ├── ERA
    │   └── APS（ソフト/ハード）
    └── ネットワーク
        ├── BMS/戦術データリンク
        ├── 位置共有（Blue Force Tracking等の概念）
        └── 遠隔操作/無人随伴（MUM-T等の概念）
```