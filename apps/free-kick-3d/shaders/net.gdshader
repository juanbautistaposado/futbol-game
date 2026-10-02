shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never;
uniform vec3 impact = vec3(0.0,1.2,54.3);
uniform float age = 2.0;
uniform float side = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
void vertex() {
 float distance_to_hit = length(VERTEX.xy-impact.xy);
 float frame = smoothstep(0.0,0.35,4.2-abs(VERTEX.x))*smoothstep(0.0,0.25,VERTEX.y)*smoothstep(0.0,0.25,2.9-VERTEX.y);
 float back = smoothstep(52.5,54.2,abs(VERTEX.z));
 float envelope = exp(-age*3.5)*smoothstep(0.0,0.055,age)*(1.0-smoothstep(1.1,1.4,age));
 VERTEX.z += side*0.65*frame*back*exp(-distance_to_hit*0.65)*sin(age*19.0-distance_to_hit*2.0)*envelope;
}
void fragment() { ALBEDO=vec3(0.52,0.58,0.54); ROUGHNESS=0.9; ALPHA=opacity; }
