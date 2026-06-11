extends Enemy

var ATK_POWER := 10
const SCORE_REWARD := 10

@export var bomb_scene : PackedScene

@onready var circlingRange := $CirclingRange/CollisionShape
@onready var timer := $BombTimer

enum State{
	APPROACH,
	CIRCLE
}

var state = State.APPROACH

var cardinalDirs := [
	Vector2(1, 0),   # Right
	Vector2(1, 1).normalized(),   # Down-Right
	Vector2(0, 1),   # Down
	Vector2(-1, 1).normalized(),  # Down-Left
	Vector2(-1, 0),  # Left
	Vector2(-1, -1).normalized(), # Up-Left
	Vector2(0, -1),  # Up
	Vector2(1, -1).normalized()   # Up-Right
]


@onready var rayArray := [
	$RaycastManager/RayRight,
	$RaycastManager/RayLowRight,
	$RaycastManager/RayDown,
	$RaycastManager/RayLowLeft,
	$RaycastManager/RayLeft,
	$RaycastManager/RayHighLeft,
	$RaycastManager/RayUp,
	$RaycastManager/RayHighRight
	]


var velocity := Vector2.ZERO
var max_speed := 230
var turn_sharpness := 1.3 # Adjust for sharper/smoother turns

var dotProdArray := []
var repelArray:= []
var interestArray := []

var repelFactor := 5
var adjacentRepelFact := 2

var playerDir := Vector2.ZERO


func _ready():
	super()
	enemy_name = "bomber"


func _process(delta):
	super(delta)
	
	dotProdArray = [] #reset arrays each process cycle
	repelArray = []
	interestArray = [] #context map
	
	if player != null:
		playerDir = Vector2(player.position - position).normalized()
	
	
	match state:
		State.APPROACH:
			move_and_avoid(playerDir, delta)
		
		State.CIRCLE:
			var perpPlayerDir := (playerDir + playerDir.rotated(rad_to_deg(90))).normalized()
			move_and_avoid(perpPlayerDir, delta)
			
			if timer.time_left == 0:
				timer.start()

func move_and_avoid(targetDir, delta): #movement with relevent context
	for dir in cardinalDirs:
		dotProdArray.append(dir.dot(targetDir))
	
	get_repelled_dirs()
	update_adjacent_dir_repulsion()
	interestArray = subtract_arrays(dotProdArray, repelArray)
	
	var idealVel = get_ideal_dir(interestArray) * max_speed #normalized vector * max_speed
	var steering_force = (idealVel - velocity) * turn_sharpness
	velocity += steering_force * delta
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	position += velocity * delta

func get_repelled_dirs (): #generates raycast context (enemies)
	for ray in rayArray:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider != null and collider.is_in_group("enemies"):
				repelArray.append(repelFactor)
			else:
				repelArray.append(0) #for safety
		else:
			repelArray.append(0)

func update_adjacent_dir_repulsion(): #completes raycast context (repulsion of adjecent directions
	var temp_repelArray = repelArray.duplicate()
	for i in range(len(repelArray)):
		if repelArray[i] == repelFactor:
			var prev_index = (i - 1 + len(repelArray)) % len(repelArray) # Update previous index, considering wrap-around
			temp_repelArray[prev_index] += adjacentRepelFact
			var next_index = (i + 1) % len(repelArray) # Update next index, considering wrap-around
			temp_repelArray[next_index] += adjacentRepelFact
	# Apply changes
	repelArray = temp_repelArray

func subtract_arrays(arr1 : Array, arr2 : Array) -> Array:
	var result := []
	for n in range(len(arr1)):
		result.append(arr1[n] - arr2[n])
	return result

func get_ideal_dir(_interestArray: Array) -> Vector2: 
	var desiredIndex := interestArray.find(_interestArray.max())
	var idealDir = cardinalDirs[desiredIndex]
	return idealDir

func spawn_bomb():
	var NewBomb := bomb_scene.instantiate()
	NewBomb.position = position
	get_parent().add_child(NewBomb)

func _on_bomb_timer_timeout():
	spawn_bomb()

func _on_circling_range_area_entered(_area):
	state = State.CIRCLE
func _on_circling_range_area_exited(_area):
	state = State.APPROACH
