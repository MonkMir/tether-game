extends RigidBody2D
class_name Dummy

#DESPAWN LOGIC
@onready var player : Node
@onready var area := $Area2D
@onready var camera := get_node("/root/Main/Camera2D")
@onready var healthBar := $HealthBar
@onready var healthIndicatorBar := $HealthBar/HealthIndicatorBar

var attackPower : float
var health : float = 50
var speedLimit : int = 1850
var currentSpeed : float

var timeOutOfBoundsSeconds : float = 0.0
var maxOffscreenTimeSeconds : float = 5.0

func _ready():
	player = get_player()
	area.area_entered.connect(_on_area_entered)
	
	healthIndicatorBar.size = Vector2(600, 90)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	healthIndicatorBar.position = Vector2(-healthIndicatorBar.size.x / 2, -512)
	healthBar._init_health(health)
	


func _physics_process(delta):
	print("Instance ID: ", get_instance_id(), " | Health: ", health)
	healthBar.health = health
	currentSpeed = linear_velocity.length()
	#What is magic number here?
	attackPower = linear_velocity.length() / 35
	
	if get_despawn_rect().has_point(global_position):
		timeOutOfBoundsSeconds = 0.0
	else:
		timeOutOfBoundsSeconds += delta
		if timeOutOfBoundsSeconds >= maxOffscreenTimeSeconds:
			if !player or self != player.newDummy:
				print("despawn")
				queue_free()


func _on_area_entered(_area):
	if _area.is_in_group("enemies"):
		_area.receive_dam_param(attackPower)

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func get_static_camera_rect() -> Rect2:
	var cameraSize = get_viewport_rect().size / camera.zoom
	var cameraCornerTopLeft := Vector2(camera.global_position - (cameraSize / 2))
	
	return Rect2(cameraCornerTopLeft, cameraSize)

func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)
