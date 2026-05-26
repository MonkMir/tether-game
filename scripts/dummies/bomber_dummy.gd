extends Dummy

@export var explosion_scene : PackedScene

@onready var main := get_node("/root/Main")
@onready var selfDestructTimer := $Timer

enum State{
	PASSIVE,
	SPECIAL
}
var state := State.PASSIVE


func _physics_process(delta):
	super(delta)
	#Set to zero to allow the explosion to handle the damage 
	attackPower = 0
	
	
	currentSpeed = linear_velocity.length()
	
	match state:
		State.PASSIVE:
			if currentSpeed > speedLimit:
				linear_velocity = linear_velocity.normalized() * speedLimit
			
			if player:
				if player.isTethered == false:
					state = State.SPECIAL
			
		State.SPECIAL:
			if selfDestructTimer.time_left == 0:
				selfDestructTimer.start()

func _on_in_trigger_range(_area):
	self_destruct()

func _on_fuse_timer():
	self_destruct()
	queue_free()
	
func self_destruct():
	var explosion := explosion_scene.instantiate()
	add_child(explosion)
	explosion.reparent(main)
	
	player.isTethered = false
	queue_free()
