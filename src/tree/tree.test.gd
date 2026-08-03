class_name MarbleTreeTest
extends GdUnitTestSuite


var instance: MarbleTree

func before_test() -> void:
	var scene:MarbleTree = auto_free(MarbleTree.scene.instantiate())
	add_child(scene)
	instance = spy(scene)
	
	
func test_not_null() -> void:
	assert_bool(true)
	assert_that(instance).is_not_null()
	
	
func test_mock_get_data()->void:
	do_return({"test":"test"}).on(instance).get_data()
	assert_that(instance.get_data()).is_equal({"test":"test"})
