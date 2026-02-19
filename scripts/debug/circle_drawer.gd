extends Node2D

## デバッグ用: 円を描画するシンプルなノード

@export var radius: float = 40.0
@export var color: Color = Color.WHITE
@export var segments: int = 32

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
