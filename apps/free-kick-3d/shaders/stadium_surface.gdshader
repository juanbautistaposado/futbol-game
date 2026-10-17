shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(0.4,0.4,0.4,1.0);
uniform float metalness = 0.0;
uniform float base_roughness = 0.85;
uniform float panel_size = 3.0;
uniform float weathering = 0.12;
varying vec3 world_position;
varying vec3 world_normal;
float surface_hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float surface_noise(vec2 p) {
 vec2 cell=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(surface_hash(cell),surface_hash(cell+vec2(1,0)),f.x),
  mix(surface_hash(cell+vec2(0,1)),surface_hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex() {
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
 vec3 n=abs(world_normal);
 vec2 plane=n.y>0.6?world_position.xz:(n.x>0.6?world_position.zy:world_position.xy);
 vec2 uv=plane/max(panel_size,0.1);
 vec2 edge_distance=(0.5-abs(fract(uv)-0.5))*panel_size;
 float joint_distance=min(edge_distance.x,edge_distance.y);
 float aa=max(length(fwidth(plane)),0.002);
 float joints=1.0-smoothstep(0.004-aa,0.009+aa,joint_distance);
 float joint_visible=1.0-smoothstep(0.04,0.35,aa);
 float variation=surface_noise(plane*0.8);
 float grain=surface_noise(plane*45.0);
 float grain_visible=1.0-smoothstep(0.012,0.065,aa);
 vec3 pigment=base_color.rgb*(1.0+(variation-0.5)*weathering);
 pigment*=1.0-joints*joint_visible*0.24;
 pigment*=1.0+(grain-0.5)*0.055*grain_visible;
 ALBEDO=pigment;
 METALLIC=metalness;
 ROUGHNESS=clamp(base_roughness+(variation-0.5)*0.1,0.3,0.98);
 SPECULAR=0.35;
}
