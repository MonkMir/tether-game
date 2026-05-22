extends Label

func _process(_delta):
	if GameState.is_game_over: #you can also do == true before colon
		self.visible = true 
	
	if Input.is_action_just_pressed("Enter") and GameState.is_game_over == true:
		get_tree().reload_current_scene()
		GameState.reset_values()
