extends MenuScreen

##-----------------------------------------------------------------------
## Starts on boot and shows several disclaimers. 
## If programm is booted for the first time ever cannot be skipped.
##-----------------------------------------------------------------------

signal finish


func _ready() -> void:
	await get_tree().create_timer(8.0).timeout
	finish.emit()


func _input(event : InputEvent) -> void:
	if Player.config["first_boot"] : return
	
	# When we press "start" button, disclaimer is skipped and next screen loads
	if event.is_action_pressed("ui_accept"): 
		finish.emit()
	
	if event is InputEventMouseButton and event.pressed:
		finish.emit()
