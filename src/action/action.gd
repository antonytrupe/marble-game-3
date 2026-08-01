class_name Action
extends Object

var subject: Object
var subject_verb: Callable
var object_verb: Callable
var object: Object
var hand: MarbleCharacter.INTERACT
var repeat: bool = false
var forever: bool = false
var count: int = 1

@warning_ignore("shadowed_variable")
func _init(hand: MarbleCharacter.INTERACT, subject: Object, subject_verb: Callable, object_verb: Callable,
		object: Object) -> void:
	#self.name = name
	self.subject = subject
	self.object = object
	self.subject_verb = subject_verb
	self.object_verb = object_verb
	self.hand = hand


func equals(other: Action) -> bool:
	return self.object == other.object and \
			self.object_verb == other.object_verb and \
			self.subject == other.subject and \
			self.subject_verb == other.subject_verb


func do() -> bool:
	if not subject or not object:
		print()
		return false
	print("%s %s %s" % [subject.name, subject_verb.get_method(), object.name])
	var s = subject_verb.call(hand, [object])
	var o = object_verb.call(hand, [subject])
	return s and o
