extends Node3D

class_name Piece

## All possible piece rotaions
enum ROTATE_DIRECTION {CLOCKWISE, COUNTER_CLOCKWISE}
enum ROTATION {NONE, R, TWICE, L}
# Courtesy to Tetris Wiki for SRS wallkick data
const WALLKICK_3x3 : Dictionary[StringName, Array] = {
	&"0-R" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,-2)],
	&"R-0" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)],
	&"R-2" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)],
	&"2-R" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,-2)],
	&"2-L" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)],
	&"L-2" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)],
	&"L-0" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)],
	&"0-L" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)]
}
const WALLKICK_4x4 : Dictionary[StringName, Array] = {
	&"0-R" : [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)],
	&"R-0" : [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)],
	&"R-2" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)],
	&"2-R" : [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(1,-2),Vector2i(-2,1)],
	&"2-L" : [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)],
	&"L-2" : [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)],
	&"L-0" : [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(1,-2),Vector2i(-2,1)],
	&"0-L" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)],
}

## All possible move directions
enum MOVE_DIRECTION {LEFT, RIGHT, UP, DOWN}
const MOVE_ACTIONS : Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MOVE_VALUES : Array[Vector2i] = [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]
var pressed_moves : Array[bool] = [false, false, false, false]

## All possible piece states
enum STATE {
	FALLING, ## Piece is falling down one cell after fall_delay
	ON_BLOCKS_TOP, ## Piece is on top of blocks and has current_drop_delay left to move freely
	INSIDE_FIELD, ## Piece is inside gamefield and again has current_drop_delay left to move within other blocks boundaries
	LANDED ## Piece is landed and awaits appearance_delay expire to ask gamefield to give new piece
}
var current_state : int = STATE.FALLING ## Current piece fall state

var gamemode : Gamemode = null ## Gamemode reference
var gamefield : Gamefield = null ## Parent gamefield reference

var piece_type : int = 0 ## Type of piece given by [PieceQueue]
var blocks : Dictionary[Vector2i, Block] = {} ## All blocks inside this piece
var height : int = 10 ## Current height
var color : int = Block.COLOR.RED ## Color of all blocks inside piece

var piece_rotation : int = 0 ## Current piece rotation
var anchor : Vector2i = Vector2i(3,3) ## Piece top-left position, used for rotation and initial block placement
var size : int = 3 ## Size of piece matrix, used for rotation

var current_fall_delay : float = 60 ## Current delay before block drops down one cell

var current_das_side : int = -1 ## Latest pressed direction where DAS will go
var current_das_delay : float = 10 ## Current delay before DAS starts
var current_das : float = 5 ## Button hold frames left before moving piece one cell

var soft_drop : float = 5 ## How many physics ticks must pass before piece quickly falls one cell down
var current_soft_drop : float = soft_drop

var total_drop_delay : float = 30 ## Total added drop_delay amount
var current_drop_delay : float = 30 ## How many physics ticks must pass before block finally lands



func _ready() -> void:
	color = PieceQueue.PIECES[piece_type]["color"]
	size = PieceQueue.PIECES[piece_type]["size"]
	
	for pos : Vector2i in PieceQueue.PIECES[piece_type]["positions"]:
		var real_pos : Vector2i = pos + anchor
		var block : Block = Block.new(Block.TYPE.PIECE, color)
		blocks[real_pos] = block
		add_child(block)
	
	_update_blocks()


## Updates blocks positions
func _update_blocks() -> void:
	gamefield._clear_ghosts()
	
	for pos : Vector2i in blocks.keys():
		var block : Block = blocks[pos]
		block.position = Vector3(pos.x * Gamefield.BLOCK_MARGIN, height * Gamefield.BLOCK_Z_MARGIN, pos.y * Gamefield.BLOCK_MARGIN) + gamefield.field_offset
		
		if height > 0:
			gamefield._place_ghost(pos)
			gamefield._place_heigth_ghost(Vector2i(pos.x, height))


## Advances piece physics
func _physics() -> void:
	if current_state == STATE.LANDED:
		return
	
	if (Input.is_action_just_pressed(&"rotate_left")) : _srs_rotate(ROTATE_DIRECTION.COUNTER_CLOCKWISE)
	if (Input.is_action_just_pressed(&"rotate_right")) : _srs_rotate(ROTATE_DIRECTION.CLOCKWISE)
	if (Input.is_action_just_pressed(&"hard_drop")) : _hard_drop()
	
	_process_soft_drop()
	_process_das()
	
	if current_state == STATE.INSIDE_FIELD:
		current_drop_delay -= 1
		if current_drop_delay <= 0 : 
			current_drop_delay = 999999999
			_land()
			return
	
	elif current_state == STATE.ON_BLOCKS_TOP:
		current_drop_delay -= 1
		if current_drop_delay <= 0 : 
			current_drop_delay = 999999999
			_fall()
	
	elif current_state == STATE.FALLING and not Input.is_action_pressed(&"soft_drop"):
		current_fall_delay -= 1
		if (current_fall_delay <= 0) :
			current_fall_delay = gamemode.fall_delay
			_fall()


## Moves piece one cell down
func _fall() -> void:
	height -= 1
	
	for pos in blocks.keys():
		if gamefield.matrix.has(pos):
			if height == 0:
				_land()
				return
			
			if height == 1:
				current_drop_delay = gamemode.min_drop_delay
				current_state = STATE.ON_BLOCKS_TOP
				break
	
	if height == 0:
		current_drop_delay = gamemode.min_drop_delay
		current_state = STATE.INSIDE_FIELD
	
	_update_blocks()


## Instantly drops piece onto field floor
func _hard_drop() -> void:
	for pos in blocks.keys():
		if gamefield.matrix.has(pos):
			if (current_state == STATE.FALLING):
				height = 1
				current_drop_delay = gamemode.min_drop_delay
				current_state = STATE.ON_BLOCKS_TOP
				_update_blocks()
				return
	
	_land()


## Drops piece quicker
func _process_soft_drop() -> void:
	if (Input.is_action_pressed(&"soft_drop")):
		if current_state == STATE.INSIDE_FIELD:
			return
		
		if current_state == STATE.ON_BLOCKS_TOP:
			for pos in blocks.keys():
				if gamefield.matrix.has(pos):
					current_soft_drop = soft_drop
					return
		
		current_soft_drop -= 1
		if (current_soft_drop <= 0):
			_fall()
			current_soft_drop = soft_drop
	else:
		current_soft_drop = soft_drop


## Moves piece quicker
func _process_das() -> void:
	var pressed_actions_count : int = 0
	for i in MOVE_ACTIONS.size():
		var action : StringName = MOVE_ACTIONS[i]
		
		if (Input.is_action_just_pressed(action)) : _move(i)
		
		if (Input.is_action_pressed(action)):
			pressed_actions_count += 1
			if not pressed_moves[i]:
				current_das_side = i
				pressed_moves[i] = true
		else:
			pressed_moves[i] = false
	
	if pressed_actions_count > 0:
		current_das_delay -= 1
	else:
		current_das_side = -1
		current_das_delay = gamemode.das_delay
	
	if current_das_side > -1 and current_das_delay <= 0:
		current_das -= 1
		if current_das <= 0 :
			current_das = gamemode.das
			if not _move(current_das_side) : current_das_delay = gamemode.das_delay


## Moves piece one cell sideways. Returns true on success
func _move(side : int) -> bool:
	var moved_blocks : Dictionary[Vector2i, Block]
	
	for pos : Vector2i in blocks.keys():
		var new_pos = pos + MOVE_VALUES[side]
		if current_state == STATE.INSIDE_FIELD and gamefield.matrix.has(new_pos) : return false
		if new_pos.x < 0 or new_pos.x >= gamemode.field_size.x : return false
		if new_pos.y < 0 or new_pos.y >= gamemode.field_size.y : return false
		
		moved_blocks[new_pos] = blocks[pos]
	
	anchor += MOVE_VALUES[side]
	
	if (current_state == STATE.ON_BLOCKS_TOP or current_state == STATE.INSIDE_FIELD) and total_drop_delay != gamemode.max_drop_delay: 
		# This weird shit is needed in case amount of frames left to add before reaching max is less than frames increment
		current_drop_delay += clampf(gamemode.max_drop_delay - total_drop_delay, 0, gamemode.drop_delay_inc)
		total_drop_delay = clampf(total_drop_delay + gamemode.drop_delay_inc, gamemode.min_drop_delay, gamemode.max_drop_delay)
	
	blocks = moved_blocks
	_update_blocks()
	return true


## Rotate piece with SRS system
func _srs_rotate(side : int) -> void:
	if piece_type == PieceQueue.PIECE_TYPE.O : return
	
	var new_rotation : int
	var rotated_blocks : Dictionary[Vector2i, Block]
	var rotation_matrix : Array[Array] = []
	
	var wallkick_dict : Dictionary[StringName, Array] = WALLKICK_3x3
	if size == 4 : wallkick_dict = WALLKICK_4x4
	var wallkick_data : Array
	
	# Build rotation matrix
	for y in size:
		rotation_matrix.append([])
		for x in size:
			if blocks.has(Vector2i(anchor.x + x, anchor.y + y)) : rotation_matrix[y].append(1)
			else: rotation_matrix[y].append(0)
	
	if (side == ROTATE_DIRECTION.CLOCKWISE):
		match piece_rotation:
			ROTATION.NONE: 
				wallkick_data = wallkick_dict[&"0-R"]
				new_rotation = ROTATION.R
			ROTATION.R: 
				wallkick_data = wallkick_dict[&"R-2"]
				new_rotation = ROTATION.TWICE
			ROTATION.TWICE: 
				wallkick_data = wallkick_dict[&"2-L"]
				new_rotation = ROTATION.L
			ROTATION.L: 
				wallkick_data = wallkick_dict[&"L-0"]
				new_rotation = ROTATION.NONE
		
		# Transpose matrix
		var transposed_matrix : Array[Array] = []
		for i in size:
			transposed_matrix.append([])
			for j in size:
				transposed_matrix[i].append(rotation_matrix[j][i])
		
		# Reverse rows
		for i in size : transposed_matrix[i].reverse()
		rotation_matrix = transposed_matrix
		
	else:
		match piece_rotation:
			ROTATION.NONE: 
				wallkick_data = wallkick_dict[&"0-L"]
				new_rotation = ROTATION.L
			ROTATION.L: 
				wallkick_data = wallkick_dict[&"L-2"]
				new_rotation = ROTATION.TWICE
			ROTATION.TWICE: 
				wallkick_data = wallkick_dict[&"2-R"]
				new_rotation = ROTATION.R
			ROTATION.R: 
				wallkick_data = wallkick_dict[&"R-0"]
				new_rotation = ROTATION.NONE
		
		# Reverse rows
		for i in size : rotation_matrix[i].reverse()
		
		# Transpose matrix
		var transposed_matrix : Array[Array] = []
		for i in size:
			transposed_matrix.append([])
			for j in size:
				transposed_matrix[i].append(rotation_matrix[j][i])
		rotation_matrix = transposed_matrix
	
	# Get rotated block coords
	var i : int = 0
	for y in size :
		for x in size :
			if rotation_matrix[y][x] == 1 : 
				rotated_blocks[Vector2i(anchor.x + x, anchor.y + y)] = blocks.values()[i]
				i += 1
	
	# Wallkick
	var wallkick : Vector2i
	var kicked_blocks : Dictionary[Vector2i, Block]
	for test in 5:
		wallkick = wallkick_data[test]
		kicked_blocks = _test_wallkick(rotated_blocks, wallkick)
		if not kicked_blocks.is_empty() : break
	
	if kicked_blocks.is_empty() : return
	
	anchor += wallkick
	blocks = kicked_blocks
	piece_rotation = new_rotation
	_update_blocks()
	
	if (current_state == STATE.ON_BLOCKS_TOP or current_state == STATE.INSIDE_FIELD) and total_drop_delay != gamemode.max_drop_delay: 
		# This weird shit is needed in case amount of frames left to add before reaching max is less than frames increment
		current_drop_delay += clampf(gamemode.max_drop_delay - total_drop_delay, 0, gamemode.drop_delay_inc)
		total_drop_delay = clampf(total_drop_delay + gamemode.drop_delay_inc, gamemode.min_drop_delay, gamemode.max_drop_delay)


## Tests wallkick for given blocks dictionary and returns kicked blocks dictionary on success
func _test_wallkick(test_blocks : Dictionary[Vector2i, Block], wallkick : Vector2i) -> Dictionary[Vector2i, Block]:
	var kicked_blocks : Dictionary[Vector2i, Block]
	for pos : Vector2i in test_blocks.keys():
		var new_pos = pos + wallkick
		
		if current_state == STATE.INSIDE_FIELD and gamefield.matrix.has(new_pos) : return {}
		if new_pos.x < 0 or new_pos.x >= gamemode.field_size.x : return {}
		if new_pos.y < 0 or new_pos.y >= gamemode.field_size.y : return {}
		
		kicked_blocks[new_pos] = test_blocks[pos]
	
	return kicked_blocks


## Stops piece movement and asks gamefield to spawn blocks, then deletes this piece
func _land() -> void:
	gamefield._clear_ghosts()
	
	current_state = STATE.LANDED
	for pos : Vector2i in blocks.keys():
		gamefield._place_block(pos, color)
	
	queue_free()
