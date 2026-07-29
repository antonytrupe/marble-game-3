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
