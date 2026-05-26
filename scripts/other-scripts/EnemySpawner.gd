extends Node2D

@export var arrowScene: PackedScene
@export var bomberScene: PackedScene
@export var parabolicScene: PackedScene

var newEnemy 
var player : Node

var maxEnemies : int = 15


func _ready():
	player = get_player()
	spawn_enemy()

func spawn_enemy():
	if !player:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= maxEnemies:
		return
	
	#From Outside of Script
	
	var enemyRando := randi_range(1, 3)
	
	if enemyRando == 1:
		newEnemy = arrowScene.instantiate()
	elif enemyRando == 2:
		newEnemy = bomberScene.instantiate()
	elif enemyRando == 3:
		newEnemy = parabolicScene.instantiate()
	
	#var difficultyFactor: int = (GameState.score / 10)
	
	
	#Randomized Spawn Location
	var viewportHeight = get_viewport_rect().size.y
	var x = 1200
	var randY: float = randf_range(0, viewportHeight)
	
	#Speed Growth
	var speedIncrease = 20
	
	#newEnemy.speed = (speedIncrease * difficultyFactor) + newEnemy.speed
	
	self.add_child(newEnemy)
	newEnemy.position.x = x
	newEnemy.position.y = randY

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")
