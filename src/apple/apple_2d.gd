class_name Apple2D
extends RigidBody2D

var is_dragging: bool = false
var is_dropping: bool = false

@onready var item: MarbleItem = %MarbleItem

func _input(event: InputEvent) -> void:
	# Stop dragging when the mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	print('_on_input_event')
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: # Mouse button down (Click/Start Drag)
				is_dragging = true
				# Set mode to static to stop physics, keep collision
				self.freeze = false
				# Calculate offset from center for smooth dragging
				#mouse_offset = global_position - event.global_position
				print('dragging')
			else: # Mouse button up (Release)
				print('stop dragging')
				is_dragging = false
				# Re-enable physics, body will sleep until next interaction
				if not is_dropping:
					self.freeze = true
				# Optionally "throw" the object on release by applying a small impulse
				# apply_central_impulse(Vector2(randf_range(-50, 50), randf_range(-50, 50))) # Example throw


func _physics_process(_delta: float) -> void:
	if is_dragging:
		var target_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = global_position.direction_to(target_pos)
		var distance: float = global_position.distance_to(target_pos)
		# Apply a force proportional to the distance to pull it toward the mouse
		apply_central_force(direction * distance * 100)
		# Add dampening to prevent orbiting the cursor
		linear_velocity *= 0.9
	elif not is_dropping:
		linear_velocity = Vector2(0, 0)
