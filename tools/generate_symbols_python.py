"""
generate_symbols_python.py

nwroyer/Python-Military-Symbols を使って兵科記号SVGを生成し、
assets/units/symbols_python/ に書き出すスクリプト。

使い方:
  python3 tools/generate_symbols_python.py

前提: /home/olanleed/work/github/Python-Military-Symbols がクローン済みであること
"""

import sys
import os

# Python-Military-Symbols のソースパスを追加
PMS_SRC = os.path.expanduser("~/work/github/Python-Military-Symbols/src")
sys.path.insert(0, PMS_SRC)

import military_symbol

# ---------------------------------------------------------------------------
# 出力先
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "../assets/units/symbols_python")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# ユニット定義（自然言語名 → milsymbol）
# v0.1仕様に対応する兵科一覧
# ---------------------------------------------------------------------------
UNIT_DEFINITIONS = [
    # id, label, friendly_name, hostile_name, weight, category
    ("inf_rifle",     "ライフル歩兵",           "friendly infantry",                  "enemy infantry",                  "light",  "infantry"),
    ("inf_mech",      "機械化歩兵",             "friendly mechanized infantry",        "enemy mechanized infantry",        "medium", "infantry"),
    ("inf_engineer",  "工兵",                   "friendly engineer",                   "enemy engineer",                   "light",  "infantry"),
    ("inf_recon",     "偵察",                   "friendly reconnaissance",             "enemy reconnaissance",             "light",  "infantry"),
    ("armor_tank",    "戦車",                   "friendly armor",                      "enemy armor",                      "heavy",  "armor"),
    ("armor_ifv",     "IFV（歩兵戦闘車）",      "friendly mechanized infantry",        "enemy mechanized infantry",        "medium", "armor"),
    ("armor_apc",     "APC（装甲兵員輸送車）",   "friendly motorized infantry",         "enemy motorized infantry",         "medium", "armor"),
    ("fs_mortar",     "迫撃砲",                 "friendly mortar",                     "enemy mortar",                     "light",  "fire_support"),
    ("fs_artillery",  "砲兵",                   "friendly artillery",                  "enemy artillery",                  "heavy",  "fire_support"),
    ("fs_atgm",       "対戦車ミサイル",          "friendly antitank",                   "enemy antitank",                   "light",  "fire_support"),
    ("recon_uav",     "UAV（無人偵察機）",       "friendly unmanned aircraft",          "enemy unmanned aircraft",          "light",  "recon"),
    ("sup_logistics", "兵站/補給",              "friendly combat service support",     "enemy combat service support",     "light",  "support"),
    ("sup_medevac",   "衛生/後送",              "friendly medical",                    "enemy medical",                    "light",  "support"),
    ("cmd_hq",        "中隊本部（HQ）",          "friendly infantry headquarters",      "enemy infantry headquarters",      "light",  "command"),
]

# 所属バリアント
AFFILIATIONS = [
    ("friendly", "friendly"),
    ("hostile",  "enemy"),
    ("unknown",  "unknown"),
]

# 確度バリアント
CONFIDENCE_VARIANTS = [
    ("conf", {}),
    ("sus",  {"standard": "2525", "status": "anticipated"}),  # 点線フレームで推定表現
]

# スタイル: medium（塗り有り・輪郭あり）
STYLE = "medium"

# ---------------------------------------------------------------------------
# 生成
# ---------------------------------------------------------------------------
generated = 0
errors = 0

print("Company Commander - 兵科記号SVG生成（Python-Military-Symbols）")
print(f"出力先: {OUTPUT_DIR}")
print("-" * 50)

for unit_id, label, friendly_name, hostile_name, weight, category in UNIT_DEFINITIONS:
    for aff_key, aff_prefix in AFFILIATIONS:
        # 所属に応じた名前を組み立て
        if aff_key == "friendly":
            name_query = friendly_name
        elif aff_key == "hostile":
            name_query = hostile_name
        else:
            # unknown: friendly名のunknown版
            name_query = "unknown " + friendly_name.replace("friendly ", "").replace("enemy ", "")

        for conf_key, conf_opts in CONFIDENCE_VARIANTS:
            filename = f"{unit_id}_{aff_key}_{conf_key}.svg"
            output_path = os.path.join(OUTPUT_DIR, filename)

            try:
                svg = military_symbol.get_symbol_svg_string_from_name(
                    name_query,
                    style=STYLE,
                    use_variants=True,
                )

                # SUSバリアントはopacityを下げて区別
                if conf_key == "sus":
                    svg = svg.replace("<svg ", '<svg opacity="0.55" ', 1)

                # メタデータコメントを先頭に付与
                meta = (
                    f"<!-- python-military-symbols generated symbol\n"
                    f"     unit_id: {unit_id}\n"
                    f"     label: {label}\n"
                    f"     query: {name_query}\n"
                    f"     affiliation: {aff_key}\n"
                    f"     confidence: {conf_key}\n"
                    f"     weight: {weight}\n"
                    f"     category: {category}\n"
                    f"-->\n"
                )
                svg = meta + svg

                with open(output_path, "w", encoding="utf-8") as f:
                    f.write(svg)

                print(f"  OK  {filename}")
                generated += 1

            except Exception as e:
                print(f"  NG  {filename} : {e}")
                errors += 1

print()
print(f"完了: {generated} ファイル生成, {errors} エラー")
print(f"出力先: {OUTPUT_DIR}")
