extends Gamemode

class_name MarathonMode

## What levels player must reach to get certain rank
enum RANKINGS  {
	E = 1, # Eeh..
	D = 2, # Damn
	C = 5, # Cool
	B = 10, # Banger
	A = 15, # Awesome
	S = 20, # Super
	X = 30, # Excellent!
	M = 50 # Master
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
	NEXT_LEVEL_REQ
}

## Dictionary of all delay frames for each specific level
const LEVEL_SPEED : Dictionary = {
	1 : [120, 20, 5, 10, 30, 120, 10, 50, 4],
	2 : [90, 20, 5, 10, 30, 120, 10, 50, 4],
	3 : [60, 20, 5, 10, 30, 120, 10, 50, 4],
	4 : [55, 20, 5, 10, 30, 120, 10, 50, 4],
	5 : [50, 20, 5, 10, 30, 120, 10, 50, 5],
	6 : [45, 20, 5, 10, 30, 120, 10, 50, 5],
	7 : [40, 20, 5, 10, 30, 120, 10, 50, 5],
	8 : [35, 20, 5, 10, 30, 120, 10, 50, 5],
	9 : [30, 20, 5, 10, 30, 120, 10, 50, 6],
	10 : [28, 20, 5, 10, 30, 120, 10, 50, 6],
	11 : [26, 20, 5, 10, 30, 120, 10, 50, 6],
	12 : [24, 20, 5, 10, 30, 120, 10, 50, 6],
	13 : [22, 20, 5, 10, 30, 120, 10, 50, 6],
	14 : [20, 10, 5, 10, 30, 120, 10, 50, 8],
	15 : [18, 10, 5, 10, 30, 120, 10, 50, 8],
	16 : [16, 10, 5, 10, 30, 120, 10, 50, 8],
	17 : [14, 10, 5, 10, 30, 120, 10, 50, 8],
	18 : [12, 10, 5, 10, 30, 120, 10, 50, 8],
	19 : [10, 10, 5, 10, 30, 120, 10, 50, 10],
	20 : [5, 10, 3, 10, 30, 120, 10, 50, 12],
	22 : [4, 10, 3, 10, 30, 120, 10, 50, 12],
	24 : [3, 10, 3, 10, 30, 120, 10, 50, 12],
	26 : [2, 10, 3, 10, 30, 120, 10, 50, 12],
	28 : [1, 10, 3, 10, 30, 120, 10, 50, 12],
	30 : [0, 10, 3, 10, 30, 120, 10, 50, 16],
	33 : [0, 5, 3, 10, 25, 110, 10, 45, 16],
	36 : [0, 5, 3, 10, 25, 100, 10, 40, 16],
	39 : [0, 5, 3, 10, 25, 90, 10, 35, 16],
	40 : [0, 5, 3, 10, 25, 85, 10, 30, 16],
	45 : [0, 5, 3, 10, 25, 80, 10, 25, 16],
	50 : [0, 5, 2, 5, 20, 75, 10, 20, 20],
	60 : [0, 5, 2, 5, 20, 70, 10, 18, 20],
	70 : [0, 5, 2, 5, 20, 65, 10, 16, 20],
	80 : [0, 3, 1, 5, 15, 60, 10, 14, 20],
	90 : [0, 3, 1, 5, 15, 55, 10, 12, 20],
	100 : [0, 3, 1, 5, 10, 50, 10, 10, 20],
	120 : [0, 3, 1, 5, 10, 45, 10, 8, 20],
	140 : [0, 3, 1, 5, 10, 40, 10, 6, 20],
	160 : [0, 3, 1, 5, 10, 35, 10, 4, 20],
	180 : [0, 3, 1, 5, 10, 30, 10, 2, 20],
	200 : [0, 3, 1, 5, 10, 25, 10, 0, 20],
	225 : [0, 3, 1, 5, 10, 20, 10, 0, 20],
	250 : [0, 3, 1, 5, 10, 10, 10, 0, 20],
}

var score : int = 0 ## Total game score
var lines : int = 0 ## Total amount of deleted lines

var level : int = 1 ## Defines game speed
var next_level_req : int = 4 ## Amount of lines needed to clear before level up
var latest_next_level_req : int = 4 ## Latest amount of lines needed to clear before level up


func _init() -> void:
	name = "MarathonMode"


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
	
	next_level_req -= amount
	if next_level_req <= 0 : _level_up()
	
	if damage > 0:
		current_damage_recovery -= amount
		if current_damage_recovery <= 0:
			current_damage_recovery = damage_recovery
			last_chance = false
			damage -= 1
			foreground._set_damage(damage)
	
	foreground._set_score_animated(score)
	foreground._set_lines_animated(lines)


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
		latest_next_level_req = LEVEL_SPEED[level][LEVEL_ARRAY.NEXT_LEVEL_REQ]
	
	next_level_req = latest_next_level_req
