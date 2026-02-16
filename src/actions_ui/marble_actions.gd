class_name ActionsWindow
extends Control

@onready var list: VBoxContainer = %VBoxContainer

func _ready() -> void:
	pass
	#ActionHRow.row_deleted.connect(_on_row_deleted)

func _on_row_deleted() -> void:
	pass
