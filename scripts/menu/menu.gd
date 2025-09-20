extends Control

##-----------------------------------------------------------------------
## Controls all menu screens.
## Each menu screen node must inherit [MenuScreen] class and feature an [AnimationPlayer] node called [b]'A'[/b].
## [b]'A'[/b] must contain [b]'start'[/b] and [b]'end'[/b] named animations in order to work, but can have more animations if needed
## Then you can do and code anything you want inside menu screen.
##-----------------------------------------------------------------------

class_name Menu

signal screen_remove_started ## Called when menu screen remove started
signal screen_removed(name : String) ## Called when menu screen is removed, and returns removed screen name
signal all_screens_removed ## Called when all menu screens in queue were removed

signal screen_add_started ## Called when new menu screen creation started
signal screen_added(name : String) ## Called when menu screen is added, and returns added screen name
signal all_screens_added ## Called when all menu screens in queue were added

const BUTTONS_ICONS_TEX : Texture = preload("res://images/menu/key_graphics.png") ## Build-in buttons icons atlas texture
const BUTTON_KEY_SCENE : PackedScene = preload("res://scenes/menu/button_key.tscn") ## Used when key is not in [constant BUTTONS_ICONS_TEX]

const BACKGROUND_SCREEN_Z_INDEX : int = -1500
const FOREGROUND_SCREEN_Z_INDEX : int = 500
const STARTUP_SCREEN_Z_INDEX : int = 1000

var main : Main ## Main node instance

var is_locked : bool = false ## If true nothing could be done with menu and its screens
var is_loading : bool = false ## If true menu currently loads all its assets

## All avaiable menu screens (stored as paths to .tscn files)
var loaded_screens_data : Dictionary = {
	"foreground" : "res://scenes/menu/screens/foreground.tscn",
	"background" : "res://scenes/menu/screens/background.tscn",
	"startup" : "res://scenes/menu/screens/startup.tscn",
	"splash_screen" : "res://scenes/menu/screens/splash_screen.tscn",
	"main_menu" : "res://scenes/menu/screens/main_menu.tscn",
	"pause" : "res://scenes/menu/screens/ingame/pause.tscn",
	"ma_game_over" : "res://scenes/menu/screens/ingame/marathon_game_over.tscn",
	"ta_game_over" : "res://scenes/menu/screens/ingame/time_attack_game_over.tscn",
	"ch_game_over" : "res://scenes/menu/screens/ingame/cheese_game_over.tscn",
}

## All avaiable menu music (stored as paths to .mp3 or .ogg)
var loaded_music_data : Dictionary = {
	"menu_theme_drums" : "res://music/gymnopedie mini cover_drums.ogg",
	"menu_theme_calm" : "res://music/gymnopedie mini cover_drumless.ogg"
}

## All avaiable system sounds (stored as loaded .mp3 or .ogg instances)
var loaded_sounds_data : Dictionary = {
	"intro_drop" : load("res://sfx/menu/intro_drop.wav"),
	"accept" : load("res://sfx/menu/accept.wav"),
	"select" : load("res://sfx/menu/select.wav"),
	"skin_select" : load("res://sfx/menu/skin_select.wav"),
	"cancel" : load("res://sfx/menu/cancel.wav"),
	"enter" : load("res://sfx/menu/start.wav"),
	"start" : load("res://sfx/menu/start3.wav"),
	"start2" : load("res://sfx/menu/start2.wav"),
}

var screens : Dictionary = {} ## All currently alive menu screens dictionary
var current_screen : Control = null ## Currently focused menu screen instance
var current_screen_name : String = "" ## Currently focused menu screen name (in snake_case)
var currently_adding_screens_amount : int = 0 ## Number of currently adding menu screens
var currently_removing_screens_amount : int = 0 ## Number of currently removing menu screens

var music_player : AudioStreamPlayer = null ## Menu music player node
var latest_music_sample_name : String = "" ## Name of latest playing menu music sample 
var is_music_playing : bool = false ## Is menu music playing currently
var last_music_position : float = 0.0 ## Latest menu music playback position

var keep_locked : bool = false ## If true menu won't unlock after menu screen is added, so menu can be unlocked manually later

var foreground : MenuScreen = null ## Foreground menu screen, which always overlay other screens
var background : MenuScreen = null ## Background menu screen, which is always behind other screens

var custom_data : Dictionary = {} ## Some custom data which could be used freely by all menu screens


func _ready() -> void:
	name = "Menu"


## Resets menu to its initial state
func _reset() -> void:
	# Free all menu screens
	for node : Node in get_children() : node.queue_free()
	
	# Reset all vars
	is_locked = false
	keep_locked = false
	currently_adding_screens_amount = 0
	currently_removing_screens_amount = 0
	current_screen = null
	current_screen_name = ""
	
	screens.clear()
	custom_data.clear()
	
	latest_music_sample_name = ""
	is_music_playing = false
	if music_player != null:
		music_player.queue_free()
		music_player = null
	
	background = _add_screen("background", "null")
	background.z_as_relative = false
	background.z_index = BACKGROUND_SCREEN_Z_INDEX
	
	foreground = _add_screen("foreground", "null")
	foreground.z_as_relative = false
	foreground.z_index = FOREGROUND_SCREEN_Z_INDEX
	foreground.visible = false


## Starts intro sequence and loads first screens [br]
## If [b]'force_screen'[/b] is passed, menu will skip intro and immidiately load passed screen
func _boot(force_screen : String = "") -> void:
	_reset()
	
	if not force_screen.is_empty():
		_add_screen(force_screen)
		return

	var startup_screen : MenuScreen = _add_screen("startup")
	startup_screen.z_as_relative = false
	startup_screen.z_index = STARTUP_SCREEN_Z_INDEX
	await startup_screen.finish
	_remove_screen("startup", "end")
	await all_screens_removed
	_add_screen("splash_screen")


## Adds new [MenuScreen] and sets it as current. Returns added menu screen reference[br]
## - [b]'screen_name'[/b] - Name of the menu screen to add, which links to one of the screens avaiable in [b]'loaded_screens_data'[/b][br]
## - [b]'screen_anim'[/b] - New menu screen starting animation name (enter "null" to skip animation)
func _add_screen(screen_name : String, screen_anim : String = "start") -> MenuScreen:
	if not screen_name in loaded_screens_data.keys():
		return null
	
	is_locked = true
	currently_adding_screens_amount += 1
	screen_add_started.emit()
	
	var new_screen : MenuScreen = load(loaded_screens_data[screen_name]).instantiate()
	screens[screen_name] = new_screen
	
	new_screen.previous_screen_name = current_screen_name
	new_screen.snake_case_name = screen_name
	new_screen.parent_menu = self
	new_screen.main = main

	current_screen_name = screen_name
	current_screen = new_screen
	
	add_child(new_screen)

	if foreground != null:
		var count = clampi(get_child_count() - 1, 0, 99999999)
		move_child(foreground, count)
	
	_process_added_screen(new_screen,screen_anim)
	return new_screen

## Helper function which starts added menu screen appear animation and waits until it ends to unlock menu[br]
## So previous funciton can return [MenuScreen] instance without waiting 
func _process_added_screen(new_screen : MenuScreen, screen_anim : String) -> void:
	# We expect that screen will show its appear animation, so we wait until it ends
	if new_screen.animation_player != null and new_screen.animation_player.has_animation(screen_anim):
		new_screen.animation_player.play(screen_anim)
		await new_screen.animation_player.animation_finished
	
	screen_added.emit(new_screen.snake_case_name)
	currently_adding_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_adding_screens_amount == 0:
		if currently_removing_screens_amount == 0 and not keep_locked: 
			is_locked = false
		
		all_screens_added.emit()


## Removes screen from menu[br]
## - [b]'screen_name'[/b] - Name of the menu screen to remove[br]
## - [b]'screen_anim'[/b] - Removing menu screen ending animation (enter "null" to skip animation)
func _remove_screen(screen_name : String, screen_anim : String = "end") -> void:
	if not screens.has(screen_name): 
		return

	is_locked = true
	screen_remove_started.emit()
	
	var old_screen : MenuScreen = screens[screen_name]
	old_screen.remove_started.emit()

	if screens.has(old_screen.previous_screen_name):
		current_screen_name = old_screen.previous_screen_name
		current_screen = screens[old_screen.previous_screen_name]
		current_screen._move_cursor()

	screens.erase(screen_name)
	currently_removing_screens_amount += 1
	
	if screen_anim != "null" and old_screen.animation_player != null and old_screen.animation_player.has_animation(screen_anim):
		old_screen.animation_player.play(screen_anim)
		await old_screen.animation_player.animation_finished
	
	old_screen.queue_free()
	screen_removed.emit(screen_name)
	currently_removing_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_removing_screens_amount == 0:
		if currently_adding_screens_amount == 0: 
			if not keep_locked:
				is_locked = false
		
		all_screens_removed.emit()


## Replaces current menu screen with new one and removes it. Returns new [MenuScreen] reference[br]
## - [b]'new_screen_name'[/b] - Name of the new menu screen which will replace current[br]
## - [b]'new_screen_anim'[/b] - New menu screen starting animation (you can enter "null" to skip animation)[br]
## - [b]'old_screen_anim'[/b] - Old menu screen ending animation (you can enter "null" to skip animation)
func _change_screen(new_screen_name : String, new_screen_anim : String = "start", old_screen_anim : String = "end") -> Control:
	if currently_adding_screens_amount > 0 : await all_screens_added
	if currently_removing_screens_amount > 0 : await all_screens_removed
	await get_tree().create_timer(0.01).timeout
	
	var old_screen_name : String = current_screen_name
	_remove_screen(current_screen_name, old_screen_anim)
	await all_screens_removed
	var new_screen : MenuScreen = _add_screen(new_screen_name, new_screen_anim)
	new_screen.previous_screen_name = old_screen_name
	
	return new_screen


## Reloads menu after game is over and adds menu screen with passed [b]'screen_name'[/b]
func _return_from_game(screen_name : String = "main_menu") -> void:
	background.visible = true
	foreground.visible = true
	
	main._toggle_darken(false)
	
	_add_screen(screen_name)
	_change_music(latest_music_sample_name)
	if music_player != null : music_player.seek(last_music_position)


## Closes all menu screens
func _exit() -> void:
	current_screen_name = ""
	is_locked = true
	
	# Fade-out menu music
	_change_music("nothing")
	
	for screen_name : String in screens.keys() : 
		if screens[screen_name] == foreground or screens[screen_name] == background : continue
		_remove_screen(screen_name)
	
	await all_screens_removed
	foreground.visible = false
	background.visible = false
	is_locked = false


## Plays one of the avaiable in [b]'loaded_sounds_data'[/b] sounds. Returns reference to created for sound playback [AudioStreamPlayer][br]
## Sound files inside "menu/sound" should be "ogg" or "mp3" with **'looping'** set to false[br]
## Announcer samples should have prefix "announce_" to work correctly[br]
## - [b]'sound_name'[/b] - Name of the sound sample in [b]'loaded_sounds_data'[br]
## - [b]'stream'[/b] - If passed, played instead of sound specified by previous parameter[br]
## - [b]'start_immidiately'[/b] - Starts sound playback immidiately
func _play_sound(sound_name : String, stream : AudioStream = null, start_immidiately : bool = true) -> AudioStreamPlayer:
	if sound_name == "" : return
	if not loaded_sounds_data.has(sound_name) and stream == null: 
		return
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	
	player.bus = 'Sound'
	if stream != null: player.stream = stream
	else: player.stream = loaded_sounds_data[sound_name]
	
	player.finished.connect(player.queue_free)
	
	add_child(player)
	if start_immidiately : player.play()
	return player


## Changes currently playing looping menu music sample[br]
## Music files inside "menu/music" should be "ogg" or "mp3" with **'looping'** set to false, *and have same file names as corresponding menu screens*[br]
## - **'music_sample_name'** - Name of the music sample in [b]'loaded_music_data'[br]
## - **'change_speed'** - Speed factor of previous music sample fade out
func _change_music(music_sample_name : String = "", change_speed : float = 1.0) -> void:
	if latest_music_sample_name == music_sample_name:
		return
	
	if music_sample_name != "nothing" and not loaded_music_data.has(music_sample_name):
		return
	
	if music_player != null: 
		last_music_position = music_player.get_playback_position()
		
		var tween : Tween = create_tween()
		tween.tween_property(music_player,"volume_db",-99.0,change_speed).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		tween.tween_callback(music_player.queue_free)
		
		is_music_playing = false
		music_player = null
	
	latest_music_sample_name = music_sample_name
	
	if music_sample_name == "nothing":
		return
	
	var music_sample : AudioStream = load(loaded_music_data[music_sample_name])
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	player.volume_db = -40.0
	player.stream = music_sample
	player.bus = "Music"
	music_player = player
	create_tween().tween_property(music_player,"volume_db",0.0,change_speed).from(-99.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	is_music_playing = true
	
	player.finished.connect(player.play)
	add_child(player)
	player.play()


### Creates and returns a button icon node, which is useful for buttons layout display
static func _create_button_icon(action : String, button_size : Vector2 = Vector2(42,42)) -> TextureRect:
	var action_index : int
	
	match action:
		# D-pad or keyboard movement actions id's
		"all_arrows" : 
			action_index = 1001 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3001
		"up_down" : 
			action_index = 1002 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3002
		"left_right" : 
			action_index = 1003 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3003
		"all_arrows2" : 
			action_index = 3004
		"up_down2" : 
			action_index = 3005
		"left_right2" : 
			action_index = 3006
		
		# Mouse buttons actions id's
		"mouse_left": action_index = 2001
		"mouse_right": action_index = 2002
		"mouse_middle": action_index = 2003
		
		"backspace": action_index = KEY_BACKSPACE
		
		# Any else action
		_:
			if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD : 
				var gamepad_action_name : String = Player.config[action + "_pad"]
				action_index = int(gamepad_action_name.substr(4))
			else:
				action_index = OS.find_keycode_from_string(Player.config[action])
	
	var atlas_region : Rect2 = Rect2(128,128,128,128)
	var atlas_position : Vector2 = Vector2(0,0)
	var icon : TextureRect
	
	match action_index:
		# Gamepad
		JOY_BUTTON_A : atlas_position = Vector2(0,0) # XBOX A
		JOY_BUTTON_B: atlas_position = Vector2(1,0) # XBOX B
		JOY_BUTTON_X: atlas_position = Vector2(2,0) # XBOX X
		JOY_BUTTON_Y: atlas_position = Vector2(3,0) # XBOX Y
		1001:atlas_position = Vector2(5,0) # ALL ARROWS
		1002: atlas_position = Vector2(1,1) # UPDOWN
		1003: atlas_position = Vector2(0,1) # LEFTRIGHT
		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_DOWN : atlas_position = Vector2(4,0) # SINGLE ARROW
		JOY_BUTTON_RIGHT_SHOULDER: atlas_position = Vector2(2,1) # R1
		JOY_BUTTON_LEFT_SHOULDER: atlas_position = Vector2(3,1) # L1
		JOY_AXIS_TRIGGER_RIGHT: atlas_position = Vector2(4,1) # R2
		JOY_AXIS_TRIGGER_LEFT: atlas_position = Vector2(5,1) # L2
		JOY_BUTTON_START: atlas_position = Vector2(0,2) # START
		JOY_BUTTON_GUIDE: atlas_position = Vector2(1,2) # SELECT
		
		# Keyboard
		KEY_ENTER: atlas_position = Vector2(2,2) # ENTER
		KEY_SHIFT: atlas_position = Vector2(3,2) # SHIFT
		KEY_ESCAPE: atlas_position = Vector2(5,2) # ESC
		KEY_SPACE: atlas_position = Vector2(4,2) # SPACE
		KEY_BACKSPACE: atlas_position = Vector2(0,3) # BACKSPACE
		KEY_UP,KEY_DOWN,KEY_RIGHT,KEY_LEFT : atlas_position = Vector2(5,3)
		3001: atlas_position = Vector2(2,3) # WASD
		3002: atlas_position = Vector2(4,3) # WS
		3003: atlas_position = Vector2(3,3) # AD
		3004: atlas_position = Vector2(3,4) # ALL ARROWS
		3005: atlas_position = Vector2(5,4) # LEFT-RIGHT ARROWS
		3006: atlas_position = Vector2(4,4) # UP-DOWN ARROWS
		
		# Mouse
		2001: atlas_position = Vector2(0,4) # LEFT CLICK
		2002: atlas_position = Vector2(1,4) # RIGHT CLICK
		2003: atlas_position = Vector2(2,4) # MIDDLE CLICK

		# If no button in atlas found, this button is threated as keyboard button and special object is created and used
		_: 
			atlas_region = Rect2(128,384,128,128)
			icon = BUTTON_KEY_SCENE.instantiate()
			icon.get_node("Label").text = OS.get_keycode_string(action_index)
			return icon
	
	atlas_region.position = atlas_position * 128

	icon = TextureRect.new()
	var tex : AtlasTexture = AtlasTexture.new()
	tex.atlas = BUTTONS_ICONS_TEX
	tex.region = atlas_region
	icon.texture = tex
	# Center TextureRect
	icon.pivot_offset = Vector2(button_size.x / 2,button_size.y / 2)
	icon.custom_minimum_size = button_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# If its single arrow button, rotate it depending on direction
	match action_index:
		JOY_BUTTON_DPAD_DOWN, KEY_DOWN, 1003 : icon.rotation_degrees = 90
		JOY_BUTTON_DPAD_LEFT, KEY_LEFT : icon.flip_h = true
		JOY_BUTTON_DPAD_UP, KEY_UP : icon.rotation_degrees = 270
	
	return icon
