extends MenuScreen


#-----------------------------------------------------------------------
# Displays button layout depending on selected button/slider
#-----------------------------------------------------------------------

const LABEL_FONT : FontFile = preload("res://fonts/visitor1.ttf")
const BUTTON_ICON_SIZE : Vector2 = Vector2(24,16)

## All avaiable to display button layouts
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

var current_button_layout : int = -1 ## Currently shown button layout
@onready var time_text : Label = $Time ## System time display label node


func _ready() -> void:
	main.input_method_changed.connect(_show_button_layout.bind(-1))
	main.total_time_tick.connect(func() -> void: time_text.text = Time.get_time_string_from_system())
	
	_update_profile_info()


## Brings this menu screen on top layer
func _raise() -> void:
	_show_button_layout(MENU_BUTTON_LAYOUT.EMPTY)
	parent_menu.move_child(self, parent_menu.get_child_count() - 1)


func _update_profile_info() -> void:
	$Player.text = Player.profile_name


## Displays button layout
func  _show_button_layout(button_layout : int = -1) -> void:
	if current_button_layout == button_layout : return
	
	# If you input -1, function will just recreate current button layout (which is used when input method changed)
	if button_layout == -1 : button_layout = current_button_layout
	
	for i : Control in $ButtonLayout.get_children():
		i.queue_free()
	
	match button_layout:
		MENU_BUTTON_LAYOUT.EMPTY:
			return
		
		# SELECT (UP_DOWN) LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.UP_DOWN_SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))
		
		# SELECT LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))
		
		# CHANGE_INPUT LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.CHANGE_INPUT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("CHANGE INPUT"))
		
		# CHANGE_VALUE SELECT BACK
		MENU_BUTTON_LAYOUT.SLIDER:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE :
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
				
				$ButtonLayout.add_child(Menu._create_button_icon("left_right", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("CHANGE VALUE"))
				
			else:
				$ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("CHANGE VALUE"))

		MENU_BUTTON_LAYOUT.TOGGLE_UP_DOWN:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("TOGGLE"))
		
		MENU_BUTTON_LAYOUT.NEXT_SKIN:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("NEXT SKIN"))
		
		MENU_BUTTON_LAYOUT.PREV_SKIN:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("PREVIOUS SKIN"))
		
		MENU_BUTTON_LAYOUT.SELECT_THEME:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("SELECT THIS THEME"))

		MENU_BUTTON_LAYOUT.TOGGLE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("TOGGLE"))
		
		MENU_BUTTON_LAYOUT.SCROLL:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SCROLL"))
		
		MENU_BUTTON_LAYOUT.PAUSE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("RETURN TO THE GAME"))
		
		MENU_BUTTON_LAYOUT.GAMEOVER:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("RETURN TO THE MENU"))

		
	current_button_layout = button_layout


## Creates special label for button layout
func _create_text_node(text : String) -> Label:
	var label : Label = Label.new()
	var label_settings : LabelSettings = LabelSettings.new()
	
	label_settings.font = LABEL_FONT
	label_settings.font_size = 12
	
	label.text = " " + tr(text) + "   "
	label.uppercase = true
	label.label_settings = label_settings
	
	return label
