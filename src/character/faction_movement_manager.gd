class_name FactionMovementManager
extends Node

## One cell spans the maximum attraction range. A character can therefore only
## affect its own cell or one of the eight adjacent cells.
const CELL_SIZE: float = FactionRelation.ATTRACT_RANGE
## Steering is intentionally sampled below the physics rate. In a dense faction
## every character is in range of every other character, so exact pair work is
## still quadratic; cached forces are applied smoothly on intervening frames.
const STEERING_INTERVAL: float = 0.1
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
]

@onready var world: World = get_parent()
var _steering_time: float = STEERING_INTERVAL
var _forces: Dictionary = {}


func _ready() -> void:
	process_physics_priority = -100


func _physics_process(delta: float) -> void:
	_steering_time += delta
	if _steering_time >= STEERING_INTERVAL:
		_rebuild_forces()
		_steering_time = 0.0

	for character: MarbleCharacter in _forces:
		FactionMovement.apply_force(character, _forces[character], delta)


func _rebuild_forces() -> void:
	var cells: Dictionary = {}
	_forces.clear()

	for node: Node in world.characters.get_children():
		if not node is MarbleCharacter:
			continue
		var character: MarbleCharacter = node
		if not FactionMovement.can_influence(character):
			continue

		var cell: Vector2i = _cell_for(character.global_position)
		if not cells.has(cell):
			cells[cell] = [] as Array[MarbleCharacter]
		cells[cell].append(character)
		if FactionMovement.can_move(character):
			_forces[character] = Vector3.ZERO

	for cell: Vector2i in cells:
		var occupants: Array[MarbleCharacter] = cells[cell]
		for index: int in range(occupants.size()):
			for other_index: int in range(index + 1, occupants.size()):
				_accumulate_pair(occupants[index], occupants[other_index])

		for offset: Vector2i in NEIGHBOR_OFFSETS:
			var neighbor: Vector2i = cell + offset
			if not cells.has(neighbor):
				continue
			for first: MarbleCharacter in occupants:
				for second: MarbleCharacter in cells[neighbor]:
					_accumulate_pair(first, second)


func _cell_for(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.z / CELL_SIZE))


func _accumulate_pair(first: MarbleCharacter, second: MarbleCharacter) -> void:
	var force: Vector3 = FactionMovement.calculate_pair_force(first, second)
	if force == Vector3.ZERO:
		return
	if _forces.has(first):
		_forces[first] += force
	if _forces.has(second):
		_forces[second] -= force
