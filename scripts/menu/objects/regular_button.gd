@tool # TODO : Remove when building release build
extends MenuSelectableButton

#-----------------------------------------------------------------------
# Button used in most of the menu screens
#-----------------------------------------------------------------------

## Avaiable to show button layouts when this button is selected
enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SLIDER,
	MAIN_MENU,
	TOGGLE_UP_DOWN,
	TOGGLE,
	SCROLL,
	PAUSE,
	GAMEOVER,
}

@export var description_node : Node ## Description [Label] node reference

@export var glow_color : Color ## Selected button color

@export_multiline var description : String = "" ## Description shown when button is selected
@export_multiline var disabled_description : String = "" ## Description shown when button is disabled
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT  ## Button layout foreground menu screen will show when this button is selected

@export var is_setting_button : bool = false ## Is this button used for setting profile config values

var current_description : String = description ## Description this button currently displays when selected


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	disable_toggled.connect(_disabled)

	if work_mode == WORK_MODE.TOGGLE : 
		selection_toggled.connect(_toggled)
		if is_setting_button : _set_toggle_by_data()

	if is_off:
		modulate = Color(0.5,0.5,0.5,1.0)
		current_description = disabled_description
	else:
		current_description = description

	$Label.text = tr(text)


func _process(_delta : float) -> void:
	$Label.text = text


## Called when this button is selected
func _selected() -> void:
	parent_menu._play_sound("select")

	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	if not description_node == null:
		description_node.text = tr(current_description)
	
	$Back.color = glow_color
	$Back.color.a = 0.75
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


## Called when this button is deselected
func _deselected() -> void:
	$Back.color = Color(0.24,0.24,0.24,0.75)


## Called when button is pressed [br]
## **'silent'** - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	if is_off:
		var tween : Tween = create_tween()
		tween.tween_property(self,"modulate",Color.RED,0.1)
		tween.tween_property(self,"modulate",Color(0.5,0.5,0.5,1.0),0.1)
		parent_menu._play_sound("error")
		return
	
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.5).from(1.0)

	super(silent)


## Called when this button is toggled
func _toggled(on : bool) -> void:
	if is_off: return

	$IO.text = tr("ON") if is_toggled else tr("OFF")

	if is_setting_button : Player._set_config_value(call_string, on)


## Sets button toggle state by config data its setting
func _set_toggle_by_data() -> void:
	is_toggled = false

	var data : Variant 
	if is_setting_button : data = Player._get_config_value(call_string)
	
	if data == null : 
		modulate = Color.RED
		return
		
	$IO.text = tr("ON") if is_toggled else tr("OFF")


## Called when this button disabled state changes
func _disabled(on : bool) -> void:
	if on : 
		modulate = Color(0.5,0.5,0.5,1.0)
		current_description = tr(disabled_description)
	else: 
		modulate = Color.WHITE
		current_description = tr(description)
