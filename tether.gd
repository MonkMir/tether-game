extends Node2D

@onready var player := get_node("/root/Main/Player")
@onready var dummy
@onready var line := $LineTexture

var pointDistance : float

@export var maxLength : int = 120 #180 max if we use dynamic stretching
var currentMaxLength : float

func _ready():
	if player.newDummy != null:
		dummy = player.newDummy

func _physics_process(delta):
	if player:
		if player.isTethered == false:
			queue_free()
		
		line.clear_points()
		line.add_point(player.position - global_position)
		line.add_point(dummy.position - global_position)
		
		pointDistance = line.get_point_position(0).distance_to(line.get_point_position(1))
		
		if pointDistance >= maxLength:
			apply_elastic_force()
		
		
		##What I really want is to make a formula to get to max within x variable seconds under ideal conditions
		#var speedIncreaseThreshold := 10
		#if dummy.currentSpeed >= dummy.speedLimit - speedIncreaseThreshold:
			#dummy.speedLimit += 150 * delta
		#else:
			#dummy.speedLimit -= 300 * delta
		
		## DEBUG TOOLS
		
		if Input.is_action_just_pressed("Scroll Up"):
			maxLength -= 20
		elif Input.is_action_just_pressed("Scroll Down"):
				maxLength += 20
		
	elif !player:
		queue_free()

@export var springStiffness : float = 1.125

func get_elastic_pull_force() -> Vector2:
	var distanceExceeded : float = max(pointDistance - maxLength, 0.0)
	
	var reboundDirection : Vector2 = (player.global_position - dummy.global_position).normalized() #direction to player
	var elasticForce : float = distanceExceeded**2 * springStiffness
	
	return elasticForce * reboundDirection

@export var counterForceWeight := 5.0

func get_damping_force() -> Vector2:
	var reboundDirection : Vector2 = (player.global_position - dummy.global_position).normalized() #direction to player
	var startingVector : Vector2 = dummy.linear_velocity 
	var velocityToPlayer : float = startingVector.dot(reboundDirection)
	
	if velocityToPlayer < 0.0:
		return reboundDirection * (-velocityToPlayer * counterForceWeight)
	else:
		return Vector2.ZERO
	

func apply_elastic_force() -> void:
	var totalForce : Vector2 = get_elastic_pull_force() + get_damping_force()
	dummy.apply_force(totalForce)
