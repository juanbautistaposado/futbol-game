shader_type spatial;
// Closed anatomical eyeballs, naturally occluded by the mesh's eyelids.
void fragment() {
    vec2 eye = (UV - 0.5) * 0.030;
    float radius = length(eye);
    float angle = atan(eye.y, eye.x);
    float iris = 1.0 - smoothstep(0.0055, 0.00585, radius);
    float pupil = 1.0 - smoothstep(0.00205, 0.00230, radius);
    float rim = smoothstep(0.0047, 0.0057, radius);
    float fibers = sin(angle * 79.0 + sin(angle * 31.0) * 1.5 + radius * 1900.0);
    vec3 iris_color = mix(vec3(0.17, 0.094, 0.043), vec3(0.030, 0.023, 0.018), rim);
    iris_color *= 0.88 + fibers * 0.12;
    float edge = smoothstep(0.007, 0.013, radius);
    vec3 sclera = mix(vec3(0.42, 0.405, 0.38), vec3(0.33, 0.27, 0.25), edge * 0.35);
    ALBEDO = mix(sclera, iris_color, iris);
    ALBEDO = mix(ALBEDO, vec3(0.004, 0.003, 0.002), pupil);
    // The upper eyelid shades the cornea. Keep the limbal ring visible without
    // the uniform bright sclera that gives the eyes a detached, doll-like look.
    float lid_shadow = smoothstep(-0.001, 0.008, -eye.y);
    ALBEDO *= 1.0 - lid_shadow * 0.23;
    ROUGHNESS = mix(0.26, 0.16, iris);
    SPECULAR = 0.48;
    CLEARCOAT = 0.22;
    CLEARCOAT_ROUGHNESS = 0.14;
}
