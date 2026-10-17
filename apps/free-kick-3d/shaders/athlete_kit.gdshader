shader_type spatial;
#include "res://shaders/football_cloth_detail.gdshaderinc"
#include "res://shaders/athlete_skin_detail.gdshaderinc"
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lettering_map : source_color, filter_linear, repeat_disable;
uniform bool lettering_enabled = false;
uniform bool shorts_details = false;
uniform bool atlas_shorts_enabled = false;
// Semantic UV regions of the complete Meshy avatar: skin/hair/shorts/beard.
// Data samplers stay linear; color references below follow the active renderer.
uniform sampler2D appearance_mask : filter_linear_mipmap, repeat_enable;
uniform sampler2D cloth_mask : filter_linear_mipmap, repeat_enable;
uniform sampler2D facial_mask : filter_linear_mipmap, repeat_enable;
uniform bool personalization_enabled = false;
uniform vec4 skin_tint : source_color = vec4(0.7, 0.5, 0.35, 1.0);
uniform vec4 hair_tint : source_color = vec4(0.15, 0.1, 0.07, 1.0);
uniform vec4 shorts_tint : source_color = vec4(0.05, 0.07, 0.1, 1.0);
uniform vec4 shirt_tint : source_color = vec4(1.0);
uniform bool beard_enabled = true;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.3;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.5;
void fragment() {
    vec3 pigment = texture(albedo_map, UV).rgb;
    vec4 regions = vec4(0.0);
    float shirt_region = white_cloth_override;
    if (semantic_masks_enabled || personalization_enabled) {
        regions = texture(appearance_mask, UV);
        shirt_region = max(shirt_region, texture(cloth_mask, UV).r);
    }
    float cloth_region = max(cloth_coverage_override, max(shirt_region, regions.b));
    if (surface_detail_enabled) {
        pigment = mix(pigment, football_clean_white(pigment), shirt_region);
        if (!personalization_enabled && semantic_masks_enabled) {
            float value = dot(pigment, vec3(0.2126, 0.7152, 0.0722));
            float reference = OUTPUT_IS_SRGB ? 0.064 : 0.0054;
            vec3 clean_shorts = atlas_shorts_color.rgb * clamp(value / reference, 0.84, 1.16);
            pigment = mix(pigment, clean_shorts, regions.b * cloth_atlas_cleanup);
        }
    }
    vec3 cloth = pigment * tint.rgb;
    if (atlas_shorts_enabled) {
        float shade = dot(pigment, vec3(0.2126, 0.7152, 0.0722));
        cloth = tint.rgb * clamp(shade / (OUTPUT_IS_SRGB ? 0.054 : 0.0043), 0.86, 1.14);
    }
    vec4 face = vec4(0.0);
    if (semantic_masks_enabled || personalization_enabled) { face = texture(facial_mask, UV); }
    float follicles = athlete_follicles(UV);
    float removed_facial_hair = 0.0;
    if (personalization_enabled) {
        float shade = dot(cloth, vec3(0.2126, 0.7152, 0.0722));
        // Preserve authored shading and pores while replacing the base pigment.
        float skin_reference = OUTPUT_IS_SRGB ? 0.477 : 0.206;
        float hair_reference = OUTPUT_IS_SRGB ? 0.125 : 0.017;
        float shorts_reference = OUTPUT_IS_SRGB ? 0.054 : 0.0043;
        // Palette colors describe perceived complexion. Skin diffuse reflectance
        // is lower than a UI swatch: this prevents the studio lights from burning
        // the first five presets to the same white/red while preserving steps.
        vec3 skin_base = skin_tint.rgb * (OUTPUT_IS_SRGB ? 0.58 : 0.58 * 0.58);
        float local_shade = dot(textureLod(albedo_map, UV, 3.0).rgb, vec3(0.2126, 0.7152, 0.0722));
        float fine_pigment = clamp(shade / max(local_shade, 0.01), 0.985, 1.015);
        vec3 skin = skin_base * fine_pigment * clamp(shade / skin_reference, 0.96, 1.04);
        vec3 hair = hair_tint.rgb * clamp(shade / hair_reference, 0.72, 1.16);
        vec3 shorts = shorts_tint.rgb * clamp(shade / shorts_reference, 0.88, 1.12);
        cloth = mix(cloth, cloth * shirt_tint.rgb, shirt_region);
        cloth = mix(cloth, skin, regions.r);
        cloth = mix(cloth, hair, regions.g);
        cloth = mix(cloth, shorts, regions.b);
        // Restore bare skin over the entire stubble/moustache area, not only its
        // darkest texels. Keep a subtle pore variation without the painted beard.
        vec3 bare_skin = skin_base * fine_pigment;
        // Scattered follicles allow complexion to show between beard hairs;
        // geometry supplies the silhouette and the longer fibers.
        vec3 beard = mix(skin, hair, 0.70 + follicles * 0.26);
        cloth = mix(cloth, beard_enabled ? beard : bare_skin, beard_enabled ? face.g : regions.a);
        cloth = mix(cloth, hair, face.b);
        // Lip pigment shares the selected complexion and a muted rosy
        // undertone. It must not retain the original light-skinned atlas color.
        vec3 lips = skin_base * vec3(0.90, 0.65, 0.67)
            * clamp(shade / skin_reference, 0.55, 1.10);
        cloth = mix(cloth, lips, face.a);
        removed_facial_hair = beard_enabled ? 0.0 : regions.a;
    }
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
    // The original atlas also engraves beard fibers in the normal map.
    // Erasing pigment alone left their relief visible under the studio rim light.
    NORMAL_MAP = mix(texture(normal_map, UV).rgb, vec3(0.5, 0.5, 1.0), removed_facial_hair);
    NORMAL_MAP_DEPTH = normal_depth;
    ROUGHNESS = max(roughness_floor, texture(roughness_map, UV).g);
    SPECULAR = specular_strength;
    if (surface_detail_enabled) {
        vec3 weave = football_weave(UV);
        float skin_region = regions.r * (1.0 - cloth_region);
        float hair_region = max(regions.g, max(face.b, face.g * float(beard_enabled))) * (1.0 - cloth_region);
        vec3 pores = vec3(0.0);
        if (skin_region > 0.01) { pores = athlete_pores(UV); }
        // Keep skin softer than polyester; retain the authored pores/normal map.
        ROUGHNESS = mix(ROUGHNESS, clamp(texture(roughness_map, UV).g, 0.50, 0.64), skin_region);
        SPECULAR = mix(SPECULAR, 0.28, skin_region);
        NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, 0.09, skin_region);
        NORMAL_MAP.xy += pores.xy * skin_region;
        ALBEDO *= 1.0 - pores.z * skin_region;
        ROUGHNESS = mix(ROUGHNESS, 0.88, hair_region);
        SPECULAR = mix(SPECULAR, 0.14, hair_region);
        NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, 0.12, hair_region);
        // Lips have finer vertical creases and a restrained moist highlight.
        float lip_detail = sin(UV.x * 3100.0 + sin(UV.y * 420.0))
            * (1.0 - smoothstep(0.5, 1.5, fwidth(UV.x * 3100.0)));
        NORMAL_MAP.x += lip_detail * face.a * 0.012;
        ROUGHNESS = mix(ROUGHNESS, 0.43, face.a);
        SPECULAR = mix(SPECULAR, 0.34, face.a);
        ALBEDO *= mix(1.0, 0.82 + weave.z * 0.005, cloth_region);
        NORMAL_MAP.xy += weave.xy * cloth_region * 0.014;
        NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, min(NORMAL_MAP_DEPTH, 0.065), cloth_region);
        float fabric_roughness = clamp(0.73 + texture(roughness_map, UV).g * 0.10 + weave.z * 0.025, 0.73, 0.86);
        ROUGHNESS = mix(ROUGHNESS, fabric_roughness, cloth_region);
        SPECULAR = mix(SPECULAR, 0.28, cloth_region);
        // A small light-driven fiber response remains visible at match scale.
        // This is deliberately restrained for sports polyester, not velvet.
        RIM = cloth_region * 0.12;
        RIM_TINT = 0.72;
    }
}
