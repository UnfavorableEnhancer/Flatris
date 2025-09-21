extends Control

class_name Foreground

const SCORE_GROW_SPEED : float = 0.75 ## Time in seconds before score should finish grow animation
const LINES_GROW_SPEED : float = 0.75 ## Time in seconds before lines should finish grow animation
const DAMAGE_GROW_SPEED : float = 0.5 ## Time in seconds before lines should finish grow animation

const PIECE_COLORS : Dictionary[int, Color] = {
	PieceQueue.PIECE_TYPE.O : Color("eee225"),
	PieceQueue.PIECE_TYPE.I : Color("04ffbe"),
	PieceQueue.PIECE_TYPE.T : Color("a73bea"),
	PieceQueue.PIECE_TYPE.S : Color("34e72e"),
	PieceQueue.PIECE_TYPE.Z : Color("e72e2e"),
	PieceQueue.PIECE_TYPE.L : Color("2554f4"),
	PieceQueue.PIECE_TYPE.J : Color("ff6804"),
	PieceQueue.PIECE_TYPE.BL : Color("763e07"),
	PieceQueue.PIECE_TYPE.BO : Color("c6c6c6"),
	PieceQueue.PIECE_TYPE.BU : Color("2fec63"),
	PieceQueue.PIECE_TYPE.CH : Color("f74393"),
}

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
var lines_goal : int = 0 ## Goal lines amount value
var damage : int = 0 ## Latest set damage value
var reversi : int = 0 ## Latest set reversi value

var is_reversi_disabled : bool = false
var is_damage_disabled : bool = false

var score_tween : Tween ## Tween used to animate score text grow
var lines_tween : Tween ## Tween used to animate lines text grow
var damage_tween : Tween ## Tween used to animate damage indicator grow
var reversi_tween : Tween ## Tween used to animate damage indicator grow

var score_add_loop_tween : Tween ## Tween used to animate score add
var score_add_tween : Tween ## Tween used to animate score add


func _ready() -> void:
	$ScoreAdd.scale.x = 0.0


func _disable_damage_bar() -> void:
	$Damage.modulate = Color("5e5e5e")
	is_damage_disabled = true


func _disable_reversi_bar() -> void:
	$Reversi.modulate.a = 0.0
	is_reversi_disabled = true


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
	lines_tween.tween_method(_set_lines, lines, number, SCORE_GROW_SPEED / 2.0)
	lines = number


## Sets lines text
func _set_lines(number : int) -> void:
	var text = "0000"
	var str_number = str(number)
	
	if lines_goal == 0:
		if str_number.length() > 4:
			$Lines/Num.text = str_number
		else:
			text = text.left(4 - str_number.length()) + str_number
			$Lines/Num.text = text
	else:
		if str_number.length() > 2:
			$Lines/Num.text = str_number + "/" + str(lines_goal)
		else:
			text = text.left(2 - str_number.length()) + str_number
			$Lines/Num.text = text + "/" + str(lines_goal)


## Sets time text
func _set_time(seconds : int) -> void:
	var hour : int = int(seconds / 3600.0)
	var hour_str : String = str(hour) + ":"
	if seconds < 3600 : hour_str = ""
	
	var minute : int = int(seconds / 60.0) - 60 * hour
	var minute_str : String = str(minute) + ":"
	if minute < 10 : minute_str = "0" + str(minute) + ":"

	var secs : int = seconds % 60
	var seconds_str : String = str(secs)
	if secs < 10 : seconds_str = "0" + str(secs)
	
	var time_str = str(hour_str + minute_str + seconds_str)
	$Time/Num.text = time_str


## Sets time text in milliseconds
func _set_time_in_milliseconds(milliseconds : int) -> void:
	var hour : int = int(milliseconds / 3600000.0)
	var hour_str : String = str(hour) + ":"
	if milliseconds < 3600000 : hour_str = ""
	
	var minute : int = int(milliseconds / 60000.0) - 60000 * hour
	var minute_str : String = str(minute) + ":"
	if minute < 10 : minute_str = "0" + str(minute) + ":"

	var secs : int = int(milliseconds / 1000.0) - 60 * minute
	var seconds_str : String = str(secs)
	if secs < 10 : seconds_str = "0" + str(secs)
	
	var millisecs : int = milliseconds % 1000
	var milliseconds_str : String = "." + str(millisecs)
	if millisecs < 100 : milliseconds_str = ".0" + str(millisecs)
	if millisecs < 10 : milliseconds_str = ".00" + str(millisecs)
	
	var time_str = str(hour_str + minute_str + seconds_str)
	$Time/Num.text = time_str
	$Time/Num2.text = milliseconds_str


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
		get_node("Next/Piece" + str(i + 1)).frame = queue_copy[i] + 1
		get_node("Next/Piece" + str(i + 1)).modulate = PIECE_COLORS[queue_copy[i]]


## Updates hold visuals
func _update_hold(piece_in_hold : int) -> void:
	if piece_in_hold == -1 : 
		$Hold/Piece.frame = 0
		return
	
	$Hold/Piece.frame = piece_in_hold + 1
	$Hold/Piece.modulate = PIECE_COLORS[piece_in_hold]


## Updates damage indicator
func _set_damage(number : int) -> void:
	if is_damage_disabled : return
	
	if is_instance_valid(damage_tween) : damage_tween.kill()
	
	if number > 20 : number = 20
	if number < 0 : number = 0
	
	$Damage/Bar.value = DAMAGE_VALUES[number]
	
	var flash_color : Color
	if damage < number: flash_color = Color.RED
	else: flash_color = Color.GREEN
	
	var damage_percent : float = number / 20.0
	var damage_color : Color = Color(1.0, 1.0 - damage_percent, clamp(1.0 - damage_percent,  0.352, 1.0))
	
	damage_tween = create_tween()
	damage_tween.tween_property($Damage/Bar, "tint_progress", flash_color, 0.1)
	damage_tween.tween_property($Damage/Bar, "tint_progress", Color.WHITE, 0.1)
	damage_tween.tween_property($Damage, "modulate", damage_color, 0.5)
	damage = number


## Updates reversi indicator
func _set_reversi(number : int) -> void:
	if is_reversi_disabled : return
	
	if is_instance_valid(reversi_tween) : reversi_tween.kill()
	
	if number > 20 : number = 20
	if number < 0 : number = 0
	
	$Reversi/Bar.value = DAMAGE_VALUES[number]
	
	var reversi_percent : float = number / 20.0
	var flash_color : Color = Color(clamp(1.0 - reversi_percent,  0.207, 1.0), 1.0, clamp(1.0 - reversi_percent,  0.591, 1.0))
	
	reversi_tween = create_tween()
	reversi_tween.tween_property($Reversi/Bar, "tint_progress", Color(0.207, 1.0, 0.591), 0.1)
	reversi_tween.tween_property($Reversi/Bar, "tint_progress", Color.WHITE, 0.1)
	reversi_tween.tween_property($Reversi, "modulate", flash_color, 0.5)
	damage = number


func _show_score_add(add_score : int, add_lines : int) -> void:
	if is_instance_valid(score_add_loop_tween) : score_add_loop_tween.kill()
	if is_instance_valid(score_add_tween) : score_add_tween.kill()
	
	score_add_loop_tween = create_tween().set_loops(50)
	score_add_tween = create_tween()
	
	var text : String = "OK"
	var flash_color : Color = Color.WHITE
	
	match add_lines:
		0:
			flash_color = Color.WHITE
			text = "OK"
		1:
			flash_color = Color.WHITE
			text = "Good"
		2:
			flash_color = Color(0.387, 0.918, 0.857, 1.0)
			text = "Nice"
		3:
			flash_color = Color(0.91, 0.889, 0.388, 1.0)
			text = "Great!"
		4:
			flash_color = Color(0.389, 0.922, 0.485, 1.0)
			text = "Awesome!"
		5:
			flash_color = Color(0.926, 0.228, 0.228, 1.0)
			text = "Amazing!"
		6:
			flash_color = Color(0.879, 0.124, 0.389, 1.0)
			text = "Wonderful!"
		7:
			flash_color = Color(0.18, 0.539, 1.0, 1.0)
			text = "Majestic!"
		8:
			flash_color = Color(0.557, 0.223, 1.0, 1.0)
			text = "Miraculous!"
		9:
			flash_color = Color(0.129, 1.0, 0.653, 1.0)
			text = "Excellent!!"
		451:
			flash_color = Color(1.0, 0.633, 0.0, 1.0)
			text = "ALL CLEAR!!"
		_:
			flash_color = Color(1.0, 0.109, 0.84, 1.0)
			text = "Impossible!!!"
	
	$ScoreAdd/Text.text = text
	if add_score == 0 : $ScoreAdd/Score.text = ""
	else : $ScoreAdd/Score.text = "+" + str(add_score)
	$ScoreAdd/Lines.text = "x" + str(add_lines)
	
	score_add_loop_tween.tween_property($ScoreAdd, "modulate", flash_color, 0.1)
	score_add_loop_tween.tween_property($ScoreAdd, "modulate", Color.WHITE, 0.1)
	
	score_add_tween.tween_property($ScoreAdd, "scale:x", 1.0, 0.25).from(0.0).set_trans(Tween.TRANS_CUBIC)
	score_add_tween.tween_interval(2.0)
	score_add_tween.tween_property($ScoreAdd, "scale:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
