extends Node
## Universal manager autoload to handle
##playing, stopping, restarting, and fading out

var channel_registry : Dictionary
var camera_visible_bounds := Rect2()

@onready var audio_channels := $SFXPool.get_children()

func _unhandled_input(event):
	if event.is_action_released("Enter"):
		update_camera_visible_bounds()

# For changing sounds dynamically. See play_sound for setting SFXPlayers and channel_registry
func _process(delta: float) -> void:
	if camera_visible_bounds == Rect2():
		update_camera_visible_bounds()
	# So far a guard clause else isn't necesary...
	
	# CHANNEL FINISHED PLAYING
	for key in channel_registry.keys():
		
		if not key.playing:
			channel_registry.erase(key)
			continue
		
		var registry_entry = channel_registry[key]
		var base_volume = registry_entry["base_volume"]
		var source_object = registry_entry["source_object"]
		var decay_on_freed = registry_entry["decay_on_freed"]
		var silence_threshold: float = -50.0
		
		# NO SOURCE OBJECT
		if not is_instance_valid(source_object):
			if decay_on_freed:
				var decay_rate_db: float = 42.0
				key.volume_db -= decay_rate_db * delta
				if key.volume_db <= silence_threshold:
					key.stop()
					channel_registry.erase(key)
				continue
		
		# SOURCE OBJECT ACTIVE
		else: 
			var object_position: Vector2 = source_object.global_position
			
			var left_overflow: float = camera_visible_bounds.position.x - object_position.x
			var right_overflow: float = object_position.x - camera_visible_bounds.end.x
			var top_overflow: float = camera_visible_bounds.position.y - object_position.y
			var bottom_overflow: float = object_position.y - camera_visible_bounds.end.y
			
			var highest_overflow: float = 0.0 
			highest_overflow = max(highest_overflow, left_overflow)
			highest_overflow = max(highest_overflow, right_overflow)
			highest_overflow = max(highest_overflow, top_overflow)
			highest_overflow = max(highest_overflow, bottom_overflow)
			
			var distance_to_silence: float = 1000.0
			var fade_progress_ratio: float = clamp(highest_overflow / distance_to_silence, 0.0, 1.0)
			
			key.volume_db = lerp(base_volume, silence_threshold, fade_progress_ratio)


## Routes a given [AudioStream] to be played back.
##[br][br]
## - Custom [b]volume_db[/b] can be passed optionally.[br]
## - Pass in [code]self[/code] if an object's sound should fade out off screen.[br]
## - Setting [b]decay_on_freed[/b] to [code]true[/code] will cause to fade out when source object is freed.[br]
## [i]Leave [code]false[/code] for hits or sounds that might free an object[/i]
func play_sound(sound: AudioStream, base_volume: float = 0.0, source_object: Node2D = null, decay_on_freed: bool = false) -> void:
	
	var oldest_channel: AudioStreamPlayer
	var longest_playtime: float = -INF
	
	for channel: AudioStreamPlayer in audio_channels:
		if channel.playing:
			var playtime: float = channel.get_playback_position()
			if playtime >= longest_playtime:
				oldest_channel = channel
				longest_playtime = playtime
			continue
		else:
			channel.stream = sound
			channel.volume_db = base_volume
			channel.play()
			
			channel_registry[channel] = {
				"base_volume": base_volume,
				"source_object": source_object,
				"decay_on_freed": decay_on_freed,
				}
			
			return
	
	oldest_channel.stream = sound
	oldest_channel.volume_db = base_volume
	oldest_channel.play()
	channel_registry[oldest_channel] = {"base_volume": base_volume, "source_object": source_object, "decay_on_freed": decay_on_freed}


## Stops playback of a sound from a provided source object.
##[br][br]
## If no source is given, stops all instances of the provided audio file 
func stop_sound(sound: AudioStream, source_object: Node2D = null) -> void:
	
	if source_object != null:
		for channel: AudioStreamPlayer in channel_registry.keys():
			
			if source_object == channel_registry[channel]["source_object"] and channel.stream == sound:
				channel.stop()
				channel_registry.erase(channel)
				return
		
		printerr("Sound's source object not found")
	
	for channel: AudioStreamPlayer in audio_channels:
		
		if channel.stream == sound:
			channel.stop()
			channel_registry.erase(channel)


# HELPER FUNCTIONS

func update_camera_visible_bounds() -> void:
	var viewport := get_viewport()
	if not viewport:
		return
		
	var active_camera := viewport.get_camera_2d()
	if not active_camera:
		return
		
	var screen_rect := viewport.get_visible_rect()
	var screen_to_world_matrix := viewport.global_canvas_transform * active_camera.get_canvas_transform()
	var world_to_screen_matrix := screen_to_world_matrix.affine_inverse()
	
	camera_visible_bounds = world_to_screen_matrix * screen_rect
