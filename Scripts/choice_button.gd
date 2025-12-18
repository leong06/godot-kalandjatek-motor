extends PanelContainer

signal choice_btn_pressed(choice_index)

@export var choice_index: int = 1

@onready var choice_text: Label = $MarginContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	emit_signal("choice_btn_pressed", choice_index)

func set_text(new_text: String) -> void:
	choice_text.text = new_text
