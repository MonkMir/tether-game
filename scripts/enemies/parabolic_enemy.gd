extends Area2D

var type := "parabolic"
var health := 100
const ATK_POWER := 7
const SCORE_REWARD := 15

@onready var player := get_node("/root/Main/Player")
@onready var timer := $Timer
@onready var sprite := $Sprite2D
@onready var collision := $Collision
@onready var healthBar := $HealthBar
@onready var healthIndicatorBar := $HealthBar/HealthIndicatorBar

enum State{
	REPOSITION
}

var state = State.REPOSITION


var speed : float = BASE_SPEED
const SPEED_GROWTH := 500
const BASE_SPEED := 100
const DECELERATION := 1000
const MAX_SPEED := 900

func _ready():
	healthIndicatorBar.size = Vector2(600, 90)
	#replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	healthIndicatorBar.position = Vector2(-healthIndicatorBar.size.x / 2, -512)
	healthBar._init_health(health)

func _process(delta):
	var direction := Vector2.RIGHT.rotated(self.rotation)
	if is_instance_valid(healthBar):
		if healthBar.is_visible_in_tree() == false:
			healthBar.show()
		
	match state:
		
		State.REPOSITION:
			pass
	
	if health <= 0:
		die()

		
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
