extends Node

@export var dialogPath: String = "res://user/story_data.json"
@export var moduleInfoPath: String = "res://user/module_info.json"
var content_dict: Dictionary = {}
var module_info: Dictionary = {}
var current_key: int = 0
var current_value: int = 0
var phraseNum: int = 0
var finished: bool = false
var temp_dir: String = "" 
var module_name: String = "default_module"

func _ready() -> void:
	load_content_dict()
	load_module_info()

func load_content_dict(path: String = dialogPath) -> void:
	dialogPath = path
	# Normalize temp_dir to ensure trailing slash
	temp_dir = path.get_base_dir().replace("\\", "/")
	if not temp_dir.ends_with("/"):
		temp_dir += "/"
	print("Loading story data from: ", dialogPath, ", temp_dir: ", temp_dir)
	
	if not FileAccess.file_exists(dialogPath):
		push_error("The file path doesn't exist: " + dialogPath)
		return

	var f = FileAccess.open(dialogPath, FileAccess.READ)
	var json = f.get_as_text()
	f.close()

	var json_object = JSON.new()
	var error = json_object.parse(json)
	if error != OK:
		push_error("JSON parsing failed for story data: " + str(error))
		return

	content_dict = json_object.data
	if typeof(content_dict) != TYPE_DICTIONARY:
		push_error("Parsed story JSON is not a dictionary")
		content_dict = {}
	else:
		for key in content_dict:
			var scene = content_dict[key]
			if scene.has("picture") and scene["picture"]:
				var full_picture_path = (temp_dir + scene["picture"]).replace("\\", "/")
				if not file_exists_alternative(full_picture_path):
					push_warning("Image not found: " + full_picture_path)
					scene["picture"] = ""
				else:
					scene["picture"] = full_picture_path
			if scene.has("choices"):
				for choice_key in scene["choices"]:
					var choice = scene["choices"][choice_key]
					if choice.has("requirement"):
						for stat in choice["requirement"]:
							if not stat in ["health", "mana", "coins"]:
								push_warning("Invalid stat in requirement: " + stat)
								choice["requirement"].erase(stat)
					if choice.has("buffs"):
						for stat in choice["buffs"]:
							if not stat in ["health", "mana", "coins"]:
								push_warning("Invalid stat in buffs: " + stat)
								choice["buffs"].erase(stat)
					# Updated: Validate dice_test (handle TYPE_FLOAT from JSON)
					if choice.has("dice_test"):
						var dt = choice["dice_test"]
						if typeof(dt) != TYPE_DICTIONARY or not dt.has("sides") or not dt.has("threshold"):
							push_warning("Invalid dice_test format in choice " + choice_key + ": must be dict with 'sides' and 'threshold'")
							choice.erase("dice_test")
						else:
							var sides_val = dt["sides"]
							var threshold_val = dt["threshold"]
							if (typeof(sides_val) != TYPE_INT and typeof(sides_val) != TYPE_FLOAT) or int(sides_val) < 2:
								push_warning("Invalid dice_test sides in choice " + choice_key + ": must be integer >=2")
								choice.erase("dice_test")
							elif (typeof(threshold_val) != TYPE_INT and typeof(threshold_val) != TYPE_FLOAT) or int(threshold_val) < 0 or int(threshold_val) >= int(sides_val):
								push_warning("Invalid dice_test threshold in choice " + choice_key + ": must be integer 0 <= threshold < sides")
								choice.erase("dice_test")
							else:
								# Cast to int for consistency
								dt["sides"] = int(sides_val)
								dt["threshold"] = int(threshold_val)

func load_module_info(path: String = moduleInfoPath) -> void:
	# Use temp_dir from load_content_dict if available
	if temp_dir:
		path = temp_dir + "module_info.json"
	path = path.replace("\\", "/")
	print("Loading module info from: ", path)
	
	if not FileAccess.file_exists(path):
		push_error("The module info path doesn't exist: " + path)
		return

	var f = FileAccess.open(path, FileAccess.READ)
	var json = f.get_as_text()
	f.close()

	var json_object = JSON.new()
	var error = json_object.parse(json)
	if error != OK:
		push_error("JSON parsing failed for module info: " + str(error))
		return

	module_info = json_object.data
	if typeof(module_info) != TYPE_DICTIONARY:
		push_error("Parsed module info JSON is not a dictionary")
		module_info = {}
	else:
		# Extract module name from module_info
		if module_info.has("title"):
			module_name = module_info["title"].to_snake_case()
			print("Module name set to: ", module_name)
		else:
			# Fallback: use the directory name or file name
			module_name = path.get_base_dir().get_file()
			if module_name.is_empty():
				module_name = "default_module"
			print("Module name set from path: ", module_name)
		
		if module_info.has("ambient_sounds"):
			var sounds = module_info["ambient_sounds"]
			for i in range(sounds.size() - 1, -1, -1):
				if typeof(sounds[i]) != TYPE_STRING:
					push_warning("Invalid ambient sound entry at index " + str(i) + ": " + str(sounds[i]))
					sounds.remove_at(i)
					continue
				var sound_path = (temp_dir + sounds[i]).replace("\\", "/")
				print("Checking sound path: ", sound_path)
				if not file_exists_alternative(sound_path):
					push_warning("Ambient sound not found: " + sound_path)
					sounds.remove_at(i)
				else:
					sounds[i] = sound_path
		if module_info.has("preview_image") and module_info["preview_image"]:
			var preview_path = (temp_dir + module_info["preview_image"]).replace("\\", "/")
			if not file_exists_alternative(preview_path):
				push_warning("Preview image not found: " + preview_path)
				module_info["preview_image"] = ""
			else:
				module_info["preview_image"] = preview_path

func file_exists_alternative(path: String) -> bool:
	# Try FileAccess first
	if FileAccess.file_exists(path):
		print("FileAccess confirmed existence: ", path)
		return true
	# Fallback to DirAccess
	var dir = DirAccess.open(path.get_base_dir())
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == path.get_file():
				print("DirAccess confirmed existence: ", path)
				return true
			file_name = dir.get_next()
	print("File not found by any method: ", path)
	return false

func get_content_dict() -> Dictionary:
	return content_dict

func get_module_info() -> Dictionary:
	return module_info

func nextPhrase() -> void:
	if content_dict.is_empty() or phraseNum >= len(content_dict):
		finished = true
		return
	
	finished = false
	phraseNum += 1
