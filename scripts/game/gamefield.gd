extends Node3D

class_name Gamefield

const HEIGHT_GHOST_OFFSET : Vector3 = Vector3(-5.0, 0.6, -11.3) ## Offset which points to (0,0) in matrix.x + height coordinates
const HEIGHT_GHOST_X_MARGIN : float = 1.1 ## Distance between height ghosts in X coordinate

const FIELD_OFFSET : Vector3 = Vector3(-5.0, 0.05, -10.4) ## Offset which points to (0,0) in matrix coordinates
const BLOCK_MARGIN : float = 1.1 ## Distance between blocks in X and Y coordinates
const BLOCK_Z_MARGIN : float = 0.6 ## Distance between blocks in Z coordinate

signal block_overlap ## Emitted when some block landed onto existing one
signal lines_cleared(amount : int) ## Emitted when lines were cleared

var field_size : Vector3i = Vector3i(10, 20, 10) ## Size of the game field. X and Y are 2D coordinates and Z is height value
var matrix : Dictionary[Vector2i, Block] = {} ## Game field matrix containing already placed blocks
var ghosts : Array = [] ## Array of currently shown ghosts
var height_ghosts : Dictionary[Vector2i, HeightGhost] = {} ## Dictionary of currently shown height ghosts

var piece_queue : PieceQueue = null
var piece : Piece = null
@onready var blocks_node : Node3D = $Blocks
@onready var ghosts_node : Node3D = $Ghosts


func _process(delta: float) -> void:
	if is_instance_valid(piece):
		$Debug/Fall.text = "current_fall_delay : " + str(piece.current_fall_delay)
		$Debug/DASSide.text = "current_das_side : " + str(piece.current_das_side)
		$Debug/DASDelay.text = "current_das_delay : " + str(piece.current_das_delay)
		$Debug/DAS.text = "current_das : " + str(piece.current_das)
		$Debug/SoftDrop.text = "current_soft_drop : " + str(piece.current_soft_drop)
		$Debug/DropDelay.text = "current_drop_delay : " + str(piece.current_drop_delay)
		$Debug/AppDelay.text = "current_appearance_delay : " + str(piece.current_appearance_delay)
		$Debug/Moves/LEFT.visible = piece.pressed_moves[0]
		$Debug/Moves/RIGHT.visible = piece.pressed_moves[1]
		$Debug/Moves/UP.visible = piece.pressed_moves[2]
		$Debug/Moves/DOWN.visible = piece.pressed_moves[3]
		
		match piece.current_state:
			Piece.STATE.FALLING : $Debug/State.text = "current state : FALLING"
			Piece.STATE.ON_BLOCKS_TOP : $Debug/State.text = "current state : ON_BLOCKS_TOP"
			Piece.STATE.INSIDE_FIELD : $Debug/State.text = "current state : INSIDE_FIELD"
			Piece.STATE.LANDED : $Debug/State.text = "current state : LANDED"


func _ready() -> void:
	piece_queue = PieceQueue.new()
	add_child(piece_queue)
	
	await get_tree().create_timer(1.0).timeout
	_give_next_piece()


## Clears matrix and prepares all values for current field size
func _clear_matrix() -> void:
	for block in matrix.values() : block.queue_free()
	matrix.clear()


## Places block onto matrix 
func _place_block(to_position : Vector2i, color : int) -> void:
	if matrix.has(to_position):
		block_overlap.emit()
		return
	
	var block : Block = Block.new(Block.TYPE.PLACED, color)
	block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.0, to_position.y * BLOCK_MARGIN) + FIELD_OFFSET
	matrix[to_position] = block
	blocks_node.add_child(block)


## Adds next piece from queue
func _give_next_piece() -> void:
	piece = Piece.new()
	piece.piece_type = piece_queue._return_next_piece()
	piece.gamefield = self
	add_child(piece)


## Puts passed piece type into hold and adds previous piece from hold
func _give_hold_piece(piece_type : int) -> void:
	piece = Piece.new()
	piece.piece_type = piece_queue._swap_with_hold(piece_type)
	piece.gamefield = self
	add_child(piece)


## Removes all ghosts from playfield
func _clear_ghosts() -> void:
	for i in ghosts : i.queue_free()
	for i in height_ghosts.values() : i.queue_free()
	ghosts.clear()
	height_ghosts.clear()


## Places ghost block onto matrix. If there's some block, puts ghost on top of block
func _place_ghost(to_position : Vector2i) -> void:
	var ghost_block : Block = Block.new(Block.TYPE.GHOST, 0)
	ghost_block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.0, to_position.y * BLOCK_MARGIN) + FIELD_OFFSET
	ghosts.append(ghost_block)
	ghosts_node.add_child(ghost_block)


## Places height ghost
func _place_heigth_ghost(to_position : Vector2i) -> void:
	if height_ghosts.has(to_position) : return
	if to_position.y == 0 : return
	
	var height_ghost : HeightGhost = HeightGhost.new()
	height_ghost.position = Vector3(to_position.x * HEIGHT_GHOST_X_MARGIN, to_position.y * BLOCK_Z_MARGIN, 0.0) + HEIGHT_GHOST_OFFSET
	
	height_ghosts[to_position] = height_ghost
	ghosts_node.add_child(height_ghost)
