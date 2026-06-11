extends Dummy


enum State {
	PASSIVE,
	SPECIAL,
	REST
}

var Dupe : PackedScene
var state := State.PASSIVE
var t : float
var speed := 2.0
var start_point : Vector2
var control_point : Vector2
var end_point : Vector2
var final_vel : Vector2
var final_dir : Vector2

func _ready():
	super()
	attack_power = 75
	Dupe = load("res://enemies/parabolic/parabolic_dummy.tscn")


func _physics_process(delta: float):
	super(delta)
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			
			if player:
				if player.is_tethered == false:
					start_point = position
					control_point = player.position + Vector2(0, start_point.y)
					end_point = Vector2(((player.position - start_point) + player.position).x, start_point.y)
					state = State.SPECIAL
		State.SPECIAL:
			angular_velocity = 30
			
			if t < 1:
				t = move_toward(t, 1, speed * delta)
				position = start_point.lerp(control_point, t).lerp(control_point.lerp(end_point, t), t)
				final_dir = (end_point - control_point).normalized()
			else:
				var dupe_node := Dupe.instantiate()
				dupe_node.state = State.REST
				dupe_node.position = position
				dupe_node.apply_central_impulse(final_dir * 1000)
				dupe_node.angular_velocity = angular_velocity
				get_parent().add_child(dupe_node)
				queue_free()
		State.REST:
			angular_velocity = 25
			attack_power = 100
