```
man_portable_anti_tank_weapons_2026_mainstream
├── 0_大分類（射手が携行して運用できるAT火器）
│   ├── 0-1_無誘導ロケット（rocket_launcher：主流）
│   │   ├── 使い切り（disposable / single-shot）
│   │   │   ├── 低〜中口径ロケット（軽量・即応）
│   │   │   └── 特徴：携行性・配備しやすさ重視
│   │   └── 再使用（reusable / reloadable）
│   │       ├── 発射筒＋弾薬交換（reload）
│   │       └── 特徴：弾種を変えて運用しやすい
│   ├── 0-2_無反動砲（recoilless_rifle：限定的だが現用枠）
│   │   ├── 肩撃ち/三脚（systemによる）
│   │   └── 特徴：直射火力・多用途弾を持てる（体系により）
│   └── 0-3_携行ATGM（man-portable ATGM：主流）
│       ├── CLU＋ミサイル（発射機＋弾体）
│       └── 形態：肩撃ち/三脚/軽車両併用など
├── 1_誘導・照準方式（Guidance / aiming）
│   ├── 1-1_無誘導（unguided）
│   │   ├── 光学照準（スコープ）
│   │   ├── 反射照準（レティクル）
│   │   └── FCS補助（測距・弾道計算：搭載例あり）
│   ├── 1-2_半自動指令誘導（SACLOS：依然多い）
│   │   ├── 有線（wire-guided）
│   │   ├── 無線（radio command：体系により）
│   │   └── レーザービームライディング（beam riding：採用例）
│   └── 1-3_撃ちっぱなし（fire-and-forget：主流化）
│       ├── IIR（画像赤外）シーカー
│       ├── MMW（ミリ波）レーダーシーカー（採用例）
│       └── ロック方式
│           ├── LOBL（発射前ロック）
│           └── LOAL（発射後ロック：可能な体系）
├── 2_攻撃プロファイル（Target attack profile）
│   ├── 2-1_直射（direct attack）
│   ├── 2-2_トップアタック（top attack：主流）
│   │   ├── 目的：砲塔上面など比較的薄い部位を狙う
│   │   └── 方式：誘導（ATGM）で多い／一部ロケットでも概念あり
│   └── 2-3_オーバーフライ（overfly top attack：採用例）
│       └── 目標上空を通過して上向き効果で攻撃（体系により）
├── 3_弾頭（Warhead）
│   ├── 3-1_HEAT（成形炸薬：基本）
│   ├── 3-2_タンデムHEAT（対ERA想定：主流）
│   ├── 3-3_多目的（MP：対人/対軽装甲/壁破壊）
│   │   ├── 遅延信管（壁貫通後起爆の類）
│   │   └── 破片効果重視（ソフトターゲット向け）
│   └── 3-4_熱圧力（thermobaric：用途限定だが現用）
│       └── 主に対建物・陣地など
├── 4_発射方式・運用上の区分
│   ├── 4-1_発射安全（代表的な区分）
│   │   ├── 後方噴射（backblastあり）
│   │   └── 低後方噴射/閉所射撃対応（CS：体系により）
│   ├── 4-2_乗員・携行
│   │   ├── 1名運用（単独携行・即応）
│   │   └── 2名運用（射手＋弾薬手：ATGMで多い）
│   └── 4-3_照準・センサー
│       ├── 昼間光学
│       ├── IR/サーマル
│       └── 測距（レーザー測距など：体系により）
└── 5_実務でよくある“呼び分け”（例の粒度）
    ├── disposable_AT_rocket
    │   └── unguided + HEAT/MP
    ├── reloadable_rocket_launcher
    │   └── unguided + 多弾種（HEAT/タンデム/MP等）
    ├── manportable_ATGM_SACLOS
    │   └── command-guided（wire/beam等）+ top-attack可の体系あり
    └── manportable_ATGM_FnF
        └── IIR/MMW + LOBL/LOAL + top-attack（主流カテゴリ）
```