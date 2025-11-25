class_name Grid
extends GridContainer


var _selected_tile : Tile
var values : Array

func _ready() -> void:
	values = []
	for i in range(0, get_child_count()):
		var tile : Tile = get_child(i)
		tile.index = i
		tile.selected.connect(_on_tile_selected)
		tile.letter_changed.connect(_on_letter_changed)
		values.append("")
	get_parent().mode_changed.connect(_on_mode_changed)

func _on_mode_changed(mode: Solver.Mode) -> void:
	clear()

func _on_tile_selected(tile: Tile) -> void:
	if _selected_tile != null:
		_selected_tile.deselect()
	_selected_tile = tile

func _on_letter_changed(idx: int, letter: String) -> void:
	values[idx] = letter

func clear() -> void:
	_selected_tile = null
	for tile in get_children():
		tile.clear()
		tile.deselect()
