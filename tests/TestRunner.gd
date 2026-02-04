extends Node

const RunTests = preload("res://tests/run_tests.gd")

func _ready() -> void:
	var runner = RunTests.new()
	add_child(runner)
