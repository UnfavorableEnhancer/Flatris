extends MenuScreen


func _on_timer_timeout() -> void:
	$Time.text = Time.get_time_string_from_system()


func _show_button_layout(layout : int) -> void:
	pass
