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
# ElementArchetypes（8種のユニットアーキタイプ）
# 仕様書: docs/units_v0.1.md, docs/concrete_weapons_v0.1.md
# =============================================================================

class ElementArchetypes:
	## INF_LINE: ライフル小隊（30人）
	## 3分隊 + 小隊本部(PL, PSG, RTO)
	static func create_inf_line() -> ElementType:
		var t := ElementType.new()
		t.id = "INF_LINE"
		t.display_name = "Rifle Platoon"
		t.category = Category.INF
		t.symbol_type = SymbolType.INF_RIFLE
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.FOOT
		t.road_speed = 5.0   # m/s
		t.cross_speed = 3.5  # m/s
		t.base_strength = 30
		t.max_strength = 30   # 30人小隊
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
	## RHA換算装甲値（スケール: 100 = 500mm RHA）
	## M1A2/レオパルト2相当の第3世代MBT
	## 正面は複合装甲で非常に強固、側面/後部はLAWでも貫通可能
	## Strength = 車両数（4両）- 1両撃破ごとに-1
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
		t.base_strength = 4   # 車両数（4両/小隊）
		t.max_strength = 4
		t.spot_range_base = 800.0
		t.spot_range_moving = 600.0
		# v0.1R: ゾーン別装甲（RHA換算, スケール: 100 = 500mm）
		# KE（APFSDS等）に対する装甲
		# 正面: 約700mm RHA = 140, 側面: 約200mm = 40, 後部: 約80mm = 16
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 140,  # 700mm RHA - APFSDSでも貫通困難
			WeaponData.ArmorZone.SIDE: 40,    # 200mm RHA - 機関砲で貫通可能
			WeaponData.ArmorZone.REAR: 16,    # 80mm RHA - 脆弱
			WeaponData.ArmorZone.TOP: 6,      # 30mm RHA - トップアタックに弱い
		}
		# CE（HEAT/RPG等）に対する装甲（ERAなしの場合）
		# 正面: 約700mm RHA = 140, 側面: 約120mm = 24, 後部: 約40mm = 8
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 140,  # 700mm RHA相当 - LAWは貫通不可
			WeaponData.ArmorZone.SIDE: 24,    # 120mm RHA相当 - LAW(60)で確実に貫通
			WeaponData.ArmorZone.REAR: 8,     # 40mm RHA相当 - LAWで確実に貫通
			WeaponData.ArmorZone.TOP: 4,      # 20mm RHA相当 - 極めて脆弱
		}
		return t

	## IFV_PLT: 歩兵戦闘車小隊（4両=1ユニット）
	## RHA換算装甲値（スケール: 100 = 500mm RHA）
	## BMP-3/89式/Bradley相当のIFV
	## 機関砲+ATGMを装備、中装甲
	## Strength = 車両数（4両）- 1両撃破ごとに-1
	static func create_ifv_plt() -> ElementType:
		var t := ElementType.new()
		t.id = "IFV_PLT"
		t.display_name = "IFV Platoon"
		t.category = Category.VEH
		t.symbol_type = SymbolType.ARMOR_IFV
		t.armor_class = 2  # Medium
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 14.0
		t.cross_speed = 9.0
		t.base_strength = 4   # 車両数（4両/小隊）
		t.max_strength = 4
		t.spot_range_base = 700.0
		t.spot_range_moving = 500.0
		# v0.1R: ゾーン別装甲（RHA換算, スケール: 100 = 500mm）
		# KE（機関砲等）に対する装甲
		# 正面: 約150mm RHA = 30, 側面: 約50mm = 10, 後部: 約30mm = 6
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 30,   # 150mm RHA - 30mm機関砲に耐える
			WeaponData.ArmorZone.SIDE: 10,    # 50mm RHA - 14.5mmHMGに耐える
			WeaponData.ArmorZone.REAR: 6,     # 30mm RHA - 12.7mmで危険
			WeaponData.ArmorZone.TOP: 3,      # 15mm RHA - 砲弾破片に脆弱
		}
		# CE（HEAT/RPG等）に対する装甲
		# 正面: 約200mm RHA = 40, 側面: 約60mm = 12, 後部: 約30mm = 6
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 40,   # 200mm RHA相当 - LAW(60)で貫通
			WeaponData.ArmorZone.SIDE: 12,    # 60mm RHA相当 - LAW(60)で確実貫通
			WeaponData.ArmorZone.REAR: 6,     # 30mm RHA相当 - RPG-7で確実貫通
			WeaponData.ArmorZone.TOP: 3,      # 15mm RHA相当 - トップアタックに脆弱
		}
		return t

	## RECON_VEH: 偵察車両（軽装甲）
	## RHA換算装甲値（スケール: 100 = 500mm RHA）
	## BRDM/LAV相当の軽装甲偵察車両
	## 小銃弾には耐えるが、AT火器には脆弱
	## Strength = 車両数（2両）- 1両撃破ごとに-1
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
		t.base_strength = 2   # 車両数（2両/分隊）
		t.max_strength = 2
		t.spot_range_base = 1000.0
		t.spot_range_moving = 800.0
		# v0.1R: ゾーン別装甲（RHA換算, スケール: 100 = 500mm）
		# 軽装甲: 7.62mmには耐えるが12.7mmで貫通、AT火器には無力
		# KE（機関砲等）に対する装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,    # 30mm RHA - 12.7mm HMGで貫通
			WeaponData.ArmorZone.SIDE: 3,     # 15mm RHA - 12.7mmで貫通
			WeaponData.ArmorZone.REAR: 2,     # 10mm RHA - 7.62mmでも危険
			WeaponData.ArmorZone.TOP: 1,      # 5mm RHA - 破片弾にも脆弱
		}
		# CE（HEAT/RPG等）に対する装甲
		# LAW(60)でも全方位から確実に貫通
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,    # 25mm RHA相当
			WeaponData.ArmorZone.SIDE: 3,     # 15mm RHA相当
			WeaponData.ArmorZone.REAR: 2,     # 10mm RHA相当
			WeaponData.ArmorZone.TOP: 1,      # 5mm RHA相当
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

	## CMD_HQ: 中隊本部（通信ハブ）
	## データリンクの中心となる指揮ユニット
	## comm_range内の全ユニットとLINK状態を維持
	static func create_cmd_hq() -> ElementType:
		var t := ElementType.new()
		t.id = "CMD_HQ"
		t.display_name = "Company HQ"
		t.category = Category.HQ
		t.symbol_type = SymbolType.CMD_HQ
		t.armor_class = 0  # Soft（装甲車に搭乗なら別途設定）
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 12.0
		t.cross_speed = 6.0
		t.base_strength = 4   # HQ要員4名
		t.max_strength = 4
		t.spot_range_base = 300.0
		t.spot_range_moving = 200.0
		# 通信ハブ設定
		t.is_comm_hub = true
		t.comm_range = 3000.0  # 3km通信範囲
		return t

	## APC_PLT: 装甲兵員輸送車小隊（4両=1ユニット）
	## RHA換算装甲値（スケール: 100 = 500mm RHA）
	## M113/BTR-80相当のAPC
	## 輸送任務が主、軽火器のみ装備
	## Strength = 車両数（4両）- 1両撃破ごとに-1
	static func create_apc_plt() -> ElementType:
		var t := ElementType.new()
		t.id = "APC_PLT"
		t.display_name = "APC Platoon"
		t.category = Category.VEH
		t.symbol_type = SymbolType.ARMOR_APC
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 13.0
		t.cross_speed = 8.0
		t.base_strength = 4
		t.max_strength = 4
		t.spot_range_base = 500.0
		t.spot_range_moving = 350.0
		# KE装甲（軽装甲: 7.62mm防護、14.5mm正面のみ）
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 8,    # 40mm RHA - 14.5mm HMGに耐える
			WeaponData.ArmorZone.SIDE: 4,     # 20mm RHA - 7.62mmに耐える
			WeaponData.ArmorZone.REAR: 3,     # 15mm RHA - 小銃弾に耐える
			WeaponData.ArmorZone.TOP: 2,      # 10mm RHA - 破片に脆弱
		}
		# CE装甲
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 6,    # 30mm RHA相当
			WeaponData.ArmorZone.SIDE: 4,     # 20mm RHA相当
			WeaponData.ArmorZone.REAR: 3,     # 15mm RHA相当
			WeaponData.ArmorZone.TOP: 2,      # 10mm RHA相当
		}
		return t

	## LIGHT_VEH: 軽装甲車両（4両=1ユニット）
	## ハンヴィー/軽装甲機動車相当
	## 最低限の装甲（7.62mm防護）、高機動性
	static func create_light_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "LIGHT_VEH"
		t.display_name = "Light Vehicle"
		t.category = Category.VEH
		t.symbol_type = SymbolType.INF_MECH
		t.armor_class = 1  # Light（最低限の装甲）
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 20.0
		t.cross_speed = 10.0
		t.base_strength = 4
		t.max_strength = 4
		t.spot_range_base = 400.0
		t.spot_range_moving = 300.0
		# 軽装甲（7.62mm防護のみ）
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 3,    # 15mm RHA - 7.62mmにかろうじて耐える
			WeaponData.ArmorZone.SIDE: 2,     # 10mm RHA
			WeaponData.ArmorZone.REAR: 2,     # 10mm RHA
			WeaponData.ArmorZone.TOP: 1,      # 5mm RHA
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 3,
			WeaponData.ArmorZone.SIDE: 2,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## COMMAND_VEH: 指揮通信車（1両=1ユニット）
	## 82式指揮通信車相当
	## 通信ハブ機能、軽装甲
	static func create_command_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "COMMAND_VEH"
		t.display_name = "Command Vehicle"
		t.category = Category.HQ
		t.symbol_type = SymbolType.CMD_HQ
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 16.0
		t.cross_speed = 8.0
		t.base_strength = 1
		t.max_strength = 1
		t.spot_range_base = 600.0
		t.spot_range_moving = 400.0
		t.is_comm_hub = true
		t.comm_range = 5000.0  # 5km通信範囲
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,
			WeaponData.ArmorZone.SIDE: 3,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## SP_MORTAR: 自走迫撃砲（2両=1ユニット）
	## 120mm自走迫撃砲相当
	## 間接射撃能力、軽装甲
	static func create_sp_mortar() -> ElementType:
		var t := ElementType.new()
		t.id = "SP_MORTAR"
		t.display_name = "SP Mortar"
		t.category = Category.WEAP
		t.symbol_type = SymbolType.FS_MORTAR
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 14.0
		t.cross_speed = 7.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 400.0
		t.spot_range_moving = 250.0
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,
			WeaponData.ArmorZone.SIDE: 3,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## SP_ARTILLERY: 自走砲（2両=1ユニット）
	## 155mm自走榴弾砲相当
	## 長距離間接射撃能力、中装甲
	static func create_sp_artillery() -> ElementType:
		var t := ElementType.new()
		t.id = "SP_ARTILLERY"
		t.display_name = "SP Artillery"
		t.category = Category.WEAP
		t.symbol_type = SymbolType.FS_ARTILLERY
		t.armor_class = 2  # Medium
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 10.0
		t.cross_speed = 6.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 500.0
		t.spot_range_moving = 300.0
		# 中装甲（破片防護）
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 12,   # 60mm RHA
			WeaponData.ArmorZone.SIDE: 8,     # 40mm RHA
			WeaponData.ArmorZone.REAR: 6,     # 30mm RHA
			WeaponData.ArmorZone.TOP: 4,      # 20mm RHA
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 10,
			WeaponData.ArmorZone.SIDE: 6,
			WeaponData.ArmorZone.REAR: 4,
			WeaponData.ArmorZone.TOP: 3,
		}
		return t

	## SPAAG: 自走高射機関砲（2両=1ユニット）
	## 87式/ゲパルト相当
	## 対空射撃能力、地上目標にも有効
	static func create_spaag() -> ElementType:
		var t := ElementType.new()
		t.id = "SPAAG"
		t.display_name = "SPAAG"
		t.category = Category.VEH
		t.symbol_type = SymbolType.ARMOR_IFV  # 専用シンボルがないためIFVを流用
		t.armor_class = 2  # Medium
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 10.0
		t.cross_speed = 6.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 800.0  # レーダー搭載で長距離索敵
		t.spot_range_moving = 600.0
		# 中装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 14,
			WeaponData.ArmorZone.SIDE: 8,
			WeaponData.ArmorZone.REAR: 6,
			WeaponData.ArmorZone.TOP: 4,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 12,
			WeaponData.ArmorZone.SIDE: 6,
			WeaponData.ArmorZone.REAR: 4,
			WeaponData.ArmorZone.TOP: 3,
		}
		return t

	## SAM_VEH: 地対空ミサイル車両（1両=1ユニット）
	## 93式/11式短SAM相当
	## 対空ミサイル装備、軽装甲
	static func create_sam_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "SAM_VEH"
		t.display_name = "SAM Vehicle"
		t.category = Category.VEH
		t.symbol_type = SymbolType.FS_ATGM  # 専用シンボルがないためATGMを流用
		t.armor_class = 0  # Soft（軽車両ベース）
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 16.0
		t.cross_speed = 8.0
		t.base_strength = 1
		t.max_strength = 1
		t.spot_range_base = 1000.0  # レーダー搭載
		t.spot_range_moving = 800.0
		# ソフトスキン（装甲なし）
		return t

	## LIGHT_TANK: 軽戦車小隊（4両=1ユニット）
	## Type 15/M8 AGS相当
	## 105mm主砲、中装甲、高機動性
	static func create_light_tank() -> ElementType:
		var t := ElementType.new()
		t.id = "LIGHT_TANK"
		t.display_name = "Light Tank Platoon"
		t.category = Category.VEH
		t.symbol_type = SymbolType.ARMOR_TANK
		t.armor_class = 2  # Medium (軽戦車なのでMBTより軽い)
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 14.0  # MBTより高速
		t.cross_speed = 10.0
		t.base_strength = 4
		t.max_strength = 4
		t.spot_range_base = 750.0
		t.spot_range_moving = 550.0
		# v0.1R: 中装甲（MBTより脆弱）
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 60,   # 300mm RHA - 30mmに耐える
			WeaponData.ArmorZone.SIDE: 20,    # 100mm RHA
			WeaponData.ArmorZone.REAR: 10,    # 50mm RHA
			WeaponData.ArmorZone.TOP: 4,      # 20mm RHA
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 70,   # 350mm RHA - ATGM/LAWで貫通
			WeaponData.ArmorZone.SIDE: 20,    # 100mm RHA
			WeaponData.ArmorZone.REAR: 8,     # 40mm RHA
			WeaponData.ArmorZone.TOP: 3,      # 15mm RHA
		}
		return t

	## MLRS: 多連装ロケット砲（2両=1ユニット）
	## MLRS/BM-21相当
	## 面制圧能力、軽装甲
	static func create_mlrs() -> ElementType:
		var t := ElementType.new()
		t.id = "MLRS"
		t.display_name = "MLRS"
		t.category = Category.WEAP
		t.symbol_type = SymbolType.FS_ARTILLERY
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 12.0
		t.cross_speed = 6.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 400.0
		t.spot_range_moving = 250.0
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,
			WeaponData.ArmorZone.SIDE: 3,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## ENGINEER_VEH: 工兵車両（2両=1ユニット）
	## CEV/地雷処理車相当
	## 障害処理能力、中装甲
	static func create_engineer_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "ENGINEER_VEH"
		t.display_name = "Engineer Vehicle"
		t.category = Category.ENG
		t.symbol_type = SymbolType.INF_ENGINEER
		t.armor_class = 2  # Medium
		t.mobility_class = GameEnums.MobilityType.TRACKED
		t.road_speed = 10.0
		t.cross_speed = 5.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 400.0
		t.spot_range_moving = 250.0
		# 中装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 20,
			WeaponData.ArmorZone.SIDE: 10,
			WeaponData.ArmorZone.REAR: 6,
			WeaponData.ArmorZone.TOP: 4,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 18,
			WeaponData.ArmorZone.SIDE: 8,
			WeaponData.ArmorZone.REAR: 5,
			WeaponData.ArmorZone.TOP: 3,
		}
		return t

	## EW_VEH: 電子戦車両（1両=1ユニット）
	## 電子妨害/情報収集能力
	static func create_ew_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "EW_VEH"
		t.display_name = "EW Vehicle"
		t.category = Category.REC
		t.symbol_type = SymbolType.CMD_HQ  # 専用シンボルがないため流用
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 14.0
		t.cross_speed = 7.0
		t.base_strength = 1
		t.max_strength = 1
		t.spot_range_base = 1200.0  # 高性能センサー
		t.spot_range_moving = 900.0
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,
			WeaponData.ArmorZone.SIDE: 3,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## ISR_VEH: ISR車両（1両=1ユニット）
	## 偵察/監視車両、UAV制御車両
	static func create_isr_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "ISR_VEH"
		t.display_name = "ISR Vehicle"
		t.category = Category.REC
		t.symbol_type = SymbolType.RECON_UAV
		t.armor_class = 0  # Soft
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 16.0
		t.cross_speed = 8.0
		t.base_strength = 1
		t.max_strength = 1
		t.spot_range_base = 1500.0  # 非常に高性能センサー/UAV
		t.spot_range_moving = 1000.0
		# ソフトスキン
		return t

	## MEDICAL_VEH: 衛生車両（2両=1ユニット）
	## 戦場救護、後送能力
	static func create_medical_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "MEDICAL_VEH"
		t.display_name = "Medical Vehicle"
		t.category = Category.LOG
		t.symbol_type = SymbolType.SUP_MEDEVAC
		t.armor_class = 1  # Light
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 16.0
		t.cross_speed = 8.0
		t.base_strength = 2
		t.max_strength = 2
		t.spot_range_base = 300.0
		t.spot_range_moving = 200.0
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 5,
			WeaponData.ArmorZone.SIDE: 3,
			WeaponData.ArmorZone.REAR: 2,
			WeaponData.ArmorZone.TOP: 1,
		}
		return t

	## CBRN_VEH: NBC偵察車両（1両=1ユニット）
	## 化学/生物/放射線検知能力
	static func create_cbrn_veh() -> ElementType:
		var t := ElementType.new()
		t.id = "CBRN_VEH"
		t.display_name = "CBRN Recon"
		t.category = Category.REC
		t.symbol_type = SymbolType.INF_RECON
		t.armor_class = 1  # Light（NBC密閉車両）
		t.mobility_class = GameEnums.MobilityType.WHEELED
		t.road_speed = 14.0
		t.cross_speed = 7.0
		t.base_strength = 1
		t.max_strength = 1
		t.spot_range_base = 600.0
		t.spot_range_moving = 400.0
		# 軽装甲
		t.armor_ke = {
			WeaponData.ArmorZone.FRONT: 8,
			WeaponData.ArmorZone.SIDE: 5,
			WeaponData.ArmorZone.REAR: 4,
			WeaponData.ArmorZone.TOP: 3,
		}
		t.armor_ce = {
			WeaponData.ArmorZone.FRONT: 6,
			WeaponData.ArmorZone.SIDE: 4,
			WeaponData.ArmorZone.REAR: 3,
			WeaponData.ArmorZone.TOP: 2,
		}
		return t

	## 全アーキタイプを取得
	static func get_all_archetypes() -> Dictionary:
		return {
			"INF_LINE": create_inf_line(),
			"INF_AT": create_inf_at(),
			"INF_MG": create_inf_mg(),
			"TANK_PLT": create_tank_plt(),
			"LIGHT_TANK": create_light_tank(),
			"IFV_PLT": create_ifv_plt(),
			"APC_PLT": create_apc_plt(),
			"LIGHT_VEH": create_light_veh(),
			"COMMAND_VEH": create_command_veh(),
			"RECON_VEH": create_recon_veh(),
			"RECON_TEAM": create_recon_team(),
			"MORTAR_SEC": create_mortar_sec(),
			"SP_MORTAR": create_sp_mortar(),
			"SP_ARTILLERY": create_sp_artillery(),
			"MLRS": create_mlrs(),
			"SPAAG": create_spaag(),
			"SAM_VEH": create_sam_veh(),
			"ENGINEER_VEH": create_engineer_veh(),
			"EW_VEH": create_ew_veh(),
			"ISR_VEH": create_isr_veh(),
			"MEDICAL_VEH": create_medical_veh(),
			"CBRN_VEH": create_cbrn_veh(),
			"LOG_TRUCK": create_log_truck(),
			"CMD_HQ": create_cmd_hq(),
		}

	## IDからアーキタイプを取得
	static func get_archetype(archetype_id: String) -> ElementType:
		match archetype_id:
			"INF_LINE": return create_inf_line()
			"INF_AT": return create_inf_at()
			"INF_MG": return create_inf_mg()
			"TANK_PLT": return create_tank_plt()
			"LIGHT_TANK": return create_light_tank()
			"IFV_PLT": return create_ifv_plt()
			"APC_PLT": return create_apc_plt()
			"LIGHT_VEH": return create_light_veh()
			"COMMAND_VEH": return create_command_veh()
			"RECON_VEH": return create_recon_veh()
			"RECON_TEAM": return create_recon_team()
			"MORTAR_SEC": return create_mortar_sec()
			"SP_MORTAR": return create_sp_mortar()
			"SP_ARTILLERY": return create_sp_artillery()
			"MLRS": return create_mlrs()
			"SPAAG": return create_spaag()
			"SAM_VEH": return create_sam_veh()
			"ENGINEER_VEH": return create_engineer_veh()
			"EW_VEH": return create_ew_veh()
			"ISR_VEH": return create_isr_veh()
			"MEDICAL_VEH": return create_medical_veh()
			"CBRN_VEH": return create_cbrn_veh()
			"LOG_TRUCK": return create_log_truck()
			"CMD_HQ": return create_cmd_hq()
			_: return create_inf_line()  # デフォルト
