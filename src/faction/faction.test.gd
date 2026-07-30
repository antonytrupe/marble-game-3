# GdUnit generated TestSuite
class_name FactionTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://src/faction/faction.gd'


func test_get_faction_name_returns_correct_names() -> void:
	assert_str(Faction.get_faction_name(Faction.Type.NONE)).is_equal("Unaligned")
	assert_str(Faction.get_faction_name(Faction.Type.RED)).is_equal("Crimson Order")
	assert_str(Faction.get_faction_name(Faction.Type.BLUE)).is_equal("Azure Covenant")
	assert_str(Faction.get_faction_name(Faction.Type.GREEN)).is_equal("Emerald Pact")
	assert_str(Faction.get_faction_name(Faction.Type.YELLOW)).is_equal("Golden Alliance")
	assert_str(Faction.get_faction_name(Faction.Type.PURPLE)).is_equal("Violet Dominion")


func test_get_faction_color_returns_correct_colors() -> void:
	assert_that(Faction.get_faction_color(Faction.Type.RED)).is_equal(Color(0.8, 0.1, 0.1, 1))
	assert_that(Faction.get_faction_color(Faction.Type.BLUE)).is_equal(Color(0.1, 0.2, 0.8, 1))


func test_from_color_matches_red() -> void:
	assert_that(Faction.from_color(Color(0.9, 0.0, 0.0, 1))).is_equal(Faction.Type.RED)


func test_from_color_matches_blue() -> void:
	assert_that(Faction.from_color(Color(0.0, 0.1, 0.9, 1))).is_equal(Faction.Type.BLUE)


func test_from_color_matches_green() -> void:
	assert_that(Faction.from_color(Color(0.0, 0.7, 0.1, 1))).is_equal(Faction.Type.GREEN)


func test_from_color_matches_yellow() -> void:
	assert_that(Faction.from_color(Color(1.0, 0.9, 0.0, 1))).is_equal(Faction.Type.YELLOW)


func test_from_color_matches_purple() -> void:
	assert_that(Faction.from_color(Color(0.6, 0.0, 0.8, 1))).is_equal(Faction.Type.PURPLE)


func test_from_color_closest_match() -> void:
	# A pinkish-red should still match RED
	assert_that(Faction.from_color(Color(0.7, 0.2, 0.2, 1))).is_equal(Faction.Type.RED)
