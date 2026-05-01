extends Area2D

const ATK_POWER := 20

@onready var timer := $Timer
@onready var sprite := $Sprite2D
@onready var player := get_node("/root/Main/Player")

func _ready():
	timer.start()

func _process(delta):
	sprite.scale += Vector2(6, 6) * delta



func _on_timer_timeout():
	queue_free()


func _on_player_entered(area):
	if area.is_in_group("player"):
		player.receive_dam_param(ATK_POWER)
