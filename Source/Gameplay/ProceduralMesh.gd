class_name ProceduralMesh;
extends MeshInstance3D;


var image_dims : Vector2i;
var crop_upper_left_index : Vector2i;
var crop_lower_right_index : Vector2i;


func generate_mesh(terrainGeneratorManager : TerrainGeneratorManager):
	mesh = ArrayMesh.new();
	
	var surface_array = [];
	surface_array.resize(Mesh.ARRAY_MAX);
	
	var uvs = PackedVector2Array();
	var indices = PackedInt32Array();
	var normals = PackedVector3Array();
	var vertices = PackedVector3Array();
	
	var image_upper_left_indices : Vector2i = crop_upper_left_index;
	var image_lower_right_indices : Vector2i = crop_lower_right_index;
	var cropped_width : int = absi(image_lower_right_indices.x - image_upper_left_indices.x) + 1;
	var cropped_height : int = absi(image_lower_right_indices.y - image_upper_left_indices.y) + 1;
	
	for i in range(image_upper_left_indices.y, image_lower_right_indices.y + 1):
		for j in range(image_upper_left_indices.x, image_lower_right_indices.x + 1):
			var index : int = clamp(i, 0, image_dims.y - 1) * image_dims.x + clamp(j, 0, image_dims.x - 1);
			var y_val : float = clamp(terrainGeneratorManager.image_data[index] / 255.0, 0.0, 1.0);
			var x_val : float = clamp(-1.0 + 2.0 * float(j - image_upper_left_indices.x) / float(cropped_width - 1), -1.0, 1.0);
			var z_val : float = clamp(-1.0 + 2.0 * float(i - image_upper_left_indices.y) / float(cropped_height - 1), -1.0, 1.0);
			vertices.append(Vector3(x_val, y_val, z_val));
			normals.append(Vector3.UP);
			uvs.append(Vector2(0.0, 0.0));
	
	for i in range(cropped_height - 1):
		for j in range(cropped_width - 1):
			var index : int = i * cropped_width + j;
			indices.append(index);
			indices.append(index + cropped_width + 1);
			indices.append(index + cropped_width);
			indices.append(index);
			indices.append(index + 1);
			indices.append(index + cropped_width + 1);
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices;
	surface_array[Mesh.ARRAY_TEX_UV] = uvs;
	surface_array[Mesh.ARRAY_NORMAL] = normals;
	surface_array[Mesh.ARRAY_INDEX]  = indices;
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array);
