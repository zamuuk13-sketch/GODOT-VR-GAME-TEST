class_name TrackingHandSkeleton
extends Node3D

## Intermediate runtime skeleton for MediaPipe hand tracking.
## Stores 21 landmarks in world space for the procedural retargeter.

const LANDMARK_COUNT := 21

var landmarks: Array[Vector3] = []
var valid := false

func _ready() -> void:
	landmarks.resize(LANDMARK_COUNT)
	for i in LANDMARK_COUNT:
		landmarks[i] = global_position

func update_from_mediapipe(raw_landmarks: Array, camera: Camera3D, distance: float, depth: float, vertical_offset: float) -> void:
	if raw_landmarks.size() < LANDMARK_COUNT or not camera:
		valid = false
		return

	for i in LANDMARK_COUNT:
		var p = raw_landmarks[i]
		if not (p is Dictionary):
			valid = false
			return

		var x := (float(p.get("x", 0.5)) - 0.5) * distance
		var y := (0.5 - float(p.get("y", 0.5))) * distance + vertical_offset
		var z := depth + (-float(p.get("z", 0.0)) * distance * 0.40)
		landmarks[i] = camera.global_transform * Vector3(x, y, z)

	valid = true

func get_landmark(index: int) -> Vector3:
	if index < 0 or index >= landmarks.size():
		return global_position
	return landmarks[index]

func get_segment_direction(start_index: int, end_index: int) -> Vector3:
	if not valid:
		return Vector3.ZERO
	var direction := get_landmark(end_index) - get_landmark(start_index)
	return direction.normalized() if direction.length_squared() > 0.000001 else Vector3.ZERO

func get_palm_basis() -> Basis:
	if not valid:
		return Basis.IDENTITY

	var wrist := get_landmark(0)
	var middle := get_landmark(9)
	var index_mcp := get_landmark(5)
	var pinky_mcp := get_landmark(17)

	var forward := (middle - wrist).normalized()
	var across := (pinky_mcp - index_mcp).normalized()
	if forward.length_squared() < 0.0001 or across.length_squared() < 0.0001:
		return Basis.IDENTITY

	var normal := across.cross(forward).normalized()
	if normal.length_squared() < 0.0001:
		return Basis.IDENTITY

	forward = normal.cross(across).normalized()
	return Basis(across, forward, normal).orthonormalized()
