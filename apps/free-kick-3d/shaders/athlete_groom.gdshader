shader_type spatial;
render_mode cull_disabled;
// Opaque tapered geometry, with root-to-tip pigment variation.
uniform vec4 hair_tint : source_color = vec4(0.16, 0.13, 0.11, 1.0);
uniform bool groom_visible = true;
uniform bool facial_hair = false;
void fragment() {
    if (!groom_visible) { discard; }
    float variation = fract(sin(floor(UV.x * 101.0) * 127.1) * 43758.5453);
    float pigment = mix(facial_hair ? 0.65 : 0.78, facial_hair ? 1.22 : 1.08, variation) * mix(0.78, 1.0, UV.y);
    ALBEDO = hair_tint.rgb * pigment;
    ROUGHNESS = mix(facial_hair ? 0.65 : 0.84, facial_hair ? 0.82 : 0.92, variation);
    SPECULAR = facial_hair ? 0.27 : 0.14;
    RIM = 0.03;
    RIM_TINT = 0.35;
}
