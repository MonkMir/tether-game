extends Node2D


# GAME START INITIALIZATIONS

@export var arrow_dummy_scene: PackedScene
@export var bomber_dummy_scene: PackedScene
@export var parabolic_dummy_scene: PackedScene
@export var tether: PackedScene

@export var max_intensity: float = 24.0
@export var fade_speed: float = 5.0

const BASE_SPEED : int = 800
const MAX_SPEED : int = 800

var new_dummy : Node2D = null
var health: int = 100
var damage_calc: int = 20
var enemies_in_range : int = 0
var move_speed := 250.0
var is_tethered := false
var targeted_enemy : Node2D = null
var nearest_enemy : Node2D = null
var dummy_position : Vector2
var dummy_rotation : float
var dummy_health : float
var dummy_enemy_name : String
var last_direction_x: float = 0.0

@onready var level := get_parent()
@onready var health_bar := $HealthBarCanvas/HealthBar
@onready var camera := $"../Camera2D"
@onready var sprite := $PlayerSprite
@onready var sprite_reverse := $PlayerSpriteReverse
@onready var thruster_glow := $ThrusterGlow
@onready var thruster_glow_reverse := $ThrusterGlowReverse
@onready var tether_cooldown : Timer = $TetherCooldown


func _ready():
	health_bar._init_health(health)


func _physics_process(delta: float) -> void:
	# PLAYER MOVEMENT
	var input_direction = Input.get_vector("Stick Left", "Stick Right", "Stick Up", "Stick Down")
	position += input_direction * move_speed * delta
	
	var current_speed_x = abs(input_direction.x) * move_speed
	var target_intensity = (current_speed_x / move_speed) * max_intensity
	
	var current_intensity = lerp(thruster_glow.modulate.r, target_intensity, fade_speed * delta)
	var base_color = Color("ff4500")
	
	var target_color = base_color * current_intensity
	target_color.a = base_color.a * (current_intensity / max_intensity)
	
	thruster_glow.modulate = target_color
	thruster_glow_reverse.modulate = target_color



	
	if input_direction.x != 0 and sign(input_direction.x) != sign(last_direction_x):
		_on_direction_flipped(sign(input_direction.x))
		last_direction_x = input_direction.x
	
	var camera_rect = get_static_camera_rect()
	position = position.clamp(camera_rect.position, camera_rect.end)
	
	# TETHER COOLDOWN
	if tether_cooldown.time_left != 0.0:
		sprite.modulate = Color(0.11, 0.11, 0.11, 1.0)
		sprite_reverse.modulate = Color(0.11, 0.11, 0.11, 1.0)
	else:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite_reverse.modulate = Color(1, 1, 1, 1)
	
	# GAME OVER LOGIC
	if health <= 0:
		self.queue_free()
		GameState.is_game_over = true


# USER INPUTS
func _input(event):
	if event.is_action_pressed("Tether") and is_tethered:
		new_dummy = null
		is_tethered = false
	elif (
			event.is_action_pressed("Tether") 
			and enemies_in_range > 0 
			and tether_cooldown.time_left == 0.0
	):
		init_target()
		tether_cooldown.start()
	elif (
			event.is_action_pressed("Tether") 
			and tether_cooldown.time_left == 0.0 
			and not is_tethered
	):
		tether_cooldown.start()


# PLAYER HURT CALACULATION
func receive_dam_param(damage):
	health -= damage
	health_bar.health = health
	GameState.combo_counter /= 2


# PLAYER'S END TETHERING SCRIPT
func init_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy != null:
		targeted_enemy = nearest_enemy
		# next step in enemy script (could we keep it in player with targetedEnemy.[data]??)
		swap_and_tether(
				targeted_enemy.position,
				targeted_enemy.rotation,
				targeted_enemy.health,
				targeted_enemy.enemy_name,
		)


func swap_and_tether(pos: Vector2, rot: float, enemy_health: float, enemy_name: String):
	dummy_position = pos - position
	dummy_rotation = rot
	dummy_enemy_name = enemy_name
	
	if dummy_enemy_name == "arrow":
		new_dummy = arrow_dummy_scene.instantiate()
	elif dummy_enemy_name == "bomber":
		new_dummy = bomber_dummy_scene.instantiate()
	elif dummy_enemy_name == "parabolic":
		new_dummy = parabolic_dummy_scene.instantiate()
	
	new_dummy.health = enemy_health
	new_dummy.global_position = dummy_position
	new_dummy.rotation = dummy_rotation
	
	add_child(new_dummy)
	new_dummy.reparent(level)
	is_tethered = true
	targeted_enemy.queue_free()
	
	var new_tether = tether.instantiate()
	new_tether.tether_origin_node = self
	level.add_child(new_tether)


func get_static_camera_rect() -> Rect2:
	var camera_size = get_viewport_rect().size / camera.zoom
	var camera_corner_top_left := Vector2(camera.global_position - (camera_size / 2))
	
	return Rect2(camera_corner_top_left, camera_size)


func _on_direction_flipped(dir_x: float) -> void:
	if dir_x > 0:
		sprite.show()
		sprite_reverse.hide()
		
		thruster_glow.show()
		thruster_glow_reverse.hide()
	elif dir_x < 0:
		sprite.hide()
		sprite_reverse.show()
		
		thruster_glow.hide()
		thruster_glow_reverse.show()


func _on_tether_range_area_entered(_enemy_area):
	enemies_in_range += 1


func _on_tether_range_area_exited(_enemy_area):
	enemies_in_range -= 1
