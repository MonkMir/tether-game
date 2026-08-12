extends Label

func _process(_delta):
	self.text = "Score: " + str(GameState.score)
	
	# DEBUG
	#text = str(Engine.get_frames_per_second())
