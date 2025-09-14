extends Node

class_name Gamemode

var main ## Main instance
var game ## Game instance
var foreground ## Foreground instance

var gamemode_name : String = "" ## Name of the gamemode
var ruleset ## Used by the gamemode ruleset


## Called on game reset
func _reset() -> void:
	pass


## Called on game pause
func _pause(_on : bool) -> void:
	pass


## Called on game over
func _game_over() -> void:
	pass


## Called on game exit
func _end() -> void:
	pass
