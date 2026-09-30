shader_type canvas_item;

uniform float scroll_rate : hint_range(0.0, 2.0) = 0.0;
uniform float step_rate : hint_range(1.0, 60.0) = 12.0;

void fragment() {
	float stepped_time = floor(TIME * step_rate) / step_rate;
	vec2 uv = UV;
	uv.x += stepped_time * scroll_rate;
	COLOR = texture(TEXTURE, fract(uv));
}
