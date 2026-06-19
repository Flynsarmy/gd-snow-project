extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const ROTATION_SPEED: float = 0.15
const RUN_ANIM_LENGTH: float = 0.6667
const WALK_ANIM_LENGTH: float = 1.3333

@onready var third_person_camera: Node3D = $ThirdPersonCamera
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").rotated(-third_person_camera.rotation.y)
	var input_length : float = input_dir.length()
	var input_angle : float = input_dir.angle_to(Vector2.UP)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Face character in direction of input
	if input_length > 0:
		visuals.rotation.y = lerp_angle(
			visuals.rotation.y,
			input_angle + PI,
			ROTATION_SPEED
		)

	move_and_slide()
