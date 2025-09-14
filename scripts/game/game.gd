extends Node3D

class_name Game

## All avaiable to play sounds
const SOUNDS : Dictionary[String, AudioStream] = {
	
}

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

var is_physics_active : bool = true ## If true, game ticks are processed by engine physics thread
var is_resetting : bool = false ## If true, game is currently resetting
var is_paused : bool = false ## If true, the game is paused and nothing happens
var is_game_over : bool = false ## If true, the game is over and needs restart

var gamemode : Gamemode = null ## Current gamemode, defines game rules and goals

var rng : RandomNumberGenerator = RandomNumberGenerator.new() ## Used to generate randomized pieces and other events with defined seed

var background_to_load : String = "THEME_A" ## What background to load at game start
var background = null ## Contains fancy visuals and music

@onready var gamefield : Gamefield = $Gamefield ## Contains all blocks and gamey stuff
@onready var foreground : Foreground = $Foreground ## Contains all game GUI which is controlled by current gamemode
@onready var pause_background : ColorRect = $PauseBackground  ## ColorRect which covers game screen when its paused

@onready var sounds : Node = $Sounds ## Contains all game sound effects
var playing_sounds : Dictionary[String, AudioStreamPlayer] = {} ## All currently played sounds


func _ready() -> void:
	pause_background.modulate.a = 0.0
	
	gamemode.game = self
	gamemode.foreground = foreground
	gamemode.main = main
	add_child(gamemode)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


## Resets game to the initial state and starts it
func _reset() -> void:
	if is_resetting : return
	is_resetting = true
	
	main._toggle_darken(true)
	await get_tree().create_timer(1.0).timeout
	
	is_physics_active = false
	
	reset_started.emit()
	gamemode._reset()
	gamefield._clear_matrix()
	
	for i : Node in sounds.get_children(): i.queue_free()
	playing_sounds.clear()
	
	is_game_over = false
	_pause(false, false)
	
	main._toggle_darken(false)
	await get_tree().create_timer(0.5).timeout
	
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
	if menu.screens.size() > 0 : menu._exit()

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
	
	var gameover_screen : MenuScreen = menu._add_screen(game_over_screen_name)
	gameover_screen._setup(self)
	
	game_over.emit()
	gamemode._game_over()


## Sets pause state to **'on'** value[br]
## - **'pause_screen'** - If true, adds menu screen as predefined in **'pause_screen_name'** if 'on' is true and waits for its closure if 'on' is false
func _pause(on : bool = true, use_pause_screen : bool = true) -> void:
	if use_pause_screen and not on: 
		menu._remove_screen("foreground")
		menu._remove_screen(pause_screen_name)
		await menu.all_screens_removed

	is_paused = on

	gamemode._pause(on)
	paused.emit(on)

	if on : create_tween().tween_property(pause_background, "modulate:a", 0.8, 1.0).from(0.0)
	else : create_tween().tween_property(pause_background, "modulate:a", 0.0, 1.0).from(0.8)
		
	if on and use_pause_screen:
		menu._add_screen("foreground")
		var pause_screen : MenuScreen = menu._add_screen(pause_screen_name)
		pause_screen._setup(self)

		menu._play_sound("confirm4")


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
