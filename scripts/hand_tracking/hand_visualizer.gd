class_name HandTrackingVisualizer
extends Node3D

@export var manager_path: NodePath
@export var camera_path: NodePath
@export var hand_model_path := "res://modelos/handvr.glb"
@export var hand_distance := 0.75
@export var hand_vertical_offset := -0.10
@export var hand_depth := -0.45
@export var hand_scale := 1.0
@export var smoothing := 22.0

var manager: HandTrackingManager
var camera: Camera3D
var left_hand: Node3D
var right_hand: Node3D
var left_tracking: TrackingHandSkeleton
var right_tracking: TrackingHandSkeleton
var left_mapper: HandSkeletonMapper
var right_mapper: HandSkeletonMapper
var left_seen := false
var right_seen := false

func _ready() -> void:
	manager = get_node_or_null(manager_path) as HandTrackingManager
	camera = get_node_or_null(camera_path) as Camera3D
	if not ResourceLoader.exists(hand_model_path):
		push_warning("handvr.glb não encontrado: " + hand_model_path)
		return
	if manager:
		manager.hand_tracking_updated.connect(_on_tracking_updated)
	_create_hand_models()

func _create_hand_models() -> void:
	var packed := load(hand_model_path) as PackedScene
	if not packed:
		push_error("Não foi possível carregar " + hand_model_path)
		return

	left_hand = packed.instantiate()
	left_hand.name = "LeftHandVisual"
	left_hand.scale = Vector3(-hand_scale, hand_scale, hand_scale)
	add_child(left_hand)

	right_hand = packed.instantiate()
	right_hand.name = "RightHandVisual"
	right_hand.scale = Vector3.ONE * hand_scale
	add_child(right_hand)

	left_tracking = TrackingHandSkeleton.new()
	left_tracking.name = "LeftTrackingSkeleton"
	add_child(left_tracking)

	right_tracking = TrackingHandSkeleton.new()
	right_tracking.name = "RightTrackingSkeleton"
	add_child(right_tracking)

	left_mapper = _make_mapper(left_hand)
	right_mapper = _make_mapper(right_hand)
	left_hand.visible = false
	right_hand.visible = false

func _make_mapper(root: Node3D) -> HandSkeletonMapper:
	var skeleton := _find_skeleton(root)
	if not skeleton:
		push_warning("handvr.glb não contém Skeleton3D.")
		return null
	var mapper := HandSkeletonMapper.new()
	add_child(mapper)
	mapper.smoothing = smoothing
	mapper.setup(skeleton)
	return mapper

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null

func _on_tracking_updated(data: Dictionary) -> void:
	var hands = data.get("hands", [])
	if not (hands is Array):
		return

	left_seen = false
	right_seen = false

	for hand_data in hands:
		if not (hand_data is Dictionary):
			continue
		var landmarks = hand_data.get("landmarks", [])
		if not (landmarks is Array) or landmarks.size() < 21:
			continue

		var label := str(hand_data.get("label", "")).to_lower()
		var target: Node3D
		var tracking: TrackingHandSkeleton
		var mapper: HandSkeletonMapper

		if "left" in label:
			target = left_hand
			tracking = left_tracking
			mapper = left_mapper
			left_seen = true
		elif "right" in label:
			target = right_hand
			tracking = right_tracking
			mapper = right_mapper
			right_seen = true
		else:
			continue

		if not target or not tracking or not mapper:
			continue

		tracking.update_from_mediapipe(landmarks, camera, hand_distance, hand_depth, hand_vertical_offset)
		_update_hand_transform(target, tracking)
		mapper.apply_tracking_skeleton(tracking, get_process_delta_time())
		target.visible = true

	if left_hand and not left_seen:
		left_hand.visible = false
	if right_hand and not right_seen:
		right_hand.visible = false

func _update_hand_transform(hand: Node3D, tracking: TrackingHandSkeleton) -> void:
	if not camera or not tracking.valid:
		return

	var weight := 1.0 - exp(-smoothing * get_process_delta_time())
	hand.global_position = hand.global_position.lerp(tracking.get_landmark(0), weight)

	var target_basis := tracking.get_palm_basis()
	if target_basis != Basis.IDENTITY:
		var current_rotation := hand.global_basis.get_rotation_quaternion()
		var target_rotation := target_basis.get_rotation_quaternion()
		hand.global_basis = Basis(current_rotation.slerp(target_rotation, weight))

func _process(_delta: float) -> void:
	if left_tracking and left_tracking.valid and left_hand and left_hand.visible:
		_update_hand_transform(left_hand, left_tracking)
		if left_mapper:
			left_mapper.apply_tracking_skeleton(left_tracking, get_process_delta_time())
	if right_tracking and right_tracking.valid and right_hand and right_hand.visible:
		_update_hand_transform(right_hand, right_tracking)
		if right_mapper:
			right_mapper.apply_tracking_skeleton(right_tracking, get_process_delta_time())
