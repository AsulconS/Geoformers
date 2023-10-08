extends Node

signal chunk_size_changed

var chunk_size: int = 4:
	set(value):
		chunk_size = value
		emit_signal("chunk_size_changed")
