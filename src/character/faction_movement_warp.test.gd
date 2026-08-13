# GdUnit generated TestSuite
class_name FactionMovementWarpTest
extends GdUnitTestSuite

var instance: MarbleCharacter

func before_test() -> void:
	instance = mock("res://src/character/character.tscn", CALL_REAL_FUNC)
	add_child(instance)
	instance.player_id = ""
	do_return(true).on(instance).is_multiplayer_authority()

func after_test() -> void:
	pass

func test_warp_speed_affects_velocity() -> void:
	var other: MarbleCharacter = mock("res://src/character/character.tscn", CALL_REAL_FUNC)
	add_child(other)
	other.add_to_group("character")
	other.player_id = ""
	do_return(true).on(other).is_multiplayer_authority()

	instance.faction._init_default_relations(FactionStatic.Type.RED)
	other.faction._init_default_relations(FactionStatic.Type.RED)
	other.global_position = Vector3(10, 0, 0)

	# Test with warp_speed = 1
	instance.warp_speed = 1
	instance.velocity = Vector3.ZERO
	instance._apply_faction_movement(0.1)
	var velocity_warp_1:float = instance.velocity.x
	# Check that it actually moved
	assert_bool(velocity_warp_1 > 0.001).is_true()

	# Test with warp_speed = 2
	instance.warp_speed = 2
	instance.velocity = Vector3.ZERO
	instance._apply_faction_movement(0.1)
	var velocity_warp_2:float  = instance.velocity.x

	# We WANT it to be different (higher)
	assert_bool(velocity_warp_2 >= velocity_warp_1 * 1.5).is_true()
