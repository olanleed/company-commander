class_name ElementFactory
extends RefCounted

## ElementFactory - ユニット生成ファクトリ
## 仕様書: docs/unit_archetypes_v0.1.md
##
## アーキタイプIDからElementInstanceを生成し、
## 適切な武装を自動的に装備する。

# =============================================================================
# 定数
# =============================================================================

## アーキタイプ別のデフォルト武装マッピング
const ARCHETYPE_WEAPONS: Dictionary = {
	"INF_LINE": ["CW_RIFLE_STD", "CW_LAW"],  # 小銃 + 軽AT武器
	"INF_AT": ["CW_RIFLE_STD", "CW_RPG_HEAT"],
	"INF_MG": ["CW_MG_STD"],
	"TANK_PLT": ["CW_TANK_KE", "CW_TANK_HEATMP", "CW_COAX_MG"],  # 主砲AP/HE + 同軸MG
	"RECON_VEH": ["CW_RIFLE_STD"],  # 軽火器のみ
	"RECON_TEAM": ["CW_RIFLE_STD"],
	"MORTAR_SEC": ["CW_MORTAR_HE", "CW_MORTAR_SMOKE"],
	"LOG_TRUCK": [],  # 武装なし
}

# =============================================================================
# ID生成
# =============================================================================

static var _id_counters: Dictionary = {}


## ユニークIDを生成
static func _generate_unique_id(archetype_id: String) -> String:
	if archetype_id not in _id_counters:
		_id_counters[archetype_id] = 0
	_id_counters[archetype_id] += 1
	return "%s_%03d" % [archetype_id, _id_counters[archetype_id]]


## IDカウンターをリセット（テスト用）
static func reset_id_counters() -> void:
	_id_counters.clear()


# =============================================================================
# Element生成
# =============================================================================

## アーキタイプIDからElementInstanceを生成
static func create_element(
	archetype_id: String,
	faction: GameEnums.Faction,
	position: Vector2,
	facing: float = 0.0
) -> ElementData.ElementInstance:
	# アーキタイプを取得
	var element_type := ElementData.ElementArchetypes.get_archetype(archetype_id)

	# インスタンス生成
	var element := ElementData.ElementInstance.new(element_type)
	element.id = _generate_unique_id(archetype_id)
	element.faction = faction
	element.position = position
	element.prev_position = position
	element.facing = facing
	element.prev_facing = facing

	# 武装を装備
	_equip_weapons(element, archetype_id)

	return element


## 武装を装備
static func _equip_weapons(element: ElementData.ElementInstance, archetype_id: String) -> void:
	if archetype_id not in ARCHETYPE_WEAPONS:
		return

	var weapon_ids: Array = ARCHETYPE_WEAPONS[archetype_id]
	var all_weapons := WeaponData.get_all_concrete_weapons()

	for weapon_id in weapon_ids:
		if weapon_id in all_weapons:
			var weapon: WeaponData.WeaponType = all_weapons[weapon_id]
			element.weapons.append(weapon)

	# 主武装を設定（後方互換）
	if element.weapons.size() > 0:
		element.primary_weapon = element.weapons[0]


# =============================================================================
# 中隊生成ヘルパー
# =============================================================================

## 標準歩兵中隊を生成（3×ライフル分隊 + 1×MG班 + 1×AT班）
static func create_infantry_company(
	faction: GameEnums.Faction,
	base_position: Vector2,
	company_id: String = ""
) -> Array[ElementData.ElementInstance]:
	var elements: Array[ElementData.ElementInstance] = []
	var spacing := 50.0  # ユニット間隔

	# 3×ライフル分隊
	for i in range(3):
		var offset := Vector2(float(i - 1) * spacing, 0.0)
		var element := create_element("INF_LINE", faction, base_position + offset)
		element.company_id = company_id
		elements.append(element)

	# 1×MG班（後方中央）
	var mg := create_element("INF_MG", faction, base_position + Vector2(0, spacing))
	mg.company_id = company_id
	elements.append(mg)

	# 1×AT班（後方左）
	var at := create_element("INF_AT", faction, base_position + Vector2(-spacing, spacing))
	at.company_id = company_id
	elements.append(at)

	return elements


## 戦車小隊を生成
static func create_tank_platoon(
	faction: GameEnums.Faction,
	base_position: Vector2,
	company_id: String = ""
) -> Array[ElementData.ElementInstance]:
	var elements: Array[ElementData.ElementInstance] = []

	var tank := create_element("TANK_PLT", faction, base_position)
	tank.company_id = company_id
	elements.append(tank)

	return elements


## 偵察チームを生成
static func create_recon_element(
	faction: GameEnums.Faction,
	base_position: Vector2,
	use_vehicle: bool = false,
	company_id: String = ""
) -> Array[ElementData.ElementInstance]:
	var elements: Array[ElementData.ElementInstance] = []

	var archetype := "RECON_VEH" if use_vehicle else "RECON_TEAM"
	var recon := create_element(archetype, faction, base_position)
	recon.company_id = company_id
	elements.append(recon)

	return elements


## 火力支援班（迫撃砲）を生成
static func create_mortar_section(
	faction: GameEnums.Faction,
	base_position: Vector2,
	company_id: String = ""
) -> Array[ElementData.ElementInstance]:
	var elements: Array[ElementData.ElementInstance] = []

	var mortar := create_element("MORTAR_SEC", faction, base_position)
	mortar.company_id = company_id
	elements.append(mortar)

	return elements


# =============================================================================
# ユーティリティ
# =============================================================================

## アーキタイプの説明を取得
static func get_archetype_description(archetype_id: String) -> String:
	match archetype_id:
		"INF_LINE":
			return "ライフル分隊（9人）: 標準的な歩兵ユニット"
		"INF_AT":
			return "対戦車チーム（4人）: RPG装備の対装甲ユニット"
		"INF_MG":
			return "機関銃班（3人）: 制圧射撃に優れた火力支援"
		"TANK_PLT":
			return "戦車小隊（4両）: 重装甲・高火力の機甲ユニット"
		"RECON_VEH":
			return "偵察車両: 高機動・長距離偵察能力"
		"RECON_TEAM":
			return "偵察チーム（4人）: 隠密偵察に優れた歩兵"
		"MORTAR_SEC":
			return "迫撃砲班（6人）: 間接射撃による火力支援"
		"LOG_TRUCK":
			return "補給トラック: 弾薬・物資の輸送"
		_:
			return "不明なアーキタイプ"


## 利用可能な全アーキタイプIDを取得
static func get_all_archetype_ids() -> Array[String]:
	return [
		"INF_LINE",
		"INF_AT",
		"INF_MG",
		"TANK_PLT",
		"RECON_VEH",
		"RECON_TEAM",
		"MORTAR_SEC",
		"LOG_TRUCK",
	]
