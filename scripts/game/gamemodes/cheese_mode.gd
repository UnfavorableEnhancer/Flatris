extends Gamemode

class_name CheeseMode

## What levels player must reach to get certain rank
enum RANKINGS  {
	E = 1, # Eeh..
	D = 2, # Damn
	C = 3, # Cool
	B = 5, # Banger
	A = 10, # Awesome
	S = 15, # Super
	X = 20, # Excellent!
	M = 30 # Master
}

## All values inside LEVEL_SPEED arrays
enum LEVEL_ARRAY {
	FALL_DELAY,
	DAS_DELAY,
	DAS,
	DROP_DELAY_INC,
	DROP_DELAY_MIN,
	DROP_DELAY_MAX,
	APPEARANCE_DELAY,
	LINE_CLEAR_DELAY,
	CHEESE_PERCENTAGE
}

## Dictionary of all delay frames for each specific level
const LEVEL_SPEED : Dictionary = {
	1 : [120, 20, 5, 10, 30, 120, 10, 50, 5.0],
	2 : [90, 20, 5, 10, 30, 120, 10, 50, 10.0],
	3 : [60, 20, 5, 10, 30, 120, 10, 50, 15.0],
	4 : [55, 20, 5, 10, 30, 120, 10, 50, 20.0],
	5 : [50, 20, 5, 10, 30, 120, 10, 50, 25.0],
	6 : [45, 20, 5, 10, 30, 120, 10, 50, 30.0],
	7 : [40, 20, 5, 10, 30, 120, 10, 50, 35.0],
	8 : [35, 20, 5, 10, 30, 120, 10, 50, 40.0],
	9 : [30, 20, 5, 10, 30, 120, 10, 50, 45.0],
	10 : [28, 20, 5, 10, 30, 120, 10, 50, 50.0],
	11 : [26, 20, 5, 10, 30, 120, 10, 50, 52.0],
	12 : [24, 20, 5, 10, 30, 120, 10, 50, 54.0],
	13 : [22, 20, 5, 10, 30, 120, 10, 50, 56.5],
	14 : [20, 10, 5, 10, 30, 120, 10, 50, 58.0],
	15 : [18, 10, 5, 10, 30, 120, 10, 50, 60.0],
	16 : [16, 10, 5, 10, 30, 120, 10, 50, 62.0],
	17 : [14, 10, 5, 10, 30, 120, 10, 50, 64.0],
	18 : [12, 10, 5, 10, 30, 120, 10, 50, 66.0],
	19 : [10, 10, 5, 10, 30, 120, 10, 50, 68.0],
	20 : [5, 10, 3, 10, 30, 120, 10, 50, 70.0],
	22 : [4, 10, 3, 10, 30, 120, 10, 50, 72.0],
	24 : [3, 10, 3, 10, 30, 120, 10, 50, 74.0],
	26 : [2, 10, 3, 10, 30, 120, 10, 50, 76.0],
	28 : [1, 10, 3, 10, 30, 120, 10, 50, 78.0],
	30 : [0, 10, 3, 10, 30, 120, 10, 50, 80.0],
	35 : [0, 10, 3, 10, 30, 120, 10, 50, 85.0],
	40 : [0, 10, 3, 10, 30, 120, 10, 50, 90.0],
}

var level : int = 1 ## Defines game speed and cheese amount
var cheese_amount : int ## Current amount of cheese blocks

var cheese : Dictionary[Vector2i, bool] ## Dictionary of already placed cheese coords
var cheese_rows : Array ## How many cheese is on each row
var cheese_columns : Array ## How many cheese is on each column 

var erased_cheese : int = 0 ## Total amount of erased cheese
var has_erased_cheese : bool = false ## If true has erased cheese in current line clear

var score : int = 0 ## Total game score
var lines : int = 0 ## Total amount of deleted lines


func _init() -> void:
	name = "CheeseMode"


func _ready() -> void:
	super()
	game.game_over_screen_name = "ch_game_over"
	Player.stats["total_cheese_attempts"] += 1


## Called on game reset
func _reset() -> void:
	super()
	
	lines = 0
	score = 0
	level = 1
	
	fall_delay = LEVEL_SPEED[1][LEVEL_ARRAY.FALL_DELAY]
	das_delay = LEVEL_SPEED[1][LEVEL_ARRAY.DAS_DELAY]
	das = LEVEL_SPEED[1][LEVEL_ARRAY.DAS]
	drop_delay_inc = LEVEL_SPEED[1][LEVEL_ARRAY.DROP_DELAY_INC]
	min_drop_delay = LEVEL_SPEED[1][LEVEL_ARRAY.DROP_DELAY_MIN]
	max_drop_delay = LEVEL_SPEED[1][LEVEL_ARRAY.DROP_DELAY_MAX]
	appearance_delay = LEVEL_SPEED[1][LEVEL_ARRAY.APPEARANCE_DELAY]
	line_clear_delay = LEVEL_SPEED[1][LEVEL_ARRAY.LINE_CLEAR_DELAY]
	
	erased_cheese = 0
	cheese_amount = 0
	cheese_rows.clear()
	cheese_columns.clear()
	
	foreground._set_score(0)
	foreground._set_lines(0)
	foreground._set_level(0)


func _set_ruleset(type : int) -> void:
	super(type)
	game.reset_ended.connect(_generate_cheese.bind(LEVEL_SPEED[1][LEVEL_ARRAY.CHEESE_PERCENTAGE]))
	
	for i in field_size.x : cheese_columns.append(0)
	for i in field_size.y : cheese_rows.append(0)


## Called when gamefield deletes lines
func _on_lines_deleted(amount : int) -> void:
	super(amount)
	
	lines += amount
	
	# All clear bonus
	if has_erased_cheese:
		var score_gain : int = 0
		if gamefield.matrix.is_empty():
			score_gain = 10000 * level
			game._add_sound("all_clear")
			Player.stats["total_all_clears"] += 1
		else:
			match amount:
				1 : score_gain = 100 * level
				2 : score_gain = 300 * level
				3 : score_gain = 500 * level
				4 : score_gain = 800 * level
				5 : score_gain = 1200 * level
				6 : score_gain = 1600 * level
				7 : score_gain = 2500 * level
				8 : score_gain = 5000 * level
				9 : score_gain = 7500 * level
				_ : score_gain = 7500 * level
		
		score += score_gain
		Player.stats["total_cheese_score"] += score_gain
		Player._set_stats_top("top_cheese_score_gain", score_gain)
		
		foreground._set_score_animated(score)
		
	foreground._set_lines_animated(lines)


## Called when some block was deleted
func _on_block_deleted(_at_position : Vector2i, is_cheese : bool) -> void:
	if is_cheese : 
		has_erased_cheese = true
		cheese_amount -= 1
		erased_cheese += 1
		Player.stats["total_cheese_erased"] += 1
		if cheese_amount <= 0 : 
			_level_up()


## Raises game level by one
func _level_up() -> void:
	level += 1
	foreground._set_level(level)
	
	if LEVEL_SPEED.has(level):
		fall_delay = LEVEL_SPEED[level][LEVEL_ARRAY.FALL_DELAY]
		das_delay = LEVEL_SPEED[level][LEVEL_ARRAY.DAS_DELAY]
		das = LEVEL_SPEED[level][LEVEL_ARRAY.DAS]
		drop_delay_inc = LEVEL_SPEED[level][LEVEL_ARRAY.DROP_DELAY_INC]
		min_drop_delay = LEVEL_SPEED[level][LEVEL_ARRAY.DROP_DELAY_MIN]
		max_drop_delay = LEVEL_SPEED[level][LEVEL_ARRAY.DROP_DELAY_MAX]
		appearance_delay = LEVEL_SPEED[level][LEVEL_ARRAY.APPEARANCE_DELAY]
		line_clear_delay = LEVEL_SPEED[level][LEVEL_ARRAY.LINE_CLEAR_DELAY]
	
	_generate_cheese(LEVEL_SPEED[level][LEVEL_ARRAY.CHEESE_PERCENTAGE])


## Clears game field and spawns cheese onto it
func _generate_cheese(percentage : int) -> void:
	gamefield._clear_matrix()
	
	cheese_amount = int(field_size.x * field_size.y * (percentage / 100.0))
	cheese_columns.resize(field_size.x)
	cheese_columns.fill(0)
	cheese_rows.resize(field_size.y)
	cheese_rows.fill(0)
	cheese.clear()
	
	_add_cheese(cheese_amount)
	
	# Generate piece holes so game will always have a solution no matter how much cheese we put
	if percentage > 50.0:
		for i : int in range(gamefield.piece_queue.queue.size() - 1, gamefield.piece_queue.queue.size() - 5):
			var piece_hole_index : int = gamefield.piece_queue.queue[i]
			var piece_hole_origin : Vector2i = Vector2i(rng.randi_range(1, field_size.x - 2), rng.randi_range(1, field_size.y - 2))
			var block_positions : Array = PieceQueue.PIECES[piece_hole_index]["positions"]
			
			for block_pos : Vector2i in block_positions:
				gamefield._remove_block(piece_hole_origin + block_pos)
	
	cheese_rows.clear()
	cheese_columns.clear()


func _add_cheese(amount : int) -> void:
	var generated_cheese : int = 0
	while generated_cheese != amount:
		var x = rng.randi_range(0, field_size.x - 1)
		var y = rng.randi_range(0, field_size.y - 1)
		
		if gamefield.matrix.has(Vector2i(x,y)) : continue
		# Dont allow to fill line with cheese blocks or that would be silly
		if cheese_columns[x] == field_size.y - 1 : continue 
		if cheese_rows[y] == field_size.x - 1 : continue 
		
		gamefield._place_block(Vector2i(x,y), true)
		cheese[Vector2i(x,y)] = true
		generated_cheese += 1
		
		if generated_cheese == amount : return
		
		cheese_rows[y] += 1
		cheese_columns[x] += 1


func _game_over(game_over_screen : MenuScreen) -> void:
	var flash_color : Color
	
	if level >= RANKINGS.M : 
		game_over_screen.get_node("Results/Letter").text = "M"
		flash_color = Color("ff1d9c")
	elif level >= RANKINGS.X : 
		game_over_screen.get_node("Results/Letter").text = "X"
		flash_color = Color("1dffaa")
	elif level >= RANKINGS.S : 
		game_over_screen.get_node("Results/Letter").text = "S"
		flash_color = Color("1df4ff")
	elif level >= RANKINGS.A : 
		game_over_screen.get_node("Results/Letter").text = "A"
		flash_color = Color("ff421d")
	elif level >= RANKINGS.B : 
		game_over_screen.get_node("Results/Letter").text = "B"
		flash_color = Color("ffb33c")
	elif level >= RANKINGS.C : 
		game_over_screen.get_node("Results/Letter").text = "C"
		flash_color = Color("fff66d")
	elif level >= RANKINGS.D : 
		game_over_screen.get_node("Results/Letter").text = "D"
		flash_color = Color.WHITE
	elif level >= RANKINGS.E : 
		game_over_screen.get_node("Results/Letter").text = "E"
		flash_color = Color.WHITE
	
	var flash_tween : Tween = create_tween().set_loops(100)
	flash_tween.tween_property(game_over_screen.get_node("Results/Letter"), "self_modulate", flash_color, 0.1)
	flash_tween.tween_property(game_over_screen.get_node("Results/Letter"), "self_modulate", Color.WHITE, 0.1)
	
	game_over_screen.get_node("Results/Score").text = "Score : " + foreground.get_node("Score/Num").text
	game_over_screen.get_node("Results/Lines").text = "Lines : " + foreground.get_node("Lines/Num").text
	game_over_screen.get_node("Results/Time").text = "Time : " + foreground.get_node("Time/Num").text
	game_over_screen.get_node("Results/Level").text = "Level : " + foreground.get_node("Level/Num").text
	
	var text = "000"
	var str_cheese = str(erased_cheese)
	
	if str_cheese.length() < 3:
		str_cheese = text.left(3 - str_cheese.length()) + str_cheese
	
	game_over_screen.get_node("Results/Cheese").text = "Erased cheese : " + str_cheese
