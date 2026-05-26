extends Area2D
class_name Projectile

@onready var player : Node
@onready var area := $Area2D
@onready var camera := get_node("/root/Main/Camera2D")

var attackPower : float

var speedLimit : int = 1850
var currentSpeed : float

var timeOutOfBoundsSeconds : float = 0.0
var maxOffscreenTimeSeconds : float = 3.0

func _ready():
	player = get_player()

func _process(delta):
	if get_despawn_rect().has_point(global_position):
		timeOutOfBoundsSeconds = 0.0
	else:
		timeOutOfBoundsSeconds += delta
		if timeOutOfBoundsSeconds >= maxOffscreenTimeSeconds:
			queue_free()


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func get_static_camera_rect() -> Rect2:
	var cameraSize = get_viewport_rect().size / camera.zoom
	var cameraCornerTopLeft := Vector2(camera.global_position - (cameraSize / 2))
	
	return Rect2(cameraCornerTopLeft, cameraSize)

func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)
