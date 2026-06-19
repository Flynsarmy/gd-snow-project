extends Node3D

const EIGTH_TURN: float = PI/4
const SENSITIVITY: float = 0.005

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _unhandled_input(event: InputEvent) -> void:
	# Mouse camera movement
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -EIGTH_TURN, EIGTH_TURN)
