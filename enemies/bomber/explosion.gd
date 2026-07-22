extends Projectile

const ATTACK_POWER : int = 50
#const PLAYER_DAMAGE : int = 20 # make sure this isn't needed before delete
@onready var _timer := $Timer
@onready var _hitbox = $Hitbox
@onready var _smoke_particles := $SmokeParticles
@onready var _ember_particles := $EmberParticles


func _ready():
	_timer.start()
	_smoke_particles.emitting = true
	_ember_particles.emitting = true


func _on_area_entered(_area):
	if _area.is_in_group("enemies"):
		_area.receive_damage(ATTACK_POWER)


func _on_timer_timeout():
	$LightFlash.hide()
	_hitbox.disabled = true


func _on_smoke_particles_finished():
	queue_free()
