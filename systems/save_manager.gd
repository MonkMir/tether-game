extends Node


const SAVE_PATH: String = "user://save_data.ini"


func _ready():
	_load_game_data()


func save_game_data() -> void:
	var leaderboard_data = ConfigFile.new()
	leaderboard_data.set_value("Scores", "high_scores", GameState.leaderboard)
	leaderboard_data.save(SAVE_PATH)


func _load_game_data() -> void:
	var save_file = ConfigFile.new()
	var error_code = save_file.load(SAVE_PATH)
	if error_code == OK:
		GameState.leaderboard = save_file.get_value("Scores", "high_scores", GameState.leaderboard)
