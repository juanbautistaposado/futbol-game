// One canopy response for the textured ground and the raised grass crowns.
// Values are scene-linear, deliberately restrained under broadcast daylight.
uniform vec3 grass_dark = vec3(0.102, 0.193, 0.076);
uniform vec3 grass_light = vec3(0.122, 0.226, 0.092);

float turf_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float turf_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 blend = f * f * (3.0 - 2.0 * f);
	return mix(mix(turf_hash(cell), turf_hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(turf_hash(cell + vec2(0.0, 1.0)), turf_hash(cell + vec2(1.0, 1.0)), blend.x), blend.y);
}

float turf_mowing_phase(vec2 ground) {
	return (ground.y + 52.5) * 0.5235987756;
}

vec3 turf_canopy_color(float stripe, vec3 to_camera) {
	// Mower passes bend leaves. Their contrast changes with viewing direction,
	// unlike permanently painted bright and dark strips. Keep the transition
	// continuous when the camera turns or switches ends of the pitch.
	float direction = to_camera.z / max(length(to_camera), 0.01);
	float response = 0.5 + (stripe - 0.5) * (0.22 + 0.70 * direction);
	return mix(grass_dark, grass_light, response);
}

float turf_wear(vec2 ground) {
	vec2 goal = vec2(ground.x / 5.3, (abs(ground.y) - 51.0) / 2.3);
	vec2 shot = vec2(ground.x / 1.7, (abs(ground.y) - 28.5) / 2.0);
	// Compact, continuous masks: maintained grass, not a brown penalty box.
	return (1.0 - smoothstep(0.0, 1.0, dot(goal, goal))) * 0.22
		+ (1.0 - smoothstep(0.0, 1.0, dot(shot, shot))) * 0.09;
}
