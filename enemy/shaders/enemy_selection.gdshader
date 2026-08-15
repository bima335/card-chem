shader_type canvas_item;

uniform bool is_selected = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.4;
uniform float max_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	if (is_selected) {
		vec2 texel_size = TEXTURE_PIXEL_SIZE;
		float alpha_sum = 0.0;

		alpha_sum += texture(TEXTURE, UV + vec2(0.0, -outline_thickness) * texel_size).a;
		alpha_sum += texture(TEXTURE, UV + vec2(0.0, outline_thickness) * texel_size).a;
		alpha_sum += texture(TEXTURE, UV + vec2(-outline_thickness, 0.0) * texel_size).a;
		alpha_sum += texture(TEXTURE, UV + vec2(outline_thickness, 0.0) * texel_size).a;

		alpha_sum += texture(TEXTURE, UV + vec2(-outline_thickness, -outline_thickness) * texel_size * 0.7071).a;
		alpha_sum += texture(TEXTURE, UV + vec2(outline_thickness, -outline_thickness) * texel_size * 0.7071).a;
		alpha_sum += texture(TEXTURE, UV + vec2(-outline_thickness, outline_thickness) * texel_size * 0.7071).a;
		alpha_sum += texture(TEXTURE, UV + vec2(outline_thickness, outline_thickness) * texel_size * 0.7071).a;

		if (base_color.a < 0.1 && alpha_sum > 0.0) {
			float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
			float dynamic_alpha = mix(min_alpha, max_alpha, pulse);
			COLOR = vec4(outline_color.rgb, outline_color.a * dynamic_alpha);
		} else {
			COLOR = base_color;
		}
	} else {
		COLOR = base_color;
	}
}