extends Dummy


enum State {
	PASSIVE,
	SPECIAL
}

var state := State.PASSIVE:
	set(new_state):
		state = new_state
		if state == State.SPECIAL:
			_set_target()
#const DEFAULT_SPEED_LIMIT : int = 2000 #1200
#const MAX_SPEED_LIMIT : int = 2000
#const MIN_SPEED_LIMIT : int = 1000
var launch_speed : float = 1000 # minimum speed to oneshot
#var direction := Vector2.ZERO
var new_dir : Vector2 # TESTING

func _ready():
	super()


func _physics_process(delta: float):
	super(delta)
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			#print("Arrow Dummy Speed: " + str(current_speed))
			# This condition is important for enemy ragdoll upon player death
			if player:
				if not player.is_tethered:
					state = State.SPECIAL
		State.SPECIAL:
				rotation = linear_velocity.angle()



func _set_target():
	var previous_move_direction = linear_velocity.normalized()
	linear_velocity = launch_speed * previous_move_direction
			
	var best_target : Node2D
	var best_alignment : float = -INF
	var auto_alignment_threshold := 0.8
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if previous_move_direction.dot(enemy.global_position) >= best_alignment:
			best_target = enemy
			best_alignment = previous_move_direction.dot(enemy.global_position)
	if best_alignment >= auto_alignment_threshold:
		var target_direction : Vector2 = global_position.direction_to(best_target.global_position)
		linear_velocity = launch_speed * target_direction
	else:
		linear_velocity = launch_speed * previous_move_direction
	
	custom_integrator = true

#func get_combo_speed_limit() -> float:
#may not be in use
#var percentToMaxCombo = inverse_lerp(0, GameState.MAX_COMBO, GameState.comboCounter)
#return lerp(MIN_SPEED_LIMIT, MAX_SPEED_LIMIT, percentToMaxCombo)
