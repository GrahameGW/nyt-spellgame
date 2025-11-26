class_name Strand

var tiles := []
var start_letter := ""
var end_letter := ""
var can_join := []

func has(tile: int) -> bool:
	return tiles.has(tile)

func start() -> int:
	return -1 if tiles.size() == 0 else tiles[0]

func end() -> int:
	return -1 if tiles.size() == 0 else tiles[-1]

# returns start and end of the strands relative to self (start, end)
# so joining a strand [5...1] to [2...8] will return (5, 8), not (8, 5)
func join_strand_ends(strand: Strand) -> Vector2i:
	var reversed = tiles.duplicate()
	reversed.reverse()
	self.tiles.append(strand.tiles)
	strand.tiles.reverse()
	strand.tiles.append(reversed)
	strand.tiles.reverse()
	self.end_letter = strand.start_letter
	strand.end_letter = self.start_letter
	return Vector2i(tiles[0], tiles[-1])

# join start of other strand to the end of this strand
func concat_strand(strand: Strand) -> Strand:
	self.tiles.append(strand.tiles)
	self.end_letter = strand.end_letter if strand.end_letter != "" else end_letter
	return self

static func from(node: NodeData) -> Strand:
	var strand = Strand.new()
	strand.tiles = [node.index]
	strand.start_letter = node.letter
	strand.end_letter = node.letter
	strand.can_join = node.can_join
	return strand
