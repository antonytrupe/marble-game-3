extends Node

@onready var l= %RichTextLabel


func _ready():
	debug.debug.connect(_debug)


func _debug(_message):
	l.append_text(str(_message)+'\n')
