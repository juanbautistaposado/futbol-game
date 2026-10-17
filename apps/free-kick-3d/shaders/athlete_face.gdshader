shader_type spatial;
// Dedicated head UVs; anatomical eyes and mouth interior are separate surfaces.
#include "res://shaders/athlete_skin_detail.gdshaderinc"
uniform sampler2D face_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 skin_tint : source_color = vec4(0.733, 0.533, 0.408, 1.0);
uniform vec4 hair_tint : source_color = vec4(0.16, 0.13, 0.11, 1.0);
uniform bool beard_enabled = false;
varying vec3 rest_position;
void vertex() { rest_position = VERTEX; }
void fragment() {
    vec3 pigment = texture(face_albedo, UV).rgb;
    // Measured cheek/forehead pigment of this atlas, in sRGB / linear light.
    // Neutralizing it keeps pale presets distinct under the editor's lighting.
    vec3 reference = OUTPUT_IS_SRGB ? vec3(0.93, 0.65, 0.50) : vec3(0.8481, 0.3801, 0.2140);
    vec3 variation = clamp(pigment / reference, vec3(0.50), vec3(1.25));
    float neck_blend = smoothstep(1.605, 1.665, rest_position.y);
    // Same diffuse calibration as the body, with local pigment retained.
    vec3 skin = skin_tint.rgb * (OUTPUT_IS_SRGB ? 0.58 : 0.3364);
    ALBEDO = skin * mix(vec3(1.0), variation, neck_blend * 0.72);
    float lip = 1.0 - smoothstep(0.78, 1.12, length((UV - vec2(0.5, 0.710)) / vec2(0.063, 0.054)));
    float nose = exp(-dot((UV - vec2(0.5, 0.58)) / vec2(0.05, 0.08), (UV - vec2(0.5, 0.58)) / vec2(0.05, 0.08)));
    float forehead = (1.0 - smoothstep(0.28, 0.43, UV.y)) * neck_blend;
    vec3 pores = athlete_pores(UV * 0.8);
    NORMAL_MAP = vec3(0.5 + pores.xy * 0.6, 1.0);
    NORMAL_MAP_DEPTH = 0.20;
    ROUGHNESS = 0.58 - nose * 0.09 - forehead * 0.045 - lip * 0.13;
    SPECULAR = 0.28 + lip * 0.05;
    ALBEDO *= 1.0 - pores.z * 0.30 * (1.0 - lip);
    if (beard_enabled) {
        // Authored on the current head, shared with the beard root sampler.
        // Vertex color remains attached to the face during kicks and dives.
        float coverage = clamp(COLOR.r, 0.0, 1.0) * (1.0 - lip);
        float follicles = athlete_follicles(UV * 1.2);
        // Subtle follicle pigment underneath real fibers, not a flat painted
        // beard. The skin remains visible between short, individually lit hairs.
        ALBEDO = mix(ALBEDO, hair_tint.rgb * 0.74, coverage * follicles * 0.045);
        ROUGHNESS = mix(ROUGHNESS, 0.72, coverage * 0.2);
    }
}
