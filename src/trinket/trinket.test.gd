# GdUnit generated TestSuite
class_name TrinketTest
extends GdUnitTestSuite

var TrinketScene: PackedScene = load("res://src/trinket/trinket.tscn")

func test_get_subject_verbs() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	var verbs: Array[Callable] = instance.get_subject_verbs()
	assert_that(verbs.size()).is_equal(1)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("transfer")

func test_transfer() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	var result: bool = instance.transfer(MarbleCharacter.INTERACT.RIGHT, [])
	assert_that(result).is_true()

func test_get_object_verbs() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	
	# Case: subject has pick_up
	var verbs: Array[Callable] = instance.get_object_verbs(["pick_up"])
	assert_that(verbs.size()).is_equal(1)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("pick_up")
	
	# Case: subject does not have pick_up
	verbs = instance.get_object_verbs(["other"])
	assert_that(verbs).is_empty()

func test_pick_up() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	var result: Array = instance.pick_up(MarbleCharacter.INTERACT.RIGHT, [])
	assert_that(result).is_equal([instance])

func test_get_data() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	instance.name = "TestTrinket"
	var data: Dictionary = instance.get_data()
	assert_that(data.get("name")).is_equal("TestTrinket")
	assert_that(data.get("scene_file_path")).is_equal("res://src/trinket/trinket.tscn")
	assert_that(data.has("transform")).is_true()

func test_load_pre_ready() -> void:
	var instance: Trinket = auto_free(TrinketScene.instantiate())
	var new_transform: Transform3D = Transform3D(Basis.IDENTITY, Vector3(1, 2, 3))
	var data: Dictionary = {
		"transform": var_to_str(new_transform)
	}
	instance.load_pre_ready(data)
	assert_that(instance.transform).is_equal(new_transform)
