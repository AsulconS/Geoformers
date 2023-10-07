@tool
extends MeshInstance3D


@export var amplitude_scale = 0.05;
@export var widht_scale : float = 0.01;
@export var height_scale : float = 0.02;
@export var terrain_texture : Texture2D;
@export var generate_procedural_mesh = false : set = generate_procedural_mesh_fn;


func generate_procedural_mesh_fn(_dummy: bool):
	mesh = ArrayMesh.new();
	
	var surface_array = [];
	surface_array.resize(Mesh.ARRAY_MAX);
	
	var vertices = PackedVector3Array();
	var uvs = PackedVector2Array();
	var normals = PackedVector3Array();
	var indices = PackedInt32Array();
	
	var image : Image = terrain_texture.get_image().duplicate();
	image.resize(widht_scale * image.get_width(), height_scale * image.get_height(), Image.INTERPOLATE_BILINEAR);
	
	var image_data : PackedByteArray = image.get_data();
	var image_dims : Vector2 = Vector2(image.get_width(), image.get_height());
	for i in range(image_dims.x):
		for j in range(image_dims.y):
			var y_val : float = amplitude_scale * image_data[i * image_dims.y + j] / 255.0;
			var x_val : float = -1.0 + 2.0 * float(j) / image_dims.y;
			var z_val : float = -1.0 + 2.0 * float(i) / image_dims.x;
			var vertex : Vector3 = Vector3(x_val, y_val, z_val);
			vertices.append(vertex);
			normals.append(Vector3.UP);
			uvs.append(Vector2(0.0, 0.0));
	for i in range(image_dims.x - 1):
		for j in range(image_dims.y - 1):
			var index : int = i * image_dims.y + j;
			indices.append(index);
			indices.append(index + image_dims.y + 1);
			indices.append(index + image_dims.y);
			indices.append(index);
			indices.append(index + 1);
			indices.append(index + image_dims.y + 1);
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices;
	surface_array[Mesh.ARRAY_TEX_UV] = uvs;
	surface_array[Mesh.ARRAY_NORMAL] = normals;
	surface_array[Mesh.ARRAY_INDEX]  = indices;
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array);


func _process(_delta):
	pass;
