extends Enemy

enum State {
	GO_TO_PATH,
	ATTACK,
	REPOSITION,
}

@export_group("Sound Effects")
@export var disengage_maching_sfx : AudioStream

@export_group("Movement Constants")
@export var SPEED_GROWTH := 400
@export var MAX_SPEED := 900
@export var max_travel_ratio := 0.3

@export_group("Spin Speeds")
@export var SPIN_SPEED_GO_TO_PATH := 30.0
@export var SPIN_SPEED_ATTACK_TARGET := 5.0
@export var SPIN_SPEED_REPOSITION_TARGET := 20.0

@export_group("Durations")
@export var ATTACK_DURATION := 1.8
@export var REPOSITION_DURATION := 2.2

@export var dart_scene : PackedScene

var state = State.GO_TO_PATH:
	set(new_state):
		if new_state == State.ATTACK:
			AudioManager.play_sound(disengage_maching_sfx, -20.0)
		state = new_state
var previous_state = null

var target_point_on_path := Vector2(INF, INF)
var spin_speed : float = SPIN_SPEED_GO_TO_PATH

var state_tween: Tween
var target_path_ratio: float = INF
var old_position: Vector2
var movement_direction : Vector2 = Vector2.RIGHT

@onready var hitbox := $Collision
@onready var path := $TransformDecoupler/Path2D
@onready var path_follow := %PathFollow2D
@onready var brake_particles := %BrakeParticles

func _ready():
	super()
	enemy_name = "parabolic"
	attack_power = 10

func _process(delta: float):
	super(delta)
	
	rotation += spin_speed * delta
	
	if state == State.REPOSITION and delta > 0.0:
		speed = global_position.distance_to(old_position) / delta
	old_position = global_position
	
	match state:
		State.GO_TO_PATH:
			enable_collision(false)
			
			if target_point_on_path == Vector2(INF, INF):
				path_follow.progress_ratio = randf_range(0.16, 0.64)
				target_point_on_path = path_follow.global_position
			
			var direction_to_target = (target_point_on_path - position).normalized()
			var distance_to_target = position.distance_to(target_point_on_path)
			
			if distance_to_target >= speed * delta:
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += direction_to_target * speed * delta
			else:
				enable_collision(true)
				position = target_point_on_path
				target_path_ratio = path_follow.progress_ratio
				movement_direction = direction_to_target
				_spawn_brake_particles()
				_update_target_ratio()
				
				change_state(State.ATTACK)
				_start_attack_sequence()

		State.REPOSITION: # See _start_path_movement()
			position = path_follow.global_position
			
			var position_delta = global_position - old_position
			if position_delta.length_squared() > 0.0:
				movement_direction = position_delta.normalized()

		State.ATTACK: # See _start_attack_sequence()
			if not player:
				if state_tween:
					state_tween.kill()
					state_tween = null
				spin_speed = move_toward(spin_speed, SPIN_SPEED_ATTACK_TARGET, 10.0 * delta)
				return

func change_state(new_state: State) -> void:
	previous_state = state
	state = new_state

func _start_path_movement() -> void:
	if state_tween:
		state_tween.kill()
		
	state_tween = create_tween().bind_node(self)
	state_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	state_tween.tween_property(
		path_follow, "progress_ratio", target_path_ratio, REPOSITION_DURATION)
	state_tween.parallel().tween_property(
		self, "spin_speed", SPIN_SPEED_REPOSITION_TARGET, REPOSITION_DURATION)
	
	state_tween.tween_callback(func():
		_spawn_brake_particles()
		change_state(State.ATTACK)
		_start_attack_sequence()
	)

func _start_attack_sequence():
	if state_tween:
		state_tween.kill()
	
	state_tween = create_tween().bind_node(self)
	state_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	state_tween.tween_property(
		self, "spin_speed", SPIN_SPEED_ATTACK_TARGET, ATTACK_DURATION)
	
	state_tween.tween_callback(func():
		if not player:
			return
		
		_fire()
		_update_target_ratio()
		change_state(State.REPOSITION)
		position = path_follow.global_position
		_start_path_movement()
	)

func _spawn_brake_particles() -> void:
	brake_particles.initial_velocity_min = speed * 0.1
	brake_particles.initial_velocity_max = speed * 0.2 
	brake_particles.global_position = global_position
	brake_particles.direction = movement_direction
	brake_particles.restart()

func enable_collision(is_enabled : bool) -> void:
	hitbox.set_deferred("disabled", not is_enabled)

func _fire():
	var new_dart := dart_scene.instantiate()
	new_dart.position = position
	# idk where I'm adding this but oh well
	get_parent().add_child(new_dart)

func _update_target_ratio() -> void:
	var current_ratio: float = path_follow.progress_ratio
	target_path_ratio = randf_range(
		current_ratio - max_travel_ratio, current_ratio + max_travel_ratio)
