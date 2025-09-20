extends Node3D

class_name Gamefield

enum GRAVITY_SIDE {UP, DOWN, LEFT, RIGHT}

const FIELD_CELL_SIZE : float = 32.0 ## Size of single block cell in pixels

const HEIGTH_FIELD_CELL_SIZE : float = 16.0 ## Heigth of single heigth ghost cell in pixels
const HEIGTH_FIELD_MARGIN : float = 0.5 ## Heigth of single heigth ghost cell in meters

const BORDER_SIZE_OFFSET : float = 0.25 ## Border size offset which makes border slightly larger than playfield
const HEIGTH_BORDER_SIZE_OFFSET : float = 0.5 ## Height border size offset which makes border slightly larger than playfield

const BLOCK_MARGIN : float = 1.6 ## Distance between blocks in X and Y axis in meters
const BLOCK_Z_MARGIN : float = 0.8 ## Distance between blocks in Z axis in meters

signal block_overlap ## Emitted when some block landed onto existing one
signal block_deleted(coords : Vector2i, is_cheese : bool) ## Emitted when some block was deleted
signal lines_cleared(amount : int) ## Emitted when lines were cleared

var game : Game = null ## Parent game reference
var gamemode : Gamemode = null ## Gamemode reference

var current_appearance_delay : float = 1 ## Current amount of frames left before giving next piece from queue

var height_ghost_offset : Vector3 ## Offset which points to (0,0) in matrix.x + height coordinates
var field_offset : Vector3 ## Offset which points to (0,0) in matrix coordinates
var field_center : Vector2 ## Gamefield center in matrix coordinates

var matrix : Dictionary[Vector2i, Block] = {} ## Game field matrix containing already placed blocks
var ghosts : Array = [] ## Array of currently shown ghosts
var height_ghosts : Dictionary[Vector2i, HeightGhost] = {} ## Dictionary of currently shown height ghosts

var scanned_blocks_positions : Array[Vector2i] = [] ## Positions of blocks which passed line check and which must be deleted after appearance_delay passes
var scanned_rows : Array[int] = [] ## Rows which got lines
var scanned_columns : Array[int] = [] ## Columns which got lines

var piece : Piece = null
var has_swapped_hold : bool = false

@onready var piece_queue : PieceQueue = $PieceQueue
@onready var blocks_node : Node3D = $Blocks
@onready var ghosts_node : Node3D = $Ghosts


func _ready() -> void:
	piece_queue.gamefield = self


## Sets gamefield visual size to match current matrix size
func _render_matrix() -> void:
	var field_x_size : float = FIELD_CELL_SIZE * gamemode.field_size.x
	var field_y_size : float = FIELD_CELL_SIZE * gamemode.field_size.y
	var field_z_size : float = HEIGTH_FIELD_CELL_SIZE * gamemode.field_size.z
	
	$Field.region_rect.size.x = field_x_size
	$Field.region_rect.size.y = field_y_size
	
	$HeigthField.region_rect.size.x = field_x_size 
	$HeigthField.region_rect.size.y = field_z_size
	$HeigthField.position.y = HEIGTH_FIELD_MARGIN * gamemode.field_size.z 
	
	$Border.scale.x = gamemode.field_size.x + BORDER_SIZE_OFFSET
	$Border.scale.y = gamemode.field_size.y + BORDER_SIZE_OFFSET
	
	$HeightBorder.scale.x = gamemode.field_size.x + BORDER_SIZE_OFFSET
	$HeightBorder.scale.y = gamemode.field_size.z + HEIGTH_BORDER_SIZE_OFFSET
	$HeightBorder.position.y = HEIGTH_FIELD_MARGIN * gamemode.field_size.z 
	
	field_offset.x = (gamemode.field_size.x / 2.0 - 0.5) * (-BLOCK_MARGIN)
	field_offset.y = 0.05
	field_offset.z = (gamemode.field_size.y / 2.0 - 0.5) * (-BLOCK_MARGIN)
	
	height_ghost_offset.x = (gamemode.field_size.x / 2.0 - 0.5) * (-BLOCK_MARGIN)
	height_ghost_offset.y = 0.6
	height_ghost_offset.z = -19.95
	
	field_center.x = int(gamemode.field_size.x / 2.0) - 1
	field_center.y = int(gamemode.field_size.y / 2.0) - 1


## Clears matrix
func _clear_matrix() -> void:
	for block in matrix.values() : block.queue_free()
	matrix.clear()
	scanned_rows.clear()
	scanned_columns.clear()


## Places block onto matrix 
func _place_block(to_position : Vector2i, cheese : bool = false) -> void:
	if matrix.has(to_position):
		matrix[to_position]._flash_red()
		block_overlap.emit()
		return
	
	var block : Block
	if cheese : block = Block.new(Block.TYPE.CHEESE)
	else : block = Block.new(Block.TYPE.PLACED)
	block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.0, to_position.y * BLOCK_MARGIN) + field_offset
	matrix[to_position] = block
	blocks_node.add_child(block)
	block._flash()


## Removes block from matrix 
func _remove_block(from_position : Vector2i) -> void:
	if matrix.has(from_position):
		matrix[from_position].queue_free()
		matrix.erase(from_position)


## Removes all scanned by line check blocks
func _remove_scanned_blocks() -> void:
	for pos : Vector2i in scanned_blocks_positions:
		if not matrix.has(pos) : continue
		var block : Block = matrix[pos]
		
		if block.color == Block.COLOR.CHEESE: block_deleted.emit(pos, true)
		else: block_deleted.emit(pos, false)
		
		block.queue_free()
		matrix.erase(pos)


## Processes single physics tick
func _physics() -> void:
	var piece_exists : bool = is_instance_valid(piece)
	
	if not piece_exists and current_appearance_delay > 0:
		current_appearance_delay -= 1
		if current_appearance_delay <= 0:
			_remove_scanned_blocks()
			_gravity_pull()
			_give_next_piece() 
		return
	
	if (Input.is_action_just_pressed(&"swap_hold")) and not has_swapped_hold: 
		var piece_type : int = piece.piece_type
		piece.queue_free()
		_give_hold_piece(piece_type)
	
	if piece_exists: 
		piece._physics()
		return
	
	if _line_check() : current_appearance_delay += gamemode.line_clear_delay
	current_appearance_delay += gamemode.appearance_delay


## Pulls all blocks from 4 sides into center, filling empty space left by cleared lines
func _gravity_pull() -> void:
	var new_matrix : Dictionary[Vector2i, Block]
	var move_amount : Array = []
	move_amount.resize(gamemode.field_size.y)
	move_amount.fill(0)
	
	for y in scanned_rows:
		if y > field_center.y:
			for dy in range(y, gamemode.field_size.y):
				move_amount[dy] += 1
		else:
			for dy in range(y, -1, -1):
				move_amount[dy] += 1
	
	for x in gamemode.field_size.x:
		for y in range(field_center.y, -1 , -1):
			if matrix.has(Vector2i(x,y)):
				var block : Block = matrix[Vector2i(x,y)]
				block.position.z += move_amount[y] * BLOCK_MARGIN
				new_matrix[Vector2i(x, y + move_amount[y])] = block
		for y in range(field_center.y+1, gamemode.field_size.y):
			if matrix.has(Vector2i(x,y)):
				var block : Block = matrix[Vector2i(x,y)]
				block.position.z -= move_amount[y] * BLOCK_MARGIN
				new_matrix[Vector2i(x, y - move_amount[y])] = block
	
	matrix = new_matrix.duplicate(true)
	new_matrix.clear()
	move_amount.resize(gamemode.field_size.x)
	move_amount.fill(0)
	
	for x in scanned_columns:
		if x > field_center.x:
			for dx in range(x, gamemode.field_size.x):
				move_amount[dx] += 1
		else:
			for dx in range(x, -1, -1):
				move_amount[dx] += 1
	
	for y in gamemode.field_size.y:
		for x in range(field_center.x, -1 , -1):
			if matrix.has(Vector2i(x,y)):
				var block : Block = matrix[Vector2i(x,y)]
				block.position.x += move_amount[x] * BLOCK_MARGIN
				new_matrix[Vector2i(x + move_amount[x], y)] = block
		for x in range(field_center.x+1, gamemode.field_size.x):
			if matrix.has(Vector2i(x,y)):
				var block : Block = matrix[Vector2i(x,y)]
				block.position.x -= move_amount[x] * BLOCK_MARGIN
				new_matrix[Vector2i(x - move_amount[x], y)] = block
	
	matrix = new_matrix.duplicate(true)
	scanned_rows.clear()
	scanned_columns.clear()


## Checks full blocks lines and erases them if found
func _line_check() -> bool:
	var erased_lines_amount : int = 0
	scanned_blocks_positions.clear()
	
	for y in gamemode.field_size.y:
		var current_line_blocks_positions : Array[Vector2i] = []
		for x in gamemode.field_size.x:
			if matrix.has(Vector2i(x,y)) : current_line_blocks_positions.append(Vector2i(x,y))
		
		if current_line_blocks_positions.size() == gamemode.field_size.x:
			for pos : Vector2i in current_line_blocks_positions:
				matrix[pos]._flash_rapidly()
				scanned_blocks_positions.append(pos)
			
			erased_lines_amount += 1
			scanned_rows.append(y)
	
	for x in gamemode.field_size.x:
		var current_line_blocks_positions : Array[Vector2i] = []
		for y in gamemode.field_size.y:
			if matrix.has(Vector2i(x,y)) : current_line_blocks_positions.append(Vector2i(x,y))
		
		if current_line_blocks_positions.size() == gamemode.field_size.y:
			for pos : Vector2i in current_line_blocks_positions:
				matrix[pos]._flash_rapidly()
				scanned_blocks_positions.append(pos)
			
			erased_lines_amount += 1
			scanned_columns.append(x)
	
	if erased_lines_amount > 0 : 
		lines_cleared.emit(erased_lines_amount)
		game._add_sound("line_clear" + str(clampi(erased_lines_amount, 1, 10)))
	
	return erased_lines_amount > 0


## Adds next piece from queue
func _give_next_piece() -> void:
	has_swapped_hold = false
	piece = Piece.new()
	piece.piece_type = piece_queue._return_next_piece()
	piece.gamefield = self
	piece.gamemode = gamemode
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
	piece.gamemode = gamemode
	piece.anchor = field_center
	add_child(piece)


## Removes all ghosts from playfield
func _clear_ghosts() -> void:
	for i in ghosts : i.queue_free()
	for i in height_ghosts.values() : i.queue_free()
	ghosts.clear()
	height_ghosts.clear()


## Places ghost block onto matrix. If there's some block, puts ghost on top of block
func _place_ghost(to_position : Vector2i, color : int, permanent : bool = false) -> void:
	var ghost_block : Block = Block.new(Block.TYPE.GHOST, color)
	ghost_block.position = Vector3(to_position.x * BLOCK_MARGIN, 0.01, to_position.y * BLOCK_MARGIN) + field_offset
	if not permanent : ghosts.append(ghost_block)
	ghosts_node.add_child(ghost_block)


## Places height ghost
func _place_height_ghost(to_position : Vector2i, color : int) -> void:
	if height_ghosts.has(to_position) : return
	if to_position.y == 0 : return
	
	var height_ghost : HeightGhost = HeightGhost.new(color)
	height_ghost.position = Vector3(to_position.x * BLOCK_MARGIN, to_position.y * BLOCK_Z_MARGIN, 0.0) + height_ghost_offset
	
	height_ghosts[to_position] = height_ghost
	ghosts_node.add_child(height_ghost)
