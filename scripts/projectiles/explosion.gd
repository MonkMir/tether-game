extends Area2D

const ATK_POWER := 60
const PLAYER_DAM := 20

@onready var timer := $Timer
@onready var sprite := $Sprite2D

func _ready():
	timer.start()

func _process(delta):
	sprite.scale += Vector2(7, 7) * delta

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.receive_dam_param(ATK_POWER)
	#elif area.is_in_group("player"):
		#area.get_parent().receive_dam_param(PLAYER_DAM)

func _on_timer_timeout():
	queue_free()
