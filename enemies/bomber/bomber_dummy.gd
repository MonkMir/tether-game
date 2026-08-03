extends Dummy


enum State {
	PASSIVE,
	SPECIAL
}


@export var explosion_scene : PackedScene

var state := State.PASSIVE

@onready var self_destruct_timer := $Timer
@onready var _trigger_zone := $Trigger/TriggerZone


func _ready():
	enemy_name = "bomber"
	super()


func _physics_process(delta: float):
	super(delta)
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			try_special_transition()
		
		State.SPECIAL:
			_trigger_zone.set_deferred("disabled", false)
			if self_destruct_timer.time_left == 0:
				self_destruct_timer.start()


func self_destruct():
	var explosion := explosion_scene.instantiate()
	add_child(explosion)
	# Who is parent?
	explosion.reparent(get_parent())
	queue_free()


func _on_fuse_timer():
	self_destruct()


func _on_trigger_zone_entered(_area):
	self_destruct()
