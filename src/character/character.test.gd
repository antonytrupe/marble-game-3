# GdUnit generated TestSuite
class_name MarbleCharacterTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://src/character/character.gd'
const MarbleCharacterScene: PackedScene = preload("res://src/character/character.tscn")


var instance: MarbleCharacter

func before_test() -> void:
	instance = auto_free(MarbleCharacterScene.instantiate())
	add_child(instance)


func after_test() -> void:
	# auto_free in before_test handles cleanup
	pass


func test_vector_to_string() -> void:
	var v:Vector3 = Vector3(1, 2, 3)
	var s:String = var_to_str(v)
	assert_str(s).is_equal('Vector3(1, 2, 3)')


func test_initial_state() -> void:
	assert_that(instance.standard_action).is_true()
	assert_that(instance.mode).is_equal(MarbleCharacter.MODE.WALK)
	assert_that(instance.actions).is_empty()


func test_get_subject_verbs_returns_pick_up() -> void:
	var verbs: Array[Callable] = instance.get_subject_verbs()
	assert_that(verbs).has_size(1)
	assert_that(verbs[0].get_method()).is_equal("pick_up")


func test_get_object_verbs_returns_empty() -> void:
	var verbs: Array[Callable] = instance.get_object_verbs([])
	assert_that(verbs).is_empty()


func test_default_faction_is_none() -> void:
	assert_that(instance.faction).is_equal(Faction.Type.NONE)


func test_setting_color_assigns_faction() -> void:
	instance.color = Color(0.8, 0.1, 0.1, 1)
	assert_that(instance.faction).is_equal(Faction.Type.RED)


func test_get_faction_name() -> void:
	instance.color = Color(0.1, 0.2, 0.8, 1)
	assert_str(instance.get_faction_name()).is_equal("Azure Covenant")


func test_color_persisted_in_data() -> void:
	instance.color = Color(0.1, 0.6, 0.15, 1)
	var data: Dictionary = instance.get_data()
	assert_that(data.has("color")).is_true()


func test_player_controlled_skips_faction_movement() -> void:
	instance.player_id = "Steam_123"
	assert_that(instance._is_player_controlled()).is_true()


func test_npc_is_not_player_controlled() -> void:
	instance.player_id = ""
	assert_that(instance._is_player_controlled()).is_false()


func test_faction_movement_attracts_same_faction() -> void:
	instance.player_id = ""
	instance.color = Faction.get_faction_color(Faction.Type.RED)
	instance.global_position = Vector3.ZERO

	var ally: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	ally.player_id = ""
	ally.color = Faction.get_faction_color(Faction.Type.RED)
	ally.global_position = Vector3(10, 0, 0)
	add_child(ally)

	instance._apply_faction_movement(1.0)
	# velocity should have positive x component (toward ally)
	assert_that(instance.velocity.x > 0).is_true()


func test_faction_movement_repels_other_faction() -> void:
	instance.player_id = ""
	instance.color = Faction.get_faction_color(Faction.Type.RED)
	instance.global_position = Vector3.ZERO

	var enemy: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	enemy.player_id = ""
	enemy.color = Faction.get_faction_color(Faction.Type.BLUE)
	enemy.global_position = Vector3(10, 0, 0)
	add_child(enemy)

	instance._apply_faction_movement(1.0)
	# velocity should have negative x component (away from enemy)
	assert_that(instance.velocity.x < 0).is_true()


func test_separation_repels_same_faction_when_too_close() -> void:
	instance.player_id = ""
	instance.color = Faction.get_faction_color(Faction.Type.RED)
	instance.global_position = Vector3.ZERO

	var ally: MarbleCharacter = auto_free(MarbleCharacterScene.instantiate())
	ally.player_id = ""
	ally.color = Faction.get_faction_color(Faction.Type.RED)
	ally.global_position = Vector3(1, 0, 0)  # within SEPARATION_DISTANCE
	add_child(ally)

	instance._apply_faction_movement(1.0)
	# velocity should have negative x component (pushed away despite same faction)
	assert_that(instance.velocity.x < 0).is_true()
