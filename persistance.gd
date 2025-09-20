extends Node

var db:SQLite

func _ready():
	db=SQLite.new()
	db.path="res://server.db"
	db.open_db()
