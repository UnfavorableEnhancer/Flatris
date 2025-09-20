extends Node

class_name Main

enum INPUT_MODE {KEYBOARD, MOUSE, GAMEPAD}

const VERSION : String = "1.0" ## Current game version
const BUILD : String = "18.09.2025" ## Latest build date

const SCREENSHOTS_PATH : String = "screenshots/" ## Path to the game screenshots folder
const LOGS_PATH : String = "logs/" ## Path to the game logs folder

const LOCAL_RANKING_PATH : String = "user://local_ranking.json" ## Path to the local ranking json (TODO : move to ranking_manager.gd)

const GAME_SCENE : PackedScene = preload("res://scenes/game/game.tscn")

signal total_time_tick  ## Emitted on each total time timer timeout
signal input_method_changed ## Emitted when input method changes from keyboard to gamepad, to mouse and etc.

static var menu : Menu ## Menu instance
static var game : Game ## Game instance

static var current_input_mode : int = INPUT_MODE.KEYBOARD ## Current input device

@onready var darken : ColorRect = $Darken ## Dark overlay node used to cover everything
@onready var loading_screen : LoadingScreen = $Loading ## Loading screen overlay node used to cover everything

@export var skip_intro : bool = false ## If true, game skips straight into main menu screen
@export var game_test : bool = false ## If true, game skips straight into marathon game with debug ruleset


## Called on boot
func _ready() -> void:
	get_window().move_to_center()
	await get_tree().create_timer(0.1).timeout
	
	_make_dirs()
	
	$TotalTime.timeout.connect(total_time_tick.emit)
	$TotalTime.start(1.0)
	
	darken.modulate.a = 0.0
	loading_screen.modulate.a = 0.0
	
	menu = Menu.new()
	menu.main = self
	menu.name = "Menu"
	add_child(menu)
	move_child(menu,0) # Move menu node to top of the tree to make it overlayable by other things
	
	var start_arguments : Dictionary = _parse_start_arguments()
	if start_arguments.has("skip_intro") : skip_intro = start_arguments["skip_intro"].is_empty()
	
	if game_test : 
		menu._reset()
		_start_game(MarathonMode.new(), Game.THEME.C)
	else : _reset()


## Creates all nessesarry for the game dirs
func _make_dirs() -> void:
	for path : String in [SCREENSHOTS_PATH, LOGS_PATH]:
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)


## Parse and save current command line arguments
func _parse_start_arguments() -> Dictionary:
	var start_arguments : Dictionary
	for argument : String in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value : PackedStringArray = argument.split("=")
			start_arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			start_arguments[argument.trim_prefix("--")] = ""
	
	return start_arguments


## Restarts whole game starting boot sequence from beginning
func _reset() -> void:
	if game != null: game.queue_free()
	
	Player._load_profile()
	
	if skip_intro : menu._boot("main_menu")
	else : menu._boot()


## Starts the game with passed gamemode
func _start_game(gamemode : Gamemode, theme : int) -> void:
	_toggle_darken(true)
	
	menu._exit()
	await get_tree().create_timer(1.0).timeout
	_toggle_loading(true)
	
	menu.background.visible = false
	menu.foreground.visible = false
	
	game = GAME_SCENE.instantiate()
	game.background_to_load = theme
	game.gamemode = gamemode
	game.menu = menu
	game.main = self
	
	add_child(game)
	move_child(game,0) # Move game node to top of the tree to make it overlayable by menu and other things
	
	game._reset()


func _input(event : InputEvent) -> void:
	# Determine current input mode
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if current_input_mode != INPUT_MODE.GAMEPAD:
			current_input_mode = INPUT_MODE.MOUSE
			input_method_changed.emit()
	elif event is InputEventJoypadButton:
		current_input_mode = INPUT_MODE.GAMEPAD
		input_method_changed.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventKey:
		current_input_mode = INPUT_MODE.KEYBOARD
		input_method_changed.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Toggle fullscreen
	if event.is_action_pressed("fullscreen"):
		if not Player.video_config["fullscreen"]:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			Player.video_config["fullscreen"] = true
		else:
			get_window().mode = Window.MODE_WINDOWED
			Player.video_config["fullscreen"] = false
	
	# Take screenshot
	if event.is_action_pressed("screenshot"):
		_take_screenshot()


## Takes screenshot and saves it as .png in SCREENSHOTS_PATH
func _take_screenshot() -> void:
	var prefix : String = "FLATRIS"

	if game == null:
		prefix = menu.current_screen_name.to_upper().replace(" ","_")
	else:
		prefix = game.gamemode.gamemode_name.to_upper()

	var date : String = Time.get_date_string_from_system().replace(".","_") 
	var time : String = Time.get_time_string_from_system().replace(":","-")

	var screenshot_path : String = SCREENSHOTS_PATH + prefix + "_" + date + "_" + time + ".png"
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.save_png(screenshot_path)


## Converts int (secs) to (hh:mm:ss) time format
static func _to_time(seconds : int) -> String:
	var hour : int = int(seconds / 3600.0)
	var hour_str : String = str(hour) + ":"
	if seconds < 3600 : hour_str = ""
	
	var minute : String = str(int(seconds / 60.0) - 60 * hour) + ":"
	if int(seconds / 60.0 - 60 * hour) < 10 : minute = "0" + str(int(seconds / 60.0) - 60 * hour) + ":"

	var secs : String = str(seconds % 60)
	if seconds % 60 < 10 : secs = "0" + str(seconds % 60)
	
	return hour_str + minute + secs


## Sets dark overlay opacity
func _toggle_darken(on : bool) -> void:
	var tween : Tween = create_tween()
	if on : tween.tween_property(darken, "modulate:a", 1.0, 1.0)
	else : tween.tween_property(darken, "modulate:a", 0.0, 1.0)


## Toggles loading screen
func _toggle_loading(on : bool) -> void:
	if on: loading_screen._play()
	else: loading_screen._stop()


func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_exit(true)


## Finishes all processes, saves all nessesary things and closes the game[br]
## If [b]'quick'[/b] is true closes game immidiately, without blackout animation
func _exit(quick : bool = false) -> void:
	Player._save_profile()
	
	if not quick:
		_toggle_darken(true)
		
		menu.is_locked = true
		if menu.is_music_playing:
			create_tween().tween_property(menu.music_player,"volume_db",-60.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		
		await get_tree().create_timer(1.25).timeout
	
	get_tree().quit()
