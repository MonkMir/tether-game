extends MarginContainer

@onready var manager : Control = get_parent()
#@export var mouse_reset_node : Control 
@export var default_focus_object : Control

func _on_play_button_pressed():
	manager.start_game()

func _on_settings_button_pressed():
	if %SettingsLabel.visible == false:
		%SettingsLabel.show()
	else:
		%SettingsLabel.text = "Wahh wahh wahh, cry about it more bozo"

func _on_quit_button_pressed():
	get_tree().quit()

func set_menu_properties():
	manager.defaultFocusButton = default_focus_object
	manager.mouse_reset_data = null
