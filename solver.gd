class_name Solver
extends Control

enum Mode { Setup, Solve, Playback }

var _nodes : Array
var _solve_steps : Array

signal mode_changed(mode: Solver.Mode)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mode_changed.emit.call_deferred(Mode.Setup)
	%SubmitButton.pressed.connect(_on_submit_pressed)
	%ClearButton.pressed.connect(_on_clear_pressed)

func _on_submit_pressed() -> void:
	print("Word is: " + %WordEdit.text)
	var grid_string := ""
	for item in $Grid.values:
		grid_string += item
	print("Array is: " + grid_string)
	solve()

func _on_clear_pressed() -> void:
	%WordEdit.clear()

	
func solve() -> void:
	var shape = Vector2i(
		$Grid.columns,
		$Grid.values.size() / $Grid.columns
	)

	# create a tree that lets you get the preceeding letter(s) legal for this letter
	var letter_tree = {}
	for j in range(0, %WordEdit.text.length()):
		var letter = %WordEdit.text[j].to_upper()
		var next = null if j == %WordEdit.text.length() - 1 else %WordEdit.text[j + 1].to_upper()
		var prev = null if j == 0 else %WordEdit.text[j - 1].to_upper()
		if letter_tree.has(letter):
			if next != null:
				letter_tree[letter]["next"].append(next)
			if prev != null:
				letter_tree[letter]["prev"].append(prev)
		else:
			letter_tree[letter] = { 
				"next": [] if next == null else [next],
				"prev": [] if prev == null else [prev]
			}
	# build up solver map
	_nodes = []
	var start = %WordEdit.text[0]
	var start_positions = []
	var end = %WordEdit.text[%WordEdit.text.length() - 1]
	var i = 0
	for y in range(0, shape.y):
		for x in range(0, shape.x):
			var item = NodeData.new()
			item.coords = Vector2i(x, y)
			item.index = i
			item.letter = $Grid.values[i].to_upper()
			item.can_join = %WordEdit.text.to_array() if item.letter == "" else letter_tree[item.letter]["next"]
			item.can_join.append("")
			if item.letter == start:
				start_positions.append(item.index)
			if x > 0:
				var neighbor = _nodes[i - 1]
				item.neighbors.append(neighbor)
				neighbor.neighbors.append(self)
			if y > 0:
				var neighbor = _nodes[i - shape.x]
				item.neighbors.append(neighbor)
				neighbor.neighbors.append(self)
			if x > 0 and y > 0:
				var neighbor = _nodes[i - shape.x - 1]
				item.neighbors.append(neighbor)
				neighbor.neighbors.append(self)
				if x < shape.x - 1:
					neighbor = _nodes[i - shape.x + 1]
					item.neighbors.append(neighbor)
					neighbor.neighbors.append(self)
			_nodes.append(item)
			i += 1
	_solve_steps = [_nodes]
	

	
	var logic = Logic.new()
	logic.solve(_nodes, start_positions)
