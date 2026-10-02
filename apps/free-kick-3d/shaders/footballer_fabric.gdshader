shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform vec4 tint : source_color = vec4(0.25, 0.35, 0.65, 1.0);
void fragment() {
    float weave = sin(UV.x * 720.0) * sin(UV.y * 620.0) * 0.012;
    float cloth_fold = sin(UV.x * 26.0 + UV.y * 13.0) * 0.016;
    ALBEDO = tint.rgb * (0.985 + weave + cloth_fold);
    ROUGHNESS = 0.87;
    METALLIC = 0.0;
}
