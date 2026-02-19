/**
 * generate_symbols.js
 *
 * milsymbol (v3.x) を使って NATO APP-6E / MIL-STD-2525E 準拠の
 * 兵科記号SVGを生成し、Godot の res://assets/units/symbols/ に書き出す。
 *
 * 使い方:
 *   cd tools
 *   npm install
 *   node generate_symbols.js
 *
 * 出力先: ../assets/units/symbols/
 *
 * --- SIDC 形式（32文字・数値型 APP-6E）---
 *  位置  長さ  内容
 *  0-1   2     バージョン (13=APP-6E/2525E)
 *  2     1     コンテキスト (0=Reality)
 *  3     1     所属 (3=友軍青, 6=敵赤, 1=不明白)
 *  4-5   2     シンボルセット (10=地上部隊, 01=航空)
 *  6     1     状態 (0=現存)
 *  7     1     HQ/TF/Dummy (0=なし, 1=HQ)
 *  8-9   2     梯隊/機動性 (00=未指定, 13=中隊)
 *  10-15 6     機能ID (ユニット種別を決める)
 *  16-19 4     修飾子1・2 (各2桁, 00=なし)
 *  20-31 12    予約済み (000000000000)
 */

import ms from "milsymbol";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.resolve(__dirname, "../assets/units/symbols");

// ---------------------------------------------------------------------------
// SIDC ビルダー
// baseSIDC: 所属プレースホルダー付きの32文字テンプレート
// affChar:  所属コード (3=友軍, 6=敵, 1=不明)
// ---------------------------------------------------------------------------
function buildSIDC(template, affChar) {
  // position 3 が所属コード
  return template.slice(0, 3) + affChar + template.slice(4);
}

// ---------------------------------------------------------------------------
// ユニット定義
// sidc: position 3 を 'X' にしたテンプレート（buildSIDCで置換）
//
// 機能ID早見表（地上部隊 symbolSet=10）:
//   121100 = 歩兵 (Infantry)
//   121102 = 機械化歩兵 (Infantry + Armour)
//   121104 = 自動車化歩兵 (Infantry + Motorized) ← APC
//   140700 = 工兵 (Engineer)
//   121300 = 偵察 (Reconnaissance)
//   120500 = 機甲/戦車 (Armour)
//   130800 = 迫撃砲 (Mortar)
//   130300 = 野戦砲兵 (Field Artillery)
//   120400 = 対戦車 (Antitank/Antiarmour)
//   163400 = 補給 (Supply)
//   161300 = 衛生 (Medical)
//
// 航空 symbolSet=01:
//   110300 = 固定翼 (Fixed Wing) ← UAV偵察機として使用
// ---------------------------------------------------------------------------
const UNIT_DEFINITIONS = [
  // ---- 歩兵系 ----
  {
    id: "inf_rifle",
    label: "ライフル歩兵",
    category: "infantry",
    weight: "light",
    // 13 0 X 10 0 0 00 121100 0000 000000000000
    sidc: "130X10000012110000000000000000",
    options: { size: 60 },
  },
  {
    id: "inf_mech",
    label: "機械化歩兵",
    category: "infantry",
    weight: "medium",
    // 機能ID 121102 = Infantry + Armour
    sidc: "130X10000012110200000000000000",
    options: { size: 60 },
  },
  {
    id: "inf_engineer",
    label: "工兵",
    category: "infantry",
    weight: "light",
    sidc: "130X10000014070000000000000000",
    options: { size: 60 },
  },
  {
    id: "inf_recon",
    label: "偵察",
    category: "infantry",
    weight: "light",
    sidc: "130X10000012130000000000000000",
    options: { size: 60 },
  },

  // ---- 機甲系 ----
  {
    id: "armor_tank",
    label: "戦車",
    category: "armor",
    weight: "heavy",
    sidc: "130X10000012050000000000000000",
    options: { size: 60 },
  },
  {
    id: "armor_ifv",
    label: "歩兵戦闘車（IFV）",
    category: "armor",
    weight: "medium",
    // 機能ID 121102 = Infantry + Armour (IFVとして代用)
    sidc: "130X10000012110200000000000000",
    options: { size: 60 },
  },
  {
    id: "armor_apc",
    label: "装甲兵員輸送車（APC）",
    category: "armor",
    weight: "medium",
    // 機能ID 121104 = Infantry + Motorized
    sidc: "130X10000012110400000000000000",
    options: { size: 60 },
  },

  // ---- 火力支援 ----
  {
    id: "fs_mortar",
    label: "迫撃砲",
    category: "fire_support",
    weight: "light",
    sidc: "130X10000013080000000000000000",
    options: { size: 60 },
  },
  {
    id: "fs_artillery",
    label: "砲兵",
    category: "fire_support",
    weight: "heavy",
    sidc: "130X10000013030000000000000000",
    options: { size: 60 },
  },
  {
    id: "fs_atgm",
    label: "対戦車ミサイル（ATGM）",
    category: "fire_support",
    weight: "light",
    sidc: "130X10000012040000000000000000",
    options: { size: 60 },
  },

  // ---- 偵察・情報 ----
  {
    id: "recon_uav",
    label: "UAV（無人偵察機）",
    category: "recon",
    weight: "light",
    // symbolSet=01 (航空), 機能ID 110300 = Fixed Wing
    sidc: "130X01000011030000000000000000",
    options: { size: 60 },
  },

  // ---- 支援 ----
  {
    id: "sup_logistics",
    label: "兵站/補給",
    category: "support",
    weight: "light",
    sidc: "130X10000016340000000000000000",
    options: { size: 60 },
  },
  {
    id: "sup_medevac",
    label: "衛生/後送",
    category: "support",
    weight: "light",
    sidc: "130X10000016130000000000000000",
    options: { size: 60 },
  },

  // ---- 指揮 ----
  {
    id: "cmd_hq",
    label: "中隊本部（HQ）",
    category: "command",
    weight: "light",
    // HQ=1, echelon=13(中隊), 歩兵記号
    sidc: "130X10011312110000000000000000",
    options: { size: 60 },
  },
];

// ---------------------------------------------------------------------------
// 所属バリアント
// APP-6E position 3: 3=友軍(青), 6=敵(赤), 1=不明(白)
// ---------------------------------------------------------------------------
const AFFILIATIONS = [
  { key: "friendly", sidcChar: "3", label: "味方" },
  { key: "hostile",  sidcChar: "6", label: "敵" },
  { key: "unknown",  sidcChar: "1", label: "不明" },
];

// ---------------------------------------------------------------------------
// 確度バリアント
// CONF: 通常表示 / SUS: 半透明（Godot側でシェーダー or modulate で追加表現）
// LOST: Godot側で非表示対応 → SVG不要
// ---------------------------------------------------------------------------
const CONFIDENCE_VARIANTS = [
  { key: "conf", svgPostProcess: null },
  {
    key: "sus",
    svgPostProcess: (svg) => svg.replace("<svg ", '<svg opacity="0.55" '),
  },
];

// ---------------------------------------------------------------------------
// ユーティリティ
// ---------------------------------------------------------------------------
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// ---------------------------------------------------------------------------
// 生成
// ---------------------------------------------------------------------------
function generateAll() {
  ensureDir(OUTPUT_DIR);

  let generated = 0;
  let errors = 0;

  for (const unit of UNIT_DEFINITIONS) {
    for (const affiliation of AFFILIATIONS) {
      const sidc = buildSIDC(unit.sidc, affiliation.sidcChar);

      for (const conf of CONFIDENCE_VARIANTS) {
        const filename = `${unit.id}_${affiliation.key}_${conf.key}.svg`;
        const outputPath = path.join(OUTPUT_DIR, filename);

        try {
          const sym = new ms.Symbol(sidc, { ...unit.options });
          let svg = sym.asSVG();

          // 確度変換（SUSは半透明化）
          if (conf.svgPostProcess) {
            svg = conf.svgPostProcess(svg);
          }

          // メタデータコメントを先頭に付与
          const svgWithMeta = svg.replace(
            "<svg",
            `<!-- milsymbol APP-6E symbol
     unit_id: ${unit.id}
     label: ${unit.label}
     sidc: ${sidc}
     affiliation: ${affiliation.key}
     confidence: ${conf.key}
     weight: ${unit.weight}
     category: ${unit.category}
-->\n<svg`
          );

          fs.writeFileSync(outputPath, svgWithMeta, "utf-8");
          generated++;

          // 「？」アイコン検出（94.8206 はundefinedIconパスの固有座標）
          const isQ = svg.includes("94.8206");
          console.log(`  ${isQ ? "Q(?)" : "OK  "} ${filename}`);
        } catch (err) {
          errors++;
          console.error(`  NG   ${filename} : ${err.message}`);
        }
      }
    }
  }

  console.log(`\n完了: ${generated} ファイル生成, ${errors} エラー`);
  console.log(`出力先: ${OUTPUT_DIR}`);
}

// ---------------------------------------------------------------------------
// エントリポイント
// ---------------------------------------------------------------------------
console.log("Company Commander - 兵科記号SVG生成");
console.log("milsymbol v3 使用 (APP-6E / MIL-STD-2525E, 32文字SIDC)");
console.log("-----------------------------------------------------------");
generateAll();
