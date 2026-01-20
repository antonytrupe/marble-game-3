extends RichTextLabel


func _process(_delta: float) -> void:
	# Set the text to display "FPS: " followed by the current frames per second
	text = "FPS: %d" % Engine.get_frames_per_second()
