class_name Logic

var state_log := []
var result : PackedInt32Array

enum Path { 
	START = 1, 
	END = 2,
	VERTICAL = 4,
	HORIZONTAL = 8,
	NORTH_EAST = 16,
	SOUTH_EAST = 32,
	SOUTH_WEST = 64,
	NORTH_WEST = 128
	}

func superimpose() -> Path:
	return Path.VERTICAL | Path.HORIZONTAL | Path.NORTH_EAST | Path.SOUTH_EAST | Path.NORTH_WEST | Path.SOUTH_WEST

func solve(nodes: Array, word: String) -> bool:
	# cache nodes and build up strand dictionary
	var strands = {}
	var start_positions = []
	var end_positions = []
	for node in nodes:
		strands[node.index] = Strand.from(node)
		if node.letter == word[0]:
			start_positions.append(node.index)
		if node.letter == word[-1]:
			end_positions.append(node.index)
	
	for start in start_positions:
		for end in end_positions:
			var cur_nodes = nodes.duplicate(true)
			var tiles = []
			tiles.resize(cur_nodes.size())
			for tile in tiles:
				tile = superimpose()
			tiles[start] = Path.START
			tiles[end] = Path.END
			# don't need to process start or end, remove them in whatever order
			# doesn't mess up the array indicies
			if start > end:
				cur_nodes.remove_at(end)
				cur_nodes.remove_at(start)
			else:
				cur_nodes.remove_at(start)
				cur_nodes.remove_at(end)
			var res = collapse(nodes, tiles, Vector2i(start, end), word)
			if is_valid_result(word, res, nodes):
				return true

	return false


func collapse(nodes: Array, tiles: Array, start_end: Vector2i, word: String) -> PackedInt32Array:
	var strand_starts = { start_end.x: word[0] }
	var strand_ends = { start_end.y: word[-1] }
	for node in nodes.filter(func(x): return x.letter != ""):
		if !strand_starts.has(node.index):
			strand_starts[node.index] = node.letter
		if !strand_ends.has(node.index):
			strand_ends[node.index] = node.letter

	var did_update = true
	while did_update:
		did_update = false
		for i in range(nodes.size() - 1, -1, -1):
			var n = nodes[i]
			var tile = tiles[n.index]
			var original = tile
			# collapse if nothing available in a direction
			if !n.neighbors.any(func (x): return x.coords.x == n.coords.x + 1):
				tile = remove_east(tile)
			if !n.neighbors.any(func (x): return x.coords.x == n.coords.x - 1):
				tile = remove_west(tile)
			if !n.neighbors.any(func (x): return x.coords.y < n.coords.y && x.neighbors.has(n)):
				tile = remove_north(tile)
			if !n.neighbors.any(func (x): return x.coords.y > n.coords.y && x.neighbors.has(n)):
				tile = remove_south(tile)
			
			# see if nearby strands block joining
			if strand_ends.has(n.index):
				for adj in n.neighbors:
					if strand_starts.has(adj.index):
						var str = strand_ends[n.index] + strand_starts[adj.index]
						if !word.contains(str):
							remove_dir(adj.coords - n.coords, tile)
			if strand_starts.has(n.index):
				for adj in n.neighbors:
					if strand_ends.has(adj.index):
						var str = strand_ends[adj.index] + strand_starts[n.index]
						if !word.contains(str):
							remove_dir(adj.coords - n.coords, tile)
			did_update = original != tile
			var log_tile = log_base_2(tile)
			if is_equal_approx(log_tile, int(log_tile)): 
				add_to_strands(n, tile, strand_starts, strand_ends)
				node_finished(n)
				nodes.remove_at(i)
	return []

func has_two_neighbors(node: NodeData) -> Path:
	# order neighbors by index
	node.neighbors.sort_custom(func (x, y): return x.index < y.index)
	var a = node.neighbors[0]
	var b = node.neighbors[1]
	if a.coords.X == b.coords.X:
		return Path.VERTICAL
	if a.coords.Y == b.coors.Y:
		return Path.HORIZONTAL
	# go clockwise checking for the x because it's easier
	if b.index == node.index + 1:
		return Path.NORTH_EAST
	if a.index == node.index + 1:
		return Path.SOUTH_EAST
	if a.index == node.index - 1:
		return Path.SOUTH_WEST
	else:
		return Path.NORTH_WEST

func remove_east(tile: Path) -> Path:
	return tile & ~(Path.NORTH_EAST | Path.SOUTH_EAST | Path.HORIZONTAL)
	
func remove_west(tile: Path) -> Path:
	return tile & ~(Path.NORTH_WEST | Path.SOUTH_WEST | Path.HORIZONTAL)

func remove_north(tile: Path) -> Path:
	return tile & ~(Path.NORTH_EAST | Path.NORTH_WEST | Path.VERTICAL)

func remove_south(tile: Path) -> Path:
	return tile & ~(Path.SOUTH_EAST | Path.SOUTH_WEST | Path.VERTICAL)

func remove_dir(dir: Vector2i, tile: Path) -> Path:
	if dir.x == 1: return remove_east(tile)
	if dir.x == -1: return remove_west(tile)
	if dir.y == 1: return remove_south(tile)
	else: return remove_north(tile)


func node_finished(node: NodeData) -> void:
	for adj in node.neighbors:
		var idx = adj.neighbors.find(node)
		adj.neighbors.remove_at(idx)

func add_to_strands(node: NodeData, tile: Path, starts: Dictionary, ends: Dictionary) -> void:
	if tile & (Path.NORTH_EAST | Path.NORTH_WEST | Path.VERTICAL) > 0:
		var start = starts[node.neighbors.find(func(x): return x.coord.y == node.coord.y - 1)]

func solve_from_start(start: int, nodes: Array, strands: Dictionary) -> PackedInt32Array:
	var cur_nodes = nodes.duplicate(true)
	var cur_strands = strands.duplicate(true)
	var res = solve_from_start(start, cur_nodes, cur_strands)

	var path : PackedInt32Array = [start]
	strands[start]["is_start"] = true

	for node in nodes:
		strands[node.index] = Strand.from(node)
		if node.index == start:
			mark_joined(node)
			path.append(node.index)
			nodes.remove_at(node.index)
	log_state(strands, path)
	
	# initialize branch logic
	var start_log_idx = state_log.size()
	var last_branch = state_log.size()
	var branch_decision = null
	
	# Order of operations:
	# Loop doing forced steps. If no forced steps available, make decision
	# log it for rollback, then proceed. If impossible situation arises, rollback
	# to state and then make a different decision. If we get forced back to state 0
	# pick a different start. If no starts available, return "impossible!"
	var did_forced = true
	while did_forced:
		did_forced = false
		# loop through nodes backwards and remove ones that get added to strands
		for i in range(nodes.size() - 1, -1, -1):
			if nodes[i].neighbors.size() == 1:
				var strand = strands
				did_forced = true
				var end = strands[nodes[i].index].end_letter
				mark_joined(nodes[i])
				nodes.remove_at(i)
					
	return []

func log_base_2(x: int) -> float:
	return log(x) / log(2)

func log_state(strands, path) -> void:
	state_log.append({
		"strands": strands,
		"path": path
	})

func is_valid_result(word: String, res: PackedInt32Array, nodes: Array) -> bool:
	if res.size() != nodes.size() or nodes[res[0]] == "" or nodes[res[-1]] == "":
		return false
	var str = ""
	for i in res:
		var letter = nodes[i].letter
		if letter != "":
			str.concat(letter)
	return word == str


# Mark node as embedded into strand so we can't connect it anymore
func mark_joined(node: NodeData) -> void:
	node.is_done = true
	node.can_join = []
	for neighbor in node.neighbors:
		var idx = neighbor.neighbors.find(node)
		if idx != -1:
			neighbor.neighbors.remove(idx)
		
func reset_nodes(nodes: Array) -> Array:
	for node in nodes:
		node.is_done = false
	return nodes
