extends Gamemode

class_name TimeAttackMode

## What completion time player must reach to get certain rank
enum RANKINGS  {
	D = 600000, # Damn
	C = 300000, # Cool
	B = 180000, # Banger
	A = 120000, # Awesome
	S = 90000, # Super
	X = 60000, # Excellent!
	M = 42000 # Master
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
	RULESET.STANDARD : [30, 12, 5, 10, 30, 120, 10, 50],
	RULESET.HARD : [10, 12, 5, 10, 30, 120, 10, 50],
	RULESET.EXTREME : [2, 8, 3, 10, 30, 120, 10, 20],
	RULESET.REVERSI : [30, 20, 5, 10, 30, 120, 10, 50],
	RULESET.ZONE : [30, 20, 5, 10, 30, 120, 10, 50],
	RULESET.CUSTOM : [30, 12, 5, 10, 30, 120, 10, 50],
	RULESET.DEBUG : [30, 20, 5, 10, 30, 120, 10, 50],
}

const LINES_GOAL : int = 40 ## Amount of lines required to delete to finish TA attempt

var flash_tween : Tween

var lines : int = 0 ## Total amount of deleted lines
var ta_start_ticks : int = 0 ## Ticks from which time attack started
var ta_pause_ticks : int = 0 ## Ticks on which game was paused


func _init() -> void:
	name = "TimeAttackMode"


func _ready() -> void:
	super()
	game.game_over_screen_name = "ta_game_over"
	Player.stats["total_time_attack_attempts"] += 1


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


## Called on game reset
func _reset() -> void:
	super()
	
	lines = 0
	foreground.lines_goal = LINES_GOAL
	foreground._set_lines(0)


## Called on game reset end
func _on_reset_ended() -> void:
	super()
	
	ta_start_ticks = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if ta_start_ticks > 0 and ta_pause_ticks == 0:
		foreground._set_time_in_milliseconds(Time.get_ticks_msec() - ta_start_ticks)


## Called on game pause
func _pause(on : bool) -> void:
	super(on)
	if on : ta_pause_ticks = Time.get_ticks_msec()
	else : 
		ta_start_ticks += Time.get_ticks_msec() - ta_pause_ticks
		ta_pause_ticks = 0


## Called when gamefield deletes lines
func _on_lines_deleted(amount : int) -> void:
	super(amount)
	
	if gamefield.matrix.is_empty():
		game._add_sound("all_clear")
		Player.stats["total_all_clears"] += 1
	
	lines += amount
	if lines >= LINES_GOAL: game._game_over()
	
	foreground._set_lines_animated(lines)


func _on_lines_scanned(amount : int, _has_cheese : bool = false) -> void:
	if gamefield.matrix.is_empty():
		amount = 451
	
	foreground._show_score_add(0, amount)


## Called on game over
func _game_over(game_over_screen : MenuScreen) -> void:
	var goal_complete : bool = lines >= LINES_GOAL
	
	if goal_complete:
		game_over_screen.get_node("Sign/Label").text = "FINISH!"
	
	var result_time : int = Time.get_ticks_msec() - ta_start_ticks
	ta_start_ticks = 0
	var flash_color : Color
	var mode_str : String = "ta_"
	
	match ruleset:
		RULESET.STANDARD : mode_str += "std"
		RULESET.HARD : mode_str += "hrd"
		RULESET.EXTREME : mode_str += "xtr"
		RULESET.REVERSI : mode_str += "rev"
		RULESET.ZONE : mode_str += "zon"
	
	if not goal_complete:
		game_over_screen.get_node("Results/Letter").text = "DQ"
		flash_color = Color("1f8416ff")
	elif result_time <= RANKINGS.M : 
		game_over_screen.get_node("Results/Letter").text = "M"
		flash_color = Color("ff1d9c")
		if ruleset != RULESET.CUSTOM: Player.progress[mode_str + "_rank"] = Player.RANK.M
	elif result_time <= RANKINGS.X : 
		game_over_screen.get_node("Results/Letter").text = "X"
		flash_color = Color("1dffaa")
		if ruleset != RULESET.CUSTOM: if Player.RANK.X > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.X
	elif result_time <= RANKINGS.S : 
		game_over_screen.get_node("Results/Letter").text = "S"
		flash_color = Color("1df4ff")
		if ruleset != RULESET.CUSTOM: if Player.RANK.S > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.S
	elif result_time <= RANKINGS.A : 
		game_over_screen.get_node("Results/Letter").text = "A"
		flash_color = Color("ff421d")
		if ruleset != RULESET.CUSTOM: if Player.RANK.A > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.A
	elif result_time <= RANKINGS.B : 
		game_over_screen.get_node("Results/Letter").text = "B"
		flash_color = Color("ffb33c")
		if ruleset != RULESET.CUSTOM: if Player.RANK.B > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.B
	elif result_time <= RANKINGS.C : 
		game_over_screen.get_node("Results/Letter").text = "C"
		flash_color = Color("fff66d")
		if ruleset != RULESET.CUSTOM: if Player.RANK.C > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.C
	elif result_time <= RANKINGS.D : 
		game_over_screen.get_node("Results/Letter").text = "D"
		flash_color = Color.WHITE
		if ruleset != RULESET.CUSTOM: if Player.RANK.D > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.D
	else : 
		game_over_screen.get_node("Results/Letter").text = "E"
		flash_color = Color.WHITE
		if ruleset != RULESET.CUSTOM: if Player.RANK.E > Player.progress[mode_str + "_rank"]: Player.progress[mode_str + "_rank"] = Player.RANK.E
	
	flash_tween = create_tween().set_loops(100)
	flash_tween.tween_property(game_over_screen.get_node("Results/Letter"), "self_modulate", flash_color, 0.2)
	flash_tween.tween_property(game_over_screen.get_node("Results/Letter"), "self_modulate", Color.WHITE, 0.2)
	
	game_over_screen.get_node("Results/Value").text = foreground.get_node("Time/Num").text + foreground.get_node("Time/Num2").text
	
	if goal_complete and ruleset != RULESET.CUSTOM:
		Player._set_local_record(mode_str + "_record", result_time)
		if Player.config["save_score_online"] : await Talo.leaderboards.add_entry(mode_str, result_time)
	
	Player._save_profile()
	
	game_over_screen.gamemode_str = "ta"
	game_over_screen.ruleset = ruleset
	
	if ruleset != RULESET.CUSTOM: await game_over_screen._load_leaderboard()


## Called on game exit
func _end() -> void:
	if is_instance_valid(flash_tween):
		flash_tween.kill()
