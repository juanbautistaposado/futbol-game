shader_type spatial;
uniform vec4 glove_tint : source_color = vec4(0.86, 0.88, 0.84, 1.0);
void fragment() {
    vec2 grid = UV * 720.0;
    float visible = 1.0 - smoothstep(0.35, 1.0, max(fwidth(grid.x), fwidth(grid.y)));
    vec2 grain = sin(grid * 6.2831853) * visible;
    ALBEDO = glove_tint.rgb * (1.0 - 0.012 * grain.x * grain.y);
    NORMAL_MAP = normalize(vec3(grain * 0.025, 1.0)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 0.25;
    // A broad, restrained reflection reads as padded latex under floodlights.
    ROUGHNESS = 0.68 + grain.x * grain.y * 0.035;
    SPECULAR = 0.32;
}
