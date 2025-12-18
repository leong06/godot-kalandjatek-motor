extends Control

@onready var key_edit: LineEdit = %"Key_Edit"
@onready var title_edit: LineEdit = %"Title_Edit"
@onready var main_text_edit: TextEdit = %"Main_Text_Edit"
@onready var save_button: Button =%"Editor_Save_Button"
@onready var debug_text: Label = $PanelContainer/Panel/MarginContainer/Content_Area/HBoxContainer/Debug_Text
@onready var option_button: OptionButton = %"Choice_Option_Button"
@onready var choice_1: MarginContainer = %"Choice_1"
@onready var choice_2: MarginContainer = %"Choice_2"
@onready var choice_3: MarginContainer = %"Choice_3"
@onready var new_scene: Button = %"New_Scene"
@onready var scene_list_container: VBoxContainer = %"SceneList_Container"
@onready var scene_list: ItemList = %"SceneList"
@onready var export_module_button: Button = %"ExportModuleButton"
@onready var export_dialog: AcceptDialog = %"ExportDialog"
@onready var module_title_edit: LineEdit = %"ModuleTitleEdit"
@onready var module_description_edit: TextEdit = %"ModuleDescriptionEdit"

# NEW: Project management UI nodes (you'll need to add these to your scene)
@onready var project_menu_button: MenuButton = %"Project_Menu_Button" # Add this button to your UI
@onready var save_project_dialog: FileDialog # Add this dialog to your scene
@onready var load_project_dialog: FileDialog # Add this dialog to your scene
@onready var new_project_dialog: ConfirmationDialog # Add this dialog to your scene
@onready var project_name_edit: LineEdit # Add this to new_project_dialog

var choice_data = []
var current_editing_key = ""
var story_data = {}
var scene_order = [] # Tracks order of scene creation
var id = 0

# Project management variables
var current_project_path: String = ""
var current_project_name: String = "Untitled Project"
var is_project_modified: bool = false

func _ready() -> void:
	export_module_button.connect("pressed", Callable(self, "_on_export_module_pressed"))
	export_dialog.connect("confirmed", Callable(self, "_on_export_dialog_confirmed"))
	save_button.connect("pressed", Callable(self, "_on_save_button_pressed"))
	new_scene.connect("pressed", Callable(self, "_on_new_scene_pressed"))
	option_button.connect("item_selected", Callable(self, "_on_option_button_item_selected"))
	scene_list.connect("item_selected", Callable(self, "_on_scene_list_item_selected"))
	
	# NEW: Setup project management
	_setup_project_management()
	
	# NEW: Auto-save timer (optional - saves every 5 minutes)
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 300.0 # 5 minutes
	auto_save_timer.timeout.connect(_on_auto_save)
	add_child(auto_save_timer)
	auto_save_timer.start()

# NEW: Setup project management UI and connections
func _setup_project_management() -> void:
	# Create project menu if it doesn't exist
	if not project_menu_button:
		project_menu_button = MenuButton.new()
		project_menu_button.text = "Project"
		# Add to your UI hierarchy where appropriate
	
	var popup = project_menu_button.get_popup()
	popup.clear()
	popup.add_item("New Project", 0)
	popup.add_item("Open Project", 1)
	popup.add_item("Save Project", 2)
	popup.add_item("Save Project As...", 3)
	popup.add_separator()
	popup.add_item("Recent Projects", 4)
	
	popup.id_pressed.connect(_on_project_menu_id_pressed)
	
	# Setup file dialogs
	if not save_project_dialog:
		save_project_dialog = FileDialog.new()
		save_project_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		save_project_dialog.access = FileDialog.ACCESS_USERDATA
		save_project_dialog.add_filter("*.advproj", "Adventure Project Files")
		save_project_dialog.file_selected.connect(_on_save_project_file_selected)
		add_child(save_project_dialog)
	
	if not load_project_dialog:
		load_project_dialog = FileDialog.new()
		load_project_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		load_project_dialog.access = FileDialog.ACCESS_USERDATA
		load_project_dialog.add_filter("*.advproj", "Adventure Project Files")
		load_project_dialog.file_selected.connect(_on_load_project_file_selected)
		add_child(load_project_dialog)
	
	if not new_project_dialog:
		new_project_dialog = ConfirmationDialog.new()
		new_project_dialog.title = "New Project"
		new_project_dialog.dialog_text = "Create a new project? Unsaved changes will be lost."
		new_project_dialog.confirmed.connect(_on_new_project_confirmed)
		add_child(new_project_dialog)
		
		# Add project name input to dialog
		project_name_edit = LineEdit.new()
		project_name_edit.placeholder_text = "Enter project name..."
		new_project_dialog.add_child(project_name_edit)

# NEW: Handle project menu selections
func _on_project_menu_id_pressed(id: int) -> void:
	match id:
		0: # New Project
			if is_project_modified:
				new_project_dialog.popup_centered()
			else:
				_create_new_project()
		1: # Open Project
			load_project_dialog.popup_centered()
		2: # Save Project
			_save_current_project()
		3: # Save Project As
			save_project_dialog.popup_centered()
		4: # Recent Projects
			_show_recent_projects()

# NEW: Create a new empty project
func _create_new_project() -> void:
	story_data.clear()
	scene_order.clear()
	current_project_path = ""
	current_project_name = project_name_edit.text if project_name_edit.text.strip_edges() != "" else "Untitled Project"
	is_project_modified = false
	
	# Clear UI
	key_edit.text = ""
	title_edit.text = ""
	main_text_edit.text = ""
	current_editing_key = ""
	
	_update_scene_list()
	debug_text.text = "New project created: " + current_project_name

func _on_new_project_confirmed() -> void:
	_create_new_project()

# NEW: Save the current project
func _save_current_project() -> void:
	if current_project_path.is_empty():
		save_project_dialog.popup_centered()
	else:
		_save_project_to_file(current_project_path)

# NEW: Save project to a specific file
func _save_project_to_file(path: String) -> void:
	var project_data = {
		"version": "1.0",
		"project_name": current_project_name,
		"story_data": story_data,
		"scene_order": scene_order,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(project_data, "\t"))
		file.close()
		current_project_path = path
		is_project_modified = false
		debug_text.text = "Project saved: " + path.get_file()
		_add_to_recent_projects(path)
	else:
		debug_text.text = "Failed to save project!"

# NEW: Load project from a file
func _load_project_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		debug_text.text = "Project file not found!"
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		debug_text.text = "Failed to open project file!"
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		debug_text.text = "Failed to parse project file!"
		return
	
	var project_data = json.get_data()
	
	# Load project data
	current_project_name = project_data.get("project_name", "Untitled Project")
	story_data = project_data.get("story_data", {})
	scene_order = project_data.get("scene_order", [])
	current_project_path = path
	is_project_modified = false
	
	# Clear current scene editing
	key_edit.text = ""
	title_edit.text = ""
	main_text_edit.text = ""
	current_editing_key = ""
	
	_update_scene_list()
	debug_text.text = "Project loaded: " + current_project_name + " (" + str(story_data.size()) + " scenes)"
	_add_to_recent_projects(path)

# NEW: File dialog callbacks
func _on_save_project_file_selected(path: String) -> void:
	# Ensure .advproj extension
	if not path.ends_with(".advproj"):
		path += ".advproj"
	_save_project_to_file(path)

func _on_load_project_file_selected(path: String) -> void:
	_load_project_from_file(path)

# NEW: Recent projects management
func _add_to_recent_projects(path: String) -> void:
	var recent_projects = _load_recent_projects()
	
	# Remove if already exists (to move it to top)
	recent_projects.erase(path)
	
	# Add to beginning
	recent_projects.insert(0, path)
	
	# Keep only last 10
	if recent_projects.size() > 10:
		recent_projects.resize(10)
	
	# Save recent projects list
	var file = FileAccess.open("user://recent_projects.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(recent_projects, "\t"))
		file.close()

func _load_recent_projects() -> Array:
	if not FileAccess.file_exists("user://recent_projects.json"):
		return []
	
	var file = FileAccess.open("user://recent_projects.json", FileAccess.READ)
	if not file:
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return []
	
	return json.get_data()

func _show_recent_projects() -> void:
	var recent_projects = _load_recent_projects()
	
	if recent_projects.is_empty():
		debug_text.text = "No recent projects found"
		return
	
	# Create a popup menu for recent projects
	var popup = PopupMenu.new()
	popup.name = "RecentProjectsPopup"
	add_child(popup)
	
	for i in range(recent_projects.size()):
		var path = recent_projects[i]
		if FileAccess.file_exists(path):
			popup.add_item(path.get_file().get_basename(), i)
	
	popup.id_pressed.connect(func(id): 
		_load_project_from_file(recent_projects[id])
		popup.queue_free()
	)
	
	popup.popup_centered()

# NEW: Auto-save functionality
func _on_auto_save() -> void:
	if is_project_modified and not current_project_path.is_empty():
		_save_project_to_file(current_project_path)
		print("Auto-saved project")

# NEW: Mark project as modified
func _mark_project_modified() -> void:
	is_project_modified = true

# MODIFIED: Update existing save method to mark project as modified
func _save_story_data() -> void:
	var ordered_story_data = {}
	for key in scene_order:
		if story_data.has(key):
			ordered_story_data[key] = story_data[key]
	
	var file = FileAccess.open("res://user/story_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(ordered_story_data, "\t"))
	file.close()
	debug_text.text = "File saved successfully!"
	
	_mark_project_modified() # NEW

func _load_story_data() -> void:
	if FileAccess.file_exists("res://user/story_data.json"):
		var file = FileAccess.open("res://user/story_data.json", FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		if json_string.length() > 0:
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				story_data = json.get_data()
				scene_order = story_data.keys()
				debug_text.text = "Loaded " + str(story_data.size()) + " scenes"
			else:
				debug_text.text = "Error during parsing!"
		else:
			story_data = {}
			scene_order = []
			debug_text.text = "No existing story data found!"

func _update_scene_list() -> void:
	scene_list.clear()
	for key in scene_order:
		if story_data.has(key):
			scene_list.add_item(key)

func _gather_choices_data() -> Dictionary:
	var choices = {}
	var num_choices = option_button.get_selected_id() + 1
	
	for i in range(1, 4):
		var choice_path = "PanelContainer/Panel/MarginContainer/Content_Area/MainContentArea/Choice_Container/ScrollContainer/Choice_Inputs/Choice_" + str(i)
		if i <= num_choices and get_node(choice_path).visible:
			var choice_node = get_node(choice_path)
			var choice_text = choice_node.get_node("VBoxContainer/HBoxContainer2/LineEdit").text
			var choice_output = choice_node.get_node("VBoxContainer/HBoxContainer3/LineEdit").text
			var failed_output = choice_node.get_node("VBoxContainer/StatsVBoxContainer/FailedOutputHBox/FailedOutputLineEdit").text.strip_edges()
			
			var requirements = {}
			var health_req = choice_node.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/HealthRequirementHBox/HealthRequirementSpinBox").value
			var mana_req = choice_node.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/ManaRequirementHBox/ManaRequirementSpinBox").value
			var coins_req = choice_node.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/CoinsRequirementHBox/CoinsRequirementSpinBox").value
			if health_req > 0:
				requirements["health"] = health_req
			if mana_req > 0:
				requirements["mana"] = mana_req
			if coins_req > 0:
				requirements["coins"] = coins_req
			
			var buffs = {}
			var health_buff = choice_node.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/HealthBuffHBox/HealthBuffSpinBox").value
			var mana_buff = choice_node.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/ManaBuffHBox/ManaBuffSpinBox").value
			var coins_buff = choice_node.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/CoinsBuffHBox/CoinsBuffSpinBox").value
			if health_buff != 0:
				buffs["health"] = health_buff
			if mana_buff != 0:
				buffs["mana"] = mana_buff
			if coins_buff != 0:
				buffs["coins"] = coins_buff
			
			var dice_test = {}
			print("=== Checking dice test for choice ", i, " ===")
			if choice_node.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList") and choice_node.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox"):
				var dice_item_list = choice_node.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList")
				var dice_threshold_spinbox = choice_node.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox")
				
				print("Found ItemList and SpinBox")
				print("ItemList item_count: ", dice_item_list.item_count)
				
				var selected_items = dice_item_list.get_selected_items()
				print("Selected items: ", selected_items)
				
				if selected_items.size() > 0:
					var selected_index = selected_items[0]
					var dice_type_text = dice_item_list.get_item_text(selected_index)
					print("Selected dice type: ", dice_type_text)
					
					var dice_sides = 0
					var lower_text = dice_type_text.to_lower()
					if lower_text.begins_with("d"):
						dice_sides = int(lower_text.substr(1))
					
					var dice_threshold = int(dice_threshold_spinbox.value)
					
					print("Extracted: sides=", dice_sides, ", threshold=", dice_threshold)
					
					if dice_sides > 0:
						dice_test["sides"] = dice_sides
						dice_test["threshold"] = dice_threshold
						print("✓ Added dice_test to choice data!")
				else:
					print("No item selected in ItemList")
			else:
				print("ERROR: Could not find DiceCheckHBox nodes!")
				print("Has ItemList: ", choice_node.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList"))
				print("Has SpinBox: ", choice_node.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox"))
			
			var choice_data = {"text": choice_text, "output": choice_output}
			if failed_output:
				choice_data["failed_output"] = failed_output
			if requirements:
				choice_data["requirement"] = requirements
			if buffs:
				choice_data["buffs"] = buffs
			if not dice_test.is_empty():
				choice_data["dice_test"] = dice_test
			
			choices[str(i)] = choice_data
	
	return choices

func _set_choices_from_data(choices: Dictionary) -> void:
	# Clear all choices first
	for i in range(1, 4):
		var choice = get_node("PanelContainer/Panel/MarginContainer/Content_Area/MainContentArea/Choice_Container/ScrollContainer/Choice_Inputs/Choice_" + str(i))
		choice.get_node("VBoxContainer/HBoxContainer2/LineEdit").text = ""
		choice.get_node("VBoxContainer/HBoxContainer3/LineEdit").text = ""
		choice.get_node("VBoxContainer/StatsVBoxContainer/FailedOutputHBox/FailedOutputLineEdit").text = ""
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/HealthRequirementHBox/HealthRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/ManaRequirementHBox/ManaRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/CoinsRequirementHBox/CoinsRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/HealthBuffHBox/HealthBuffSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/ManaBuffHBox/ManaBuffSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/CoinsBuffHBox/CoinsBuffSpinBox").value = 0
		
		if choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList"):
			var dice_item_list = choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList")
			dice_item_list.deselect_all()
		if choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox"):
			choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox").value = 0
	
	# Determine max choice number
	var max_choice = 0
	for choice_key in choices.keys():
		var choice_num = int(choice_key)
		if choice_num > max_choice:
			max_choice = choice_num
	
	# Update option button and visibility
	# max_choice is the actual number of choices (1, 2, or 3)
	# option_button indices: 0=no choices, 1=1 choice, 2=2 choices, 3=3 choices
	option_button.select(max_choice)
	_update_choice_visibility(max_choice)
	
	# Set choice data
	for choice_key in choices.keys():
		var choice_num = int(choice_key)
		var choice = get_node("PanelContainer/Panel/MarginContainer/Content_Area/MainContentArea/Choice_Container/ScrollContainer/Choice_Inputs/Choice_" + str(choice_num))
		var choice_data = choices[choice_key]
		choice.get_node("VBoxContainer/HBoxContainer2/LineEdit").text = choice_data["text"]
		choice.get_node("VBoxContainer/HBoxContainer3/LineEdit").text = choice_data["output"]
		if choice_data.has("failed_output"):
			choice.get_node("VBoxContainer/StatsVBoxContainer/FailedOutputHBox/FailedOutputLineEdit").text = choice_data["failed_output"]
		if choice_data.has("requirement"):
			if choice_data["requirement"].has("health"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/HealthRequirementHBox/HealthRequirementSpinBox").value = choice_data["requirement"]["health"]
			if choice_data["requirement"].has("mana"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/ManaRequirementHBox/ManaRequirementSpinBox").value = choice_data["requirement"]["mana"]
			if choice_data["requirement"].has("coins"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/CoinsRequirementHBox/CoinsRequirementSpinBox").value = choice_data["requirement"]["coins"]
		if choice_data.has("buffs"):
			if choice_data["buffs"].has("health"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/HealthBuffHBox/HealthBuffSpinBox").value = choice_data["buffs"]["health"]
			if choice_data["buffs"].has("mana"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/ManaBuffHBox/ManaBuffSpinBox").value = choice_data["buffs"]["mana"]
			if choice_data["buffs"].has("coins"):
				choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/CoinsBuffHBox/CoinsBuffSpinBox").value = choice_data["buffs"]["coins"]
		
		if choice_data.has("dice_test"):
			if choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList") and choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox"):
				var dice_item_list = choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList")
				var dice_threshold_spinbox = choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox")
				
				var dice_sides = choice_data["dice_test"]["sides"]
				var dice_threshold = choice_data["dice_test"]["threshold"]
				
				var dice_text_lower = "d" + str(dice_sides)
				for idx in range(dice_item_list.item_count):
					if dice_item_list.get_item_text(idx).to_lower() == dice_text_lower:
						dice_item_list.select(idx)
						break
				
				dice_threshold_spinbox.value = dice_threshold

# MODIFIED: Mark project as modified when saving scenes
func _on_save_button_pressed() -> void:
	var scene_key = key_edit.text.strip_edges()
	
	if scene_key.is_empty():
		return
	
	var scene_data = {
		"title": title_edit.text,
		"narr_text": main_text_edit.text,
		"choices": _gather_choices_data()
	}
	
	story_data[scene_key] = scene_data
	if not scene_order.has(scene_key):
		scene_order.append(scene_key)
	current_editing_key = scene_key
	
	_save_story_data()
	_mark_project_modified() # NEW
	
	_update_scene_list()
	
	for i in range(scene_list.get_item_count()):
		if scene_list.get_item_text(i) == scene_key:
			scene_list.select(i)
			break

func _on_option_button_item_selected(index: int) -> void:
	_update_choice_visibility(index)
	_mark_project_modified() # NEW

func _on_new_scene_pressed() -> void:
	key_edit.text = ""
	title_edit.text = ""
	main_text_edit.text = ""
	current_editing_key = ""
	
	option_button.select(0)
	_update_choice_visibility(0)
	
	for i in range(1, 4):
		var choice = get_node("PanelContainer/Panel/MarginContainer/Content_Area/MainContentArea/Choice_Container/ScrollContainer/Choice_Inputs/Choice_" + str(i))
		choice.get_node("VBoxContainer/HBoxContainer2/LineEdit").text = ""
		choice.get_node("VBoxContainer/HBoxContainer3/LineEdit").text = ""
		choice.get_node("VBoxContainer/StatsVBoxContainer/FailedOutputHBox/FailedOutputLineEdit").text = ""
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/HealthRequirementHBox/HealthRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/ManaRequirementHBox/ManaRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/RequirementsHBox/CoinsRequirementHBox/CoinsRequirementSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/HealthBuffHBox/HealthBuffSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/ManaBuffHBox/ManaBuffSpinBox").value = 0
		choice.get_node("VBoxContainer/StatsVBoxContainer/BuffsHBox/CoinsBuffHBox/CoinsBuffSpinBox").value = 0
		
		print("Clearing dice test for choice ", i)
		if choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList"):
			var dice_item_list = choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/ItemList")
			print("Before clear - selected items: ", dice_item_list.get_selected_items())
			dice_item_list.deselect_all()
			print("After clear - selected items: ", dice_item_list.get_selected_items())
		else:
			print("WARNING: Could not find ItemList for choice ", i)
		if choice.has_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox"):
			var spinbox = choice.get_node("VBoxContainer/StatsVBoxContainer/DiceCheckHBox/SpinBox")
			print("Before clear - spinbox value: ", spinbox.value)
			spinbox.value = 0
			print("After clear - spinbox value: ", spinbox.value)
		else:
			print("WARNING: Could not find SpinBox for choice ", i)
	
	debug_text.text = "New scene added!"

func _update_choice_visibility(index: int) -> void:
	choice_1.visible = false
	choice_2.visible = false
	choice_3.visible = false
	
	id = index
	
	match id:
		0:
			choice_1.visible = false
			choice_2.visible = false
			choice_3.visible = false
		1:
			choice_1.visible = true
		2:
			choice_1.visible = true
			choice_2.visible = true
		3:
			choice_1.visible = true
			choice_2.visible = true
			choice_3.visible = true

func _on_list_scene_pressed() -> void:
	scene_list_container.visible = !scene_list_container.visible
	if scene_list_container.visible:
		_update_scene_list()

func _on_scene_list_item_selected(index: int) -> void:
	var selected_key = scene_list.get_item_text(index)
	
	if story_data.has(selected_key):
		var scene = story_data[selected_key]
		
		key_edit.text = selected_key
		title_edit.text = scene["title"]
		main_text_edit.text = scene["narr_text"]
		current_editing_key = selected_key
		
		if scene.has("choices"):
			_set_choices_from_data(scene["choices"])
		else:
			# If no choices, set to 0 and hide all
			option_button.select(0)
			_update_choice_visibility(0)

func _on_export_module_pressed() -> void:
	if story_data.size() == 0:
		debug_text.text = "No scenes to export!"
		return
	module_title_edit.text = ""
	module_description_edit.text = ""
	export_dialog.popup_centered()

func _on_export_dialog_confirmed() -> void:
	var module_title = module_title_edit.text.strip_edges()
	var module_description = module_description_edit.text.strip_edges()
	
	if module_title.is_empty():
		debug_text.text = "Module title is required!"
		return
	
	var module_info = {
		"title": module_title,
		"description": module_description,
		"preview_image": "",
		"ambient_sounds": []
	}
	
	var temp_dir = "user://temp/export_" + str(randi())
	DirAccess.make_dir_recursive_absolute(temp_dir)
	
	var story_file = FileAccess.open(temp_dir + "/story_data.json", FileAccess.WRITE)
	story_file.store_string(JSON.stringify(story_data, "\t"))
	story_file.close()
	
	var info_file = FileAccess.open(temp_dir + "/module_info.json", FileAccess.WRITE)
	if info_file:
		info_file.store_string(JSON.stringify(module_info, "\t"))
		info_file.close()
	else:
		debug_text.text = "Failed to write module_info.json!"
		return
	
	var gdz_path = "user://modules/" + module_title.to_snake_case() + ".gdz"
	var zip_packer = ZIPPacker.new()
	var err = zip_packer.open(gdz_path)
	if err != OK:
		debug_text.text = "Failed to create GDZ file!"
		return
	
	var dir = DirAccess.open(temp_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_add_directory_to_zip(zip_packer, temp_dir + "/" + file_name, file_name)
			else:
				var file = FileAccess.open(temp_dir + "/" + file_name, FileAccess.READ)
				var buffer = file.get_buffer(file.get_length())
				file.close()
				zip_packer.start_file(file_name)
				zip_packer.write_file(buffer)
				zip_packer.close_file()
			file_name = dir.get_next()
	
	zip_packer.close()
	
	_remove_directory(temp_dir)
	
	debug_text.text = "Module exported to " + gdz_path + "!"

func _add_directory_to_zip(packer: ZIPPacker, dir_path: String, zip_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = dir_path + "/" + file_name
			var zip_file_path = zip_path + "/" + file_name
			if dir.current_is_dir():
				_add_directory_to_zip(packer, full_path, zip_file_path)
			else:
				var file = FileAccess.open(full_path, FileAccess.READ)
				var buffer = file.get_buffer(file.get_length())
				file.close()
				packer.start_file(zip_file_path)
				packer.write_file(buffer)
				packer.close_file()
			file_name = dir.get_next()

func _remove_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = dir_path + "/" + file_name
			if dir.current_is_dir():
				_remove_directory(full_path)
			else:
				DirAccess.remove_absolute(full_path)
			file_name = dir.get_next()
		DirAccess.remove_absolute(dir_path)

func _on_quit_button_pressed() -> void:
	# NEW: Check for unsaved changes before quitting
	if is_project_modified:
		var quit_dialog = ConfirmationDialog.new()
		quit_dialog.dialog_text = "You have unsaved changes. Are you sure you want to quit?"
		quit_dialog.confirmed.connect(func(): get_tree().quit())
		add_child(quit_dialog)
		quit_dialog.popup_centered()
	else:
		get_tree().quit()
