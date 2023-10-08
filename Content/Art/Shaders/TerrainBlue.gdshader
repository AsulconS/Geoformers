shader_type spatial;

varying vec3 vertex_position;

uniform vec3 albedo_ref : source_color = vec3(0.0f, 0.2f, 1.0f);

void vertex() {
	float height = clamp(VERTEX.y, 0.0f, 1.0f);
	vertex_position = height * albedo_ref;
}

void fragment() {
	ALBEDO = vertex_position;
	ROUGHNESS = 0.95f;
	METALLIC = 0.5f;
}
