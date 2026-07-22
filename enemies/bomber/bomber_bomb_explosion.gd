extends Area2D

const ATTACK_POWER : int = 20
@onready var _timer := $Timer
@onready var _ember_particles := %EmberParticles
@onready var _smoke_particles := %SmokeParticles
@onready var _light_flash := $LightFlash
@onready var _hitbox := $Hitbox
@onready var _player := get_tree().get_first_node_in_group("player")


func _ready():
	_timer.start()
	_ember_particles.emitting = true
	_smoke_particles.emitting = true



func _on_timer_timeout():
	_light_flash.hide()
	_hitbox.set_deferred("disabled", true)

func _on_player_entered(hurtbox):
	if hurtbox.is_in_group("player"):
		_player.receive_damage(ATTACK_POWER)


func _on_smoke_particles_finished():
	queue_free()
