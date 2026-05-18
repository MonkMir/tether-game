extends RigidBody2D

@onready var player := get_node("/root/Main/Player")
@onready var spring := get_node("/root/Main/Player/Tether")

enum State{
	PASSIVE,
	SPECIAL
}
var state := State.PASSIVE

var atkPower : float

#WARNING Speed controlled by tether script
const ABSOLUTE_SPEED_LIMIT : int = 2500
const DEFAULT_SPEED_LIMIT : int = 2000 #1200 
var speedLimit : float 
var currentSpeed : float

var launchSpeed : float = 1720
var direction := Vector2.ZERO
var newDir : Vector2

func _ready():
	speedLimit = DEFAULT_SPEED_LIMIT

func _physics_process(delta):
	currentSpeed = linear_velocity.length()
	print(speedLimit)
	#What is magic number here?
	atkPower = linear_velocity.length() / 15
	#if player.isTethered == false: state = State.SPECIAL
	match state:
		State.PASSIVE:
			
			if currentSpeed > speedLimit:
				linear_velocity = linear_velocity.normalized() * speedLimit
			
			
			#This condition is important for enemy ragdoll upon player death
			if player:
				if player.isTethered == false:
					self.state = State.SPECIAL
			
		State.SPECIAL:
			custom_integrator = true
			
			var previousMoveDirection = linear_velocity.normalized()
			linear_velocity = launchSpeed * previousMoveDirection
			
			#BUG add rotation instructions after passive angular velocity is fixed


func launch_dir() -> Vector2: #not functional
		var enemies = get_tree().get_nodes_in_group("enemies")
		var enemyDir : Vector2
		var selectDotProd : float = -INF
		
		for enemy in enemies:
			enemyDir = (enemy.position - position).normalized()
			var currentDotProd := direction.dot(enemyDir)
			
			if currentDotProd > selectDotProd and currentDotProd > 0:
				newDir = enemyDir
				
		
		if selectDotProd != -INF:
			print("new selected!")
			return newDir
			
		else:
			print("womp")
			return direction

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.receive_dam_param(atkPower)
