extends MarginContainer

func _ready():
	#%PlayButton.grab_focus() #this might be better left off if I want nav wake
	show()

func _on_play_button_pressed():
	hide()
	get_tree().current_scene.add_child(preload("res://scenes/levels/level_1.tscn").instantiate())
	GameState.is_pausable = true


func _on_settings_button_pressed():
	if %SettingsLabel.visible == false:
		%SettingsLabel.show()
	else:
		%SettingsLabel.text = "Wahh wahh wahh, cry about it more bozo"


func _on_quit_button_pressed():
	get_tree().quit()

func update_active_menu_variables():
	var manager = get_parent()
	manager.defaultFocusButton = %PlayButton
	manager.mouseResetPosition = get_viewport().get_visible_rect().size / 2
