extends Control

func _play() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(%Progress,"modulate:a",1.0,0.5).from(0.0)
	tween.tween_property(%TextBack,"scale:x",1.0,0.5).from(0.0)
	
	$A.play("loading")


func _stop() -> void:
	$A.stop()
