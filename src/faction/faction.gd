class_name Faction extends Node

## Global cache of overall-relation results between Faction pairs.
## Key: packed int64 built from both instance IDs (smaller first).
static var _relation_cache: Dictionary[int, float] = {}

## Global dependency map linking a single Faction instance ID to all its 64-bit cache keys.
## Key: single Faction instance ID. Value: Array of 64-bit combined keys.
static var _dependency_index: Dictionary[int, Array] = {}

## Cached result of get_main_faction(). Invalidated when relations change.
var _main_faction_cache: FactionStatic.Type = FactionStatic.Type.NONE
var _main_faction_dirty: bool = true

## Relation toward each faction.
## Missing entries default to neutral (0.0).
var _relations: Dictionary[FactionStatic.Type, FactionRelation] = {}:
	set(value):
		_relations = value
		_main_faction_dirty = true

func _ready() -> void:
	pass

func _init(faction: FactionStatic.Type=FactionStatic.Type.NONE, initial_value: float=0.0) -> void:
	_relations[faction] = FactionRelation.new(clampf(initial_value, -1.0, 1.0))
	_invalidate_cache()

## Returns the faction type with the highest relation value, excluding NONE.
## Returns NONE if no relations exist or all are toward NONE.
## Result is cached and invalidated when relations change.
func get_main_faction() -> FactionStatic.Type:
	if not _main_faction_dirty:
		return _main_faction_cache
	var best_faction: FactionStatic.Type = FactionStatic.Type.NONE
	var best_value: float = -INF
	for f: FactionStatic.Type in _relations:
		if f == FactionStatic.Type.NONE:
			continue
		if _relations[f].value > best_value:
			best_value = _relations[f].value
			best_faction = f
	_main_faction_cache = best_faction
	_main_faction_dirty = false
	return best_faction

## Returns the relation value toward the given faction type.
## Positive = friendly, negative = hostile, 0 = neutral.
func get_relation(faction: FactionStatic.Type) -> float:
	if faction in _relations:
		return _relations[faction].value
	return 0.0

## Returns an overall relation score toward another character by averaging
## the difference across all faction relations both characters share.
## Positive = similar allegiances (attract), negative = opposing (repel).
## Results are cached globally; call invalidate_cache() if relations change.
func get_overall_relation(other: Faction) -> float:
	var start_time = Time.get_ticks_usec()
	var key: int = _cache_key(other)
	if key in _relation_cache:
		return _relation_cache[key]
	#print('miss')
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

	var result: float = 0.0 if count == 0 else total / count

	# Save to cache
	_relation_cache[key] = result

	# Register dependencies for selective updates later
	_register_dependency(get_instance_id(), key)
	_register_dependency(other.get_instance_id(), key)
	#print("get_overall_relation: ", Time.get_ticks_usec() - start_time, " us")
	return result

## Sets the relation value toward the given faction type, clamped to [-1, 1].
func set_relation(other_faction: FactionStatic.Type, value: float) -> void:
	_relations[other_faction] = FactionRelation.new(clampf(value, -1.0, 1.0))
	_invalidate_cache()

## Initializes default relations based on the character's own faction.
## Same faction = 1.0 (fully friendly), other factions = -0.5 (moderately hostile).
## NONE faction gets all-neutral relations.
func _init_default_relations(my_faction: FactionStatic.Type) -> void:
	_relations.clear()
	_invalidate_cache()
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if my_faction == FactionStatic.Type.NONE:
			_relations[f] = FactionRelation.new(0.0)
		elif f == my_faction:
			_relations[f] = FactionRelation.new(randf_range(0.8, 1.0))
		elif f == FactionStatic.Type.NONE:
			_relations[f] = FactionRelation.new(0.0)
		else:
			_relations[f] = FactionRelation.new(randf_range(-1.0, 0.8))

## Builds a symmetric cache key from two Faction instances using 64-bit bit-shifting.
## Lower 32 bits store the smaller ID, upper 32 bits store the larger ID.
func _cache_key(other: Faction) -> int:
	var a: int = get_instance_id()
	var b: int = other.get_instance_id()
	if a > b:
		var tmp: int = a
		a = b
		b = tmp
	return (a << 32) | (b & 0xFFFFFFFF)

## Links an individual instance ID to a global cache key entry.
func _register_dependency(instance_id: int, combined_key: int) -> void:
	if not _dependency_index.has(instance_id):
		_dependency_index[instance_id] = [] as Array[int]

	if not _dependency_index[instance_id].has(combined_key):
		_dependency_index[instance_id].append(combined_key)

## Removes only the cached relation entries that involve this specific Faction instance.
func _invalidate_cache() -> void:
	_main_faction_dirty = true
	var my_id: int = get_instance_id()

	if not _dependency_index.has(my_id):
		return # No entries cached for this faction yet

	# Duplicate array to safely mutate references while looping
	var affected_keys: Array = _dependency_index[my_id].duplicate()

	for combined_key in affected_keys:
		# Wipe out the paired evaluation score
		_relation_cache.erase(combined_key)

		# Break down the key to locate and clean the sibling faction's index array
		var a: int = combined_key >> 32
		var b: int = combined_key & 0xFFFFFFFF
		var sibling_id: int = b if a == my_id else a

		if _dependency_index.has(sibling_id):
			_dependency_index[sibling_id].erase(combined_key)
			if _dependency_index[sibling_id].is_empty():
				_dependency_index.erase(sibling_id)

	# Erase this instance's complete dependency index row
	_dependency_index.erase(my_id)


## Clears the entire relation cache. Call when bulk changes occur.
static func clear_cache() -> void:
	_relation_cache.clear()
	_dependency_index.clear()
