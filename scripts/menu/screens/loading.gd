extends Control

class_name LoadingScreen


func _play() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self,"modulate:a",1.0,0.5)
	
	$A.play("loading")


func _stop() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self,"modulate:a",0.0,0.5)
	
	await tween.finished
	$A.stop()
