class_name DualKeyCache

# Primary cache: Uses combined 64-bit int keys
var _cache: Dictionary[int, Variant] = {}

# Dependency index: Links a single 32-bit int piece to an array of combined 64-bit int keys
var _dependency_index: Dictionary[int, Array] = {}

## Combines two 32-bit integers into a single unique 64-bit integer key
func get_combined_key(piece_1: int, piece_2: int) -> int:
	# Shift piece_1 into the upper 32 bits, and OR it with piece_2 in the lower 32 bits
	return (piece_1 << 32) | (piece_2 & 0xFFFFFFFF)

## Adds or updates an item in the cache using two integer pieces
func insert(piece_1: int, piece_2: int, value: Variant) -> void:
	var combined_key: int = get_combined_key(piece_1, piece_2)

	# Save the actual data
	_cache[combined_key] = value

	# Link individual pieces to this combined key for later lookups
	_register_dependency(piece_1, combined_key)
	_register_dependency(piece_2, combined_key)

## Updates or clears entries when a single piece changes, without knowing the paired piece
func invalidate_or_update_by_single_piece(changed_piece: int, new_value: Variant = null) -> void:
	if not _dependency_index.has(changed_piece):
		return # Nothing cached uses this piece

	# Duplicate the array to avoid modification errors while looping
	var affected_keys: Array = _dependency_index[changed_piece].duplicate()

	for combined_key in affected_keys:
		if new_value == null:
			# Option A: Wipe out the stale data
			_cache.erase(combined_key)

			# Clean up the reverse dependency for the OTHER piece bound to this key
			_unregister_sibling_dependency(changed_piece, combined_key)
		else:
			# Option B: Update the data directly
			_cache[combined_key] = new_value

	# If we deleted the data entirely, remove this piece from the index
	if new_value == null:
		_dependency_index.erase(changed_piece)

# Helper to build the dependency index
func _register_dependency(piece: int, combined_key: int) -> void:
	if not _dependency_index.has(piece):
		_dependency_index[piece] = [] as Array[int]

	if not _dependency_index[piece].has(combined_key):
		_dependency_index[piece].append(combined_key)

# Helper to remove the combined key tracking from the sibling piece when data is erased
func _unregister_sibling_dependency(current_piece: int, combined_key: int) -> void:
	# Extract the two original IDs from the 64-bit key
	var p1: int = combined_key >> 32
	var p2: int = combined_key & 0xFFFFFFFF

	# Identify which ID belongs to the sibling piece
	var sibling_piece: int = p2 if p1 == current_piece else p1

	if _dependency_index.has(sibling_piece):
		_dependency_index[sibling_piece].erase(combined_key)
		if _dependency_index[sibling_piece].is_empty():
			_dependency_index.erase(sibling_piece)
