extends MeshInstance3D

class_name HeightGhost

const GHOST_BLOCK_MAT : Material = preload("res://materials/piece_ghost.material")


func _init() -> void:
	name = "HeigthGhost"
	mesh = BoxMesh.new()
	mesh.size = Vector3(1.5,0.7,0.1)
	mesh.material = GHOST_BLOCK_MAT
