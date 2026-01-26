extends Node

signal persist(o: Dictionary)
signal load
signal load_finished
signal new
signal load_character(name: String, data: Dictionary)
signal load_player(name: String, data: Dictionary)
signal load_warp_monument(name: String, data: Dictionary)
signal load_tree(name: String, data: Dictionary)
signal load_apple(name: String, data: Dictionary)
var _db: SQLite


func _ready() -> void:
	load.connect(_load)
	new.connect(_new)


func _load_object(clazz_name: String, callback: Callable) -> void:
	var rs: Array = _db.select_rows(clazz_name, "", ["name", "data"])
	rs.all(callback)


func _load_warp_monuments() -> void:
	var instanced_class: WarpMonument = WarpMonument.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	var _load_warp_monument: Callable = func(r: Dictionary) -> bool:
		load_warp_monument.emit(r.name, JSON.parse_string(r.data))
		return true

	_load_object(clazz_name, _load_warp_monument)


func _load_characters() -> void:
	var instanced_class: MarbleCharacter = MarbleCharacter.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	var _load_character: Callable = func(r: Dictionary) -> bool:
		load_character.emit(r.name, JSON.parse_string(r.data))
		return true

	_load_object(clazz_name, _load_character)


func _load_players() -> void:
	var instanced_class: Player = Player.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	var _load_player: Callable = func(r: Dictionary) -> bool:
			load_player.emit(r.name, JSON.parse_string(r.data))
			return true

	_load_object(clazz_name, _load_player)


func _load_trees() -> void:
	var instanced_class: MarbleTree = MarbleTree.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	var _load_tree: Callable = func(r: Dictionary) -> bool:
			load_tree.emit(r.name, JSON.parse_string(r.data))
			return true

	_load_object(clazz_name, _load_tree)


func _load_apples() -> void:
	var instanced_class: Apple3D = Apple3D.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	var _load_apple: Callable = func(r: Dictionary) -> bool:
			load_apple.emit(r.name, JSON.parse_string(r.data))
			return true

	_load_object(clazz_name, _load_apple)

func _new() -> void:
	_db = SQLite.new()
	_db.path = "res://server.db"
	_db.open_db()

	for i: Dictionary in persist.get_connections():
		persist.disconnect(i.callable)
	persist.connect(_persist)
	_db.drop_table("Player")
	_db.drop_table("MarbleCharacter")
	_db.drop_table("MarbleTree")
	_db.drop_table("Apple3D")
	_db.drop_table("WarpMonument")
	_create_character_table()
	_create_player_table()
	_create_warp_monument_table()
	_create_tree_table()
	_create_apple_table()
	_load_players()
	_load_characters()
	_load_warp_monuments()
	_load_trees()
	_load_apples()
	load_finished.emit()

func _load() -> void:
	_db = SQLite.new()
	_db.path = "res://server.db"
	_db.open_db()

	for i: Dictionary in persist.get_connections():
		persist.disconnect(i.callable)
	persist.connect(_persist)
	_create_character_table()
	_create_player_table()
	_create_warp_monument_table()
	_create_tree_table()
	_create_apple_table()
	_load_players()
	_load_characters()
	_load_warp_monuments()
	_load_trees()
	_load_apples()
	load_finished.emit()


func _persist(o: Object) -> void:
	var clazz_name: String = o.get_script().get_global_name()
	#Debug.debug.emit("persisting %s:%s" % [clazz_name, o.name])
	_db.query_with_bindings(
		(
			"INSERT INTO %s (name, data) VALUES (?, ? ) ON CONFLICT (name) DO update set data=excluded.data"
			% [clazz_name]
		),
		[str(o.name), JSON.stringify(o.get_data())]
	)


func _create_table(clazz_name: String) -> void:
	var r: Array = _db.select_rows("sqlite_master", "type='table' and name='%s'" % [clazz_name], ["name"])
	#Debug.debug.emit(r)
	if r.size() > 0:
		return

	var table_dict: Dictionary = Dictionary()
	table_dict["name"] = {
		"data_type": "text", "not_null": true, "primary_key": true, "unique": true
	}
	table_dict["data"] = {"data_type": "text", "not_null": true}

	_db.create_table(clazz_name, table_dict)


func _create_warp_monument_table() -> void:
	var instanced_class: WarpMonument = WarpMonument.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	_create_table(clazz_name)


func _create_character_table() -> void:
	var instanced_class: MarbleCharacter = MarbleCharacter.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	_create_table(clazz_name)


func _create_player_table() -> void:
	var instanced_class: Player = Player.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	_create_table(clazz_name)


func _create_tree_table() -> void:
	var instanced_class: MarbleTree = MarbleTree.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	_create_table(clazz_name)


func _create_apple_table() -> void:
	var instanced_class: Apple3D = Apple3D.new()
	var clazz_name: String = instanced_class.get_script().get_global_name()

	_create_table(clazz_name)
