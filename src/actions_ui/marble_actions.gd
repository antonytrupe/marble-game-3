class_name ActionsWindow
extends Control

const ACTIONHROW_SCENE: Resource = preload("res://src/actions_ui/action_h_box.tscn")

@onready var list: VBoxContainer = %VBoxContainer
@onready var client: Client = $/root/Game/Client


func _on_row_deleted(index: int) -> void:
	client.current_character.action_remove(index)


func _on_row_moved(from: int, to: int) -> void:
	client.current_character.action_reorder(from, to)


func _on_row_repeat_toggled(index: int, toggled_on: bool) -> void:
	client.current_character.action_repeat(index, toggled_on)


func _on_forever_toggled(index: int, toggled_on: bool) -> void:
	client.current_character.action_forever(index, toggled_on)


func _on_count_value_changed(index: int, count: int) -> void:
	client.current_character.action_count_changed(index, count)


func update_actions() -> void:
	for c: Node in list.get_children():
		c.queue_free()
	for a: Action in client.current_character.actions:
		var aa: ActionHRow = ACTIONHROW_SCENE.instantiate()
		#aa.action = a
		list.add_child(aa)
		aa.repeat.button_pressed = a.repeat
		aa.forever.button_pressed = a.forever
		aa.count.value = a.count

		aa.label.text = a.subject_verb.get_method()
		aa.row_deleted.connect(_on_row_deleted)
		aa.row_moved.connect(_on_row_moved)
		aa.repeat_toggled.connect(_on_row_repeat_toggled)
		aa.forever_toggled.connect(_on_forever_toggled)
		aa.count_value_changed.connect(_on_count_value_changed)
