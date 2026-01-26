extends Node

@onready var l: RichTextLabel = %DebugRichText


func _ready()->void:
	Debug.debug.connect(_debug)
	Debug.info.connect(_debug)


func _debug(_message:Array)->void:
	l.append_text(str(_message) + '\n')
