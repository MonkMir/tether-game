extends Dummy


@onready var main := get_node("/root/Main")

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
	super()
	attackPower = 75
	
	dupe = load("res://scenes/dummies/parabolic_dummy.tscn")

func _physics_process(delta):
	super(delta)
	match state:
		State.PASSIVE:
			if currentSpeed > speedLimit:
				linear_velocity = linear_velocity.normalized() * speedLimit
			
			if player:
				if player.isTethered == false:
					
					startPoint = position
					controlPoint = player.position + Vector2(0, startPoint.y)
					endPoint = Vector2(((player.position - startPoint) + player.position).x, startPoint.y)
					
					state = State.SPECIAL
	
		State.SPECIAL:
			angular_velocity = 30
			if t < 1:
				t = move_toward(t, 1, speed * delta)
				position = startPoint.lerp(controlPoint, t).lerp(controlPoint.lerp(endPoint, t), t)
				finalDir = (endPoint - controlPoint).normalized()
			else: 
				
				var dupeNode := dupe.instantiate()
				dupeNode.state = State.REST
				dupeNode.position = position
				dupeNode.apply_central_impulse(finalDir * 1000)
				dupeNode.angular_velocity = angular_velocity
				main.add_child(dupeNode)
				queue_free()
	
		State.REST:
			angular_velocity = 25
			attackPower = 100
