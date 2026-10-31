extends Node3D
## Spinning collectible coin.

@export var spin_speed: float = 2.5

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
