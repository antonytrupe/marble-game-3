# GdUnit generated TestSuite
class_name AxeTest
extends GdUnitTestSuite

var AxeScene: PackedScene = load("res://src/axe/axe.tscn")

func test_pick_up() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	var result: Array = instance.pick_up(MarbleCharacter.INTERACT.RIGHT, [])
	assert_that(result).is_equal([instance])

func test_chop() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	var result: Array = instance.chop(MarbleCharacter.INTERACT.RIGHT, [])
	assert_that(result).is_empty()

func test_transfer() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	var result: bool = instance.transfer(MarbleCharacter.INTERACT.RIGHT, [])
	assert_that(result).is_true()

func test_get_object_verbs() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	
	# Case: subject has pick_up
	var verbs: Array[Callable] = instance.get_object_verbs(["pick_up"])
	assert_that(verbs.size()).is_equal(1)
	assert_that(verbs.map(func(f: Callable)-> String: return f.get_method())).contains("pick_up")
	
	# Case: subject does not have pick_up
	verbs = instance.get_object_verbs(["other"])
	assert_that(verbs).is_empty()

func test_get_subject_verbs() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	var verbs: Array[Callable] = instance.get_subject_verbs()
	assert_that(verbs.size()).is_equal(2)
	var methods: Array = verbs.map(func(f: Callable)-> String: return f.get_method())
	assert_that(methods).contains("chop")
	assert_that(methods).contains("transfer")

func test_get_data() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	add_child(instance)
	instance.name = "TestAxe"
	instance.marble_item.warp_speed = 2.5
	instance.marble_item.age.age = 10.0
	
	var data: Dictionary = instance.get_data()
	assert_that(data.get("name")).is_equal("TestAxe")
	assert_that(data.get("warp_speed")).is_equal(2.5)
	assert_that(data.get("age")).is_equal(10.0)
	assert_that(data.has("transform")).is_true()

func test_load_pre_ready() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	var new_transform: Transform3D = Transform3D(Basis.IDENTITY, Vector3(1, 2, 3))
	var data: Dictionary = {
		"transform": var_to_str(new_transform)
	}
	instance.load_pre_ready(data)
	assert_that(instance.transform).is_equal(new_transform)

func test_load_post_ready() -> void:
	var instance: Axe = auto_free(AxeScene.instantiate())
	add_child(instance)
	var data: Dictionary = {
		"age": 50.0,
		"warp_speed": 3.0
	}
	instance.load_post_ready(data)
	assert_that(instance.marble_item.age.age).is_equal(50.0)
	assert_that(instance.marble_item.warp_speed).is_equal(3.0)
