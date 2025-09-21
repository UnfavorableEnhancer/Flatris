extends MenuScreen

## All avaiable menu tabs
enum MENU_TAB {
	MARATHON_MODE,
	TIME_ATTACK_MODE,
	CHEESE_MODE,
	OPTIONS,
	STATS,
	ABOUT,
	EXIT
}

const LEADERBOARD_ENTRY : PackedScene = preload("res://scenes/menu/leaderboard_entry.tscn")
const ANIMATION_SPEED : float = 0.25
const MAX_ENTRIES : int = 50 ## Max amount of entries leaderboard is going to display

var current_tab : int = -1
var selected_skin : int = 0
var selected_color : int = Block.COLOR.RED
var selected_theme : int = Game.THEME.A
var selected_ruleset : int = Gamemode.RULESET.STANDARD

var is_in_assign_mode : bool = false ## True if currently assigning button to an action
var input_to_assign : InputEvent = null ## Stores input which is going to be assigned to an action
signal input_received ## Emitted when input is received, used in control assign sequence

var current_leaderboard_page : int = 0
var current_leaderboard_entries : Array[TaloLeaderboardEntry] = []
var leaderboard_entries_count : int = 0
var at_last_leaderboard_page : bool = false


func _ready() -> void:
	_reload_all_action_icons()
	_load_stats()
	
	Player.config["first_boot"] = false
	
	parent_menu.foreground.visible = true
	parent_menu.foreground._update_profile_info()
	
	$Main.position.y = -20.0
	$SkinWindow.modulate.a = 0.0
	$SkinWindow.position = Vector2(38, 68)
	$Main/WindowBack.modulate.a = 0.0
	$Main/WindowBack.position = Vector2(208.0, 108.0)
	$Main/GameWindow.modulate.a = 0.0
	$Main/GameWindow.visible = true
	$Main/GameWindow.position = Vector2(208.0, 108.0)
	$Main/OptionsWindow.modulate.a = 0.0
	$Main/OptionsWindow.visible = true
	$Main/OptionsWindow.position = Vector2(1000.0, 1000.0)
	$Main/StatsWindow.modulate.a = 0.0
	$Main/StatsWindow.visible = true
	$Main/StatsWindow.position = Vector2(1000.0, 1000.0)
	$Main/AboutWindow.modulate.a = 0.0
	$Main/AboutWindow.visible = true
	$Main/AboutWindow.position = Vector2(1000.0, 1000.0)
	$Main/QuitWindow.modulate.a = 0.0
	$Main/QuitWindow.visible = true
	$Main/QuitWindow.position = Vector2(1000.0, 1000.0)
	$Main/GameWindow/Expl.modulate.a = 1.0
	$Main/GameWindow/Expl2.modulate.a = 0.0
	$Main/GameWindow/Expl3.modulate.a = 0.0
	
	_select_block_skin(int(Player.config["block_skin"]))
	_select_color_skin(int(Player.config["color_skin"]))
	
	match int(Player.config["background_theme"]):
		Game.THEME.A : _select_theme("A")
		Game.THEME.B : _select_theme("B")
		Game.THEME.C : _select_theme("C")
	
	match int(Player.config["ruleset"]):
		Gamemode.RULESET.STANDARD : _select_ruleset("std")
		Gamemode.RULESET.HARD : _select_ruleset("hrd")
		Gamemode.RULESET.EXTREME : _select_ruleset("xtr")
		Gamemode.RULESET.REVERSI : _select_ruleset("rev")
		Gamemode.RULESET.ZONE : _select_ruleset("zon")
		Gamemode.RULESET.CUSTOM : _select_ruleset("custom")
	
	parent_menu._change_music("menu_theme_drums")
	
	cursor_selection_success.connect(_on_select)
	
	await parent_menu.all_screens_added
	_select_tab(MENU_TAB.MARATHON_MODE)
	cursor = Vector2i(0,1)
	_move_cursor()


## Called when cursor successfully selects selectable
func _on_select(pos : Vector2i) -> void:
	if pos.x == 0 and pos.y > 0: _select_tab(pos.y - 1)
	
	if Main.current_input_mode == Main.INPUT_MODE.MOUSE : return
	
	if current_tab == MENU_TAB.OPTIONS and pos.x == 1:
		$Main/OptionsWindow/Scroll.scroll_vertical = 32 * (pos.y - 5)
	if current_tab == MENU_TAB.STATS and pos.x == 1:
		$Main/StatsWindow/Scroll.scroll_vertical = 32 * (pos.y - 5)
	if pos.x == 2:
		$Main/GameWindow/CustomRuleset.scroll_vertical = 32 * (pos.y - 5)


## Selects menu tab
# You have full rights to kill me for this mess, but i didnt had much time left :P
func _select_tab(tab : int) -> void:
	var tab_instance : Control
	var tab_button_instance : Button
	var description_instance : Label = null
	var prev_tab_instance : Control
	var prev_tab_button_instance : Button
	var prev_description_instance : Label = null
	var tab_color : Color
	var show_skin_select : bool = true
	
	match current_tab:
		MENU_TAB.MARATHON_MODE :
			prev_tab_instance = $Main/GameWindow
			prev_tab_button_instance = $Main/Marathon
			prev_description_instance = $Main/GameWindow/Expl
		MENU_TAB.TIME_ATTACK_MODE :
			prev_tab_instance = $Main/GameWindow
			prev_tab_button_instance = $Main/TimeAttack
			prev_description_instance = $Main/GameWindow/Expl2
		MENU_TAB.CHEESE_MODE :
			prev_tab_instance = $Main/GameWindow
			prev_tab_button_instance = $Main/Cheese
			prev_description_instance = $Main/GameWindow/Expl3
		MENU_TAB.OPTIONS :
			prev_tab_instance = $Main/OptionsWindow
			prev_tab_button_instance = $Main/Options
		MENU_TAB.STATS :
			prev_tab_instance = $Main/StatsWindow
			prev_tab_button_instance = $Main/Stats
		MENU_TAB.ABOUT :
			prev_tab_instance = $Main/AboutWindow
			prev_tab_button_instance = $Main/About
		MENU_TAB.EXIT :
			prev_tab_instance = $Main/QuitWindow
			prev_tab_button_instance = $Main/Exit
	
	current_tab = tab
	
	match tab:
		MENU_TAB.MARATHON_MODE :
			tab_instance = $Main/GameWindow
			tab_button_instance = $Main/Marathon
			tab_color = tab_button_instance.button_color
			description_instance = $Main/GameWindow/Expl
			show_skin_select = true
			_load_ranks()
			_update_leaderboard()
			$Main/GameWindow/hrd.description = "Features 8x8x8 field. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/hrd.current_description = "Features 8x8x8 field. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/xtr.description = "Features 9x9x9 field and extended piece bag. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/xtr.current_description = "Features 9x9x9 field and extended piece bag. Game ends instantly if piece lands onto placed block."
		MENU_TAB.TIME_ATTACK_MODE :
			tab_instance = $Main/GameWindow
			tab_button_instance = $Main/TimeAttack
			tab_color = tab_button_instance.button_color
			description_instance = $Main/GameWindow/Expl2
			show_skin_select = true
			_load_ranks()
			_update_leaderboard()
			$Main/GameWindow/hrd.description = "Features 8x8x8 field. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/hrd.current_description = "Features 8x8x8 field. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/xtr.description = "Features 9x9x9 field and extended piece bag. Game ends instantly if piece lands onto placed block."
			$Main/GameWindow/xtr.current_description = "Features 9x9x9 field and extended piece bag. Game ends instantly if piece lands onto placed block."
		MENU_TAB.CHEESE_MODE :
			tab_instance = $Main/GameWindow
			tab_button_instance = $Main/Cheese
			tab_color = tab_button_instance.button_color
			description_instance = $Main/GameWindow/Expl3
			show_skin_select = true
			_load_ranks()
			_update_leaderboard()
			$Main/GameWindow/hrd.description = "Features 8x8x8 field and higher damage"
			$Main/GameWindow/hrd.current_description = "Features 8x8x8 field and higher damage"
			$Main/GameWindow/xtr.description = "Features 9x9x9 field, higher damage and extended piece bag."
			$Main/GameWindow/xtr.current_description = "Features 9x9x9 field, higher damage and extended piece bag."
		MENU_TAB.OPTIONS :
			tab_instance = $Main/OptionsWindow
			tab_button_instance = $Main/Options
			tab_color = tab_button_instance.button_color
			show_skin_select = false
		MENU_TAB.STATS :
			tab_instance = $Main/StatsWindow
			tab_button_instance = $Main/Stats
			tab_color = tab_button_instance.button_color
			show_skin_select = false
		MENU_TAB.ABOUT :
			tab_instance = $Main/AboutWindow
			tab_button_instance = $Main/About
			tab_color = tab_button_instance.button_color
			show_skin_select = false
		MENU_TAB.EXIT :
			tab_instance = $Main/QuitWindow
			tab_button_instance = $Main/Exit
			tab_color = tab_button_instance.button_color
			show_skin_select = false
	
	var tween = create_tween().set_parallel()
	
	if prev_tab_instance != null and prev_tab_instance != tab_instance : 
		var tween2 = create_tween()
		tween2.tween_property(prev_tab_instance, "modulate:a", 0.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween2.tween_property(prev_tab_instance, "position", Vector2(1000,1000), 0.0)
	
	tween.tween_property(tab_instance, "modulate:a", 1.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tab_instance.position = Vector2(208.0, 108.0)
	
	if prev_description_instance != null :
		tween.tween_property(prev_description_instance, "modulate:a", 0.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if description_instance != null :
		tween.tween_property(description_instance, "modulate:a", 1.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if prev_tab_button_instance != null :
		tween.tween_property(prev_tab_button_instance, "size:x", 146.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(tab_button_instance, "size:x", 170.0, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Main/WindowBack, "modulate", tab_color, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($SkinWindow/Back, "modulate", tab_color, ANIMATION_SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	selectables.clear()
	
	if show_skin_select :
		tween.tween_property($SkinWindow, "modulate:a", 1.0, ANIMATION_SPEED * 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property($Main, "position:y", 0.0, ANIMATION_SPEED * 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		_set_selectable_position($SkinWindow/BlockSkin/PrevSkin, Vector2i(0,0))
		_set_selectable_position($SkinWindow/BlockSkin/NextSkin, Vector2i(1,0))
		_set_selectable_position($SkinWindow/ColorSkin/PrevColor, Vector2i(2,0))
		_set_selectable_position($SkinWindow/ColorSkin/NextColor, Vector2i(3,0))
		_set_selectable_position($SkinWindow/ThemeSkin/ThemeA, Vector2i(4,0))
		_set_selectable_position($SkinWindow/ThemeSkin/ThemeB, Vector2i(5,0))
		_set_selectable_position($SkinWindow/ThemeSkin/ThemeC, Vector2i(6,0))
	
	else :
		tween.tween_property($SkinWindow, "modulate:a", 0.0, ANIMATION_SPEED * 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property($Main, "position:y", -20.0, ANIMATION_SPEED * 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	_set_selectable_position($Main/Marathon, Vector2i(0, 1))
	_set_selectable_position($Main/TimeAttack, Vector2i(0, 2))
	_set_selectable_position($Main/Cheese, Vector2i(0, 3))
	_set_selectable_position($Main/Options, Vector2i(0, 4))
	_set_selectable_position($Main/Stats, Vector2i(0, 5))
	_set_selectable_position($Main/About, Vector2i(0, 6))
	_set_selectable_position($Main/Exit, Vector2i(0, 7))
	
	match current_tab:
		MENU_TAB.MARATHON_MODE, MENU_TAB.TIME_ATTACK_MODE, MENU_TAB.CHEESE_MODE :
			_set_selectable_position($Main/GameWindow/std, Vector2i(1, 1))
			_set_selectable_position($Main/GameWindow/hrd, Vector2i(1, 2))
			_set_selectable_position($Main/GameWindow/xtr, Vector2i(1, 3))
			_set_selectable_position($Main/GameWindow/rev, Vector2i(1, 4))
			_set_selectable_position($Main/GameWindow/zon, Vector2i(1, 5))
			_set_selectable_position($Main/GameWindow/Custom, Vector2i(1, 6))
			_set_selectable_position($Main/GameWindow/Play, Vector2i(1, 7))
			
			if selected_ruleset == Gamemode.RULESET.CUSTOM:
				_load_custom_ruleset_selectables()
			else:
				_unload_custom_ruleset_selectables()
		
		MENU_TAB.OPTIONS :
			_set_selectable_position($Main/OptionsWindow/Scroll/V/Music/Slider, Vector2i(1, 1))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/Sound/Slider, Vector2i(1, 2))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/Fullscreen, Vector2i(1, 3))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/Resolution/Slider, Vector2i(1, 4))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/FPSLimit/Slider, Vector2i(1, 5))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/SaveOnline, Vector2i(1, 6))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/StaticBack, Vector2i(1, 7))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/MoveLeft, Vector2i(1, 8))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/MoveRight, Vector2i(1, 9))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/MoveUp, Vector2i(1, 10))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/MoveDown, Vector2i(1, 11))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/RotateRight, Vector2i(1, 12))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/RotateLeft, Vector2i(1, 13))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/HardDrop, Vector2i(1, 14))
			_set_selectable_position($Main/OptionsWindow/Scroll/V/Hold, Vector2i(1, 15))
		
		MENU_TAB.STATS :
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalPlayTime/Button, Vector2i(1, 1))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalMAAttempts/Button, Vector2i(1, 2))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalTAAttempts/Button, Vector2i(1, 3))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalCHAttempts/Button, Vector2i(1, 4))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalMAScore/Button, Vector2i(1, 5))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TopMAScoreGain/Button, Vector2i(1, 6))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalCHScore/Button, Vector2i(1, 7))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TopCHScoreGain/Button, Vector2i(1, 8))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalCheese/Button, Vector2i(1, 9))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalPieces/Button, Vector2i(1, 10))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalHolds/Button, Vector2i(1, 11))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalLines/Button, Vector2i(1, 12))
			_set_selectable_position($Main/StatsWindow/Scroll/V/Total4XLines/Button, Vector2i(1, 13))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalAllClears/Button, Vector2i(1, 14))
			_set_selectable_position($Main/StatsWindow/Scroll/V/TotalDamage/Button, Vector2i(1, 15))
		
		MENU_TAB.EXIT :
			_set_selectable_position($Main/QuitWindow/Exit, Vector2i(1,7))
	
	pass


## Selects block skin
func _select_block_skin(skin : int) -> void:
	selected_skin = skin
	$SkinWindow/BlockSkin/Skin.frame = selected_skin
	Player.config["block_skin"] = selected_skin


## Switches to next block skin
func _next_block_skin() -> void:
	selected_skin = wrapi(selected_skin + 1, 0, 23)
	$SkinWindow/BlockSkin/Skin.frame = selected_skin
	Player.config["block_skin"] = selected_skin


## Switches to previous block skin
func _prev_block_skin() -> void:
	selected_skin = wrapi(selected_skin - 1, 0, 23)
	$SkinWindow/BlockSkin/Skin.frame = selected_skin
	Player.config["block_skin"] = selected_skin


## Selects color skin
func _select_color_skin(color : int) -> void:
	selected_color = color
	$SkinWindow/ColorSkin/Color.color = Block.COLOR_VALUES[selected_color]
	$SkinWindow/BlockSkin/Skin.modulate = Block.COLOR_VALUES[selected_color]
	Player.config["color_skin"] = selected_color


## Switches to next color skin
func _next_color() -> void:
	selected_color = wrapi(selected_color + 1, 0, 10)
	$SkinWindow/ColorSkin/Color.color = Block.COLOR_VALUES[selected_color]
	$SkinWindow/BlockSkin/Skin.modulate = Block.COLOR_VALUES[selected_color]
	Player.config["color_skin"] = selected_color


## Switches to previous color skin
func _prev_color() -> void:
	selected_color = wrapi(selected_color - 1, 0, 10)
	$SkinWindow/ColorSkin/Color.color = Block.COLOR_VALUES[selected_color]
	$SkinWindow/BlockSkin/Skin.modulate = Block.COLOR_VALUES[selected_color]
	Player.config["color_skin"] = selected_color


## Selects background theme
func _select_theme(new_theme : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)
	match new_theme:
		"A" : 
			selected_theme = Game.THEME.A
			tween.tween_property($SkinWindow/ThemeSkin/ThemeA, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeB, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeC, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"B" : 
			selected_theme = Game.THEME.B
			tween.tween_property($SkinWindow/ThemeSkin/ThemeA, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeB, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeC, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"C" : 
			selected_theme = Game.THEME.C
			tween.tween_property($SkinWindow/ThemeSkin/ThemeA, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeB, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($SkinWindow/ThemeSkin/ThemeC, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
	
	Player.config["background_theme"] = selected_theme


## Selects ruleset
func _select_ruleset(ruleset : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)
	var tween2 : Tween = create_tween()
	
	if selected_ruleset == Gamemode.RULESET.CUSTOM and ruleset != "custom":
		_unload_custom_ruleset_selectables()
		
		tween2.tween_property($Main/GameWindow/CustomRuleset, "modulate:a", 0.0, ANIMATION_SPEED)
		tween2.tween_property($Main/GameWindow/CustomRuleset, "position:x", -1000.0, 0.0)
		$Main/GameWindow/Leaderboard.position.x = 158
		tween.tween_property($Main/GameWindow/Leaderboard, "modulate:a", 1.0, ANIMATION_SPEED)
	
	match ruleset:
		"std" : 
			selected_ruleset = Gamemode.RULESET.STANDARD
			tween.tween_property($Main/GameWindow/std, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"hrd" : 
			selected_ruleset = Gamemode.RULESET.HARD
			tween.tween_property($Main/GameWindow/std, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"xtr" : 
			selected_ruleset = Gamemode.RULESET.EXTREME
			tween.tween_property($Main/GameWindow/std, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"rev" : 
			selected_ruleset = Gamemode.RULESET.REVERSI
			tween.tween_property($Main/GameWindow/std, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"zon" : 
			selected_ruleset = Gamemode.RULESET.ZONE
			tween.tween_property($Main/GameWindow/std, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
		"custom" : 
			selected_ruleset = Gamemode.RULESET.CUSTOM
			tween.tween_property($Main/GameWindow/std, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/hrd, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/xtr, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/rev, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/zon, "modulate", Color(0.5,0.5,0.5), ANIMATION_SPEED)
			tween.tween_property($Main/GameWindow/Custom, "modulate", Color(1.0,1.0,1.0), ANIMATION_SPEED)
			
			tween2.tween_property($Main/GameWindow/Leaderboard, "modulate:a", 0.0, ANIMATION_SPEED)
			tween2.tween_property($Main/GameWindow/Leaderboard, "position:x", -1000.0, 0.0)
			$Main/GameWindow/CustomRuleset.position = Vector2(124,34)
			tween.tween_property($Main/GameWindow/CustomRuleset, "modulate:a", 1.0, ANIMATION_SPEED)
			
			_load_custom_ruleset_selectables()
	
	Player.config["ruleset"] = selected_ruleset
	_update_leaderboard()


func _start_game() -> void:
	var tween : Tween = create_tween().set_loops(0)
	tween.tween_property($Main/GameWindow/Play, "modulate", Color.CYAN, 0.1)
	tween.tween_property($Main/GameWindow/Play, "modulate", Color.WHITE, 0.1)
	
	var gamemode : Gamemode
	match current_tab:
		MENU_TAB.MARATHON_MODE:
			gamemode = MarathonMode.new()
			gamemode.ruleset = selected_ruleset
		MENU_TAB.TIME_ATTACK_MODE:
			gamemode = TimeAttackMode.new()
			gamemode.ruleset = selected_ruleset
		MENU_TAB.CHEESE_MODE:
			gamemode = CheeseMode.new()
			gamemode.ruleset = selected_ruleset
	
	main._start_game(gamemode, selected_theme)


func _quit() -> void:
	Player._save_profile()
	
	main._exit()


func _load_ranks() -> void:
	var mode_str : String
	
	match current_tab:
		MENU_TAB.MARATHON_MODE : mode_str = "ma_"
		MENU_TAB.TIME_ATTACK_MODE : mode_str = "ta_"
		MENU_TAB.CHEESE_MODE : mode_str = "ch_"
	
	for i : String in ["std", "hrd", "xtr", "rev", "zon"]:
		var rank_letter : String = "-"
		var rank_color : Color = Color.WHITE
		match Player.progress[mode_str + i + "_rank"]:
			Player.RANK.NONE : rank_letter = "-"
			Player.RANK.E : 
				rank_color = Color.WHITE
				rank_letter = "E"
			Player.RANK.D : 
				rank_color = Color.WHITE
				rank_letter = "D"
			Player.RANK.C : 
				rank_color = Color.WHITE
				rank_letter = "C"
			Player.RANK.B : 
				rank_color = Color.WHITE
				rank_letter = "B"
			Player.RANK.A : 
				rank_color = Color.WHITE
				rank_letter = "A"
			Player.RANK.S : 
				rank_color = Color("14ff75")
				rank_letter = "S"
			Player.RANK.X : 
				rank_color = Color("ce61f1")
				rank_letter = "X"
			Player.RANK.M : 
				rank_color = Color("ff801b")
				rank_letter = "M"
		
		get_node("Main/GameWindow/" + i + "/Rank/Label").text = rank_letter
		get_node("Main/GameWindow/" + i + "/Rank/Label").modulate = rank_color


func _load_stats() -> void:
	$Main/StatsWindow/Scroll/V/TotalPlayTime/Value.text = Main._to_time(Player.stats["total_play_time"])
	$Main/StatsWindow/Scroll/V/TotalMAAttempts/Value.text = _make_number_str_with_zeroes(Player.stats["total_marathon_attempts"], "00")
	$Main/StatsWindow/Scroll/V/TotalTAAttempts/Value.text = _make_number_str_with_zeroes(Player.stats["total_time_attack_attempts"], "00")
	$Main/StatsWindow/Scroll/V/TotalCHAttempts/Value.text = _make_number_str_with_zeroes(Player.stats["total_cheese_attempts"], "00")
	$Main/StatsWindow/Scroll/V/TotalMAScore/Value.text = _make_number_str_with_zeroes(Player.stats["total_marathon_score"], "000000")
	$Main/StatsWindow/Scroll/V/TopMAScoreGain/Value.text = _make_number_str_with_zeroes(Player.stats["top_marathon_score_gain"], "000000")
	$Main/StatsWindow/Scroll/V/TotalCHScore/Value.text = _make_number_str_with_zeroes(Player.stats["total_cheese_score"], "000000")
	$Main/StatsWindow/Scroll/V/TopCHScoreGain/Value.text = _make_number_str_with_zeroes(Player.stats["top_cheese_score_gain"], "000000")
	$Main/StatsWindow/Scroll/V/TotalCheese/Value.text = _make_number_str_with_zeroes(Player.stats["total_cheese_erased"], "000")
	$Main/StatsWindow/Scroll/V/TotalPieces/Value.text = _make_number_str_with_zeroes(Player.stats["total_pieces_landed"], "0000")
	$Main/StatsWindow/Scroll/V/TotalHolds/Value.text = _make_number_str_with_zeroes(Player.stats["total_holds"], "0000")
	$Main/StatsWindow/Scroll/V/TotalLines/Value.text = _make_number_str_with_zeroes(Player.stats["total_lines"], "0000")
	$Main/StatsWindow/Scroll/V/Total4XLines/Value.text = _make_number_str_with_zeroes(Player.stats["total_tetrises"], "000")
	$Main/StatsWindow/Scroll/V/TotalAllClears/Value.text = _make_number_str_with_zeroes(Player.stats["total_all_clears"], "00")
	$Main/StatsWindow/Scroll/V/TotalDamage/Value.text = _make_number_str_with_zeroes(Player.stats["total_damage"], "000")


func _make_number_str_with_zeroes(number : int, zeroes : String = "000000") -> String:
	var str_number = str(number)
	
	if str_number.length() > zeroes.length():
		return str_number
	else:
		str_number = zeroes.left(zeroes.length() - str_number.length()) + str_number
		return str_number


func _unload_custom_ruleset_selectables() -> void:
	_remove_selectable_position(Vector2i(2, 1))
	_remove_selectable_position(Vector2i(2, 2))
	_remove_selectable_position(Vector2i(2, 3))
	_remove_selectable_position(Vector2i(2, 4))
	_remove_selectable_position(Vector2i(2, 5))
	_remove_selectable_position(Vector2i(2, 6))
	_remove_selectable_position(Vector2i(2, 7))
	_remove_selectable_position(Vector2i(2, 8))
	_remove_selectable_position(Vector2i(2, 9))
	_remove_selectable_position(Vector2i(2, 10))
	
	_set_selectable_position($Main/GameWindow/Leaderboard/Prev, Vector2i(2, 1))
	_set_selectable_position($Main/GameWindow/Leaderboard/Next, Vector2i(3, 1))


func _load_custom_ruleset_selectables() -> void:
	_remove_selectable_position(Vector2i(2, 1))
	_remove_selectable_position(Vector2i(3, 1))
	
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/SizeX/Slider, Vector2i(2, 1))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/SizeY/Slider, Vector2i(2, 2))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/SizeZ/Slider, Vector2i(2, 3))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/MaxDamage/Slider, Vector2i(2, 4))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/DamageRec/Slider, Vector2i(2, 5))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Extend, Vector2i(2, 6))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Gravity, Vector2i(2, 7))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Zone, Vector2i(2, 8))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Reversi, Vector2i(2, 9))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Dzen, Vector2i(2, 10))
	_set_selectable_position($Main/GameWindow/CustomRuleset/V/Death, Vector2i(2, 11))


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
			"move_left" : action_holder = $Main/OptionsWindow/Scroll/V/MoveLeft
			"move_right" : action_holder = $Main/OptionsWindow/Scroll/V/MoveRight
			"move_up" : action_holder = $Main/OptionsWindow/Scroll/V/MoveUp
			"move_down" : action_holder = $Main/OptionsWindow/Scroll/V/MoveDown
			"rotate_left" : action_holder = $Main/OptionsWindow/Scroll/V/RotateLeft
			"rotate_right" : action_holder = $Main/OptionsWindow/Scroll/V/RotateRight
			"hard_drop" : action_holder = $Main/OptionsWindow/Scroll/V/HardDrop
			"swap_hold" : action_holder = $Main/OptionsWindow/Scroll/V/Hold
			_ : return
		
		action_holder.get_node("Icon").free()
		
		var new_icon : TextureRect = Menu._create_button_icon(action, Vector2(24,24))
		new_icon.name = "Icon"
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.position = Vector2(336,0)
		action_holder.add_child(new_icon)


func _next_page() -> void:
	if at_last_leaderboard_page : return
	current_leaderboard_page += 1
	$Main/GameWindow/Leaderboard/Page.text = str(current_leaderboard_page + 1)
	_build_leaderboard()


func _previous_page() -> void:
	if current_leaderboard_page == 0 : return
	at_last_leaderboard_page = false
	current_leaderboard_page -= 1
	$Main/GameWindow/Leaderboard/Page.text = str(current_leaderboard_page + 1)
	_build_leaderboard()


func _update_leaderboard() -> void:
	current_leaderboard_entries.clear()
	leaderboard_entries_count = 0
	
	if !Talo.players.identified : 
		_build_leaderboard()
		return
	
	var leaderboard_name : String
	
	match current_tab:
		MENU_TAB.MARATHON_MODE : leaderboard_name = "ma_"
		MENU_TAB.TIME_ATTACK_MODE : leaderboard_name = "ta_"
		MENU_TAB.CHEESE_MODE : leaderboard_name = "ch_"
		_ : return
	
	match selected_ruleset:
		Gamemode.RULESET.STANDARD : leaderboard_name += "std"
		Gamemode.RULESET.HARD : leaderboard_name += "hrd"
		Gamemode.RULESET.EXTREME : leaderboard_name += "xtr"
		Gamemode.RULESET.REVERSI : leaderboard_name += "rev"
		Gamemode.RULESET.ZONE : leaderboard_name += "zon"
		Gamemode.RULESET.CUSTOM : return
	
	var options := Talo.leaderboards.GetEntriesOptions.new()
	options.page = 0

	var res := await Talo.leaderboards.get_entries(leaderboard_name, options)
	if res == null:
		_build_leaderboard()
		return
	
	current_leaderboard_entries = res.entries
	leaderboard_entries_count = res.count
	
	_build_leaderboard()


func _build_leaderboard() -> void:
	for i : Node in $Main/GameWindow/Leaderboard/V.get_children():
		if i.name == "TableLegend" : continue
		i.queue_free()
	
	at_last_leaderboard_page = false
	var record_name : String
	
	match current_tab:
		MENU_TAB.MARATHON_MODE : record_name = "ma_"
		MENU_TAB.TIME_ATTACK_MODE : record_name = "ta_"
		MENU_TAB.CHEESE_MODE : record_name = "ch_"
	
	match selected_ruleset:
		Gamemode.RULESET.STANDARD : record_name += "std"
		Gamemode.RULESET.HARD : record_name += "hrd"
		Gamemode.RULESET.EXTREME : record_name += "xtr"
		Gamemode.RULESET.REVERSI : record_name += "rev"
		Gamemode.RULESET.ZONE : record_name += "zon"
		Gamemode.RULESET.CUSTOM : return
	
	record_name += "_record"
	var player_entry : ColorRect = LEADERBOARD_ENTRY.instantiate()
	
	match current_tab:
		MENU_TAB.MARATHON_MODE, MENU_TAB.CHEESE_MODE :
			$Main/GameWindow/Leaderboard/V/TableLegend/Score.visible = true
			$Main/GameWindow/Leaderboard/V/TableLegend/Level.visible = true
			$Main/GameWindow/Leaderboard/V/TableLegend/Lines.visible = true
			$Main/GameWindow/Leaderboard/V/TableLegend/Time.visible = false
			
			player_entry.entry_name = Player.profile_name + "_" + Player.vault_key.left(6)
			player_entry.score = Player.progress[record_name][Player.RECORD_ARRAY.SCORE]
			player_entry.level = Player.progress[record_name][Player.RECORD_ARRAY.LEVEL]
			player_entry.lines = Player.progress[record_name][Player.RECORD_ARRAY.LINES]
			
		MENU_TAB.TIME_ATTACK_MODE :
			$Main/GameWindow/Leaderboard/V/TableLegend/Score.visible = false
			$Main/GameWindow/Leaderboard/V/TableLegend/Level.visible = false
			$Main/GameWindow/Leaderboard/V/TableLegend/Lines.visible = false
			$Main/GameWindow/Leaderboard/V/TableLegend/Time.visible = true
			
			player_entry.entry_name = Player.profile_name + "_" + Player.vault_key.left(6)
			player_entry.time = Player.progress[record_name][Player.RECORD_ARRAY.SCORE]
			player_entry.score_visible = false
			player_entry.level_visible = false
			player_entry.lines_visible = false
			player_entry.time_visible = true
	
	player_entry.id = 0
	player_entry.color = Color("3b0d03")
	$Main/GameWindow/Leaderboard/V.add_child(player_entry)
	
	if leaderboard_entries_count == 0 : 
		$Main/GameWindow/Leaderboard/Prev._set_disable(true)
		$Main/GameWindow/Leaderboard/Next._set_disable(true)
		return
	
	if current_leaderboard_page > 0 : $Main/GameWindow/Leaderboard/Prev._set_disable(false)
	else : $Main/GameWindow/Leaderboard/Prev._set_disable(true)
	
	$Main/GameWindow/Leaderboard/Next._set_disable(false)
	
	for i in 5:
		if current_leaderboard_entries.size() == i + current_leaderboard_page * 5 or i + current_leaderboard_page * 5 == MAX_ENTRIES: 
			at_last_leaderboard_page = true
			$Main/GameWindow/Leaderboard/Next._set_disable(true)
			return
		
		var online_entry : ColorRect = LEADERBOARD_ENTRY.instantiate()
		var online_data : TaloLeaderboardEntry = current_leaderboard_entries.get(i + current_leaderboard_page * 5)
		
		if online_data == null :
			at_last_leaderboard_page = true
			$Main/GameWindow/Leaderboard/Next._set_disable(true)
			return
		
		match current_tab:
			MENU_TAB.MARATHON_MODE, MENU_TAB.CHEESE_MODE :
				online_entry.entry_name = online_data.player_alias.identifier
				online_entry.score = online_data.score
				if online_data.props.size() > 0:
					online_entry.level = online_data.props[0].to_dictionary()["value"]
					online_entry.lines = online_data.props[1].to_dictionary()["value"]
			MENU_TAB.TIME_ATTACK_MODE :
				online_entry.entry_name = online_data.player_alias.identifier
				online_entry.time = online_data.score
				online_entry.score_visible = false
				online_entry.level_visible = false
				online_entry.lines_visible = false
				online_entry.time_visible = true
		
		if online_data.player_alias.identifier == Player.profile_name + "_" + Player.vault_key.left(6): online_entry.color = Color(0.061, 0.305, 0.191, 1.0)
		online_entry.id = (i + current_leaderboard_page * 5) + 1
		$Main/GameWindow/Leaderboard/V.add_child(online_entry)
		
		if current_leaderboard_entries.size() == ((i + current_leaderboard_page * 5) + 1) or i + current_leaderboard_page * 5 == MAX_ENTRIES: 
			at_last_leaderboard_page = true
			$Main/GameWindow/Leaderboard/Next._set_disable(true)


func _visit_source_code() -> void:
	OS.shell_open("https://github.com/UnfavorableEnhancer/Flatris")


func _visit_luminext() -> void:
	OS.shell_open("https://github.com/UnfavorableEnhancer/Project-Luminext")
