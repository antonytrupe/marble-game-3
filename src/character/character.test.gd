# GdUnit generated TestSuite
class_name MarbleCharacterTest
extends GdUnitTestSuite

@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')
# TestSuite generated from
#const __source: String = 'res://src/character/character.gd'
var MarbleCharacterScene: PackedScene = load("res://src/character/character.tscn")

var instance: MarbleCharacter

func before_test() -> void:
	instance = mock("res://src/character/character.tscn", CALL_REAL_FUNC)
	add_child(instance)

func after_test() -> void:
	# auto_free in before_test handles cleanup
	pass


func test_vector_to_string() -> void:
	var v: Vector3 = Vector3(1, 2, 3)
	var s: String = var_to_str(v)
	assert_str(s).is_equal('Vector3(1, 2, 3)')


func test_initial_state() -> void:
	assert_that(instance.standard_action).is_true()
	assert_that(instance.mode).is_equal(MarbleCharacter.MODE.WALK)
	assert_that(instance.actions).is_empty()


func test_get_subject_verbs_returns_pick_up() -> void:
	var verbs: Array[Callable] = instance.get_subject_verbs()
	assert_that(verbs.size()).is_greater(0)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("pick_up")


func test_get_subject_verbs_returns_transfer() -> void:
	var verbs: Array[Callable] = instance.get_subject_verbs()
	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	instance.right_inventory = trinket
	assert_that(verbs.size()).is_greater(0)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("transfer")


func test_get_indirect_object_verbs_returns_transfer() -> void:
	var verbs: Array[Callable] = instance.get_indirect_object_verbs()
	assert_that(verbs.size()).is_greater(0)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("transfer")


func test_mock_is_server_true() -> void:
	do_return(true).on(instance).is_server()
	assert_that(instance.is_server()).is_true()


func test_mock_is_server_false() -> void:
	do_return(false).on(instance).is_server()
	assert_that(instance.is_server()).is_false()


func test_mock_raycast_is_colliding() -> void:
	do_return(true).on(instance).raycast_is_colliding()
	assert_that(instance.raycast_is_colliding()).is_true()


func test_pick_up_item_right_hand() -> void:
	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	add_child(trinket)
	do_return(true).on(instance).is_server()
	do_return(true).on(instance).raycast_is_colliding()
	do_return(trinket).on(instance).get_target()
	do_return(Vector3.ZERO).on(instance).get_collision_point()

	instance.interact(MarbleCharacter.INTERACT.RIGHT)
	assert_that(instance.right_inventory).is_equal(trinket)


func test_pick_up_item_left_hand() -> void:
	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	add_child(trinket)
	do_return(true).on(instance).is_server()
	do_return(true).on(instance).raycast_is_colliding()
	do_return(trinket).on(instance).get_target()
	do_return(Vector3.ZERO).on(instance).get_collision_point()
	instance.interact(MarbleCharacter.INTERACT.LEFT)
	assert_that(instance.right_inventory).is_null()
	assert_that(instance.left_inventory).is_equal(trinket)


func test_pick_up_trinket_right_hand_rotation_alignment() -> void:
	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	add_child(trinket)
	# Set a specific rotation for the trinket
	trinket.rotation = Vector3(1, 1, 1)

	do_return(true).on(instance).is_server()
	do_return(true).on(instance).raycast_is_colliding()
	do_return(trinket).on(instance).get_target()
	do_return(Vector3.ZERO).on(instance).get_collision_point()

	instance.interact(MarbleCharacter.INTERACT.RIGHT)

	# After pick_up, the trinket's rotation should match the hand marker's rotation
	assert_that(trinket.global_transform.basis).is_equal(instance.inventory_right_marker.global_transform.basis)


func test_transfer_trinket_from_character_to_character() -> void:
	var receiver: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	add_child(receiver)
	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	add_child(trinket)
	instance.right_inventory = trinket
	assert_that(instance.right_inventory).is_equal(trinket)
	var result: bool = instance.transfer(MarbleCharacter.INTERACT.RIGHT, [trinket], receiver)
	assert_that(result).is_true()
	assert_that(instance.right_inventory).is_null()
	assert_that(receiver.right_inventory).is_equal(trinket)


func test_transfer_trinket_from_character_to_character_via_interact() -> void:
	do_return(true).on(instance).is_server()
	do_return(true).on(instance).raycast_is_colliding()
	do_return(Vector3.ZERO).on(instance).get_collision_point()

	var receiver: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	add_child(receiver)
	do_return(receiver).on(instance).get_target()

	var trinket: Trinket = auto_free(Trinket.scene.instantiate())
	add_child(trinket)
	#do_return(trinket).on(instance).get_target()

	instance.right_inventory = trinket
	assert_that(instance.right_inventory).is_equal(trinket)

	# Act
	instance.interact(MarbleCharacter.INTERACT.RIGHT)

	# Assert
	assert_that(instance.right_inventory).is_null()
	assert_that(receiver.right_inventory).is_equal(trinket)


func test_transfer_axe_from_character_to_character_via_interact() -> void:
	do_return(true).on(instance).is_server()
	do_return(true).on(instance).raycast_is_colliding()
	do_return(Vector3.ZERO).on(instance).get_collision_point()

	var receiver: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	add_child(receiver)
	do_return(receiver).on(instance).get_target()

	var axe: Axe = auto_free(Axe.scene.instantiate())
	add_child(axe)
	#do_return(trinket).on(instance).get_target()

	instance.right_inventory = axe
	assert_that(instance.right_inventory).is_equal(axe)

	# Act
	instance.interact(MarbleCharacter.INTERACT.RIGHT)

	# Assert
	assert_that(instance.right_inventory).is_null()
	assert_that(receiver.right_inventory).is_equal(axe)


func test_get_object_verbs_returns_empty() -> void:
	var verbs: Array[Callable] = instance.get_object_verbs([])
	assert_that(verbs).is_empty()


func test_default_faction_is_none() -> void:
	assert_that(instance.faction.get_main_faction()).is_equal(FactionStatic.Type.NONE)


func test_setting_faction_assigns_faction() -> void:
	instance.faction = Faction.new(FactionStatic.Type.RED)
	assert_that(instance.faction.get_main_faction()).is_equal(FactionStatic.Type.RED)


func test_get_faction_name() -> void:
	instance.faction = Faction.new(FactionStatic.Type.BLUE)
	assert_str(instance.get_faction_name()).is_equal("Azure Alliance")


func test_faction_persisted_in_data() -> void:
	instance.faction = Faction.new(FactionStatic.Type.GREEN)
	var data: Dictionary = instance.get_data()
	assert_that(data.has("faction_relations")).is_true()


func test_default_relations_for_none_faction() -> void:
	assert_float(instance.faction.get_relation(FactionStatic.Type.RED)).is_equal(0.0)
	assert_float(instance.faction.get_relation(FactionStatic.Type.BLUE)).is_equal(0.0)


func test_default_relations_for_assigned_faction() -> void:
	var faction :FactionStatic.Type= FactionStatic.Type.RED
	instance.faction._init_default_relations(faction)
	assert_float(instance.faction.get_relation(FactionStatic.Type.RED)).is_greater(0.8)
	assert_float(instance.faction.get_relation(FactionStatic.Type.BLUE)).is_greater_equal(-1.0)
	assert_float(instance.faction.get_relation(FactionStatic.Type.BLUE)).is_less_equal(0.8)
	assert_float(instance.faction.get_relation(FactionStatic.Type.NONE)).is_equal(0.0)


func test_get_main_faction_returns_highest_relation() -> void:
	var faction :FactionStatic.Type= FactionStatic.Type.RED
	instance.faction._init_default_relations(faction)
	assert_that(instance.faction.get_main_faction()).is_equal(FactionStatic.Type.RED)
	# Override BLUE to be higher than RED
	instance.faction.set_relation(FactionStatic.Type.BLUE, 1.0)
	instance.faction.set_relation(FactionStatic.Type.RED, 0.5)
	assert_that(instance.faction.get_main_faction()).is_equal(FactionStatic.Type.BLUE)


func test_get_main_faction_returns_none_when_no_relations() -> void:
	assert_that(instance.faction.get_main_faction()).is_equal(FactionStatic.Type.NONE)


func test_set_relation_clamps_value() -> void:
	instance.faction.set_relation(FactionStatic.Type.BLUE, 2.0)
	assert_float(instance.faction.get_relation(FactionStatic.Type.BLUE)).is_equal(1.0)
	instance.faction.set_relation(FactionStatic.Type.BLUE, -5.0)
	assert_float(instance.faction.get_relation(FactionStatic.Type.BLUE)).is_equal(-1.0)


func test_custom_relation_affects_movement(_do_skip :bool= true) -> void:
	instance.player_id = ""
	#var faction:FactionStatic.Type = FactionStatic.Type.RED
	instance.faction._init_default_relations(FactionStatic.Type.RED)
	# Make RED friendly toward BLUE
	instance.faction.set_relation(FactionStatic.Type.BLUE, 0.8)
	instance.global_position = Vector3.ZERO

	var other: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	other.player_id = ""
	add_child(other)
	other.faction = auto_free(Faction.new(FactionStatic.Type.RED))
	other.global_position = Vector3(10, 0, 0)

	instance._apply_faction_movement(1.0)
	# Should attract (positive x) since relation is friendly
	assert_that(instance.velocity.x).is_greater(0.0)


func test_player_controlled_skips_faction_movement() -> void:
	instance.player_id = "Steam_123"
	assert_that(instance._is_player_controlled()).is_true()


func test_npc_is_not_player_controlled() -> void:
	instance.player_id = ""
	assert_that(instance._is_player_controlled()).is_false()


func test_faction_movement_attracts_same_faction(_do_skip :bool= true) -> void:
	instance.player_id = ""
	var faction:FactionStatic.Type = FactionStatic.Type.RED
	instance.faction._init_default_relations(faction)
	instance.global_position = Vector3.ZERO

	var ally: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	ally.player_id = ""
	add_child(ally)
	ally.faction = auto_free(Faction.new(FactionStatic.Type.RED))
	ally.global_position = Vector3(10, 0, 0)

	instance._apply_faction_movement(1.0)
	# velocity should have positive x component (toward ally)
	assert_that(instance.velocity.x > 0).is_true()


func test_faction_movement_repels_other_faction(_do_skip :bool= true) -> void:
	instance.player_id = ""
	var faction :FactionStatic.Type= FactionStatic.Type.RED
	instance.faction._init_default_relations(faction)
	instance.global_position = Vector3.ZERO

	var enemy: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	enemy.player_id = ""
	add_child(enemy)
	enemy.faction = auto_free(Faction.new(FactionStatic.Type.BLUE))
	enemy.global_position = Vector3(10, 0, 0)

	instance._apply_faction_movement(1.0)
	# velocity should have negative x component (away from enemy)
	assert_that(instance.velocity.x < 0).is_true()


func test_separation_repels_same_faction_when_too_close() -> void:
	instance.player_id = ""
	var faction :FactionStatic.Type= FactionStatic.Type.RED
	instance.faction._init_default_relations(faction)
	instance.global_position = Vector3.ZERO

	var ally: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	ally.player_id = ""
	add_child(ally)
	ally.faction = auto_free(Faction.new(FactionStatic.Type.RED))
	ally.global_position = Vector3(1, 0, 0)  # within SEPARATION_DISTANCE

	instance._apply_faction_movement(1.0)
	# velocity should have negative x component (pushed away despite same faction)
	assert_that(instance.velocity.x < 0).is_true()
