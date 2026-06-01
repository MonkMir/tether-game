extends Node

signal pause_toggled(isPaused : bool)

var is_pausable = false
var is_game_over = false

var lastPauseToggleFrame: int = 0

var score = 0
var comboCounter : int = 0
const MAX_COMBO : int = 24

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("Pause"):
		toggle_pause()


func game_over_reset():
	score = 0 
	is_game_over = false

func toggle_pause() -> void:
	if is_pausable == false:
		return
	
	var currentFrame = Engine.get_process_frames()
	if currentFrame == lastPauseToggleFrame:
		return
	
	lastPauseToggleFrame = currentFrame
	
	get_tree().paused = !get_tree().paused
	var isPaused : bool = get_tree().paused
	pause_toggled.emit(isPaused)

#to be called by process or setter
func update_combo():
	comboCounter = clampi(comboCounter, 0, MAX_COMBO)
