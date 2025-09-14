extends Node

##-----------------------------------------------------------------------
## Singletone containing all currently loaded profile audio/video/controls/etc. settings and savedata.
##-----------------------------------------------------------------------

class_name Profile

enum RESOLUTION {x1280x720, x1360x768, x1440x900, x1600x900, x1680x1050, x1920x1080, CUSTOM} ## Avaiable windowed resolutions

## Profile loading statuses
enum PROFILE_STATUS {
	OK, 
	PROGRESS_FAIL, ## Progress loading/saving failed
	PROGRESS_MISSING, ## Progress file is missing
	CONFIG_FAIL, ## Config file loading/saving failed
	CONFIG_MISSING, ## Config file is missing
	PROFILE_IS_MISSING, # Whole profile is missing
	GLOBAL_DATA_ERROR, ## Last profile name was lost
	NO_PROFILES_EXIST ## Profile directory is empty
}

const AUDIO_BUS_MINIMUM_DB : float = -29 ## Minimum db value when bus is still on
const CONFIG_PATH : String = "config.json" ## Path to the profile config
const SAVEDATA_PATH : String = "savedata.dat" ## Path to the profile savedata

signal profile_loaded ## Emitted when profile is loaded
signal profile_saved ## Emitted when profile is saved
signal config_changed ## Emitted when config was saved and has some changes
signal savedata_changed ## Emitted when savedata was saved and has some changes

var profile_name : String = "guest" ## Name of the loaded profile
var profile_status : int = PROFILE_STATUS.OK ## Profile loading status

var user_ruleset : Ruleset = Ruleset.new() ## Ruleset used for playlist/synthesia mode and which can be freely modified by player

## Contains all settings
var config : Dictionary = {
	"first_boot" : true, # If true, game was boot for the first time ever
	
	"sound_volume" : -7.0,
	"music_volume" : -7.0,
	
	"resolution_x" : 1280,
	"resolution_y" : 720,
	"fullscreen" : false, # Press F1 to toggle
	"max_fps" : 120, # FPS limit
	"static_background" : false, # Disables background animation
	"block_skin" : 0, # Selected blocks skin
	
	"save_score_online" : true, # If false, disables saving records to online ranking
	
	"gamefield_size_x" : 10,
	"gamefield_size_y" : 10,
	"extended_piece_queue" : false, # Adds some more pieces to the queue
	"field_invertion" : false, # After some pieces placed field inverts completely
	"instant_death" : false, # Game ends instantly if piece is landed on block
	"piece_at_top" : false, # Piece always spawns on top of the field
	"block_gravity" : false, # Blocks move down after line clear
	"zone_mode" : false, # Adds some delay before line clear allowing to add more lines
	"dzen_mode" : false, # No gameover possible
	
	# Keyboard controls
	"move_left" : "Left", ## Moves piece in hand left
	"move_right" : "Right", ## Moves piece in hand right
	"move_up" : "Up", ## Moves piece in hand up
	"move_down" : "Down", ## Moves piece in hand down
	"rotate_left" : "Z", ## Rotates piece in hand clockwise
	"rotate_right" : "X", ## Rotates piece in hand counter-clockwise
	"hard_drop" : "Space", ## Quickly drops down piece in hand
	"hold" : "Shift", ## Replaces current piece in hand with piece from hold
	
	"ui_accept" : "Enter", ## UI accept action
	"ui_cancel" : "Escape", ## UI cancel action
	"ui_extra" : "Space", ## Extra UI action
	
	# Gamepad controls
	"move_left_pad" : "joy_14", # DPAD LEFT
	"move_right_pad" : "joy_15", # DPAD RIGHT
	"move_up_pad" : "joy_15", # DPAD RIGHT
	"move_down_pad" : "joy_15", # DPAD RIGHT
	"rotate_left_pad" : "joy_1", # B
	"rotate_right_pad" : "joy_2", # X
	"quick_drop_pad" : "joy_13", # DPAD DOWN
	"passive_ability_pad" : "joy_9", # L1
	"special_ability_pad" : "joy_10", # R1
	"quick_retry_pad" : "joy_4", # SELECT
	
	"ui_accept_pad" : "joy_0", # A
	"ui_cancel_pad" : "joy_1", # B
	"ui_extra_pad" : "joy_5", # R1
}

## Current profile progression results
var progress : Dictionary = {
	"puzzles_solved" : 0,
}

## Unique profile indentifier
var vault_key : String = "0451"

## All player statistics
var stats : Dictionary[String, int] = {
	# Game general
	"total_time" : 0,
	"total_play_time" : 0,
	"total_score" : 0,
	"total_lines" : 0,
	"total_tetrises" : 0,
	"total_pieces_landed" : 0,
	"total_pieces_holded" : 0,
	"top_score_in_marathon" : 0,
	"top_level_in_marathon" : 0,
	"top_time_in_marathon" : 0,
	"top_time_in_ta" : 0,
	"top_score_gain" : 0,
}

## Loads profile
func _load_profile() -> int:
	profile_status = PROFILE_STATUS.OK
	
	var err : int  = _load_config()
	if err == ERR_DOES_NOT_EXIST : 
		return PROFILE_STATUS.CONFIG_MISSING
	elif err == ERR_CANT_OPEN : 
		return PROFILE_STATUS.CONFIG_FAIL
	
	err = _load_savedata()
	if err == ERR_DOES_NOT_EXIST :
		return PROFILE_STATUS.PROGRESS_MISSING
	if err == ERR_CANT_OPEN : 
		return PROFILE_STATUS.PROGRESS_FAIL
	
	profile_loaded.emit()
	return profile_status


## Saves current profile
func _save_profile() -> int:
	_save_config()
	_save_savedata()

	profile_saved.emit()
	return OK


## Creates new blank profile with standard config and empty savedata
func _create_profile(create_name : String) -> int:
	profile_name = create_name

	var blank_profile : Profile = Profile.new()
	config = blank_profile.config
	progress = blank_profile.progress
	stats = blank_profile.stats
	vault_key = str(randi_range(0, 2^24) + hash(OS.get_unique_id())).left(32)

	var err : int = _save_savedata()
	if err != OK : return err

	err = _save_config()
	if err != OK : return err

	profile_loaded.emit()
	return OK


## Deletes profile config and savedata completely
func _delete_profile() -> void:
	if FileAccess.file_exists(CONFIG_PATH) : DirAccess.remove_absolute(CONFIG_PATH)
	if FileAccess.file_exists(SAVEDATA_PATH) : DirAccess.remove_absolute(CONFIG_PATH)


## Loads specified profile savedata
func _load_savedata() -> int:
	if not FileAccess.file_exists(SAVEDATA_PATH) : return ERR_DOES_NOT_EXIST
	
	# Yeah I know that I just left encrypted file key in open-source project code. But it's intended to prevent regular user from changing the file, not a hacker ;)
	var file : FileAccess = FileAccess.open_encrypted_with_pass(SAVEDATA_PATH, FileAccess.READ, "0451")
	if not file : return ERR_CANT_OPEN
	
	var loaded_data : Variant = file.get_var()
	if loaded_data == null or loaded_data is not Dictionary : return ERR_CANT_ACQUIRE_RESOURCE
	
	for key : String in stats.keys():
		if loaded_data.has(key):
			stats[key] = loaded_data[key]
	
	vault_key = file.get_pascal_string()
	
	loaded_data = file.get_var()
	for key : String in progress.keys():
		if loaded_data.has(key):
			progress[key] = loaded_data[key]
	
	profile_name = file.get_pascal_string()
	
	file.close()
	
	savedata_changed.emit()
	
	if vault_key == "0451" : 
		vault_key = str(randi_range(0, 2^24) + hash(OS.get_unique_id())).left(32)
		_save_savedata()
	
	return OK


## Saves specified profile savedata
func _save_savedata() -> int:
	var file : FileAccess = FileAccess.open_encrypted_with_pass(SAVEDATA_PATH, FileAccess.WRITE, "0451")
	if not file : return FileAccess.get_open_error()

	if vault_key == "0451" : 
		vault_key = str(randi_range(0, 2^24) + hash(OS.get_unique_id())).left(32)

	file.store_var(stats)
	file.store_pascal_string(vault_key)
	file.store_var(progress)
	file.store_pascal_string(profile_name)
	file.close()

	return OK


## Loads config from .json formatted file. If name is not specified, loads current profile config
func _load_config() -> int:
	if not FileAccess.file_exists(CONFIG_PATH) : return ERR_DOES_NOT_EXIST
		
	var file : FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file : return ERR_CANT_OPEN
	
	var loaded_config : Variant = JSON.parse_string(file.get_as_text())
	if loaded_config == null or not loaded_config.has("music_volume") : return ERR_CANT_OPEN
	
	for key : String in config.keys() : if loaded_config.has(key) : config[key] = loaded_config[key]
	
	file.close()
	_apply_config_setting("all")
	return OK


## Saves config to .json formatted file. If name is not specified, saves current profile config
func _save_config() -> int:
	var file : FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if not file : return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close() 
	
	return OK


## Returns string associated with specified setting value. Used by sliders
func _get_config_value_string(setting_name : String, value : Variant) -> String:
	var return_string : String = ""
	
	match setting_name:
		"music_volume" : return_string = str(round((value + 30) / 30 * 100)) + "%"
		"sound_volume" : return_string = str(round((value + 30) / 30 * 100)) + "%"
		"resolution" : return_string = str(config["resolution_x"]) + "x" + str(config["resolution_y"])
		"max_fps" : return_string = str(value) + " FPS"
		_ : return_string = str(value)

	return return_string


## Returns specified setting value
func _get_config_value(setting_name : String) -> Variant:
	if setting_name == "resolution":
		match int(config["resolution_x"]):
			1280 : return RESOLUTION.x1280x720
			1360 : return RESOLUTION.x1360x768
			1440 : return RESOLUTION.x1440x900
			1600 : return RESOLUTION.x1600x900
			1680 : return RESOLUTION.x1680x1050
			1920 : return RESOLUTION.x1920x1080
			_: return RESOLUTION.CUSTOM
	
	elif setting_name in config.keys() : return config[setting_name]
	return null


## Sets specified setting value
func _set_config_value(setting_name : String, value : Variant) -> void:
	if setting_name == "resolution":
		match int(value):
			RESOLUTION.x1280x720 : 
				config["resolution_x"] = 1280
				config["resolution_y"] = 720
			RESOLUTION.x1360x768 : 
				config["resolution_x"] = 1360
				config["resolution_y"] = 768
			RESOLUTION.x1440x900 : 
				config["resolution_x"] = 1440
				config["resolution_y"] = 900
			RESOLUTION.x1600x900 : 
				config["resolution_x"] = 1600
				config["resolution_y"] = 900
			RESOLUTION.x1680x1050 : 
				config["resolution_x"] = 1680
				config["resolution_y"] = 1050
			RESOLUTION.x1920x1080 : 
				config["resolution_x"] = 1920
				config["resolution_y"] = 1080
	
	elif setting_name in config.keys() : config[setting_name] = value
	config_changed.emit()


## Applies specified setting, making it working[br]
## [i]'all', 'all_audio', 'all_video', 'all_controls'[/i] and [i]'all_misc'[/i] can be passed to [b]'setting_name'[/b] to apply all settings of specified category.
func _apply_config_setting(setting_name : String = "all") -> void:
	match setting_name:
		"all":
			for i : String in config.keys() : 
				_apply_config_setting(i)
		
		"music_volume":
			var volume : float = config["music_volume"]
			AudioServer.set_bus_volume_db(1,volume)
			# Disable music bus if volume is too low
			if volume <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(1,-100)
		"sound_volume":
			var volume : float = config["sound_volume"]
			AudioServer.set_bus_volume_db(2,volume)
			# Disable sound bus if volume is too low
			if volume <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(2,-100)
		"resolution":
			get_window().size = Vector2(config["resolution_x"],config["resolution_y"])
		"max_fps":
			Engine.max_fps = config["max_fps"]
		"fullscreen":
			if config["fullscreen"]:
				get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			else:
				get_window().mode = Window.MODE_WINDOWED
				get_window().move_to_center()
		
		"move_left" : _update_input_config(setting_name)
		"move_right" : _update_input_config(setting_name)
		"move_up" : _update_input_config(setting_name)
		"move_down" : _update_input_config(setting_name)
		"rotate_left" : _update_input_config(setting_name)
		"rotate_right" : _update_input_config(setting_name)
		"hard_drop" : _update_input_config(setting_name)
		"hold" : _update_input_config(setting_name)
		"ui_accept" :  _update_input_config(setting_name)
		"ui_cancel" : _update_input_config(setting_name)
		"ui_extra" : _update_input_config(setting_name)


## Sets [InputEvent] **'event'** for specified **'action'** name
func _update_input_config(action : String, event : InputEvent = null) -> void:
	if event != null:
		if event is InputEventKey : config[action] = OS.get_keycode_string(event.keycode)
		elif event is InputEventJoypadButton : config[action + "_pad"] = "joy_" + str(event.button_index)


## Updates [InputMap] for passed **'action'**
func _apply_input_config(action : String) -> void:
	if action.ends_with("_pad") : return
	InputMap.action_erase_events(action)
	
	var new_event : InputEvent = InputEventKey.new()
	new_event.keycode = OS.find_keycode_from_string(config[action])
	InputMap.action_add_event(action,new_event)
	
	new_event = InputEventJoypadButton.new()
	new_event.button_index = int(config[action + "_pad"].substr(4))
	InputMap.action_add_event(action,new_event)


## Sets top value in stats, if passed value is greater than current in stats
func _set_stats_top(stat_name : String, new_value : int) -> void:
	if not stats.has(stat_name): return
	if stats[stat_name] < new_value : 
		stats[stat_name] = new_value
