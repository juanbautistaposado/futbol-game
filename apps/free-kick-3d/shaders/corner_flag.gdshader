shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float free_edge = clamp(UV.x, 0.0, 1.0);
	VERTEX.z += sin(TIME * 2.3 - UV.x * 5.0) * 0.045 * free_edge * free_edge;
}

void fragment() {
	ALBEDO = mix(vec3(0.81, 0.21, 0.14), vec3(0.96, 0.80, 0.27), step(0.5, UV.x));
	ROUGHNESS = 0.88;
}
