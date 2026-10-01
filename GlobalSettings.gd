extends Node

var sensitivity: float = 0.003

var main_menu: bool = true

var can_pause: bool = true 


signal show_ui_buttons_changed(new_value)

var show_ui_buttons: bool = false:
	set(value):
		if show_ui_buttons != value:
			show_ui_buttons = value
			show_ui_buttons_changed.emit(show_ui_buttons)
