extends Node

signal pause_toggled(is_paused : bool)

const MAX_COMBO : int = 24

var is_pausable : bool = false
var is_game_over : bool = false:
	set(new_bool):
		if new_bool == true and is_game_over == false:
			is_game_over = new_bool
			_update_leaderboard()
			SignalBus.game_over.emit()
		else: is_game_over = new_bool

var combo_counter : int = 0
var last_pause_toggle_frame: int = 0
var score : int = 0
var leaderboard: Array = []
var _max_score_entries : int = 5


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	leaderboard.resize(_max_score_entries)
	leaderboard.fill(0)


func _input(event):
	if event.is_action_pressed("Pause"):
		toggle_pause()


func _update_leaderboard():
	leaderboard.append(score)
	leaderboard.sort()
	leaderboard.reverse()
	if leaderboard.size() > _max_score_entries:
		leaderboard.resize(_max_score_entries)
	
	SaveManager.save_game_data()


# rename to "reset_game_state"?
func game_over_reset():
	score = 0 
	is_game_over = false


func toggle_pause() -> void:
	if is_pausable == false:
		return
	
	var current_frame : int = Engine.get_process_frames()
	if current_frame == last_pause_toggle_frame:
		return
	
	last_pause_toggle_frame = current_frame
	
	get_tree().paused = !get_tree().paused
	var is_paused : bool = get_tree().paused
	pause_toggled.emit(is_paused)


# To be called by process or setter
func update_combo():
	combo_counter = clampi(combo_counter, 0, MAX_COMBO)
