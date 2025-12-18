extends VBoxContainer

@onready var title_label: Label = %Label
@onready var picture: TextureRect = %TextureRect
@onready var narr_text: RichTextLabel = %RichTextLabel
@onready var statindicator: RichTextLabel = %StatIndicator
@onready var choices_container: VBoxContainer = %VBoxContainer
@onready var choice_1: PanelContainer = %"ChoiceContainer"
@onready var choice_2: PanelContainer = %"ChoiceContainer2"
@onready var choice_3: PanelContainer = %"ChoiceContainer3"

# Játék statok UI label
@onready var health_label: Label = %"Health_Label"
@onready var mana_label: Label = %"Mana_Label"
@onready var coins_label: Label = %"Coins_Label"

@export var start_page: String = "start"
@export var death_page: String = "health_is_zero"
@export var mana_low_page: String = "mana_is_zero"

# TTS változók

@export var tts_enabled: bool = true
@export_range(0, 100, 1) var tts_volume: int = 70  
@export_range(0.5, 2.0, 0.1) var tts_rate: float = 1.0  
@export_range(0.5, 2.0, 0.1) var tts_pitch: float = 1.0 

var player_stats: Dictionary = {"health": 100, "mana": 100, "coins": 0}
var used_hp: bool = false
var is_dead: bool = false
var shown_death: bool = false
var content_dict: Dictionary
var current_page: String

# Mentlési rendszer
var current_module_name: String = ""
var save_file_path: String = ""

var tts_voice: String = ""

func _ready() -> void:
	randomize()
	content_dict = ContentData.content_dict

	
	current_module_name = ContentData.module_name if "module_name" in ContentData else "default_module"
	save_file_path = "user://save_" + current_module_name.to_snake_case() + ".json"
	print("Save file path set to: ", save_file_path)

	# TTS inicializáció
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		print("TTS not supported on this platform!")
		tts_enabled = false
	else:
		var voices = DisplayServer.tts_get_voices_for_language("en")
		if voices.size() > 0:
			tts_voice = voices[0]
			print("TTS voice selected: ", tts_voice)
		else:
			print("No English TTS voices found! Check system TTS settings.")
			tts_enabled = false

	var keys = content_dict.keys()
	keys.sort()
	if keys.size() > 0:
		current_page = start_page if content_dict.has(start_page) else keys[0]
	else:
		push_error("No content found in the story data!")
		return

	
	if FileAccess.file_exists(save_file_path):
		print("Save file found for module '", current_module_name, "', loading...")
		if load_game():
			print("Game loaded successfully from save.")
		else:
			print("Failed to load save, starting new game.")
			set_content(content_dict[current_page])
	else:
		print("No save file found, starting new game.")
		set_content(content_dict[current_page])

	
	choice_1.connect("choice_btn_pressed", Callable(self, "process_choice"))
	choice_2.connect("choice_btn_pressed", Callable(self, "process_choice"))
	choice_3.connect("choice_btn_pressed", Callable(self, "process_choice"))

	
	update_ui()

	
	if statindicator:
		statindicator.bbcode_enabled = true


func _exit_tree() -> void:
	stop_tts()


# TTS funkciók

func speak_text(text: String) -> void:
	print("=== TTS SPEAK_TEXT ===")
	print("TTS Enabled: ", tts_enabled)
	print("Text received: ", text)
	if not tts_enabled:
		print("TTS is disabled!")
		return

	# TTS hang megállítása - potenciális hiba?
	if DisplayServer.tts_is_speaking():
		print("Stopping previous speech...")
		DisplayServer.tts_stop()

	var clean_text = strip_bbcode(text)
	print("Clean text: ", clean_text)
	print("Length: ", clean_text.length())
	if clean_text.is_empty():
		print("ERROR: Text is empty after cleaning!")
		return

	if tts_voice.is_empty():
		print("ERROR: No valid TTS voice available!")
		return

	print("Calling DisplayServer.tts_speak...")
	DisplayServer.tts_speak(clean_text, tts_voice, tts_volume, tts_pitch, tts_rate)
	print("TTS speak called!")
	
	# 1 frame után TTS hang vizsgálata
	await get_tree().process_frame
	print("Is speaking after 1 frame: ", DisplayServer.tts_is_speaking())
	print("=== END SPEAK_TEXT ===")


func stop_tts() -> void:
	print("STOP_TTS called")
	if DisplayServer.tts_is_speaking():
		print("Stopping active TTS")
		DisplayServer.tts_stop()
	else:
		print("No TTS currently speaking")


func toggle_tts() -> void:
	tts_enabled = not tts_enabled
	print("TTS toggled! Now: ", "ENABLED" if tts_enabled else "DISABLED")
	if not tts_enabled:
		stop_tts()



func strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)


func _process(delta: float) -> void:
	if player_stats["health"] <= 0 and not is_dead:
		is_dead = true
		if is_dead and not shown_death:
			if content_dict.has(death_page):
				narr_text.text += "\n" + str(content_dict[death_page]["narr_text"])
				set_choice_btn(content_dict[death_page])
				shown_death = true
				update_ui()
				speak_text(str(content_dict[death_page]["narr_text"]))
			else:
				push_warning("Death page not found: " + death_page)


# Mentés és betöltés
func save_game() -> bool:
	var save_data = {
		"module_name": current_module_name,
		"current_page": current_page,
		"player_stats": player_stats.duplicate(true)
	}
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + save_file_path)
		return false
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("Game saved to: " + save_file_path)
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(save_file_path):
		push_error("No save file found: " + save_file_path)
		return false
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: " + save_file_path)
		return false
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_error = json.parse(json_text)
	if parse_error != OK:
		push_error("JSON parse error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return false
	var save_data = json.data
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("Save data is not a dictionary")
		return false
	if not save_data.has("current_page") or not save_data.has("player_stats"):
		push_error("Invalid save data: missing current_page or player_stats")
		return false
	if save_data.has("module_name") and save_data["module_name"] != current_module_name:
		push_error("Save file is for a different module: " + str(save_data["module_name"]))
		return false

	current_page = save_data["current_page"]
	player_stats = save_data["player_stats"].duplicate(true)
	if not player_stats.has("health") or not player_stats.has("mana") or not player_stats.has("coins"):
		push_error("Invalid player_stats in save data")
		return false
	player_stats["health"] = max(0, int(player_stats.get("health", 0)))
	player_stats["mana"] = max(0, int(player_stats.get("mana", 0)))
	player_stats["coins"] = max(0, int(player_stats.get("coins", 0)))

	if not content_dict.has(current_page):
		push_error("Saved page '" + current_page + "' not found in content_dict")
		return false

	set_content(content_dict[current_page])
	update_ui()
	used_hp = false
	is_dead = false
	shown_death = false
	print("Game loaded: page '" + current_page + "', stats: " + str(player_stats))
	return true


func _on_save_pressed() -> void:
	if save_game():
		if statindicator:
			statindicator.text += "\n[color=green]Game saved![/color]"
	else:
		if statindicator:
			statindicator.text += "\n[color=red]Save failed![/color]"


func _on_load_pressed() -> void:
	if load_game():
		if statindicator:
			statindicator.text += "\n[color=green]Game loaded![/color]"
	else:
		if statindicator:
			statindicator.text += "\n[color=red]Load failed![/color]"


# Döntések feldolgozása
func process_choice(choice_index: int) -> void:
	print("=== Process Choice Called: Index ", choice_index, " ===")
	print("Current page: ", current_page)
	stop_tts()
	if statindicator:
		statindicator.text = ""
	print("Cleared statindicator.text")

	if is_dead:
		print("Player is dead, handling death choice")
		current_page = death_page
		if content_dict.has(current_page) and content_dict[current_page].has("choices") and content_dict[current_page]["choices"].has(str(choice_index)) and content_dict[current_page]["choices"][str(choice_index)].has("output"):
			get_parent().scroll_vertical = 0
			var output_value = content_dict[current_page]["choices"][str(choice_index)]["output"]
			current_page = output_value
			if content_dict.has(output_value):
				set_content(content_dict[output_value])
				update_ui()
			return

	var choice_key = str(choice_index)
	if not content_dict[current_page]["choices"].has(choice_key):
		print("ERROR: Choice key '", choice_key, "' not found in current page!")
		return

	var choice = content_dict[current_page]["choices"][choice_key]
	print("Found choice: ", choice)

	if choice.has("output"):
		get_parent().scroll_vertical = 0
		var output_value = choice["output"]
		print("Initial output_value: ", output_value)

		# Dice test
		if choice.has("dice_test"):
			print("Dice test found! Processing roll...")
			var dt = choice["dice_test"]
			var sides = int(dt["sides"])
			var threshold = int(dt["threshold"])
			var roll = randi() % sides + 1
			print("Rolled: ", roll, " (sides: ", sides, ", threshold: ", threshold, ")")
			var success = roll > threshold
			var color = "green" if success else "red"
			var msg = "\n[color=" + color + "]Rolled " + str(roll) + " on d" + str(sides) + " (needed >" + str(threshold) + ") - " + ("Success!" if success else "Failure!") + "[/color]"
			if statindicator:
				statindicator.text += msg
			if not success:
				if choice.has("failed_output"):
					output_value = choice["failed_output"]
					print("Dice failed, using failed_output: ", output_value)
				else:
					print("Dice failed, but no failed_output—blocking choice")
					return

		# Feltételek
		if choice.has("requirement"):
			print("Checking requirements...")
			var requirements = choice["requirement"]
			for stat in requirements.keys():
				if player_stats[stat] < requirements[stat]:
					print("Requirement failed for ", stat)
					if stat == "mana" and choice.has("output"):
						var health_deduction = (player_stats[stat] - requirements[stat]) * 1.5
						player_stats["health"] += round(health_deduction)
						if statindicator:
							statindicator.text += "\n[color=red]Health decreased by " + str(-round(health_deduction)) + "[/color]"
						used_hp = true
						output_value = choice["output"]
					elif choice.has("failed_output"):
						output_value = choice["failed_output"]
					if stat == "mana" and content_dict.has(mana_low_page):
						output_value = mana_low_page
					else:
						print("Requirement blocked choice")
						return

		# Buffok
		if choice.has("buffs"):
			print("Applying buffs...")
			var buffs = choice["buffs"]
			for stat in buffs.keys():
				var change = buffs[stat]
				player_stats[stat] += change
				if change >= 0:
					if statindicator:
						statindicator.text += "\n[color=green]" + stat.capitalize() + " increased by " + str(change) + "[/color]"
				else:
					if statindicator:
						statindicator.text += "\n[color=red]" + stat.capitalize() + " decreased by " + str(-change) + "[/color]"
				if stat in ["health", "mana"] and player_stats[stat] < 0:
					player_stats[stat] = 0

		current_page = output_value
		print("Setting current_page to: ", current_page)
		if content_dict.has(output_value):
			print("Content exists, calling set_content...")
			set_content(content_dict[output_value])
			update_ui()
		else:
			push_warning("Page not found: " + output_value)
	else:
		print("ERROR: No 'output' in choice!")
	print("=== End Process Choice ===")


# Content beállítása
func set_content(output_value) -> void:
	print("=== SET_CONTENT START ===")
	DisplayServer.tts_stop()  # Immediate stop

	set_title(output_value)
	set_picture(output_value)
	set_narr_text_no_tts(output_value)
	set_choice_btn(output_value)

	if not tts_enabled:
		print("TTS disabled, skipping speech")
		print("=== SET_CONTENT END ===")
		return

	var narr_text_value = str(output_value["narr_text"])

	get_tree().create_timer(0.5).timeout.connect(func():
		print("=== TIMER CALLBACK - SPEAKING ===")
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
		await get_tree().create_timer(0.1).timeout
		var clean = strip_bbcode(narr_text_value)
		if clean.is_empty():
			print("No text to speak after cleaning")
			return
		print("Speaking (", clean.length(), " chars): ", clean.substr(0, 100))
		DisplayServer.tts_speak(clean, tts_voice, tts_volume, tts_pitch, tts_rate)
		print("TTS speak called!")
		
		
		await get_tree().process_frame
		print("Is speaking after call: ", DisplayServer.tts_is_speaking())
		print("=== END TIMER CALLBACK ===")
	)


func set_title(output_value) -> void:
	title_label.text = str(output_value["title"])


func set_picture(output_value) -> void:
	if output_value.has("picture") and output_value["picture"]:
		var texture = load(output_value["picture"])
		if texture:
			picture.texture = texture
		else:
			print("Failed to load picture: ", output_value["picture"])
			picture.texture = null
	else:
		picture.texture = null


func set_narr_text_no_tts(output_value) -> void:
	var narr_text_value = str(output_value["narr_text"])
	print("Setting narr_text: ", narr_text_value.substr(0, 50), "...")
	narr_text.text = narr_text_value


func set_choice_btn(output_value) -> void:
	print("=== SET_CHOICE_BTN START ===")
	
	if choice_1.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_1.disconnect("choice_btn_pressed", Callable(self, "process_choice"))
	if choice_2.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_2.disconnect("choice_btn_pressed", Callable(self, "process_choice"))
	if choice_3.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_3.disconnect("choice_btn_pressed", Callable(self, "process_choice"))

	for choice_i in choices_container.get_children():
		if choice_i.visible:
			choice_i.set_text("")
			choice_i.visible = false

	var choices = output_value["choices"] if not is_dead else content_dict[death_page]["choices"]
	for choice in choices:
		match choice:
			"1":
				choice_1.set_text(str(choices[str(choice_1.choice_index)]["text"]))
				choice_1.visible = true
			"2":
				choice_2.set_text(str(choices[str(choice_2.choice_index)]["text"]))
				choice_2.visible = true
			"3":
				choice_3.set_text(str(choices[str(choice_3.choice_index)]["text"]))
				choice_3.visible = true

	# Reconnect
	if not choice_1.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_1.connect("choice_btn_pressed", Callable(self, "process_choice"))
	if not choice_2.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_2.connect("choice_btn_pressed", Callable(self, "process_choice"))
	if not choice_3.is_connected("choice_btn_pressed", Callable(self, "process_choice")):
		choice_3.connect("choice_btn_pressed", Callable(self, "process_choice"))

	print("TTS is speaking after set_choice_btn: ", DisplayServer.tts_is_speaking())
	print("=== SET_CHOICE_BTN END ===")


func update_ui() -> void:
	if health_label and mana_label and coins_label:
		health_label.text = str(player_stats["health"])
		mana_label.text = str(player_stats["mana"])
		coins_label.text = str(player_stats["coins"])
	else:
		print("Warning: One or more UI labels not found")


func _on_main_menu_button_pressed() -> void:
	stop_tts()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	stop_tts()
	get_tree().quit()


func _on_tts_button_pressed() -> void:
	toggle_tts()
	print("TTS button pressed! TTS is now: ", "ENABLED" if tts_enabled else "DISABLED")


# TTS teszt gomb (depracated funkció, korábbi teszt)
func _on_test_tts_button_pressed() -> void:
	print("=== MANUAL TTS TEST BUTTON ===")
	var test_text = "This is a manual TTS test. The voice should speak clearly now."
	print("Speaking: ", test_text)
	if tts_voice.is_empty():
		print("No TTS voice available!")
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(test_text, tts_voice, tts_volume, tts_pitch, tts_rate)
	print("TTS speak called!")
	
	
	await get_tree().process_frame
	print("Is speaking: ", DisplayServer.tts_is_speaking())
	print("=== END MANUAL TEST ===")
