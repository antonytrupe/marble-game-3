class_name Faction
extends Node

const ATTRACT_RANGE: float = 300.0
const REPEL_RANGE: float = 150.0
const ATTRACT_STRENGTH: float = 4.0
const REPEL_STRENGTH: float = 2.0
const MOVE_SPEED: float = 1.5
const SEPARATION_DISTANCE: float = 6.0
const SEPARATION_STRENGTH: float = 6.0

# var faction: FactionStatic.Type = FactionStatic.Type.NONE

## Relation toward each faction.
## Missing entries default to neutral (0.0).
var relations: Dictionary[FactionStatic.Type, FactionRelation] = {}


func _ready() -> void:
	pass


## Returns the faction type with the highest relation value, excluding NONE.
## Returns NONE if no relations exist or all are toward NONE.
func get_main_faction() -> FactionStatic.Type:
	var best_faction: FactionStatic.Type = FactionStatic.Type.NONE
	var best_value: float = -INF
	for f: FactionStatic.Type in relations:
		if f == FactionStatic.Type.NONE:
			continue
		if relations[f].value > best_value:
			best_value = relations[f].value
			best_faction = f
	return best_faction


## Returns the relation value toward the given faction type.
## Positive = friendly, negative = hostile, 0 = neutral.
func get_relation(faction: FactionStatic.Type) -> float:
	if faction in relations:
		return relations[faction].value
	return 0.0


## Returns an overall relation score toward another character by averaging
## the difference across all faction relations both characters share.
## Positive = similar allegiances (attract), negative = opposing (repel).
func get_overall_relation(other: Faction) -> float:
	var total: float = 0.0
	var count: int = 0
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if f == FactionStatic.Type.NONE:
			continue
		var my_val: float = get_relation(f)
		var other_val: float = other.get_relation(f)
		if my_val<0 and other_val<0:
			continue
		# Dot-product style: same sign = agreement, opposite = disagreement
		var s: float = sign(my_val * other_val)
		# var sign:float = my_val * other_val
		
		total += s * (abs(my_val) + abs(other_val)) / 2
		count += 1
	if count == 0:
		return 0.0
	return total / count


## Sets the relation value toward the given faction type, clamped to [-1, 1].
func set_relation(other_faction: FactionStatic.Type, value: float) -> void:
	relations[other_faction] = FactionRelation.new(clampf(value, -1.0, 1.0))


## Initializes default relations based on the character's own faction.
## Same faction = 1.0 (fully friendly), other factions = -0.5 (moderately hostile).
## NONE faction gets all-neutral relations.
func _init_default_relations(my_faction: FactionStatic.Type) -> void:
	relations.clear()
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if my_faction == FactionStatic.Type.NONE:
			relations[f] = FactionRelation.new(0.0)
		elif f == my_faction:
			relations[f] = FactionRelation.new(1.0)
		elif f == FactionStatic.Type.NONE:
			relations[f] = FactionRelation.new(0.0)
		else:
			# relations[f] = randf_range(-1.0, 0.9)#random relation
			relations[f] = FactionRelation.new(-1.0)  #max hostile
