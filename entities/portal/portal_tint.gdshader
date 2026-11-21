shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float luminance = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
	float shading = 0.55 + 0.45 * luminance;
	vec3 tinted = tint_color.rgb * shading;
	COLOR = vec4(mix(texel.rgb, tinted, 0.7), texel.a * tint_color.a);
}
