class_name Tile
extends AspectRatioContainer

var index := 0

var _selected := false
var _default_color := Color.html("ffe0caa9")
var _color_hover := Color.html("ffaecaa9")
var _color_focus := Color.html("ff499ce0")

signal letter_changed(idx: int, letter: String)
signal selected(tile: Tile)


func _enter_tree() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	$Label.text_changed.connect(_on_text_changed)

func deselect() -> void:
	$ColorRect.color = _default_color
	_selected = false

func clear() -> void:
	$Label.text = ""
	letter_changed.emit(index, "")

func set_letter(letter: String) -> void:
	$Label.text = letter[0]
	letter_changed.emit(letter[0])

func _on_mouse_entered() -> void:
	$ColorRect.color = _color_hover
	
func _on_mouse_exited() -> void:
	if _selected:
		return
	$ColorRect.color = _default_color

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		_selected = true
		selected.emit(self)
		$ColorRect.color = _color_focus
		$Label.grab_focus()
	elif event.is_action_pressed("rclick"):
		$Label.text = ""
		letter_changed.emit(index, "")


func _on_text_changed(text: String) -> void:
	letter_changed.emit(index, text)
