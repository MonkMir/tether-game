extends Projectile

const ATTACK_POWER : int = 60
#const PLAYER_DAMAGE : int = 20 # make sure this isn't needed before delete
@onready var _timer := $Timer
@onready var _sprite := $Sprite2D


func _ready():
	_timer.start()


func _process(delta):
	super(delta)
	_sprite.scale += Vector2(7, 7) * delta


func _on_area_entered(hurtbox):
	if hurtbox.is_in_group("enemies"):
		hurtbox.receive_dam_param(ATTACK_POWER)


func _on_timer_timeout():
	queue_free()
