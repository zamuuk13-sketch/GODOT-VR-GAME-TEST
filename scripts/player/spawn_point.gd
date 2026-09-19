extends Marker3D
class_name VRSpawnPoint

## Ponto único de nascimento do jogador VR.
## Você só precisa posicionar/rotacionar este Marker3D no editor.
@export var player_height: float = 1.70
@export var align_player_to_spawn_rotation := true

func get_spawn_transform() -> Transform3D:
	return global_transform

func get_spawn_position() -> Vector3:
	return global_position

func get_spawn_rotation() -> Basis:
	return global_basis

func get_player_transform() -> Transform3D:
	var transform := global_transform
	transform.origin.y += player_height
	return transform
