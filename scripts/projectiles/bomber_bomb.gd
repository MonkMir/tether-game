extends Sprite2D

@onready var player := get_tree().get_first_node_in_group("player")
@export var explosion_scene : PackedScene

var dir : Vector2
var speed := 320.0
const  ACCEL := 3.5
const MIN_SPEED := 20

func _ready():
	if player != null:
		dir = (player.position - position).normalized()

func _process(delta):
	if speed > MIN_SPEED:
		speed -= ACCEL
		position += speed * dir * delta
	else: 
		speed = 0 
		position += MIN_SPEED * dir * delta
		modulate = Color(3, 3, 3, .7)


func _on_timer_timeout():
	queue_free()
	explode()

func explode():
	var explosion := explosion_scene.instantiate()
	explosion.position = position
	#WARNING idk what parent even is
	get_parent().add_child(explosion)
	queue_free()

func evaluate_ancestry_for_group(targetGroup: String) -> bool:
	var ancestorNode = get_parent()
	while ancestorNode != null:
		if ancestorNode.is_in_group(targetGroup):
			return true
		ancestorNode = ancestorNode.get_parent()
	return false
