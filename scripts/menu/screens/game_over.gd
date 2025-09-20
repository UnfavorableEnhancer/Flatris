extends MenuScreen

var game : Game = null


func _setup(game_ref : Game) -> void:
	game = game_ref


func _restart() -> void:
	game._reset()


func _exit() -> void:
	game._end()
