shader_type sky;
render_mode disable_fog;

// Static clouds are baked into the sky radiance once, then sampled as a cubemap.
// No TIME or POSITION dependency: camera motion never rebakes the illumination.
uniform vec3 zenith_color : source_color = vec3(0.30, 0.49, 0.69);
uniform vec3 horizon_color : source_color = vec3(0.76, 0.83, 0.86);
uniform vec3 cloud_color : source_color = vec3(0.92, 0.94, 0.96);
uniform vec3 ground_color : source_color = vec3(0.22, 0.27, 0.20);

float hash_cloud(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float cloud_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cloud(cell), hash_cloud(cell + vec2(1.0, 0.0)), f.x),
		mix(hash_cloud(cell + vec2(0.0, 1.0)), hash_cloud(cell + vec2(1.0)), f.x), f.y);
}

float cloud_layer(vec2 p) {
	float value = 0.0;
	float weight = 0.52;
	mat2 rotation = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		value += cloud_noise(p) * weight;
		p = rotation * p * 2.07 + vec2(17.3, 8.1);
		weight *= 0.49;
	}
	return value;
}

void sky() {
	if (!AT_CUBEMAP_PASS) {
		COLOR = texture(RADIANCE, EYEDIR).rgb;
	} else {
		vec3 direction = normalize(EYEDIR);
		float elevation = max(direction.y, 0.0);
		vec3 sky_color = mix(horizon_color, zenith_color, pow(elevation, 0.42));
		vec2 cloud_uv = direction.xz / max(elevation + 0.14, 0.16) * 2.0;
		float density = cloud_layer(cloud_uv + vec2(2.4, 6.8));
		float cloud = smoothstep(0.47, 0.69, density) * smoothstep(0.015, 0.20, elevation);
		float silver = cloud_layer(cloud_uv * 1.85 + vec2(3.0, 1.0));
		vec3 clouds = cloud_color * mix(0.69, 1.0, silver);
		sky_color = mix(sky_color, clouds, cloud * 0.86);
		if (LIGHT0_ENABLED) {
			float sun_alignment = max(dot(direction, LIGHT0_DIRECTION), 0.0);
			// Broad atmospheric scatter, with a restrained sun disc to avoid fireflies.
			sky_color += LIGHT0_COLOR * pow(sun_alignment, 18.0) * 0.16;
			sky_color += LIGHT0_COLOR * smoothstep(0.99988, 0.99997, sun_alignment) * 1.6;
		}
		COLOR = mix(ground_color, sky_color, smoothstep(-0.08, 0.02, direction.y));
	}
}
