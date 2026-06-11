extends Dummy


enum State {
	PASSIVE,
	SPECIAL
}

@export var explosion_scene : PackedScene

var state := State.PASSIVE

@onready var self_destruct_timer := $Timer


func _physics_process(delta: float):
	super(delta)
	#Set to zero to allow the explosion to handle the damage
	attack_power = 0
	current_speed = linear_velocity.length()
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			
			if player:
				if player.is_tethered == false:
					state = State.SPECIAL
		State.SPECIAL:
			if self_destruct_timer.time_left == 0:
				self_destruct_timer.start()


func _on_in_trigger_range(_area):
	self_destruct()


func _on_fuse_timer():
	self_destruct()
	queue_free()


func self_destruct():
	var Explosion := explosion_scene.instantiate()
	add_child(Explosion)
	# Who is parent?
	Explosion.reparent(get_parent())
	player.is_tethered = false
	queue_free()
