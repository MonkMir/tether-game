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
	if check_ancestry_for_group(self, "player") == true:
		isPlayerHealth = true
	if check_ancestry_for_group(self, "dummies") == true:
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

#To be called in by the health bar's user
func _init_health(_health):
	health = _health
	#healthIndicatorBar.max_value = health #Hey but like why were these here before?
	healthIndicatorBar.value = health
	#damageIndicatorBar.max_value = health
	damageIndicatorBar.value = health
	

func _process(_delta):
	
	if check_ancestry_for_group(self, "dummies") == true:
		print(str(self.health) + "/100 HP")
	
	
	var getGrandparent := get_parent().get_parent()
	if getGrandparent != get_node("/root/Main/Player"):
		global_position = get_parent().global_position 
		scale = Vector2(.1, .1)

func _on_timer_timeout():
	damageIndicatorBar.value = health

func check_ancestry_for_group(targetNode: Node, targetGroup: String) -> bool:
	var ancestorNode = targetNode.get_parent()
	while ancestorNode != null:
		if ancestorNode.is_in_group(targetGroup):
			return true
		ancestorNode = ancestorNode.get_parent()
	return false
