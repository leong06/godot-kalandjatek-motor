extends Control

var stats = {"hp": 100, "mana": 100, "str": 0}

@onready var health_label: Label = %"Health_Label"
@onready var eletero_label: Label = $Sidebar/Panel/MarginContainer/VBoxContainer/HBoxContainer/Skill_2/CenterContainer/Eletero_Label
@onready var szerencse_label: Label = $Sidebar/Panel/MarginContainer/VBoxContainer/HBoxContainer/Skill_3/CenterContainer/Szerencse_Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	ugyesseg_label.text = str(stats["hp"])
#	eletero_label.text = str(stats["mana"])
#	szerencse_label.text = str(stats["str"])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
