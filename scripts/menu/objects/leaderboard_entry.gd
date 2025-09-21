extends ColorRect

var id : int = 0
var entry_name : String = "missing_no"
var score : int = 0 
var level : int = 0 
var lines : int = 0 
var time : int = 0 

var score_visible : bool = true
var level_visible : bool = true
var lines_visible : bool = true
var time_visible : bool = false


func _ready() -> void:
	if id == 0 : $H/Rank.text = "rec"
	else : $H/Rank.text = str(id)
	
	var thing_index : int = entry_name.rfind("_")
	if thing_index == -1 : 
		$H/Name.text = entry_name
		$H/ID.text = "??????"
	else:
		$H/Name.text = entry_name.left(thing_index)
		$H/ID.text = entry_name.right(6)
	
	$H/Score.text = _make_number_str_with_zeroes(score, "000000")
	$H/Score.visible = score_visible
	$H/Level.text = _make_number_str_with_zeroes(level, "00")
	$H/Level.visible = level_visible
	$H/Lines.text = _make_number_str_with_zeroes(lines, "0000")
	$H/Lines.visible = lines_visible
	$H/Time.text = _get_time_str_in_milliseconds(time)
	$H/Time.visible = time_visible


func _make_number_str_with_zeroes(number : int, zeroes : String = "000000") -> String:
	var str_number = str(number)
	
	if str_number.length() > zeroes.length():
		return str_number
	else:
		str_number = zeroes.left(zeroes.length() - str_number.length()) + str_number
		return str_number


func _get_time_str_in_milliseconds(milliseconds : int) -> String:
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
	
	return hour_str + minute_str + seconds_str + milliseconds_str
