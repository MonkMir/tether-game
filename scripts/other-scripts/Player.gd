extends Node2D

@export var arrow_dummy_scene: PackedScene
@export var bomber_dummy_scene: PackedScene
@export var parabolic_dummy_scene: PackedScene
@export var tether: PackedScene

@onready var main := get_parent()
@onready var healthBar := $HealthBarCanvas/HealthBar
@onready var camera := $"../Camera2D"
@onready var sprite := $PlayerSprite
@onready var spring := $Tether
@onready var line := $Tether/Line2D 
@onready var tetherCooldown := $TetherCooldown

var newDummy : Node = null

var health: int = 1000 #revert to 100 later
var damageCalc: int = 20

var enemiesInRange : int = 0
var tetherLength := 0
var maxLength := 325




##GAME START INITIALIZATIONS
func _ready():
	healthBar._init_health(health)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta): 
	##PLAYER MOVEMENT
	#var mousePosition = get_global_mouse_position()
	#position = mousePosition
	var moveSpeed := 1000 
	var inputDirection = Input.get_vector("Stick Left", "Stick Right", "Stick Up", "Stick Down")
	position += inputDirection * moveSpeed * delta
	
	var camera_rect = get_static_camera_rect()
	position = position.clamp(camera_rect.position, camera_rect.end)
	
	
	#var dashDistance = 300
	#var dashTime = 0.25
	#
	#if Input.is_action_just_pressed("Dash"):
		#var dash_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#dash_tween.tween_property(self, "position", position + inputDirection * dashDistance, dashTime)
		#await dash_tween.finished

	
	
	##TETHER COOLDOWN
	
	if tetherCooldown.time_left != 0.0:
		sprite.modulate = Color(0.111, 0.111, 0.111, 0.502)
	else: 
		sprite.modulate = Color(1, 1, 1, 1)
	
	
	
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

##NUMBER OF TETHERABLE ENEMIES IN RANGE
func _on_tether_range_area_entered(_area): #only detects enemy layer
		enemiesInRange += 1

func _on_tether_range_area_exited(_area):
	enemiesInRange -= 1

func get_static_camera_rect() -> Rect2:
	var cameraSize = get_viewport_rect().size / camera.zoom
	var cameraCornerTopLeft := Vector2(camera.global_position - (cameraSize / 2))
	
	return Rect2(cameraCornerTopLeft, cameraSize)
