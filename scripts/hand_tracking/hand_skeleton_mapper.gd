class_name HandSkeletonMapper
extends Node

## Procedural retargeting for the exact handvr.glb rig.
## No prerecorded hand animations are used.

const BONE_NAMES := {
	"hand": "hand_R_00",
	"thumb": ["thumb01_R_01", "thumb02_R_02", "thumb03_R_03"],
	"index": ["index00_R_04", "index01_R_05", "index02_R_06", "index03_R_07"],
	"middle": ["middle00_R_08", "middle01_R_09", "middle02_R_010", "middle03_R_011"],
	"ring": ["ring00_R_012", "ring01_R_013", "ring02_R_014", "ring03_R_015"],
	"pinky": ["pinky00_R_016", "pinky01_R_017", "pinky02_R_018", "pinky03_R_019"]
}

const SEGMENTS := {
	"thumb": [[1, 2], [2, 3], [3, 4]],
	"index": [[5, 6], [6, 7], [7, 8]],
	"middle": [[9, 10], [10, 11], [11, 12]],
	"ring": [[13, 14], [14, 15], [15, 16]],
	"pinky": [[17, 18], [18, 19], [19, 20]]
}

var skeleton: Skeleton3D
var smoothing := 24.0
var override_amount := 1.0
var _bone_map: Dictionary = {}
var _rest_dirs: Dictionary = {}

func setup(target_skeleton: Skeleton3D) -> void:
	skeleton = target_skeleton
	_bone_map.clear()
	_rest_dirs.clear()
	if not skeleton:
		return
	for group_name in BONE_NAMES:
		var names = BONE_NAMES[group_name]
		if names is Array:
			for bone_name in names:
				_register_bone(str(bone_name))
		else:
			_register_bone(str(names))

func _register_bone(bone_name: String) -> void:
	var index := skeleton.find_bone(bone_name)
	if index < 0:
		push_warning("handvr.glb bone not found: " + bone_name)
		return
	_bone_map[bone_name] = index
	_rest_dirs[index] = _rest_bone_direction(index)

func apply_tracking_skeleton(tracking: TrackingHandSkeleton, delta: float) -> void:
	if not skeleton or not tracking or not tracking.valid:
		return

	var weight := 1.0 - exp(-smoothing * delta)
	_apply_palm_pose(tracking, weight)

	for finger in SEGMENTS:
		var names: Array = BONE_NAMES[finger]
		var pairs: Array = SEGMENTS[finger]
		for level in pairs.size():
			var bone_name := str(names[level])
			if not _bone_map.has(bone_name):
				continue
			var pair: Array = pairs[level]
			var world_direction := tracking.get_segment_direction(pair[0], pair[1])
			if world_direction.length_squared() < 0.0001:
				continue
			var local_direction := skeleton.global_transform.basis.inverse() * world_direction
			_apply_direction(int(_bone_map[bone_name]), local_direction, weight)

func _apply_palm_pose(tracking: TrackingHandSkeleton, weight: float) -> void:
	var name := str(BONE_NAMES["hand"])
	if not _bone_map.has(name):
		return
	var bone_idx := int(_bone_map[name])
	var rest_pose := skeleton.get_bone_global_rest(bone_idx)
	var target_basis := skeleton.global_transform.basis.inverse() * tracking.get_palm_basis()
	if target_basis == Basis.IDENTITY:
		return
	target_basis = target_basis.orthonormalized()
	var rest_basis := rest_pose.basis.orthonormalized()
	var delta_rotation := target_basis.get_rotation_quaternion() * rest_basis.get_rotation_quaternion().inverse()
	var desired := Transform3D(Basis(delta_rotation) * rest_pose.basis, skeleton.get_bone_global_pose(bone_idx).origin)
	var blended := skeleton.get_bone_global_pose(bone_idx).interpolate_with(desired, weight)
	skeleton.set_bone_global_pose_override(bone_idx, blended, override_amount, false)

func _apply_direction(bone_idx: int, target_direction: Vector3, weight: float) -> void:
	var rest_direction: Vector3 = _rest_dirs.get(bone_idx, Vector3.ZERO)
	if target_direction.length_squared() < 0.0001 or rest_direction.length_squared() < 0.0001:
		return
	var delta_rotation := Quaternion(rest_direction.normalized(), target_direction.normalized())
	var rest_pose := skeleton.get_bone_global_rest(bone_idx)
	var desired := Transform3D(Basis(delta_rotation) * rest_pose.basis, skeleton.get_bone_global_pose(bone_idx).origin)
	var blended := skeleton.get_bone_global_pose(bone_idx).interpolate_with(desired, weight)
	skeleton.set_bone_global_pose_override(bone_idx, blended, override_amount, false)

func _rest_bone_direction(bone_idx: int) -> Vector3:
	var rest_pose := skeleton.get_bone_global_rest(bone_idx)
	var children := skeleton.get_bone_children(bone_idx)
	if not children.is_empty():
		return (skeleton.get_bone_global_rest(children[0]).origin - rest_pose.origin).normalized()
	var parent := skeleton.get_bone_parent(bone_idx)
	if parent >= 0:
		return (rest_pose.origin - skeleton.get_bone_global_rest(parent).origin).normalized()
	return Vector3.UP
