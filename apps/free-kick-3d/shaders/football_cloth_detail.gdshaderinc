// Fine knitted polyester detail, filtered away before it can shimmer in play.
// UV0 and the semantic atlas masks remain unchanged for the character editor.
uniform bool surface_detail_enabled = false;
uniform float cloth_coverage_override : hint_range(0.0, 1.0) = 0.0;
uniform float white_cloth_override : hint_range(0.0, 1.0) = 0.0;
uniform bool semantic_masks_enabled = false;
uniform float cloth_atlas_cleanup : hint_range(0.0, 1.0) = 0.82;
uniform vec4 atlas_shorts_color : source_color = vec4(0.0549, 0.0627, 0.1059, 1.0);

vec3 football_weave(vec2 uv) {
    // Jersey-knit loops have a gentle diagonal offset, not a checkerboard.
    vec2 grid = vec2(uv.x + uv.y * 0.12, uv.y) * vec2(1050.0, 1420.0);
    float footprint = max(fwidth(grid.x), fwidth(grid.y));
    float visible = 1.0 - smoothstep(0.35, 1.0, footprint);
    return vec3(sin(grid.x * 6.2831853), sin(grid.y * 6.2831853),
        sin(grid.x * 6.2831853) * sin(grid.y * 6.2831853)) * visible;
}

vec3 football_clean_white(vec3 pigment) {
    float value = dot(pigment, vec3(0.2126, 0.7152, 0.0722));
    float reference = OUTPUT_IS_SRGB ? 0.94 : 0.87;
    // The scan already contains shadows. Keep small fold variation while
    // letting the stadium lights supply the main shading. Also suppress dark
    // texels bleeding into tiny white UV islands at lower texture mip levels.
    float detail = clamp(value / reference, 0.0, 1.1);
    vec3 neutral = vec3(reference * (0.90 + detail * 0.10));
    return mix(pigment, neutral, cloth_atlas_cleanup);
}
