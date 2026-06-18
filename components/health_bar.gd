extends Node2D


var health : int = 0 : set = set_health
var is_player_health : bool
var is_dummy_health : bool

@onready var timer = $HealthIndicatorBar/Timer
@onready var health_indicator_bar = $HealthIndicatorBar
@onready var trailing_bar = $HealthIndicatorBar/TrailingBar


func _ready():
	set_as_top_level(true)
	
	if evaluate_ancestry_for_group("player") == true:
		is_player_health = true
	
	if evaluate_ancestry_for_group("dummies") == true:
		is_dummy_health = true
	
	# IMPORTANT: health bar's default position is at the top of the screen rather than the player
	# setting it's position manually.
	# This is a really stupid way to do this but too lazy.
	# The source of this bandaid likely has to do with the order of the dummy spawn code
	is_player_health = false
	
	if is_player_health == true or is_dummy_health == true:
		show()
	else:
		hide()


func _process(_delta):
	if get_parent() is not CanvasLayer:
		global_position = get_parent().global_position
		scale = Vector2(.1, .1)
	else:
		show()


func set_health(new_health):
	var prev_health = health
	health = min(health_indicator_bar.max_value, new_health)
	health_indicator_bar.value = health
	
	# WARNING calculate max on the fly rather than hard coding 100
	if health < 100:
		show()
	
	if health < prev_health:
		timer.start()
	else:
		trailing_bar.value = health


# To be called in by the health bar's user
func _init_health(_health):
	health = _health
	health_indicator_bar.value = health
	trailing_bar.value = health


func evaluate_ancestry_for_group(target_group: String) -> bool:
	var ancestor_node = get_parent()
	
	while ancestor_node != null:
		if ancestor_node.is_in_group(target_group):
			return true
		ancestor_node = ancestor_node.get_parent()
	
	return false


func _on_timer_timeout():
	trailing_bar.value = health
