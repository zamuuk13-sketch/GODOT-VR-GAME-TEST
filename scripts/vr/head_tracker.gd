extends Node3D
class_name VRHeadTracker

@export var enabled_on_android := true
@export var use_accelerometer := true
@export var gyro_smoothing := 14.0
@export var max_pitch := 89.0
@export var max_roll := 45.0

var head_rotation := Vector3.ZERO
var calibrated_rotation := Vector3.ZERO
var gyro_available := false
var accelerometer_available := false

func _ready() -> void:
	gyro_available = _sensor_vector_available("get_gyroscope")
	accelerometer_available = _sensor_vector_available("get_accelerometer")
	calibrate()
	set_process(true)

func _process(delta: float) -> void:
	if OS.has_feature("android") and not enabled_on_android:
		return
	if not gyro_available:
		return

	var gyro := Input.get_gyroscope()
	var target := head_rotation + gyro * delta
	target.x = clamp(target.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
	target.z = clamp(target.z, deg_to_rad(-max_roll), deg_to_rad(max_roll))

	var weight := 1.0 - exp(-gyro_smoothing * delta)
	head_rotation = head_rotation.lerp(target, weight)
	rotation = head_rotation - calibrated_rotation

func calibrate() -> void:
	calibrated_rotation = head_rotation

func reset_calibration() -> void:
	calibrate()

func get_gyro() -> Vector3:
	return Input.get_gyroscope() if gyro_available else Vector3.ZERO

func get_accelerometer() -> Vector3:
	return Input.get_accelerometer() if accelerometer_available else Vector3.ZERO

func _sensor_vector_available(method_name: String) -> bool:
	return Input.has_method(method_name)
