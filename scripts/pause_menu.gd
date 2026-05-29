extends MarginContainer

func _ready():
	hide()
	
	PauseManager.pause_toggled.connect(_on_pause_toggled)

func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return

	if event is InputEventMouseMotion:
		var focusedNode = get_viewport().gui_get_focus_owner()
		if focusedNode:
			focusedNode.release_focus()

	elif event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
		if get_viewport().gui_get_focus_owner() == null:
			%ResumeButton.grab_focus()

func _on_pause_toggled(isPaused) -> void:
	if isPaused:
		show()
		%ResumeButton.grab_focus()
	else:
		hide()


func _on_resume_button_pressed():
	PauseManager.toggle_pause()


func _on_restart_button_pressed():
	get_tree().reload_current_scene()
	PauseManager.toggle_pause()


func _on_quit_button_pressed():
	get_tree().quit()
