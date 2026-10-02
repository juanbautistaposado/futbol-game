shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.1,0.2,0.5,1.0);
void fragment() {
 float thread = sin(UV.x*1200.0)*sin(UV.y*950.0);
 float fade = 1.0-smoothstep(0.001,0.02,length(fwidth(UV)));
 float fold = sin(UV.x*62.83+sin(UV.y*12.0)*1.2)*0.022;
 fold += sin(UV.x*110.0-UV.y*22.0)*0.012;
 float edge = pow(abs(cos(UV.x*6.28318)),18.0);
 float hem = 1.0-smoothstep(0.012,0.026,UV.y);
 ALBEDO = mix(tint.rgb*(0.95+thread*0.022*fade+fold-edge*0.12),vec3(0.8,0.82,0.78),hem*0.75);
 ROUGHNESS = 0.8;
 NORMAL_MAP = normalize(vec3(fold*1.5,cos(UV.y*44.0)*0.025,1.0))*0.5+0.5;
 NORMAL_MAP_DEPTH = 0.35;
}
