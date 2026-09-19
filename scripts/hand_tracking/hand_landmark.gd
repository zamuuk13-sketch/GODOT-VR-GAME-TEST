class_name HandLandmark
extends RefCounted

var index: int
var position: Vector3
var visibility: float

func _init(p_index: int = 0, p_position: Vector3 = Vector3.ZERO, p_visibility: float = 0.0) -> void:
	index = p_index
	position = p_position
	visibility = p_visibility
