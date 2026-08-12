extends Projectile


const ATTACK_POWER := 13


@export var purple_shot : AudioStream

var _speed := 60
var _direction : Vector2


func _ready():
	if player:
		_direction = global_position.direction_to(player.global_position)
		AudioManager.play_sound(purple_shot, -5.0)


func _process(delta: float):
	super(delta)
	
	position += _speed * _direction * delta


func _on_player_entered(hurtbox):
	if hurtbox.is_in_group("player"):
		player.receive_damage(ATTACK_POWER)
	
	if player:
		SignalBus.player_hit.emit(player.global_position, position)
