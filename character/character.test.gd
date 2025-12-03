# GdUnit generated TestSuite
class_name MarbleCharacterTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://character/character.gd'


var instance:MarbleCharacter
var other:MarbleCharacter

func before_test() -> void:
	instance=MarbleCharacter.new()
	other=MarbleCharacter.new()


func after_test() -> void:
	instance.queue_free()
	other.queue_free()
