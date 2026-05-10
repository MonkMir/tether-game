extends Area2D

#BUG enemy sometimes gets stuck. in this case, previousState = null which suggests
#that it never leaves GO_TO_PATH 
#
#BUG clear shot interval code. I like how it works
#
#BUG make spin_and_transition use time based transition rather than rate based.
#maybe add an optional lerp variation?
#
#
#
#

var type := "parabolic"
var health := 100
const ATK_POWER := 7
const SCORE_REWARD := 15

@onready var main := get_node("/root/Main")
@onready var player := get_node("/root/Main/Player")
@export var dart_scene : PackedScene
@onready var shotIntervalTimer := $ShotInterval
@onready var shotClusterTimer := $ShotCluster
@onready var collision1 := $Collision
@onready var collision2 := $CollisionShape2D
@onready var healthBar := $HealthBar
@onready var healthIndicatorBar := $HealthBar/HealthIndicatorBar
@onready var path := $TransformDecoupler/Path2D
@onready var pathFollow := $TransformDecoupler/Path2D/PathFollow2D

enum State{
	GO_TO_PATH,
	ATTACK,
	REPOSITION
}

var state = State.GO_TO_PATH
var previousState = null

var randomPathLength := INF
var previousDistanceToTarget := INF
var targetPathProgress : float
var targetPointOnPath := Vector2(INF, INF) #should be generated at the end of state during transition

var reachedTargetSpin : bool = false

var speed : float = BASE_SPEED
var currentSpinDegPerSec : float = INF

var invertShotArc : int = 1

const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 1000
const MAX_SPEED := 1200

func _ready():
	healthIndicatorBar.size = Vector2(600, 90)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	healthIndicatorBar.position = Vector2(-healthIndicatorBar.size.x / 2, -512)
	healthBar._init_health(health)

func _process(delta):
	if is_instance_valid(healthBar):
		if healthBar.is_visible_in_tree() == false:
			healthBar.show()
		
	match state:
		
		State.GO_TO_PATH:
			spin_and_transition(1080.0, delta)
			enable_collision(false)
			if targetPointOnPath == Vector2(INF, INF):
				targetPointOnPath = generate_new_path_target()
			
			var directionToTarget = (targetPointOnPath - position).normalized()
			var distanceToTarget = position.distance_to(targetPointOnPath)
			
			
			if distanceToTarget >= speed * delta:
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += directionToTarget * speed * delta
			else:
				enable_collision(true)
				position = targetPointOnPath
				speed = 0.0
				
				pathFollow.progress = path.curve.get_closest_offset(path.to_local(global_position))
				targetPointOnPath = generate_new_path_target()
				state = State.ATTACK
			
			
#Speed should probably be used in this state...
		State.REPOSITION:
			#would be better if transition rate was total time to transition instead of degpersec
			if previousState == State.GO_TO_PATH:
				spin_and_transition(250.0, delta, 500.0)
			else:
				spin_and_transition(250.0, delta)
				
			if currentSpinDegPerSec == 250.0:
				reachedTargetSpin = true
			
			if reachedTargetSpin == true:
				move_along_path()
			
			if position.is_equal_approx(targetPointOnPath):
				position = pathFollow.global_position
				reachedTargetSpin = false
				
				previousState = State.REPOSITION
				targetPointOnPath = generate_new_path_target()
				state = State.ATTACK
				
		State.ATTACK:
			spin_and_transition(1420.0, delta, 800.0)
			
			if currentSpinDegPerSec == 1420.0:
				reachedTargetSpin = true
			
			if reachedTargetSpin == true:
				if shotIntervalTimer.time_left == 0.0 and player != null:
					shotIntervalTimer.start()
					
					previousState = State.ATTACK
					
					targetPointOnPath = generate_new_path_target()
					state = State.REPOSITION
	
	
	if health <= 0:
		die()

		
func _on_area_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(ATK_POWER)

#Note: if you want to reuse this function in other project, you should refactor to use secondsToTransition
func spin_and_transition(targetSpinDegPerSec, delta, spinTransitionDegPerSec = 200.0) -> void:
	#Declare currentSpinDegPerSec as INF to bypass or 0 not to bypass the initial spin transition
	if currentSpinDegPerSec == INF:
		currentSpinDegPerSec = targetSpinDegPerSec
	else:
		#currentSpinDegPerSec != targetSpinDegPerSec
		currentSpinDegPerSec = move_toward(currentSpinDegPerSec, targetSpinDegPerSec,
		spinTransitionDegPerSec * delta)
		
	#use a Node2D as a container to replace self if more specificity is needed
	self.rotate(deg_to_rad(currentSpinDegPerSec) * delta)

func move_along_path():
	##should I use delta here?
	pathFollow.progress = lerp(pathFollow.progress, targetPathProgress, .05)
	position = pathFollow.global_position

func enable_collision(_isEnabled : bool) -> void:
	collision1.set_deferred("disabled", !_isEnabled)
	collision2.set_deferred("disabled", !_isEnabled)

func spawn_dart():
	var newDart := dart_scene.instantiate()
	newDart.position = position
	newDart.plusOrMinus *= invertShotArc
	main.add_child(newDart)

func receive_dam_param(damage):
	health -= damage
	healthBar.health = health

func die():
	GameState.score += SCORE_REWARD
	queue_free()
	#maybe spawn_score_change_particle?

#func get_path_length():
	#return path.curve.get_baked_length()
	
func generate_path_progress() -> float:
	var maxProgress : float = path.curve.get_baked_length()
	var randomProgress : float = randf_range(0.0, maxProgress)
	return randomProgress

func generate_new_path_target() -> Vector2:
	var _targetPathProgress := generate_path_progress()
	
	var localPathTarget : Vector2 = path.curve.sample_baked(_targetPathProgress)
	var randomPathTarget = path.to_global(localPathTarget)
	
	#basically a setter function 
	targetPathProgress = _targetPathProgress
	
	return randomPathTarget


func _on_shot_interval_timeout():
	var shotsRemaining : int = 3
	invertShotArc *= -1
	
	if shotsRemaining == 0:
		pass
	else:
		for shot in shotsRemaining:
			shotClusterTimer.start()
			await shotClusterTimer.timeout



func _on_shot_cluster_timeout():
	spawn_dart()
