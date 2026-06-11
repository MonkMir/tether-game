extends MarginContainer

@export var mouse_reset_node : Control 
@export var default_focus_object : Control
@onready var _manager : Control = get_parent()


func _on_resume_button_pressed():
	GameState.toggle_pause()


func _on_restart_button_pressed():
	_manager.reload_level()
	GameState.toggle_pause()


func _on_quit_button_pressed():
	get_tree().reload_current_scene()
	GameState.toggle_pause()
	GameState.is_pausable = false


func set_menu_properties():
	_manager.default_focus = default_focus_object
	_manager.mouse_reset_data = mouse_reset_node
