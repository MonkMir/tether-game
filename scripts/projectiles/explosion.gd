extends Projectile

const ATK_POWER := 60
const PLAYER_DAM := 20

@onready var timer := $Timer
@onready var sprite := $Sprite2D

func _ready():
	timer.start()

func _process(delta):
	super(delta)
	sprite.scale += Vector2(7, 7) * delta

func _on_area_entered(_area):
	if _area.is_in_group("enemies"):
		_area.receive_dam_param(ATK_POWER)

func _on_timer_timeout():
	queue_free()
