extends Sprite2D

@onready var main := get_node("/root/Main")
@onready var player := get_node("/root/Main/Player")
@export var explosion_scene : PackedScene

var dir : Vector2
var speed := 320.0
const  ACCEL := 3.5
const MIN_SPEED := 20

func _ready():
	if player != null:
		dir = (player.position - position).normalized()

func _process(delta):
	if speed > MIN_SPEED:
		speed -= ACCEL
		position += speed * dir * delta
	else: 
		speed = 0 
		position += MIN_SPEED * dir * delta
		modulate = Color(3, 3, 3, .7)


func _on_timer_timeout():
	queue_free()
	explode()

func explode():
	var explosion := explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	queue_free()
