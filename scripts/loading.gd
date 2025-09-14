extends Control

##-----------------------------------------------------------------------
## Loading screen which overlays everything and is meant to be shown when game loads something heavy
## To be avaiable a MenuScreen scene must be placed into *"res://menu/loading.tscn"* 
## and it must have animation named *"loading"* and method *'_set_text(text : String)'*
##-----------------------------------------------------------------------

class_name LoadingScreen

const LOADING_SCREEN_PATH : String = "res://scenes/menu/loading.tscn" ## Path to the loading screen
const LOADING_APPEAR_SPEED : float = 1.0 ## How fast loading screen should appear in seconds

var screen : Control = null ## Loaded loading screen instance


## Loads loading screen [MenuScreen] from *LOADING_SCREEN_PATH*
func _load() -> void :
	if not FileAccess.file_exists(LOADING_SCREEN_PATH) : return
	
	screen = load(LOADING_SCREEN_PATH).instantiate()

	if not screen.has_method("_play") : 
		screen.free()
		return
	if not screen.has_method("_stop") : 
		screen.free()
		return
	if not screen.has_method("_set_text") : 
		screen.free()
		return

	add_child(screen)
	screen.modulate.a = 0.0


## Toggles loading animation which overlaps everything. Menu must be loaded first and contain menu screen called [b]"loading"[/b] in order to work.
func _toggle_loading(on : bool) -> void:
	if screen == null: return

	var tween : Tween = create_tween()
	if on:
		tween.tween_property(screen, "modulate:a", 1.0, LOADING_APPEAR_SPEED)
		screen._play()
	elif not on:
		tween.tween_property(screen, "modulate:a", 0.0, LOADING_APPEAR_SPEED)
		await tween.finished
		screen._stop()
