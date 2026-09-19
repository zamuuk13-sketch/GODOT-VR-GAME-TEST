extends CharacterBody3D
class_name VRTestPlayer

@export var spawn_point_path: NodePath
@export var use_spawn_point_on_ready := true

func _ready() -> void:
	if use_spawn_point_on_ready:
		call_deferred("reset_to_spawn")

func reset_to_spawn() -> void:
	var spawn := get_node_or_null(spawn_point_path) as VRSpawnPoint
	if not spawn:
		push_warning("VR SpawnPoint não encontrado: " + str(spawn_point_path))
		return

	var spawn_transform := spawn.get_player_transform()
	global_position = spawn_transform.origin
	if spawn.align_player_to_spawn_rotation:
		global_basis = spawn.global_basis
	velocity = Vector3.ZERO

func get_spawn_point() -> VRSpawnPoint:
	return get_node_or_null(spawn_point_path) as VRSpawnPoint
