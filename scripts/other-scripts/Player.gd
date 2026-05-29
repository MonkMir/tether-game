extends Node2D

@export var arrow_dummy_scene: PackedScene
@export var bomber_dummy_scene: PackedScene
@export var parabolic_dummy_scene: PackedScene
@export var tether: PackedScene

@onready var level := get_parent()
@onready var healthBar := $HealthBarCanvas/HealthBar
@onready var camera := $"../Camera2D"
@onready var sprite := $PlayerSprite
@onready var spring := $Tether
@onready var line := $Tether/Line2D 
@onready var tetherCooldown := $TetherCooldown

var newDummy : Node = null

var health: int = 100
var damageCalc: int = 20

var enemiesInRange : int = 0

var moveSpeed : float = 1000
const BASE_SPEED : int = 800
const MAX_SPEED : int = 1000



##GAME START INITIALIZATIONS
func _ready():
	healthBar._init_health(health)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _physics_process(delta): 
	
	##PLAYER MOVEMENT
	var inputDirection = Input.get_vector("Stick Left", "Stick Right", "Stick Up", "Stick Down")
	position += inputDirection * moveSpeed * delta
	
	var camera_rect = get_static_camera_rect()
	position = position.clamp(camera_rect.position, camera_rect.end)
	
	
	##TETHER COOLDOWN
	if tetherCooldown.time_left != 0.0:
		sprite.modulate = Color(0.111, 0.111, 0.111, 0.502)
	else: 
		sprite.modulate = Color(1, 1, 1, 1)
	
	
	##GAME OVER LOGIC
	if health <= 0:
		self.queue_free()
		GameState.is_game_over = true


##USER INPUTS
var isTethered := false
func _input(event):
	if event.is_action_pressed("Tether") and isTethered == true:
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
	
	GameState.comboCounter /= 2


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
	swap_and_tether(targetedEnemy.position, targetedEnemy.rotation, targetedEnemy.health, targetedEnemy.enemyName)

var dummyPosition : Vector2  #init elsewhere
var dummyRotation : float
var dummyHealth : float
var dummyEnemyName : String

func swap_and_tether(pos: Vector2, rot:float, enemyHealth: float, enemyName: String):
	dummyPosition = pos - position
	dummyRotation = rot
	dummyEnemyName = enemyName
	if dummyEnemyName == "arrow":  
		newDummy = arrow_dummy_scene.instantiate()
	elif dummyEnemyName == "bomber":
		newDummy = bomber_dummy_scene.instantiate()
	elif dummyEnemyName == "parabolic":  
		newDummy = parabolic_dummy_scene.instantiate()
	newDummy.health = enemyHealth
	newDummy.global_position = dummyPosition
	newDummy.rotation = dummyRotation
	
	add_child(newDummy)
	newDummy.reparent(level)
	
	
	isTethered = true
	targetedEnemy.queue_free()
	
	var newTether = tether.instantiate()
	newTether.tetherOriginNode = self
	level.add_child(newTether)
	

func _on_tether_range_area_entered(_area): #only detects enemy layer
	enemiesInRange += 1

func _on_tether_range_area_exited(_area):
	enemiesInRange -= 1

func get_static_camera_rect() -> Rect2:
	var cameraSize = get_viewport_rect().size / camera.zoom
	var cameraCornerTopLeft := Vector2(camera.global_position - (cameraSize / 2))
	
	return Rect2(cameraCornerTopLeft, cameraSize)
