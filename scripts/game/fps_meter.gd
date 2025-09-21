extends Control


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		if visible : visible = false
		else : visible = true


func _process(_delta: float) -> void:
	if visible:
		$Text.text = str(Engine.get_frames_per_second())
