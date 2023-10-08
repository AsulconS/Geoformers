class_name TerrainGeneratorManager;
extends Node;


# Terrain Export Data
@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");


# Image Data
var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;

# Chunks Data
var chunk_read_size   : int = 16;
var chunk_world_dims  : Vector3 = Vector3(3.0, 1.25, 2.0);
var chunk_read_origin : Vector2i = Vector2i(6415, 6325);
var chunk_plane_origin : Vector2 = Vector2.ZERO;

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
	var chunk_plane_dims : Vector2 = Vector2(chunk_world_dims.x, chunk_world_dims.z);
	var chunk_read_dims : Vector2i = Vector2i(chunk_read_size, chunk_read_size);
	var chunk_read_half_ndims : Vector2i = chunk_read_dims / 2;
	var chunk_read_half_pdims : Vector2i = (chunk_read_dims + Vector2i.ONE) / 2;
	
	var ul_offset_low : Vector2i = Vector2i(-m / 2, -n / 2);
	var lr_offset_lim : Vector2i = Vector2i((m + 1) / 2, (n + 1) / 2);
	for i in range(ul_offset_low.y, lr_offset_lim.y):
		for j in range(ul_offset_low.x, lr_offset_lim.x):
			var direction_vector : Vector2i = Vector2i(j, i);
			var chunk_read_pos   : Vector2i = chunk_read_origin + chunk_read_dims * direction_vector;
			var chunk_plane_pos  : Vector2  = chunk_plane_origin + chunk_plane_dims * Vector2(direction_vector);
			generate_chunk(chunk_plane_pos,
						   chunk_read_pos - chunk_read_half_ndims,
						   chunk_read_pos + chunk_read_half_pdims);


func _ready():
	GeneratorConfig.chunk_size_changed.connect(_on_chunk_size_changed)
	load_image_on_memory();
	loading_thread = Thread.new();
	var size = GeneratorConfig.chunk_size
	loading_thread.start(generate_m_x_n_chunks.bind(size, size));

func _exit_tree():
	should_abort_chunk_loading = true;
	loading_thread.wait_to_finish();

func _on_chunk_size_changed():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	loading_thread = Thread.new();
	var size = GeneratorConfig.chunk_size
	loading_thread.start(generate_m_x_n_chunks.bind(size, size));
