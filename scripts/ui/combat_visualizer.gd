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

## 射線の色（陣営別）- 視認性向上のため透明度を上げる
const FIRE_LINE_BLUE := Color(0.2, 0.6, 1.0, 1.0)  # より明るい青、完全不透明
const FIRE_LINE_RED := Color(1.0, 0.3, 0.2, 1.0)   # 完全不透明

## 射線の幅 - 視認性向上のため太くする
const FIRE_LINE_WIDTH := 4.0  # 少し太く

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
	var last_update_time: float  ## 最終更新時刻（CONTINUOUS武器の有効期限用）
	var duration: float
	var damage: float
	var suppression: float
	var is_hit: bool  ## 命中したかどうか（false=外れ/抑圧射撃）
	var weapon_mechanism: WeaponData.Mechanism  ## 弾頭メカニズム
	var fire_model: WeaponData.FireModel = WeaponData.FireModel.CONTINUOUS  ## 射撃モデル（CONTINUOUS/DISCRETE）
	var draw_count: int = 0  ## _drawで描画された回数（実際に描画されたことを保証）

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

## アクティブな射撃関係（shooter_id -> FireEvent）
## 同じ射手が同じ目標を撃ち続けている場合は更新のみ
var _active_engagements: Dictionary = {}

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
	# Main.gdより後に_processが実行されるようにする
	# （Main.gdでadd_fire_eventが呼ばれた後に描画処理が行われることを保証）
	process_priority = 100

func _process(delta: float) -> void:
	# deltaを加算（ポーズ中は進まない）
	_current_time += delta

	# 描画を要求（_drawは_processの後に呼ばれる）
	queue_redraw()

	# クリーンアップは次フレームの_processの最初に実行
	# （今フレームの_drawでdraw_countがインクリメントされた後）
	# → call_deferredで遅延させても_drawより先に実行されてしまうため、
	#   _drawの最後でクリーンアップを呼ぶ方式に変更

func _draw() -> void:
	if show_fire_lines:
		_draw_fire_lines()

	if show_tracers:
		_draw_tracers()

	if show_muzzle_flash:
		_draw_muzzle_flashes()

	if show_impacts:
		_draw_impacts()

	# クリーンアップは_drawの最後に実行
	# （draw_countがインクリメントされた後なので安全）
	_cleanup_expired_effects()

# =============================================================================
# 射撃イベント登録
# =============================================================================

## 射撃イベントを追加
## DISCRETE武器（戦車砲、ATGM等）は毎回新しいイベントを作成
## CONTINUOUS武器（機関銃等）は同じターゲットへの射撃を更新
func add_fire_event(
	shooter_id: String,
	target_id: String,
	shooter_pos: Vector2,
	target_pos: Vector2,
	shooter_faction: GameEnums.Faction,
	damage: float = 0.0,
	suppression: float = 0.0,
	is_hit: bool = false,
	weapon_mechanism: WeaponData.Mechanism = WeaponData.Mechanism.SMALL_ARMS,
	fire_model: WeaponData.FireModel = WeaponData.FireModel.CONTINUOUS,
	custom_duration: float = -1.0  ## カスタム表示時間（-1なら自動計算）
) -> void:
	var event: FireEvent
	var is_new := true

	# DISCRETE武器は毎回新しいイベントを作成（draw_countをリセット）
	# CONTINUOUS武器は同じshooter->targetの組み合わせで既存イベントを更新
	if fire_model == WeaponData.FireModel.CONTINUOUS:
		var engagement_key := shooter_id + "->" + target_id
		if _active_engagements.has(engagement_key):
			event = _active_engagements[engagement_key]
			is_new = false
		else:
			event = FireEvent.new()
			event.shooter_id = shooter_id
			event.target_id = target_id
			_fire_events.append(event)
			_active_engagements[engagement_key] = event
	else:
		# DISCRETE: 常に新しいイベントを作成
		event = FireEvent.new()
		event.shooter_id = shooter_id
		event.target_id = target_id
		_fire_events.append(event)

	# 位置とステータスを更新
	event.shooter_pos = shooter_pos
	event.target_pos = target_pos
	event.shooter_faction = shooter_faction

	# 新規イベントの場合はtime_createdを設定
	if is_new:
		event.time_created = _current_time
		event.draw_count = 0  # 明示的にリセット
		# 新規イベント追加時は即座に再描画を強制
		queue_redraw()

	# last_update_timeは常に更新（有効期限判定用）
	event.last_update_time = _current_time

	# 射線の表示時間を設定
	if custom_duration > 0:
		event.duration = custom_duration
	else:
		event.duration = 1.0  # デフォルトは1秒
	event.damage = damage
	event.suppression = suppression
	event.is_hit = is_hit
	event.weapon_mechanism = weapon_mechanism
	event.fire_model = fire_model

	# マズルフラッシュは間引く（5回に1回程度）
	if is_new or randf() < 0.2:
		var flash_size := MUZZLE_FLASH_RADIUS
		match weapon_mechanism:
			WeaponData.Mechanism.KINETIC:
				flash_size = MUZZLE_FLASH_RADIUS * 2.0
			WeaponData.Mechanism.SHAPED_CHARGE:
				flash_size = MUZZLE_FLASH_RADIUS * 1.5
			WeaponData.Mechanism.BLAST_FRAG:
				flash_size = MUZZLE_FLASH_RADIUS * 2.5
		_add_muzzle_flash(shooter_pos, flash_size)

	# 着弾エフェクトも間引く
	if is_hit and (is_new or randf() < 0.3):
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
		# 描画カウントをインクリメント（実際に_drawで処理されたことを記録）
		event.draw_count += 1

		# last_update_time からの経過時間でフェードアウト
		var since_update := _current_time - event.last_update_time
		var alpha := 1.0 - (since_update / event.duration)
		alpha = clampf(alpha, 0.0, 1.0)

		if alpha <= 0.0:
			continue

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
		# 有効期限判定: last_update_timeから1秒以上経過したら無効
		var since_update := _current_time - event.last_update_time
		if since_update >= event.duration:
			continue

		# 射手と目標間の距離を計算
		var distance := event.shooter_pos.distance_to(event.target_pos)

		# 武器別のトレーサー設定を取得（距離、射撃モデル、陣営を考慮）
		var tracer_config := _get_tracer_config(event.weapon_mechanism, distance, event.fire_model, event.shooter_faction)
		var tracer_color: Color = tracer_config.color
		var tracer_width: float = tracer_config.width
		var tracer_length: float = tracer_config.length
		var speed_mult: float = tracer_config.speed

		var direction := (event.target_pos - event.shooter_pos).normalized()

		# 機関砲（KINETIC + CONTINUOUS）の場合は複数のトレーサーを描画（連続射撃の視覚効果）
		# 戦車砲（KINETIC + DISCRETE）は単発なので複数トレーサーは描画しない
		if event.weapon_mechanism == WeaponData.Mechanism.KINETIC and event.fire_model == WeaponData.FireModel.CONTINUOUS:
			# 経過時間から複数の弾丸位置を計算
			var age := _current_time - event.time_created
			var tracer_interval := 0.15  # 弾丸間隔（秒）
			var flight_time := distance / 800.0  # 800m/sとして飛行時間を計算

			# 現在飛行中の弾丸を複数描画
			var num_tracers := 3  # 同時に表示する弾丸数
			for i in range(num_tracers):
				var tracer_age := age - i * tracer_interval
				if tracer_age < 0:
					continue
				var bullet_progress := fmod(tracer_age / flight_time, 1.0)
				if bullet_progress >= 1.0:
					continue

				var bullet_pos: Vector2 = event.shooter_pos.lerp(event.target_pos, bullet_progress)
				var tracer_start := bullet_pos - direction * tracer_length
				var alpha := (1.0 - bullet_progress * 0.3) * (1.0 - float(i) * 0.2)  # 後続の弾は薄く
				var color := Color(tracer_color.r, tracer_color.g, tracer_color.b, tracer_color.a * alpha)
				draw_line(tracer_start, bullet_pos, color, tracer_width)
		else:
			# 単発武器: 従来のトレーサー描画
			var age := _current_time - event.time_created
			var progress := age / event.duration
			var bullet_progress := minf(progress * speed_mult, 1.0)
			var bullet_pos: Vector2 = event.shooter_pos.lerp(event.target_pos, bullet_progress)

			# トレーサーを描画（弾丸が到達前のみ）
			if bullet_progress < 1.0:
				var tracer_start := bullet_pos - direction * tracer_length
				var alpha := 1.0 - bullet_progress * 0.5  # 到達に近づくにつれ薄くなる
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
## 距離を考慮して速度を調整（遠距離でもトレーサーが見えるように）
## 間接射撃の場合は陣営色を使用
func _get_tracer_config(
	mechanism: WeaponData.Mechanism,
	distance: float = 500.0,
	fire_model: WeaponData.FireModel = WeaponData.FireModel.CONTINUOUS,
	faction: GameEnums.Faction = GameEnums.Faction.BLUE
) -> Dictionary:
	# 距離に応じた速度スケール（遠いほど遅くする）
	# 基準距離500mで1.0、2000mで0.5程度になるよう調整
	var distance_scale := clampf(500.0 / maxf(distance, 100.0), 0.3, 2.0)

	# 間接射撃の場合は陣営色を使用（赤い軌跡ではなく青/赤の陣営色）
	# speedは1.0固定: custom_durationで正確な飛翔時間が設定されているため
	if fire_model == WeaponData.FireModel.INDIRECT:
		var faction_color := FIRE_LINE_BLUE if faction == GameEnums.Faction.BLUE else FIRE_LINE_RED
		return {
			"color": faction_color,
			"width": TRACER_BLAST_WIDTH,
			"length": TRACER_BLAST_LENGTH,
			"speed": 1.0  # 飛翔時間はcustom_durationで正確に設定済み
		}

	match mechanism:
		WeaponData.Mechanism.SMALL_ARMS:
			return {
				"color": TRACER_SMALL_ARMS_COLOR,
				"width": TRACER_SMALL_ARMS_WIDTH,
				"length": TRACER_SMALL_ARMS_LENGTH,
				"speed": 4.0 * distance_scale  # 高速
			}
		WeaponData.Mechanism.KINETIC:
			return {
				"color": TRACER_KINETIC_COLOR,
				"width": TRACER_KINETIC_WIDTH,
				"length": TRACER_KINETIC_LENGTH,
				"speed": 5.0 * distance_scale  # 超高速（視認性のため少し遅く）
			}
		WeaponData.Mechanism.SHAPED_CHARGE:
			return {
				"color": TRACER_SHAPED_COLOR,
				"width": TRACER_SHAPED_WIDTH,
				"length": TRACER_SHAPED_LENGTH,
				"speed": 2.5 * distance_scale  # ロケットは少し遅め
			}
		WeaponData.Mechanism.BLAST_FRAG:
			return {
				"color": TRACER_BLAST_COLOR,
				"width": TRACER_BLAST_WIDTH,
				"length": TRACER_BLAST_LENGTH,
				"speed": 2.0 * distance_scale  # 曲射は遅め
			}
		_:
			return {
				"color": TRACER_COLOR,
				"width": TRACER_WIDTH,
				"length": TRACER_LENGTH,
				"speed": 3.0 * distance_scale
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
	# 期限切れの射撃イベントを削除（last_update_timeベース）
	var valid_events: Array[FireEvent] = []
	var expired_keys: Array[String] = []

	# 最低でも1回は_drawで描画されることを保証
	# draw_count が0のイベントは絶対に削除しない
	const MIN_DRAW_COUNT := 1

	for event in _fire_events:
		# まだ一度も描画されていない場合は必ず保持
		if event.draw_count < MIN_DRAW_COUNT:
			valid_events.append(event)
			continue

		# last_update_time から duration 経過していなければ有効
		var elapsed := _current_time - event.last_update_time
		if elapsed < event.duration:
			valid_events.append(event)
		else:
			# アクティブエンゲージメントからも削除
			var key := event.shooter_id + "->" + event.target_id
			expired_keys.append(key)
	_fire_events = valid_events

	for key in expired_keys:
		_active_engagements.erase(key)

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
