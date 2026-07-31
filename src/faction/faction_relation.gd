class_name FactionRelation


const ATTRACT_RANGE: float = 300.0
const REPEL_RANGE: float = 50.0
const ATTRACT_STRENGTH: float = 24.0
const REPEL_STRENGTH: float = 12.0
const MOVE_SPEED: float = 1.5
const SEPARATION_DISTANCE: float = 4.0
const SEPARATION_STRENGTH: float = 6.0


## Degree of friendliness (+) or hostility (-) toward a faction.
## Values range from -1.0 (fully hostile) to 1.0 (fully friendly).
var value: float


func _init(initial_value: float = 0.0) -> void:
	value = clampf(initial_value, -1.0, 1.0)
