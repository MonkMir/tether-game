extends Projectile


const ATTACK_POWER := 5

var _speed := 1.5
var _direction : Vector2


func _ready():
	if player:
		_direction = global_position.direction_to(player.global_position)


func _process(delta: float):
	super(delta)
	rotation += 20 * delta
	
	position += _speed * _direction


func _on_player_entered(hurtbox):
	if hurtbox.is_in_group("player"):
		player.receive_dam_param(ATTACK_POWER)
