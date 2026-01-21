class_name InventoryWindow
extends MarbleWindow

@onready var window: MarbleWindow = %Window

@export var items: Inventory


func _on_client_current_character_updated(c: MarbleCharacter) -> void:
	items = c.inventory
	print(c.player_name)
	print(c.inventory.items)
