extends MenuScreen

var game : Game = null

var is_in_assign_mode : bool = false ## True if currently assigning button to an action
var input_to_assign : InputEvent = null ## Stores input which is going to be assigned to an action
signal input_received ## Emitted when input is received, used in control assign sequence


func _ready() -> void:
	_reload_all_action_icons()
	cursor_selection_success.connect(_on_select)


## Called when cursor successfully selects selectable
func _on_select(pos : Vector2i) -> void:
	if Main.current_input_mode == Main.INPUT_MODE.MOUSE : return
	
	if pos.x == 1:
		$OptionsWindow/Scroll.scroll_vertical = 32 * (pos.y - 3)


func _setup(game_ref : Game) -> void:
	game = game_ref
	
	if game.gamemode is MarathonMode:
		$Sign/Back.modulate = Color("219cff")
		$Options/Back.modulate = Color("219cff")
		$OptionsWindow/Back.modulate = Color("219cff")
	elif game.gamemode is TimeAttackMode:
		$Sign/Back.modulate = Color("ff219e")
		$Options/Back.modulate = Color("ff219e")
		$OptionsWindow/Back.modulate = Color("ff219e")
	elif game.gamemode is CheeseMode:
		$Sign/Back.modulate = Color("ffb426")
		$Options/Back.modulate = Color("ffb426")
		$OptionsWindow/Back.modulate = Color("ffb426")


func _continue() -> void:
	game._pause(false)


func _restart() -> void:
	game._reset()


func _exit() -> void:
	game._end()


func _input(event : InputEvent) -> void:
	super(event)

	if is_in_assign_mode:
		input_to_assign = event
		input_received.emit()


## Waits for player button input and assigns it to **'action_name'**
func _assign_control(action_name : String) -> void:
	if is_in_assign_mode: return
	is_in_assign_mode = true
	
	$ContolAssign/Action.text = action_name
	
	$ContolAssign.position = Vector2(0,0)
	create_tween().tween_property($ContolAssign, "modulate:a", 1.0, 0.5).from(0.0)
	
	parent_menu.is_locked = true
	
	await get_tree().create_timer(0.25).timeout
	await input_received

	Player._update_input_config(action_name, input_to_assign)
	Player._apply_input_config(action_name)
	_load_icon_for_action(action_name)

	var tween : Tween = create_tween()
	tween.tween_property($ContolAssign, "modulate:a", 0.0, 0.5)
	tween.tween_property($ContolAssign, "position:x", 2000.0, 0.0)

	await get_tree().create_timer(0.5).timeout
	parent_menu.is_locked = false
	is_in_assign_mode = false


## Loads correct button icons for all actions
func _reload_all_action_icons() -> void:
	for action_name : String in [
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		"rotate_left",
		"rotate_right",
		"hard_drop",
		"swap_hold"
	]:
		_load_icon_for_action(action_name)


## Loads correct button icons for **'action'**
func _load_icon_for_action(action : String) -> void:
		var action_holder : Control = null
		
		match action:
			"move_left" : action_holder = $OptionsWindow/Scroll/V/MoveLeft
			"move_right" : action_holder = $OptionsWindow/Scroll/V/MoveRight
			"move_up" : action_holder = $OptionsWindow/Scroll/V/MoveUp
			"move_down" : action_holder = $OptionsWindow/Scroll/V/MoveDown
			"rotate_left" : action_holder = $OptionsWindow/Scroll/V/RotateLeft
			"rotate_right" : action_holder = $OptionsWindow/Scroll/V/RotateRight
			"hard_drop" : action_holder = $OptionsWindow/Scroll/V/HardDrop
			"swap_hold" : action_holder = $OptionsWindow/Scroll/V/Hold
			_ : return
		
		action_holder.get_node("Icon").free()
		
		var new_icon : TextureRect = Menu._create_button_icon(action, Vector2(24,24))
		new_icon.name = "Icon"
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.position = Vector2(326,0)
		action_holder.add_child(new_icon)
