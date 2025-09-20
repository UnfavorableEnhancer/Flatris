extends Node3D

class_name Background

@onready var music_player : AudioStreamPlayer = $Music
@onready var background_animation : AnimationPlayer = $A


func _ready() -> void:
	if not Player.config["static_background"]:
		background_animation.play("anim")


func _start_music() -> void:
	music_player.play()


func _stop_music() -> void:
	music_player.stop()


func _pause_music(on : bool) -> void:
	music_player.stream_paused = on
