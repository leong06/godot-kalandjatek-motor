extends Node

const MODULES_DIR = "user://modules/"
const TEMP_DIR = "user://temp/"

func _ready() -> void:
	# Ensure modules and temp directories exist
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("modules"):
			var err = dir.make_dir("modules")
			if err != OK:
				push_error("Failed to create modules directory: " + str(err))
		if not dir.dir_exists("temp"):
			var err = dir.make_dir("temp")
			if err != OK:
				push_error("Failed to create temp directory: " + str(err))
	else:
		push_error("Failed to access user:// directory!")

func get_available_modules() -> Array:
	var modules = []
	var dir = DirAccess.open(MODULES_DIR)
	if dir:
		print("Scanning directory: " + MODULES_DIR)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Found file: " + file_name)
			if file_name.ends_with(".gdz"):
				print("Processing GDZ file: " + file_name)
				var module_info = load_module_info(file_name)
				if module_info:
					modules.append({
						"file_name": file_name,
						"title": module_info.get("title", "Untitled"),
						"description": module_info.get("description", ""),
						"preview_image": module_info.get("preview_image", "")
					})
					print("Module added: " + module_info.get("title", "Untitled"))
				else:
					print("Failed to load module info for: " + file_name)
			else:
				print("Skipping non-GDZ file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open modules directory: " + MODULES_DIR)
	return modules

func load_module_info(gdz_file: String) -> Dictionary:
	var temp_path = TEMP_DIR + gdz_file.get_basename()
	print("Extracting GDZ to: " + temp_path)
	if not extract_gdz(gdz_file, temp_path):
		print("Failed to extract GDZ: " + gdz_file)
		return {}
	
	var info_path = temp_path + "/module_info.json"
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			print("module_info.json content: " + json_text)
			var json = JSON.new()
			var error = json.parse(json_text)
			if error == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY:
					print("Successfully loaded module_info.json for: " + gdz_file)
					return data
				else:
					print("module_info.json is not a valid dictionary for: " + gdz_file)
			else:
				print("Failed to parse module_info.json for: " + gdz_file + " (JSON Error: " + json.get_error_message() + ", Line: " + str(json.get_error_line()) + ")")
		else:
			print("Failed to open module_info.json at: " + info_path)
	else:
		print("module_info.json not found in extracted GDZ: " + temp_path)
	return {}

func extract_gdz(gdz_file: String, extract_path: String) -> bool:
	var zip_reader = ZIPReader.new()
	var err = zip_reader.open(MODULES_DIR + gdz_file)
	if err != OK:
		push_error("Failed to open GDZ file: " + gdz_file + " (Error: " + str(err) + ")")
		return false
	
	DirAccess.make_dir_recursive_absolute(extract_path)
	var files = zip_reader.get_files()
	print("Files in GDZ: " + str(files))
	for file_path in files:
		var data = zip_reader.read_file(file_path)
		var full_path = extract_path + "/" + file_path
		DirAccess.make_dir_recursive_absolute(full_path.get_base_dir())
		var file = FileAccess.open(full_path, FileAccess.WRITE)
		if file:
			file.store_buffer(data)
			file.close()
			print("Extracted file: " + full_path)
		else:
			print("Failed to write file: " + full_path)
	
	zip_reader.close()
	return true

func load_module(gdz_file: String) -> String:
	var temp_path = TEMP_DIR + gdz_file.get_basename()
	if extract_gdz(gdz_file, temp_path):
		var story_path = temp_path + "/story_data.json"
		if FileAccess.file_exists(story_path):
			print("Loaded module story path: " + story_path)
			# Load both story data and module info
			ContentData.load_content_dict(story_path)
			ContentData.load_module_info() # Uses temp_dir set by load_content_dict
			return story_path
		else:
			print("story_data.json not found in: " + temp_path)
	else:
		print("Failed to extract GDZ for loading: " + gdz_file)
	return ""

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
	else:
		print("Failed to open directory for removal: " + dir_path)
