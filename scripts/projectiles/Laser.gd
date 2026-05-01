extends Node2D

@export var speed = 1500

func _process(delta):
	
	self.position.x += speed * delta


func _on_area_entered(otherArea):
	
	if otherArea.is_in_group("enemy"):
		self.queue_free()
