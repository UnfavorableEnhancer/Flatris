extends MenuScreen

const LEADERBOARD_ENTRY : PackedScene = preload("res://scenes/menu/leaderboard_entry.tscn")
const MAX_ENTRIES : int = 50 ## Max amount of entries leaderboard is going to display

var game : Game = null

var current_leaderboard_page : int = 0
var current_leaderboard_entries : Array[TaloLeaderboardEntry] = []
var leaderboard_entries_count : int = 0
var at_last_leaderboard_page : bool = false

var gamemode_str : String = "ma"
var ruleset : int = Gamemode.RULESET.STANDARD


func _setup(game_ref : Game) -> void:
	game = game_ref


func _restart() -> void:
	game._reset()


func _exit() -> void:
	game._end()


func _next_page() -> void:
	if at_last_leaderboard_page : return
	current_leaderboard_page += 1
	$Leaderboard/Page.text = str(current_leaderboard_page + 1)
	_build_leaderboard()


func _previous_page() -> void:
	if current_leaderboard_page == 0 : return
	at_last_leaderboard_page = false
	current_leaderboard_page -= 1
	$Leaderboard/Page.text = str(current_leaderboard_page + 1)
	_build_leaderboard()


func _load_leaderboard() -> void:
	current_leaderboard_entries.clear()
	leaderboard_entries_count = 0
	
	if !Talo.players.identified : 
		_build_leaderboard()
		return
	
	var leaderboard_name : String = gamemode_str + "_"
	
	match ruleset:
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
	for i : Node in $Leaderboard/V.get_children():
		if i.name == "TableLegend" : continue
		i.queue_free()
	
	var record_name : String = gamemode_str + "_"
	
	match ruleset:
		Gamemode.RULESET.STANDARD : record_name += "std"
		Gamemode.RULESET.HARD : record_name += "hrd"
		Gamemode.RULESET.EXTREME : record_name += "xtr"
		Gamemode.RULESET.REVERSI : record_name += "rev"
		Gamemode.RULESET.ZONE : record_name += "zon"
		Gamemode.RULESET.CUSTOM : return
	
	record_name += "_record"
	var player_entry : ColorRect = LEADERBOARD_ENTRY.instantiate()
	
	match gamemode_str:
		"ma", "ch" :
			player_entry.entry_name = Player.profile_name + "_" + Player.vault_key.left(6)
			player_entry.score = Player.progress[record_name][Player.RECORD_ARRAY.SCORE]
			player_entry.level = Player.progress[record_name][Player.RECORD_ARRAY.LEVEL]
			player_entry.lines = Player.progress[record_name][Player.RECORD_ARRAY.LINES]
			
			$Leaderboard/V/TableLegend/Score.visible = true
			$Leaderboard/V/TableLegend/Level.visible = true
			$Leaderboard/V/TableLegend/Lines.visible = true
			$Leaderboard/V/TableLegend/Time.visible = false
		"ta" :
			player_entry.entry_name = Player.profile_name + "_" + Player.vault_key.left(6)
			player_entry.time = Player.progress[record_name][Player.RECORD_ARRAY.SCORE]
			player_entry.score_visible = false
			player_entry.level_visible = false
			player_entry.lines_visible = false
			player_entry.time_visible = true
			
			$Leaderboard/V/TableLegend/Score.visible = false
			$Leaderboard/V/TableLegend/Level.visible = false
			$Leaderboard/V/TableLegend/Lines.visible = false
			$Leaderboard/V/TableLegend/Time.visible = true
	
	player_entry.id = 0
	player_entry.color = Color("3b0d03")
	$Leaderboard/V.add_child(player_entry)
	
	if leaderboard_entries_count == 0 : 
		$Leaderboard/Prev._set_disable(true)
		$Leaderboard/Next._set_disable(true)
		return
	
	if current_leaderboard_page > 0 : $Leaderboard/Prev._set_disable(false)
	$Leaderboard/Next._set_disable(false)
	
	for i in 10:
		if current_leaderboard_entries.size() == i + current_leaderboard_page * 10 or i + current_leaderboard_page * 10 == MAX_ENTRIES: 
			at_last_leaderboard_page = true
			$Leaderboard/Next._set_disable(true)
			return
		
		var online_entry : ColorRect = LEADERBOARD_ENTRY.instantiate()
		var online_data : TaloLeaderboardEntry = current_leaderboard_entries[i + current_leaderboard_page * 10]
		
		match gamemode_str:
			"ma", "ch" :
				online_entry.entry_name = online_data.player_alias.identifier
				online_entry.score = online_data.score
				if online_data.props.size() > 0:
					online_entry.level = online_data.props[0].to_dictionary()["value"]
					online_entry.lines = online_data.props[1].to_dictionary()["value"]
			"ta" :
				online_entry.entry_name = online_data.player_alias.identifier
				online_entry.time = online_data.score
				online_entry.score_visible = false
				online_entry.level_visible = false
				online_entry.lines_visible = false
				online_entry.time_visible = true
		
		if online_data.player_alias.identifier == Player.profile_name + "_" + Player.vault_key.left(6): online_entry.color = Color(0.264, 0.493, 0.582, 1.0)
		online_entry.id = (i + current_leaderboard_page * 10) + 1
		$Leaderboard/V.add_child(online_entry)
		
		if current_leaderboard_entries.size() == ((i + current_leaderboard_page * 5) + 1) or i + current_leaderboard_page * 5 == MAX_ENTRIES: 
			at_last_leaderboard_page = true
			$Leaderboard/Next._set_disable(true)
