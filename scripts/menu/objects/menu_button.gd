@tool
extends MenuSelectableButton

#-----------------------------------------------------------------------
# Button used in main menu screen for next menu screen selection
#-----------------------------------------------------------------------

@export_multiline var description : String = "" ## Description shown when button is selected
@export_multiline var disabled_description : String = "" ## Description shown when button is disabled
@export var button_color : Color ## Selected button color

## Avaiable to show button layouts when this button is selected
enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SLIDER,
	TOGGLE_UP_DOWN,
	NEXT_SKIN,
	PREV_SKIN,
	SELECT_THEME,
	TOGGLE,
	SCROLL,
	PAUSE,
	GAMEOVER,
}

@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT  ## Button layout foreground menu screen will show when this button is selected


func _ready() -> void:
	super()
	
	if is_off : button_color = Color(0.5,0.5,0.5,1.0)
	
	selected.connect(_selected)
	disable_toggled.connect(_disabled)
	
	$Label.text = tr(text)


func _process(_delta : float) -> void:
	$Label.text = text
	$Back.self_modulate = button_color


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
	if not silent and press_sound_name.begins_with("announce") : parent_menu._play_sound("confirm")
	
	super(silent)


## Called when this button is selected
func _selected() -> void:
	parent_menu._play_sound("select")
	
	if is_instance_valid(parent_menu.foreground):
		parent_menu.foreground._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


## Called when this button disabled state changes
func _disabled(on : bool) -> void:
	is_off = on
	if is_off : 
		modulate = Color(0.5,0.5,0.5,1.0)
	else: 
		modulate = Color.WHITE
