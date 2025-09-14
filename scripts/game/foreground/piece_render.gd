extends CenterContainer

const CELL_3X3 : int = 8 ## Cell size if piece is 4x4
const CELL_4X4 : int = 6 ## Cell size if piece is 3x3

@onready var grid : GridContainer = $Grid


## Draws given piece type
func _render_piece(piece_type : int) -> void:
	for i in grid.get_children() : i.free()
	
	var piece : Dictionary = PieceQueue.PIECES[piece_type]
	var piece_size : int = piece["size"]
	
	grid.columns = piece_size
	
	for y : int in size:
		for x : int in size:
			var color_rect : ColorRect = ColorRect.new()
			
			if piece_size == 4 : color_rect.custom_minimum_size = Vector2(CELL_4X4, CELL_4X4)
			else : color_rect.custom_minimum_size = Vector2(CELL_3X3, CELL_3X3)
			
			color_rect.color = Block.COLOR_VALUES[piece["color"]]
			if not piece["positions"].has(Vector2i(x,y)): color_rect.color.a = 0.0
				
			grid.add_child(color_rect)
