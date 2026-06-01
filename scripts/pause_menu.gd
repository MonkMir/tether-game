extends MarginContainer

func _ready():
	hide()
	
	PauseManager.pause_toggled.connect(_on_pause_toggled)

func _on_pause_toggled(isPaused) -> void:
	if isPaused:
		show()
		%ResumeButton.grab_focus()
	else:
		hide()


func _on_resume_button_pressed():
	PauseManager.toggle_pause()

func _on_restart_button_pressed():
	reload_level()
	PauseManager.toggle_pause()

func _on_quit_button_pressed():
	get_tree().reload_current_scene()
	PauseManager.toggle_pause()
	GameState.is_pausable = false

func update_active_menu_variables():
	var manager = get_parent()
	manager.defaultFocusButton = %ResumeButton
	manager.mouseResetPosition = %MouseResetPositionPause.global_position

func reload_level():
	var rootNode = get_tree().current_scene
	var oldLevel = rootNode.get_node("Level1")
	
	if oldLevel:
		oldLevel.queue_free()
	
	await get_tree().process_frame
	
	var newLevel = preload("res://scenes/levels/level_1.tscn").instantiate()
	rootNode.add_child(newLevel)
