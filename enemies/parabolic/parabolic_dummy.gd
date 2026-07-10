extends Dummy


enum State {
	PASSIVE,
	SPECIAL,
	REST
}

@export var rebound_force : int = 350

var state := State.PASSIVE:
	set(new_state):
		state = new_state
		if state == State.SPECIAL:
			_init_special_state()

var _rebound_direction : Vector2

func _ready():
	super()
	attack_power = 75


func _physics_process(delta: float):
	super(delta)
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			
			if player:
				if player.is_tethered == false:
					state = State.SPECIAL
		State.SPECIAL:
			apply_central_force(rebound_force * _rebound_direction)
			angular_velocity = 20

	
	
func _init_special_state():
	var previous_move_direction : Vector2 = linear_velocity.normalized()
	_rebound_direction = - (get_closest_axis(previous_move_direction))
	
	gravity_scale = 0.0
	wrecking_ball_mode = false
	attack_power = 100



func get_closest_axis(velocity: Vector2) -> Vector2:
	if velocity == Vector2.ZERO:
		return Vector2.ZERO
		
	if abs(velocity.x) > abs(velocity.y):
		return Vector2.RIGHT if velocity.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if velocity.y > 0 else Vector2.UP
