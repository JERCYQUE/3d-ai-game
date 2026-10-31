extends Node3D
## Spinning collectible coin. Disappears when the player walks into it.

signal collected

@export var spin_speed: float = 2.5

@onready var _pickup: Area3D = $PickupArea


func _ready() -> void:
	add_to_group("coin")
	_pickup.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	collected.emit()
	queue_free()
