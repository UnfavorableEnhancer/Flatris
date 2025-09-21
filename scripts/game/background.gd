extends Node3D

class_name Background

@onready var music_player : AudioStreamPlayer = $Music
@onready var background_animation : AnimationPlayer = $A


func _start_music() -> void:
	music_player.volume_db = 0.0
	music_player.play()
	
	if not Player.config["static_background"]:
		background_animation.play("anim")


func _stop_music() -> void:
	music_player.stop()
	background_animation.play("end")


func _pause_music(on : bool) -> void:
	music_player.stream_paused = on


func _muffle_music(on : bool) -> void:
	if on : create_tween().tween_property(music_player, "volume_db", -20.0, 2.0)
	else : create_tween().tween_property(music_player, "volume_db", 0.0, 2.0)


func _fade_out() -> void:
	create_tween().tween_property(music_player, "volume_db", -99.0, 3.0).set_trans(Tween.TRANS_CUBIC)
