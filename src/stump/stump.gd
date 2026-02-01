class_name Stump
extends Node3D

static var scene: Resource = preload("res://src/stump/stump.tscn")
@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8

@onready var age: MarbleAge = %MarbleAge
