extends Node3D

class_name Game

## All avaiable background themes to load
enum THEME {A, B, C}

## All avaiable to play sounds
const SOUNDS : Dictionary[String, AudioStream] = {
	"move" : preload("res://sfx/game/move.wav"),
	"piece_drop" : preload("res://sfx/game/piece_drop2.wav"),
	"rotate" : preload("res://sfx/game/rotate.wav"),
	"line_clear1" : preload("res://sfx/game/line_clear1.wav"),
	"line_clear2" : preload("res://sfx/game/line_clear2.wav"),
	"line_clear3" : preload("res://sfx/game/line_clear3.wav"),
	"line_clear4" : preload("res://sfx/game/line_clear4.wav"),
	"line_clear5" : preload("res://sfx/game/line_clear5.wav"),
	"line_clear6" : preload("res://sfx/game/line_clear6.wav"),
	"line_clear7" : preload("res://sfx/game/line_clear7.wav"),
	"line_clear8" : preload("res://sfx/game/line_clear8.wav"),
	"line_clear9" : preload("res://sfx/game/line_clear9.wav"),
	"line_clear10" : preload("res://sfx/game/line_clear10.wav"),
	"damage" : preload("res://sfx/game/damage.wav"),
	"all_clear" : preload("res://sfx/game/all_clear.wav"),
	"reverse" : preload("res://sfx/game/charge.wav"),
	"game_over" : preload("res://sfx/game/game_over.wav"),
	"game_over2" : preload("res://sfx/game/game_over2.wav"),
}

const THEME_A_BACKGROUND : String = "res://scenes/game/background/theme_a.tscn"
const THEME_B_BACKGROUND : String = "res://scenes/game/background/theme_b.tscn"
const THEME_C_BACKGROUND : String = "res://scenes/game/background/theme_c.tscn"

const TICK : float = 1 / 60.0 ## Single game physics tick

signal reset_started ## Emitted when game reset is started
signal reset_ended ## Emitted when game reset is finished

signal paused(on : bool) ## Emitted when game pause state is changed and returns new state
signal game_over ## Emitted when game is over

var main : Main ## Main instance
var menu : Menu ## Menu instance

var menu_screen_to_return_name : String = "main_menu" ## Name of the menu screen created after game exit
var pause_screen_name : String = "playlist_mode_pause" ## Name of the menu screen created on game pause
var game_over_screen_name : String = "playlist_mode_gameover" ## Name of the menu screen created on game over

var is_physics_active : bool = false ## If true, game ticks are processed by engine physics thread
var is_resetting : bool = false ## If true, game is currently resetting
var is_paused : bool = false ## If true, the game is paused and nothing happens
var is_game_over : bool = false ## If true, the game is over and needs restart

var gamemode : Gamemode = null ## Current gamemode, defines game rules and goals

var background_to_load : int = THEME.A ## What background to load at game start
var background : Background = null ## Contains fancy visuals and music
var foreground : Foreground = null ## Contains all game GUI which is controlled by current gamemode

@onready var gamefield : Gamefield = $Gamefield ## Contains all blocks and gamey stuff
@onready var pause_background : ColorRect = $PauseBackground  ## ColorRect which covers game screen when its paused

@onready var sounds : Node = $Sounds ## Contains all game sound effects
var playing_sounds : Dictionary[String, AudioStreamPlayer] = {} ## All currently played sounds


func _ready() -> void:
	pause_background.modulate.a = 0.0
	
	var background_path
	match background_to_load:
		THEME.A : 
			background_path = THEME_A_BACKGROUND
			gamefield.get_node("Field").texture = load("res://images/game/theme_a_cell.png")
			gamefield.get_node("HeigthField").texture = load("res://images/game/theme_a_heigth_cell.png")
		THEME.B : 
			background_path = THEME_B_BACKGROUND
			gamefield.get_node("Field").texture = load("res://images/game/theme_b_cell.png")
			gamefield.get_node("HeigthField").texture = load("res://images/game/theme_b_heigth_cell.png")
		THEME.C : 
			background_path = THEME_C_BACKGROUND
			gamefield.get_node("Field").texture = load("res://images/game/theme_c_cell.png")
			gamefield.get_node("HeigthField").texture = load("res://images/game/theme_c_heigth_cell.png")
	
	background = load(background_path).instantiate()
	add_child(background)
	
	if gamemode is MarathonMode or gamemode is CheeseMode:
		foreground = load("res://scenes/game/foreground/marathon_foreground.tscn").instantiate()
		add_child(foreground)
	elif gamemode is TimeAttackMode:
		foreground = load("res://scenes/game/foreground/time_attack_foreground.tscn").instantiate()
		add_child(foreground)
	
	gamemode.game = self
	gamemode.foreground = foreground
	gamemode.gamefield = gamefield
	gamemode.main = main
	
	gamefield.gamemode = gamemode
	gamefield.game = self
	gamefield._render_matrix()
	
	add_child(gamemode)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


## Resets game to the initial state and starts it
func _reset() -> void:
	if is_resetting : return
	is_resetting = true
	
	if menu.screens.size() > 2 : 
		menu._exit()
		await menu.all_screens_removed
	
	main._toggle_darken(true)
	background._stop_music()
	await get_tree().create_timer(1.0).timeout
	
	gamefield.piece_queue._clear()
	gamefield.piece_queue._shuffle()
	
	is_physics_active = false
	
	reset_started.emit()
	gamemode._reset()
	gamefield._clear_matrix()
	
	for i : Node in sounds.get_children(): i.queue_free()
	playing_sounds.clear()
	
	is_game_over = false
	
	main._toggle_darken(false)
	main._toggle_loading(false)
	await get_tree().create_timer(1.0).timeout
	
	_pause(false, false)
	background._start_music()
	reset_ended.emit()
	is_physics_active = true
	is_resetting = false


## Restarts the game
func _retry() -> void:
	if menu.screens.size() > 0 : menu._exit()
	
	main._toggle_darken(true)
	main._toggle_loading(true)
	await get_tree().create_timer(1.0).timeout

	_reset()


## Finishes the game and adds predefined in **'menu_screen_to_return'** menu screen
func _end() -> void:
	gamemode._end()
	if menu.screens.size() > 0 : 
		menu._exit()
		await menu.all_screens_removed
	
	main._toggle_darken(true)
	await get_tree().create_timer(1.0).timeout
	
	menu._return_from_game("main_menu")
	queue_free()


## Ends the game and adds game over menu screen as predefined in **'game_over_screen_name'**
func _game_over() -> void:
	is_game_over = true
	_pause(true,false)
	
	for i : Node in sounds.get_children(): i.queue_free()
	playing_sounds.clear()
	
	create_tween().tween_property(pause_background, "modulate:a", 0.8, 1.0).from(0.0)
	var gameover_screen : MenuScreen = menu._add_screen(game_over_screen_name)
	gameover_screen._setup(self)
	
	game_over.emit()
	gamemode._game_over(gameover_screen)


## Sets pause state to **'on'** value[br]
## - **'pause_screen'** - If true, adds menu screen as predefined in **'pause_screen_name'** if 'on' is true and waits for its closure if 'on' is false
func _pause(on : bool = true, use_pause_screen : bool = true) -> void:
	if use_pause_screen and not on: 
		menu.foreground.visible = false
		menu._remove_screen("pause")
		await menu.all_screens_removed
	
	is_paused = on
	
	gamemode._pause(on)
	paused.emit(on)
	background._muffle_music(on)
	
	if on : create_tween().tween_property(pause_background, "modulate:a", 0.8, 1.0).from(0.0)
	else : create_tween().tween_property(pause_background, "modulate:a", 0.0, 1.0)
	
	if on and use_pause_screen:
		menu.foreground.visible = true
		
		var pause_screen : MenuScreen = menu._add_screen("pause")
		pause_screen._setup(self)
		
		menu._play_sound("cancel")


## Processes single game tick
func _tick(_delta : float = TICK) -> void:
	if Input.is_action_just_pressed("pause") : 
		if not is_paused : _pause(true)
		else : _pause(false)
	
	if is_paused : return
	
	gamefield._physics()


func _physics_process(delta: float) -> void:
	if not is_physics_active : return
	_tick(delta)


## Adds sound effect from currently playing skin and returns its instance[br]
## - **'sound_name'** - Name of the entry inside SOUNDS
## - **'play_once'** - If true, only one instance of sound can be played at once[br]
func _add_sound(sound_name : StringName, play_once : bool = false) -> AudioStreamPlayer:
	if play_once and playing_sounds.has(sound_name) : return null
	if not SOUNDS.has(sound_name) : return null
	
	var sample : AudioStream = SOUNDS[sound_name]
	
	while playing_sounds.has(sound_name):
		sound_name += str(randi_range(10,100000000))
	
	var sound_player : AudioStreamPlayer = AudioStreamPlayer.new()
	sound_player.name = sound_name
	sound_player.stream = sample
	sound_player.bus = "Sound"
	sound_player.finished.connect(sound_player.queue_free)
	sound_player.finished.connect(_sound_finished.bind(sound_name))
	playing_sounds[sound_name] = sound_player
	sounds.add_child(sound_player)
	sound_player.play()
	
	return sound_player


func _sound_finished(sound_name : String) -> void:
	playing_sounds.erase(sound_name)
