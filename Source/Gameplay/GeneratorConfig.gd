extends Node;

signal chunk_render_distance_changed;

var chunk_render_distance: int = 4:
	set(value):
		chunk_render_distance = value;
		emit_signal("chunk_render_distance_changed");
