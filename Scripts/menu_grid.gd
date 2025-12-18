extends Control

@onready var grid_container: GridContainer = %GridContainer
@onready var play_button: Button = %PlayButton
@onready var module_loader: Node = %ModuleLoader
@onready var select_button: Button = $SelectButton
@onready var quit_button: Button = $Quit_Button
@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer
@onready var load_module_button: Button = $Load_Module_Button
@onready var editor_button: Button = $Editor_Button


var selected_module: String = ""
var module_buttons: Array = []

func _ready() -> void:
	if not module_loader:
		push_error("ModuleLoader node not found! Please add a ModuleLoader node with module_loader.gd script to the MainMenu scene.")
		return
	if not grid_container:
		push_error("GridContainer node not found! Ensure %GridContainer is set in the scene.")
		return
	print("GridContainer visible: ", grid_container.visible)
	print("GridContainer size: ", grid_container.size)
	grid_container.columns = 3 
	load_modules()
	play_button.disabled = true
	initial_buttons()
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))

func load_modules() -> void:
	var modules = module_loader.get_available_modules()
	print("Modules found: " + str(modules))
	if modules.is_empty():
		print("No modules found in user://modules/")
	for module in modules:
		var button = Button.new()
		button.text = module["title"]
		button.custom_minimum_size = Vector2(150, 100) 
		if module["preview_image"] and FileAccess.file_exists(module["preview_image"]):
			var texture = load(module["preview_image"])
			var texture_rect = TextureRect.new()
			texture_rect.texture = texture
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.custom_minimum_size = Vector2(100, 100)
			button.add_child(texture_rect)
		else:
			print("No valid preview image for module: " + module["title"])
		button.connect("pressed", Callable(self, "_on_module_selected").bind(module["file_name"]))
		grid_container.add_child(button)
		module_buttons.append(button)
		print("Added module button: " + module["title"] + " (Visible: " + str(button.visible) + ", Size: " + str(button.size) + ")")

func _on_module_selected(module_file: String) -> void:
	selected_module = module_file
	play_button.disabled = false
	play_button.visible = true
	for button in module_buttons:
		button.disabled = false
		button.modulate = Color(1, 1, 1)
	var pressed_button = module_buttons[grid_container.get_children().find(grid_container.get_child(grid_container.get_child_count() - 1))]
	pressed_button.disabled = true
	pressed_button.modulate = Color(0.7, 0.7, 0.7)

func _on_play_pressed() -> void:
	if selected_module:
		var story_path = module_loader.load_module(selected_module)
		if story_path:
			ContentData.dialogPath = story_path
			get_tree().change_scene_to_file("res://Scenes/ui_scene.tscn") 
		else:
			print("Failed to load module: " + selected_module)

func initial_buttons() -> void:
	select_button.visible = true
	quit_button.visible = true
	editor_button.visible = true
	play_button.visible = false
	load_module_button.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_select_button_pressed() -> void:
	scroll_container.visible = true
	select_button.visible = false
	quit_button.visible = false
	load_module_button.visible = true
	editor_button.visible = false
	

func _on_options_button_pressed() -> void:
	select_button.visible = false
	quit_button.visible = false
	load_module_button.visible = false
	editor_button.visible = false



func _on_load_module_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/module_loader.tscn") 


func _on_editor_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/editor_scene.tscn") 
