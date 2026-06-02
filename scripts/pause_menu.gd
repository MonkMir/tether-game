extends MarginContainer

##TESTING
#func _ready():
	#print(%MouseResetPositionPause.global_position)
#
#func _process(delta):
	#print(%MouseResetPositionPause.global_position)

func _on_resume_button_pressed():
	GameState.toggle_pause()

func _on_restart_button_pressed():
	reload_level()
	GameState.toggle_pause()

func _on_quit_button_pressed():
	get_tree().reload_current_scene()
	GameState.toggle_pause()
	GameState.is_pausable = false

func set_menu_properties():
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
