#class_name Persistance
extends Node

signal persist(o: Object)
signal delete(o: Object)
signal load_game
signal load_finished
signal new_game
signal load_object(name: String, data: Dictionary)

var tables: Array[String] = []
var _db: SQLite


func _ready() -> void:
	load_game.connect(_load_game)
	new_game.connect(_new_game)
	delete.connect(_delete)


func _delete(o: Object) -> void:
	var table_name: String = o.get_script().get_global_name()
	_db.delete_rows(table_name, "name = '%s'"%o.name)


func _load_objects(clazz_name: String) -> void:
	var rs: Array = _db.select_rows(clazz_name, "", ["name", "data"])
	var callback: Callable = func(r: Dictionary) -> bool:
		load_object.emit(r.name, JSON.parse_string(r.data))
		return true
	rs.all(callback)


func _load_all_entities() -> void:
	for table: String in tables:
		_load_objects(table)


func _get_tables() -> void:
	_db.query("SELECT name FROM sqlite_schema WHERE type='table' ORDER BY name;")
	var rs: Array[Dictionary] = _db.query_result
	var a: Array = rs.map(func(row: Dictionary) -> String: return row.name as String) as Array[String]
	tables.assign(a)
	print(tables)


func _init_db() -> void:
	_db = SQLite.new()
	_db.path = "user://server.db"
	_db.open_db()

	_get_tables()

	if not persist.is_connected(_persist):
		persist.connect(_persist)


func _new_game() -> void:
	_init_db()
	_drop_tables()
	_load_all_entities()
	load_finished.emit()

func _load_game() -> void:
	_init_db()
	#_setup_tables(false)
	_load_all_entities()
	load_finished.emit()


func _persist(o: Object) -> void:
	var clazz_name: String = o.get_script().get_global_name()
	if not tables.has(clazz_name):
		_create_table(clazz_name)
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
	tables.append(clazz_name)
	_db.create_table(clazz_name, table_dict)


func _drop_tables() -> void:
	for table: String in tables:
		#var script: Script = config.script
		#var clazz_name: String = script.get_global_name()
		_db.drop_table(table)
	tables = []
