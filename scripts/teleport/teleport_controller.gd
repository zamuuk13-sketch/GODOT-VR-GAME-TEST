class_name VRTeleportController
extends Node3D

## Stage 5: curved hand-directed teleport.
## Right hand controls the arc. Ring + pinky closure confirms teleport.

signal teleport_target_changed(valid: bool, position: Vector3)
signal teleported(position: Vector3)

@export var player_path: NodePath
@export var visualizer_path: NodePath
@export var collision_mask := 1
@export var arc_points := 28
@export var arc_time := 0.85
@export var gravity := 7.5
@export var hand_forward_distance := 1.0
@export var minimum_hand_direction := 0.08
@export var target_radius := 0.09
@export var confirmation_cooldown := 0.45
@export var ring_close_ratio := 0.62
@export var pinky_close_ratio := 0.62

var player: CharacterBody3D
var visualizer: HandTrackingVisualizer
var arc_mesh: ImmediateMesh
var arc_instance: MeshInstance3D
var target_instance: MeshInstance3D
var valid_material: StandardMaterial3D
var invalid_material: StandardMaterial3D
var hidden_material: StandardMaterial3D
var current_valid := false
var current_target := Vector3.ZERO
var cooldown := 0.0
var was_confirming := false

func _ready() -> void:
	player = get_node_or_null(player_path) as CharacterBody3D
	visualizer = get_node_or_null(visualizer_path) as HandTrackingVisualizer
	_create_visuals()
	_clear_arc()
	_hide_target()

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

	if not visualizer or not visualizer.right_tracking or not visualizer.right_tracking.valid or not visualizer.right_seen:
		_clear_arc()
		_hide_target()
		current_valid = false
		was_confirming = false
		return

	var tracking := visualizer.right_tracking
	var wrist := tracking.get_landmark(0)
	var palm_basis := tracking.get_palm_basis()
	var direction := -palm_basis.z

	if direction.length_squared() < minimum_hand_direction * minimum_hand_direction:
		_clear_arc()
		_hide_target()
		return

	direction = direction.normalized()
	var points := _build_arc(wrist, direction)
	var hit := _find_arc_hit(points)

	_draw_arc(points, hit.valid)
	if hit.valid:
		current_valid = true
		current_target = hit.position
		_show_target(hit.position, true)
		teleport_target_changed.emit(true, hit.position)
	else:
		current_valid = false
		_show_target(points.back(), false)
		teleport_target_changed.emit(false, points.back())

	var confirming := _ring_and_pinky_closed(tracking)
	if confirming and not was_confirming and cooldown <= 0.0 and current_valid:
		_do_teleport(current_target)
	was_confirming = confirming

func _build_arc(origin: Vector3, direction: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var velocity := direction * hand_forward_distance
	for i in arc_points:
		var t := float(i) / float(maxi(1, arc_points - 1)) * arc_time
		points.append(origin + velocity * t + Vector3.DOWN * (0.5 * gravity * t * t))
	return points

func _find_arc_hit(points: Array[Vector3]) -> Dictionary:
	var space := get_world_3d().direct_space_state
	for i in range(1, points.size()):
		var query := PhysicsRayQueryParameters3D.create(points[i - 1], points[i], collision_mask)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var result := space.intersect_ray(query)
		if not result.is_empty():
			var normal: Vector3 = result.get("normal", Vector3.UP)
			# Teleport only to reasonably walkable surfaces, avoiding walls/ceilings.
			if normal.dot(Vector3.UP) >= 0.55:
				return {"valid": true, "position": result["position"]}
			return {"valid": false, "position": result["position"]}
	return {"valid": false, "position": points.back()}

func _ring_and_pinky_closed(tracking: TrackingHandSkeleton) -> bool:
	return _finger_closed(tracking, 13, 14, 16, ring_close_ratio) and _finger_closed(tracking, 17, 18, 20, pinky_close_ratio)

func _finger_closed(tracking: TrackingHandSkeleton, mcp: int, pip: int, tip: int, ratio: float) -> bool:
	var mcp_pos := tracking.get_landmark(mcp)
	var pip_pos := tracking.get_landmark(pip)
	var tip_pos := tracking.get_landmark(tip)
	var palm_size := tracking.get_landmark(5).distance_to(tracking.get_landmark(17))
	if palm_size < 0.001:
		return false
	var tip_to_mcp := tip_pos.distance_to(mcp_pos)
	var straight_length := mcp_pos.distance_to(pip_pos) + pip_pos.distance_to(tip_pos)
	return tip_to_mcp <= straight_length * ratio

func _do_teleport(position: Vector3) -> void:
	if not player:
		return
	player.global_position = Vector3(position.x, position.y + 0.02, position.z)
	player.velocity = Vector3.ZERO
	cooldown = confirmation_cooldown
	teleported.emit(player.global_position)

func _create_visuals() -> void:
	arc_mesh = ImmediateMesh.new()
	arc_instance = MeshInstance3D.new()
	arc_instance.name = "TeleportArc"
	arc_instance.mesh = arc_mesh
	add_child(arc_instance)

	valid_material = _make_material(Color(0.15, 1.0, 0.35, 1.0))
	invalid_material = _make_material(Color(1.0, 0.12, 0.12, 1.0))
	hidden_material = _make_material(Color(0.15, 1.0, 0.35, 0.0))
	arc_instance.material_override = invalid_material

	var sphere := SphereMesh.new()
	sphere.radius = target_radius
	sphere.height = target_radius * 2.0
	target_instance = MeshInstance3D.new()
	target_instance.name = "TeleportTarget"
	target_instance.mesh = sphere
	target_instance.material_override = invalid_material
	add_child(target_instance)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material

func _draw_arc(points: Array[Vector3], valid: bool) -> void:
	if not arc_mesh:
		return
	arc_mesh.clear_surfaces()
	if points.is_empty():
		return
	arc_instance.material_override = valid_material if valid else invalid_material
	arc_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in points:
		arc_mesh.surface_add_vertex(point)
	arc_mesh.surface_end()

func _clear_arc() -> void:
	if arc_mesh:
		arc_mesh.clear_surfaces()

func _show_target(position: Vector3, valid: bool) -> void:
	if not target_instance:
		return
	target_instance.visible = true
	target_instance.global_position = position
	target_instance.material_override = valid_material if valid else invalid_material

func _hide_target() -> void:
	if target_instance:
		target_instance.visible = false
