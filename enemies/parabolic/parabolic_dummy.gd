extends Dummy


enum State {
	PASSIVE,
	SPECIAL,
	EXCITED,
}





@onready var _hitbox_default := $Area2D/HitboxDefault
@onready var _hitbox_excited := $Area2D/HitboxExcited
@onready var _excited_particles := $ExcitedParticles
@onready var _multihit_timer := $MultihitTimer

@export var rebound_force: int = 320

var state := State.PASSIVE:
	set(new_state):
		state = new_state
		if state == State.SPECIAL:
			_enter_special_state()
		elif state == State.EXCITED:
			_enter_excited_state()

var _rebound_direction: Vector2
var _rotation_speed: int = 20
var _is_arc_crested := false

func _ready():
	super()
	attack_power = 75


func _physics_process(delta: float):
	super(delta)
	
	match state:
		State.PASSIVE:
			if current_speed > speed_limit:
				linear_velocity = linear_velocity.normalized() * speed_limit
			
			if player:
				if player.is_tethered == false:
					state = State.SPECIAL
		State.SPECIAL:
			apply_central_force(rebound_force * _rebound_direction)
			angular_velocity = _rotation_speed
			
			if not _is_arc_crested and linear_velocity.dot(_rebound_direction) > 0:
				_is_arc_crested = true
				state = State.EXCITED
		State.EXCITED:
			apply_central_force(rebound_force * _rebound_direction)
			angular_velocity = _rotation_speed


func _enter_special_state():
	gravity_scale = 0.0
	attack_power = 100
	
	if linear_velocity.y >= 0:
		_rebound_direction = Vector2.UP
	else:
		_rebound_direction = Vector2.DOWN


func _enter_excited_state():
	_hitbox_default.disabled = true
	_hitbox_excited.disabled = false
	_excited_particles.emitting = true

# uncomment to turn on multihit code
#func _on_area_entered(entered_area):
	#super(entered_area)
	#
	#if state == State.EXCITED and entered_area.is_in_group("enemies"):
		#_hitbox_excited.set_deferred("disabled", true)
		#_multihit_timer.start()

func _on_multihit_timer_timeout():
	_hitbox_excited.disabled = false
