class_name SymbolManager
extends RefCounted

## 兵科記号（シンボル）のロードと管理
## 仕様書: docs/units_v0.1.md
##
## assets/units/symbols/ からSVGをロードしてキャッシュする

# =============================================================================
# 定数
# =============================================================================

const SYMBOLS_PATH := "res://assets/units/symbols/"
const SYMBOL_SIZE := Vector2(64, 64)  # デフォルトサイズ

# =============================================================================
# キャッシュ
# =============================================================================

var _texture_cache: Dictionary = {}  # symbol_name -> Texture2D

# =============================================================================
# シンボル取得
# =============================================================================

## シンボルテクスチャを取得
func get_symbol_texture(symbol_name: String) -> Texture2D:
	# キャッシュチェック
	if _texture_cache.has(symbol_name):
		return _texture_cache[symbol_name]

	# ロード
	var path := SYMBOLS_PATH + symbol_name + ".svg"
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			_texture_cache[symbol_name] = texture
			return texture

	# フォールバック: unknownシンボル
	push_warning("SymbolManager: Symbol not found: " + symbol_name)
	return _get_fallback_texture()


## Elementインスタンスからシンボルを取得
func get_symbol_for_element(element: ElementData.ElementInstance, viewer_faction: GameEnums.Faction) -> Texture2D:
	var symbol_name := element.get_symbol_name(viewer_faction)
	return get_symbol_texture(symbol_name)


## フォールバックテクスチャ
func _get_fallback_texture() -> Texture2D:
	var fallback_name := "inf_rifle_unknown_sus"
	if _texture_cache.has(fallback_name):
		return _texture_cache[fallback_name]

	var path := SYMBOLS_PATH + fallback_name + ".svg"
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			_texture_cache[fallback_name] = texture
			return texture

	return null

# =============================================================================
# プリロード
# =============================================================================

## 全シンボルをプリロード
func preload_all_symbols() -> void:
	var dir := DirAccess.open(SYMBOLS_PATH)
	if not dir:
		push_error("SymbolManager: Cannot open symbols directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".svg"):
			var symbol_name := file_name.replace(".svg", "")
			get_symbol_texture(symbol_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("SymbolManager: Preloaded " + str(_texture_cache.size()) + " symbols")


## キャッシュをクリア
func clear_cache() -> void:
	_texture_cache.clear()
