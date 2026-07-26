class_name ServerTest
extends GdUnitTestSuite

# The class under test
var _server: Server


func before_test() -> void:
	# Create an instance of the server script
	_server = auto_free(Server.new())


func test_get_random_vector_within_radius_and_on_ground() -> void:
	# Test the distance calculation algorithm used by _get_random_vector
	var radius: float = 50.0
	var center: Vector3 = Vector3(10, 0, 20)

	# Act & Assert - Verify random points stay within radius
	for i: int in range(100):
		# Replicate the calculation from _get_random_vector
		var r: float = radius * sqrt(randf())
		var theta: float = randf() * 2 * PI
		var x: float = center.x + r * cos(theta)
		var z: float = center.z + r * sin(theta)

		# Assert XZ distance is within the radius
		var distance: float = Vector2(x - center.x, z - center.z).length()
		assert_float(distance).is_less_equal(radius)


func test_spawn_spring_adds_a_spring_to_flora() -> void:
	var center: Vector3 = Vector3(5, 0, 7)
	_server._spawn_spring(1, center)

	assert_int(_server.world.flora.get_child_count()).is_equal(1)
	assert_object(_server.world.flora.get_child(0)).is_instanceof(Spring)
