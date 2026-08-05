extends Node
## Universal manager autoload to handle
##playing, stopping, restarting, and fading out

var channel_registry : Dictionary
var viewport_rect := Rect2()

@onready var audio_channels := $SFXPool.get_children()



func _process(_delta: float) -> void:
	if viewport_rect == Rect2():
		update_viewport_rect()
	
	for key in channel_registry.keys():
		if not key.playing:
			channel_registry.erase(key)
			continue
		
		var registry_entry = channel_registry[key]
		var source_object = registry_entry["source"]
		var decay_on_despawn = registry_entry["decay_on_despawn"]
		
		if source_object == null:
			continue
		
		if is_instance_valid(source_object):
			var object_position: Vector2 = source_object.global_position
			
			var left_overflow: float = viewport_rect.position.x - object_position.x
			var right_overflow: float = object_position.x - viewport_rect.end.x
			var top_overflow: float = viewport_rect.position.y - object_position.y
			var bottom_overflow: float = object_position.y - viewport_rect.end.y
			
			var highest_overflow: float = 0.0
			highest_overflow = max(highest_overflow, left_overflow)
			highest_overflow = max(highest_overflow, right_overflow)
			highest_overflow = max(highest_overflow, top_overflow)
			highest_overflow = max(highest_overflow, bottom_overflow)
			
			var distance_to_silence: float = 300.0
			var fade_progress_ratio: float = clamp(highest_overflow / distance_to_silence, 0.0, 1.0)
			key.volume_db = fade_progress_ratio * -40.0
		else:
			if decay_on_despawn:
				var silence_threshold: float = -60.0
				var decay_rate_db: float = 1.5
				key.volume_db -= decay_rate_db
				
				if key.volume_db <= silence_threshold:
					key.stop()
					channel_registry.erase(key)
			else:
				channel_registry.erase(key)


## Routes a given [AudioStream] to be played back.[br]
##
## - Base instance volume volume can be passed optionally.[br]
## - [Node2D] source objects should always be passed as self for off screen fade.[br]
## - Sounds that abruptly end, like looped sounds, should receive the 
## optional [b]decay_on_despawn[/b] argument.
func play_sound(sound: AudioStream, base_volume: float = 0.0, source_object: Node2D = null, decay_on_despawn: bool = false) -> void:
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
				"source": source_object,
				"decay_on_despawn": decay_on_despawn,
				}
			return
			
	oldest_channel.stream = sound
	oldest_channel.volume_db = base_volume
	oldest_channel.play()
	channel_registry[oldest_channel] = {"source": source_object, "decay_on_despawn": decay_on_despawn}


## Stops all playback instances of the provided audio stream
func stop_sound(sound: AudioStream) -> void:
	
	for channel: AudioStreamPlayer in audio_channels:
		
		if channel.stream == sound:
			channel.stop()


## Calls stop_sound() and play_sound() in AudioManager
func restart_sound(sound: AudioStream, base_volume: float, source_object: Node2D = null, decay_on_despawn: bool = false) -> void:
	stop_sound(sound)
	play_sound(sound, base_volume, source_object, decay_on_despawn)


# HELPER FUNCTIONS


func update_viewport_rect() -> void:
	var viewport := get_viewport()
	if not viewport:
		return
		
	var camera := viewport.get_camera_2d()
	if not camera:
		return
		
	var camera_size: Vector2 = Vector2(viewport.size) / camera.zoom
	var camera_corner_top_left := camera.global_position - (camera_size / 2.0)
	
	viewport_rect = Rect2(camera_corner_top_left, camera_size)
