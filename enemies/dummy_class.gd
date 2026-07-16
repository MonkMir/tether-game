extends RigidBody2D
class_name Dummy


var attack_power : float
var wrecking_ball_mode := true
var health : float = 100
var speed_limit : int = 435
var current_speed : float
var time_out_of_bounds_seconds : float = 0.0
var max_offscreen_time_seconds := 5.0

@onready var player : Node
@onready var area := $Area2D
@onready var hitbox := $Area2D/CollisionShape2D
@onready var camera := get_viewport().get_camera_2d()
@onready var health_bar := $HealthBar
@onready var health_indicator_bar := $HealthBar/HealthIndicatorBar


func _ready():
	player = get_player()
	area.area_entered.connect(_on_area_entered)
	health_indicator_bar.size = Vector2(150, 25)
	# replace position.y value with a less magical number. sprite.get_rect().size.y + headroom
	health_indicator_bar.position = Vector2(-health_indicator_bar.size.x / 2, -128)
	health_bar._init_health(health)
	gravity_scale = 0.4


func _physics_process(delta: float):
	if health <= 0:
		die()
		return
	
	# healthBar.health = health
	# WARNING this might be a vestige from prior testing. test it
	current_speed = linear_velocity.length()
	
	if wrecking_ball_mode:
		var speed_to_damage_divisor : int = 15
		attack_power = linear_velocity.length() / speed_to_damage_divisor
	
	if get_despawn_rect().has_point(global_position):
		time_out_of_bounds_seconds = 0.0
	else:
		time_out_of_bounds_seconds += delta
	
	if time_out_of_bounds_seconds >= max_offscreen_time_seconds:
		if !player or self != player.new_dummy:
			queue_free()


func _on_area_entered(entered_area):
	if entered_area.is_in_group("enemies"):
		entered_area.receive_dam_param(attack_power)
		SignalBus.enemy_hit.emit(global_position, entered_area.global_position)
	
	if self.state == self.State.SPECIAL:
		return
	
	var max_self_damage: float = 16
	var self_damage: float
	var to_max_speed_ratio : float = inverse_lerp(0, speed_limit, linear_velocity.length())
	
	self_damage = max_self_damage * to_max_speed_ratio
	receive_dam_param(self_damage)


func receive_dam_param(damage):
	health -= damage
	health_bar.health = health


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func get_static_camera_rect() -> Rect2:
	var camera_size = get_viewport_rect().size / camera.zoom
	var camera_corner_top_left := Vector2(camera.global_position - (camera_size / 2))
	
	return Rect2(camera_corner_top_left, camera_size)


func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)


func die():
	queue_free()
