#class_name MarbleCharacterTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

var tree: MarbleTree


func before_each():
	pass
	#tree = partial_double(load("res://objects/tree/tree.tscn")).instantiate()
	#stub(tree.is_server).to_return(true)


func test_not_null():
	pass
	#assert_not_null(tree)
