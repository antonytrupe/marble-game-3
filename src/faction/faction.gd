class_name Faction
extends Node

## Global cache of overall-relation results between Faction pairs.
## Key: packed int64 built from both instance IDs (smaller first).
## Cleared automatically when any faction's relations change.
var _relation_cache: Dictionary = {}

## Cached result of get_main_faction(). Invalidated when relations change.
var _main_faction_cache: FactionStatic.Type = FactionStatic.Type.NONE
var _main_faction_dirty: bool = true

## Relation toward each faction.
## Missing entries default to neutral (0.0).
var relations: Dictionary[FactionStatic.Type, FactionRelation] = {}:
	set(value):
		relations = value
		_main_faction_dirty = true


func _ready() -> void:
	pass


func _init(faction: FactionStatic.Type=FactionStatic.Type.NONE, initial_value: float=0.0) -> void:
	relations[faction] = FactionRelation.new(clampf(initial_value, -1.0, 1.0))
	invalidate_cache()


## Returns the faction type with the highest relation value, excluding NONE.
## Returns NONE if no relations exist or all are toward NONE.
## Result is cached and invalidated when relations change.
func get_main_faction() -> FactionStatic.Type:
	if not _main_faction_dirty:
		return _main_faction_cache
	var best_faction: FactionStatic.Type = FactionStatic.Type.NONE
	var best_value: float = -INF
	for f: FactionStatic.Type in relations:
		if f == FactionStatic.Type.NONE:
			continue
		if relations[f].value > best_value:
			best_value = relations[f].value
			best_faction = f
	_main_faction_cache = best_faction
	_main_faction_dirty = false
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
## Results are cached globally; call invalidate_cache() if relations change.
func get_overall_relation(other: Faction) -> float:
	var key: int = _cache_key(other)
	if key in _relation_cache:
		return _relation_cache[key]
	var total: float = 0.0
	var count: int = 0
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if f == FactionStatic.Type.NONE:
			continue
		var my_val: float = get_relation(f)
		var other_val: float = other.get_relation(f)
		if my_val <= 0.0 and other_val <= 0.0:
			continue
		# Dot-product style: same sign = agreement, opposite = disagreement
		var product: float = my_val * other_val
		var s: float = sign(product) if product != 0 else sign(my_val + other_val)

		total += s * (abs(my_val) + abs(other_val)) / 2
		count += 1
	var result: float
	if count == 0:
		result = 0.0
	else:
		result = total / count
	_relation_cache[key] = result
	return result


## Sets the relation value toward the given faction type, clamped to [-1, 1].
func set_relation(other_faction: FactionStatic.Type, value: float) -> void:
	relations[other_faction] = FactionRelation.new(clampf(value, -1.0, 1.0))
	invalidate_cache()


## Initializes default relations based on the character's own faction.
## Same faction = 1.0 (fully friendly), other factions = -0.5 (moderately hostile).
## NONE faction gets all-neutral relations.
func _init_default_relations(my_faction: FactionStatic.Type) -> void:
	relations.clear()
	invalidate_cache()
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if my_faction == FactionStatic.Type.NONE:
			relations[f] = FactionRelation.new(0.0)
		elif f == my_faction:
			relations[f] = FactionRelation.new(randf_range(0.8, 1.0))
		elif f == FactionStatic.Type.NONE:
			relations[f] = FactionRelation.new(0.0)
		else:
			relations[f] = FactionRelation.new(randf_range(-1.0, 0.8))  #random relation
#relations[f] = FactionRelation.new(-1.0)  #max hostile


## Builds a symmetric cache key from two Faction instances.
func _cache_key(other: Faction) -> int:
	var a: int = get_instance_id()
	var b: int = other.get_instance_id()
	if a > b:
		var tmp: int = a
		a = b
		b = tmp
	return a * 2147483647 + b


## Removes all cached relation entries that involve this Faction instance.
func invalidate_cache() -> void:
	_relation_cache.clear()
	_main_faction_dirty = true


## Clears the entire relation cache. Call when bulk changes occur.
func clear_cache() -> void:
	_relation_cache.clear()
