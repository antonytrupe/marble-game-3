class_name Action
extends Object

@export var do: Callable
@export var name: String


@warning_ignore("shadowed_variable")
func _init(name: String, do: Callable) -> void:
	self.name = name
	self.do = do
