shader_type spatial;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform sampler2D lettering_map : source_color, filter_linear, repeat_disable;
uniform bool lettering_enabled = false;
uniform bool shorts_details = false;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.3;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.5;
void fragment() {
    vec3 cloth = texture(albedo_map, UV).rgb * tint.rgb;
    if (lettering_enabled && all(greaterThanEqual(UV2, vec2(0.0))) && all(lessThanEqual(UV2, vec2(1.0)))) {
        vec4 print_color = texture(lettering_map, UV2);
        cloth = mix(cloth, print_color.rgb, print_color.a);
    }
    if (shorts_details) {
        // The GLB export flips V relative to the Blender seam coordinates.
        float height = 1.0 - UV2.y;
        float hem = 1.0 - smoothstep(0.0006, 0.0018, abs(height - 0.009));
        float side_panel = (1.0 - smoothstep(0.035, 0.055, abs(UV2.x - 0.5)))
            * (1.0 - smoothstep(0.18, 0.23, height));
        float waist = 1.0 - smoothstep(0.001, 0.003, abs(height - 0.303));
        cloth *= (1.0 + 0.12 * side_panel) * (1.0 - 0.18 * hem - 0.12 * waist);
    }
    ALBEDO = cloth;
    NORMAL_MAP = texture(normal_map, UV).rgb;
    NORMAL_MAP_DEPTH = normal_depth;
    ROUGHNESS = max(roughness_floor, texture(roughness_map, UV).g);
    SPECULAR = specular_strength;
}
