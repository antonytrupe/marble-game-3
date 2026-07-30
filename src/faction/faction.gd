class_name Faction
extends RefCounted

enum Type {
	NONE,
	RED,
	BLUE,
	GREEN,
	YELLOW,
	PURPLE,
}

const NAMES: Dictionary[Type, String] = {
	Type.NONE: "Unaligned",
	Type.RED: "Crimson Covenant",
	Type.BLUE: "Azure Alliance",
	Type.GREEN: "Emerald Dominion",
	Type.YELLOW: "Golden Order",
	Type.PURPLE: "Purple Pact",
}

const COLORS: Dictionary[Type, Color] = {
	Type.NONE: Color(0.7, 0.7, 0.7, 1),
	Type.RED: Color(0.8, 0.1, 0.1, 1),
	Type.BLUE: Color(0.1, 0.2, 0.8, 1),
	Type.GREEN: Color(0.1, 0.6, 0.15, 1),
	Type.YELLOW: Color(0.9, 0.8, 0.1, 1),
	Type.PURPLE: Color(0.5, 0.1, 0.7, 1),
}


static func get_faction_name(faction: Type) -> String:
	return NAMES.get(faction, "Unaligned")


static func get_faction_color(faction: Type) -> Color:
	return COLORS.get(faction, COLORS[Type.NONE])


static func from_color(color: Color) -> Type:
	var best_faction: Type = Type.NONE
	var best_distance: float = INF
	for faction: Type in COLORS:
		if faction == Type.NONE:
			continue
		var dist: float = _color_distance(color, COLORS[faction])
		if dist < best_distance:
			best_distance = dist
			best_faction = faction
	return best_faction


static func _color_distance(a: Color, b: Color) -> float:
	var dr: float = a.r - b.r
	var dg: float = a.g - b.g
	var db: float = a.b - b.b
	return dr * dr + dg * dg + db * db
