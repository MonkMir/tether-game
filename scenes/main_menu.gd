extends MarginContainer

@onready var manager : Control = get_parent()

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
	manager.defaultFocusButton = %PlayButton
	manager.mouseResetPosition = get_viewport().get_visible_rect().size / 2
