extends Node2D

@export var is_disabled := false

@export var arrow_scene: PackedScene
@export var bomber_scene: PackedScene
@export var parabolic_scene: PackedScene

var new_enemy
var player : Node
var max_enemies : int = 9

func _ready():
	player = get_player()


func spawn_enemy():
	if is_disabled:
		return
	
	if not player:
		return
	
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	
	# From Outside of Script
	var enemy_rando := randi_range(1, 3)
	
	if enemy_rando == 1:
		new_enemy = arrow_scene.instantiate()
	elif enemy_rando == 2:
		new_enemy = bomber_scene.instantiate()
	elif enemy_rando == 3:
		new_enemy = parabolic_scene.instantiate()
	
	#var difficultyFactor: int = (GameState.score / 10) #Randomized Spawn Location
	var viewport_height = get_viewport_rect().size.y
	var x = 330
	var rand_y: float = randf_range(0, viewport_height)
	
	var speed_increase = 20
	#newEnemy.speed = (speedIncrease * difficultyFactor) + newEnemy.speed
	self.add_child(new_enemy)
	new_enemy.position.x = x
	new_enemy.position.y = rand_y


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")
