extends Node2D

@export var sparks_scene : PackedScene

func _ready():
	child_entered_tree.connect(_manage_cleanup)
	SignalBus.player_hit.connect(_spawn_sparks.bind(Color.YELLOW))
	SignalBus.enemy_hit.connect(_spawn_sparks.bind(Color(1.0, 0.518, 0.345, 1.0)))

func _spawn_sparks(_position:Vector2, impact_position:Vector2, spark_color: Color):
	var sparks : CPUParticles2D = sparks_scene.instantiate()
	add_child(sparks)
	sparks.position = _position
	sparks.look_at(impact_position)
	sparks.color = spark_color
	
	sparks.emitting = true


func _manage_cleanup(node: Node):
	if node is CPUParticles2D or node is GPUParticles2D:
		var time = node.lifetime / node.speed_scale
		get_tree().create_timer(time).timeout.connect(node.queue_free)
