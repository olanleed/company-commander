class_name ElementData
extends RefCounted

## Element（要素）のデータモデル
## 仕様書: docs/units_v0.1.md
##
## Element は中隊の内部構成要素。
## ElementType (固定仕様) と ElementInstance (可変状態) を保持。

# =============================================================================
# Element カテゴリ
# =============================================================================

enum Category {
	INF,   ## 歩兵
	VEH,   ## 車両
	REC,   ## 偵察
	WEAP,  ## 火器
	ENG,   ## 工兵
	LOG,   ## 兵站
	HQ,    ## 司令部
}

# =============================================================================
# シンボルタイプ (SVGファイル名に対応)
# =============================================================================

enum SymbolType {
	INF_RIFLE,
	INF_MECH,
	INF_RECON,
	INF_ENGINEER,
	ARMOR_TANK,
	ARMOR_IFV,
	ARMOR_APC,
	FS_MORTAR,
	FS_ATGM,
	FS_ARTILLERY,
	RECON_UAV,
	SUP_LOGISTICS,
	SUP_MEDEVAC,
	CMD_HQ,
}

# =============================================================================
# ElementType (固定仕様)
# =============================================================================

class ElementType:
	var id: String = ""
	var display_name: String = ""
	var category: Category = Category.INF
	var symbol_type: SymbolType = SymbolType.INF_RIFLE

	## Mobility
	var mobility_class: GameEnums.MobilityType = GameEnums.MobilityType.FOOT
	var road_speed: float = 5.0  # m/s
	var cross_speed: float = 3.0  # m/s

	## Combat
	var base_strength: int = 100
	var max_strength: int = 100

	## Sensors
	var spot_range_base: float = 300.0  # m
	var spot_range_moving: float = 200.0  # m

	## Protection - armor_class
	## 0 = Soft (ソフトスキン) - 小銃弾で貫通可能 (トラック、ジープ、歩兵)
	## 1 = Light Armor (軽装甲) - 小銃弾耐性、12.7mm/機関砲で貫通 (装甲偵察車、APC)
	## 2 = Medium Armor (中装甲) - 機関砲耐性、ATで貫通 (IFV、旧式戦車)
	## 3 = Heavy Armor (重装甲) - AT以外は無効 (MBT)
	var armor_class: int = 0

	## Communication (データリンク)
	var is_comm_hub: bool = false        # 通信ハブ（指揮ユニット）か
	var comm_range: float = 2000.0       # 通信距離 (m)

	## Transport (輸送能力)
	var can_transport_infantry: bool = false  # 歩兵輸送能力
	var transport_capacity: int = 0           # 輸送可能な歩兵数（0=輸送不可）

	## v0.1R: ゾーン別装甲（0-100レーティング）
	## 仕様書: docs/damage_model_v0.1.md
	## ArmorZone.FRONT/SIDE/REAR/TOP → rating
	var armor_ke: Dictionary = {}  # KINETICに対する装甲
	var armor_ce: Dictionary = {}  # SHAPED_CHARGEに対する装甲


	## 独立したコピーを作成（VehicleCatalog modifier適用用）
	func duplicate() -> ElementType:
		var copy := ElementType.new()
		copy.id = id
		copy.display_name = display_name
		copy.category = category
		copy.symbol_type = symbol_type
		copy.mobility_class = mobility_class
		copy.road_speed = road_speed
		copy.cross_speed = cross_speed
		copy.base_strength = base_strength
		copy.max_strength = max_strength
		copy.spot_range_base = spot_range_base
		copy.spot_range_moving = spot_range_moving
		copy.armor_class = armor_class
		copy.is_comm_hub = is_comm_hub
		copy.comm_range = comm_range
		copy.can_transport_infantry = can_transport_infantry
		copy.transport_capacity = transport_capacity
		copy.armor_ke = armor_ke.duplicate()
		copy.armor_ce = armor_ce.duplicate()
		return copy


# =============================================================================
# ElementInstance (可変状態)
# =============================================================================

class ElementInstance:
	var id: String = ""
	var element_type: ElementType

	## 所属
	var faction: GameEnums.Faction = GameEnums.Faction.NONE
	var company_id: String = ""

	## 位置・移動
	var position: Vector2 = Vector2.ZERO
	var facing: float = 0.0  # ラジアン
	var velocity: Vector2 = Vector2.ZERO

	## 前tick位置 (補間用)
	var prev_position: Vector2 = Vector2.ZERO
	var prev_facing: float = 0.0

	## 状態
	var state: GameEnums.UnitState = GameEnums.UnitState.ACTIVE
	var current_strength: int = 100  # 仕様: Strength 0-100 スケール
	var suppression: float = 0.0  # 0.0 ~ 1.0

	## 視界状態 (他陣営から見た状態)
	var contact_state: GameEnums.ContactState = GameEnums.ContactState.UNKNOWN
	var last_seen_tick: int = -1
	var last_known_position: Vector2 = Vector2.ZERO

	## 移動
	var current_path: PackedVector2Array = PackedVector2Array()
	var path_index: int = 0
	var is_moving: bool = false
	var use_road_only: bool = false
	var is_reversing: bool = false  ## 後退中フラグ（正面を維持して後退）
	var break_contact_smoke_requested: bool = false  ## 離脱時の煙幕要請

	## 命令
	var current_order_type: GameEnums.OrderType = GameEnums.OrderType.HOLD
	var order_target_position: Vector2 = Vector2.ZERO
	var order_target_id: String = ""  ## 命令の対象ID（ATTACKコマンドなど）
	var pending_move_order: Dictionary = {}  ## SACLOS誘導中の待機移動命令 {target: Vector2, use_route: bool}

	## 戦闘
	var primary_weapon: WeaponData.WeaponType = null  ## 主武装（後方互換）
	var weapons: Array[WeaponData.WeaponType] = []    ## 全武装リスト
	var current_weapon: WeaponData.WeaponType = null  ## 現在使用中の武器
	var current_target_id: String = ""  ## 現在の射撃目標
	var forced_target_id: String = ""  ## プレイヤー指定の強制交戦目標
	var atgm_guided_target_id: String = ""  ## ATGM誘導中のターゲット（移動中も表示用に保持）
	var last_fire_tick: int = -1  ## 最後に射撃したtick
	var last_hit_tick: int = 0    ## 最後に被弾したtick（RETURN_FIRE判定用）
	var sop_mode: GameEnums.SOPMode = GameEnums.SOPMode.FIRE_AT_WILL  ## 射撃ルール
	var accumulated_damage: float = 0.0  ## 蓄積ダメージ（1.0超過でstrength-1）
	var accumulated_armor_damage: float = 0.0  ## 連続射撃の装甲ダメージ蓄積（1.0超過で車両ダメージ判定）

	## v0.1R: 車両サブシステムHP（armor_class >= 1 の場合のみ使用）
	var mobility_hp: int = 100      ## 機動力HP (0-100)
	var firepower_hp: int = 100     ## 火力HP (0-100)
	var sensors_hp: int = 100       ## センサーHP (0-100)

	## 破壊関連
	var is_destroyed: bool = false       ## 完全破壊フラグ（フェードアウト開始）
	var destroy_tick: int = -1           ## 破壊開始tick
	var catastrophic_kill: bool = false  ## 爆発・炎上による破壊か（車両用）

	## 通信状態（データリンク）
	var comm_state: GameEnums.CommState = GameEnums.CommState.LINKED  ## 現在の通信状態
	var comm_hub_id: String = ""         ## 接続先ハブID（空の場合はハブなし）

	## 兵器カタログ
	var vehicle_id: String = ""          ## カタログ車両ID（例: "JPN_Type10"）

	## 弾薬状態
	## 仕様: docs/ammunition_system_v0.1.md
	var ammo_state = null  ## AmmoState型（循環参照回避のため型指定なし）

	## 補給ユニット設定（LOG_TRUCK用）
	var supply_config: Dictionary = {}  ## {capacity, supply_range_m, ammo_resupply_rate, fuel_resupply_rate}
	var supply_remaining: int = 0       ## 残り補給容量（補給実行で減少）

	## 搭乗・輸送関連
	var embarked_infantry_id: String = ""  ## 搭乗中の歩兵ユニットID（IFV/APC用）
	var transport_vehicle_id: String = ""  ## 乗車中の車両ID（歩兵用）
	var is_embarked: bool = false          ## 乗車中フラグ（歩兵用、trueの場合は非表示）
	var boarding_target_id: String = ""    ## 乗車移動中の目標車両ID（歩兵用）
	var unloading_target_pos: Vector2 = Vector2.ZERO  ## 下車移動中の目標位置（歩兵用）
	var awaiting_boarding_id: String = ""  ## 乗車待機中の歩兵ID（車両用、衝突回避除外用）

	## 間接射撃（砲兵用）
	var fire_mission_target: Vector2 = Vector2.ZERO  ## 間接射撃の目標位置（Vector2.ZEROなら未指定）
	var fire_mission_active: bool = false            ## 間接射撃任務が有効か

	## 砲兵展開状態
	## STOWED: 収納状態（移動可能、射撃不可）
	## DEPLOYING: 展開中（移動不可、射撃不可）
	## DEPLOYED: 展開完了（移動不可、射撃可能）
	## PACKING: 撤収中（移動不可、射撃不可）
	enum ArtilleryDeployState { STOWED, DEPLOYING, DEPLOYED, PACKING }
	var artillery_deploy_state: ArtilleryDeployState = ArtilleryDeployState.STOWED
	var artillery_deploy_progress: float = 0.0       ## 展開/撤収の進捗（0.0〜1.0）
	var artillery_deploy_time_sec: float = 30.0      ## 展開にかかる時間（秒）
	var artillery_pack_time_sec: float = 30.0        ## 撤収にかかる時間（秒）

	## 初期化
	func _init(p_type: ElementType = null) -> void:
		# 重要: 型付き配列はインスタンスごとに新しく初期化する必要がある
		weapons = []
		current_path = PackedVector2Array()

		if p_type:
			element_type = p_type
			current_strength = p_type.max_strength
			# v0.1R: 車両サブシステムHPを初期化
			mobility_hp = 100
			firepower_hp = 100
			sensors_hp = 100


	## シンボル名を取得 (SVGファイル名用)
	func get_symbol_name(viewer_faction: GameEnums.Faction) -> String:
		if not element_type:
			return "inf_rifle_unknown_sus"

		var type_str := _symbol_type_to_string(element_type.symbol_type)
		var affiliation := _get_affiliation_string(viewer_faction)
		var state_str := _get_contact_state_string()

		return "%s_%s_%s" % [type_str, affiliation, state_str]


	func _symbol_type_to_string(st: SymbolType) -> String:
		match st:
			SymbolType.INF_RIFLE: return "inf_rifle"
			SymbolType.INF_MECH: return "inf_mech"
			SymbolType.INF_RECON: return "inf_recon"
			SymbolType.INF_ENGINEER: return "inf_engineer"
			SymbolType.ARMOR_TANK: return "armor_tank"
			SymbolType.ARMOR_IFV: return "armor_ifv"
			SymbolType.ARMOR_APC: return "armor_apc"
			SymbolType.FS_MORTAR: return "fs_mortar"
			SymbolType.FS_ATGM: return "fs_atgm"
			SymbolType.FS_ARTILLERY: return "fs_artillery"
			SymbolType.RECON_UAV: return "recon_uav"
			SymbolType.SUP_LOGISTICS: return "sup_logistics"
			SymbolType.SUP_MEDEVAC: return "sup_medevac"
			SymbolType.CMD_HQ: return "cmd_hq"
			_: return "inf_rifle"


	func _get_affiliation_string(viewer_faction: GameEnums.Faction) -> String:
		if viewer_faction == GameEnums.Faction.NONE:
			return "unknown"
		if faction == viewer_faction:
			return "friendly"
		elif faction == GameEnums.Faction.NONE:
			return "unknown"
		else:
			return "hostile"


	func _get_contact_state_string() -> String:
		match contact_state:
			GameEnums.ContactState.CONFIRMED:
				return "conf"
			_:
				return "sus"


	## 移動速度を取得 (地形考慮)
	func get_speed(terrain: GameEnums.TerrainType) -> float:
		if not element_type:
			return 3.0

		match terrain:
			GameEnums.TerrainType.ROAD:
				return element_type.road_speed
			GameEnums.TerrainType.OPEN:
				return element_type.cross_speed
			GameEnums.TerrainType.FOREST:
				if element_type.mobility_class == GameEnums.MobilityType.FOOT:
					return element_type.cross_speed * 0.6
				else:
					return element_type.cross_speed * 0.4
			GameEnums.TerrainType.URBAN:
				return element_type.cross_speed * 0.5
			_:
				return element_type.cross_speed


	## 状態を保存 (補間用)
	func save_prev_state() -> void:
		prev_position = position
		prev_facing = facing


	## 補間位置を取得
	func get_interpolated_position(alpha: float) -> Vector2:
		return prev_position.lerp(position, alpha)


	## 補間角度を取得
	func get_interpolated_facing(alpha: float) -> float:
		return lerp_angle(prev_facing, facing, alpha)


	## 車両かどうか（装甲の有無に関係なく、WHEELED/TRACKED = 車両）
	## LOG_TRUCK（ソフトスキン）も車両として扱う
	func is_vehicle() -> bool:
		if not element_type:
			return false
		return element_type.mobility_class == GameEnums.MobilityType.WHEELED or \
			   element_type.mobility_class == GameEnums.MobilityType.TRACKED


	## ソフトスキン車両かどうか（armor_class = 0 の車両）
	## トラック、ジープ、非装甲HQ車両など
	## 小銃弾で貫通可能、破壊しやすい
	func is_soft_skin_vehicle() -> bool:
		if not element_type:
			return false
		return is_vehicle() and element_type.armor_class == 0


	## 装甲車両かどうか（armor_class >= 1）
	## 戦車、IFV、装甲偵察車両など
	## ソフトスキン車両（トラック等）は含まない
	func is_armored_vehicle() -> bool:
		if not element_type:
			return false
		return is_vehicle() and element_type.armor_class >= 1


	## 軽装甲車両かどうか（armor_class = 1-2）
	## 装甲偵察車、IFV、APC等
	## 小銃弾に耐えるが、12.7mm/機関砲で貫通可能
	func is_light_armor() -> bool:
		if not element_type:
			return false
		return element_type.armor_class >= 1 and element_type.armor_class <= 2


	## 重装甲車両かどうか（armor_class >= 3）
	## 戦車のみ - 抑圧耐性が高く、小火器/機関砲では貫通困難
	func is_heavy_armor() -> bool:
		if not element_type:
			return false
		return element_type.armor_class >= 3


	## v0.1R: 表示用Strength
	## 歩兵: 人数（例: 30人小隊 → Strength=30）
	## 車両: 車両数（例: 4両小隊 → Strength=4）
	func get_display_strength() -> int:
		return current_strength


# =============================================================================
# ElementArchetypes（JSONローダー・SSoT対応）
# 仕様書: docs/units_v0.1.md, docs/concrete_weapons_v0.1.md
# =============================================================================

class ElementArchetypes:
	const ARCHETYPES_JSON_PATH := "res://data/archetypes/element_archetypes.json"

	static var _archetypes: Dictionary = {}
	static var _json_loaded: bool = false


	## JSONファイルからアーキタイプデータを読み込む
	static func _ensure_json_loaded() -> void:
		if _json_loaded:
			return

		var file := FileAccess.open(ARCHETYPES_JSON_PATH, FileAccess.READ)
		if not file:
			push_error("Cannot open archetypes JSON: %s" % ARCHETYPES_JSON_PATH)
			return

		var json_text := file.get_as_text()
		file.close()

		var json := JSON.new()
		var error := json.parse(json_text)
		if error != OK:
			push_error("JSON parse error in %s: %s" % [ARCHETYPES_JSON_PATH, json.get_error_message()])
			return

		var archetypes_array: Array = json.data
		for archetype_data in archetypes_array:
			var archetype := _dict_to_element_type(archetype_data)
			_archetypes[archetype.id] = archetype

		_json_loaded = true
		print("Loaded %d archetypes from JSON" % _archetypes.size())


	## DictionaryをElementTypeに変換
	static func _dict_to_element_type(data: Dictionary) -> ElementType:
		var t := ElementType.new()

		t.id = data.get("id", "")
		t.display_name = data.get("display_name", "")
		t.category = _string_to_category(data.get("category", "INF"))
		t.symbol_type = _string_to_symbol_type(data.get("symbol_type", "INF_RIFLE"))
		t.mobility_class = _string_to_mobility(data.get("mobility_class", "FOOT"))
		t.armor_class = data.get("armor_class", 0)
		t.road_speed = data.get("road_speed", 5.0)
		t.cross_speed = data.get("cross_speed", 3.0)
		t.base_strength = data.get("base_strength", 100)
		t.max_strength = data.get("max_strength", 100)
		t.spot_range_base = data.get("spot_range_base", 300.0)
		t.spot_range_moving = data.get("spot_range_moving", 200.0)

		# 通信ハブ設定
		t.is_comm_hub = data.get("is_comm_hub", false)
		t.comm_range = data.get("comm_range", 2000.0)

		# 輸送能力
		t.can_transport_infantry = data.get("can_transport_infantry", false)
		t.transport_capacity = data.get("transport_capacity", 0)

		# 装甲データ
		if data.has("armor_ke"):
			t.armor_ke = _dict_to_armor(data.armor_ke)
		if data.has("armor_ce"):
			t.armor_ce = _dict_to_armor(data.armor_ce)

		return t


	## 装甲DictionaryをArmorZone enumキーに変換
	static func _dict_to_armor(data: Dictionary) -> Dictionary:
		var result := {}
		for zone_str in data:
			var zone := _string_to_armor_zone(zone_str)
			result[zone] = data[zone_str]
		return result


	## 文字列をCategoryに変換
	static func _string_to_category(s: String) -> Category:
		match s:
			"INF": return Category.INF
			"VEH": return Category.VEH
			"REC": return Category.REC
			"WEAP": return Category.WEAP
			"ENG": return Category.ENG
			"LOG": return Category.LOG
			"HQ": return Category.HQ
			_: return Category.INF


	## 文字列をSymbolTypeに変換
	static func _string_to_symbol_type(s: String) -> SymbolType:
		match s:
			"INF_RIFLE": return SymbolType.INF_RIFLE
			"INF_MECH": return SymbolType.INF_MECH
			"INF_RECON": return SymbolType.INF_RECON
			"INF_ENGINEER": return SymbolType.INF_ENGINEER
			"ARMOR_TANK": return SymbolType.ARMOR_TANK
			"ARMOR_IFV": return SymbolType.ARMOR_IFV
			"ARMOR_APC": return SymbolType.ARMOR_APC
			"FS_MORTAR": return SymbolType.FS_MORTAR
			"FS_ATGM": return SymbolType.FS_ATGM
			"FS_ARTILLERY": return SymbolType.FS_ARTILLERY
			"RECON_UAV": return SymbolType.RECON_UAV
			"SUP_LOGISTICS": return SymbolType.SUP_LOGISTICS
			"SUP_MEDEVAC": return SymbolType.SUP_MEDEVAC
			"CMD_HQ": return SymbolType.CMD_HQ
			_: return SymbolType.INF_RIFLE


	## 文字列をMobilityTypeに変換
	static func _string_to_mobility(s: String) -> GameEnums.MobilityType:
		match s:
			"FOOT": return GameEnums.MobilityType.FOOT
			"WHEELED": return GameEnums.MobilityType.WHEELED
			"TRACKED": return GameEnums.MobilityType.TRACKED
			_: return GameEnums.MobilityType.FOOT


	## 文字列をArmorZoneに変換
	static func _string_to_armor_zone(s: String) -> WeaponData.ArmorZone:
		match s:
			"FRONT": return WeaponData.ArmorZone.FRONT
			"SIDE": return WeaponData.ArmorZone.SIDE
			"REAR": return WeaponData.ArmorZone.REAR
			"TOP": return WeaponData.ArmorZone.TOP
			_: return WeaponData.ArmorZone.FRONT


	## 全アーキタイプを取得（SSoT対応：JSONから読み込み）
	static func get_all_archetypes() -> Dictionary:
		_ensure_json_loaded()
		return _archetypes


	## IDからアーキタイプを取得（SSoT対応：JSONから読み込み）
	static func get_archetype(archetype_id: String) -> ElementType:
		_ensure_json_loaded()
		if archetype_id in _archetypes:
			return _archetypes[archetype_id]
		# デフォルト: INF_LINE
		if "INF_LINE" in _archetypes:
			return _archetypes["INF_LINE"]
		return ElementType.new()
