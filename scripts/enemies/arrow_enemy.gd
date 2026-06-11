extends Enemy


enum State {
	COOLDOWN,
	ATTACK,
	DECELERATE
}

const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 1000
const MAX_SPEED := 900

var state = State.COOLDOWN
var target_point := Vector2.INF
var distance : float = -INF
var prev_distance : float = INF

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
			
			position += (direction * resting_speed) * delta
		State.ATTACK:
			distance = position.distance_to(target_point)
			unspin()
			
			if distance < prev_distance: # checks when point is crossed
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += direction * speed * delta
				prev_distance = distance
			else:
				prev_distance = INF
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


func _track_state_timeout():
	if player != null:
		target_point = player.position
		look_at(target_point)
		#self.rotation += 2 * PI #handles negative rotation overflow
		#self.rotation = fmod(rotation, 2 * PI) #handles rotation overflow
		unspin()
		state = State.ATTACK


func unspin():
	sprite.rotation = 0
	collision.rotation = 0
	# Be deathly cautious adding parameters here that could cause silent errors
	GameState.combo_counter += 1
