extends TextEdit

func _input(_event: InputEvent):
	if Input.is_action_just_pressed("chat"):
		release_focus()
