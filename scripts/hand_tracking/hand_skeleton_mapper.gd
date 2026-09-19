class_name HandSkeletonMapper
extends Node

const LANDMARK_COUNT := 21

# MediaPipe landmark indices:
# 0 wrist
# 1-4 thumb
# 5-8 index
# 9-12 middle
# 13-16 ring
# 17-20 pinky
const SEGMENTS := {
	"thumb": [[1, 2], [2, 3], [3, 4]],
	"index": [[5, 6], [6, 7], [7, 8]],
	"middle": [[9, 10], [10, 11], [11, 12]],
	"ring": [[13, 14], [14, 15], [15, 16]],
	"pinky": [[17, 18], [18, 19], [19, 20]]
}

var skeleton: Skeleton3D
var bone_targets: Dictionary = {}
var smoothing := 24.0
var override_amount := 1.0

func setup(target_skeleton: Skeleton3D) -> void:
	skeleton = target_skeleton
	bone_targets.clear()
	_discover_bones()

func _discover_bones() -> void:
	if not skeleton:
		return

	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i).to_lower()
		var key := _classify_bone(bone_name)
		if key != "":
			bone_targets[i] = key

func _classify_bone(name: String) -> String:
	var n := name.replace("-", "_").replace(".", "_")

	if "wrist" in n or "hand" in n or "palm" in n:
		return "wrist"

	var finger := ""
	if "thumb" in n:
		finger = "thumb"
	elif "index" in n or "pointer" in n:
		finger = "index"
	elif "middle" in n:
		finger = "middle"
	elif "ring" in n:
		finger = "ring"
	elif "pinky" in n or "little" in n:
		finger = "pinky"

	if finger == "":
		return ""

	var level := 0
	if "prox" in n or "mcp" in n or "_1" in n or n.ends_with("1"):
		level = 0
	elif "inter" in n or "pip" in n or "_2" in n or n.ends_with("2"):
		level = 1
	elif "dist" in n or "dip" in n or "_3" in n or n.ends_with("3"):
		level = 2
	elif "_4" in n or n.ends_with("4") or "tip" in n:
		level = 2
	else:
		level = 0

	return "%s_%d" % [finger, level]

func apply_landmarks(landmarks: Array, delta: float) -> void:
	if not skeleton or landmarks.size() < LANDMARK_COUNT:
		return

	var weight := 1.0 - exp(-smoothing * delta)

	# Rotate each finger bone so its long axis follows the corresponding
	# MediaPipe landmark segment.
	for bone_idx in bone_targets:
		var target_name: String = bone_targets[bone_idx]
		if target_name == "wrist":
			continue

		var parts := target_name.split("_")
		if parts.size() != 2:
			continue

		var finger: String = parts[0]
		var level := int(parts[1])
		if not SEGMENTS.has(finger):
			continue

		var pair: Array = SEGMENTS[finger][level]
		var a := _landmark_vector(landmarks[pair[0]])
		var b := _landmark_vector(landmarks[pair[1]])
		var target_dir := (b - a).normalized()
		if target_dir.length_squared() < 0.0001:
			continue

		var rest_pose := skeleton.get_bone_global_rest(bone_idx)
		var rest_dir := _rest_bone_direction(bone_idx, rest_pose)
		if rest_dir.length_squared() < 0.0001:
			continue

		var delta_rotation := Quaternion(rest_dir, target_dir)
		var desired_basis := Basis(delta_rotation) * rest_pose.basis
		var current_pose := skeleton.get_bone_global_pose(bone_idx)
		var desired := Transform3D(desired_basis, current_pose.origin)
		var blended := current_pose.interpolate_with(desired, weight)

		skeleton.set_bone_global_pose_override(
			bone_idx,
			blended,
			override_amount,
			false
		)

func _rest_bone_direction(bone_idx: int, rest_pose: Transform3D) -> Vector3:
	var children := skeleton.get_bone_children(bone_idx)
	if children.is_empty():
		var parent := skeleton.get_bone_parent(bone_idx)
		if parent >= 0:
			return (rest_pose.origin - skeleton.get_bone_global_rest(parent).origin).normalized()
		return Vector3.FORWARD

	var child_rest := skeleton.get_bone_global_rest(children[0])
	return (child_rest.origin - rest_pose.origin).normalized()

func _landmark_vector(value: Variant) -> Vector3:
	if value is Dictionary:
		return Vector3(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0)),
			float(value.get("z", 0.0))
		)
	return Vector3.ZERO
