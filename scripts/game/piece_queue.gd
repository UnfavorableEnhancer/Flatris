extends Node

class_name PieceQueue

## All possible pieces
const PIECES : Array[Dictionary] = [
	{ # O
		Vector2i(4,9) : Block.COLOR.YELLOW,
		Vector2i(5,9) : Block.COLOR.YELLOW,
		Vector2i(4,10) : Block.COLOR.YELLOW,
		Vector2i(5,10) : Block.COLOR.YELLOW,
	},
	{ # I
		Vector2i(3,9) : Block.COLOR.CYAN,
		Vector2i(4,9) : Block.COLOR.CYAN,
		Vector2i(5,9) : Block.COLOR.CYAN,
		Vector2i(6,9) : Block.COLOR.CYAN,
	},
	{ # T
		Vector2i(3,9) : Block.COLOR.PURPLE,
		Vector2i(4,9) : Block.COLOR.PURPLE,
		Vector2i(5,9) : Block.COLOR.PURPLE,
		Vector2i(4,8) : Block.COLOR.PURPLE,
	},
	{ # S
		Vector2i(3,9) : Block.COLOR.GREEN,
		Vector2i(4,9) : Block.COLOR.GREEN,
		Vector2i(4,8) : Block.COLOR.GREEN,
		Vector2i(5,8) : Block.COLOR.GREEN,
	},
	{ # Z
		Vector2i(3,8) : Block.COLOR.RED,
		Vector2i(4,8) : Block.COLOR.RED,
		Vector2i(4,9) : Block.COLOR.RED,
		Vector2i(5,9) : Block.COLOR.RED,
	},
	{ # L
		Vector2i(3,8) : Block.COLOR.BLUE,
		Vector2i(3,9) : Block.COLOR.BLUE,
		Vector2i(4,9) : Block.COLOR.BLUE,
		Vector2i(5,9) : Block.COLOR.BLUE,
	},
	{ # J
		Vector2i(3,9) : Block.COLOR.ORANGE,
		Vector2i(4,9) : Block.COLOR.ORANGE,
		Vector2i(5,9) : Block.COLOR.ORANGE,
		Vector2i(5,8) : Block.COLOR.ORANGE,
	},
]

const QUEUE_VISIBLE_SIZE : int = 4 ## Amount of visible in foreground queue pieces

signal queue_updated(new_queue : Array[int]) ## Emitted when piece queue changes
signal hold_updated(new_hold : int) ## Emitted when piece in hold changes

var gamefield : Gamefield = null ## Parent gamefield reference

var queue : Array[int] = [] ## Current queue of pieces
var hold : int = -1 ## Current piece in hold

var rng : RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_shuffle()


## Adds random pieces to the queue with 7-bag system
func _shuffle() -> void:
	var raw_bag : Array = [0,1,2,3,4,5,6]
	
	while not raw_bag.is_empty():
		var piece_type = rng.randi_range(0, raw_bag.size() - 1)
		queue.append(piece_type)
		raw_bag.pop_front()
	
	queue_updated.emit(queue)


## Returns latest stored in queue piece and shifts it right
func _return_next_piece() -> int:
	var next_piece_type : int = queue.pop_back()
	
	if queue.size() < QUEUE_VISIBLE_SIZE: _shuffle()
	else: queue_updated.emit(queue)
	
	return next_piece_type


## Places passed piece type into hold and returns previous piece type from hold if it existed
func _swap_with_hold(piece_type : int) -> int:
	var prev_hold : int = hold
	hold = piece_type
	hold_updated.emit(hold)
	
	if prev_hold == -1 : return -1
	else : return prev_hold
