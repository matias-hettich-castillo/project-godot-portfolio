extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 2
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 10
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 3
# Sensitivity of mouse rotation.
@export var mouse_sensitivity = 0.1
# Camera max top/bot angle
@export var camera_max_top_angle = 65
@export var camera_max_bot_angle = -65
# Camera max/min zoom
@export var camera_max_zoom_distance = 10
@export var camera_min_zoom_distance = 0
@export var camera_zoom_distance = 5

var target_velocity = Vector3.ZERO
var camera_rotation = Vector2()

func _input(event):
	# Exit on ESC
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	# Get mouse scroll event for camera zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_zoom_distance += 1
			if camera_zoom_distance > camera_max_zoom_distance:
				camera_zoom_distance = camera_max_zoom_distance
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_zoom_distance -= 1
			if camera_zoom_distance < camera_min_zoom_distance:
				camera_zoom_distance = camera_min_zoom_distance
				
		# Update the camera position
		$CameraPivot/SpringArm3D.spring_length = camera_zoom_distance
	
	# Capture mouse movement
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Mouse movement to camera
	if event is InputEventMouseMotion:
		camera_rotation -= event.relative * mouse_sensitivity
		camera_rotation.y = clamp(camera_rotation.y, camera_max_bot_angle, camera_max_top_angle)
		$CameraPivot.rotation_degrees.x = camera_rotation.y
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

func _physics_process(delta):
	var direction = Vector3.ZERO

	# Get the camera's global transform and basis
	var camera_global_transform = $CameraPivot/SpringArm3D/Camera3D.global_transform
	var camera_basis = camera_global_transform.basis

	if Input.is_action_pressed("move_right"):
		direction += camera_basis.x
	if Input.is_action_pressed("move_left"):
		direction -= camera_basis.x
	if Input.is_action_pressed("move_back"):
		direction += camera_basis.z
	if Input.is_action_pressed("move_forward"):
		direction -= camera_basis.z

	direction.y = 0  # Limit movement to the horizontal plane

	# Normalize the direction vector
	if direction.length_squared() > 0:
		direction = direction.normalized()
	$Pivot.look_at(position + direction, Vector3.UP)

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# Set the movement based on camera direction
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
