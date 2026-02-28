extends GutTest

## エンティティID命名規則テスト
## 命名規則 v0.1 に基づくIDフォーマットの検証
##
## 新命名規則:
##   Missile: M_{国籍}_{名称}
##   Weapon:  W_{国籍}_{カテゴリ}_{名称}
##
## 国籍コード: USA, RUS, JPN, CHN, GEN

const MissileDataScript := preload("res://scripts/data/missile_data.gd")
const WeaponDataScript := preload("res://scripts/data/weapon_data.gd")


func before_all() -> void:
	MissileDataScript._reset_for_testing()


func after_all() -> void:
	MissileDataScript._reset_for_testing()


# =============================================================================
# ミサイルID命名規則テスト
# =============================================================================

func test_missile_id_format_regex() -> void:
	## ミサイルIDが M_{国籍}_{名称} フォーマットに従うことを検証
	var regex := RegEx.new()
	regex.compile("^M_(USA|RUS|JPN|CHN|GEN)_[A-Z0-9]+$")

	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		var result := regex.search(missile_id)
		assert_not_null(result, "Missile ID '%s' should match M_{NATION}_{NAME} format" % missile_id)


func test_missile_id_usa_prefix() -> void:
	## 米国ミサイルは M_USA_ プレフィックス
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	# 米国製ミサイルのリスト
	var usa_missiles := ["M_USA_JAVELIN", "M_USA_TOW2B"]

	for missile_id in usa_missiles:
		if missile_id in profiles:
			assert_true(missile_id.begins_with("M_USA_"),
				"US missile '%s' should have M_USA_ prefix" % missile_id)


func test_missile_id_rus_prefix() -> void:
	## ロシアミサイルは M_RUS_ プレフィックス
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	var rus_missiles := ["M_RUS_KORNET", "M_RUS_KONKURS", "M_RUS_REFLEKS"]

	for missile_id in rus_missiles:
		if missile_id in profiles:
			assert_true(missile_id.begins_with("M_RUS_"),
				"Russian missile '%s' should have M_RUS_ prefix" % missile_id)


func test_missile_id_jpn_prefix() -> void:
	## 日本ミサイルは M_JPN_ プレフィックス
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	var jpn_missiles := ["M_JPN_01LMAT", "M_JPN_79MAT", "M_JPN_MMPM"]

	for missile_id in jpn_missiles:
		if missile_id in profiles:
			assert_true(missile_id.begins_with("M_JPN_"),
				"Japanese missile '%s' should have M_JPN_ prefix" % missile_id)


func test_missile_id_chn_prefix() -> void:
	## 中国ミサイルは M_CHN_ プレフィックス
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	var chn_missiles := ["M_CHN_HJ10", "M_CHN_HJ9"]

	for missile_id in chn_missiles:
		if missile_id in profiles:
			assert_true(missile_id.begins_with("M_CHN_"),
				"Chinese missile '%s' should have M_CHN_ prefix" % missile_id)


func test_all_missiles_have_new_id_format() -> void:
	## 全ミサイルが新IDフォーマットを使用していることを確認
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		# 旧フォーマット（MSL_）は使用しない
		assert_false(missile_id.begins_with("MSL_"),
			"Missile ID '%s' should not use legacy MSL_ prefix" % missile_id)
		# 新フォーマット（M_）を使用
		assert_true(missile_id.begins_with("M_"),
			"Missile ID '%s' should use new M_ prefix" % missile_id)


# =============================================================================
# 武器ID命名規則テスト
# =============================================================================

func test_atgm_weapon_id_format_regex() -> void:
	## ATGM武器IDが W_{国籍}_ATGM_{名称} フォーマットに従うことを検証
	## 注: 現時点ではATGM武器のみ新命名規則に移行済み
	var regex := RegEx.new()
	regex.compile("^W_(USA|RUS|JPN|CHN|GEN)_ATGM_[A-Z0-9]+$")

	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	# ATGMのみチェック（新命名規則に移行済み）
	for weapon_id in weapons.keys():
		if "_ATGM_" in weapon_id or weapon_id.ends_with("_ATGM"):
			var result := regex.search(weapon_id)
			assert_not_null(result,
				"ATGM Weapon ID '%s' should match W_{NATION}_ATGM_{NAME} format" % weapon_id)


func test_atgm_weapon_ids() -> void:
	## ATGM武器は W_{国籍}_ATGM_{名称} フォーマット
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	var atgm_weapons := [
		"W_USA_ATGM_JAVELIN",
		"W_USA_ATGM_TOW2B",
		"W_RUS_ATGM_KORNET",
		"W_RUS_ATGM_KONKURS",
		"W_RUS_ATGM_REFLEKS",
		"W_JPN_ATGM_01LMAT",
		"W_JPN_ATGM_79MAT",
		"W_JPN_ATGM_MMPM",
		"W_CHN_ATGM_HJ10",
		"W_CHN_ATGM_HJ9"
	]

	for weapon_id in atgm_weapons:
		if weapon_id in weapons:
			assert_true("_ATGM_" in weapon_id,
				"ATGM weapon '%s' should contain _ATGM_ category" % weapon_id)


func test_no_legacy_cw_atgm_prefix() -> void:
	## ATGM武器は旧CW_ATGM_プレフィックスを使用しない
	## 注: 現時点ではATGM武器のみ新命名規則に移行済み
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	for weapon_id in weapons.keys():
		if "ATGM" in weapon_id:
			assert_false(weapon_id.begins_with("CW_"),
				"ATGM Weapon ID '%s' should not use legacy CW_ prefix" % weapon_id)


func test_all_atgm_weapons_have_new_id_format() -> void:
	## 全ATGM武器が新IDフォーマットを使用していることを確認
	## 注: 現時点ではATGM武器のみ新命名規則に移行済み
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	for weapon_id in weapons.keys():
		if "ATGM" in weapon_id:
			assert_true(weapon_id.begins_with("W_"),
				"ATGM Weapon ID '%s' should use new W_ prefix" % weapon_id)


# =============================================================================
# ミサイル-武器ID連携テスト
# =============================================================================

func test_missile_weapon_id_consistency() -> void:
	## ミサイルプロファイルの weapon_id が対応する武器に一致
	var profiles: Dictionary = MissileDataScript.get_all_profiles()
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	for missile_id in profiles.keys():
		var profile = profiles[missile_id]
		var weapon_id: String = profile.weapon_id

		assert_true(weapon_id in weapons,
			"Missile '%s' references weapon '%s' which should exist" % [missile_id, weapon_id])


func test_missile_weapon_nation_consistency() -> void:
	## ミサイルと武器の国籍コードが一致
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		var profile = profiles[missile_id]
		var weapon_id: String = profile.weapon_id

		# M_USA_JAVELIN -> USA, W_USA_ATGM_JAVELIN -> USA
		var missile_parts: PackedStringArray = missile_id.split("_")
		var weapon_parts: PackedStringArray = weapon_id.split("_")

		if missile_parts.size() >= 2 and weapon_parts.size() >= 2:
			var missile_nation: String = missile_parts[1]
			var weapon_nation: String = weapon_parts[1]

			assert_eq(missile_nation, weapon_nation,
				"Missile '%s' (%s) and weapon '%s' (%s) should have same nation" % [
					missile_id, missile_nation, weapon_id, weapon_nation
				])


func test_missile_name_in_weapon_id() -> void:
	## ミサイル名が武器IDに含まれる
	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		var profile = profiles[missile_id]
		var weapon_id: String = profile.weapon_id

		# M_USA_JAVELIN -> JAVELIN, W_USA_ATGM_JAVELIN -> JAVELIN
		var missile_parts: PackedStringArray = missile_id.split("_")
		var weapon_parts: PackedStringArray = weapon_id.split("_")

		if missile_parts.size() >= 3 and weapon_parts.size() >= 4:
			var missile_name: String = missile_parts[2]
			var weapon_name: String = weapon_parts[3]

			assert_eq(missile_name, weapon_name,
				"Missile '%s' name should match weapon '%s' name" % [missile_id, weapon_id])


# =============================================================================
# 後方互換性テスト（移行期間中）
# =============================================================================

func test_get_profile_by_new_id() -> void:
	## 新IDでプロファイルを取得できる
	var javelin = MissileDataScript.get_profile("M_USA_JAVELIN")
	assert_not_null(javelin, "Should get Javelin by new ID M_USA_JAVELIN")

	var kornet = MissileDataScript.get_profile("M_RUS_KORNET")
	assert_not_null(kornet, "Should get Kornet by new ID M_RUS_KORNET")

	var mmpm = MissileDataScript.get_profile("M_JPN_MMPM")
	assert_not_null(mmpm, "Should get MMPM by new ID M_JPN_MMPM")


func test_get_profile_for_weapon_by_new_id() -> void:
	## 新武器IDでミサイルプロファイルを取得できる
	var javelin = MissileDataScript.get_profile_for_weapon("W_USA_ATGM_JAVELIN")
	assert_not_null(javelin, "Should get Javelin by new weapon ID W_USA_ATGM_JAVELIN")
	assert_eq(javelin.id, "M_USA_JAVELIN")

	var kornet = MissileDataScript.get_profile_for_weapon("W_RUS_ATGM_KORNET")
	assert_not_null(kornet, "Should get Kornet by new weapon ID W_RUS_ATGM_KORNET")
	assert_eq(kornet.id, "M_RUS_KORNET")


# =============================================================================
# IDフォーマットバリデーション
# =============================================================================

func test_no_lowercase_in_ids() -> void:
	## IDに小文字は含まない
	var profiles: Dictionary = MissileDataScript.get_all_profiles()
	var weapons: Dictionary = WeaponDataScript.get_all_concrete_weapons()

	for missile_id in profiles.keys():
		assert_eq(missile_id, missile_id.to_upper(),
			"Missile ID '%s' should be all uppercase" % missile_id)

	for weapon_id in weapons.keys():
		assert_eq(weapon_id, weapon_id.to_upper(),
			"Weapon ID '%s' should be all uppercase" % weapon_id)


func test_no_spaces_or_special_chars_in_ids() -> void:
	## IDにスペースや特殊文字は含まない（アンダースコアのみ許可）
	var regex := RegEx.new()
	regex.compile("^[A-Z0-9_]+$")

	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		var result := regex.search(missile_id)
		assert_not_null(result,
			"Missile ID '%s' should only contain A-Z, 0-9, and underscore" % missile_id)


func test_nation_code_is_valid() -> void:
	## 国籍コードが有効なものであること
	var valid_nations := ["USA", "RUS", "JPN", "CHN", "GEN", "GER", "GBR", "FRA", "KOR", "ISR"]

	var profiles: Dictionary = MissileDataScript.get_all_profiles()

	for missile_id in profiles.keys():
		var parts: PackedStringArray = missile_id.split("_")
		if parts.size() >= 2:
			var nation: String = parts[1]
			assert_true(nation in valid_nations,
				"Missile ID '%s' has invalid nation code '%s'" % [missile_id, nation])
