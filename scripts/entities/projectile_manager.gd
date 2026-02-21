class_name ProjectileManager
extends Node2D

## 砲弾のビジュアル管理クラス
## 仕様:
## - 実際の弾速とファイアレートで砲弾を表示
## - REDチームは赤、BLUEチームは青の丸で表現
## - DISCRETE武器（戦車砲、RPG、LAW等）の発射時に砲弾を生成
## - 着弾時にダメージを適用（遅延ダメージモデル）

## 砲弾が着弾した時に発火（target_id, damage_info）
signal projectile_impact(target_id: String, damage_info: Dictionary)

# =============================================================================
# 砲弾データ
# =============================================================================

class Projectile:
	var id: int = 0
	var start_pos: Vector2 = Vector2.ZERO      ## 発射位置
	var target_pos: Vector2 = Vector2.ZERO     ## 目標位置
	var current_pos: Vector2 = Vector2.ZERO    ## 現在位置
	var speed_mps: float = 1000.0              ## 弾速（m/s）
	var size: float = 3.0                      ## 砲弾サイズ（ピクセル）
	var faction: GameEnums.Faction = GameEnums.Faction.BLUE
	var is_hit: bool = false                   ## ヒットしたかどうか
	var flight_time: float = 0.0               ## 飛翔時間（秒）
	var total_flight_time: float = 0.0         ## 総飛翔時間（秒）
	var weapon_id: String = ""                 ## 武器ID（デバッグ用）

	## 遅延ダメージ情報（着弾時に適用）
	var has_damage_info: bool = false          ## ダメージ情報を持つか
	var target_id: String = ""                 ## 目標ユニットID
	var damage_info: Dictionary = {}           ## ダメージ情報（kill, mission_kill, catastrophic等）

# =============================================================================
# 状態
# =============================================================================

var _projectiles: Array[Projectile] = []
var _next_id: int = 0

# 色設定
const COLOR_BLUE: Color = Color(0.3, 0.5, 1.0, 1.0)
const COLOR_RED: Color = Color(1.0, 0.3, 0.3, 1.0)
const COLOR_TRAIL: float = 0.3  # トレイル（軌跡）の透明度

# =============================================================================
# 初期化
# =============================================================================

func _ready() -> void:
	# 常に再描画（砲弾が動くため）
	pass


# =============================================================================
# 砲弾生成
# =============================================================================

## 砲弾を発射
## shooter_pos: 発射位置（ワールド座標）
## target_pos: 目標位置（ワールド座標）
## weapon: 使用武器（弾速とサイズを取得）
## faction: 発射側の陣営
## is_hit: この砲弾がヒットするかどうか
func fire_projectile(
	shooter_pos: Vector2,
	target_pos: Vector2,
	weapon: WeaponData.WeaponType,
	faction: GameEnums.Faction,
	is_hit: bool = false
) -> void:
	# 弾速が0の場合は即着弾（ビジュアルなし）
	if weapon.projectile_speed_mps <= 0:
		return

	var proj := Projectile.new()
	proj.id = _next_id
	_next_id += 1

	proj.start_pos = shooter_pos
	proj.target_pos = target_pos
	proj.current_pos = shooter_pos
	proj.speed_mps = weapon.projectile_speed_mps
	proj.size = weapon.projectile_size
	proj.faction = faction
	proj.is_hit = is_hit
	proj.weapon_id = weapon.id
	proj.flight_time = 0.0

	# 総飛翔時間を計算
	var distance := shooter_pos.distance_to(target_pos)
	proj.total_flight_time = distance / proj.speed_mps

	_projectiles.append(proj)


## 砲弾を発射（遅延ダメージ付き）
## 着弾時にprojectile_impactシグナルでダメージ情報を通知
func fire_projectile_with_damage(
	shooter_pos: Vector2,
	target_pos: Vector2,
	weapon: WeaponData.WeaponType,
	faction: GameEnums.Faction,
	target_id: String,
	damage_info: Dictionary
) -> void:
	# 弾速が0の場合は即着弾
	if weapon.projectile_speed_mps <= 0:
		# 即座にダメージを通知
		projectile_impact.emit(target_id, damage_info)
		return

	var proj := Projectile.new()
	proj.id = _next_id
	_next_id += 1

	proj.start_pos = shooter_pos
	proj.target_pos = target_pos
	proj.current_pos = shooter_pos
	proj.speed_mps = weapon.projectile_speed_mps
	proj.size = weapon.projectile_size
	proj.faction = faction
	proj.is_hit = damage_info.get("hit", false)
	proj.weapon_id = weapon.id
	proj.flight_time = 0.0

	# 遅延ダメージ情報を設定
	proj.has_damage_info = true
	proj.target_id = target_id
	proj.damage_info = damage_info

	# 総飛翔時間を計算
	var distance := shooter_pos.distance_to(target_pos)
	proj.total_flight_time = distance / proj.speed_mps

	_projectiles.append(proj)


# =============================================================================
# 更新
# =============================================================================

## 砲弾を更新（毎フレーム呼ばれる）
func update_projectiles(delta: float) -> void:
	var to_remove: Array[int] = []
	var impacts: Array[Projectile] = []

	for i in range(_projectiles.size()):
		var proj := _projectiles[i]

		# 飛翔時間を更新
		proj.flight_time += delta

		# 到達判定
		if proj.flight_time >= proj.total_flight_time:
			to_remove.append(i)
			# 遅延ダメージ情報があれば着弾処理へ
			if proj.has_damage_info:
				impacts.append(proj)
			continue

		# 位置を補間
		var t := proj.flight_time / proj.total_flight_time
		proj.current_pos = proj.start_pos.lerp(proj.target_pos, t)

	# 到達した砲弾を削除（逆順で削除）
	for i in range(to_remove.size() - 1, -1, -1):
		_projectiles.remove_at(to_remove[i])

	# 着弾したダメージを通知
	for proj in impacts:
		projectile_impact.emit(proj.target_id, proj.damage_info)

	# 再描画
	queue_redraw()


## 全砲弾をクリア
func clear_all() -> void:
	_projectiles.clear()
	queue_redraw()


# =============================================================================
# 描画
# =============================================================================

func _draw() -> void:
	for proj in _projectiles:
		_draw_projectile(proj)


func _draw_projectile(proj: Projectile) -> void:
	# 陣営に応じた色
	var base_color: Color
	if proj.faction == GameEnums.Faction.BLUE:
		base_color = COLOR_BLUE
	else:
		base_color = COLOR_RED

	# 軌跡（短い線）
	var direction := (proj.target_pos - proj.start_pos).normalized()
	var trail_length := proj.size * 3.0
	var trail_start := proj.current_pos - direction * trail_length
	var trail_color := Color(base_color.r, base_color.g, base_color.b, COLOR_TRAIL)
	draw_line(trail_start, proj.current_pos, trail_color, proj.size * 0.5)

	# 砲弾本体（円）
	draw_circle(proj.current_pos, proj.size, base_color)

	# ヒット予定の砲弾は少し明るく
	if proj.is_hit:
		var glow_color := Color(base_color.r + 0.2, base_color.g + 0.2, base_color.b + 0.2, 0.5)
		draw_circle(proj.current_pos, proj.size * 1.5, glow_color)


# =============================================================================
# ユーティリティ
# =============================================================================

## アクティブな砲弾数を取得
func get_active_count() -> int:
	return _projectiles.size()


## 特定の陣営の砲弾数を取得
func get_count_by_faction(faction: GameEnums.Faction) -> int:
	var count := 0
	for proj in _projectiles:
		if proj.faction == faction:
			count += 1
	return count
