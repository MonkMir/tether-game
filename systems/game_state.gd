extends Node

signal pause_toggled(is_paused : bool)

const MAX_COMBO : int = 24

var is_pausable : bool = false
var last_pause_toggle_frame: int = 0

var is_game_over : bool = false:
	set(new_bool):
		if new_bool == true and is_game_over == false:
			is_game_over = new_bool
			_update_leaderboard()
			SignalBus.game_over.emit()
		else: is_game_over = new_bool

var toss_kill_count: int
var hit_transaction_registry: Dictionary
# This is the unused combo system
var combo_counter : int = 0
var score : int = 0
var leaderboard: Array = []
var _max_score_entries : int = 5


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	leaderboard.resize(_max_score_entries)
	leaderboard.fill(0)
	
	SignalBus.tether_toggled.connect(_on_tether_toggled)
	SignalBus.enemy_died.connect(_on_enemy_killed)


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


#EXPERIMENTAL To be called by process or setter
func update_combo():
	combo_counter = clampi(combo_counter, 0, MAX_COMBO)


func _spawn_score_increment_label(text: String, start_position: Vector2) -> void:
	var label = Label.new()
	label.text = text
	label.position = start_position
	
	var custom_font = preload("res://components/EpsonPixeledRegular-0Py9.ttf")
	label.add_theme_font_override("font", custom_font)
	label.add_theme_font_size_override("font_size", 9)
	
	add_child(label)
	
	var tween = create_tween()
	
	var target_position = start_position + Vector2(0, -20)
	
	tween.parallel().tween_property(label, "position", target_position, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	
	tween.tween_callback(label.queue_free)


func _on_tether_toggled(just_tethered: bool):
	if not just_tethered:
		toss_kill_count = 0


func _on_enemy_killed(victim_id: int) -> void:
	var score_reward: int
	var score_growth_sample: Array[int]
	
	var attacker_type : String = hit_transaction_registry[victim_id]["attacker_type"]
	var is_tethered : bool = hit_transaction_registry[victim_id]["is_tethered"]
	var victim_position : Vector2 = hit_transaction_registry[victim_id]["victim_position"]
	
	if is_tethered:
		score_reward = 1
		score += score_reward
		_spawn_score_increment_label("+" + str(score_reward), victim_position)
		hit_transaction_registry.erase(victim_id)
		return
	
	toss_kill_count += 1
	
	match attacker_type:
		"arrow":
			score_growth_sample = [1, 4, 8, 10]
		"bomber":
			score_growth_sample = [1, 2, 2, 2, 3]
		"parabolic":
			score_growth_sample = [1, 3, 5]
	
	if toss_kill_count <= score_growth_sample.size():
		score_reward = score_growth_sample[toss_kill_count -1]
	else:
		score_reward = score_growth_sample.back()
	
	score += score_reward
	_spawn_score_increment_label("+" + str(score_reward), victim_position)
	hit_transaction_registry.erase(victim_id)
