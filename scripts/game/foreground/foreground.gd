extends Control

class_name Foreground

const SCORE_GROW_SPEED : float = 0.75 ## Time in seconds before score should finish grow animation
const LINES_GROW_SPEED : float = 0.75 ## Time in seconds before lines should finish grow animation
const DAMAGE_GROW_SPEED : float = 0.5 ## Time in seconds before lines should finish grow animation

## Dictionary of all damage indicator values corresponing to given damage
const DAMAGE_VALUES : Dictionary[int, float] = {
	0 : 0.0,
	1 : 1.25,
	2 : 2.25,
	3 : 3.25,
	4 : 4.15,
	5 : 5.15,
	6 : 6.1,
	7 : 7.1,
	8 : 8.1,
	9 : 9.0,
	10 : 9.9,
	11 : 10.9,
	12 : 11.9,
	13 : 12.8,
	14 : 13.8,
	15 : 14.8,
	16 : 15.8,
	17 : 16.7,
	18 : 17.7,
	19 : 18.7,
	20 : 19.5,
}

var score : int = 0 ## Latest set score value
var lines : int = 0 ## Latest set lines value
var damage : int = 0 ## Latest set damage value

var score_tween : Tween ## Tween used to animate score text grow
var lines_tween : Tween ## Tween used to animate lines text grow
var damage_tween : Tween ## Tween used to animate damage indicator grow


## Sets score with grow animation
func _set_score_animated(number : int) -> void:
	if number > 999999 : $Score/Num.label_settings.font_size = 16
	elif number > 9999999 : $Score/Num.label_settings.font_size = 14
	elif number > 99999999 : $Score/Num.label_settings.font_size = 12
	elif number > 999999999 : 
		number = 999999999
		$Score/Num.text = "999999999"
		return
	
	if is_instance_valid(score_tween) : score_tween.kill()
	score_tween = create_tween()
	score_tween.tween_method(_set_score, score, number, SCORE_GROW_SPEED).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	score = number


## Sets score text
func _set_score(number : int) -> void:
	var text = "000000"
	var str_number = str(number)
	
	if str_number.length() > 6:
		$Score/Num.text = str_number
	else:
		text = text.left(6 - str_number.length()) + str_number
		$Score/Num.text = text


## Sets lines with grow animation
func _set_lines_animated(number : int) -> void:
	if is_instance_valid(lines_tween) : lines_tween.kill()
	lines_tween = create_tween()
	lines_tween.tween_method(_set_lines, lines, number, SCORE_GROW_SPEED).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	lines = number


## Sets lines text
func _set_lines(number : int) -> void:
	var text = "0000"
	var str_number = str(number)
	
	if str_number.length() > 4:
		$Lines/Num.text = str_number
	else:
		text = text.left(4 - str_number.length()) + str_number
		$Lines/Num.text = text


## Sets time text
func _set_time(seconds : int) -> void:
	var hour : int = int(seconds / 3600.0)
	var hour_str : String = str(hour) + ":"
	if seconds < 3600 : hour_str = ""
	
	var minute : String = str(int(seconds / 60.0) - 60 * hour) + ":"
	if int(seconds / 60.0 - 60 * hour) < 10 : minute = "0" + str(int(seconds / 60.0) - 60 * hour) + ":"

	var secs : String = str(seconds % 60)
	if seconds % 60 < 10 : secs = "0" + str(seconds % 60)
	
	var time_str = str(hour_str + minute + secs)
	$Time/Num.text = time_str


## Sets level text
func _set_level(number : int) -> void:
	var text = "00"
	var str_number = str(number)
	
	if str_number.length() > 2:
		$Level/Num.text = str_number
	else:
		text = text.left(2 - str_number.length()) + str_number
		$Level/Num.text = text


## Updates queue visuals
func _update_queue(queue : Array[int]) -> void:
	var queue_copy : Array[int] = queue.duplicate()
	queue_copy.reverse()
	for i : int in queue_copy.size():
		if i >= 4 : return
		get_node("Next/PieceRender" + str(i + 1))._render_piece(queue_copy[i])


## Updates hold visuals
func _update_hold(piece_in_hold : int) -> void:
	$Hold/PieceRender._render_piece(piece_in_hold)


## Updates damage indicator
func _set_damage(number : int) -> void:
	if is_instance_valid(damage_tween) : damage_tween.kill()
	damage_tween = create_tween()
	damage_tween.tween_property($Damage/Bar, "value", DAMAGE_VALUES[number], DAMAGE_GROW_SPEED).from(DAMAGE_VALUES[damage]).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	damage = number
