class_name TerrainGeneratorManager;
extends Node;


# Terrain Export Data
@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");


# Image Data
var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;

# Chunks Param Data
var chunk_read_size          : int = 16;
var chunk_world_dims         : Vector3 = Vector3(2.0, 1.25, 2.0);
var chunk_read_origin        : Vector2i = Vector2i(6415, 6325);
var chunk_rendering_distance : int = 3;
# Chunk Computed Data
var chunk_plane_dims : Vector2;
var chunk_read_dims  : Vector2i;
var chunk_read_half_ndims : Vector2i;
var chunk_read_half_pdims : Vector2i;
var chunk_cache_pool  : Dictionary;
var chunk_state_array : PackedByteArray;
var chunk_cached_dims : Vector2i;
var chunk_matrix_side_size : int;

var chunk_render_origin : Vector2;
var last_chunk_render_origin : Vector2;

# Global aux
var loading_thread : Thread;
var chunks_generated : int = 0;
var should_abort_chunk_loading : bool = false;


func load_image_on_memory():
	image = terrain_texture.get_image().duplicate();
	image_data = image.get_data();
	image_dims = Vector2i(image.get_width(), image.get_height());


func generate_chunk(world_plane_position : Vector2, crop_upper_left_index : Vector2i, crop_lower_right_index : Vector2i):
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


func generate_m_x_n_chunks(m : int, n : int):
	var ul_offset_low : Vector2i = Vector2i(-m / 2, -n / 2);
	var lr_offset_lim : Vector2i = Vector2i((m + 1) / 2, (n + 1) / 2);
	for i in range(ul_offset_low.y, lr_offset_lim.y):
		for j in range(ul_offset_low.x, lr_offset_lim.x, 8):
			if should_abort_chunk_loading:
				return;
			
			var last_chunk_ul_bounds : Vector2 = last_chunk_render_origin - 0.5 * chunk_plane_dims;
			var last_chunk_lr_bounds : Vector2 = last_chunk_render_origin + 0.5 * chunk_plane_dims;
			
			var cached_chunk_state_index : int = (i - ul_offset_low.y) * chunk_cached_dims.x + (j - ul_offset_low.x) / 8;
			var cached_chunk_state : int = chunk_state_array[cached_chunk_state_index];
			for k in range(8):
				if (j + k) >= lr_offset_lim.x:
					break;
				if not (cached_chunk_state & (0x1 << k)):
					var direction_vector : Vector2i = Vector2i(j + k, i);
					var chunk_read_pos   : Vector2i = chunk_read_origin + chunk_read_dims * direction_vector;
					var chunk_plane_pos  : Vector2  = chunk_render_origin + chunk_plane_dims * Vector2(direction_vector);
					generate_chunk(chunk_plane_pos,
								   chunk_read_pos - chunk_read_half_ndims,
								   chunk_read_pos + chunk_read_half_pdims);
					chunk_state_array[cached_chunk_state_index] |= (0x1 << k);


func _ready():
	# Load image on ready
	load_image_on_memory();
	
	# Chunk State Computing
	chunk_matrix_side_size = 2 * chunk_rendering_distance + 1;
	chunk_cached_dims = Vector2i((chunk_matrix_side_size + 7) / 8, chunk_matrix_side_size);
	chunk_state_array.resize(chunk_cached_dims.x * chunk_cached_dims.y);
	
	# Compute chunk runtime data
	chunk_read_dims = Vector2(chunk_read_size, chunk_read_size);
	chunk_plane_dims = Vector2(chunk_world_dims.x, chunk_world_dims.z);
	chunk_read_half_ndims = chunk_read_dims / 2;
	chunk_read_half_pdims = (chunk_read_dims + Vector2i.ONE) / 2;
	
	# Async loading chunks
	loading_thread = Thread.new();
	loading_thread.start(generate_m_x_n_chunks.bind(chunk_matrix_side_size,
													chunk_matrix_side_size));


func _exit_tree():
	should_abort_chunk_loading = true;
	loading_thread.wait_to_finish();


func _process(_delta : float):
	if not loading_thread.is_alive():
		generate_m_x_n_chunks(chunk_matrix_side_size, chunk_matrix_side_size);
