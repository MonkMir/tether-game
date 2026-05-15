extends Node2D

@export var arrow_dummy_scene: PackedScene
@export var bomber_dummy_scene: PackedScene
@export var parabolic_dummy_scene: PackedScene
@export var tether: PackedScene

@onready var main := get_parent()
@onready var healthBar := $HealthBarCanvas/HealthBar
@onready var sprite := $PlayerSprite
@onready var spring := $Tether
@onready var line := $Tether/Line2D 
@onready var tetherCooldown := $TetherCooldown

var newDummy : Node = null

var health: int = 100
var damageCalc: int = 20

var enemiesInRange : int = 0
var tetherLength := 0
var maxLength := 325




##GAME START INITIALIZATIONS
func _ready():
	healthBar._init_health(health)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(_delta): 
	##PLAYER MOVEMENT
	var mousePosition = get_global_mouse_position()
	position = mousePosition
	
	##TETHER COOLDOWN
	
	if tetherCooldown.time_left != 0.0:
		sprite.modulate = Color(0.111, 0.111, 0.111, 0.502)
	else: 
		sprite.modulate = Color(1, 1, 1, 1)
	
	
	
	
	
	#pls rember to delet this
	#
	#if Input.is_action_just_pressed("Shoot") and isTethered == true:
		#spring.node_b = NodePath()
		#newDummy = null
		#isTethered = false
		#tetherCooldown.start()
	#elif Input.is_action_just_pressed("Shoot") and enemiesInRange > 0:
		#init_target()
	  
	
	
	
	
	
	
	
	##TETHER PROCESSES
	
	
	##DRAW TETHER LINE
	#line.points = []
	#line.add_point(Vector2(0, 0)) #player's position is always (0, 0) relative to Line2D child
	#if newDummy != null:
		#line.add_point(newDummy.position - global_position)
	#
	###TETHER LENGTH TRACKING
	#if spring.node_b != NodePath():
		#tetherLength = line.get_point_position(1).distance_to(line.get_point_position(2))
	#else:
		#tetherLength = 0

	##TETHER MAX LENGTH BREAK
	#if tetherLength > maxLength:
		#break_tether()
	
	##OTHER PROCESSES
	
	##GAME OVER/HEALTH SYSTEM
	if health <= 0:
		self.queue_free()
		GameState.is_game_over = true

var isTethered := false
##USER INPUTS
func _input(event):
	
	
	if event.is_action_pressed("Tether") and isTethered == true:
		#spring.node_b = NodePath()
		newDummy = null
		isTethered = false
		
		
		
	elif event.is_action_pressed("Tether") and enemiesInRange > 0 and tetherCooldown.time_left == 0.0:
		init_target()
		tetherCooldown.start()
		
	elif event.is_action_pressed("Tether") and tetherCooldown.time_left == 0.0 and isTethered == false:
		tetherCooldown.start()

##PLAYER HURT CALACULATION

func receive_dam_param(damage):
	health -= damage
	healthBar.health = health

##PLAYER'S END TETHERING SCRIPT
var targetedEnemy : Node = null
var nearestEnemy : Node = null 

func init_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearestDistance = INF #init elsewhere
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearestDistance:
			nearestDistance = distance
			nearestEnemy = enemy
	
	if nearestEnemy != null:
		targetedEnemy = nearestEnemy
		#next step in enemy script (could we keep it in player with targetedEnemy.[data]??)
	swap_and_tether(targetedEnemy.position, targetedEnemy.rotation, targetedEnemy.type)

var dummyPosition : Vector2 = Vector2(0, 0) #init elsewhere
var dummyRotation : float = 0
var dummyType : String = ""

func swap_and_tether(pos: Vector2, rot:float, type: String):
	dummyPosition = pos - position
	dummyRotation = rot
	dummyType = type
	
	if dummyType == "arrow":  
		newDummy = arrow_dummy_scene.instantiate()
	elif dummyType == "bomber":
		newDummy = bomber_dummy_scene.instantiate()
	elif dummyType == "parabolic":  
		newDummy = parabolic_dummy_scene.instantiate()
	
	newDummy.global_position = dummyPosition
	newDummy.rotation = dummyRotation
	
	add_child(newDummy) #can we do add_sibling?
	newDummy.reparent(main)
	
	isTethered = true
	targetedEnemy.queue_free()
	
	
	main.add_child(tether.instantiate())

func break_tether():
	spring.node_b = NodePath()
	newDummy = null
	line.clear_points()

##NUMBER OF TETHERABLE ENEMIES IN RANGE
func _on_tether_range_area_entered(_area): #only detects enemy layer
		enemiesInRange += 1

func _on_tether_range_area_exited(_area):
	enemiesInRange -= 1
