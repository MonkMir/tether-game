extends Dummy

enum State{
	PASSIVE,
	SPECIAL
}
var state := State.PASSIVE

#const DEFAULT_SPEED_LIMIT : int = 2000 #1200 
#const MAX_SPEED_LIMIT : int = 2000
#const MIN_SPEED_LIMIT : int = 1000

var launchSpeed : float = 3500 #minimum speed to oneshot
#var direction := Vector2.ZERO
var newDir : Vector2

#TESTING
func _ready():
	super()

func _physics_process(delta):
	super(delta)
	
	match state:
		State.PASSIVE:
			if currentSpeed > speedLimit:
				linear_velocity = linear_velocity.normalized() * speedLimit
			
			#print("Arrow Dummy Speed: " + str(currentSpeed))
			
			#This condition is important for enemy ragdoll upon player death
			if player:
				if player.isTethered == false:
					state = State.SPECIAL
			
		State.SPECIAL:
			#built-in bool that disable's Godot's physics simulation
			custom_integrator = true
			
			var previousMoveDirection = linear_velocity.normalized()
			linear_velocity = launchSpeed * previousMoveDirection
			
			#BUG add rotation instructions after passive angular velocity is fixed

#not functional
#func launch_dir() -> Vector2: 
		#var enemies = get_tree().get_nodes_in_group("enemies")
		#var enemyDir : Vector2
		#var selectDotProd : float = -INF
		#
		#for enemy in enemies:
			#enemyDir = (enemy.position - position).normalized()
			#var currentDotProd := direction.dot(enemyDir)
			#
			#if currentDotProd > selectDotProd and currentDotProd > 0:
				#newDir = enemyDir
				#
		#
		#if selectDotProd != -INF:
			#print("new selected!")
			#return newDir
			#
		#else:
			#print("womp")
			#return direction

#func get_combo_speed_limit() -> float: #may not be in use
	#var percentToMaxCombo = inverse_lerp(0, GameState.MAX_COMBO, GameState.comboCounter)
	#return lerp(MIN_SPEED_LIMIT, MAX_SPEED_LIMIT, percentToMaxCombo)
