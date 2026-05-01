extends ProgressBar


@onready var timer = $Timer
@onready var damageBar = $DamageIndicatorBar


var health = 0 : set = set_health

func _ready():
	set_as_top_level(true)

func set_health(newHealth):
	var prevHealth = health
	health = min(max_value, newHealth)
	value = health
	
	if health <= 0:
		queue_free()
	if health < prevHealth:
		timer.start()
	else:
		damageBar.value = health

func _init_health(_health): #I don't like that _health starts with an underscore
	health = _health
	max_value = health
	value = health
	damageBar.max_value = health
	damageBar.value = health

func _process(_delta):
		
	var getGrandparent := get_parent().get_parent()
	if getGrandparent != get_node("/root/Main/Player"):
		global_position = get_parent().global_position 
		scale = Vector2(.1, .1)

func _on_timer_timeout():
	damageBar.value = health
