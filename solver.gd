class_name Solver
extends Control

enum Mode { Setup, Solve, Playback }

var _nodes : Array
var _solve_steps : Array

signal mode_changed(SolverMode)

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
		$Grid.values.length() / $Grid.columns
	)
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
			item.letter = $Grid.values[i]
			if item.letter == start:
				start_positions.append(item.index)
			if x > 0:
				var neighbor = _nodes[i - 1]
				item.neighbors.append(neighbor)
				neighbor.append(self)
			if y > 0:
				var neighbor = _nodes[i - shape.x]
				item.neighbors.append(neighbor)
				neighbor.append(self)
			if x > 0 and y > 0:
				var neighbor = _nodes[i - shape.x - 1]
				item.neighbors.append(neighbor)
				neighbor.append(self)
				if x < shape.x - 1:
					neighbor = _nodes[i - shape.x + 1]
					item.neighbors.append(neighbor)
					neighbor.append(self)
			_nodes.append(item)
			i += 1
	_solve_steps = [_nodes]
	
	# create a tree that lets you get the preceeding letter(s) legal for this letter
	var letter_tree = {}
	for j in range(1, %WordEdit.text.length()):
		var letter = %WordEdit.text[j]
		var prev = %WordEdit.text[j - 1]
		if letter_tree.has(letter):
			letter_tree[letter].append(prev)
		else:
			letter_tree[letter] = [prev]

	for pos_idx in start_positions:
		var path = [pos_idx]
		for node in _nodes:
			node.left = null
			node.right = null
			node.letter_left = ""
			node.letter_right = ""
			node.is_start = false
			node.is_end = false
			if node.index == pos_idx:
				node.letter_left = node.letter
				node.left = self
				node.is_start = true

		while _nodes.size() > 1:
			var current_nodes = _solve_steps[_solve_steps.size() - 1]
			# check current state for rollback needs and/or clear nodes
			for node in current_nodes:
				if node.left != null and node.right != null:
					if node.letter == "":
						pass
					if letter_tree[node.letter].has(node.letter_left):
						current_nodes.remove(node)
				
			_solve_steps.append(_nodes)
