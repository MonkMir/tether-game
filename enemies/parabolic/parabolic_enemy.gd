extends Enemy


# BUG enemy sometimes gets stuck. in this case, previousState = null which suggests
# that it never leaves GO_TO_PATH. edit: remote tab says it's stuck in REPOSITION
#
# BUG make spin_and_transition use time based transition rather than rate based.
# maybe add an optional lerp variation? Also maybe use a tween instead

enum State {
	GO_TO_PATH,
	ATTACK,
	REPOSITION
}

const SPEED_GROWTH := 400
const BASE_SPEED := 500
const DECELERATION := 700
const MAX_SPEED := 900

@export var dart_scene : PackedScene

var state = State.GO_TO_PATH
var previous_state = null
var random_path_length := INF
var previous_distance_to_target := INF
var target_path_progress : float
var target_point_on_path := Vector2(INF, INF) # should be generated at the end of state during transition
var reached_target_spin : bool = false
var current_spin_deg_per_sec : float = INF



@onready var shot_interval_timer := $ShotInterval
@onready var shot_cluster_timer := $ShotCluster
@onready var collision1 := $Collision
@onready var collision2 := $CollisionShape2D
@onready var path := $TransformDecoupler/Path2D
@onready var path_follow := $TransformDecoupler/Path2D/PathFollow2D


func _ready():
	super()
	enemy_name = "parabolic"
	attack_power = 5


func _process(delta: float):
	super(delta)
	
	match state:
		State.GO_TO_PATH:
			spin_and_transition(1080.0, delta)
			enable_collision(false)
			
			if target_point_on_path == Vector2(INF, INF):
				target_point_on_path = generate_new_path_target()
			
			var direction_to_target = (target_point_on_path - position).normalized()
			var distance_to_target = position.distance_to(target_point_on_path)
			
			if distance_to_target >= speed * delta:
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += direction_to_target * speed * delta
			else:
				enable_collision(true)
				position = target_point_on_path
				speed = 0.0
				path_follow.progress = path.curve.get_closest_offset(path.to_local(global_position))
				target_point_on_path = generate_new_path_target()
				state = State.ATTACK
		# Speed should probably be used in this state...
		State.REPOSITION:
			# would be better if transition rate was total time to transition instead of degpersec
			if previous_state == State.GO_TO_PATH:
				spin_and_transition(250.0, delta, 500.0)
			else:
				spin_and_transition(250.0, delta)
			
			if current_spin_deg_per_sec == 250.0:
				reached_target_spin = true
			
			if reached_target_spin == true:
				move_along_path()
			
			if position.is_equal_approx(target_point_on_path):
				position = path_follow.global_position
				reached_target_spin = false
				previous_state = State.REPOSITION
				target_point_on_path = generate_new_path_target()
				state = State.ATTACK
		State.ATTACK:
			spin_and_transition(1420.0, delta, 800.0)
			
			if current_spin_deg_per_sec == 1420.0:
				reached_target_spin = true
			
			if reached_target_spin == true:
				if shot_interval_timer.time_left == 0.0 and player != null:
					shot_interval_timer.start()
				
				previous_state = State.ATTACK
				target_point_on_path = generate_new_path_target()
				state = State.REPOSITION


# Note: if you want to reuse this function in other project, you should refactor to use secondsToTransition
func spin_and_transition(target_spin_deg_per_sec, delta, spin_transition_deg_per_sec = 200.0) -> void:
	# Declare currentSpinDegPerSec as INF to bypass or 0 not to bypass the initial spin transition
	if current_spin_deg_per_sec == INF:
		current_spin_deg_per_sec = target_spin_deg_per_sec
	else:
		# currentSpinDegPerSec != targetSpinDegPerSec
		current_spin_deg_per_sec = move_toward(current_spin_deg_per_sec, target_spin_deg_per_sec, spin_transition_deg_per_sec * delta)
	
	# use a Node2D as a container to replace self if more specificity is needed
	self.rotate(deg_to_rad(current_spin_deg_per_sec) * delta)


func move_along_path():
	# #should I use delta here?
	path_follow.progress = lerp(path_follow.progress, target_path_progress, .05)
	position = path_follow.global_position


func enable_collision(is_enabled : bool) -> void:
	collision1.set_deferred("disabled", !is_enabled)


func spawn_dart():
	var new_dart := dart_scene.instantiate()
	new_dart.position = position
	
	# where are we adding this?
	get_parent().add_child(new_dart)


func generate_path_progress() -> float:
	var max_progress : float = path.curve.get_baked_length()
	var random_progress : float = randf_range(0.0, max_progress)
	
	return random_progress


func generate_new_path_target() -> Vector2:
	var _target_path_progress := generate_path_progress()
	var local_path_target : Vector2 = path.curve.sample_baked(_target_path_progress)
	var random_path_target = path.to_global(local_path_target)
	
	# basically a setter function
	target_path_progress = _target_path_progress
	
	return random_path_target


func _on_shot_interval_timeout():
	spawn_dart()
