extends Node3D

class_name Gamefield

const FIELD_CELL_SIZE : float = 32.0 ## Size of single block cell in pixels

const HEIGTH_FIELD_CELL_SIZE : float = 16.0 ## Heigth of single heigth ghost cell in pixels
const HEIGTH_FIELD_MARGIN : float = 0.5 ## Heigth of single heigth ghost cell in meters

const BORDER_SIZE_OFFSET : float = 0.25 ## Border size offset which makes border slightly larger than playfield
const HEIGTH_BORDER_SIZE_OFFSET : float = 0.5 ## Height border size offset which makes border slightly larger than playfield

const BLOCK_MARGIN : float = 1.6 ## Distance between blocks in X and Y axis in meters
const BLOCK_Z_MARGIN : float = 0.8 ## Distance between blocks in Z axis in meters

signal block_overlap ## Emitted when some block landed onto existing one
signal lines_cleared(amount : int) ## Emitted when lines were cleared

var line_clear_delay : float = 30 ## Amount of frames after line clear which is added to appearance_delay
var appearance_delay : float = 10 ## How many physics ticks passes before next piece is given
var current_appearance_delay : float = 60

var height_ghost_offset : Vector3 ## Offset which points to (0,0) in matrix.x + height coordinates
var field_offset : Vector3 ## Offset which points to (0,0) in matrix coordinates
var field_center : Vector2 ## Gamefield center in matrix coordinates

var field_size : Vector3i = Vector3i(10, 10, 10) ## Size of the game field. X and Y are 2D coordinates and Z is height value
var matrix : Dictionary[Vector2i, Block] = {} ## Game field matrix containing already placed blocks
var ghosts : Array = [] ## Array of currently shown ghosts
var height_ghosts : Dictionary[Vector2i, HeightGhost] = {} ## Dictionary of currently shown height ghosts

var scanned_blocks_positions : Array[Vector2i] = [] ## Positions of blocks which passed line check and which must be deleted after appearance_delay passes

var piece : Piece = null
var has_swapped_hold : bool = false

@onready var piece_queue : PieceQueue = $PieceQueue
@onready var blocks_node : Node3D = $Blocks
@onready var ghosts_node : Node3D = $Ghosts


func _ready() -> void:
	_render_matrix()
	_clear_matrix()


## Sets gamefield visual size to match current matrix size
func _render_matrix() -> void:
	var field_x_size : float = FIELD_CELL_SIZE * field_size.x
	var field_y_size : float = FIELD_CELL_SIZE * field_size.y
	var field_z_size : float = HEIGTH_FIELD_CELL_SIZE * field_size.z
	
	$Field.region_rect.size.x = field_x_size
	$Field.region_rect.size.y = field_y_size
	
	$HeigthField.region_rect.size.x = field_x_size 
	$HeigthField.region_rect.size.y = field_z_size
	$HeigthField.position.y = HEIGTH_FIELD_MARGIN * field_size.z 
	
	$Border.scale.x = field_size.x + BORDER_SIZE_OFFSET
	$Border.scale.y = field_size.y + BORDER_SIZE_OFFSET
	
	$HeightBorder.scale.x = field_size.x + BORDER_SIZE_OFFSET
	$HeightBorder.scale.y = field_size.z + HEIGTH_BORDER_SIZE_OFFSET
	$HeightBorder.position.y = HEIGTH_FIELD_MARGIN * field_size.z 
	
	field_offset.x = (field_size.x / 2.0 - 0.5) * (-BLOCK_MARGIN)
	field_offset.y = 0.05
	field_offset.z = (field_size.y / 2.0 - 0.5) * (-BLOCK_MARGIN)
	
	height_ghost_offset.x = (field_size.x / 2.0 - 0.5) * (-BLOCK_MARGIN)
	height_ghost_offset.y = 0.6
	height_ghost_offset.z = -19.95
	
	field_center.x = int(field_size.x / 2.0) - 1
	field_center.y = int(field_size.y / 2.0) - 1


## Clears matrix
func _clear_matrix() -> void:
	for block in matrix.values() : block.queue_free()
	matrix.clear()


## Places block onto matrix 
func _place_block(to_position : Vector2i, color : int) -> void:
	if matrix.has(to_position):
		block_overlap.emit()
		return
	
	var block : Block = Block.new(Block.TYPE.PLACED, color)
	block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.0, to_position.y * BLOCK_MARGIN) + field_offset
	matrix[to_position] = block
	blocks_node.add_child(block)
	block._flash()


## Removes all scanned by line check blocks
func _remove_scanned_blocks() -> void:
	for pos : Vector2i in scanned_blocks_positions:
		print(pos)
		matrix[pos].queue_free()
		matrix.erase(pos)


## Processes single physics tick
func _physics() -> void:
	var piece_exists : bool = is_instance_valid(piece)
	
	if not piece_exists and current_appearance_delay > 0:
		current_appearance_delay -= 1
		if current_appearance_delay <= 0:
			_remove_scanned_blocks()
			_give_next_piece() 
		return
	
	if (Input.is_action_just_pressed(&"swap_hold")) and not has_swapped_hold: 
		var piece_type : int = piece.piece_type
		piece.queue_free()
		_give_hold_piece(piece_type)
	
	if piece_exists: 
		piece._physics()
		return
	
	if _line_check() : current_appearance_delay += line_clear_delay
	current_appearance_delay += appearance_delay


## Checks full blocks lines and erases them if found
func _line_check() -> bool:
	var erased_lines_amount : int = 0
	scanned_blocks_positions.clear()
	
	for y in field_size.y:
		var current_line_blocks_positions : Array[Vector2i] = []
		for x in field_size.x:
			if matrix.has(Vector2i(x,y)) : current_line_blocks_positions.append(Vector2i(x,y))
		
		if current_line_blocks_positions.size() == field_size.x:
			for pos : Vector2i in current_line_blocks_positions:
				matrix[pos]._flash_rapidly()
				scanned_blocks_positions.append(pos)
				erased_lines_amount += 1
	
	lines_cleared.emit(erased_lines_amount)
	return erased_lines_amount > 0


## Adds next piece from queue
func _give_next_piece() -> void:
	has_swapped_hold = false
	piece = Piece.new()
	piece.piece_type = piece_queue._return_next_piece()
	piece.gamefield = self
	piece.anchor = field_center
	add_child(piece)


## Puts passed piece type into hold and adds previous piece from hold
func _give_hold_piece(piece_type : int) -> void:
	var next_piece_type : int = piece_queue._swap_with_hold(piece_type)
	if next_piece_type == -1 : next_piece_type = piece_queue._return_next_piece()
	
	has_swapped_hold = true
	piece = Piece.new()
	piece.piece_type = next_piece_type
	piece.gamefield = self
	piece.anchor = field_center
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
	ghost_block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.0, to_position.y * BLOCK_MARGIN) + field_offset
	ghosts.append(ghost_block)
	ghosts_node.add_child(ghost_block)


## Places height ghost
func _place_heigth_ghost(to_position : Vector2i) -> void:
	if height_ghosts.has(to_position) : return
	if to_position.y == 0 : return
	
	var height_ghost : HeightGhost = HeightGhost.new()
	height_ghost.position = Vector3(to_position.x * BLOCK_MARGIN, to_position.y * BLOCK_Z_MARGIN, 0.0) + height_ghost_offset
	
	height_ghosts[to_position] = height_ghost
	ghosts_node.add_child(height_ghost)
