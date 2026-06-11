extends Projectile


const ATTACK_POWER := 5

var start_point : Vector2
var end_point : Vector2
var mid_point: Vector2
var control_point : Vector2
var perp_dir : Vector2
var control_perp_dist : float
var plus_or_minus := 1
var t : float
var speed := 1.0
var final_dir : Vector2
var final_speed := 420

func _ready():
	if player:
		end_point = player.position
		start_point = global_position
		mid_point = (end_point + start_point) / 2
		perp_dir = ((end_point - start_point).normalized()).rotated(.5 * PI)
		control_perp_dist = (start_point.distance_to(end_point)) / 2.5
		control_point = mid_point + control_perp_dist * plus_or_minus * perp_dir
		final_dir = (end_point - control_point).normalized()


func _process(delta: float):
	super(delta)
	rotation += 20 * delta
	
	if t < 1:
		t = move_toward(t, 1, speed * delta)
		position = start_point.lerp(control_point, t).lerp(control_point.lerp(end_point, t), t)
	else:
		position += final_speed * final_dir * delta


func _on_player_entered(hurtbox):
	if hurtbox.is_in_group("player"):
		player.receive_dam_param(ATTACK_POWER)
