class_name TerrainGeneratorManager;
extends Node;


# Terrain Export Data
@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");

@export var character_node : CharacterBody3D;


# Image Data
var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;

# Chunks Param Data
var chunk_read_size         : int = 16;
var chunk_world_dims        : Vector3 = Vector3(2.0, 1.25, 2.0);
var chunk_render_distance   : int = 3;

# Chunk Computed Data
var chunk_plane_dims : Vector2;
var chunk_state_array_dim : int;
var chunk_cache_pool  : Dictionary;
var chunk_state_array : Array[ProceduralMesh];
var chunk_new_state_array : Array[ProceduralMesh];
var chunk_world_read_origin : Vector2i;

# Last Variables
var last_player_pos : Vector2;
var last_chunk_render_center_pos : Vector2i;

# Global aux
var loading_thread : Thread;
var chunks_generated : int = 0;
var should_abort_chunk_loading : bool = false;


func _load_image_on_memory() -> void:
	image = terrain_texture.get_image().duplicate();
	image_data = image.get_data();
	image_dims = Vector2i(image.get_width(), image.get_height());


func _generate_chunk(world_plane_position : Vector2, crop_upper_left_index : Vector2i, crop_lower_right_index : Vector2i) -> ProceduralMesh:
	if should_abort_chunk_loading:
		return;
	
	var new_mesh : ProceduralMesh = ProceduralMesh.new();
	new_mesh.scale = 0.5 * chunk_world_dims;
	new_mesh.position = Vector3(world_plane_position.x, 0.0, world_plane_position.y);
	new_mesh.material_override = ShaderMaterial.new();
	new_mesh.material_override.set_shader(terrain_shader);
	
	new_mesh.image_dims = image_dims;
	new_mesh.crop_upper_left_index = crop_upper_left_index;
	new_mesh.crop_lower_right_index = crop_lower_right_index;
	new_mesh.generate_mesh(self);
	chunks_generated += 1;
	
	call_deferred("add_child", new_mesh);
	return new_mesh;


func _generate_chunks_quad(chunk_render_center_pos : Vector2i, chunk_read_center_pos : Vector2i) -> void:
	var chunk_ul_bounds : Vector2i = chunk_render_center_pos - Vector2i(chunk_state_array_dim, chunk_state_array_dim) / 2;
	var chunk_lr_bounds : Vector2i = chunk_render_center_pos + Vector2i(chunk_state_array_dim, chunk_state_array_dim) / 2;
	var chunk_render_center_world_pos : Vector2 = Vector2(chunk_render_center_pos) * chunk_plane_dims;
	var chunk_render_pos_difference : Vector2i = chunk_render_center_pos - last_chunk_render_center_pos;
	
	# Repositionate based on new origin
	var n : int = chunk_state_array_dim;
	var ul_offset_low : Vector2i = Vector2i(-n / 2, -n / 2);
	var lr_offset_lim : Vector2i = Vector2i((n + 1) / 2, (n + 1) / 2);
	var x_penetration_dir : int = signi(chunk_render_pos_difference.x) if (chunk_render_pos_difference.x != 0) else 1;
	var y_penetration_dir : int = signi(chunk_render_pos_difference.y) if (chunk_render_pos_difference.y != 0) else 1;
	var i_lower : int = ul_offset_low.y if (y_penetration_dir > 0) else (lr_offset_lim.y - 1);
	var i_upper : int = lr_offset_lim.y if (y_penetration_dir > 0) else (ul_offset_low.y - 1);
	var j_lower : int = ul_offset_low.x if (x_penetration_dir > 0) else (lr_offset_lim.x - 1);
	var j_upper : int = lr_offset_lim.x if (x_penetration_dir > 0) else (ul_offset_low.x - 1);
	var base_offset : Vector2i = Vector2i.ZERO;
	var found_base_offset : bool = false;
	for i in range(i_lower, i_upper, y_penetration_dir):
		for j in range(j_lower, j_upper, x_penetration_dir):
			var direction_vector : Vector2i = Vector2i(j, i);
			var last_chunk_render_pos : Vector2i = last_chunk_render_center_pos + direction_vector;
			
			var chunk_state_x_index : int = j - ul_offset_low.x;
			var chunk_state_y_index : int = i - ul_offset_low.y;
			var chunk_state_index   : int = chunk_state_y_index * chunk_state_array_dim + chunk_state_x_index;
			
			var is_x_bounded : bool = (last_chunk_render_pos.x >= chunk_ul_bounds.x) and (last_chunk_render_pos.x <= chunk_lr_bounds.x);
			var is_y_bounded : bool = (last_chunk_render_pos.y >= chunk_ul_bounds.y) and (last_chunk_render_pos.y <= chunk_lr_bounds.y);
			if (is_x_bounded and is_y_bounded):
				if not found_base_offset:
					base_offset = Vector2i(chunk_state_x_index, chunk_state_y_index);
					found_base_offset = true;
				if chunk_state_array[chunk_state_index] != null:
					var new_state_x_index : int = chunk_state_x_index - x_penetration_dir * base_offset.x;
					var new_state_y_index : int = chunk_state_y_index + y_penetration_dir * base_offset.y;
					var new_state_index   : int = new_state_y_index * chunk_state_array_dim + new_state_x_index;
					chunk_new_state_array[new_state_index] = chunk_state_array[chunk_state_index];
					chunk_state_array[chunk_state_index] = null;
	
	# Regenerate safe state
	for i in range(ul_offset_low.y, lr_offset_lim.y):
		for j in range(ul_offset_low.x, lr_offset_lim.x):
			var direction_vector : Vector2i = Vector2i(j, i);
			var chunk_read_pos   : Vector2i = chunk_read_center_pos + chunk_read_size * direction_vector;
			var chunk_plane_pos  : Vector2  = chunk_render_center_world_pos + chunk_plane_dims * Vector2(direction_vector);
			
			var chunk_state_x_index : int = j - ul_offset_low.x;
			var chunk_state_y_index : int = i - ul_offset_low.y;
			var chunk_state_index   : int = chunk_state_y_index * chunk_state_array_dim + chunk_state_x_index;
			
			# Move from new to current
			if chunk_state_array[chunk_state_index] != null:
				chunk_state_array[chunk_state_index].queue_free();
				chunks_generated -= 1;
			chunk_state_array[chunk_state_index] = chunk_new_state_array[chunk_state_index];
			chunk_new_state_array[chunk_state_index] = null;
			if chunk_state_array[chunk_state_index] == null:
				chunk_state_array[chunk_state_index] = _generate_chunk(chunk_plane_pos,
																	   chunk_read_pos - (chunk_read_size / 2) * Vector2i.ONE,
																	   chunk_read_pos + ((chunk_read_size + 1) / 2) * Vector2i.ONE);


func _compute_chunk_state_props() -> void:
	# Chunk State Computing
	chunk_render_distance = GeneratorConfig.chunk_render_distance;
	chunk_state_array_dim = 2 * chunk_render_distance + 1;
	chunk_state_array.resize(chunk_state_array_dim * chunk_state_array_dim);
	chunk_new_state_array.resize(chunk_state_array_dim * chunk_state_array_dim);


func _ready() -> void:
	# Connect Signal
	GeneratorConfig.chunk_render_distance_changed.connect(_on_chunk_render_distance_changed);
	
	# Init routines
	_load_image_on_memory();
	_compute_chunk_state_props();
	
	# Compute chunk read data
	chunk_plane_dims = Vector2(chunk_world_dims.x, chunk_world_dims.z);
	
	# Async loading chunks
	chunk_world_read_origin = Vector2i(6415, 6325);
	var player_pos : Vector2 = Vector2(character_node.position.x,
									   character_node.position.z);
	var render_center_pos : Vector2i = Vector2i(player_pos / chunk_plane_dims);
	last_player_pos = player_pos;
	last_chunk_render_center_pos = render_center_pos;
	
	# Strat Threads
	loading_thread = Thread.new();
	loading_thread.start(_generate_chunks_quad.bind(render_center_pos, chunk_world_read_origin));
	#_generate_chunks_quad(render_center_pos, chunk_world_read_origin);


func _exit_tree() -> void:
	should_abort_chunk_loading = true;
	loading_thread.wait_to_finish();


func _process(_delta : float) -> void:
	if not loading_thread.is_alive():
		var player_pos : Vector2 = Vector2(character_node.position.x,
										   character_node.position.z);
		var delta_pos : Vector2 = Vector2(player_pos.x - last_player_pos.x,
										  player_pos.y - last_player_pos.y);
		var render_center_pos : Vector2i = Vector2i(player_pos / chunk_plane_dims);
		if ((abs(delta_pos.x) >= chunk_plane_dims.x) or (abs(delta_pos.y) >= chunk_plane_dims.y)):
			chunk_world_read_origin += Vector2i(float(chunk_read_size) * (delta_pos / chunk_plane_dims));
			_generate_chunks_quad(render_center_pos, chunk_world_read_origin);
			last_player_pos = player_pos;
			last_chunk_render_center_pos = render_center_pos;


func _on_chunk_render_distance_changed() -> void:
	for child in get_children():
		remove_child(child);
		child.queue_free();
	chunks_generated = get_child_count();
	
	_compute_chunk_state_props();
	var player_pos : Vector2 = Vector2(character_node.position.x,
									   character_node.position.z);
	var render_center_pos : Vector2i = Vector2i(player_pos / chunk_plane_dims);
	last_player_pos = player_pos;
	last_chunk_render_center_pos = render_center_pos;
	
	loading_thread = Thread.new();
	loading_thread.start(_generate_chunks_quad.bind(render_center_pos, chunk_world_read_origin));
