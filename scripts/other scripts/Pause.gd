extends Node2D


var isPaused := false

	
func _input(event):
	if event.is_action_pressed("Pause"):
		isPaused = !isPaused
		get_tree().paused = isPaused
		if get_tree().paused == true:
			print("PAUSED")
		else:
			print("UNPAUSED")
