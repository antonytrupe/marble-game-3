class_name Action
extends RefCounted

var subject: Object
var subject_verb: Callable
var object_verb: Callable
var indirect_object_verb: Callable
var object: Object
var indirect_object: Object
var hand: MarbleCharacter.INTERACT
var repeat: bool = false
var forever: bool = false
var count: int = 1

@warning_ignore("shadowed_variable")
func _init(hand: MarbleCharacter.INTERACT,
		subject: Object, subject_verb: Callable,
		object: Object, object_verb: Callable,
		indirect_object: Object, indirect_object_verb: Callable) -> void:
	self.hand = hand
	self.subject = subject
	self.subject_verb = subject_verb
	self.object_verb = object_verb
	self.object = object
	self.indirect_object = indirect_object
	self.indirect_object_verb = indirect_object_verb


func equals(other: Action) -> bool:
	return self.hand == other.hand and \
			self.subject == other.subject and \
			self.object == other.object and \
			self.indirect_object == other.indirect_object and \
			self.subject_verb == other.subject_verb and \
			self.object_verb == other.object_verb and \
			self.indirect_object_verb == other.indirect_object_verb
# self.repeat == other.repeat and \
# self.forever == other.forever and \
# self.count == other.count and \


func do() -> bool:
	if not subject or not object:
		print()
		return false
	print("%s %s %s" % [subject.name, subject_verb.get_method(), object.name])
	var s:bool = subject_verb.call(hand, [object])
	var o:bool = object_verb.call(hand, [subject])
	var i:bool
	if indirect_object_verb:
		i = indirect_object_verb.call(hand, [])
	return s and o and i
