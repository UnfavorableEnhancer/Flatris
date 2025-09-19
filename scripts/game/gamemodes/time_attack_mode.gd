extends Gamemode

class_name TimeAttackMode

## What completion time player must reach to get certain rank
enum RANKINGS  {
	E = 600, # Eeh..
	D = 300, # Damn
	C = 180, # Cool
	B = 120, # Banger
	A = 90, # Awesome
	S = 60, # Super
	X = 45, # Excellent!
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
	LINE_CLEAR_DELAY
}

## Dictionary of all delay frames for each specific ruleset
const RULESET_SPEED : Dictionary = {
	RULESET.STANDARD : [30, 20, 5, 10, 30, 120, 10, 50],
	RULESET.HARD : [10, 10, 3, 10, 30, 120, 10, 50],
	RULESET.EXTREME : [1, 5, 1, 10, 30, 120, 10, 20],
	RULESET.REVERSI : [30, 20, 5, 10, 30, 120, 10, 50],
	RULESET.ZONE : [30, 20, 5, 10, 30, 120, 10, 50],
	RULESET.DEBUG : [30, 20, 5, 10, 30, 120, 10, 50],
}

const LINES_AMOUNT : int = 40 ## Amount of lines required to delete to finish TA attempt

var lines : int = 0 ## Total amount of deleted lines
var ta_start_ticks : int = 0 ## Ticks from which time attack started


func _ready() -> void:
	super()
	game.reset_ended.connect(_start_countdown)


func _set_ruleset(type : int) -> void:
	super(type)
	
	fall_delay = RULESET_SPEED[type][LEVEL_ARRAY.FALL_DELAY]
	das_delay = RULESET_SPEED[type][LEVEL_ARRAY.DAS_DELAY]
	das = RULESET_SPEED[type][LEVEL_ARRAY.DAS]
	drop_delay_inc = RULESET_SPEED[type][LEVEL_ARRAY.DROP_DELAY_INC]
	min_drop_delay = RULESET_SPEED[type][LEVEL_ARRAY.DROP_DELAY_MIN]
	max_drop_delay = RULESET_SPEED[type][LEVEL_ARRAY.DROP_DELAY_MAX]
	appearance_delay = RULESET_SPEED[type][LEVEL_ARRAY.APPEARANCE_DELAY]
	line_clear_delay = RULESET_SPEED[type][LEVEL_ARRAY.LINE_CLEAR_DELAY]


## Stores tick when TA started
func _start_countdown() -> void:
	ta_start_ticks = Time.get_ticks_msec()


## Called when gamefield deletes lines
func _on_lines_deleted(amount : int) -> void:
	lines += amount
	
	current_damage_recovery -= lines
	if current_damage_recovery <= 0:
		current_damage_recovery = damage_recovery
		if damage > 0:
			last_chance = false
			damage -= 1
			foreground._set_damage(damage)
	
	foreground._set_lines_animated(lines)


## Called when block tries to spawn in existing one
func _on_block_overlap() -> void:
	game._add_sound("damage")
	
	damage += 1
	foreground._set_damage(int(20 * (damage / float(max_damage))))
	
	if last_chance : game._game_over()
	if damage >= max_damage : last_chance = true
