extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(_on_text_changed)

func _on_text_changed(val: String) -> void:
	text = val.to_upper()
	caret_column = text.length()
