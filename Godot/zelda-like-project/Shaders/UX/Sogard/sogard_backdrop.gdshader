shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation : hint_range(0.0, 1.0) = 0.0;
uniform float darken : hint_range(0.0, 1.0) = 0.72;
uniform vec4 tint : source_color = vec4(0.0157, 0.0039, 0.0078, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = mix(c, tint.rgb, darken);
	COLOR = vec4(c, alpha);
}
