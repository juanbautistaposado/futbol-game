shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Original dense 1 m clipped-canopy maps, mipmapped and anisotropic.
// The near geometry layer shares these colours and the six-metre cut bands.
uniform sampler2D surface_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
#include "res://shaders/turf_surface.gdshaderinc"
varying vec3 world;
varying float top_surface;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	top_surface = clamp(dot(MODEL_NORMAL_MATRIX * NORMAL, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
}

void fragment() {
	vec2 ground = world.xz;
	float footprint = max(length(dFdx(ground)), length(dFdy(ground)));
	float mowing_phase = turf_mowing_phase(ground);
	float edge_filter = max(fwidth(mowing_phase), 0.07);
	float stripe = smoothstep(-edge_filter, edge_filter, sin(mowing_phase));
	vec3 grass = turf_canopy_color(stripe, CAMERA_POSITION_WORLD - world);

	// A professional close-cut pitch reads as a cohesive canopy. Macro
	// variation is only +/-0.8%, avoiding the former long camouflage clouds.
	float broad = turf_noise(ground * 0.055 + vec2(11.7, 3.4));
	float patch = turf_noise(ground * 2.4 + vec2(41.8, 17.2));
	grass *= 0.992 + broad * 0.016 + (patch - 0.5) * 0.025;

	vec3 detail = texture(surface_detail, ground).rgb;
	vec3 detail_other = texture(surface_detail, vec2(-ground.y, ground.x) + vec2(0.413, 0.271)).rgb;
	float leaf_light = mix(detail.r, detail_other.r, 0.22);
	// The neutral texture mean preserves luminosity across mip levels.
	grass *= 0.66 + leaf_light * 0.68;
	grass += vec3(0.003, 0.002, -0.001) * (detail.g - 0.5);

	float broken_wear = smoothstep(0.25, 0.78, patch * 0.7 + detail.g * 0.3);
	float wear = turf_wear(ground) * broken_wear;
	grass = mix(grass, vec3(0.157, 0.153, 0.069), wear);

	ALBEDO = grass;
	// A broad leaf response provides grazing highlights rather than the
	// flat matte carpet. Fine normal frequencies fade before moire appears.
	ROUGHNESS = clamp(0.80 + (detail.b - 0.76) * 0.25 + wear * 0.11, 0.77, 0.90);
	SPECULAR = 0.24;
	vec3 relief = texture(surface_normal, ground).xyz * 2.0 - 1.0;
	float normal_visible = 1.0 - smoothstep(0.025, 0.12, footprint);
	vec3 normal_world = normalize(vec3(relief.x * 0.65 * normal_visible, 1.0,
		 relief.y * 0.65 * normal_visible + (stripe * 2.0 - 1.0) * 0.020));
	vec3 grass_normal_view = (VIEW_MATRIX * vec4(normal_world, 0.0)).xyz;
	NORMAL = normalize(mix(NORMAL, grass_normal_view, top_surface));
}
