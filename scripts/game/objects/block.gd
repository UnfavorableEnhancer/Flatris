extends MeshInstance3D

class_name Block


const GHOST_BLOCK_MAT : String = "res://materials/piece_ghost.material"
const PLACED_BLOCK_MAT : String = "res://materials/base.material"
const PIECE_BLOCK_MAT : String = "res://materials/piece.material"

enum TYPE{
	PLACED,
	GHOST,
	PIECE,
	CHEESE
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
	CHEESE, # CH
}

const COLOR_VALUES : Dictionary[int, Color] = {
	COLOR.CYAN : Color("05d3f6"),
	COLOR.YELLOW : Color("f2dc04"),
	COLOR.PURPLE : Color("861eff"),
	COLOR.GREEN : Color("13ff0b"),
	COLOR.RED : Color("ef1717"),
	COLOR.BLUE : Color("0e1bea"),
	COLOR.ORANGE : Color("ff3608"),
	COLOR.BROWN : Color("4b2e12"),
	COLOR.WHITE : Color("cfcfcf"),
	COLOR.LIME : Color("3ab557"),
	COLOR.PINK : Color("c94dc9"),
	COLOR.CHEESE : Color("ffd71e")
}

const BLOCK_TEXTURES : Dictionary[int, Texture] = {
	0 : preload("res://images/game/blocks/block1.png"),
	1 : preload("res://images/game/blocks/block2.png"),
	2 : preload("res://images/game/blocks/block3.png"),
	3 : preload("res://images/game/blocks/block4.png"),
	4 : preload("res://images/game/blocks/block5.png"),
	5 : preload("res://images/game/blocks/block6.png"),
	6 : preload("res://images/game/blocks/block7.png"),
	7 : preload("res://images/game/blocks/block8.png"),
	8 : preload("res://images/game/blocks/block9.png"),
	9 : preload("res://images/game/blocks/block10.png"),
	10 : preload("res://images/game/blocks/block11.png"),
	11 : preload("res://images/game/blocks/block12.png"),
	12 : preload("res://images/game/blocks/block13.png"),
	13 : preload("res://images/game/blocks/block14.png"),
	14 : preload("res://images/game/blocks/block15.png"),
	15 : preload("res://images/game/blocks/block16.png"),
	16 : preload("res://images/game/blocks/block17.png"),
	17 : preload("res://images/game/blocks/block18.png"),
	18 : preload("res://images/game/blocks/block19.png"),
	19 : preload("res://images/game/blocks/block20.png"),
	20 : preload("res://images/game/blocks/block21.png"),
	21 : preload("res://images/game/blocks/block22.png"),
	22 : preload("res://images/game/blocks/block23.png"),
	23 : preload("res://images/game/blocks/block24.png"),
	42 : preload("res://images/game/blocks/block25.png"),
}

var color : int

signal removed


func _init(type : int, new_color : int = 0) -> void:
	mesh = BoxMesh.new()
	mesh.size = Vector3(1.5,0.1,1.5)
	
	match type:
		TYPE.GHOST : 
			color = new_color
			name = "BlockGhost"
			mesh.material = load(GHOST_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
		TYPE.PLACED : 
			color = Player.config["color_skin"]
			name = "Block"
			mesh.material = load(PLACED_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
			mesh.material.albedo_texture = BLOCK_TEXTURES[Player.config["block_skin"]]
		TYPE.PIECE : 
			color = new_color
			name = "PieceBlock"
			mesh.material = load(PIECE_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
		TYPE.CHEESE :
			color = COLOR.CHEESE
			name = "CHEESE"
			mesh.material = load(PLACED_BLOCK_MAT).duplicate(true)
			mesh.material.albedo_color = COLOR_VALUES[color]
			mesh.material.albedo_texture = BLOCK_TEXTURES[42]


## Make blocks flash
func _flash() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "mesh:material:albedo_color", Color.WHITE, 0.1)
	tween.tween_property(self, "mesh:material:albedo_color", COLOR_VALUES[color], 0.1)


## Make blocks flash red
func _flash_red() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "mesh:material:albedo_color", Color.RED, 0.1)
	tween.tween_property(self, "mesh:material:albedo_color", COLOR_VALUES[color], 0.1)


## Make block flash rapidly
func _flash_rapidly() -> void:
	var tween : Tween = create_tween().set_loops()
	tween.tween_property(self, "mesh:material:albedo_color", Color.WHITE, 0.1)
	tween.tween_property(self, "mesh:material:albedo_color", COLOR_VALUES[color], 0.1)
