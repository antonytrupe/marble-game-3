class_name FactionRelation

## Degree of friendliness (+) or hostility (-) toward a faction.
## Values range from -1.0 (fully hostile) to 1.0 (fully friendly).
var value: float


func _init(initial_value: float = 0.0) -> void:
	value = clampf(initial_value, -1.0, 1.0)
