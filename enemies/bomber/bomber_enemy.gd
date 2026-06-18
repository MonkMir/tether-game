extends Enemy


enum State{
	APPROACH,
	CIRCLE
}

var ATK_POWER := 10
const SCORE_REWARD := 10

@export var bomb_scene : PackedScene
@export var max_speed := 100
@export var turn_sharpness := 1.2 # Adjust for sharper/smoother turns
@export var repel_factor := 5
@export var adjacent_repel_factor := 2




var state = State.APPROACH

var cardinal_directions := [
	Vector2(1, 0),   # Right
	Vector2(1, 1).normalized(),   # Down-Right
	Vector2(0, 1),   # Down
	Vector2(-1, 1).normalized(),  # Down-Left
	Vector2(-1, 0),  # Left
	Vector2(-1, -1).normalized(), # Up-Left
	Vector2(0, -1),  # Up
	Vector2(1, -1).normalized()   # Up-Right
]


var velocity := Vector2.ZERO

var dot_product_array : Array[float]
var repel_array:= []
var interest_array := []



var player_direction := Vector2.ZERO

# sprite declared in enemy class
@onready var sprite_reverse := $SpriteReverse
@onready var circling_range := $circling_range/CollisionShape
@onready var timer := $BombTimer
@onready var ray_array := [
	$RaycastManager/RayRight,
	$RaycastManager/RayLowRight,
	$RaycastManager/RayDown,
	$RaycastManager/RayLowLeft,
	$RaycastManager/RayLeft,
	$RaycastManager/RayHighLeft,
	$RaycastManager/RayUp,
	$RaycastManager/RayHighRight
	]

func _ready():
	super()
	enemy_name = "bomber"


func _process(delta):
	super(delta)
	
	dot_product_array = [] # reset arrays each process cycle
	repel_array = []
	interest_array = [] # context map
	
	if player != null:
		player_direction = Vector2(player.position - position).normalized()
	
	if velocity.x > 0:
		sprite.hide()
		sprite_reverse.show()
	elif velocity.x < 0:
		sprite.show()
		sprite_reverse.hide()
	
	
	match state:
		State.APPROACH:
			move_and_avoid(player_direction, delta)
		
		State.CIRCLE:
			var perpPlayerDir := (player_direction + player_direction.rotated(rad_to_deg(90))).normalized()
			move_and_avoid(perpPlayerDir, delta)
			
			if timer.time_left == 0:
				timer.start()

func move_and_avoid(targetDir, delta): #movement with relevent context
	for dir in cardinal_directions:
		dot_product_array.append(dir.dot(targetDir))
	
	get_repelled_dirs()
	update_adjacent_dir_repulsion()
	interest_array = subtract_arrays(dot_product_array, repel_array)
	
	var idealVel = get_ideal_dir(interest_array) * max_speed #normalized vector * max_speed
	var steering_force = (idealVel - velocity) * turn_sharpness
	velocity += steering_force * delta
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	position += velocity * delta


func get_repelled_dirs (): #generates raycast context (enemies)
	for ray in ray_array:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider != null and collider.is_in_group("enemies"):
				repel_array.append(repel_factor)
			else:
				repel_array.append(0) #for safety
		else:
			repel_array.append(0)


func update_adjacent_dir_repulsion(): #completes raycast context (repulsion of adjecent directions
	var temp_repel_array = repel_array.duplicate()
	for i in range(len(repel_array)):
		if repel_array[i] == repel_factor:
			var prev_index = (i - 1 + len(repel_array)) % len(repel_array) # Update previous index, considering wrap-around
			temp_repel_array[prev_index] += adjacent_repel_factor
			var next_index = (i + 1) % len(repel_array) # Update next index, considering wrap-around
			temp_repel_array[next_index] += adjacent_repel_factor
	# Apply changes
	repel_array = temp_repel_array


func subtract_arrays(arr1 : Array, arr2 : Array) -> Array:
	var result := []
	for n in range(len(arr1)):
		result.append(arr1[n] - arr2[n])
	return result


func get_ideal_dir(_interest_array: Array) -> Vector2: 
	var desired_index := interest_array.find(_interest_array.max())
	var ideal_direction = cardinal_directions[desired_index]
	return ideal_direction


func spawn_bomb():
	var new_bomb := bomb_scene.instantiate()
	new_bomb.position = position
	get_parent().add_child(new_bomb)


func _on_bomb_timer_timeout():
	spawn_bomb()


func _on_circling_range_area_entered(_area):
	state = State.CIRCLE


func _on_circling_range_area_exited(_area):
	state = State.APPROACH
