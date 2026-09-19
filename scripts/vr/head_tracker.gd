extends Node3D
class_name VRHeadTracker

@export var gyro_sensitivity := 1.0
@export var smoothing := 18.0
@export var use_gravity_correction := true
@export var gravity_correction_strength := 3.0
@export var max_pitch := 89.0
@export var max_roll := 45.0

var head_rotation := Vector3.ZERO
var calibration_rotation := Vector3.ZERO
var gyro_available := false
var accelerometer_available := false
var gravity_available := false

func _ready() -> void:
	gyro_available = OS.has_feature("android") or not Input.get_gyroscope().is_zero_approx()
	accelerometer_available = OS.has_feature("android") or not Input.get_accelerometer().is_zero_approx()
	gravity_available = OS.has_feature("android") or not Input.get_gravity().is_zero_approx()
	calibrate()
	set_process(true)

func _process(delta: float) -> void:
	if not gyro_available:
		return

	var gyro := Input.get_gyroscope() * gyro_sensitivity
	var target_rotation := head_rotation + gyro * delta
	var weight := 1.0 - exp(-smoothing * delta)
	head_rotation = head_rotation.lerp(target_rotation, weight)

	if use_gravity_correction and gravity_available:
		var gravity := Input.get_gravity()
		if gravity.length() > 0.1:
			gravity = gravity.normalized()
			var target_pitch := atan2(gravity.x, -gravity.y)
			var target_roll := atan2(gravity.z, -gravity.y)
			var correction_weight := 1.0 - exp(-gravity_correction_strength * delta)
			head_rotation.x = lerp_angle(head_rotation.x, target_pitch, correction_weight)
			head_rotation.z = lerp_angle(head_rotation.z, target_roll, correction_weight)

	head_rotation.x = clamp(head_rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
	head_rotation.z = clamp(head_rotation.z, deg_to_rad(-max_roll), deg_to_rad(max_roll))

	rotation = head_rotation - calibration_rotation

func calibrate() -> void:
	calibration_rotation = head_rotation

func reset_calibration() -> void:
	calibrate()

func get_gyro() -> Vector3:
	return Input.get_gyroscope() if gyro_available else Vector3.ZERO

func get_accelerometer() -> Vector3:
	return Input.get_accelerometer() if accelerometer_available else Vector3.ZERO

func get_gravity() -> Vector3:
	return Input.get_gravity() if gravity_available else Vector3.ZERO
