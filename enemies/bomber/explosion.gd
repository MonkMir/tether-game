extends Projectile


const ATTACK_POWER : int = 50


@export var large_explosion_sfx : AudioStream

@onready var _timer := $Timer
@onready var _hitbox = $Hitbox
@onready var _smoke_particles := $SmokeParticles
@onready var _ember_particles := $EmberParticles


func _ready():
	_timer.start()
	_smoke_particles.emitting = true
	_ember_particles.emitting = true
	AudioManager.play_sound(large_explosion_sfx, -2.0)


func _on_area_entered(_area):
#if is_queued_for_deletion(): # see if this is a real issue before enabling
		#return
	
	if _area.is_in_group("enemies"):
		
		var victim_id : int = _area.get_instance_id()
		GameState.hit_transaction_registry[victim_id] = {
		"attacker_type" : "bomber",
		"is_tethered" : false,
		"victim_position" : _area.global_position,
		}
		
		_area.receive_damage(ATTACK_POWER)
		SignalBus.enemy_hit.emit(self.global_position, _area.global_position)


func _on_timer_timeout():
	$LightFlash.hide()
	_hitbox.set_deferred("disabled", true)


func _on_smoke_particles_finished():
	queue_free()
