extends Node

class_name Gamemode

## All possible rulesets
enum RULESET {
	STANDARD, # 10x10 field size, 1 damage per block, 15 piece regen
	HARD, # 9x9 field size, 2 damage per block, 5 piece regen, extended queue
	EXTREME, # 8x8 field size, instant death, extended queue
	REVERSI, # 10x10 field size, 2 damage per block, 10 piece regen, extended queue, reverse mode
	ZONE, # 9x9 field size, 2 damage per block, 10 piece regen, extended queue, zone mode
	CUSTOM,
	DEBUG # Test ruleset
}

const REVERSE_PIECES = 25 ## Amount of pieces needed for field reverse

var main : Main ## Main instance
var game : Game ## Game instance
var gamefield : Gamefield ## Gamefield instance
var foreground : Foreground ## Foreground instance

var gamemode_name : String = "" ## Name of the gamemode
var ruleset : int = RULESET.DEBUG ## Selected ruleset

var rng : RandomNumberGenerator = RandomNumberGenerator.new() ## Used to generate randomized pieces and other events with defined seed

var time_timer : Timer = null ## Timer which counts current game time

var field_size : Vector3i = Vector3i(10,10,10) ## Size of the game field. X and Y are 2D coordinates and Z is height value

var dzen_mode : bool = false ## If true game over is impossible
var zone_mode : bool = false ## If true game field waits for some frames before deleting scanned lines
var reversi_mode : bool = false ## If true game field will reverse after some amount of pieces placed
var death_mode : bool = false ## If true piece landing on block always leads to instant game over

var extended_piece_queue : bool = false ## If true piece queue will use few more non traditional pieces

var max_damage : int = 20 ## Amount of damage which player can take before game over
var last_chance : bool = false ## True if damage reached the max and player has one more chance to avoid putting blocks
var damage_recovery : int = 10 ## Amount of pieces which must be dropped perfectly to reduce damage by one
var current_damage_recovery : int = 10 ## Current amount of pieces which must be dropped perfectly to reduce damage by one

var damage : int = 0 ## Total taken damage
var time : int = 0 ## Total game time

var fall_delay : float = 60 ## How many physics ticks must pass before piece falls down one cell
var das_delay : float = 10 ## How many physics ticks must pass before DAS activates
var das : float = 5 ## Button hold frames left before moving piece one cell
var drop_delay_inc : float = 10 ## How much current drop delay raises when piece successfully moves
var min_drop_delay : float = 30 ## Mimimal drop delay duration
var max_drop_delay : float = 120 ## Maximum drop delay duration
var appearance_delay : float = 10 ## How many physics ticks passes before next piece is given
var line_clear_delay : float = 30 ## Amount of frames after line clear which is added to appearance_delay


func _ready() -> void:
	_set_ruleset(ruleset)
	
	time_timer = Timer.new()
	time_timer.timeout.connect(func() -> void: time += 1; foreground._set_time(time))
	add_child(time_timer)
	
	gamefield.lines_cleared.connect(_on_lines_deleted)
	gamefield.block_overlap.connect(_on_block_overlap)
	gamefield.block_deleted.connect(_on_block_deleted)
	gamefield.piece_queue.hold_updated.connect(foreground._update_hold)
	gamefield.piece_queue.queue_updated.connect(foreground._update_queue)


func _set_ruleset(type : int) -> void:
	match type:
		RULESET.STANDARD : 
			field_size = Vector3i(10, 10, 10)
			dzen_mode = false
			zone_mode = false
			reversi_mode = false
			death_mode = false
			extended_piece_queue = false
			max_damage = 20
			damage_recovery = 10
			
		RULESET.HARD : 
			field_size = Vector3i(8, 8, 8)
			dzen_mode = false
			zone_mode = false
			reversi_mode = false
			death_mode = false
			extended_piece_queue = true
			max_damage = 20
			damage_recovery = 5
			
		RULESET.EXTREME : 
			field_size = Vector3i(9, 9, 9)
			dzen_mode = false
			zone_mode = false
			reversi_mode = false
			death_mode = true
			extended_piece_queue = true
			max_damage = 4
			damage_recovery = 1
			
		RULESET.ZONE : 
			field_size = Vector3i(10, 10, 10)
			dzen_mode = false
			zone_mode = true
			reversi_mode = false
			death_mode = false
			extended_piece_queue = false
			max_damage = 20
			damage_recovery = 10
			
		RULESET.REVERSI : 
			field_size = Vector3i(8, 8, 8)
			dzen_mode = false
			zone_mode = false
			reversi_mode = true
			death_mode = false
			extended_piece_queue = true
			max_damage = 20
			damage_recovery = 10
			
		RULESET.CUSTOM : 
			field_size = Vector3i(Player.config["gamefield_size_x"], Player.config["gamefield_size_y"], Player.config["gamefield_size_z"])
			dzen_mode = Player.config["dzen_mode"]
			zone_mode = Player.config["zone_mode"]
			reversi_mode = Player.config["reversi_mode"]
			death_mode = Player.config["death_mode"]
			extended_piece_queue = Player.config["extended_piece_queue"]
			max_damage = Player.config["max_damage"]
			damage_recovery = Player.config["damage_recovery"]
		
		RULESET.DEBUG : 
			field_size = Vector3i(10,10,10)
			dzen_mode = true
			zone_mode = false
			reversi_mode = false
			death_mode = false
			extended_piece_queue = false
			max_damage = 20
			damage_recovery = 10
	
	current_damage_recovery = damage_recovery


## Called when gamefield deletes lines
func _on_lines_deleted(_amount : int) -> void:
	pass


## Called when block tries to spawn in existing one
func _on_block_overlap() -> void:
	pass


## Called when some block was deleted
func _on_block_deleted(_at_position : Vector2i) -> void:
	pass


## Called on game reset
func _reset() -> void:
	time_timer.start(1.0)


## Called on game pause
func _pause(on : bool) -> void:
	time_timer.paused = on


## Called on game over
func _game_over() -> void:
	pass


## Called on game exit
func _end() -> void:
	pass
