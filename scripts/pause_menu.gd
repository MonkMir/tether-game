extends MarginContainer

@onready var manager : Control = get_parent()
@export var mouse_reset_node : Control 
@export var default_focus_object : Control

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
	manager.defaultFocusButton = default_focus_object
	manager.mouse_reset_data = mouse_reset_node

func reload_level():
	var rootNode = get_tree().current_scene
	var oldLevel = rootNode.get_node("Level1")
	
	if oldLevel:
		oldLevel.queue_free()
	
	await get_tree().process_frame
	
	var newLevel = preload("res://scenes/levels/level_1.tscn").instantiate()
	rootNode.add_child(newLevel)
