# Use the GdUnitTestSuite base class
class_name Transform3dTest
extends GdUnitTestSuite

# Individual test case
func test_transform_serialization_roundtrip() -> void:
	print('foo')
	# 1. Arrange: Create a non-default Transform3D
	var original: Transform3D = Transform3D(
			Basis(Vector3.UP, deg_to_rad(45.0)).scaled(Vector3(2, 2, 2)),
			Vector3(10.5, -5.0, 0.0000000000000001)  # Small value to test scientific notation
	)

	# 2. Act: Convert to String and back to Variant
	var serialized_str: String = var_to_str(original)
	print(serialized_str)
	var deserialized_obj: Transform3D = str_to_var(serialized_str)
	print(deserialized_obj)

	# 3. Assert: Verify the resulting object is a Transform3D and matches the original
	assert_that(deserialized_obj).is_not_null()
	assert_that(typeof(deserialized_obj)).is_equal(TYPE_TRANSFORM3D)

	# Use is_equal_approx to handle floating point precision in scientific notation
	var result: Transform3D = deserialized_obj
	assert_bool(result.is_equal_approx(original)).is_true()

# Parameterized test for scientific notation/edge cases
func test_extreme_values_serialization(value: float, test_parameters: Array=[
	[0.000000000123],  # Scientific notation (1.23e-10)
	[999999999.9],  # Large value
	[-0.0]  # Negative zero
]) -> void:
	var original: Transform3D = Transform3D(Basis(), Vector3(value, 0, 0))
	var roundtrip: Transform3D = str_to_var(var_to_str(original))

	assert_bool(roundtrip.is_equal_approx(original)).is_true()
