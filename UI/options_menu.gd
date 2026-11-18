extends Control

@onready var pauseMenu = $"../PauseMenu"
@onready var mainMenu = $"../MainMenu"
@onready var sensitivity_label : Label = $Panel2/ScrollContainer/VBoxContainer/HBoxContainer2/Sensitivity3
@onready var sensitivity_slider: HSlider = $Panel2/ScrollContainer/VBoxContainer/HBoxContainer2/Sensitivity2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sensitivity_slider.value = GlobalSettings.sensitivity
	update_sensitivity_label(GlobalSettings.sensitivity)

	load_keybinds()
	setup_keybinds()


func testEsc():
	if Input.is_action_just_pressed("esc") and GlobalSettings.main_menu == false:
		hide()
	if Input.is_action_just_pressed("esc") and GlobalSettings.main_menu == true:
		hide()	
		mainMenu.show()	
		
func _process(_delta):
	testEsc()

func _on_volume_2_changed(value):
	AudioServer.set_bus_volume_db(0,value/5)

func _on_screen_mode_item_selected(index):
	match index: 
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func update_sensitivity_label(val: float) -> void:
	sensitivity_label.text = str(snapped(val, 0.001) * 1000)


func _on_sensitivity_2_value_changed(value: float) -> void:
	GlobalSettings.sensitivity = value
	update_sensitivity_label(value)



	
# KEYBINDS

var listening_action: String = ""

@onready var keybind_buttons = {
	"ui_left": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/left,
	"ui_right": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/right,
	"ui_up": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/moveforward,
	"ui_down": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/movebackward,
	"ui_accept": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/jump,
	"sprint": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/sprint,
	"pickup": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/hold,
	"throw": $Panel2/ScrollContainer/VBoxContainer/VBoxContainer/throw,
	"dialogue":$Panel2/ScrollContainer/VBoxContainer/VBoxContainer/talktonpc
}


func setup_keybinds():
	for action in keybind_buttons:
		keybind_buttons[action].pressed.connect(
			func(): start_rebinding(action)
		)

	update_keybind_buttons()


func start_rebinding(action: String):
	listening_action = action
	keybind_buttons[action].text = "Press a key..."



func _input(event):
	if listening_action == "":
		return

	# Keyboard input
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			listening_action = ""
			update_keybind_buttons()
			get_viewport().set_input_as_handled()
			return

		var action = listening_action
		listening_action = ""

		remove_old_bindings(action)

		var new_event = InputEventKey.new()
		new_event.physical_keycode = event.physical_keycode

		if new_event.physical_keycode == 0:
			new_event.keycode = event.keycode

		InputMap.action_add_event(action, new_event)

		save_keybinds()
		update_keybind_buttons()
		get_viewport().set_input_as_handled()

	# Mouse input
	elif event is InputEventMouseButton and event.pressed:
		var action = listening_action
		listening_action = ""

		remove_old_bindings(action)

		var new_event = InputEventMouseButton.new()
		new_event.button_index = event.button_index

		InputMap.action_add_event(action, new_event)

		save_keybinds()
		update_keybind_buttons()
		get_viewport().set_input_as_handled()


func remove_old_bindings(action: String):
	for old_event in InputMap.action_get_events(action):
		if old_event is InputEventKey or old_event is InputEventMouseButton:
			InputMap.action_erase_event(action, old_event)




func update_keybind_buttons():
	var action_names = {
		"ui_left": "Move Left",
		"ui_right": "Move Right",
		"ui_up": "Move Forward",
		"ui_down": "Move Backward",
		"ui_accept": "Jump",
		"sprint": "Sprint",
		"pickup": "Pickup",
		"throw": "Throw/Roll/Slide",
		"dialogue": "Talk to NPC",
	}

	for action in keybind_buttons:
		var button = keybind_buttons[action]
		var key_name = "Unassigned"
		var display_name = action_names.get(action, action)

		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var code = event.physical_keycode

				if code == 0:
					code = event.keycode

				if code != 0:
					key_name = OS.get_keycode_string(code)
					break

			elif event is InputEventMouseButton:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						key_name = "Mouse Left"
					MOUSE_BUTTON_RIGHT:
						key_name = "Mouse Right"
					MOUSE_BUTTON_MIDDLE:
						key_name = "Mouse Middle"
					MOUSE_BUTTON_WHEEL_UP:
						key_name = "Wheel Up"
					MOUSE_BUTTON_WHEEL_DOWN:
						key_name = "Wheel Down"
					_:
						key_name = "Mouse Button " + str(event.button_index)

				break

		button.text = display_name + ": " + key_name


func save_keybinds():
	var config = ConfigFile.new()

	for action in keybind_buttons:
		var key_code = 0

		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				key_code = event.keycode
				if key_code == 0:
					key_code = event.physical_keycode
				break

		if key_code != 0:
			config.set_value("keybinds", action, key_code)

	config.save("user://keybinds.cfg")



func load_keybinds():
	var config = ConfigFile.new()

	if config.load("user://keybinds.cfg") != OK:
		return

	for action in keybind_buttons:

		if not config.has_section_key("keybinds", action):
			continue

		var key_code = int(config.get_value("keybinds", action))

		if key_code == 0:
			continue

		for old_event in InputMap.action_get_events(action):
			if old_event is InputEventKey:
				InputMap.action_erase_event(action, old_event)

		var new_event = InputEventKey.new()
		new_event.keycode = key_code

		InputMap.action_add_event(action, new_event)
