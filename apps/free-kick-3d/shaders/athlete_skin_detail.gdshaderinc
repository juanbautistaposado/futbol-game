// Analytic, derivative-filtered microrelief: no large extra atlas per identity.
uniform sampler2D skin_microdetail : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
float athlete_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 athlete_pores(vec2 uv) {
    vec2 p = uv * 4.0;
    vec2 texel = 1.0 / vec2(textureSize(skin_microdetail, 0));
    float center = texture(skin_microdetail, p).r;
    float dx = texture(skin_microdetail, p + vec2(texel.x, 0.0)).r - center;
    float dy = texture(skin_microdetail, p + vec2(0.0, texel.y)).r - center;
    float broad = textureLod(skin_microdetail, p, 4.0).r;
    return vec3(vec2(dx, dy) * 0.42, (center - broad) * 0.12);
}

float athlete_follicles(vec2 uv) {
    vec2 p = uv * 2100.0;
    vec2 cell = floor(p);
    vec2 f = fract(p) - 0.5;
    float seed = athlete_hash(cell);
    f.x += f.y * (seed - 0.5) * 0.7;
    float fiber = (1.0 - smoothstep(0.055, 0.19, abs(f.x)))
        * (1.0 - smoothstep(0.22, 0.49, abs(f.y)));
    float filtered = 1.0 - smoothstep(0.45, 1.6, max(length(dFdx(p)), length(dFdy(p))));
    return mix(0.42, fiber, filtered) * mix(0.75, 1.0, seed);
}
