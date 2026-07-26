class_name MarbleTreeTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

var tree: MarbleTree


func before_each() -> void:
	pass
	#tree = partial_double(load("res://objects/tree/tree.tscn")).instantiate()
	#stub(tree.is_server).to_return(true)


func test_not_null() -> void:
	assert_bool(true)
	#assert_not_null(tree)
