extends Node

class_name PieceQueue

## All possible pieces types
enum PIECE_TYPE {
	O,
	I,
	T,
	S,
	Z,
	L,
	J,
	BL,
	BO,
	BU,
	CH,
}

## All possible pieces forms
const PIECES : Array[Dictionary] = [
	{ # O
		"size" : 4,
		"color" : Block.COLOR.YELLOW,
		"positions" : [Vector2i(1,1),Vector2i(2,1),Vector2i(1,2),Vector2i(2,2)],
	},
	{ # I
		"size" : 4,
		"color" : Block.COLOR.CYAN,
		"positions" : [Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)],
	},
	{ # T
		"size" : 3,
		"color" : Block.COLOR.PURPLE,
		"positions" : [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	},
	{ # S
		"size" : 3,
		"color" : Block.COLOR.GREEN,
		"positions" : [Vector2i(0,1),Vector2i(1,1),Vector2i(1,0),Vector2i(2,0)],
	},
	{ # Z
		"size" : 3,
		"color" : Block.COLOR.RED,
		"positions" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	},
	{ # L
		"size" : 3,
		"color" : Block.COLOR.BLUE,
		"positions" : [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	},
	{ # J
		"size" : 3,
		"color" : Block.COLOR.ORANGE,
		"positions" : [Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(2,0)],
	},
	{ # BL
		"size" : 3,
		"color" : Block.COLOR.BROWN,
		"positions" : [Vector2i(0,2),Vector2i(0,1),Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	},
	{ # BO
		"size" : 3,
		"color" : Block.COLOR.WHITE,
		"positions" : [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(0,2),Vector2i(1,2),Vector2i(2,2)],
	},
	{ # BU
		"size" : 3,
		"color" : Block.COLOR.LIME,
		"positions" : [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	},
	{ # CH
		"size" : 3,
		"color" : Block.COLOR.PINK,
		"positions" : [Vector2i(2,0),Vector2i(1,1),Vector2i(0,2)],
	}
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
		var index = rng.randi_range(0, raw_bag.size() - 1)
		queue.append(raw_bag[index])
		raw_bag.remove_at(index)
	
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
