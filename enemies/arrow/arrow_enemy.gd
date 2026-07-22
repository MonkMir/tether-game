extends Enemy


enum State {
	COOLDOWN,
	ATTACK,
	DECELERATE
}

const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 400
const MAX_SPEED := 300

var state = State.COOLDOWN
var _is_in_bounds := false
var _target_point := Vector2.INF
var _distance_to_target : float = -INF
var _prior_distance_to_target : float = INF

@onready var timer := $Timer


func _ready():
	super()
	enemy_name = "arrow"
	speed = BASE_SPEED
	attack_power = 15
	


func _process(delta: float):
	super(delta)
	var direction := Vector2.RIGHT.rotated(self.rotation)
	
	match state:
		State.COOLDOWN:
			var resting_speed := 20.0
			
			if timer.time_left == 0:
				timer.start() # clean up with await
			
			%ThrusterParticles.emitting = false
			position += (direction * resting_speed) * delta
		State.ATTACK:
			%ThrusterParticles.emitting = true
			_distance_to_target = position.distance_to(_target_point)
			unspin()
			
			if _distance_to_target < _prior_distance_to_target:
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += direction * speed * delta
				_prior_distance_to_target = _distance_to_target
			else:
				_prior_distance_to_target = INF
				state = State.DECELERATE
			
		State.DECELERATE:
			collision.rotation = lerp(collision.rotation, PI, .07)
			sprite.rotation = lerp(sprite.rotation, PI, .07)
			speed -= DECELERATION * delta
			
			if speed > 0:
				position += direction * speed * delta
			else:
				speed = BASE_SPEED
				state = State.COOLDOWN
	
	if not _is_in_bounds:
		if get_static_camera_rect().has_point(position):
			_is_in_bounds = true
	else:
		position = position.clamp(get_static_camera_rect().position, get_static_camera_rect().end)


func _track_state_timeout():
	if not player:
		return
	
	_target_point = player.position
	look_at(_target_point)
	#self.rotation += 2 * PI #handles negative rotation overflow
	#self.rotation = fmod(rotation, 2 * PI) #handles rotation overflow
	unspin()
	state = State.ATTACK


func unspin():
	sprite.rotation = 0
	collision.rotation = 0
	
	# Be deathly cautious adding parameters here that could cause silent errors
	GameState.combo_counter += 1
