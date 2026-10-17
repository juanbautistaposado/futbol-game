shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never;
uniform vec3 impact = vec3(0.0,1.2,54.3);
uniform float age = 2.0;
uniform float side = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
void vertex() {
 vec3 rest = VERTEX;
 float depth = abs(rest.z);
 float width_tension = smoothstep(0.0,0.25,4.2-abs(rest.x));
 float floor_tension = smoothstep(0.0,0.18,rest.y);
 float top_tension = smoothstep(0.0,0.20,2.9-rest.y);
 float front_tension = smoothstep(52.5,52.75,depth);
 float rear_tension = smoothstep(0.0,0.20,54.3-depth);
 float bow_x = sin(clamp((rest.x+4.2)/8.4,0.0,1.0)*3.14159265);
 float bow_y = sin(clamp(rest.y/2.9,0.0,1.0)*3.14159265);
 float bow_z = sin(clamp((depth-52.5)/1.8,0.0,1.0)*3.14159265);
 float frame;
 // Each panel has a little fabric slack, with its perimeter tied to the frame.
 if (abs(rest.x)>4.185) {
  VERTEX.x -= sign(rest.x)*0.025*bow_y*bow_z;
  frame = floor_tension*top_tension*front_tension*rear_tension;
 } else if (rest.y>2.885) {
  VERTEX.y -= 0.035*bow_x*bow_z;
  frame = width_tension*front_tension*rear_tension;
 } else {
  VERTEX.z -= side*0.025*bow_x*bow_y;
  frame = width_tension*floor_tension*top_tension*front_tension;
 }
 float distance_to_hit = length(rest-impact);
 float envelope = exp(-age*3.5)*smoothstep(0.0,0.055,age)*(1.0-smoothstep(1.1,1.4,age));
 VERTEX.z += side*0.65*frame*exp(-distance_to_hit*0.65)*sin(age*19.0-distance_to_hit*2.0)*envelope;
}
void fragment() {
 ALBEDO=vec3(0.86,0.89,0.85);
 ROUGHNESS=0.84;
 SPECULAR=0.18;
 ALPHA=opacity;
}
