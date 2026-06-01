extends Node

var score = 0
var is_pausable = false
var is_game_over = false


##COMBO DATA
var comboCounter : int = 0
const MAX_COMBO : int = 24

func _process(_delta):
	#print("Combo: " + str(GameState.comboCounter))
	
	comboCounter = clampi(comboCounter, 0, MAX_COMBO)


func reset_values():
	score = 0 
	is_game_over = false
