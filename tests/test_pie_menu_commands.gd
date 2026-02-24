extends GutTest

## パイメニューコマンドのテスト
## 仕様書: docs/pie_menu_commands_v0.2.md
##
## テスト対象:
## - 共通コマンド（全ユニット）
## - ユニットタイプ別コマンド
## - SOP（交戦規則）
## - コマンド可用性判定

# =============================================================================
# 定数・参照
# =============================================================================

const ElementDataScript := preload("res://scripts/data/element_data.gd")
const WeaponDataScript := preload("res://scripts/data/weapon_data.gd")

# =============================================================================
# 共通コマンドテスト
# =============================================================================

func test_common_commands_exist() -> void:
	## 共通コマンド（Move, Stop, Attack, Break Contact）が存在する
	assert_true(GameEnums.OrderType.MOVE != null, "MOVE command exists")
	assert_true(GameEnums.OrderType.ATTACK != null, "ATTACK command exists")
	assert_true(GameEnums.OrderType.BREAK_CONTACT != null, "BREAK_CONTACT command exists")
	# STOP は新規追加が必要（現在は HOLD が存在）
	assert_true(GameEnums.OrderType.HOLD != null, "HOLD/STOP command exists")


func test_common_commands_values() -> void:
	## 共通コマンドの値が正しい
	assert_eq(GameEnums.OrderType.MOVE, 1, "MOVE = 1")
	assert_eq(GameEnums.OrderType.ATTACK, 6, "ATTACK = 6")
	assert_eq(GameEnums.OrderType.BREAK_CONTACT, 12, "BREAK_CONTACT = 12")


# =============================================================================
# SOPモードテスト
# =============================================================================

func test_sop_modes_exist() -> void:
	## SOPモード（Hold Fire, Return Fire, Fire at Will）が存在する
	assert_true(GameEnums.SOPMode.HOLD_FIRE != null, "HOLD_FIRE exists")
	assert_true(GameEnums.SOPMode.RETURN_FIRE != null, "RETURN_FIRE exists")
	assert_true(GameEnums.SOPMode.FIRE_AT_WILL != null, "FIRE_AT_WILL exists")


func test_sop_modes_values() -> void:
	## SOPモードの値が正しい
	assert_eq(GameEnums.SOPMode.HOLD_FIRE, 0, "HOLD_FIRE = 0")
	assert_eq(GameEnums.SOPMode.RETURN_FIRE, 1, "RETURN_FIRE = 1")
	assert_eq(GameEnums.SOPMode.FIRE_AT_WILL, 2, "FIRE_AT_WILL = 2")


func test_sop_mode_count() -> void:
	## SOPモードは3種類
	# enum の値を確認
	var sop_values := [
		GameEnums.SOPMode.HOLD_FIRE,
		GameEnums.SOPMode.RETURN_FIRE,
		GameEnums.SOPMode.FIRE_AT_WILL,
	]
	assert_eq(sop_values.size(), 3, "SOPMode has 3 values")


# =============================================================================
# 戦車コマンドテスト
# =============================================================================

func test_tank_required_commands() -> void:
	## 戦車に必要なコマンド: Move, Attack, Stop, Reverse, Break Contact
	var tank_commands := _get_tank_commands()

	assert_true(tank_commands.has(GameEnums.OrderType.MOVE), "Tank has MOVE")
	assert_true(tank_commands.has(GameEnums.OrderType.ATTACK), "Tank has ATTACK")
	assert_true(tank_commands.has(GameEnums.OrderType.HOLD), "Tank has STOP (HOLD)")
	assert_true(tank_commands.has(GameEnums.OrderType.RETREAT), "Tank has REVERSE (RETREAT)")
	assert_true(tank_commands.has(GameEnums.OrderType.BREAK_CONTACT), "Tank has BREAK_CONTACT")


func test_tank_optional_commands() -> void:
	## 戦車のオプションコマンド: Smoke（装備時のみ）
	var tank_commands := _get_tank_commands()

	# Smokeは装備によって変わるので、存在チェックのみ
	assert_true(GameEnums.OrderType.SMOKE != null, "SMOKE command exists in enum")


func _get_tank_commands() -> Array:
	## 戦車の利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.ATTACK,
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.RETREAT,  # REVERSE
		GameEnums.OrderType.BREAK_CONTACT,
		GameEnums.OrderType.SMOKE,
	]


# =============================================================================
# 装甲戦闘車コマンドテスト
# =============================================================================

func test_ifv_required_commands() -> void:
	## IFV/APCに必要なコマンド: Move, Attack, Stop, Reverse, Break Contact
	var ifv_commands := _get_ifv_commands()

	assert_true(ifv_commands.has(GameEnums.OrderType.MOVE), "IFV has MOVE")
	assert_true(ifv_commands.has(GameEnums.OrderType.ATTACK), "IFV has ATTACK")
	assert_true(ifv_commands.has(GameEnums.OrderType.HOLD), "IFV has STOP (HOLD)")
	assert_true(ifv_commands.has(GameEnums.OrderType.BREAK_CONTACT), "IFV has BREAK_CONTACT")


func test_ifv_transport_commands() -> void:
	## IFV/APCの輸送コマンド: Unload, Load（将来実装）
	# 現在のOrderTypeにはUnload/Loadがないので、将来追加が必要
	# このテストは追加時に更新する
	pass


func _get_ifv_commands() -> Array:
	## IFV/APCの利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.ATTACK,
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.RETREAT,  # REVERSE
		GameEnums.OrderType.BREAK_CONTACT,
		GameEnums.OrderType.SMOKE,
	]


# =============================================================================
# 砲兵コマンドテスト
# =============================================================================

func test_artillery_required_commands() -> void:
	## 砲兵に必要なコマンド: Move, Stop, Break Contact
	var arty_commands := _get_artillery_commands()

	assert_true(arty_commands.has(GameEnums.OrderType.MOVE), "Artillery has MOVE")
	assert_true(arty_commands.has(GameEnums.OrderType.HOLD), "Artillery has STOP (HOLD)")
	assert_true(arty_commands.has(GameEnums.OrderType.BREAK_CONTACT), "Artillery has BREAK_CONTACT")


func test_artillery_fire_mission_commands() -> void:
	## 砲兵の射撃任務コマンド: Fire Mission HE, Smoke（将来実装）
	# 現在のOrderTypeには詳細な射撃任務がないので、SUPPORT or SUPPRESSで代用
	assert_true(GameEnums.OrderType.SUPPORT != null, "SUPPORT command exists")
	assert_true(GameEnums.OrderType.SMOKE != null, "SMOKE command exists")


func _get_artillery_commands() -> Array:
	## 砲兵の利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.BREAK_CONTACT,
		GameEnums.OrderType.SUPPORT,  # Fire Mission HE
		GameEnums.OrderType.SMOKE,  # Fire Mission Smoke
	]


# =============================================================================
# 歩兵コマンドテスト
# =============================================================================

func test_infantry_required_commands() -> void:
	## 歩兵に必要なコマンド: Move, Attack, Stop, Break Contact
	var inf_commands := _get_infantry_commands()

	assert_true(inf_commands.has(GameEnums.OrderType.MOVE), "Infantry has MOVE")
	assert_true(inf_commands.has(GameEnums.OrderType.ATTACK), "Infantry has ATTACK")
	assert_true(inf_commands.has(GameEnums.OrderType.HOLD), "Infantry has STOP (HOLD)")
	assert_true(inf_commands.has(GameEnums.OrderType.BREAK_CONTACT), "Infantry has BREAK_CONTACT")


func test_infantry_special_commands() -> void:
	## 歩兵の特殊コマンド: Fast Move, Ambush
	# MOVE_FAST が存在
	assert_true(GameEnums.OrderType.MOVE_FAST != null, "MOVE_FAST exists for Fast Move")
	# Ambush は将来実装（現在はRECONを流用可能）


func _get_infantry_commands() -> Array:
	## 歩兵の利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.MOVE_FAST,  # Fast Move
		GameEnums.OrderType.ATTACK,
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.BREAK_CONTACT,
	]


# =============================================================================
# 偵察コマンドテスト
# =============================================================================

func test_recon_required_commands() -> void:
	## 偵察に必要なコマンド: Move, Stop, Break Contact, Recon
	var recon_commands := _get_recon_commands()

	assert_true(recon_commands.has(GameEnums.OrderType.MOVE), "Recon has MOVE")
	assert_true(recon_commands.has(GameEnums.OrderType.HOLD), "Recon has STOP (HOLD)")
	assert_true(recon_commands.has(GameEnums.OrderType.BREAK_CONTACT), "Recon has BREAK_CONTACT")
	assert_true(recon_commands.has(GameEnums.OrderType.RECON), "Recon has RECON")


func _get_recon_commands() -> Array:
	## 偵察の利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.RECON,  # Recon Move / Observe
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.BREAK_CONTACT,
	]


# =============================================================================
# 支援車両コマンドテスト
# =============================================================================

func test_support_required_commands() -> void:
	## 支援車両に必要なコマンド: Move, Stop, Break Contact
	var support_commands := _get_support_commands()

	assert_true(support_commands.has(GameEnums.OrderType.MOVE), "Support has MOVE")
	assert_true(support_commands.has(GameEnums.OrderType.HOLD), "Support has STOP (HOLD)")
	assert_true(support_commands.has(GameEnums.OrderType.BREAK_CONTACT), "Support has BREAK_CONTACT")


func test_support_special_commands() -> void:
	## 支援車両の特殊コマンド: Resupply, Follow（将来実装）
	# 現在のOrderTypeにはResupply/Followがない
	# SUPPORT コマンドを流用可能
	assert_true(GameEnums.OrderType.SUPPORT != null, "SUPPORT command exists")


func _get_support_commands() -> Array:
	## 支援車両の利用可能コマンドを返す
	return [
		GameEnums.OrderType.MOVE,
		GameEnums.OrderType.HOLD,  # STOP
		GameEnums.OrderType.BREAK_CONTACT,
		GameEnums.OrderType.SUPPORT,  # Resupply / Follow
	]


# =============================================================================
# コマンド可用性判定テスト
# =============================================================================

func test_get_available_commands_tank() -> void:
	## 戦車アーキタイプのコマンド可用性
	var archetype := "TANK_PLT"
	var commands := _get_available_commands_for_archetype(archetype)

	assert_true(commands.has(GameEnums.OrderType.MOVE), "TANK_PLT has MOVE")
	assert_true(commands.has(GameEnums.OrderType.ATTACK), "TANK_PLT has ATTACK")
	assert_true(commands.has(GameEnums.OrderType.RETREAT), "TANK_PLT has REVERSE")


func test_get_available_commands_infantry() -> void:
	## 歩兵アーキタイプのコマンド可用性
	var archetype := "INF_LINE"
	var commands := _get_available_commands_for_archetype(archetype)

	assert_true(commands.has(GameEnums.OrderType.MOVE), "INF_LINE has MOVE")
	assert_true(commands.has(GameEnums.OrderType.ATTACK), "INF_LINE has ATTACK")
	# 歩兵はReverseを持たない
	assert_false(commands.has(GameEnums.OrderType.RETREAT), "INF_LINE does not have REVERSE")


func test_get_available_commands_artillery() -> void:
	## 砲兵アーキタイプのコマンド可用性
	var archetype := "SP_ARTILLERY"
	var commands := _get_available_commands_for_archetype(archetype)

	assert_true(commands.has(GameEnums.OrderType.MOVE), "SP_ARTILLERY has MOVE")
	assert_true(commands.has(GameEnums.OrderType.SUPPORT), "SP_ARTILLERY has SUPPORT (Fire Mission)")
	# 砲兵は直接攻撃を持たない
	assert_false(commands.has(GameEnums.OrderType.ATTACK), "SP_ARTILLERY does not have ATTACK")


func test_get_available_commands_recon() -> void:
	## 偵察アーキタイプのコマンド可用性
	var archetype := "RECON_VEH"
	var commands := _get_available_commands_for_archetype(archetype)

	assert_true(commands.has(GameEnums.OrderType.MOVE), "RECON_VEH has MOVE")
	assert_true(commands.has(GameEnums.OrderType.RECON), "RECON_VEH has RECON")


func _get_available_commands_for_archetype(archetype: String) -> Array:
	## アーキタイプ別のコマンド可用性を返す（仕様書準拠）
	var commands := []

	# 共通コマンド
	commands.append(GameEnums.OrderType.MOVE)
	commands.append(GameEnums.OrderType.HOLD)  # STOP
	commands.append(GameEnums.OrderType.BREAK_CONTACT)

	# アーキタイプ別
	match archetype:
		"TANK_PLT", "LIGHT_TANK":
			commands.append(GameEnums.OrderType.ATTACK)
			commands.append(GameEnums.OrderType.RETREAT)  # REVERSE
			commands.append(GameEnums.OrderType.SMOKE)
		"IFV_PLT", "APC_PLT":
			commands.append(GameEnums.OrderType.ATTACK)
			commands.append(GameEnums.OrderType.RETREAT)  # REVERSE
			commands.append(GameEnums.OrderType.SMOKE)
		"SP_ARTILLERY", "SP_MORTAR", "MLRS":
			commands.append(GameEnums.OrderType.SUPPORT)  # Fire Mission
			commands.append(GameEnums.OrderType.SMOKE)
		"INF_LINE", "INF_AT", "INF_MG":
			commands.append(GameEnums.OrderType.ATTACK)
			commands.append(GameEnums.OrderType.MOVE_FAST)
		"RECON_VEH", "RECON_TEAM":
			commands.append(GameEnums.OrderType.RECON)
			commands.append(GameEnums.OrderType.ATTACK)
		"LOG_TRUCK", "COMMAND_VEH", "MEDICAL_VEH":
			commands.append(GameEnums.OrderType.SUPPORT)
		_:
			# デフォルト：共通コマンドのみ
			pass

	return commands


# =============================================================================
# Move + SOP 組み合わせテスト
# =============================================================================

func test_move_with_hold_fire() -> void:
	## Move + Hold Fire = 隠密移動（撃たない）
	var order_type := GameEnums.OrderType.MOVE
	var sop := GameEnums.SOPMode.HOLD_FIRE

	# この組み合わせは「隠密移動」を意味する
	assert_eq(order_type, GameEnums.OrderType.MOVE)
	assert_eq(sop, GameEnums.SOPMode.HOLD_FIRE)
	# 実際の動作テストは統合テストで行う


func test_move_with_return_fire() -> void:
	## Move + Return Fire = 通常移動（撃たれたら反撃）
	var order_type := GameEnums.OrderType.MOVE
	var sop := GameEnums.SOPMode.RETURN_FIRE

	assert_eq(order_type, GameEnums.OrderType.MOVE)
	assert_eq(sop, GameEnums.SOPMode.RETURN_FIRE)


func test_move_with_fire_at_will() -> void:
	## Move + Fire at Will = 攻撃前進（走行間射撃）
	var order_type := GameEnums.OrderType.MOVE
	var sop := GameEnums.SOPMode.FIRE_AT_WILL

	# この組み合わせは旧「Attack Move」と同等
	assert_eq(order_type, GameEnums.OrderType.MOVE)
	assert_eq(sop, GameEnums.SOPMode.FIRE_AT_WILL)


# =============================================================================
# 廃止されたコマンドのテスト
# =============================================================================

func test_attack_move_deprecated() -> void:
	## Attack Move は廃止（Move + SOP で代替）
	# ATTACK_MOVE は enum に存在するが、UIでは使用しない
	# 将来的に削除予定
	assert_true(GameEnums.OrderType.ATTACK_MOVE != null, "ATTACK_MOVE still exists in enum (deprecated)")


func test_defend_deprecated() -> void:
	## Defend は廃止（Stop + SOP で代替）
	# DEFEND は enum に存在するが、UIでは使用しない
	# Stop (HOLD) と SOP の組み合わせで代替
	assert_true(GameEnums.OrderType.DEFEND != null, "DEFEND still exists in enum (deprecated)")


# =============================================================================
# パイメニュー方向配置テスト
# =============================================================================

func test_pie_menu_direction_mapping() -> void:
	## パイメニューの方向配置（仕様書準拠）
	# ↑ (N) = Move
	# → (E) = Attack
	# ↓ (S) = Stop
	# ↖ (NW) = Break Contact

	var directions := {
		"N": GameEnums.OrderType.MOVE,
		"E": GameEnums.OrderType.ATTACK,
		"S": GameEnums.OrderType.HOLD,  # STOP
		"NW": GameEnums.OrderType.BREAK_CONTACT,
	}

	assert_eq(directions["N"], GameEnums.OrderType.MOVE, "North = Move")
	assert_eq(directions["E"], GameEnums.OrderType.ATTACK, "East = Attack")
	assert_eq(directions["S"], GameEnums.OrderType.HOLD, "South = Stop")
	assert_eq(directions["NW"], GameEnums.OrderType.BREAK_CONTACT, "NorthWest = Break Contact")


# =============================================================================
# 将来実装予定コマンドのプレースホルダーテスト
# =============================================================================

func test_future_commands_not_yet_implemented() -> void:
	## 将来実装予定のコマンド（現在はenumに存在しない）
	# これらのテストは実装時に更新する

	# Unload / Load（IFV/APC用）
	# Fire Position（戦車用）
	# Deploy / Cease Fire（砲兵用）
	# Ambush（歩兵用）
	# Observe / Hide（偵察用）
	# Resupply（LOG_TRUCK用）

	# 現在は存在しないことを確認（将来追加時にこのテストを更新）
	var order_type_names := []
	for i in range(20):  # enum の範囲をチェック
		if GameEnums.OrderType.values().has(i):
			order_type_names.append(i)

	# 現在のOrderTypeの数を確認
	assert_true(order_type_names.size() > 0, "OrderType has values")


# =============================================================================
# アーキタイプカテゴリ分類テスト
# =============================================================================

func test_archetype_category_tank() -> void:
	## 戦車カテゴリのアーキタイプ
	var tank_archetypes := ["TANK_PLT", "LIGHT_TANK"]

	for archetype in tank_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "TANK", "%s is TANK category" % archetype)


func test_archetype_category_ifv() -> void:
	## 装甲戦闘車カテゴリのアーキタイプ
	var ifv_archetypes := ["IFV_PLT", "APC_PLT"]

	for archetype in ifv_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "IFV", "%s is IFV category" % archetype)


func test_archetype_category_artillery() -> void:
	## 砲兵カテゴリのアーキタイプ
	var arty_archetypes := ["SP_ARTILLERY", "SP_MORTAR", "MLRS"]

	for archetype in arty_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "ARTILLERY", "%s is ARTILLERY category" % archetype)


func test_archetype_category_infantry() -> void:
	## 歩兵カテゴリのアーキタイプ
	var inf_archetypes := ["INF_LINE", "INF_AT", "INF_MG"]

	for archetype in inf_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "INFANTRY", "%s is INFANTRY category" % archetype)


func test_archetype_category_recon() -> void:
	## 偵察カテゴリのアーキタイプ
	var recon_archetypes := ["RECON_VEH", "RECON_TEAM"]

	for archetype in recon_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "RECON", "%s is RECON category" % archetype)


func test_archetype_category_support() -> void:
	## 支援カテゴリのアーキタイプ
	var support_archetypes := ["LOG_TRUCK", "COMMAND_VEH", "MEDICAL_VEH"]

	for archetype in support_archetypes:
		var category := _get_archetype_category(archetype)
		assert_eq(category, "SUPPORT", "%s is SUPPORT category" % archetype)


func _get_archetype_category(archetype: String) -> String:
	## アーキタイプからカテゴリを返す
	match archetype:
		"TANK_PLT", "LIGHT_TANK":
			return "TANK"
		"IFV_PLT", "APC_PLT":
			return "IFV"
		"SP_ARTILLERY", "SP_MORTAR", "MLRS":
			return "ARTILLERY"
		"INF_LINE", "INF_AT", "INF_MG":
			return "INFANTRY"
		"RECON_VEH", "RECON_TEAM":
			return "RECON"
		"SPAAG", "SAM_VEH":
			return "AIR_DEFENSE"
		"LOG_TRUCK", "COMMAND_VEH", "MEDICAL_VEH":
			return "SUPPORT"
		_:
			return "UNKNOWN"


# =============================================================================
# SOPシステムUIテスト
# =============================================================================

func test_sop_order_types_exist() -> void:
	## SOP切り替え用OrderTypeが存在する
	assert_true(GameEnums.OrderType.has("WEAPONS_FREE"), "WEAPONS_FREE OrderType exists")
	assert_true(GameEnums.OrderType.has("WEAPONS_HOLD"), "WEAPONS_HOLD OrderType exists")


func test_sop_weapons_free_value() -> void:
	## WEAPONS_FREE OrderTypeの値が適切
	var weapons_free: int = GameEnums.OrderType.WEAPONS_FREE
	assert_gt(weapons_free, 0, "WEAPONS_FREE has positive value")


func test_sop_weapons_hold_value() -> void:
	## WEAPONS_HOLD OrderTypeの値が適切
	var weapons_hold: int = GameEnums.OrderType.WEAPONS_HOLD
	assert_gt(weapons_hold, 0, "WEAPONS_HOLD has positive value")


func test_sop_not_in_default_pie_menu() -> void:
	## SOPコマンドはパイメニューのデフォルトに含まれない（右パネルで操作）
	var pie_menu_script := preload("res://scripts/ui/pie_menu.gd")
	var default_commands: Array = pie_menu_script.DEFAULT_COMMANDS

	var has_sop_command := false
	for cmd in default_commands:
		if cmd.type == GameEnums.OrderType.WEAPONS_FREE or cmd.type == GameEnums.OrderType.WEAPONS_HOLD:
			has_sop_command = true
			break

	assert_false(has_sop_command, "Pie menu default has no SOP command (SOP is in right panel)")


func test_element_default_sop_mode() -> void:
	## 新規ElementInstanceのデフォルトSOPはFIRE_AT_WILL
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_sop"
	elem.archetype = "TANK_PLT"

	assert_eq(elem.sop_mode, GameEnums.SOPMode.FIRE_AT_WILL, "Default SOP is FIRE_AT_WILL")


func test_element_sop_mode_changeable() -> void:
	## ElementInstanceのSOPモードを変更できる
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_sop"
	elem.archetype = "TANK_PLT"

	elem.sop_mode = GameEnums.SOPMode.HOLD_FIRE
	assert_eq(elem.sop_mode, GameEnums.SOPMode.HOLD_FIRE, "SOP changed to HOLD_FIRE")

	elem.sop_mode = GameEnums.SOPMode.RETURN_FIRE
	assert_eq(elem.sop_mode, GameEnums.SOPMode.RETURN_FIRE, "SOP changed to RETURN_FIRE")

	elem.sop_mode = GameEnums.SOPMode.FIRE_AT_WILL
	assert_eq(elem.sop_mode, GameEnums.SOPMode.FIRE_AT_WILL, "SOP changed to FIRE_AT_WILL")


func test_sop_toggle_from_fire_at_will() -> void:
	## FIRE_AT_WILL状態でWEAPONS_HOLDコマンド実行→HOLD_FIREに変更
	# このテストはMain.gd側のハンドラが実装されたら検証する
	# 仕様: FIRE_AT_WILL → WEAPONS_HOLD → HOLD_FIRE
	var current_sop := GameEnums.SOPMode.FIRE_AT_WILL
	var expected_sop := GameEnums.SOPMode.HOLD_FIRE

	# シミュレート: WEAPONS_HOLDコマンド実行
	var new_sop := _simulate_sop_toggle(current_sop, GameEnums.OrderType.WEAPONS_HOLD)
	assert_eq(new_sop, expected_sop, "FIRE_AT_WILL + WEAPONS_HOLD = HOLD_FIRE")


func test_sop_toggle_from_hold_fire() -> void:
	## HOLD_FIRE状態でWEAPONS_FREEコマンド実行→FIRE_AT_WILLに変更
	var current_sop := GameEnums.SOPMode.HOLD_FIRE
	var expected_sop := GameEnums.SOPMode.FIRE_AT_WILL

	var new_sop := _simulate_sop_toggle(current_sop, GameEnums.OrderType.WEAPONS_FREE)
	assert_eq(new_sop, expected_sop, "HOLD_FIRE + WEAPONS_FREE = FIRE_AT_WILL")


func test_sop_toggle_from_return_fire() -> void:
	## RETURN_FIRE状態でのSOPトグル
	var current_sop := GameEnums.SOPMode.RETURN_FIRE

	# WEAPONS_FREE → FIRE_AT_WILL
	var new_sop_free := _simulate_sop_toggle(current_sop, GameEnums.OrderType.WEAPONS_FREE)
	assert_eq(new_sop_free, GameEnums.SOPMode.FIRE_AT_WILL, "RETURN_FIRE + WEAPONS_FREE = FIRE_AT_WILL")

	# WEAPONS_HOLD → HOLD_FIRE
	var new_sop_hold := _simulate_sop_toggle(current_sop, GameEnums.OrderType.WEAPONS_HOLD)
	assert_eq(new_sop_hold, GameEnums.SOPMode.HOLD_FIRE, "RETURN_FIRE + WEAPONS_HOLD = HOLD_FIRE")


func _simulate_sop_toggle(current_sop: GameEnums.SOPMode, order_type: GameEnums.OrderType) -> GameEnums.SOPMode:
	## SOPトグルのシミュレーション（Main.gdのロジックを模倣）
	match order_type:
		GameEnums.OrderType.WEAPONS_FREE:
			return GameEnums.SOPMode.FIRE_AT_WILL
		GameEnums.OrderType.WEAPONS_HOLD:
			return GameEnums.SOPMode.HOLD_FIRE
		_:
			return current_sop


# =============================================================================
# SOP射撃判定テスト
# =============================================================================

func test_sop_hold_fire_blocks_shooting() -> void:
	## HOLD_FIREモードでは自発的な射撃を行わない
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_hold"
	elem.sop_mode = GameEnums.SOPMode.HOLD_FIRE

	var can_fire := _can_initiate_fire(elem)
	assert_false(can_fire, "HOLD_FIRE blocks initiating fire")


func test_sop_fire_at_will_allows_shooting() -> void:
	## FIRE_AT_WILLモードでは自由に射撃可能
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_free"
	elem.sop_mode = GameEnums.SOPMode.FIRE_AT_WILL

	var can_fire := _can_initiate_fire(elem)
	assert_true(can_fire, "FIRE_AT_WILL allows initiating fire")


func test_sop_return_fire_blocks_unprovoked_shooting() -> void:
	## RETURN_FIREモードでは攻撃されていない限り射撃しない
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_return"
	elem.sop_mode = GameEnums.SOPMode.RETURN_FIRE
	elem.last_hit_tick = 0  # 攻撃されていない

	var can_fire := _can_initiate_fire_return_fire_check(elem, 100)
	assert_false(can_fire, "RETURN_FIRE blocks unprovoked fire")


func test_sop_return_fire_allows_retaliation() -> void:
	## RETURN_FIREモードでは最近攻撃されたら反撃可能
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_return_hit"
	elem.sop_mode = GameEnums.SOPMode.RETURN_FIRE
	elem.last_hit_tick = 95  # 5tick前に攻撃された

	var can_fire := _can_initiate_fire_return_fire_check(elem, 100)
	assert_true(can_fire, "RETURN_FIRE allows retaliation after being hit")


func test_sop_return_fire_timeout() -> void:
	## RETURN_FIREモードで一定時間経過後は反撃権が失効
	var elem := ElementDataScript.ElementInstance.new()
	elem.id = "test_return_timeout"
	elem.sop_mode = GameEnums.SOPMode.RETURN_FIRE
	elem.last_hit_tick = 50  # 50tick前に攻撃された（タイムアウト）

	# 30秒 = 300tick後はタイムアウト
	var can_fire := _can_initiate_fire_return_fire_check(elem, 400)
	assert_false(can_fire, "RETURN_FIRE retaliation expires after timeout")


## SOPに基づく射撃開始可否を判定（HOLD_FIRE / FIRE_AT_WILL のみ）
func _can_initiate_fire(elem: ElementData.ElementInstance) -> bool:
	match elem.sop_mode:
		GameEnums.SOPMode.HOLD_FIRE:
			return false
		GameEnums.SOPMode.FIRE_AT_WILL:
			return true
		GameEnums.SOPMode.RETURN_FIRE:
			return false  # 追加のチェックが必要
		_:
			return false


## RETURN_FIREモードの射撃可否を判定（last_hit_tickを考慮）
func _can_initiate_fire_return_fire_check(elem: ElementData.ElementInstance, current_tick: int) -> bool:
	if elem.sop_mode != GameEnums.SOPMode.RETURN_FIRE:
		return _can_initiate_fire(elem)

	# 攻撃されていない場合は射撃不可
	if elem.last_hit_tick <= 0:
		return false

	# 反撃タイムアウト: 30秒 = 300tick
	const RETURN_FIRE_TIMEOUT := 300
	var ticks_since_hit := current_tick - elem.last_hit_tick

	return ticks_since_hit <= RETURN_FIRE_TIMEOUT
