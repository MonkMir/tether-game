extends RigidBody2D

@onready var player := get_node("/root/Main/Player")
@onready var spring := get_node("/root/Main/Player/Tether")

enum State{
	PASSIVE,
	SPECIAL
}
var state := State.PASSIVE

var atkPower : float

var launchForce : float = 1720
var direction := Vector2.ZERO
var newDir : Vector2

func _physics_process(delta):
	#What is 17 here?
	atkPower = linear_velocity.length() / 17
	
	match state:
		State.PASSIVE:
			if is_instance_valid(player):
				if spring.node_b == NodePath():
					direction = linear_velocity.normalized()
					state = State.SPECIAL
		State.SPECIAL:
			linear_velocity = direction * launchForce
			angular_velocity = 0
			rotation = direction.angle()

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
