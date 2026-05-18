extends Node2D

@export var arrowScene: PackedScene
@export var bomberScene: PackedScene
@export var parabolicScene: PackedScene

var newEnemy 

func _ready():
	spawn_enemy()

func spawn_enemy():
	
	#From Outside of Script
	
	var enemyRando := 1#randi_range(1, 3)
	
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
