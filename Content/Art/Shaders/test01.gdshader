shader_type spatial;

varying vec3 vertex_position;

void vertex() {
	float height = clamp(VERTEX.y, 0.0f, 1.0f);
	vertex_position = vec3(0.0f, 0.2f * height, height);
}

void fragment() {
	ALBEDO = vertex_position;
	ROUGHNESS = 0.95f;
	METALLIC = 0.5f;
}
