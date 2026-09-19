extends Node3D

const HOUSE_SCENE := "res://modelos/casa.glb"
const HOUSE_NAME := "House"

@export var house_position := Vector3.ZERO
@export var house_rotation_degrees := Vector3.ZERO
@export var house_scale := Vector3.ONE
@export var create_missing_collisions := true

var house: Node3D

func _ready() -> void:
	_load_house_environment()

func _load_house_environment() -> void:
	if not ResourceLoader.exists(HOUSE_SCENE):
		push_error("casa.glb não encontrado em " + HOUSE_SCENE)
		return

	var house_scene := load(HOUSE_SCENE) as PackedScene
	if not house_scene:
		push_error("Não foi possível carregar " + HOUSE_SCENE)
		return

	house = house_scene.instantiate() as Node3D
	if not house:
		push_error("casa.glb não produziu um Node3D válido.")
		return

	house.name = HOUSE_NAME
	house.position = house_position
	house.rotation_degrees = house_rotation_degrees
	house.scale = house_scale
	add_child(house)

	_prepare_house_environment(house)

func _prepare_house_environment(root: Node) -> void:
	# Mantém o GLB como o ambiente visual principal.
	# Colisões que já vierem no arquivo são habilitadas para o mundo e teleporte.
	var collision_count := 0

	for node in root.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		body.collision_layer = 1
		body.collision_mask = 1
		collision_count += 1

	for node in root.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape.shape:
			shape.disabled = false

	# Se o GLB não trouxer corpos de colisão, não inventamos uma geometria
	# baseada em nomes desconhecidos. O diagnóstico informa isso para a etapa
	# de colisão do mapa, preservando o modelo visual.
	if collision_count == 0 and create_missing_collisions:
		push_warning("casa.glb carregada como ambiente, mas não possui StaticBody3D. Colisões do mapa ainda precisam ser geradas.")
