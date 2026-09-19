extends Marker3D
class_name VRSpawnPoint

@export var player_height: float = 1.70

func get_spawn_transform() -> Transform3D:
	return global_transform
