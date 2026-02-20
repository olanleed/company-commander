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

	## Protection
	var armor_class: int = 0  # 0=ソフト, 1=軽装甲, 2=中装甲, 3=重装甲

	## v0.1R: ゾーン別装甲（0-100レーティング）
	## 仕様書: docs/damage_model_v0.1.md
	## ArmorZone.FRONT/SIDE/REAR/TOP → rating
	var armor_ke: Dictionary = {}  # KINETICに対する装甲
	var armor_ce: Dictionary = {}  # SHAPED_CHARGEに対する装甲

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

	## 命令
	var current_order_type: GameEnums.OrderType = GameEnums.OrderType.HOLD
	var order_target_position: Vector2 = Vector2.ZERO
	var order_target_id: String = ""  ## 命令の対象ID（ATTACKコマンドなど）

	## 戦闘
	var primary_weapon: WeaponData.WeaponType = null  ## 主武装（後方互換）
	var weapons: Array[WeaponData.WeaponType] = []    ## 全武装リスト
	var current_weapon: WeaponData.WeaponType = null  ## 現在使用中の武器
	var current_target_id: String = ""  ## 現在の射撃目標
	var forced_target_id: String = ""  ## プレイヤー指定の強制交戦目標
	var last_fire_tick: int = -1  ## 最後に射撃したtick
	var sop_mode: GameEnums.SOPMode = GameEnums.SOPMode.FIRE_AT_WILL  ## 射撃ルール
	var accumulated_damage: float = 0.0  ## 蓄積ダメージ（1.0超過でstrength-1）

	## v0.1R: 車両サブシステムHP（armor_class >= 1 の場合のみ使用）
	var mobility_hp: int = 100      ## 機動力HP (0-100)
	var firepower_hp: int = 100     ## 火力HP (0-100)
	var sensors_hp: int = 100       ## センサーHP (0-100)

	## 破壊関連
	var is_destroyed: bool = false       ## 完全破壊フラグ（フェードアウト開始）
	var destroy_tick: int = -1           ## 破壊開始tick
	var catastrophic_kill: bool = false  ## 爆発・炎上による破壊か（車両用）

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


	## v0.1R: 車両かどうか
	func is_vehicle() -> bool:
		if not element_type:
			return false
		return element_type.armor_class >= 1


	## v0.1R: 表示用Strength（車両はサブシステムHP平均）
	func get_display_strength() -> int:
		if is_vehicle():
			return clampi((mobility_hp + firepower_hp + sensors_hp) / 3, 0, 100)
		return current_strength


# =============================================================================
# ElementArchetypes（8種のユニットアーキタイプ）
# 仕様書: docs/units_v0.1.md, docs/concrete_weapons_v0.1.md
# =============================================================================

class ElementArchetypes:
	## INF_LINE: ライフル分隊（9人）
	static func create_inf_line() -> ElementType:
		var t := ElementType.new()
		t.id = "INF_LINE"
		t.display_name = "Rifle Squad"
		t.category = Category.INF
		t.symbol_type = SymbolType.INF_RIFLE
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 5.0   # m/s
		t.cross_speed = 3.5  # m/s
		t.base_strength = 9
		t.max_strength = 9   # 9人分隊
		t.spot_range_base = 300.0
		t.spot_range_moving = 200.0
		return t

	## INF_AT: 対戦車分隊（4人）
	static func create_inf_at() -> ElementType:
		var t := ElementType.new()
		t.id = "INF_AT"
		t.display_name = "AT Team"
		t.category = Category.INF
		t.symbol_type = SymbolType.FS_ATGM
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 4.5
		t.cross_speed = 3.0
		t.base_strength = 4
		t.max_strength = 4
		t.spot_range_base = 400.0
		t.spot_range_moving = 250.0
		return t

	## INF_MG: 機関銃班（3人）
	static func create_inf_mg() -> ElementType:
		var t := ElementType.new()
		t.id = "INF_MG"
		t.display_name = "MG Team"
		t.category = Category.WEAP
		t.symbol_type = SymbolType.INF_RIFLE  # MGシンボルがない場合
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 4.0
		t.cross_speed = 2.5
		t.base_strength = 3
		t.max_strength = 3
		t.spot_range_base = 350.0
		t.spot_range_moving = 200.0
		return t

	## TANK_PLT: 戦車小隊（4両=1ユニット）
	static func create_tank_plt() -> ElementType:
		var t := ElementType.new()
		t.id = "TANK_PLT"
		t.display_name = "Tank Platoon"
		t.category = Category.VEH
		t.symbol_type = SymbolType.ARMOR_TANK
		t.armor_class = 3  # Heavy
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 12.0
		t.cross_speed = 8.0
		t.base_strength = 100  # 車両HP（サブシステム管理）
		t.max_strength = 100
		t.spot_range_base = 800.0
		t.spot_range_moving = 600.0
		# v0.1R: ゾーン別装甲（MBT相当）
		# 正面は強固、側面は中程度、後方は弱い
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 95,
			WeaponData.ArmorZone.SIDE: 55,
			WeaponData.ArmorZone.REAR: 25,
			WeaponData.ArmorZone.TOP: 15,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 90,
			WeaponData.ArmorZone.SIDE: 50,
			WeaponData.ArmorZone.REAR: 20,
			WeaponData.ArmorZone.TOP: 10,
		}
		return t

	## RECON_VEH: 偵察車両（軽装甲）
	static func create_recon_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "RECON_VEH"
		t.display_name = "Recon Vehicle"
		t.category = Category.REC
		t.symbol_type = SymbolType.INF_RECON
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 18.0
		t.cross_speed = 10.0
		t.base_strength = 100
		t.max_strength = 100
		t.spot_range_base = 1000.0
		t.spot_range_moving = 800.0
		# v0.1R: ゾーン別装甲（軽装甲車両相当）
		# 小銃弾には耐えるが、AT火器には脆弱
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 30,
			WeaponData.ArmorZone.SIDE: 20,
			WeaponData.ArmorZone.REAR: 10,
			WeaponData.ArmorZone.TOP: 5,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 25,
			WeaponData.ArmorZone.SIDE: 15,
			WeaponData.ArmorZone.REAR: 8,
			WeaponData.ArmorZone.TOP: 5,
		}
		return t

	## RECON_TEAM: 偵察チーム（4人）
	static func create_recon_team() -> ElementType:
		var t := ElementType.new()
		t.id = "RECON_TEAM"
		t.display_name = "Recon Team"
		t.category = Category.REC
		t.symbol_type = SymbolType.INF_RECON
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 5.5
		t.cross_speed = 4.0
		t.base_strength = 4
		t.max_strength = 4
		t.spot_range_base = 500.0
		t.spot_range_moving = 350.0
		return t

	## MORTAR_SEC: 迫撃砲班（6人 + 2門）
	static func create_mortar_sec() -> ElementType:
		var t := ElementType.new()
		t.id = "MORTAR_SEC"
		t.display_name = "Mortar Section"
		t.category = Category.WEAP
		t.symbol_type = SymbolType.FS_MORTAR
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 3.5
		t.cross_speed = 2.0
		t.base_strength = 6
		t.max_strength = 6
		t.spot_range_base = 200.0
		t.spot_range_moving = 100.0
		return t

	## LOG_TRUCK: 補給トラック
	static func create_log_truck() -> ElementType:
		var t := ElementType.new()
		t.id = "LOG_TRUCK"
		t.display_name = "Supply Truck"
		t.category = Category.LOG
		t.symbol_type = SymbolType.SUP_LOGISTICS
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 15.0
		t.cross_speed = 6.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 150.0
		t.spot_range_moving = 100.0
		return t

	## 全アーキタイプを取得
	static func get_all_archetypes() -> Dictionary:
		return {
			"INF_LINE": create_inf_line(),
			"INF_AT": create_inf_at(),
			"INF_MG": create_inf_mg(),
			"TANK_PLT": create_tank_plt(),
			"RECON_VEH": create_recon_veh(),
			"RECON_TEAM": create_recon_team(),
			"MORTAR_SEC": create_mortar_sec(),
			"LOG_TRUCK": create_log_truck(),
		}

	## IDからアーキタイプを取得
	static func get_archetype(archetype_id: String) -> ElementType:
		match archetype_id:
			"INF_LINE": return create_inf_line()
			"INF_AT": return create_inf_at()
			"INF_MG": return create_inf_mg()
			"TANK_PLT": return create_tank_plt()
			"RECON_VEH": return create_recon_veh()
			"RECON_TEAM": return create_recon_team()
			"MORTAR_SEC": return create_mortar_sec()
			"LOG_TRUCK": return create_log_truck()
			_: return create_inf_line()  # デフォルト
