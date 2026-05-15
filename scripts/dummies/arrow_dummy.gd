extends RigidBody2D

@onready var player := get_node("/root/Main/Player")
@onready var spring := get_node("/root/Main/Player/Tether")

enum State{
	PASSIVE,
	SLINGSHOT,
	SPECIAL
}
var state := State.PASSIVE

var atkPower : float

const IDEAL_MAX_SPEED : int = 1500
#const SLINGSHOT_MAX_SPEED : int = 3000
#var currentMaxSpeed : float

var launchForce : float = 1720
var direction := Vector2.ZERO
var newDir : Vector2
#
#func _ready():
	#currentMaxSpeed = IDEAL_MAX_SPEED

func _physics_process(delta):
	print(linear_velocity)
	
	#What is 17 here?
	atkPower = linear_velocity.length() / 17
	#if player.isTethered == false: state = State.SPECIAL
	match state:
		State.PASSIVE:
			if linear_velocity.length() > IDEAL_MAX_SPEED:
				linear_velocity = linear_velocity.normalized() * IDEAL_MAX_SPEED
			
			if player.isTethered == false:
				self.state = State.SPECIAL
			
		State.SPECIAL:
			custom_integrator = true
			
			var previousMoveDirection = linear_velocity.normalized()
			linear_velocity = launchForce * previousMoveDirection
			
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
