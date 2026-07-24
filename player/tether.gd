extends Node2D


@export var max_length : int = 10 #180 max if we use dynamic stretching
@export var spring_stiffness : float = 1.125
@export var friction_damping := 5.0

var point_distance : float
var current_max_length : float

@onready var tether_origin_node : Node
@onready var dummy
@onready var line := $LineTexture


func _ready():
	if tether_origin_node.new_dummy != null:
		dummy = tether_origin_node.new_dummy
	
	SignalBus.tether_toggled.connect(func(boolean): if boolean == false: queue_free())


func _physics_process(_delta):
	if not tether_origin_node or not dummy:
		tether_origin_node.sever_tether_externally()
		return
	
	line.clear_points()
	line.add_point(tether_origin_node.position - global_position)
	line.add_point(dummy.position - global_position)
	point_distance = line.get_point_position(0).distance_to(line.get_point_position(1))
	
	if point_distance >= max_length:
		apply_elastic_force()


func get_elastic_pull_force() -> Vector2:
	var distance_exceeded : float = max(point_distance - max_length, 0.0)
	var rebound_direction : Vector2 = (tether_origin_node.global_position - dummy.global_position).normalized() # direction to tetherOriginNode
	var elastic_force : float = distance_exceeded**2 * spring_stiffness
	
	return elastic_force * rebound_direction


func get_damping_force() -> Vector2:
	var rebound_direction : Vector2 = (tether_origin_node.global_position - dummy.global_position).normalized() # direction to tetherOriginNode
	var starting_vector : Vector2 = dummy.linear_velocity
	var velocity_to_tether_origin_node : float = starting_vector.dot(rebound_direction)
	
	if velocity_to_tether_origin_node < 0.0:
		return rebound_direction * (-velocity_to_tether_origin_node * friction_damping)
	else:
		return Vector2.ZERO


func apply_elastic_force() -> void:
	var total_force : Vector2 = get_elastic_pull_force() + get_damping_force()
	
	dummy.apply_force(total_force)
