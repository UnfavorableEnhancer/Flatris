extends MeshInstance3D

class_name HeightGhost

const GHOST_BLOCK_MAT : String = "res://materials/piece_ghost.material"


func _init(color : int = 0) -> void:
	name = "HeigthGhost"
	mesh = BoxMesh.new()
	mesh.size = Vector3(1.5,0.7,0.1)
	mesh.material = load(GHOST_BLOCK_MAT).duplicate(true)
	mesh.material.albedo_color = Block.COLOR_VALUES[color]
	
