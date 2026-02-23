extends Button

func _get_drag_data(_at_position: Vector2) -> Variant:
	var root: Control = get_owner()
	set_drag_preview(root.duplicate(16))
	root.visible = false
	return root
