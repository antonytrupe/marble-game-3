class_name InventoryWindow
extends MarbleWindow

@export var items: Inventory

@onready var window: MarbleWindow = %Window

func _on_client_current_character_updated(c: MarbleCharacter) -> void:
	#items = c.inventory
	print(c.player_name)
	#print(c.inventory.items)
	#for item in items.items.values():
		#add_item(item)


func _on_area_2d_body_exited(body: Node2D) -> void:
	print('dropping')
	#TODO drop the item on the group
	#TODO remove the 2d object from the tree
	if body is Apple2D:
		body.gravity_scale = 1
		body.freeze = false
		body.is_dropping = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Apple2D:
		body.gravity_scale = 0
		body.is_dropping = false
