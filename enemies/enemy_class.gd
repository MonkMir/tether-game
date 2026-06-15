extends Area2D
class_name Enemy


@export var speed : float

var enemy_name : String
var health : int = 100
var attack_power : int = 0
var score_reward : int = 1

@onready var player : Node
@onready var health_bar := $HealthBar
@onready var health_indicator_bar := $HealthBar/HealthIndicatorBar
@onready var sprite := $Sprite
@onready var collision := $CollisionShape2D
@onready var camera := get_viewport().get_camera_2d()


func _ready():
	player = get_player()
	area_entered.connect(_on_area_entered)
	health_bar._init_health(health)
	health_indicator_bar.size = Vector2(150, 25)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	health_indicator_bar.position = Vector2(-health_indicator_bar.size.x / 2, -128)


func _process(_delta):
	if !player and get_despawn_rect().has_point(global_position) == false:
		queue_free()
	
	if not health_bar:
		return
	
	if health <= 0:
		die()


# Deal damage
func _on_area_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(attack_power)


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func get_static_camera_rect() -> Rect2:
	var camera_size = get_viewport_rect().size / camera.zoom
	var camera_corner_top_left := Vector2(camera.global_position - (camera_size / 2))
	
	return Rect2(camera_corner_top_left, camera_size)


func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)


func receive_dam_param(damage):
	health -= damage
	health_bar.health = health


func die():
	GameState.score += score_reward
	queue_free()
