extends RigidBody2D

@export var explosion_scene : PackedScene

@onready var main := get_node("/root/Main")
@onready var player := get_node("/root/Main/Player")
@onready var spring := get_node("/root/Main/Player/Tether")
@onready var timer := $Timer

enum State{
	PASSIVE,
	SPECIAL
}
var state := State.PASSIVE


func _physics_process(_delta):
	
	match state:
		State.PASSIVE:
			if is_instance_valid(player):
				if spring.node_b == NodePath():
					state = State.SPECIAL
			
		State.SPECIAL:
			if timer.time_left == 0:
				timer.start()

func _on_in_trigger_range(area):
	explode()
	
func _on_fuse_timer():
	explode()
	queue_free()
	
func explode():
	var explosion := explosion_scene.instantiate()
	add_child(explosion)
	explosion.reparent(main)
	queue_free()
