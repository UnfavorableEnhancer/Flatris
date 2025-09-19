extends MenuScreen

##-----------------------------------------------------------------------
## Game splash screen animation
##-----------------------------------------------------------------------

var is_exiting : bool = true ## True if game is currently exiting


func _ready() -> void:
	parent_menu.screens["foreground"].visible = false
	$Version.text = "Version " + Main.VERSION + "\nBuild " + Main.BUILD
	
	var loop_tween : Tween = create_tween().set_loops(0)
	loop_tween.tween_property($Press, "self_modulate:a", 0.0, 0.25)
	loop_tween.tween_property($Press, "self_modulate:a", 1.0, 0.25)
	
	var tween : Tween = create_tween()
	var letters : Array = ["F", "L", "A", "T", "R", "I", "S"]
	
	var letter : String = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 1.0).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.75).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.5).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.35).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.2).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.1).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	
	letter = letters.pick_random()
	letters.erase(letter)
	tween.tween_property(get_node("Logo/" + letter), "position:y", -8.0, 0.05).from(-500.0)
	tween.tween_callback(parent_menu._play_sound.bind("intro_drop"))
	tween.tween_callback(parent_menu._play_sound.bind("enter"))
	
	await get_tree().create_timer(4.0).timeout
	is_exiting = false


func _input(event : InputEvent) -> void:
	# Press "start" button to proceed to menu screen
	if not is_exiting:
		if event.is_action_pressed("ui_enter"):
			is_exiting = true 
			
			parent_menu._play_sound("start")
			parent_menu._change_screen("main_menu")
	
	# Exit the game
	if event.is_action_pressed("ui_exit"):
		if is_exiting : return
		is_exiting = true
		main._exit()
