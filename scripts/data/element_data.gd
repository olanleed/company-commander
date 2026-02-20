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

	## 戦闘
	var primary_weapon: WeaponData.WeaponType = null  ## 主武装
	var current_target_id: String = ""  ## 現在の射撃目標
	var last_fire_tick: int = -1  ## 最後に射撃したtick
	var sop_mode: GameEnums.SOPMode = GameEnums.SOPMode.FIRE_AT_WILL  ## 射撃ルール
	var accumulated_damage: float = 0.0  ## 蓄積ダメージ（1.0超過でstrength-1）

	## v0.1R: 車両サブシステムHP（armor_class >= 1 の場合のみ使用）
	var mobility_hp: int = 100      ## 機動力HP (0-100)
	var firepower_hp: int = 100     ## 火力HP (0-100)
	var sensors_hp: int = 100       ## センサーHP (0-100)

	## 初期化
	func _init(p_type: ElementType = null) -> void:
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
