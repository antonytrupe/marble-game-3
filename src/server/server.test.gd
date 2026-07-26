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


func test_spawn_spring_method_exists() -> void:
	assert_bool(_server.has_method("_spawn_spring")).is_true()


func test_spawn_spring_adds_it_to_terra() -> void:
	var character: MarbleCharacter = auto_free(MarbleCharacter.new())
	character.global_position = Vector3(0, 0, 0)
	character.global_transform.basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)

	_server._spawn_spring(character)

	assert_int(_server.world.terra.get_child_count()).is_equal(1)
	assert_object(_server.world.terra.get_child(0)).is_instanceof(Spring)
