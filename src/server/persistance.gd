extends Node

signal persist(o: Object)
signal load
signal load_finished
signal new
signal load_character(name: String, data: Dictionary)
signal load_player(name: String, data: Dictionary)
signal load_warp_monument(name: String, data: Dictionary)
signal load_tree(name: String, data: Dictionary)
signal load_apple(name: String, data: Dictionary)
signal load_monster(name: String, data: Dictionary)
var _db: SQLite


func _ready() -> void:
	load.connect(_load)
	new.connect(_new)


func _get_entity_config() -> Array[Dictionary]:
	return [
		{ "script": Player, "signal": load_player },
		{ "script": MarbleCharacter, "signal": load_character },
		{ "script": WarpMonument, "signal": load_warp_monument },
		{ "script": MarbleTree, "signal": load_tree },
		{ "script": Apple3D, "signal": load_apple },
		{ "script": Monster, "signal": load_monster },
	]


func _load_object(clazz_name: String, callback: Callable) -> void:
	var rs: Array = _db.select_rows(clazz_name, "", ["name", "data"])
	rs.all(callback)


func _load_all_entities() -> void:
	for config: Dictionary in _get_entity_config():
		var script: Script = config.script
		var clazz_name: String = script.get_global_name()
		var load_signal: Signal = config.signal

		var callback: Callable = func(r: Dictionary) -> bool:
			load_signal.emit(r.name, JSON.parse_string(r.data))
			return true

		_load_object(clazz_name, callback)


func _init_db() -> void:
	_db = SQLite.new()
	_db.path = "res://server.db"
	_db.open_db()

	if not persist.is_connected(_persist):
		persist.connect(_persist)


func _new() -> void:
	_init_db()
	_setup_tables(true)
	_load_all_entities()
	load_finished.emit()

func _load() -> void:
	_init_db()
	_setup_tables(false)
	_load_all_entities()
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


func _setup_tables(drop_existing: bool) -> void:
	for config: Dictionary in _get_entity_config():
		var script: Script = config.script
		var clazz_name: String = script.get_global_name()

		if drop_existing:
			_db.drop_table(clazz_name)

		_create_table(clazz_name)
