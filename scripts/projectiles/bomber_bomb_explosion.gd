extends Area2D

const ATTACK_POWER : int = 20
@onready var _timer := $Timer
@onready var _sprite := $Sprite2D
@onready var _player := get_tree().get_first_node_in_group("player")


func _ready():
	_timer.start()


func _process(delta):
	_sprite.scale += Vector2(6, 6) * delta


func _on_timer_timeout():
	queue_free()


func _on_player_entered(hurtbox):
	if hurtbox.is_in_group("player"):
		_player.receive_dam_param(ATTACK_POWER)
