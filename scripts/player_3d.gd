extends CharacterBody3D
## Third-person character controller.
## Gravity, camera-relative WASD movement, Space to jump.

@export var move_speed: float = 5.0
@export var acceleration: float = 14.0
@export var jump_velocity: float = 4.8
@export var camera_path: NodePath = ^"SpringArm3D/Camera3D"

@onready var _camera: Camera3D = get_node_or_null(camera_path) as Camera3D
@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_apply_movement(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func _apply_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = _camera_relative(input_dir)
	var target: Vector3 = direction * move_speed
	var weight: float = clampf(acceleration * delta, 0.0, 1.0)
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).lerp(target, weight)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Turns the 2D input into a world direction using the camera's yaw,
## so W always walks where the camera looks.
func _camera_relative(input_dir: Vector2) -> Vector3:
	if input_dir.is_zero_approx():
		return Vector3.ZERO
	var cam_basis: Basis = global_transform.basis
	if is_instance_valid(_camera):
		cam_basis = _camera.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3.ZERO
	return (right.normalized() * input_dir.x - forward.normalized() * input_dir.y).normalized()
