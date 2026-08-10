extends CharacterBody2D

enum State {
	IDLE,
	CHARGING,
	CHARGED,
	TETHERED,
}

# EXPORT SYSTEM SETTINGS
@export_group("Scenes")
@export var arrow_dummy_scene: PackedScene
@export var bomber_dummy_scene: PackedScene
@export var parabolic_dummy_scene: PackedScene
@export var tether: PackedScene

@export_group("Sound Effects")
@export var tether_charge_sfx: AudioStream
@export var tether_ready_sfx: AudioStream
@export var tether_fail_sfx: AudioStream
@export var tether_latch_sfx: AudioStream
@export var light_hit_sfx: AudioStream
@export var heavy_hit_sfx: AudioStream
@export var electric_crackle_sfx: AudioStream


@export_group("Movement Physics")
@export var move_speed := 250.0
@export var acceleration: float = 12.0
@export var deceleration: float = 10.0

@export_group("Thruster Visuals")
@export var _flame_max_intensity: float = 24.0
@export var flame_fade_speed: float = 5.0

@export_group("Flags")
@export var is_invincible := false

# CORE STATE ENGINE
var state := State.IDLE:
	set(new_state):
		#print(new_state)
		
		if state == State.TETHERED and new_state != State.TETHERED:
			SignalBus.tether_toggled.emit(false)
			
		elif state == State.CHARGED and new_state == State.IDLE:
			AudioManager.play_sound(tether_fail_sfx)

		if new_state == State.CHARGING:
			AudioManager.play_sound(tether_charge_sfx, -6.0)
			
		elif new_state == State.TETHERED:
			SignalBus.tether_toggled.emit(true)
			AudioManager.play_sound(tether_latch_sfx)
			
		elif new_state == State.CHARGED:
			AudioManager.play_sound(tether_ready_sfx, 0.0, self, false)
			
		state = new_state

# NODE REFERENCES
@onready var level := get_parent()
@onready var health_bar := $HealthBarCanvas/HealthBar
@onready var camera := get_viewport().get_camera_2d()
@onready var sprite := %PlayerSprite
@onready var player_sprites = $PlayerSprites
@onready var sprite_reverse := %PlayerSpriteReverse
@onready var thruster_glow := %ThrusterGlow
@onready var thruster_glow_reverse := %ThrusterGlowReverse
@onready var i_frame_timer := %"I-FrameTimer"
@onready var charge_particles := %ChargeParticles
@onready var fail_particles := %FailParticles
@onready var tether_particles := %TetherParticles

# PLAYER AND MOVEMENT DATA
var health: int = 100
var _velocity := Vector2.ZERO
var _last_direction_x: float = 0.0

var new_dummy : Node2D = null
var _enemies_in_range: int = 0
var _targeted_enemy : Node2D = null
var _nearest_enemy : Node2D = null

# PARTICLE AND SYSTEM DATA

var _early_damping_value: int = 150
var _charge_timer: Timer = null
var _blink_tween: Tween = null

@onready var _default_damping_min: float = %ChargeParticles.damping_min
@onready var _default_damping_max: float = %ChargeParticles.damping_max


func _ready():
	health_bar._init_health(health)
	_charge_timer = Timer.new()
	_charge_timer.one_shot = true
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_on_charge_timer_timeout)
	
	$TetherRangeArea.area_entered.connect(func(_area): _enemies_in_range += 1)
	$TetherRangeArea.area_exited.connect(func(_area): _enemies_in_range -= 1)


func _unhandled_input(event: InputEvent) -> void:
	match state:
		State.IDLE:
			if event.is_action_pressed("Tether"):
				_charge_tether()
				state = State.CHARGING
		State.CHARGING:
			if event.is_action_released("Tether"):
				_exit_charge()
				state = State.IDLE
		State.CHARGED:
			if event.is_action_released("Tether"):
				if _enemies_in_range == 0:
					_exit_charge()
					fail_particles.restart()
					state = State.IDLE
				else:
					_deploy_tether()
					tether_particles.global_position = new_dummy.global_position
					tether_particles.look_at(global_position)
					tether_particles.restart()
					state = State.TETHERED
		State.TETHERED:
			if event.is_action_pressed("Tether"):
				_charge_tether()
				state = State.CHARGING


func _physics_process(delta: float) -> void:
	# PLAYER MOVEMENT AND BOUNDARY CLAMPING
	var input_direction = Input.get_vector("Stick Left", "Stick Right", "Stick Up", "Stick Down")
	if input_direction != Vector2.ZERO:
		_velocity = _velocity.lerp(input_direction * move_speed, acceleration * delta)
	else:
		_velocity = _velocity.lerp(Vector2.ZERO, deceleration * delta)
	position += _velocity * delta
	var camera_rect = get_static_camera_rect()
	position = position.clamp(camera_rect.position, camera_rect.end)

	# THRUSTER VISUALS AND DIRECTION FLIPPING
	var current_speed_x = abs(_velocity.x)
	var target_intensity = (current_speed_x / move_speed) * _flame_max_intensity
	var current_intensity = lerp(thruster_glow.modulate.r, target_intensity, flame_fade_speed * delta)
	var base_color = Color("ff4500")
	var target_color = base_color * current_intensity
	target_color.a = base_color.a * (current_intensity / _flame_max_intensity)
	thruster_glow.modulate = target_color
	thruster_glow_reverse.modulate = target_color
	if _velocity.x != 0 and sign(_velocity.x) != sign(_last_direction_x):
		_on_direction_flipped(sign(_velocity.x))
		_last_direction_x = _velocity.x
		
	# GAME OVER LOGIC
	if health <= 0:
		_im_gonna_kill_myself()


# PLAYER DAMAGE MECHANICS

func receive_damage(damage):
	if is_invincible or damage == 0:
		return
	
	AudioManager.play_sound(light_hit_sfx, 2.0)
	AudioManager.play_sound(heavy_hit_sfx, 4.0)
	AudioManager.play_sound(electric_crackle_sfx, 4.0)
	
	is_invincible = true
	i_frame_timer.start()
	
	health -= damage
	health_bar.health = health
	GameState.combo_counter /= 2
	
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(player_sprites, "modulate:a", 0.2, 0.01)
	_blink_tween.tween_interval(0.09)
	_blink_tween.tween_property(player_sprites, "modulate:a", 1.0, 0.01)
	_blink_tween.tween_interval(0.09)


func _im_gonna_kill_myself():
	self.queue_free()
	GameState.is_game_over = true


# TETHER MEHCANICS

func _deploy_tether():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = INF
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			_nearest_enemy = enemy
	if _nearest_enemy != null:
		_targeted_enemy = _nearest_enemy
		swap_and_tether(
			_targeted_enemy.position,
			_targeted_enemy.rotation,
			_targeted_enemy.health,
			_targeted_enemy.enemy_name,
		)


func swap_and_tether(
		enemy_position: Vector2,
		 enemy_rotation: float,
		 enemy_health: float,
		 enemy_name: String,
	):
	
	if enemy_name == "arrow":
		new_dummy = arrow_dummy_scene.instantiate()
	elif enemy_name == "bomber":
		new_dummy = bomber_dummy_scene.instantiate()
	elif enemy_name == "parabolic":
		new_dummy = parabolic_dummy_scene.instantiate()
		
	new_dummy.health = enemy_health
	new_dummy.global_position = enemy_position - position
	new_dummy.rotation = enemy_rotation
	add_child(new_dummy)
	new_dummy.reparent(level)
	_targeted_enemy.queue_free()
	
	var new_tether = tether.instantiate()
	new_tether.tether_origin_node = self
	level.add_child(new_tether)


func sever_tether_externally():
	state = State.IDLE


func _charge_tether():
	charge_particles.damping_min = _default_damping_min
	charge_particles.damping_max = _default_damping_max
	charge_particles.restart()
	_charge_timer.start(charge_particles.lifetime)


func _exit_charge():
	AudioManager.stop_sound(tether_charge_sfx)
	charge_particles.emitting = false
	charge_particles.damping_min = _early_damping_value
	_charge_timer.stop()


# SPRITE ANIMATION
func _on_direction_flipped(x_direction: float) -> void:
	if x_direction > 0:
		sprite.show()
		sprite_reverse.hide()
		thruster_glow.show()
		thruster_glow_reverse.hide()
	elif x_direction < 0:
		sprite.hide()
		sprite_reverse.show()
		thruster_glow.hide()
		thruster_glow_reverse.show()


# MISC
func get_static_camera_rect() -> Rect2:
	var camera_size = get_viewport_rect().size / camera.zoom
	var camera_corner_top_left := Vector2(camera.global_position - (camera_size / 2))
	return Rect2(camera_corner_top_left, camera_size)


# SIGNAL CALLBACKS
func _on_charge_timer_timeout():
	if state != State.CHARGING:
		return
	var flash_tween = create_tween()
	player_sprites.modulate = Color(10, 10, 10, 1)
	flash_tween.tween_property(player_sprites, "modulate", Color.WHITE, 0.3)
	state = State.CHARGED


func _on_i_frame_timer_timeout():
	is_invincible = false
	
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
		
	player_sprites.modulate.a = 1.0
