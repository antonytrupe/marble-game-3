extends Node

signal persist(o_name,o)
signal start(o)
signal load_character(name,data)
signal load_player(name,data)


const CHARACTER_SCENE = preload("res://character/character.tscn")
const PLAYER_SCENE = preload("res://player/player.gd")


var _db:SQLite


func _ready():
	start.connect(_start)


func _load_characters():
	var instancedClass = MarbleCharacter.new()
	var className = instancedClass.get_script().get_global_name()
	var rs=_db.select_rows(className, "",['name','data'])

	var _load_character=func(r):
		Debug.debug.emit('persistance._load_character '+str(r.name))
		load_character.emit(r.name,JSON.parse_string(r.data))
		return true

	rs.all(_load_character)


func _load_players():
	var instancedClass = Player.new()
	var className = instancedClass.get_script().get_global_name()
	var rs=_db.select_rows(className, "",['name','data'])

	rs.all(func(r):
		Debug.debug.emit('_load_player '+str(r.name))
		load_player.emit(r.name,JSON.parse_string(r.data))
		return true
	)

func _start():
	_db=SQLite.new()
	_db.path="res://server.db"
	_db.open_db()

	persist.connect(_persist)
	_create_character_table()
	_create_player_table()
	_load_players()
	_load_characters()


func _persist(className,o:Object):
	Debug.debug.emit('persisting '+o.name)
	#Debug.debug.emit('persisting '+o.get_script().get_global_name())
	#var className:String=o.get_script().get_global_name()
	_db.query_with_bindings("INSERT INTO %s (name, data) VALUES (?, ? ) ON CONFLICT (name) DO update set data=excluded.data" % [className],
	[str(o.name),JSON.stringify(o.get_data())])


func _create_character_table():
	var instancedClass = MarbleCharacter.new()
	var className = instancedClass.get_script().get_global_name()

	var r=_db.select_rows("sqlite_master", "type='table' and name='%s'"%[className],['name'])
	Debug.debug.emit(r)
	if r.size()>0:
		return

	var table_dict : Dictionary = Dictionary()
	table_dict["name"] = {"data_type":"text", "not_null": true, "primary_key":true, "unique":true}
	table_dict["data"] = {"data_type":"text", "not_null": true}

	_db.create_table(className, table_dict)

func _create_player_table():
	var instancedClass = Player.new()
	var className = instancedClass.get_script().get_global_name()

	var r=_db.select_rows("sqlite_master", "type='table' and name='%s'"%[className],['name'])
	if r.size()>0:
		return

	var table_dict : Dictionary = Dictionary()
	table_dict["name"] = {"data_type":"text", "not_null": true, "primary_key":true, "unique":true}
	table_dict["data"] = {"data_type":"text", "not_null": true}

	_db.create_table(className, table_dict)
