class_name Logic

var state_log := []

func solve(nodes: Array, start_positions: Array) -> bool:
	var cached = nodes.duplicate()
	
	for start in start_positions:
		nodes = reset_nodes(cached)
		var strands = { }
		var path = []
		
		# initialize strands and path Strands are defined by their 
		# end, not their start (but there's a func to grab that)
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
					
	return true
		
func log_state(strands, path) -> void:
	state_log.append({
		"strands": strands,
		"path": path
	})

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
