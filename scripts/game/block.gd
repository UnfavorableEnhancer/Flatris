extends MeshInstance3D

class_name Block


const GHOST_BLOCK_MAT : Material = preload("res://materials/piece_ghost.material")
const PLACED_BLOCK_MAT : String = "res://materials/base.material"
const PIECE_BLOCK_MAT : String = "res://materials/piece.material"

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
	ORANGE, # L
	BROWN, # BL
	WHITE, # BO
	LIME, # BU
	PINK, # CH
}

const COLOR_VALUES : Dictionary[int, Color] = {
	COLOR.CYAN : Color("05d3f6"),
	COLOR.YELLOW : Color("f2dc04"),
	COLOR.PURPLE : Color("861eff"),
	COLOR.GREEN : Color("11d43f"),
	COLOR.RED : Color("de2e2e"),
	COLOR.BLUE : Color("1e45a8"),
	COLOR.ORANGE : Color("e05e1f"),
	COLOR.BROWN : Color("4b2e12"),
	COLOR.WHITE : Color("cfcfcf"),
	COLOR.LIME : Color("3ab557"),
	COLOR.PINK : Color("c94dc9")
}

var color : int


func _init(type : int, block_color : int) -> void:
	mesh = BoxMesh.new()
	mesh.size.y = 0.1
	color = block_color
	
	match type:
		TYPE.GHOST : mesh.material = GHOST_BLOCK_MAT
		TYPE.PLACED : 
			mesh.material = load(PLACED_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
		TYPE.PIECE : 
			mesh.material = load(PIECE_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
