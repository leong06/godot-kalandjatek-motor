extends Control

@onready var module_id_input = $PanelContainer/CenterContainer/VBoxContainer/HBoxContainer/ModuleIDInput
@onready var status_label = $PanelContainer/CenterContainer/VBoxContainer/StatusLabel
@onready var download_request = $DownloadRequest
@onready var download_button: Button = $PanelContainer/CenterContainer/VBoxContainer/HBoxContainer/DownloadButton
@onready var return_button: Button = $PanelContainer/CenterContainer/VBoxContainer/ReturnButton


# Modul betöltés script HTTP használatával
func _ready():
	
	download_button.pressed.connect(_on_download_button_pressed)
	
	download_request.request_completed.connect(_on_request_completed)

func _on_download_button_pressed():
	var module_id = module_id_input.text.strip_edges()
	if module_id == "":
		status_label.text = "Please enter a module ID"
		return
	if not module_id.is_valid_int():
		status_label.text = "Module ID must be a number"
		return
	
	status_label.text = "Downloading..."
	var url = "http://localhost:5000/api/modules/" + module_id + "/download"
	var error = download_request.request(url)
	if error != OK:
		status_label.text = "Error initiating download"
		download_request.request_completed.disconnect(_on_request_completed)

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		status_label.text = "Error: Module not found or server error"
		return
	
	
	var filename = "module_" + module_id_input.text + ".gdz"
	for header in headers:
		if header.begins_with("Content-Disposition"):
			var matches = header.match('attachment; filename="*"')
			if matches:
				filename = matches[1]
				break
	
	
	var dir = DirAccess.open("user://")
	dir.make_dir("modules")
	var file_path = "user://modules/" + filename
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		file.close()
		status_label.text = "Module downloaded to " + file_path
	else:
		status_label.text = "Error saving file"


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
