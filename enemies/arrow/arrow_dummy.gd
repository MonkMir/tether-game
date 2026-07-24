extends Dummy


enum State {
	WRECKING_BALL,
	SPECIAL
}


@onready var _thruster_particles = %ThrusterParticles

var state := State.WRECKING_BALL:
	set(new_state):
		state = new_state
		if state == State.SPECIAL:
			_thruster_particles.show()
			_set_target()
#const DEFAULT_SPEED_LIMIT : int = 2000 #1200
#const MAX_SPEED_LIMIT : int = 2000
#const MIN_SPEED_LIMIT : int = 1000
var launch_speed : float = 1000 # minimum speed to oneshot

func _ready():
	super()
	_thruster_particles.hide()


func _physics_process(delta: float):
	super(delta)
	
	match state:
		
		State.WRECKING_BALL:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			try_special_transition()
		
		State.SPECIAL:
			attack_power = 75
			rotation = linear_velocity.angle()




func _set_target() -> void:
	var previous_move_direction : Vector2 = linear_velocity.normalized()
	linear_velocity = launch_speed * previous_move_direction
	
	var best_target : Node2D
	var best_alignment : float = -INF
	var auto_alignment_threshold := 0.75
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_position: Vector2 = enemy.global_position
		if not get_static_camera_rect().has_point(enemy_position):
			continue 
		
		if previous_move_direction.dot(enemy_position) >= best_alignment:
			best_target = enemy
			best_alignment = previous_move_direction.dot(enemy_position)
	
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
