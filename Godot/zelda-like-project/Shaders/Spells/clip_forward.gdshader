shader_type canvas_item;

uniform vec2 clip_origin;
uniform vec2 clip_dir;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (dot(world_pos - clip_origin, clip_dir) < 0.0) {
		discard;
	}
}
