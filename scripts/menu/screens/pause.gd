extends MenuScreen

var game : Game = null


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
