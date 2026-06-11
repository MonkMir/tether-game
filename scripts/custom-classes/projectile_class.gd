class_name Projectile
extends Area2D

# WARNING I don't know if class properties will be private, so I'm making them public
var atack_power : float
var speed_limit : int = 1850
var current_speed : float
# These are probably private, so check later
var time_out_of_bounds_seconds := 0.0
var max_offscreen_time_seconds := 3.0
@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var area := $Area2D
@onready var camera := get_viewport().get_camera_2d()


func _process(delta):
	if get_despawn_rect().has_point(global_position):
		time_out_of_bounds_seconds = 0.0
	else:
		time_out_of_bounds_seconds += delta
		if time_out_of_bounds_seconds >= max_offscreen_time_seconds:
			queue_free()


func get_static_camera_rect() -> Rect2:
	var camera_size : Vector2 = get_viewport_rect().size / camera.zoom
	var camera_corner_top_left := Vector2(camera.global_position - (camera_size / 2))
	
	return Rect2(camera_corner_top_left, camera_size)


func get_despawn_rect() -> Rect2:
	return get_static_camera_rect().grow(100)
