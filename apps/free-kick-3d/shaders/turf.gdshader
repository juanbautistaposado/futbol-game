shader_type spatial;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void fragment() {
 // Alternating mowing direction is visible from the cameras without a harsh
 // checkerboard edge. World coordinates keep the pattern aligned across pitch.
 float stripe = smoothstep(0.40, 0.60, fract((world.z + 12.0) / 6.0));
 vec3 grass = mix(vec3(0.058, 0.188, 0.045), vec3(0.067, 0.210, 0.052), stripe);
 float broad_variation = sin(world.x * 0.23) * sin(world.z * 0.17);
 vec2 cell = world.xz * 0.55;
 vec2 tile = floor(cell);
 vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(cell));
 float wear = mix(mix(hash(tile), hash(tile + vec2(1.0, 0.0)), blend.x), mix(hash(tile + vec2(0.0, 1.0)), hash(tile + vec2(1.0, 1.0)), blend.x), blend.y);
 float grain = hash(floor(world.xz * 95.0)) - 0.5;
 float fine_detail = 1.0 - smoothstep(0.015, 0.065, length(fwidth(world.xz)));
 ALBEDO = grass * (0.97 + broad_variation * 0.03 + (wear - 0.5) * 0.065 + grain * 0.045 * fine_detail);
 ROUGHNESS = 0.91;
 SPECULAR = 0.25;
}
