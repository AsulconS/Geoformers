shader_type canvas_item;

uniform float x_speed: hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float y_speed: hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float wave_speed: hint_range(0.0,20.0, 0.1) = 1.0;
vec2 calculateCoord(vec2 uv){
	float sin_xf = ((TIME*wave_speed/20.0)/2.0)+0.5;
	float sin_yf = ((TIME*wave_speed/20.0)/2.0)+0.5;
	vec2 coord = uv+vec2(sin_xf*x_speed,sin_yf*y_speed);
	while (coord.x > 1.0){
		coord.x = coord.x - 1.0;
	}
	while (coord.y > 1.0){
		coord.y = coord.y - 1.0;
	}
	return coord;
}

void fragment() {
	COLOR = texture(TEXTURE,calculateCoord(UV));
}
