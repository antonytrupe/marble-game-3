class_name Utilities
extends Node


static func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	var r :float= radius * sqrt(randf())
	var theta :float= randf() * 2 * PI
	var x :float= center.x + r * cos(theta)
	var z :float= center.z + r * sin(theta)
	return Vector3(x, 0, z)


static func get_random_point_in_cone_of_sphere(
	cone_origin: Vector3, cone_direction: Vector3, cone_height: float, cone_angle: float
) -> Vector3:
	"""
	Generates a random point uniformly distributed within a spherical cone.
	Args:
		cone_origin: The tip of the cone.
		cone_direction: The axis vector of the cone (should be normalized).
		cone_height: The height of the cone.
		cone_angle: The half-angle of the cone in radians.
	Returns:
		A random Vector3 point inside the specified cone.
	"""

	# Ensure the cone direction is a normalized vector.
	cone_direction = cone_direction.normalized()

	# Step 1: Generate a random distance from the cone's origin.
	# To get a uniform volume distribution, use the cube root of a uniform random number.
	var dist :float= pow(randf(), 1.0 / 3.0) * cone_height

	# Step 2: Generate a random direction vector inside a cone aligned with the Z-axis.
	# Uniformly distribute the polar angle theta within the cone's angle.
	var cos_half_angle :float= cos(cone_angle)
	var u :float= randf()
	var theta :float= acos(u * (1.0 - cos_half_angle) + cos_half_angle)

	# Uniformly distribute the azimuthal angle phi (from 0 to 2*PI).
	var phi :float= randf() * TAU
	# Convert spherical coordinates to a Cartesian vector aligned with the Z-axis (Vector3.FORWARD).
	var local_point:Vector3 = Vector3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))

	# Step 3: Rotate the local point from the Z-axis to the specified cone axis.
	# The correct way to get the quaternion for this rotation is with the constructor.
	var rotation = Quaternion(Vector3.FORWARD, cone_direction)
	var rotated_point = rotation.xform(local_point)

	# Step 4: Combine the cone's origin, the rotated direction, and the distance.
	return cone_origin + (rotated_point * dist)
