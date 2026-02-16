class_name Action
extends Object

var subject: Object
var subject_verb: Callable
var object_verb: Callable
var object: Object
var hand: MarbleCharacter.INTERACT


@warning_ignore("shadowed_variable")
func _init(hand: MarbleCharacter.INTERACT, subject: Object, subject_verb: Callable, object_verb: Callable, object: Object) -> void:
	#self.name = name
	self.subject = subject
	self.object = object
	self.subject_verb = subject_verb
	self.object_verb = object_verb
	self.hand = hand

func do() -> void:
	print("%s %s %s" % [subject.name, subject_verb.get_method(), object.name])
	subject_verb.call(hand, [object])
	object_verb.call(hand, [subject])
