extends MeshInstance3D

class_name Block

const PLACED_BLOCK_MAT : Material = preload("res://materials/base.material")
const GHOST_BLOCK_MAT : Material = preload("res://materials/piece_ghost.material")
const PIECE_BLOCK_MAT : Material = preload("res://materials/piece.material")

enum TYPE{
	PLACED,
	GHOST,
	PIECE
}

enum COLOR{
	CYAN, # I
	YELLOW, # O
	PURPLE, # T
	GREEN, # S
	RED, # Z
	BLUE, # J
	ORANGE # L
}

var color : int


func _init(type : int, block_color : int) -> void:
	mesh = BoxMesh.new()
	mesh.size.y = 0.1
	color = block_color
	
	match type:
		TYPE.PLACED : mesh.material = PLACED_BLOCK_MAT
		TYPE.GHOST : mesh.material = GHOST_BLOCK_MAT
		TYPE.PIECE : mesh.material = PIECE_BLOCK_MAT
