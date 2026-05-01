extends RigidBody2D

var atkPower : float

@onready var main := get_node("/root/Main")
@onready var player := get_node("/root/Main/Player")
@onready var spring := get_node("/root/Main/Player/Tether")
var dupe : PackedScene

enum State {
	PASSIVE,
	SPECIAL,
	REST
}

var state := State.PASSIVE

var t : float
var speed := 2.0

var startPoint : Vector2
var controlPoint : Vector2
var endPoint : Vector2

var finalVel : Vector2
var finalDir : Vector2

func _ready():
	dupe = load("res://scenes/dummies/parabolic_dummy.tscn")

func _physics_process(delta):
	match state:
		State.PASSIVE:
			atkPower = linear_velocity.length() / 17
			if is_instance_valid(player):
				if spring.node_b == NodePath():
					startPoint = position
					controlPoint = player.position + Vector2(0, startPoint.y)
					endPoint = Vector2(((player.position - startPoint) + player.position).x,  startPoint.y)
					state = State.SPECIAL
	
		State.SPECIAL:
			atkPower = 75
			angular_velocity = 30
			if t < 1:
				t = move_toward(t, 1, speed * delta)
				position = startPoint.lerp(controlPoint, t).lerp(controlPoint.lerp(endPoint, t), t)
				finalDir = (endPoint - controlPoint).normalized()
			else: 
				queue_free()
				var dupeNode := dupe.instantiate()
				dupeNode.state = State.REST
				dupeNode.position = position
				dupeNode.apply_central_impulse(finalDir * 1000)
				dupeNode.angular_velocity = angular_velocity
				main.add_child(dupeNode)
	
		State.REST:
			angular_velocity = 25
			atkPower = 100

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.receive_dam_param(atkPower)
