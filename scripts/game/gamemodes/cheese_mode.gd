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
var cheese : Dictionary[Vector2i, bool] ## Dictionary of all cheese blocks
var cheese_rows : Array ## How many cheese is on each row
var cheese_columns : Array ## How many cheese is on each column 

var score : int = 0 ## Total game score
var lines : int = 0 ## Total amount of deleted lines


func _init() -> void:
	name = "CheeseMode"


func _set_ruleset(type : int) -> void:
	super(type)
	game.reset_ended.connect(_generate_cheese.bind(LEVEL_SPEED[1][LEVEL_ARRAY.CHEESE_PERCENTAGE]))
	
	for i in field_size.x : cheese_columns.append(0)
	for i in field_size.y : cheese_rows.append(0)


## Called when gamefield deletes lines
func _on_lines_deleted(amount : int) -> void:
	lines += amount
	
	# All clear bonus
	if gamefield.matrix.is_empty():
		score += 10000 * level
		game._add_sound("all_clear")
	else:
		match amount:
			1 : score += 100 * level
			2 : score += 300 * level
			3 : score += 500 * level
			4 : score += 800 * level
			5 : score += 1200 * level
			6 : score += 1600 * level
			7 : score += 2500 * level
			8 : score += 5000 * level
			9 : score += 7500 * level
	
	current_damage_recovery -= lines
	if current_damage_recovery <= 0:
		current_damage_recovery = damage_recovery
		if damage > 0:
			last_chance = false
			damage -= 1
			foreground._set_damage(damage)
	
	foreground._set_score_animated(score)
	foreground._set_lines_animated(lines)


## Called when some block was deleted
func _on_block_deleted(at_position : Vector2i) -> void:
	if cheese.has(at_position) : cheese.erase(at_position)
	if cheese.is_empty() : _level_up()


## Called when block tries to spawn in existing one
func _on_block_overlap() -> void:
	game._add_sound("damage")
	
	damage += 1
	foreground._set_damage(int(20 * (damage / float(max_damage))))
	
	if last_chance : game._game_over()
	if damage >= max_damage : last_chance = true


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
	
	var cheese_amount : int = int(field_size.x * field_size.y * (percentage / 100.0))
	var generated_cheese : int = 0
	
	while generated_cheese != cheese_amount:
		for x in field_size.x:
			for y in field_size.y:
				# Dont allow to fill line with cheese blocks or that would be silly
				if cheese_columns[x] == field_size.y - 1 : continue 
				if cheese_rows[y] == field_size.x - 1 : continue 
				
				if (rng.randf() > 0.5):
					gamefield._place_block(Vector2i(x,y), true)
					cheese[Vector2i(x,y)] = true
					generated_cheese += 1
					cheese_rows[y] += 1
					cheese_columns[x] += 1
	
	# Generate piece holes so game will always have a solution no matter how much cheese we put
	if percentage > 50.0:
		var piece_hole_index : int = gamefield.piece_queue.queue[gamefield.piece_queue.size() - 1]
		var piece_hole_origin : Vector2i = Vector2i(rng.randi_range(1, field_size.x - 2), rng.randi_range(1, field_size.y - 2))
		var block_positions : Array = PieceQueue.PIECES[piece_hole_index]["positions"]
		
		for block_pos : Vector2i in block_positions:
			gamefield._remove_block(piece_hole_origin + block_pos)
