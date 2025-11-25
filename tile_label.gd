extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(_on_text_changed)
	focus_entered.connect(_on_focus_entered)

func _on_text_changed(val: String) -> void:
	text = val.to_upper()
	caret_column = 0
	select_all()

func _on_focus_entered() -> void:
	caret_column = 0
	select_all()
