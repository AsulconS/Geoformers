extends CharacterBody3D


const SPEED = 3.0;
const FLY_SPEED = 2.5;
const TILT_MAX_ANGLE = 0.45 * PI;
const TILT_DEG_PER_SEC = 0.5 * PI;
const YAW_DEG_PER_SEC  = 0.75 * PI;

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");


func _physics_process(delta):
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward");
	var input_fly = Input.get_axis("Down", "Up");
	var input_yaw = Input.get_axis("YawLeft", "YawRight");
	var input_tilt = Input.get_axis("TiltDown", "TiltUp");
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	if direction:
		velocity.x = direction.x * SPEED;
		velocity.z = direction.z * SPEED;
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED);
		velocity.z = move_toward(velocity.z, 0, SPEED);
	velocity.y = input_fly * FLY_SPEED;
	
	var cam_rotation : Vector3 = get_node("Camera3D").rotation;
	var can_tilt_up   : bool = (input_tilt > 0.0) and (cam_rotation.x <= TILT_MAX_ANGLE);
	var can_tilt_down : bool = (input_tilt < 0.0) and (cam_rotation.x >= -TILT_MAX_ANGLE);
	if can_tilt_up or can_tilt_down:
		get_node("Camera3D").rotation.x += delta * input_tilt * TILT_DEG_PER_SEC;
	rotation.y += delta * -input_yaw * YAW_DEG_PER_SEC;
	move_and_slide();
