extends Node


@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");
@onready var terrain_chunk_size : Vector2 = Vector2();


var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;
var chunk_dims : Vector2 = Vector2(3.0, 2.0);
var ul_chunk_pos : Vector2 = Vector2(0.295, 0.565);
var lr_chunk_pos : Vector2 = Vector2(0.305, 0.58);


func load_image_on_memory():
	image = terrain_texture.get_image().duplicate();
	#image.resize(image.get_width(), image.get_height(), Image.INTERPOLATE_BILINEAR);
	
	image_data = image.get_data();
	image_dims = Vector2i(image.get_width(), image.get_height());


func generate_chunk(position : Vector2, crop_upper_left_pivot : Vector2, crop_lower_right_pivot : Vector2):
	var new_mesh : ProceduralMesh = ProceduralMesh.new();
	new_mesh.name = "MeshInstance01";
	add_child(new_mesh);
	
	new_mesh.position = Vector3(position.x, 0.0, position.y);
	new_mesh.scale = Vector3(1.5, 0.2, 1.0);
	new_mesh.material_override = ShaderMaterial.new();
	new_mesh.material_override.set_shader(terrain_shader);
	
	new_mesh.crop_upper_left_pivot = crop_upper_left_pivot;
	new_mesh.crop_lower_right_pivot = crop_lower_right_pivot;
	new_mesh.generate_mesh(image_data, image_dims);


func _ready():
	load_image_on_memory();
	var chunk_crop_dims : Vector2 = lr_chunk_pos - ul_chunk_pos;
	var terrain_origin  : Vector2 = Vector2.ZERO;
	generate_chunk(terrain_origin, ul_chunk_pos, lr_chunk_pos);
	generate_chunk(terrain_origin + chunk_dims * Vector2.LEFT,
				   ul_chunk_pos + chunk_crop_dims * Vector2.LEFT,
				   lr_chunk_pos + chunk_crop_dims * Vector2.LEFT);
	generate_chunk(terrain_origin + chunk_dims * Vector2.RIGHT,
				   ul_chunk_pos + chunk_crop_dims * Vector2.RIGHT,
				   lr_chunk_pos + chunk_crop_dims * Vector2.RIGHT);
	generate_chunk(terrain_origin + chunk_dims * Vector2.DOWN,
				   ul_chunk_pos + chunk_crop_dims * Vector2.DOWN,
				   lr_chunk_pos + chunk_crop_dims * Vector2.DOWN);
	generate_chunk(terrain_origin + chunk_dims * Vector2.UP,
				   ul_chunk_pos + chunk_crop_dims * Vector2.UP,
				   lr_chunk_pos + chunk_crop_dims * Vector2.UP);
