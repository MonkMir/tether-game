extends MarginContainer


@export var default_focus_object : Control
@onready var _manager : Control = get_parent()

@onready var scores_vbox: BoxContainer = %ScoresBox
@onready var score_template: Label = %ScoreTemplate
@onready var input_guard_timer := $InputGuardTimer

@onready var header: Label = $MainVBox/Header

func _process(_delta):
	if GameState.is_game_over:
		self.visible = true 
		GameState.is_pausable = false
	
	if (
			Input.is_action_just_pressed("ui_accept")
			and GameState.is_game_over
			and input_guard_timer.time_left == 0.0
		):
		get_tree().reload_current_scene()
		# Make sure to update is_pausable if it reloads the level
		GameState.game_over_reset()


func _initialize_header() -> void:
	var score_placement : int = GameState.leaderboard.find(GameState.score)
	
	if score_placement == -1: # no placement
		header.text = "ur trash give up. your performance offends me like irl"
	elif score_placement == 0: # highest score
		header.text = "Nice one buddy! Now try getting a job or gf maybe :D"
	else: # general leaderboard placement
		header.text = "I painterd yours yellow so you don't get lost : )"



func initialize_game_over_screen() -> void:
	_initialize_header()
	input_guard_timer.start()
	
	for child in scores_vbox.get_children():
		if child != score_template:
			child.queue_free()
	
	for index in GameState.leaderboard.size():
		var index_score: int = GameState.leaderboard[index]
		
		var new_display: Label = score_template.duplicate()
		new_display.text = "#" + str(index + 1) + "   " + str(index_score)
		new_display.visible = true
		scores_vbox.add_child(new_display)
		
		if index_score == GameState.score:
			new_display.add_theme_color_override("font_color", Color.GOLD)


func set_menu_properties():
	_manager.default_focus = null
	_manager.mouse_reset_data = null
