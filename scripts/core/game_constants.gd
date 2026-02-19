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
# 拠点定数
# =============================================================================

## 拠点の半径 (メートル)
const CP_RADIUS_M: float = 40.0

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
