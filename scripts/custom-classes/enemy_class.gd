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
@onready var collision := $CollisionShape2D
@onready var camera := get_viewport().get_camera_2d()

@export var speed : float

func _ready():
	player = get_player()
	area_entered.connect(_on_area_entered)
	
	healthBar._init_health(health)
	
	healthIndicatorBar.size = Vector2(600, 90)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	healthIndicatorBar.position = Vector2(-healthIndicatorBar.size.x / 2, -512)

func _process(_delta):
	if !player and get_despawn_rect().has_point(global_position) == false:
		queue_free()
	
	
	if health <= 0:
		die()

#Deal damage
func _on_area_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(attackPower)

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func get_static_camera_rect() -> Rect2:
	var cameraSize = get_viewport_rect().size / camera.zoom
	var cameraCornerTopLeft := Vector2(camera.global_position - (cameraSize / 2))
	
	return Rect2(cameraCornerTopLeft, cameraSize)

func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)

func receive_dam_param(damage):
	health -= damage
	healthBar.health = health

func die():
	GameState.score += scoreReward
	queue_free()
