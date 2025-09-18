extends MenuScreen


func _set_color(color1 : Color, color2 : Color) -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Gradient, "texture:gradient:colors", PackedColorArray([Color(0,0,0,0), color1]), 1.0)
	tween.tween_property($Gradient3, "texture:gradient:colors", PackedColorArray([Color(0,0,0,0), color2, color2, Color(0,0,0,0)]), 1.0)
