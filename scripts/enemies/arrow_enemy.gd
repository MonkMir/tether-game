extends Enemy

@onready var timer := $Timer

enum State{
	COOLDOWN,
	ATTACK,
	DECELERATE
}

var state = State.COOLDOWN

var targetPoint := Vector2.INF

const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 1000
const MAX_SPEED := 900

var distance : float = -INF
var prevDistance : float = INF

func _ready():
	super()
	enemyName = "arrow"
	speed = BASE_SPEED
	attackPower = 15
	
	healthIndicatorBar.size = Vector2(600, 90)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	healthIndicatorBar.position = Vector2(-healthIndicatorBar.size.x / 2, -512)


func _process(delta):
	super(delta)
	var direction := Vector2.RIGHT.rotated(self.rotation)
	
	match state:
		
		State.COOLDOWN:
			var restingSpeed := 20.0
			if timer.time_left == 0:
				timer.start() #clean up with await
			position += (direction * restingSpeed) * delta
		
		State.ATTACK:
			distance = position.distance_to(targetPoint)
			unspin()
			if distance < prevDistance: #checks when point is crossed
				speed = min(speed + SPEED_GROWTH * delta, MAX_SPEED)
				position += direction * speed * delta
				prevDistance = distance
			else:
				prevDistance = INF
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
		targetPoint = player.position
		look_at(targetPoint)
		#self.rotation += 2 * PI #handles negative rotation overflow
		#self.rotation = fmod(rotation, 2 * PI) #handles rotation overflow
		unspin()
		state = State.ATTACK
		

func unspin():
	sprite.rotation = 0
	collision.rotation = 0
	
	#Be deathly cautious adding parameters here that could cause silent errors
	GameState.comboCounter += 1
