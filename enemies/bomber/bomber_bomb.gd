extends Sprite2D


const MIN_SPEED := 20
const ACCELERATION := 3.5

@export var explosion_scene : PackedScene

var direction : Vector2
var speed := 50.0

@onready var player := get_tree().get_first_node_in_group("player")


func _ready():
	if player != null:
		direction = (player.position - position).normalized()


func _process(delta: float):
	if speed > MIN_SPEED:
		speed -= ACCELERATION
		position += speed * direction * delta
	else:
		speed = 0
		position += MIN_SPEED * direction * delta


func explode():
	var Explosion := explosion_scene.instantiate()
	Explosion.position = position
	#WARNING idk what parent even is lol
	get_parent().add_child(Explosion)
	queue_free()


func evaluate_ancestry_for_group(target_group: String) -> bool:
	var ancestor_node = get_parent()
	
	while ancestor_node != null:
		if ancestor_node.is_in_group(target_group):
			return true
		ancestor_node = ancestor_node.get_parent()
	
	return false


func _on_timer_timeout():
	queue_free()
	explode()
