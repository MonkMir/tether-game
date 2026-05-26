extends Projectile

const ATK_POWER := 5

var startPoint : Vector2
var endPoint : Vector2
var midPoint: Vector2
var controlPoint : Vector2

var perpDir : Vector2
var controlPerpDist : float
var plusOrMinus := 1

var t : float
var speed := 1.0

var finalDir : Vector2
var finalSpeed := 420

func _ready():
	super()
	if player:
		endPoint = player.position
	startPoint = global_position
	midPoint = (endPoint + startPoint) / 2
	
	perpDir = ((endPoint - startPoint).normalized()).rotated(.5 * PI)
	controlPerpDist = (startPoint.distance_to(endPoint)) / 2.5
	
	controlPoint = midPoint + controlPerpDist * plusOrMinus * perpDir
	finalDir = (endPoint - controlPoint).normalized()
func _process(delta):
	super(delta)
	
	rotation += 20 * delta
	
	if t < 1:
		t = move_toward(t, 1, speed * delta)
		position = startPoint.lerp(controlPoint, t).lerp(controlPoint.lerp(endPoint, t), t)
	else:
		position += finalSpeed * finalDir * delta

func _on_player_entered(_area):
	if _area.is_in_group("player"):
		player.receive_dam_param(ATK_POWER)
