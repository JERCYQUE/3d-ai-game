extends CharacterBody3D
## Third-person character controller.
## Mouse-look camera (SpringArm3D) that collides with the level, wheel zoom,
## gravity, camera-relative WASD, smooth turn toward movement, Space to jump
## and a walk bob so the robot steps instead of sliding.

const BOB_AMPLITUDE: float = 0.055
const BOB_SPEED: float = 9.0

@export var move_speed: float = 5.0
@export var acceleration: float = 14.0
@export var jump_velocity: float = 4.8
@export var turn_speed: float = 10.0
## Degrees of camera rotation per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.12
@export var min_pitch: float = -70.0
@export var max_pitch: float = 15.0
@export var zoom_step: float = 0.4
@export var min_zoom: float = 1.2
@export var max_zoom: float = 8.0

@onready var _arm: SpringArm3D = $SpringArm3D
@onready var _visual: Node3D = $Visual
@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _pitch: float = -15.0
var _bob_time: float = 0.0


func _ready() -> void:
	_pitch = _arm.rotation_degrees.x
	# The arm must not collide with the character it is attached to,
	# otherwise it snaps onto its own capsule and the camera glues to the head.
	_arm.add_excluded_object(self)
	_arm.collision_mask = 1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		# Yaw around the player, pitch on the arm itself (clamped so the
		# camera never flips over the character).
		_arm.rotation_degrees.y -= motion.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		_arm.rotation_degrees.x = _pitch
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_arm.spring_length = clampf(_arm.spring_length - zoom_step, min_zoom, max_zoom)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_arm.spring_length = clampf(_arm.spring_length + zoom_step, min_zoom, max_zoom)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_apply_movement(delta)
	move_and_slide()
	_animate_visual(delta)


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
	if direction.length_squared() > 0.0001:
		_turn_visual_toward(direction, delta)


## Turns the model (not the body) so the mesh faces where it walks:
## the body keeps its transform, so the camera orbit stays stable.
func _turn_visual_toward(direction: Vector3, delta: float) -> void:
	var target_yaw: float = atan2(-direction.x, -direction.z)
	var weight: float = clampf(turn_speed * delta, 0.0, 1.0)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, weight)


## Walk bob: the model rises and falls while it moves on the ground,
## and settles back to zero when it stops or is airborne.
func _animate_visual(delta: float) -> void:
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and speed > 0.4:
		_bob_time += delta * BOB_SPEED * clampf(speed / move_speed, 0.35, 1.0)
		_visual.position.y = sin(_bob_time) * BOB_AMPLITUDE
	else:
		_bob_time = 0.0
		_visual.position.y = lerpf(_visual.position.y, 0.0, clampf(delta * 12.0, 0.0, 1.0))


## Turns the 2D input into a world direction using the camera's yaw,
## so W always walks where the camera looks.
func _camera_relative(input_dir: Vector2) -> Vector3:
	if input_dir.is_zero_approx():
		return Vector3.ZERO
	var cam_basis: Basis = global_transform.basis
	var camera: Camera3D = _arm.get_node_or_null("Camera3D") as Camera3D
	if is_instance_valid(camera):
		cam_basis = camera.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3.ZERO
	return (right.normalized() * input_dir.x - forward.normalized() * input_dir.y).normalized()
