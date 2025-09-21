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
	$H/Rank.text = str(id)
	
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
	$H/Time.text = Main._to_time(time)
	$H/Time.visible = time_visible


func _make_number_str_with_zeroes(number : int, zeroes : String = "000000") -> String:
	var str_number = str(number)
	
	if str_number.length() > zeroes.length():
		return str_number
	else:
		str_number = zeroes.left(zeroes.length() - str_number.length()) + str_number
		return str_number
