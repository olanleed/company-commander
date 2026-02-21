class_name GameConstants
extends RefCounted

## ゲーム全体で使用する定数を定義
## 仕様書: docs/game_loop_v0.1.md, docs/ruleset_v0.1.md

# =============================================================================
# シミュレーション定数
# =============================================================================

## シミュレーションの固定タイムステップ (秒)
const SIM_DT: float = 0.1

## シミュレーション周波数 (Hz)
const SIM_HZ: int = 10

## 1描画フレームで実行する最大シムステップ数
const MAX_STEPS_PER_FRAME: int = 8

# =============================================================================
# 時間操作
# =============================================================================

## 利用可能なシム速度倍率
const SIM_SPEEDS: Array[float] = [0.0, 1.0, 2.0, 4.0]

## デフォルトのシム速度インデックス (1x)
const DEFAULT_SIM_SPEED_INDEX: int = 1

# =============================================================================
# マップ定数
# =============================================================================

## マップサイズ (メートル)
const MAP_SIZE_M: Vector2 = Vector2(2000.0, 2000.0)

## 地形グリッドのセルサイズ (メートル)
const TERRAIN_GRID_CELL_M: float = 10.0

## 地形グリッドサイズ (セル数)
const TERRAIN_GRID_SIZE: Vector2i = Vector2i(200, 200)

# =============================================================================
# ナビゲーション定数
# =============================================================================

## 地形のtravel_cost
const NAV_TERRAIN_TRAVEL_COST: float = 1.0

## 道路のtravel_cost
const NAV_ROAD_TRAVEL_COST: float = 0.65

## エッジ接続マージン (メートル)
const NAV_EDGE_CONNECTION_MARGIN: float = 2.0

## パス再計算周期 (Hz)
const PATH_RECALC_HZ: float = 1.0

# =============================================================================
# ユニット衝突回避
# =============================================================================

## 歩兵の衝突半径 (メートル)
const UNIT_COLLISION_RADIUS_INFANTRY: float = 15.0

## 車両の衝突半径 (メートル)
const UNIT_COLLISION_RADIUS_VEHICLE: float = 20.0

## 衝突回避力の強さ
const COLLISION_AVOIDANCE_FORCE: float = 80.0

## 衝突検出範囲の倍率（衝突半径の合計 × この倍率）
const COLLISION_DETECTION_MULT: float = 1.5

# =============================================================================
# 拠点定数
# 仕様書: docs/capture_v0.1.md
# =============================================================================

## 拠点の半径 (メートル)
const CP_RADIUS_M: float = 40.0

## 占領速度 (controlポイント/秒/有効パワー)
const CAPTURE_RATE: float = 1.5

## スタッキング上限（パワーの合計上限）
const CAPTURE_CAP: float = 2.0      ## CapturePower上限
const NEUTRALIZE_CAP: float = 2.0   ## NeutralizePower上限
const CONTEST_CAP: float = 3.0      ## ContestPower上限

## Contest閾値（この値以上でContest扱い）
const CONTEST_THRESHOLD: float = 0.05

## control_milli範囲
const CONTROL_MILLI_MAX: int = 100000   ## +100000 = Blue完全支配
const CONTROL_MILLI_MIN: int = -100000  ## -100000 = Red完全支配

## 役割別基礎パワー [capture, neutralize, contest]
## INF
const CP_POWER_INF_CAPTURE: float = 1.00
const CP_POWER_INF_NEUTRALIZE: float = 1.00
const CP_POWER_INF_CONTEST: float = 1.00
## REC
const CP_POWER_REC_CAPTURE: float = 0.70
const CP_POWER_REC_NEUTRALIZE: float = 0.70
const CP_POWER_REC_CONTEST: float = 0.80
## VEH (IFV/APC)
const CP_POWER_VEH_CAPTURE: float = 0.00
const CP_POWER_VEH_NEUTRALIZE: float = 0.40
const CP_POWER_VEH_CONTEST: float = 0.80
## TANK
const CP_POWER_TANK_CAPTURE: float = 0.00
const CP_POWER_TANK_NEUTRALIZE: float = 0.60
const CP_POWER_TANK_CONTEST: float = 1.00
## WEAP/LOG/HQ - 全て0
const CP_POWER_NONE_CAPTURE: float = 0.00
const CP_POWER_NONE_NEUTRALIZE: float = 0.00
const CP_POWER_NONE_CONTEST: float = 0.00

## 姿勢倍率
const CP_POSTURE_DEFEND: float = 1.00
const CP_POSTURE_ATTACK: float = 0.90
const CP_POSTURE_MOVE: float = 0.80
const CP_POSTURE_BREAK_CONTACT: float = 0.60

# =============================================================================
# 視界・索敵定数
# 仕様書: docs/vision_v0.1.md
# =============================================================================

## 視認チェック間隔 (tick数) - 5Hz = 0.2秒ごと
const VISION_SCAN_INTERVAL_TICKS: int = 2

## CONF確定に必要な連続視認回数
const CONF_ACQUIRE_STREAK: int = 2

## CONF→SUS遷移時間 (tick数) - 3.0秒
const T_CONF_TO_SUS_TICKS: int = 30

## SUS→LOST遷移時間 (tick数) - 15.0秒
const T_SUS_TO_LOST_TICKS: int = 150

## LOST→忘却時間 (tick数) - 60秒
const T_LOST_TO_FORGET_TICKS: int = 600

## 位置誤差成長速度 (m/s)
const ERROR_GROWTH_MPS: float = 6.0

## 位置誤差上限 (m)
const ERROR_MAX_M: float = 300.0

## 森林透過の基準距離 (m) - T_forest = exp(-L/60)
const FOREST_LOS_DECAY_M: float = 60.0

## 煙透過の基準距離 (m) - τ = density * L / 40
const SMOKE_LOS_DECAY_M: float = 40.0

## 実質ブロック閾値 - T < 0.10 で視認不可
const LOS_BLOCK_THRESHOLD: float = 0.10

# =============================================================================
# 中隊AI定数
# 仕様書: docs/company_ai_v0.1.md
# =============================================================================

## AI更新レート（tick間隔）
const AI_CONTACT_EVAL_TICKS: int = 5     ## 接触評価（0.5秒 = 5tick）
const AI_TACTICAL_EVAL_TICKS: int = 10   ## 戦術評価（1秒 = 10tick）
const AI_OPERATIONAL_EVAL_TICKS: int = 50  ## 大局評価（5秒 = 50tick）

## 距離閾値（メートル）
const STANDOFF_RECON_M: float = 250.0          ## 観測点オフセット
const SUPPORT_BY_FIRE_MIN_M: float = 500.0     ## 支援射撃ライン最小
const SUPPORT_BY_FIRE_MAX_M: float = 800.0     ## 支援射撃ライン最大
const CONTACT_NEAR_M: float = 600.0            ## 近距離接触
const ARMOR_THREAT_M: float = 900.0            ## 装甲脅威距離

## 要素間隔（メートル）
const FOOT_SPACING_M: float = 25.0             ## 歩兵間隔
const VEHICLE_SPACING_M: float = 40.0          ## 車両間隔
const THREAT_SPACING_MULTIPLIER: float = 1.5   ## 脅威時の間隔倍率

## 命令制御
const MIN_REORDER_INTERVAL_SEC: float = 1.0    ## 再命令抑制時間

## 火力支援トリガー
const CONTESTED_HE_TRIGGER_SEC: float = 10.0   ## CONTESTED時HE要請までの時間
const OPEN_CROSSING_LEN_M: float = 30.0        ## 煙幕トリガーのOPEN横断長

# =============================================================================
# 戦闘イベント定数
# 仕様書: docs/combat_events_v0.1.md
# =============================================================================

## エスカレーション距離
const ESCALATION_CONTACT_NEAR_M: float = 600.0
const ESCALATION_ARMOR_THREAT_M: float = 900.0

## 影響半径
const ALERT_RADIUS_CONTACT_M: float = 800.0
const ALERT_RADIUS_FIRE_M: float = 400.0
const ALERT_RADIUS_CP_M: float = 600.0

## 至近弾距離
const NEAR_MISS_INFANTRY_M: float = 15.0
const NEAR_MISS_VEHICLE_M: float = 25.0

## クールダウン（tick数）
const CONTACT_COOLDOWN_TICKS: int = 20  ## 2秒
const FIRE_COOLDOWN_TICKS: int = 10     ## 1秒

## 戦闘終息（tick数）
const COMBAT_CLEAR_TIMEOUT_TICKS: int = 200  ## 20秒
const COMBAT_RECOVERY_TICKS: int = 50        ## 5秒

# =============================================================================
# リスク評価定数
# 仕様書: docs/risk_assessment_v0.1.md
# =============================================================================

## Intel weights
const W_CONFIDENCE_CONF: float = 1.0
const W_CONFIDENCE_SUS: float = 0.6
const W_CONFIDENCE_LOST: float = 0.2
const SUS_RECENCY_WINDOW_TICKS: int = 150  ## 15秒
const LOST_RECENCY_WINDOW_TICKS: int = 600 ## 60秒

## Armor threat距離
const R_HEAVY_M: float = 1200.0
const R_LIGHT_M: float = 900.0
const DISTANCE_FALLOFF_POWER: float = 2.0
const LOS_BLOCK_RISK_WEIGHT: float = 0.35

## AT threat
const R_COVER_M: float = 150.0
const AT_SHORT_RANGE_M: float = 450.0
const AT_LONG_RANGE_M: float = 1200.0

## Open exposure
const RISK_SAMPLE_STEP_M: float = 25.0
const OPEN_TIME_NORM_S: float = 20.0
const ROAD_OPEN_FACTOR: float = 0.5

## Risk thresholds
const ARMOR_NEAR_CONF_M: float = 900.0
const OPEN_CROSSING_TRIGGER_M: float = 30.0
const OPEN_CROSSING_LONG_M: float = 80.0

## Smoothing
const RISK_DECAY_DOWN_PER_SEC: float = 20.0

# =============================================================================
# 戦闘定数
# 仕様書: docs/combat_v0.1.md
# =============================================================================

## 直射の基準係数 (v0.1R)
## バランス目標: 最良条件でSuppressed(40%)到達は4-5秒、擃滅は約30-60秒
## 計算例（ライフル300m、supp=70、leth=80、dt=0.1）:
##   d_supp = 0.12 × 0.70 × 0.1 = 0.0084/tick → 1秒で0.084 → 約4.8秒でSuppressed
##   d_dmg  = 3.0 × 0.80 × 0.1 = 0.24/tick → 1秒で2.4 → 約42秒で擃滅(100→0)
const K_DF_SUPP: float = 0.12   ## 抑圧係数（約4-5秒でSuppressed）
const K_DF_HIT: float = 0.50    ## ヒット確率係数（0.25→0.50: AT武器のヒット率改善）
const K_DF_DMG: float = 3.0     ## ダメージ係数（約40秒で擃滅）

## 間接の基準係数（1発あたり）(v0.1R)
## バランス目標: 1発で15-20%抑圧、直撃付近で1-2人ダメージ
const K_IF_SUPP: float = 3.0    ## 抑圧係数（1発で約15-20%抑圧）
const K_IF_HIT: float = 0.65    ## ヒット確率係数（v0.1R新規）
const K_IF_DMG: float = 2.0     ## ダメージ係数（直撃で1-2人）
const R_BLAST_M: float = 40.0   ## 爆風半径（m）

## 抑圧回復
const SUPP_RECOVERY_BASE: float = 1.2   ## 基本回復/秒
const SUPP_UNDER_FIRE_COOLDOWN_TICKS: int = 20  ## 被弾後の回復抑制時間（2秒）

## 抑圧閾値
const SUPP_THRESHOLD_SUPPRESSED: float = 0.40
const SUPP_THRESHOLD_PINNED: float = 0.70
const SUPP_THRESHOLD_BROKEN: float = 0.90

## 射手状態係数（M_shooter）
const M_SHOOTER_NORMAL: float = 1.00
const M_SHOOTER_SUPPRESSED: float = 0.70
const M_SHOOTER_PINNED: float = 0.35
const M_SHOOTER_BROKEN: float = 0.15

## 目標回避係数
const M_EVASION_STATIONARY: float = 1.00
const M_EVASION_MOVING: float = 0.85

## Cohesion/Fatigue係数
const M_COHESION_MIN: float = 0.6
const M_COHESION_SCALE: float = 0.4
const M_FATIGUE_MAX_PENALTY: float = 0.3

## 抑圧による能力低下
const SPEED_MULT_SUPPRESSED: float = 0.85
const SPEED_MULT_PINNED: float = 0.20
const SPEED_MULT_BROKEN: float = 0.00

const CAP_MULT_SUPPRESSED: float = 0.50
const CAP_MULT_PINNED: float = 0.20
const CAP_MULT_BROKEN: float = 0.00

## Strength影響
const M_STRENGTH_FIRE_MIN: float = 0.5
const M_STRENGTH_FIRE_SCALE: float = 0.5

## 戦闘不能閾値
const STRENGTH_DESTROYED: float = 0.0
const STRENGTH_COMBAT_INEFFECTIVE: float = 15.0
const STRENGTH_DEGRADED: float = 30.0

## 弾薬ペナルティ閾値
const AMMO_LOW_THRESHOLD: float = 0.20
const AMMO_CRITICAL_THRESHOLD: float = 0.05
const AMMO_LOW_FIRE_MULT: float = 0.85
const AMMO_LOW_SUPP_MULT: float = 0.90
const AMMO_CRITICAL_FIRE_MULT: float = 0.50
const AMMO_CRITICAL_SUPP_MULT: float = 0.70

## 煙・視界係数
const M_SMOKE_FIRE_MIN: float = 0.25
const M_FOLIAGE_FIRE_MIN: float = 0.35

## 面制圧（Attack Area）
const AREA_ATTACK_DMG_MULT: float = 0.35
const AREA_ATTACK_SUPP_MULT: float = 0.70
const AREA_ATTACK_DEFAULT_RADIUS_M: float = 35.0

## 地形遮蔽係数（直射）
const COVER_DF_OPEN: float = 1.0
const COVER_DF_ROAD: float = 1.0
const COVER_DF_FOREST: float = 0.50
const COVER_DF_URBAN: float = 0.35

## 地形遮蔽係数（間接）
const COVER_IF_OPEN: float = 1.0
const COVER_IF_ROAD: float = 0.9
const COVER_IF_FOREST: float = 0.70
const COVER_IF_URBAN: float = 0.55

## Dig-in係数
const ENTRENCH_DF_MULT: float = 0.70
const ENTRENCH_IF_MULT: float = 0.90

## 分散モード係数（間接）
const DISPERSION_IF_COLUMN: float = 1.15
const DISPERSION_IF_DEPLOYED: float = 1.00
const DISPERSION_IF_DISPERSED: float = 0.85

## 通信状態による抑圧回復倍率
const COMM_RECOVERY_GOOD: float = 1.0
const COMM_RECOVERY_DEGRADED: float = 0.7
const COMM_RECOVERY_LOST: float = 0.4

## 姿勢による抑圧回復倍率
const POSTURE_RECOVERY_DEFEND: float = 1.2
const POSTURE_RECOVERY_ATTACK: float = 0.8

# =============================================================================
# v0.1R 車両サブシステム定数
# 仕様書: docs/combat_v0.1.md
# =============================================================================

## Mobility状態閾値
const VEHICLE_MOBILITY_DAMAGED_THRESHOLD: int = 50
const VEHICLE_MOBILITY_CRITICAL_THRESHOLD: int = 25
const VEHICLE_MOBILITY_IMMOBILIZED_THRESHOLD: int = 0

## Mobility速度倍率
const VEHICLE_MOBILITY_DAMAGED_MULT: float = 0.70
const VEHICLE_MOBILITY_CRITICAL_MULT: float = 0.35
const VEHICLE_MOBILITY_IMMOBILIZED_MULT: float = 0.0

## Firepower状態閾値
const VEHICLE_FIREPOWER_DAMAGED_THRESHOLD: int = 50
const VEHICLE_FIREPOWER_CRITICAL_THRESHOLD: int = 25
const VEHICLE_FIREPOWER_DISABLED_THRESHOLD: int = 0

## Firepower倍率
const VEHICLE_FIREPOWER_DAMAGED_MULT: float = 0.80
const VEHICLE_FIREPOWER_CRITICAL_MULT: float = 0.50

## Sensors状態閾値
const VEHICLE_SENSORS_DAMAGED_THRESHOLD: int = 50
const VEHICLE_SENSORS_CRITICAL_THRESHOLD: int = 25
const VEHICLE_SENSORS_DOWN_THRESHOLD: int = 0

## Sensors視界倍率
const VEHICLE_SENSORS_DAMAGED_RANGE_MULT: float = 0.80
const VEHICLE_SENSORS_CRITICAL_RANGE_MULT: float = 0.60
const VEHICLE_SENSORS_DOWN_RANGE_MULT: float = 0.40

# =============================================================================
# v0.1R アスペクトアングル倍率
# =============================================================================

## Heavy（戦車）のアスペクト倍率
const ASPECT_HEAVY_FRONT: float = 0.70
const ASPECT_HEAVY_SIDE: float = 1.00
const ASPECT_HEAVY_REAR: float = 1.25
const ASPECT_HEAVY_TOP: float = 1.10

## Light（軽装甲）のアスペクト倍率
const ASPECT_LIGHT_FRONT: float = 0.95
const ASPECT_LIGHT_SIDE: float = 1.10
const ASPECT_LIGHT_REAR: float = 1.20
const ASPECT_LIGHT_TOP: float = 1.10

# =============================================================================
# v0.1R 脆弱性（デフォルト値）
# vulnerability_dmg_vs / vulnerability_supp_vs
# =============================================================================

## Soft（歩兵）の脆弱性
const VULN_SOFT_SMALLARMS_DMG: float = 1.00
const VULN_SOFT_SMALLARMS_SUPP: float = 1.00
const VULN_SOFT_AUTOCANNON_DMG: float = 1.00
const VULN_SOFT_AUTOCANNON_SUPP: float = 1.00
const VULN_SOFT_HEFRAG_DMG: float = 1.40
const VULN_SOFT_HEFRAG_SUPP: float = 1.30
const VULN_SOFT_AT_DMG: float = 1.00
const VULN_SOFT_AT_SUPP: float = 1.00

## Light（軽装甲）の脆弱性
const VULN_LIGHT_SMALLARMS_DMG: float = 0.15
const VULN_LIGHT_SMALLARMS_SUPP: float = 0.25
const VULN_LIGHT_AUTOCANNON_DMG: float = 0.60
const VULN_LIGHT_AUTOCANNON_SUPP: float = 0.70
const VULN_LIGHT_HEFRAG_DMG: float = 0.40
const VULN_LIGHT_HEFRAG_SUPP: float = 0.70
const VULN_LIGHT_AT_DMG: float = 1.00
const VULN_LIGHT_AT_SUPP: float = 1.00

## Heavy（戦車）の脆弱性
const VULN_HEAVY_SMALLARMS_DMG: float = 0.00
const VULN_HEAVY_SMALLARMS_SUPP: float = 0.10
const VULN_HEAVY_AUTOCANNON_DMG: float = 0.15
const VULN_HEAVY_AUTOCANNON_SUPP: float = 0.35
const VULN_HEAVY_HEFRAG_DMG: float = 0.10
const VULN_HEAVY_HEFRAG_SUPP: float = 0.50
const VULN_HEAVY_AT_DMG: float = 1.00
const VULN_HEAVY_AT_SUPP: float = 0.30  # 戦車乗員は装甲で守られており抑圧されにくい

# =============================================================================
# v0.1R 被害分布
# =============================================================================

## Soft被害量
const SOFT_DAMAGE_MINOR_MIN: float = 0.8
const SOFT_DAMAGE_MINOR_MAX: float = 2.0
const SOFT_DAMAGE_MAJOR_MIN: float = 2.0
const SOFT_DAMAGE_MAJOR_MAX: float = 5.0
const SOFT_DAMAGE_CRITICAL_MIN: float = 5.0
const SOFT_DAMAGE_CRITICAL_MAX: float = 12.0

## Vehicle被害量
const VEHICLE_DAMAGE_MINOR_MIN: int = 8
const VEHICLE_DAMAGE_MINOR_MAX: int = 18
const VEHICLE_DAMAGE_MAJOR_MIN: int = 18
const VEHICLE_DAMAGE_MAJOR_MAX: int = 35

## 被害カテゴリ確率（base）
const DAMAGE_CAT_BASE_MINOR: float = 0.75
const DAMAGE_CAT_BASE_MAJOR: float = 0.22
const DAMAGE_CAT_BASE_CRITICAL: float = 0.03

## Vehicle E閾値
const VEHICLE_E_LOW: float = 0.25
const VEHICLE_E_HIGH: float = 0.60

## Vehicle Critical時
const VEHICLE_CRITICAL_CATASTROPHIC_CHANCE: float = 0.40
const VEHICLE_CRITICAL_MISSION_KILL_CHANCE: float = 0.60

## サブシステム割り振り（threat_classごと）[sensors, mobility, firepower]
const SUBSYS_DIST_SMALLARMS: Array[float] = [0.70, 0.25, 0.05]
const SUBSYS_DIST_AUTOCANNON: Array[float] = [0.20, 0.40, 0.40]
const SUBSYS_DIST_HEFRAG: Array[float] = [0.35, 0.35, 0.30]
const SUBSYS_DIST_AT: Array[float] = [0.20, 0.35, 0.45]

# =============================================================================
# v0.1R 面制圧補正
# =============================================================================

const AREA_ATTACK_SUPP_MULT_V01R: float = 0.80
const AREA_ATTACK_HIT_MULT_V01R: float = 0.25

# =============================================================================
# 破壊・消滅演出
# =============================================================================

## フェードアウト時間（秒）
const DESTROY_FADE_DURATION_SEC: float = 3.0
## フェードアウト時間（tick, 10Hz）
const DESTROY_FADE_DURATION_TICKS: int = 30

# =============================================================================
# v0.1R 貫徹判定
# 仕様書: docs/damage_model_v0.1.md
# RHA換算スケール: 100 = 500mm RHA
# =============================================================================

## 貫徹確率計算: p_pen = sigmoid((P - A) / PENETRATION_SIGMOID_SCALE)
## スケール15で: diff=+30→88%, diff=0→50%, diff=-30→12%
## 例: LAW(60) vs MBT側面(24) = +36 → 約91%貫通
## 例: LAW(60) vs MBT正面(140) = -80 → 約0.5%貫通
const PENETRATION_SIGMOID_SCALE: float = 15.0

## 車両への小火器抑圧上限（仕様書: max 20%）
const VEHICLE_SMALLARMS_SUPP_CAP: float = 0.20

## ゾーン判定角度閾値（仕様書: ±60°=FRONT, ±150°〜=REAR）
const ZONE_FRONT_ANGLE_RAD: float = 1.047  # PI/3 = 60°
const ZONE_REAR_ANGLE_RAD: float = 2.618   # 5*PI/6 = 150°
