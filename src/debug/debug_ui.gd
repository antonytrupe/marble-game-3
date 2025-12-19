extends Node

@onready var l= %RichTextLabel


func _ready():
	Debug.debug.connect(_debug)
	Debug.info.connect(_debug)


func _debug(_message):
	l.append_text(str(_message)+'\n')
