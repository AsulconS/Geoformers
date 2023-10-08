class_name TerrainGeneratorManager;
extends Node;


@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");
@onready var terrain_chunk_size : Vector2 = Vector2();


var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;
var chunk_dims : Vector2 = Vector2(3.0, 2.0);
var ul_chunk_pos : Vector2 = Vector2(0.295, 0.565); # [6350, 6200]
var lr_chunk_pos : Vector2 = Vector2(0.305, 0.58);  # [6500, 6400]
var chunks_generated : int = 0;

var loading_thread : Thread;


func load_image_on_memory():
	image = terrain_texture.get_image().duplicate();
	#image.resize(image.get_width(), image.get_height(), Image.INTERPOLATE_BILINEAR);
	
	image_data = image.get_data();
	image_dims = Vector2i(image.get_width(), image.get_height());


func generate_chunk(position : Vector2, crop_upper_left_pivot : Vector2, crop_lower_right_pivot : Vector2, albedo_ref : Vector3 = Vector3(0.0, 0.2, 1.0)):
	var new_mesh : ProceduralMesh = ProceduralMesh.new();
	new_mesh.name = "MeshInstance01";
	new_mesh.position = Vector3(position.x, 0.0, position.y);
	new_mesh.scale = Vector3(1.5, 0.2, 1.0);
	new_mesh.material_override = ShaderMaterial.new();
	new_mesh.material_override.set_shader(terrain_shader);
	new_mesh.material_override.set_shader_parameter("albedo_ref", albedo_ref);
	
	new_mesh.crop_upper_left_pivot = crop_upper_left_pivot;
	new_mesh.crop_lower_right_pivot = crop_lower_right_pivot;
	new_mesh.generate_mesh(self);
	chunks_generated += 1;
	
	call_deferred("add_child", new_mesh);


func generate_m_x_n_chunks(m : int, n : int):
	var ul_offset : Vector2i = Vector2i(-m / 2, -n / 2);
	var lr_offset_lim : Vector2i = Vector2i((m + 1) / 2, (n + 1) / 2);
	var terrain_origin  : Vector2 = Vector2.ZERO;
	var chunk_crop_dims : Vector2 = lr_chunk_pos - ul_chunk_pos;
	for i in range(ul_offset.y, lr_offset_lim.y):
		for j in range(ul_offset.x, lr_offset_lim.x):
			var direction_vector : Vector2 = Vector2(float(j), float(i));
			generate_chunk(terrain_origin + chunk_dims * direction_vector,
						   ul_chunk_pos + chunk_crop_dims * direction_vector,
						   lr_chunk_pos + chunk_crop_dims * direction_vector);


func _ready():
	load_image_on_memory();
	loading_thread = Thread.new();
	loading_thread.start(generate_m_x_n_chunks.bind(9, 9));


func _exit_tree():
	loading_thread.wait_to_finish();
