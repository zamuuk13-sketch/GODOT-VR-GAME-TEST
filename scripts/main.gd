extends Node3D

const HOUSE_SCENE := "res://modelos/casa.glb"

func _ready() -> void:
	if ResourceLoader.exists(HOUSE_SCENE):
		var house_scene := load(HOUSE_SCENE)
		if house_scene is PackedScene:
			var house := house_scene.instantiate()
			house.name = "House"
			add_child(house)
			_prepare_house_collisions(house)
	else:
		push_warning("modelo não encontrado: " + HOUSE_SCENE + " — coloque casa.glb em res://modelos.")

func _prepare_house_collisions(root: Node) -> void:
	for node in root.find_children("*", "StaticBody3D", true, false):
		node.collision_layer = 1
		node.collision_mask = 1
