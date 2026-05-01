extends Area2D

var type := "arrow"
var health := 100
const ATK_POWER := 15
const SCORE_REWARD := 15

@onready var player := get_node("/root/Main/Player")
@onready var timer := $Timer
@onready var sprite := $Sprite2D
@onready var collision := $Collision
@onready var healthBar := $HealthBar

enum State{
	COOLDOWN,
	ATTACK,
	DECELERATE
}

var state = State.COOLDOWN

var trackedPos := Vector2.INF

var speed : float = BASE_SPEED
const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 1000
const MAX_SPEED := 900

var distance : float = -INF
var prevDistance : float = INF

func _ready():
	healthBar.size = Vector2(600, 90)
	healthBar.pivot_offset = Vector2(-33, -40)
	healthBar._init_health(health)
	

func _process(delta):
	var direction := Vector2.RIGHT.rotated(self.rotation)
	if is_instance_valid(healthBar):
		if healthBar.is_visible_in_tree() == false:
			healthBar.show()
		
	match state:
		
		State.COOLDOWN:
			var restingSpeed := 20.0
			if timer.time_left == 0:
				timer.start() #clean up with await
			position += (direction * restingSpeed) * delta
		
		State.ATTACK:
			distance = position.distance_to(trackedPos)
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
	
	if health <= 0:
		die()

func _track_state_timeout():
	if player != null:
		trackedPos = player.position
		look_at(trackedPos)
		#self.rotation += 2 * PI #handles negative rotation overflow
		#self.rotation = fmod(rotation, 2 * PI) #handles rotation overflow
		unspin()
		state = State.ATTACK
		
func _on_area_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(ATK_POWER)
	

#func spin(spinSpeed:float, delta):
	#sprite.rotate(rad_to_deg(spinSpeed * delta))
	#collision.rotate(rad_to_deg(spinSpeed * delta))

func unspin():
	sprite.rotation = 0
	collision.rotation = 0

func receive_dam_param(damage):
	health -= damage
	healthBar.health = health

func die():
	GameState.score += SCORE_REWARD
	queue_free()
