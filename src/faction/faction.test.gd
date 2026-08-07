# GdUnit generated TestSuite
class_name FactionTest
extends GdUnitTestSuite

@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')
# TestSuite generated from
const __source: String = 'res://src/faction/faction.gd'

var faction: Faction


func before_test() -> void:
	faction = auto_free(Faction.new())
	Faction.clear_cache()


func after_test() -> void:
	pass


# --- get_relation ---
func test_get_relation_returns_zero_for_missing_faction() -> void:
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(0.0)


func test_get_relation_returns_stored_value() -> void:
	faction._relations[FactionStatic.Type.BLUE] = FactionRelation.new(0.75)
	assert_float(faction.get_relation(FactionStatic.Type.BLUE)).is_equal(0.75)


func test_get_relation_returns_negative_value() -> void:
	faction._relations[FactionStatic.Type.GREEN] = FactionRelation.new(-0.5)
	assert_float(faction.get_relation(FactionStatic.Type.GREEN)).is_equal(-0.5)


# --- set_relation ---
func test_set_relation_stores_value() -> void:
	faction.set_relation(FactionStatic.Type.RED, 0.5)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(0.5)


func test_set_relation_clamps_above_one() -> void:
	faction.set_relation(FactionStatic.Type.RED, 2.0)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(1.0)


func test_set_relation_clamps_below_negative_one() -> void:
	faction.set_relation(FactionStatic.Type.RED, -5.0)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(-1.0)


func test_set_relation_allows_boundary_values() -> void:
	faction.set_relation(FactionStatic.Type.RED, 1.0)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(1.0)
	faction.set_relation(FactionStatic.Type.RED, -1.0)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_equal(-1.0)


func test_set_relation_overwrites_previous_value() -> void:
	faction.set_relation(FactionStatic.Type.BLUE, 0.3)
	faction.set_relation(FactionStatic.Type.BLUE, -0.7)
	assert_float(faction.get_relation(FactionStatic.Type.BLUE)).is_equal(-0.7)


func test_set_relation_clears_main_faction_cache()->void:
	faction.set_relation(FactionStatic.Type.BLUE, 0.3)
	faction.get_main_faction()
	faction.set_relation(FactionStatic.Type.BLUE, -0.7)
	assert_that(faction._main_faction_dirty).is_true()


# --- get_main_faction ---
func test_get_main_faction_returns_none_when_empty() -> void:
	assert_that(faction.get_main_faction()).is_equal(FactionStatic.Type.NONE)


func test_get_main_faction_returns_none_when_only_none_relation() -> void:
	faction._relations[FactionStatic.Type.NONE] = FactionRelation.new(1.0)
	assert_that(faction.get_main_faction()).is_equal(FactionStatic.Type.NONE)


func test_get_main_faction_returns_highest_relation() -> void:
	faction.set_relation(FactionStatic.Type.RED, 0.5)
	faction.set_relation(FactionStatic.Type.BLUE, 0.9)
	faction.set_relation(FactionStatic.Type.GREEN, 0.3)
	assert_that(faction.get_main_faction()).is_equal(FactionStatic.Type.BLUE)


func test_get_main_faction_ignores_none_type() -> void:
	faction._relations[FactionStatic.Type.NONE] = FactionRelation.new(10.0)
	faction.set_relation(FactionStatic.Type.RED, 0.2)
	assert_that(faction.get_main_faction()).is_equal(FactionStatic.Type.RED)


func test_get_main_faction_works_with_all_negative_relations() -> void:
	faction.set_relation(FactionStatic.Type.RED, -0.5)
	faction.set_relation(FactionStatic.Type.BLUE, -0.2)
	faction.set_relation(FactionStatic.Type.GREEN, -0.8)
	assert_that(faction.get_main_faction()).is_equal(FactionStatic.Type.BLUE)


func test_get_main_faction_uses_cache() -> void:
	# Populate cache
	faction.set_relation(FactionStatic.Type.RED, 0.5)
	faction.set_relation(FactionStatic.Type.BLUE, 0.9)
	# make sure main faction cache is empty
	assert_that(faction._main_faction_cache).is_equal(FactionStatic.Type.NONE)
	# Get main faction
	faction.get_main_faction()
	# Check that cache is populated
	assert_that(faction._main_faction_cache).is_equal(FactionStatic.Type.BLUE)

# --- _init_default_relations ---

func test_init_default_relations_none_faction_all_neutral() -> void:
	faction._init_default_relations(FactionStatic.Type.NONE)
	for f: FactionStatic.Type in FactionStatic.Type.values():
		assert_float(faction.get_relation(f)).is_equal(0.0)


func test_init_default_relations_own_faction_is_one() -> void:
	faction._init_default_relations(FactionStatic.Type.RED)
	assert_float(faction.get_relation(FactionStatic.Type.RED)).is_greater_equal(0.8)


func test_init_default_relations_none_type_is_zero() -> void:
	faction._init_default_relations(FactionStatic.Type.RED)
	assert_float(faction.get_relation(FactionStatic.Type.NONE)).is_equal(0.0)


func test_init_default_relations_other_factions_in_range() -> void:
	faction._init_default_relations(FactionStatic.Type.RED)
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if f == FactionStatic.Type.RED or f == FactionStatic.Type.NONE:
			continue
		var val: float = faction.get_relation(f)
		assert_float(val).is_less_equal(0.9)
		assert_float(val).is_greater_equal(-1.0)


func test_init_default_relations_clears_previous() -> void:
	faction.set_relation(FactionStatic.Type.PURPLE, 0.99)
	faction._init_default_relations(FactionStatic.Type.BLUE)
	# PURPLE should no longer be 0.99 — it should be in the random range
	assert_float(faction.get_relation(FactionStatic.Type.BLUE)).is_greater_equal(0.8)


# --- get_overall_relation ---

func test_invalidate_cache_is_selective() -> void:
	var f1: Faction = auto_free(Faction.new())
	var f2: Faction = auto_free(Faction.new())
	var f3: Faction = auto_free(Faction.new())
	
	# Populate cache
	f1.get_overall_relation(f2)
	f2.get_overall_relation(f3)
	
	assert_int(Faction._relation_cache.size()).is_equal(2)
	
	# Changing f1 should only invalidate f1-f2
	f1.set_relation(FactionStatic.Type.RED, 0.5)
	
	assert_int(Faction._relation_cache.size()).is_equal(1)
	assert_bool(Faction._relation_cache.has(f2._cache_key(f3))).is_true()
	assert_bool(Faction._relation_cache.has(f1._cache_key(f2))).is_false()

func test_overall_relation_identical_factions() -> void:
	#faction.clear_cache()
	assert_dict(faction._relation_cache).is_empty()
	var other: Faction = auto_free(Faction.new())
	faction.set_relation(FactionStatic.Type.RED, 1.0)
	#faction.set_relation(FactionStatic.Type.BLUE, -0.5)
	other.set_relation(FactionStatic.Type.RED, 1.0)
	#other.set_relation(FactionStatic.Type.BLUE, -0.5)
	assert_that(faction).is_equal(other)
	print(faction)
	print(other)
	assert_float(faction.get_overall_relation(other)).is_equal(1.0)


func test_overall_relation_opposite_factions_is_negative() -> void:
	var other: Faction = auto_free(Faction.new())
	# Set all factions to opposite extremes
	for f: FactionStatic.Type in FactionStatic.Type.values():
		if f == FactionStatic.Type.NONE:
			continue
		faction.set_relation(f, 1.0)
		other.set_relation(f, -1.0)
	var result: float = faction.get_overall_relation(other)
	assert_float(result).is_less(0.0)


func test_overall_relation_both_empty_returns_onezero() -> void:
	var other: Faction = auto_free(Faction.new())
	# Both have 0 for all factions, so 1 - abs(0 - 0) = 1 for each
	assert_float(faction.get_overall_relation(other)).is_equal(0.0)


func test_overall_relation_is_symmetric() -> void:
	var other: Faction = auto_free(Faction.new())
	faction.set_relation(FactionStatic.Type.RED, 0.8)
	faction.set_relation(FactionStatic.Type.BLUE, -0.3)
	other.set_relation(FactionStatic.Type.RED, -0.2)
	other.set_relation(FactionStatic.Type.GREEN, 0.6)
	var ab: float = faction.get_overall_relation(other)
	var ba: float = other.get_overall_relation(faction)
	assert_float(ab).is_equal(ba)


func test_overall_relation_excludes_none_type() -> void:
	var other: Faction = auto_free(Faction.new())
	faction._relations[FactionStatic.Type.NONE] = FactionRelation.new(1.0)
	other._relations[FactionStatic.Type.NONE] = FactionRelation.new(-1.0)
	# NONE should be skipped, so both empty non-NONE → 1.0
	assert_float(faction.get_overall_relation(other)).is_equal(0.0)


func test_overall_relation_partial_overlap() -> void:
	var other: Faction = auto_free(Faction.new())
	# Only faction has RED set, other has nothing — difference is the value
	faction.set_relation(FactionStatic.Type.RED, 0.6)
	var result: float = faction.get_overall_relation(other)
	# For RED: 1 - abs(0.6 - 0) = 0.4, for others: 1 - 0 = 1.0
	# Average of 0.4 and four 1.0s = 4.4 / 5 = 0.88
	assert_float(result).is_equal_approx(0.3, 0.01)
