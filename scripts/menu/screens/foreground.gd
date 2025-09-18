extends MenuScreen


func _on_timer_timeout() -> void:
	$Time.text = Time.get_time_string_from_system()
