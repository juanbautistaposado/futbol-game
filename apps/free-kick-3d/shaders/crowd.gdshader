shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float cheer : hint_range(0.0,1.0) = 0.0;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 shirt_color;
varying vec3 shorts_color;
vec3 hue_color(float hue) {
	vec3 p = abs(fract(vec3(hue)+vec3(0.0,0.6666667,0.3333333))*6.0-3.0);
	return mix(vec3(1.0),clamp(p-1.0,0.0,1.0),0.55)*0.23;
}
void vertex() {
	float phase = INSTANCE_CUSTOM.r*6.2831853;
	float wave = sin(TIME*(1.25+INSTANCE_CUSTOM.g)+phase);
	float upper = smoothstep(0.65,1.55,VERTEX.y);
	VERTEX.x += wave*0.009*upper;
	VERTEX.z += cos(TIME*1.1+phase)*0.006*upper;
	VERTEX.y += max(0.0,wave)*cheer*0.07;
	shirt_color = OUTPUT_IS_SRGB ? COLOR.rgb : pow(COLOR.rgb,vec3(2.2));
	shorts_color = hue_color(INSTANCE_CUSTOM.b);
}
void fragment() {
	vec3 original = texture(albedo_map,UV).rgb;
	vec3 cloth = original*shirt_color;
	vec3 body = mix(original,cloth,UV2.x);
	float dark_fabric = 1.0-smoothstep(0.06,0.18,max(original.r,max(original.g,original.b)));
	body = mix(body,shorts_color*(0.8+dot(original,vec3(0.2126,0.7152,0.0722))*3.0),UV2.y*dark_fabric);
	ALBEDO = body;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	AO = 0.88;
}
