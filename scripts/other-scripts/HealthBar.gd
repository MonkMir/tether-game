extends Node2D

#IMPORTANT: health bar's default position is at the top of the screen rather than the player
# setting it's position manually.

@onready var timer = $HealthIndicatorBar/Timer
@onready var healthIndicatorBar = $HealthIndicatorBar
@onready var damageIndicatorBar = $HealthIndicatorBar/DamageIndicatorBar


var health = 0 : set = set_health

func _ready():
	set_as_top_level(true)

func set_health(newHealth):
	var prevHealth = health
	health = min(healthIndicatorBar.max_value, newHealth)
	healthIndicatorBar.value = health
	
	if health <= 0:
		queue_free()
	if health < prevHealth:
		timer.start()
	else:
		damageIndicatorBar.value = health

func _init_health(_health): #I don't like that _health starts with an underscore
	health = _health
	healthIndicatorBar.max_value = health
	healthIndicatorBar.value = health
	damageIndicatorBar.max_value = health
	damageIndicatorBar.value = health

func _process(_delta):
		
	var getGrandparent := get_parent().get_parent()
	if getGrandparent != get_node("/root/Main/Player"):
		global_position = get_parent().global_position 
		scale = Vector2(.1, .1)

func _on_timer_timeout():
	damageIndicatorBar.value = health
