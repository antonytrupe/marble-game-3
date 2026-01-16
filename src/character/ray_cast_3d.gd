extends RayCast3D

var last_target: MeshInstance3D = null

func _process(_delta):
	if is_colliding():
		var collider = get_collider()
		# Find the MeshInstance3D child if the collider is a PhysicsBody
		var mesh = collider.get_node_or_null("HighlightMeshInstance3D")

		if mesh and mesh != last_target:
			#print('colliding with raycast')
			_clear_highlight()
			_set_highlight(mesh, 1.0)
			last_target = mesh
		else:
			_clear_highlight()
	else:
		_clear_highlight()


func _set_highlight(mesh: MeshInstance3D, value: float):
	# Use set_shader_parameter to toggle the effect
	var mat = mesh.mesh.material as ShaderMaterial
	#print(mat)
	if mat:
		mat.set_shader_parameter("intensity", value)


func _clear_highlight():
	if last_target:
		_set_highlight(last_target, 0.0)
		last_target = null
