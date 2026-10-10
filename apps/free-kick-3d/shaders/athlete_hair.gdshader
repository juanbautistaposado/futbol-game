shader_type spatial;
render_mode cull_disabled;
uniform vec4 hair_tint : source_color = vec4(0.1, 0.07, 0.04, 1.0);
uniform vec4 skin_tint : source_color = vec4(0.6, 0.35, 0.2, 1.0);
void fragment() {
	float coverage = smoothstep(0.08, 0.9, COLOR.r);
	float strand = 0.98 + 0.02 * sin(UV.x * 1600.0 + sin(UV.y * 450.0));
	ALBEDO = mix(skin_tint.rgb, hair_tint.rgb * strand, coverage);
	ROUGHNESS = 0.88;
	SPECULAR = 0.15;
}
