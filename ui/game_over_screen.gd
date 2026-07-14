extends MarginContainer

func _process(_delta):
	if GameState.is_game_over:
		self.visible = true 
		GameState.is_pausable = false
	
	if Input.is_action_just_pressed("ui_accept") and GameState.is_game_over:
		get_tree().reload_current_scene()
		# Make sure to update is_pausable if it reloads the level
		GameState.game_over_reset()
