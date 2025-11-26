class_name Strand

var tiles := []
var text := ""
var is_start := false
var is_end := false

func has(tile: int) -> bool:
	return tiles.has(tile)

func start() -> Dictionary:
	var idx = -1 if tiles.size() == 0 else tiles[0]
	return { "index": idx, "letter": text[0] }

func end() -> Dictionary:
	var idx = -1 if tiles.size() == 0 else tiles[-1]
	return { "index": idx, "letter": text[-1] }


static func from(node: NodeData) -> Strand:
	var strand = Strand.new()
	strand.tiles = [node.index]
	strand.text = node.letter
	return strand
