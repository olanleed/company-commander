extends GutTest

## HUD弾種表示のテスト
## RightPanelの_get_ammo_type_display()関数の検証

const RightPanelScript := preload("res://scripts/ui/right_panel.gd")
const WeaponDataScript := preload("res://scripts/data/weapon_data.gd")

var right_panel: RightPanel


func before_each() -> void:
	right_panel = RightPanel.new()
	add_child_autofree(right_panel)


# =============================================================================
# 戦車砲（APFSDS）テスト
# =============================================================================

func test_apfsds_display() -> void:
	## APFSDS弾は"APFSDS"と表示される
	var weapon = WeaponDataScript.create_cw_tank_ke()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "APFSDS", "Tank gun APFSDS should display 'APFSDS'")


func test_apfsds_jgsdf_display() -> void:
	## 自衛隊戦車砲もAPFSDS表示
	var weapon = WeaponDataScript.create_cw_tank_ke_120_jgsdf()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "APFSDS", "JGSDF tank gun should display 'APFSDS'")


func test_apfsds_125mm_display() -> void:
	## 125mm戦車砲（ロシア/中国）もAPFSDS表示
	var weapon = WeaponDataScript.create_cw_tank_ke_125()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "APFSDS", "125mm tank gun should display 'APFSDS'")


# =============================================================================
# HEAT弾テスト
# =============================================================================

func test_heat_display() -> void:
	## HEAT-MP弾は"HEAT"と表示される
	var weapon = WeaponDataScript.create_cw_tank_heatmp()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "HEAT", "HEAT-MP should display 'HEAT'")


# =============================================================================
# ATGMテスト
# =============================================================================

func test_atgm_display() -> void:
	## ATGMは"ATGM"と表示される
	var weapon = WeaponDataScript.create_cw_atgm()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "ATGM", "ATGM should display 'ATGM'")


func test_atgm_javelin_display() -> void:
	## Javelinも"ATGM"と表示される
	var weapon = WeaponDataScript.create_cw_atgm_javelin()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "ATGM", "Javelin should display 'ATGM'")


func test_atgm_kornet_display() -> void:
	## Kornetも"ATGM"と表示される
	var weapon = WeaponDataScript.create_cw_atgm_kornet()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "ATGM", "Kornet should display 'ATGM'")


# =============================================================================
# CONTINUOUS武器（弾種表示なし）テスト
# =============================================================================

func test_autocannon_no_ammo_display() -> void:
	## 機関砲（CONTINUOUS）は弾種表示なし
	var weapon = WeaponDataScript.create_cw_autocannon_30()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "", "Autocannon should have no ammo type display")


func test_rifle_no_ammo_display() -> void:
	## 小銃（CONTINUOUS）は弾種表示なし
	var weapon = WeaponDataScript.create_rifle()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "", "Rifle should have no ammo type display")


func test_mg_no_ammo_display() -> void:
	## 機関銃（CONTINUOUS）は弾種表示なし
	var weapon = WeaponDataScript.create_mg()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	assert_eq(ammo_type, "", "MG should have no ammo type display")


# =============================================================================
# 迫撃砲テスト
# =============================================================================

func test_mortar_he_display() -> void:
	## 迫撃砲HEは"HE"と表示される
	var weapon = WeaponDataScript.create_cw_mortar_he()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	# 迫撃砲はINDIRECTなのでDISCRETEチェックに引っかからない
	# 現在の実装ではDISCRETEのみ弾種表示なので空文字列
	# 将来INDIRECT対応が必要な場合はこのテストを修正
	assert_eq(ammo_type, "", "Mortar HE (INDIRECT) currently has no ammo display")


# =============================================================================
# null/無効な武器テスト
# =============================================================================

func test_null_weapon_no_crash() -> void:
	## null武器でもクラッシュしない
	var ammo_type = right_panel._get_ammo_type_display(null)
	assert_eq(ammo_type, "", "null weapon should return empty string")


# =============================================================================
# RPG/LAWテスト
# =============================================================================

func test_law_display() -> void:
	## LAWは"CE"と表示される（RPGではない、汎用SHAPED_CHARGE）
	var weapon = WeaponDataScript.create_cw_law()
	var ammo_type = right_panel._get_ammo_type_display(weapon)

	# LAWはid="CW_LAW"なのでRPGとは判定されず、CEと表示
	assert_eq(ammo_type, "CE", "LAW should display 'CE'")
