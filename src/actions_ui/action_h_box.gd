class_name ActionHRow
extends Container

signal row_deleted(index: int)
signal row_moved(from: int, to: int)
signal repeat_toggled(index: int, toggled_on: bool)
signal forever_toggled(index: int, toggled_on: bool)
signal count_value_changed(index: int, count: int)

#var action: Action

# Reference to a small ColorRect child used as a line (e.g., 2px height)
@onready var drop_indicator: ColorRect = %DropIndicator
@onready var label: Label = %Label
@onready var count: SpinBox = %Count
@onready var forever: Button = %Forever
@onready var repeat: Button = %Repeat


func _ready() -> void:
	drop_indicator.visible = false
	# Ensure the container is set to "Pass" or "Stop" to receive mouse events
	mouse_filter = Control.MOUSE_FILTER_PASS


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop: bool = data is Control and data.get_parent() == get_parent()

	if can_drop:
		# Show the indicator line when hovering with a valid drag
		drop_indicator.visible = true
	return can_drop


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	#print("from %s to %s" % [data.get_index(),get_index()])
	row_moved.emit(data.get_index(), get_index())

	drop_indicator.visible = false
	get_parent().move_child(data, get_index())
	data.visible = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_END:
			drop_indicator.visible = false

		NOTIFICATION_MOUSE_EXIT:
			drop_indicator.visible = false


func _on_cancel_pressed() -> void:
	row_deleted.emit(get_index())
	queue_free()


func _on_repeat_toggled(toggled_on: bool) -> void:
	count.visible = toggled_on
	forever.visible = toggled_on
	repeat_toggled.emit(get_index(), toggled_on)


func _on_forever_toggled(toggled_on: bool) -> void:
	count.visible = ! toggled_on
	forever_toggled.emit(get_index(), toggled_on)


func _on_count_value_changed(value: float) -> void:
	count_value_changed.emit(get_index(), value)
