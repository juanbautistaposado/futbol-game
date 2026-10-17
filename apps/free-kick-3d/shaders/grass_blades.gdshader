shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float fade_start = 10.0;
uniform float fade_end = 15.0;
uniform float focus_radius = 8.75;
uniform float focus_offset = 5.0;
uniform float focus_fade_width = 2.5;
#include "res://shaders/turf_surface.gdshaderinc"
varying vec3 world;
varying float leaf_variation;
varying float leaf_height;
varying float worn_canopy;

float chalk_mask(vec2 p) {
	vec2 a = abs(p);
	float chalk = 0.0;
	// Suppress blades on the painted lines, including curved markings.
	if (abs(a.x - 34.0) < 0.085 || abs(a.y - 52.5) < 0.085 || a.y < 0.085) chalk = 1.0;
	if (abs(length(p) - 9.15) < 0.085 || length(p) < 0.18) chalk = 1.0;
	if ((abs(a.x - 20.16) < 0.085 && a.y >= 35.915) || (abs(a.y - 36.0) < 0.085 && a.x <= 20.245)) chalk = 1.0;
	if ((abs(a.x - 9.16) < 0.085 && a.y >= 46.915) || (abs(a.y - 47.0) < 0.085 && a.x <= 9.245)) chalk = 1.0;
	vec2 penalty = vec2(p.x, a.y - 41.5);
	if (length(penalty) < 0.19 || (abs(length(penalty) - 9.15) < 0.085 && a.y < 36.0)) chalk = 1.0;
	if (abs(length(a - vec2(34.0, 52.5)) - 1.0) < 0.085) chalk = 1.0;
	return chalk;
}


void vertex() {
	vec3 root_world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float distance_to_camera = distance(root_world, CAMERA_POSITION_WORLD);
	float detail = 1.0 - smoothstep(fade_start, fade_end, distance_to_camera);
	vec2 forward = -INV_VIEW_MATRIX[2].xz;
	forward /= max(length(forward), 0.001);
	vec2 focus = CAMERA_POSITION_WORLD.xz + forward * focus_offset;
	detail *= 1.0 - smoothstep(focus_radius - focus_fade_width, focus_radius, distance(root_world.xz, focus));
	// Collapse roots on paint or outside the field in the vertex stage.
	// Opaque leaves can then use early depth testing, including under MSAA.
	if (abs(root_world.x) > 34.0 || abs(root_world.z) > 52.5 || chalk_mask(root_world.xz) > 0.5) detail = 0.0;
	float tip = UV.y;
	float mowing_phase = turf_mowing_phase(root_world.xz);
	// Tiles and instances rotate during pooling. Cancel that rotation so
	// curved crowns still follow the alternating, six-metre mower passes.
	float original_angle = atan(MODEL_MATRIX[2].x, MODEL_MATRIX[2].z);
	float target_angle = (sin(mowing_phase) > 0.0 ? 0.0 : 3.14159265);
	target_angle += (INSTANCE_CUSTOM.a - 0.5) * 1.10;
	float turn = target_angle - original_angle;
	mat2 align_mowing = mat2(vec2(cos(turn), -sin(turn)), vec2(sin(turn), cos(turn)));
	VERTEX.xz = align_mowing * VERTEX.xz;
	NORMAL.xz = align_mowing * NORMAL.xz;
	// Distinct leaves within one crown do not all bend or grow alike.
	float leaf_seed = sin(INSTANCE_CUSTOM.b * 6.283185 + UV2.x * 2.7);
	VERTEX.y *= 0.94 + leaf_seed * 0.08;
	VERTEX.x += leaf_seed * tip * tip * 0.0020;
	// The canopy is shorter in the same worn goal/shot zones as the surface.
	// Preserve every root and avoid adding another mesh or a transparent decal.
	worn_canopy = turf_wear(root_world.xz);
	VERTEX.y *= 1.0 - worn_canopy * 1.15;
	// A whole blade shrinks at the distance transition: no blended material,
	// no screen-door shimmer, and the base remains rooted in the surface.
	VERTEX.y *= detail;
	VERTEX.z *= detail;
	VERTEX.x *= detail;
	float wind_phase = TIME * 1.2 + root_world.x * 0.71 + root_world.z * 0.43 + INSTANCE_CUSTOM.g * 6.283185;
	VERTEX.x += sin(wind_phase) * tip * tip * 0.00045 * detail;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	leaf_variation = INSTANCE_CUSTOM.r;
	leaf_height = tip;
}


void fragment() {
	float mowing_phase = turf_mowing_phase(world.xz);
	float edge_filter = max(fwidth(mowing_phase), 0.07);
	float stripe = smoothstep(-edge_filter, edge_filter, sin(mowing_phase));
	vec3 grass = turf_canopy_color(stripe, CAMERA_POSITION_WORLD - world);
	// The dense lawn and its raised leaves share one illumination response.
	// Keep root-to-tip variation subtle: dark isolated cutouts break the mat.
	grass *= mix(0.94, 1.035, leaf_height);
	grass *= 0.955 + leaf_variation * 0.09;
	grass = mix(grass, vec3(0.157, 0.153, 0.069), worn_canopy * 0.5);
	ALBEDO = grass;
	// A tiny diffuse fill represents light scattered through neighbouring
	// leaves, preventing individual ribbons reading as black needles.
	EMISSION = grass * 0.010;
	ROUGHNESS = 0.80;
	SPECULAR = 0.24;
	// The surrounding canopy scatters light into the curved ribbons. Blend
	// most of their response toward the lawn while retaining a small change
	// with leaf direction, instead of flat black polygons against the ground.
	vec3 lawn_normal = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	if (dot(NORMAL, lawn_normal) < 0.0) NORMAL = -NORMAL;
	NORMAL = normalize(mix(NORMAL, lawn_normal, 0.76));
}
