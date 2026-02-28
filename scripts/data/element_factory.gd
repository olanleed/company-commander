class_name ElementFactory
extends RefCounted

## ElementFactory - ユニット生成ファクトリ
## 仕様書: docs/unit_archetypes_v0.1.md
##
## アーキタイプIDからElementInstanceを生成し、
## 適切な武装を自動的に装備する。
## VehicleCatalogと連携して各国兵器の特性を反映する。

const VehicleCatalogClass = preload("res://scripts/data/vehicle_catalog.gd")
const AmmoStateClass = preload("res://scripts/data/ammo_state.gd")

# =============================================================================
# 定数
# =============================================================================

## 共有VehicleCatalogインスタンス
static var _vehicle_catalog = null  # VehicleCatalogClass

## アーキタイプ別のデフォルト武装マッピング
const ARCHETYPE_WEAPONS: Dictionary = {
	"INF_LINE": ["CW_RIFLE_STD", "CW_CARL_GUSTAF"],  # 小銃 + 84mm無反動砲
	"INF_AT": ["CW_RIFLE_STD", "CW_RPG_HEAT"],
	"INF_MG": ["CW_MG_STD"],
	"TANK_PLT": ["CW_TANK_KE", "CW_TANK_HEATMP", "CW_COAX_MG"],  # 主砲AP/HE + 同軸MG
	"IFV_PLT": ["CW_AUTOCANNON_30", "W_GEN_ATGM_STD", "CW_COAX_MG"],  # 機関砲 + ATGM + 同軸MG
	"APC_PLT": ["CW_HMG"],  # 12.7mm重機関銃
	"LIGHT_VEH": ["CW_RIFLE_STD"],  # 軽火器のみ
	"COMMAND_VEH": ["CW_HMG"],  # 12.7mm重機関銃
	"RECON_VEH": ["CW_RIFLE_STD"],  # 軽火器のみ
	"RECON_TEAM": ["CW_RIFLE_STD"],
	"MORTAR_SEC": ["CW_MORTAR_HE", "CW_MORTAR_SMOKE"],
	"SP_MORTAR": ["CW_MORTAR_120"],  # 120mm自走迫撃砲
	"SP_ARTILLERY": ["CW_HOWITZER_155"],  # 155mm榴弾砲
	"SPAAG": ["CW_AUTOCANNON_35"],  # 35mm連装機関砲
	"SAM_VEH": [],  # 対空ミサイル（未実装）
	"ATGM_VEH": ["W_JPN_ATGM_MMPM"],  # 対戦車ミサイル車両
	"LOG_TRUCK": [],  # 武装なし
	"CMD_HQ": ["CW_RIFLE_STD"],  # 軽火器のみ
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
# VehicleCatalog連携
# =============================================================================

## VehicleCatalogを初期化してロード
static func init_vehicle_catalog() -> void:
	if _vehicle_catalog == null:
		_vehicle_catalog = VehicleCatalogClass.new()
		_vehicle_catalog.load_all()


## VehicleCatalogを取得
static func get_vehicle_catalog():
	if _vehicle_catalog == null:
		init_vehicle_catalog()
	return _vehicle_catalog


## 車両カタログを使用してElementInstanceを生成
## vehicle_id: カタログ内の車両ID (例: "JPN_Type10", "USA_M1A2")
static func create_element_with_vehicle(
	vehicle_id: String,
	faction: GameEnums.Faction,
	position: Vector2,
	facing: float = 0.0
) -> ElementData.ElementInstance:
	# カタログを初期化
	if _vehicle_catalog == null:
		init_vehicle_catalog()

	# 車両設定を取得
	var vehicle_config = _vehicle_catalog.get_vehicle(vehicle_id)
	if not vehicle_config:
		push_warning("[ElementFactory] Vehicle not found: %s, using base archetype" % vehicle_id)
		return create_element("TANK_PLT", faction, position, facing)

	# ベースアーキタイプを取得（コピーを作成してmodifierを適用）
	var archetype_id: String = vehicle_config.base_archetype
	var base_archetype: ElementData.ElementType = ElementData.ElementArchetypes.get_archetype(archetype_id)
	var element_type: ElementData.ElementType = base_archetype.duplicate()

	# VehicleConfigのmodifierを適用（コピーに適用するので元のアーキタイプは変更されない）
	_vehicle_catalog.apply_to_element_type(element_type, vehicle_config)

	# インスタンス生成
	var element := ElementData.ElementInstance.new(element_type)
	element.id = _generate_unique_id(archetype_id)
	element.faction = faction
	element.position = position
	element.prev_position = position
	element.facing = facing
	element.prev_facing = facing

	# 車両IDを記録（将来の参照用）
	element.vehicle_id = vehicle_id

	# 武装を装備（modifierを適用）
	_equip_weapons_with_vehicle(element, archetype_id, vehicle_config)

	# 砲兵展開時間を設定（SP_ARTILLERY/SP_MORTARのみ）
	if archetype_id in ["SP_ARTILLERY", "SP_MORTAR"]:
		element.artillery_deploy_time_sec = vehicle_config.artillery_deploy_time_sec
		element.artillery_pack_time_sec = vehicle_config.artillery_pack_time_sec

	# 弾薬状態を初期化（車両カタログから）
	_init_ammo_state(element, vehicle_config)

	# 補給設定を初期化（LOG_TRUCK用）
	_init_supply_config(element, vehicle_config)

	return element


## 武装を装備（VehicleConfig適用）
static func _equip_weapons_with_vehicle(
	element: ElementData.ElementInstance,
	archetype_id: String,
	vehicle_config
) -> void:
	# VehicleCatalogのweapon_id指定があればそれを優先
	if vehicle_config.main_gun.has("weapon_id") or vehicle_config.atgm.has("weapon_id") or vehicle_config.secondary_weapons.size() > 0:
		# VehicleCatalogから武装を適用
		_vehicle_catalog.apply_weapons_to_element(element, vehicle_config)
		# current_weaponを設定
		if element.weapons.size() > 0:
			element.current_weapon = element.weapons[0]
		return

	# フォールバック: ARCHETYPE_WEAPONSから武装を装備
	if archetype_id not in ARCHETYPE_WEAPONS:
		return

	var weapon_ids: Array = ARCHETYPE_WEAPONS[archetype_id]
	var all_weapons := WeaponData.get_all_concrete_weapons()

	for weapon_id in weapon_ids:
		if weapon_id in all_weapons:
			# 武器をコピーしてmodifierを適用
			var base_weapon: WeaponData.WeaponType = all_weapons[weapon_id]
			var weapon := _copy_weapon(base_weapon)

			# 主砲系武器にはmain_gun modifierを適用
			if weapon_id in ["CW_TANK_KE", "CW_TANK_HEATMP"]:
				_vehicle_catalog.apply_to_weapon(weapon, vehicle_config)

			element.weapons.append(weapon)

	# 主武装を設定
	if element.weapons.size() > 0:
		element.primary_weapon = element.weapons[0]


## 弾薬状態を初期化（車両カタログから）
static func _init_ammo_state(element: ElementData.ElementInstance, vehicle_config) -> void:
	# カタログデータを収集
	var catalog_data := {}

	# 主砲
	if vehicle_config.main_gun.size() > 0:
		catalog_data["main_gun"] = vehicle_config.main_gun

	# ATGM
	if vehicle_config.atgm.size() > 0:
		catalog_data["atgm"] = vehicle_config.atgm

	# 弾薬がある場合のみAmmoStateを作成（主砲またはATGMがある場合）
	if catalog_data.has("main_gun") or catalog_data.has("atgm"):
		# 防護情報（誘爆脆弱性計算用）
		if vehicle_config.protection.size() > 0:
			catalog_data["protection"] = vehicle_config.protection
		element.ammo_state = AmmoStateClass.create_from_catalog(catalog_data)


## 補給設定を初期化（LOG_TRUCK用）
static func _init_supply_config(element: ElementData.ElementInstance, vehicle_config) -> void:
	# 補給設定がある場合のみ適用
	if vehicle_config.supply.size() > 0:
		element.supply_config = vehicle_config.supply.duplicate()
		# 残り補給容量を初期化（unit_countで乗算）
		var base_capacity: int = element.supply_config.get("capacity", 0)
		var unit_count: int = vehicle_config.unit_count
		element.supply_remaining = base_capacity * unit_count


## WeaponTypeをコピー（独立したインスタンスを作成）
static func _copy_weapon(original: WeaponData.WeaponType) -> WeaponData.WeaponType:
	var copy := WeaponData.WeaponType.new()
	copy.id = original.id
	copy.display_name = original.display_name
	copy.mechanism = original.mechanism
	copy.fire_model = original.fire_model
	copy.min_range_m = original.min_range_m
	copy.max_range_m = original.max_range_m
	copy.range_band_thresholds_m = original.range_band_thresholds_m.duplicate()
	copy.threat_class = original.threat_class
	copy.preferred_target = original.preferred_target
	copy.ammo_endurance_min = original.ammo_endurance_min
	copy.rof_rpm = original.rof_rpm
	copy.sigma_hit_m = original.sigma_hit_m
	copy.direct_hit_radius_m = original.direct_hit_radius_m
	copy.shock_radius_m = original.shock_radius_m
	copy.setup_time_sec = original.setup_time_sec
	copy.displace_time_sec = original.displace_time_sec
	copy.requires_observer = original.requires_observer
	copy.blast_radius_m = original.blast_radius_m
	copy.projectile_speed_mps = original.projectile_speed_mps
	copy.projectile_size = original.projectile_size

	# weapon_role（JSONから読み込まれた値を保持）
	copy.weapon_role = original.weapon_role

	# Dictionaryは深いコピー
	copy.lethality = original.lethality.duplicate(true)
	copy.suppression_power = original.suppression_power.duplicate(true)
	copy.pen_ke = original.pen_ke.duplicate(true)
	copy.pen_ce = original.pen_ce.duplicate(true)

	return copy


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
		"IFV_PLT",
		"APC_PLT",
		"LIGHT_VEH",
		"COMMAND_VEH",
		"RECON_VEH",
		"RECON_TEAM",
		"MORTAR_SEC",
		"SP_MORTAR",
		"SP_ARTILLERY",
		"SPAAG",
		"SAM_VEH",
		"LOG_TRUCK",
		"CMD_HQ",
	]
