class_name CombatVisualizer
extends Node2D

## 交戦状態の可視化
## - 射線（誰が誰を撃っているか）
## - マズルフラッシュ
## - 着弾エフェクト
## - 抑圧インジケータ

# =============================================================================
# 定数
# =============================================================================

## 射線の色（陣営別）
const FIRE_LINE_BLUE := Color(0.2, 0.5, 1.0, 0.6)
const FIRE_LINE_RED := Color(1.0, 0.3, 0.2, 0.6)

## 射線の幅
const FIRE_LINE_WIDTH := 2.0

## マズルフラッシュ
const MUZZLE_FLASH_COLOR := Color(1.0, 0.9, 0.3, 0.9)
const MUZZLE_FLASH_RADIUS := 8.0
const MUZZLE_FLASH_DURATION := 0.1  # 秒

## 着弾エフェクト
const IMPACT_COLOR := Color(1.0, 0.6, 0.2, 0.8)
const IMPACT_RADIUS := 6.0
const IMPACT_DURATION := 0.15  # 秒

## 弾道の弾丸表示（デフォルト）
const TRACER_COLOR := Color(1.0, 0.95, 0.6, 0.7)
const TRACER_LENGTH := 20.0
const TRACER_WIDTH := 1.5

## 武器別トレーサー設定
## SMALL_ARMS: 小銃・MG - 黄色い細い線
const TRACER_SMALL_ARMS_COLOR := Color(1.0, 0.95, 0.5, 0.7)
const TRACER_SMALL_ARMS_WIDTH := 1.5
const TRACER_SMALL_ARMS_LENGTH := 15.0

## KINETIC: AP/APFSDS - 白い太い線（高速）
const TRACER_KINETIC_COLOR := Color(0.9, 0.95, 1.0, 0.9)
const TRACER_KINETIC_WIDTH := 3.0
const TRACER_KINETIC_LENGTH := 30.0

## SHAPED_CHARGE: HEAT/RPG/ATGM - オレンジの炎っぽい線
const TRACER_SHAPED_COLOR := Color(1.0, 0.5, 0.2, 0.8)
const TRACER_SHAPED_WIDTH := 4.0
const TRACER_SHAPED_LENGTH := 25.0

## BLAST_FRAG: HE/迫撃砲 - 赤い大きな弧
const TRACER_BLAST_COLOR := Color(1.0, 0.3, 0.1, 0.8)
const TRACER_BLAST_WIDTH := 5.0
const TRACER_BLAST_LENGTH := 20.0

## 点線の設定（外れ/抑圧射撃用）
const DASH_LENGTH := 15.0
const GAP_LENGTH := 10.0

# =============================================================================
# データ構造
# =============================================================================

## 射撃イベント（可視化用）
class FireEvent:
	var shooter_id: String
	var target_id: String
	var shooter_pos: Vector2
	var target_pos: Vector2
	var shooter_faction: GameEnums.Faction
	var time_created: float
	var duration: float
	var damage: float
	var suppression: float
	var is_hit: bool  ## 命中したかどうか（false=外れ/抑圧射撃）
	var weapon_mechanism: WeaponData.Mechanism  ## 弾頭メカニズム

## マズルフラッシュ
class MuzzleFlash:
	var position: Vector2
	var time_created: float
	var duration: float
	var size: float = 8.0

## 着弾エフェクト
class ImpactEffect:
	var position: Vector2
	var time_created: float
	var duration: float
	var weapon_mechanism: WeaponData.Mechanism = WeaponData.Mechanism.SMALL_ARMS

# =============================================================================
# 状態
# =============================================================================

var _fire_events: Array[FireEvent] = []
var _muzzle_flashes: Array[MuzzleFlash] = []
var _impact_effects: Array[ImpactEffect] = []

var _current_time: float = 0.0

## 射線表示のオン/オフ
var show_fire_lines: bool = true
var show_muzzle_flash: bool = true
var show_impacts: bool = true
var show_tracers: bool = true

# =============================================================================
# ライフサイクル
# =============================================================================

func _ready() -> void:
	z_index = 50  # ユニットの上、UIの下

func _process(delta: float) -> void:
	_current_time += delta
	_cleanup_expired_effects()
	queue_redraw()

func _draw() -> void:
	if show_fire_lines:
		_draw_fire_lines()

	if show_tracers:
		_draw_tracers()

	if show_muzzle_flash:
		_draw_muzzle_flashes()

	if show_impacts:
		_draw_impacts()

# =============================================================================
# 射撃イベント登録
# =============================================================================

## 射撃イベントを追加
func add_fire_event(
	shooter_id: String,
	target_id: String,
	shooter_pos: Vector2,
	target_pos: Vector2,
	shooter_faction: GameEnums.Faction,
	damage: float = 0.0,
	suppression: float = 0.0,
	is_hit: bool = false,
	weapon_mechanism: WeaponData.Mechanism = WeaponData.Mechanism.SMALL_ARMS
) -> void:
	var event := FireEvent.new()
	event.shooter_id = shooter_id
	event.target_id = target_id
	event.shooter_pos = shooter_pos
	event.target_pos = target_pos
	event.shooter_faction = shooter_faction
	event.time_created = _current_time
	event.duration = 0.3  # 射線は0.3秒表示
	event.damage = damage
	event.suppression = suppression
	event.is_hit = is_hit
	event.weapon_mechanism = weapon_mechanism
	_fire_events.append(event)

	# マズルフラッシュを追加（武器に応じてサイズ変更）
	var flash_size := MUZZLE_FLASH_RADIUS
	match weapon_mechanism:
		WeaponData.Mechanism.KINETIC:
			flash_size = MUZZLE_FLASH_RADIUS * 2.0
		WeaponData.Mechanism.SHAPED_CHARGE:
			flash_size = MUZZLE_FLASH_RADIUS * 1.5
		WeaponData.Mechanism.BLAST_FRAG:
			flash_size = MUZZLE_FLASH_RADIUS * 2.5
	_add_muzzle_flash(shooter_pos, flash_size)

	# 着弾エフェクトを追加（命中時のみ派手に）
	if is_hit:
		_add_impact(target_pos, weapon_mechanism)


## マズルフラッシュを追加
func _add_muzzle_flash(pos: Vector2, size: float = MUZZLE_FLASH_RADIUS) -> void:
	var flash := MuzzleFlash.new()
	flash.position = pos
	flash.time_created = _current_time
	flash.duration = MUZZLE_FLASH_DURATION
	flash.size = size
	_muzzle_flashes.append(flash)


## 着弾エフェクトを追加
func _add_impact(pos: Vector2, mechanism: WeaponData.Mechanism = WeaponData.Mechanism.SMALL_ARMS) -> void:
	var impact := ImpactEffect.new()
	impact.position = pos
	impact.time_created = _current_time
	impact.weapon_mechanism = mechanism
	# 武器に応じて持続時間を変更
	match mechanism:
		WeaponData.Mechanism.BLAST_FRAG:
			impact.duration = 0.4  # 爆発は長め
		WeaponData.Mechanism.SHAPED_CHARGE:
			impact.duration = 0.3
		WeaponData.Mechanism.KINETIC:
			impact.duration = 0.2
		_:
			impact.duration = IMPACT_DURATION
	_impact_effects.append(impact)

# =============================================================================
# 描画
# =============================================================================

func _draw_fire_lines() -> void:
	for event in _fire_events:
		var age := _current_time - event.time_created
		var alpha := 1.0 - (age / event.duration)
		alpha = clampf(alpha, 0.0, 1.0)

		var base_color: Color
		if event.shooter_faction == GameEnums.Faction.BLUE:
			base_color = FIRE_LINE_BLUE
		else:
			base_color = FIRE_LINE_RED

		var color := Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha)

		# 命中=実線、外れ/抑圧=点線
		if event.is_hit:
			draw_line(event.shooter_pos, event.target_pos, color, FIRE_LINE_WIDTH)
		else:
			_draw_dashed_line(event.shooter_pos, event.target_pos, color, FIRE_LINE_WIDTH)


## 点線を描画
func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var total_dist := from.distance_to(to)
	var direction := (to - from).normalized()
	var segment_length := DASH_LENGTH + GAP_LENGTH
	var current_dist := 0.0

	while current_dist < total_dist:
		var dash_start := from + direction * current_dist
		var dash_end_dist := minf(current_dist + DASH_LENGTH, total_dist)
		var dash_end := from + direction * dash_end_dist

		draw_line(dash_start, dash_end, color, width)
		current_dist += segment_length


func _draw_tracers() -> void:
	for event in _fire_events:
		var age := _current_time - event.time_created
		var progress := age / event.duration

		if progress >= 1.0:
			continue

		# 武器別のトレーサー設定を取得
		var tracer_config := _get_tracer_config(event.weapon_mechanism)
		var tracer_color: Color = tracer_config.color
		var tracer_width: float = tracer_config.width
		var tracer_length: float = tracer_config.length
		var speed_mult: float = tracer_config.speed

		# 弾丸の位置を計算（射手から目標へ移動）
		var bullet_progress := minf(progress * speed_mult, 1.0)
		var direction := (event.target_pos - event.shooter_pos).normalized()
		var bullet_pos: Vector2 = event.shooter_pos.lerp(event.target_pos, bullet_progress)

		# トレーサーを描画
		var tracer_start := bullet_pos - direction * tracer_length
		var alpha := 1.0 - progress
		var color := Color(tracer_color.r, tracer_color.g, tracer_color.b, tracer_color.a * alpha)

		# 武器によって描画スタイルを変更
		match event.weapon_mechanism:
			WeaponData.Mechanism.BLAST_FRAG:
				# 爆発物は弧を描く軌道
				_draw_arcing_tracer(event.shooter_pos, event.target_pos, bullet_progress, color, tracer_width)
			WeaponData.Mechanism.SHAPED_CHARGE:
				# 成形炸薬は炎の尾を引く
				_draw_rocket_tracer(tracer_start, bullet_pos, direction, color, tracer_width)
			_:
				# 通常の直線トレーサー
				draw_line(tracer_start, bullet_pos, color, tracer_width)


## 武器別トレーサー設定を取得
func _get_tracer_config(mechanism: WeaponData.Mechanism) -> Dictionary:
	match mechanism:
		WeaponData.Mechanism.SMALL_ARMS:
			return {
				"color": TRACER_SMALL_ARMS_COLOR,
				"width": TRACER_SMALL_ARMS_WIDTH,
				"length": TRACER_SMALL_ARMS_LENGTH,
				"speed": 4.0  # 高速
			}
		WeaponData.Mechanism.KINETIC:
			return {
				"color": TRACER_KINETIC_COLOR,
				"width": TRACER_KINETIC_WIDTH,
				"length": TRACER_KINETIC_LENGTH,
				"speed": 6.0  # 超高速
			}
		WeaponData.Mechanism.SHAPED_CHARGE:
			return {
				"color": TRACER_SHAPED_COLOR,
				"width": TRACER_SHAPED_WIDTH,
				"length": TRACER_SHAPED_LENGTH,
				"speed": 2.5  # ロケットは少し遅め
			}
		WeaponData.Mechanism.BLAST_FRAG:
			return {
				"color": TRACER_BLAST_COLOR,
				"width": TRACER_BLAST_WIDTH,
				"length": TRACER_BLAST_LENGTH,
				"speed": 2.0  # 曲射は遅め
			}
		_:
			return {
				"color": TRACER_COLOR,
				"width": TRACER_WIDTH,
				"length": TRACER_LENGTH,
				"speed": 3.0
			}


## 弧を描くトレーサー（迫撃砲など）
func _draw_arcing_tracer(from: Vector2, to: Vector2, progress: float, color: Color, width: float) -> void:
	var mid := (from + to) / 2.0
	var dist := from.distance_to(to)
	var arc_height := dist * 0.3  # 距離の30%の高さの弧

	# 放物線の頂点を計算
	mid.y -= arc_height

	# 3点を通る放物線上の現在位置を計算
	var t := progress
	var pos := from.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(to, (t - 0.5) * 2.0)

	# 弾の軌跡を描画
	var trail_length := 5
	var prev_pos := pos
	for i in range(1, trail_length + 1):
		var t2 := maxf(0.0, progress - 0.02 * i)
		var trail_pos := from.lerp(mid, t2 * 2.0) if t2 < 0.5 else mid.lerp(to, (t2 - 0.5) * 2.0)
		var trail_alpha := color.a * (1.0 - float(i) / trail_length)
		var trail_color := Color(color.r, color.g, color.b, trail_alpha)
		draw_line(prev_pos, trail_pos, trail_color, width * (1.0 - float(i) / trail_length * 0.5))
		prev_pos = trail_pos

	# 弾頭
	draw_circle(pos, width * 1.5, color)


## ロケット/ミサイルトレーサー（HEAT/ATGMなど）
func _draw_rocket_tracer(tracer_start: Vector2, bullet_pos: Vector2, direction: Vector2, color: Color, width: float) -> void:
	# メインの弾
	draw_line(tracer_start, bullet_pos, color, width)

	# 炎の尾（複数の線で表現）
	var flame_length := 15.0
	var flame_color := Color(1.0, 0.7, 0.2, color.a * 0.6)
	var flame_start := tracer_start - direction * flame_length

	# 揺らぎを加えた炎
	var perp := Vector2(-direction.y, direction.x)
	for i in range(3):
		var offset := perp * sin(_current_time * 20.0 + i * 2.0) * 3.0
		var f_start := flame_start + offset * (i + 1) * 0.3
		var f_alpha := flame_color.a * (1.0 - float(i) / 3.0)
		draw_line(f_start, tracer_start, Color(flame_color.r, flame_color.g, flame_color.b, f_alpha), width * 0.7)


func _draw_muzzle_flashes() -> void:
	for flash in _muzzle_flashes:
		var age := _current_time - flash.time_created
		var alpha := 1.0 - (age / flash.duration)
		alpha = clampf(alpha, 0.0, 1.0)

		var color := Color(MUZZLE_FLASH_COLOR.r, MUZZLE_FLASH_COLOR.g, MUZZLE_FLASH_COLOR.b, MUZZLE_FLASH_COLOR.a * alpha)
		var radius := flash.size * (1.0 + age / flash.duration * 0.5)  # 少し拡大

		# 中心の明るい部分
		draw_circle(flash.position, radius, color)

		# 外側のグロー
		var glow_color := Color(color.r, color.g, color.b, color.a * 0.3)
		draw_circle(flash.position, radius * 1.5, glow_color)


func _draw_impacts() -> void:
	for impact in _impact_effects:
		var age := _current_time - impact.time_created
		var alpha := 1.0 - (age / impact.duration)
		alpha = clampf(alpha, 0.0, 1.0)

		# 武器別の着弾エフェクト
		match impact.weapon_mechanism:
			WeaponData.Mechanism.BLAST_FRAG:
				_draw_explosion_impact(impact.position, age, impact.duration, alpha)
			WeaponData.Mechanism.SHAPED_CHARGE:
				_draw_shaped_charge_impact(impact.position, age, impact.duration, alpha)
			WeaponData.Mechanism.KINETIC:
				_draw_kinetic_impact(impact.position, age, impact.duration, alpha)
			_:
				_draw_small_arms_impact(impact.position, age, impact.duration, alpha)


## 小火器の着弾（小さな土埃）
func _draw_small_arms_impact(pos: Vector2, age: float, duration: float, alpha: float) -> void:
	var color := Color(IMPACT_COLOR.r, IMPACT_COLOR.g, IMPACT_COLOR.b, IMPACT_COLOR.a * alpha)
	var radius := IMPACT_RADIUS * (1.0 + age / duration)

	draw_circle(pos, radius, color)

	# 土煙
	var debris_count := 3
	for i in range(debris_count):
		var angle := TAU * i / debris_count + age * 2.0
		var offset := Vector2(cos(angle), sin(angle)) * radius * 1.2
		var debris_radius := radius * 0.25
		var debris_color := Color(0.6, 0.5, 0.4, alpha * 0.4)
		draw_circle(pos + offset, debris_radius, debris_color)


## 運動エネルギー弾の着弾（金属的な火花）
func _draw_kinetic_impact(pos: Vector2, age: float, duration: float, alpha: float) -> void:
	var radius := IMPACT_RADIUS * 1.5 * (1.0 + age / duration * 0.5)

	# 白い閃光
	var flash_color := Color(1.0, 1.0, 0.9, alpha * 0.9)
	draw_circle(pos, radius, flash_color)

	# 火花を放射状に描画
	var spark_count := 6
	for i in range(spark_count):
		var angle := TAU * i / spark_count
		var spark_length := radius * 2.0 * (1.0 + age / duration)
		var spark_end := pos + Vector2(cos(angle), sin(angle)) * spark_length
		var spark_color := Color(1.0, 0.9, 0.5, alpha * 0.7)
		draw_line(pos, spark_end, spark_color, 1.5)


## 成形炸薬弾の着弾（ジェット状の炎）
func _draw_shaped_charge_impact(pos: Vector2, age: float, duration: float, alpha: float) -> void:
	var radius := IMPACT_RADIUS * 2.0 * (1.0 + age / duration * 0.8)

	# オレンジの炎
	var flame_color := Color(1.0, 0.5, 0.1, alpha * 0.8)
	draw_circle(pos, radius, flame_color)

	# 内側の白い部分
	var core_color := Color(1.0, 0.9, 0.7, alpha * 0.9)
	draw_circle(pos, radius * 0.5, core_color)

	# 煙
	var smoke_color := Color(0.3, 0.3, 0.3, alpha * 0.4)
	var smoke_offset := Vector2(0, -radius * 1.5 * age / duration)
	draw_circle(pos + smoke_offset, radius * 0.8, smoke_color)


## 爆発の着弾（大きな爆発）
func _draw_explosion_impact(pos: Vector2, age: float, duration: float, alpha: float) -> void:
	var base_radius := IMPACT_RADIUS * 3.0
	var radius := base_radius * (1.0 + age / duration * 2.0)

	# 外側の煙
	var smoke_color := Color(0.4, 0.35, 0.3, alpha * 0.5)
	draw_circle(pos, radius * 1.3, smoke_color)

	# 火の玉
	var fire_color := Color(1.0, 0.4, 0.1, alpha * 0.7)
	draw_circle(pos, radius, fire_color)

	# 中心の白い閃光（初期のみ）
	if age < duration * 0.3:
		var core_alpha := alpha * (1.0 - age / (duration * 0.3))
		var core_color := Color(1.0, 1.0, 0.8, core_alpha)
		draw_circle(pos, radius * 0.4, core_color)

	# 破片
	var debris_count := 8
	for i in range(debris_count):
		var angle := TAU * i / debris_count + i * 0.5
		var debris_dist := radius * 1.5 * (age / duration)
		var debris_pos := pos + Vector2(cos(angle), sin(angle)) * debris_dist
		var debris_radius := 3.0 * (1.0 - age / duration)
		var debris_color := Color(0.5, 0.4, 0.3, alpha * 0.6)
		draw_circle(debris_pos, debris_radius, debris_color)

# =============================================================================
# クリーンアップ
# =============================================================================

func _cleanup_expired_effects() -> void:
	# 期限切れの射撃イベントを削除
	var valid_events: Array[FireEvent] = []
	for event in _fire_events:
		if _current_time - event.time_created < event.duration:
			valid_events.append(event)
	_fire_events = valid_events

	# 期限切れのマズルフラッシュを削除
	var valid_flashes: Array[MuzzleFlash] = []
	for flash in _muzzle_flashes:
		if _current_time - flash.time_created < flash.duration:
			valid_flashes.append(flash)
	_muzzle_flashes = valid_flashes

	# 期限切れの着弾エフェクトを削除
	var valid_impacts: Array[ImpactEffect] = []
	for impact in _impact_effects:
		if _current_time - impact.time_created < impact.duration:
			valid_impacts.append(impact)
	_impact_effects = valid_impacts

# =============================================================================
# クエリ
# =============================================================================

## 現在の射撃数を取得
func get_active_fire_count() -> int:
	return _fire_events.size()


## 全エフェクトをクリア
func clear_all() -> void:
	_fire_events.clear()
	_muzzle_flashes.clear()
	_impact_effects.clear()
	queue_redraw()
