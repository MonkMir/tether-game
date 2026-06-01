extends Node2D

signal pause_toggled(isPaused : bool)

var lastToggleFrame: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("Pause"):
		toggle_pause()
	
func toggle_pause() -> void:
	if GameState.is_pausable == false:
		return
	
	var currentFrame = Engine.get_process_frames()
	if currentFrame == lastToggleFrame:
		return
	
	lastToggleFrame = currentFrame
	
	get_tree().paused = !get_tree().paused
	var isPaused : bool = get_tree().paused
	pause_toggled.emit(isPaused)
