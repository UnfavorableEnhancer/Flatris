extends MeshInstance3D

class_name HeightGhost

const GHOST_BLOCK_MAT : Material = preload("res://materials/piece_ghost.material")


func _init() -> void:
	mesh = BoxMesh.new()
	mesh.size.y = 0.5
	mesh.size.z = 0.1
	mesh.material = GHOST_BLOCK_MAT
