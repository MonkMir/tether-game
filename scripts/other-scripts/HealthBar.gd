extends Node2D

#IMPORTANT: health bar's default position is at the top of the screen rather than the player
# setting it's position manually.

@onready var timer = $HealthIndicatorBar/Timer
@onready var healthIndicatorBar = $HealthIndicatorBar
@onready var damageIndicatorBar = $HealthIndicatorBar/DamageIndicatorBar


var health = 0 : set = set_health
var isPlayerHealth : bool

func _ready():
	set_as_top_level(true)
	if get_ancestry_flag(self, "player") == true:
		isPlayerHealth = true
	
	if isPlayerHealth == true:
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

func get_ancestry_flag(targetNode: Node, targetGroup : String) -> bool:
	var player_nodes = get_tree().get_nodes_in_group(targetGroup)
	
	for player in player_nodes:
		if player.is_ancestor_of(targetNode):
			return true
			
	return false
