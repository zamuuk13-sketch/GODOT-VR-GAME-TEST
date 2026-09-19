extends CharacterBody3D
class_name VRTestPlayer

@export var spawn_point_path: NodePath

func _ready() -> void:
	if spawn_point_path != NodePath():
		var spawn := get_node_or_null(spawn_point_path) as Marker3D
		if spawn:
			global_transform = spawn.global_transform

func reset_to_spawn() -> void:
	if spawn_point_path == NodePath():
		return
	var spawn := get_node_or_null(spawn_point_path) as Marker3D
	if spawn:
		global_transform = spawn.global_transform
