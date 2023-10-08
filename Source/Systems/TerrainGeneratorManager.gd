extends Node


@onready var terrain_shader : Shader = preload("res://Content/Art/Shaders/TerrainBlue.gdshader");
@onready var terrain_texture : Texture2D = preload("res://Content/Art/Textures/EarthTerrain.png");


var image : Image;
var image_dims : Vector2i;
var image_data : PackedByteArray;


func load_image_on_memory():
	image = terrain_texture.get_image().duplicate();
	image.resize(image.get_width(), image.get_height(), Image.INTERPOLATE_BILINEAR);
	
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
	generate_chunk(Vector2(0.0, 0.0), Vector2(0.295, 0.565), Vector2(0.305, 0.58));
	generate_chunk(Vector2(0.0, -2.0), Vector2(0.295, 0.565 - 0.015), Vector2(0.305, 0.58 - 0.015));


func _process(_delta):
	pass
