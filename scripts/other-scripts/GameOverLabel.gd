extends Label

func _process(_delta):
	if GameState.is_game_over: #you can also do == true before colon
		self.visible = true 
		GameState.is_pausable = false
	
	if Input.is_action_just_pressed("ui_accept") and GameState.is_game_over == true:
		get_tree().reload_current_scene()
		GameState.reset_values()
		#hey make sure to update iz_pausable if it reloads the level
