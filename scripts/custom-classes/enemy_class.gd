extends Area2D
class_name Enemy

var enemyName : String
var health : int = 100
var attackPower : int = 0
var scoreReward : int = 10

@onready var player : Node
@onready var healthBar := $HealthBar
@onready var healthIndicatorBar := $HealthBar/HealthIndicatorBar
@onready var sprite := $Sprite2D
@onready var collision = $CollisionShape2D

@export var speed : float


func _ready():
	player = get_player()
	area_entered.connect(_on_area_entered)
	
	healthBar._init_health(health)

func _process(_delta):
	if health <= 0:
		die()

#Deal damage
func _on_area_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(attackPower)

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func receive_dam_param(damage):
	health -= damage
	healthBar.health = health

func die():
	GameState.score += scoreReward
	queue_free()
