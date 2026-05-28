extends Node2D

#IMPORTANT: health bar's default position is at the top of the screen rather than the player
# setting it's position manually.

@onready var timer = $HealthIndicatorBar/Timer
@onready var healthIndicatorBar = $HealthIndicatorBar
@onready var damageIndicatorBar = $HealthIndicatorBar/DamageIndicatorBar


var health : int = 0 : set = set_health
var isPlayerHealth : bool
var isDummyHealth : bool

func _ready():
	set_as_top_level(true)
	if evaluate_ancestry_for_group("player") == true:
		isPlayerHealth = true
	if evaluate_ancestry_for_group("dummies") == true:
		isDummyHealth = true
	
	if isPlayerHealth == true or isDummyHealth == true:
		show()
	else:
		hide()

func set_health(newHealth):
	var prevHealth = health
	health = min(healthIndicatorBar.max_value, newHealth)
	healthIndicatorBar.value = health
	#WARNING calculate max on the fly rather than hard coding 100
	if health < 100:
		show()
	
	if health <= 0:
		queue_free()
	if health < prevHealth:
		timer.start()
	else:
		damageIndicatorBar.value = health

func _process(_delta):
	if !isPlayerHealth:
		global_position = get_parent().global_position 
		scale = Vector2(.1, .1)

func _on_timer_timeout():
	damageIndicatorBar.value = health

#To be called in by the health bar's user
func _init_health(_health):
	health = _health
	#healthIndicatorBar.max_value = health #These lines are bad if you want to pass in a part full bar
	healthIndicatorBar.value = health
	#damageIndicatorBar.max_value = health
	damageIndicatorBar.value = health

func evaluate_ancestry_for_group(targetGroup: String) -> bool:
	var ancestorNode = get_parent()
	while ancestorNode != null:
		if ancestorNode.is_in_group(targetGroup):
			return true
		ancestorNode = ancestorNode.get_parent()
	return false
