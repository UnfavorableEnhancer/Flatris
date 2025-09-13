extends Node3D

class_name Piece

## All possible piece rotations
const ROTATIONS : Array[Dictionary] = [
	{}, # O
	{ # I
		
	},
]

## All possible move directions
enum ROTATE_DIRECTION {LEFT, RIGHT}
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

var gamefield : Gamefield = null ## Parent gamefield reference

var piece_type : int = 0 ## Type of piece given by [PieceQueue]
var blocks : Dictionary[Vector2i, Block] = {} ## All blocks inside this piece
var height : int = 10 ## Current height
var color : int = Block.COLOR.RED ## Color of all blocks inside piece

var appearance_delay : float = 10 ## How many physics ticks passes before piece starts falling
var current_appearance_delay : float = appearance_delay

var fall_delay : float = 10 ## How many physics ticks must pass before piece falls down one cell
var current_fall_delay : float = fall_delay

var current_das_side : int = -1
var das_delay : float = 90 ## How many physics ticks must pass before DAS activates 
var current_das_delay : float = das_delay
var das : float = 10 ## DAS frames
var current_das : float = das

var soft_drop : float = 5 ## How many physics ticks must pass before piece quickly falls one cell down
var current_soft_drop : float = soft_drop

var total_drop_delay : float = min_drop_delay ## Total added drop_delay amount
var current_drop_delay : float = min_drop_delay ## How many physics ticks must pass before block finally lands
var drop_delay_inc : float = 30 ## How much current drop delay raises when piece successfully moves
var min_drop_delay : float = 60 ## Mimimal drop delay duration
var max_drop_delay : float = 180 ## Maximum drop delay duration


func _ready() -> void:
	color = PieceQueue.PIECES[piece_type].values()[0]
	for pos : Vector2i in PieceQueue.PIECES[piece_type].keys():
		var block : Block = Block.new(Block.TYPE.PIECE, color)
		blocks[pos] = block
		add_child(block)
	
	_update_blocks()


## Updates blocks positions
func _update_blocks() -> void:
	gamefield._clear_ghosts()
	
	for pos : Vector2i in blocks.keys():
		var block : Block = blocks[pos]
		block.position = Vector3(pos.x * Gamefield.BLOCK_MARGIN, height * Gamefield.BLOCK_Z_MARGIN, pos.y * Gamefield.BLOCK_MARGIN) + Gamefield.FIELD_OFFSET
		
		if height > 0:
			gamefield._place_ghost(pos)
			gamefield._place_heigth_ghost(Vector2i(pos.x, height))


## Advances piece physics
func _physics_process(_delta : float) -> void:
	if current_state == STATE.LANDED:
		current_appearance_delay -= 1
		if (current_appearance_delay < 0) : _finish()
		return
	
	if (Input.is_action_just_pressed(&"swap_hold")) : 
		_finish(true)
		return
	
	if (Input.is_action_just_pressed(&"rotate_left")) : _srs_rotate(ROTATE_DIRECTION.LEFT)
	if (Input.is_action_just_pressed(&"rotate_right")) : _srs_rotate(ROTATE_DIRECTION.RIGHT)
	
	if (Input.is_action_just_pressed(&"hard_drop")):
		_hard_drop()
	
	if (Input.is_action_pressed(&"soft_drop")):
		current_soft_drop -= 1
		if (current_soft_drop < 0):
			if (current_state == STATE.INSIDE_FIELD):
				_land()
				current_soft_drop = 999999999
			elif current_state == STATE.FALLING:
				_fall()
				current_soft_drop = soft_drop
	else:
		if current_state == STATE.FALLING:
			current_soft_drop = soft_drop
	
	for i in MOVE_ACTIONS.size():
		var action : StringName = MOVE_ACTIONS[i]
		var pressed_actions_count : int = 0
		
		if (Input.is_action_just_pressed(action)) : _move(i)
		
		if (Input.is_action_pressed(action)):
			current_das_delay -= 1
			pressed_actions_count += 1
			if not pressed_moves[i]:
				current_das_side = i
				pressed_moves[i] = true
		
		else:
			pressed_moves[i] = false
			if pressed_actions_count :
				current_das_side = -1
				current_das_delay = das_delay
	
	if current_das_side > -1 and current_das_delay < 0:
		current_das -= 1
		if current_das < 0 :
			current_das = das
			if not _move(current_das_side): 
				current_das_side = -1
				current_das_delay = das_delay
	
	if current_state == STATE.INSIDE_FIELD:
		current_drop_delay -= 1
		if current_drop_delay < 0 : 
			current_drop_delay = 999999999
			_land()
	
	elif current_state == STATE.ON_BLOCKS_TOP:
		current_drop_delay -= 1
		if current_drop_delay < 0 : 
			current_drop_delay = 999999999
			_fall()
	
	elif current_state == STATE.FALLING :
		current_fall_delay -= 1
		if (current_fall_delay < 0) :
			current_fall_delay = fall_delay
			_fall()


## Moves piece one cell down
func _fall() -> void:
	height -= 1
	
	for pos in blocks.keys():
		if height == 1 and gamefield.matrix.has(pos):
			if (current_state == STATE.ON_BLOCKS_TOP): 
				_land()
				return
			
			current_drop_delay = min_drop_delay
			current_state = STATE.ON_BLOCKS_TOP
			break
	
	if height == 0:
		current_drop_delay = min_drop_delay
		current_state = STATE.INSIDE_FIELD
	
	_update_blocks()


## Instantly drops piece onto field floor
func _hard_drop() -> void:
	for pos in blocks.keys():
		if gamefield.matrix.has(pos):
			if (current_state == STATE.FALLING):
				height = 1
				current_drop_delay = min_drop_delay
				current_state = STATE.ON_BLOCKS_TOP
				_update_blocks()
				return
	
	_land()


## Moves piece one cell sideways. Returns true on success
func _move(side : int) -> bool:
	var new_blocks : Dictionary[Vector2i, Block]
	
	for pos : Vector2i in blocks.keys():
		var new_pos = pos + MOVE_VALUES[side]
		if current_state == STATE.INSIDE_FIELD and gamefield.matrix.has(new_pos) : return false
		if new_pos.x < 0 or new_pos.x >= gamefield.field_size.x : return false
		if new_pos.y < 0 or new_pos.y >= gamefield.field_size.y : return false
		
		new_blocks[new_pos] = blocks[pos]
	
	if (current_state == STATE.ON_BLOCKS_TOP or current_state == STATE.INSIDE_FIELD) and total_drop_delay != max_drop_delay: 
		# This weird shit is needed in case amount of frames left to add before reaching max is less than frames increment
		current_drop_delay += clampf(max_drop_delay - total_drop_delay, 0, drop_delay_inc)
		total_drop_delay = clampf(total_drop_delay + drop_delay_inc, min_drop_delay, max_drop_delay)
	
	blocks = new_blocks
	_update_blocks()
	return true


## Rotate piece with SRS system
func _srs_rotate(side : int) -> void:
	return
	
	var new_blocks : Dictionary[Vector2i, Block]
	
	for pos : Vector2i in blocks.keys():
		var new_pos = pos + MOVE_VALUES[side]
		
		if current_state == STATE.INSIDE_FIELD and gamefield.matrix.has(new_pos) : return
		if new_pos.x < 0 or new_pos.x >= gamefield.field_size.x : return
		if new_pos.y < 0 or new_pos.y >= gamefield.field_size.y : return
		
		new_blocks[new_pos] = blocks[pos]
	
	if (current_state == STATE.ON_BLOCKS_TOP or current_state == STATE.INSIDE_FIELD) and total_drop_delay != max_drop_delay: 
		# This weird shit is needed in case amount of frames left to add before reaching max is less than frames increment
		current_drop_delay += clampf(max_drop_delay - total_drop_delay, 0, drop_delay_inc)
		total_drop_delay = clampf(total_drop_delay + drop_delay_inc, min_drop_delay, max_drop_delay)
	
	blocks = new_blocks
	_update_blocks()
	return


## Stops piece movement and asks gamefield to spawn blocks
func _land() -> void:
	current_state = STATE.LANDED
	for pos : Vector2i in blocks.keys():
		gamefield._place_block(pos, color)
		blocks[pos].queue_free()


## Removes piece and asks gamefield to give next from queue
## If 'swap_with_hold' is true, place this piece into hold
func _finish(swap_with_hold : bool = false) -> void:
	if swap_with_hold : gamefield._give_hold_piece(piece_type)
	else : gamefield._give_next_piece()
	queue_free()
