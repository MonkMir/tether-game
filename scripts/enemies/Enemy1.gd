extends Area2D


var isTargeted : bool = false : set = init_spawn_dummy #modified from player script

var enemyType := "arrow"
var baseSpeed := 200
var speed := baseSpeed
var scoreGain := 10

func _process(delta):
	position.x -= speed * delta
	
	
#DEATH SCRIPT
func _on_area_entered(area): #should I do _area? what value is area receiving???
	GameState.score += scoreGain
	self.queue_free()
	#Should I fix score increase on game over?

func init_spawn_dummy(_isTargeted):
	var player := get_node("/root/Main/Player") #can we figure out why relative path didn't work?
	player.call("swap_and_tether", global_position, rotation, enemyType)
	queue_free()
