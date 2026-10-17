shader_type spatial;
render_mode cull_disabled, skip_vertex_transform, diffuse_burley;
uniform sampler2D colour_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D clothing_atlas : filter_linear_mipmap, repeat_disable;
uniform float cheer : hint_range(0.0,1.0) = 0.0;
varying vec2 atlas_uv;
varying vec3 shirt_colour;
varying vec3 shorts_colour;
vec3 hue_colour(float hue) {
	vec3 p = abs(fract(vec3(hue)+vec3(0.0,0.6666667,0.3333333))*6.0-3.0);
	return mix(vec3(1.0),clamp(p-1.0,0.0,1.0),0.55)*0.23;
}
void vertex() {
	vec3 root = (MODEL_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 camera_direction = normalize(vec3(CAMERA_POSITION_WORLD.x-root.x,0.0,CAMERA_POSITION_WORLD.z-root.z));
	vec3 local_x = normalize(MODEL_MATRIX[0].xyz);
	vec3 local_z = normalize(MODEL_MATRIX[2].xyz);
	float angle = atan(dot(camera_direction,local_x),dot(camera_direction,local_z));
	float view = mod(floor(angle*1.2732395447+0.5)+8.0,8.0);
	// The atlas contains eight complete views of each pose, with transparent padding.
	atlas_uv = vec2((UV.x+view)/8.0,(UV.y+INSTANCE_CUSTOM.a)/2.0);
	shirt_colour = OUTPUT_IS_SRGB ? COLOR.rgb : pow(COLOR.rgb,vec3(2.2));
	shorts_colour = hue_colour(INSTANCE_CUSTOM.b);
	vec3 right = normalize(vec3(camera_direction.z,0.0,-camera_direction.x));
	float scale = length(MODEL_MATRIX[1].xyz);
	float phase = INSTANCE_CUSTOM.r*6.2831853;
	float wave = sin(TIME*(1.25+INSTANCE_CUSTOM.g)+phase);
	vec3 world = root+right*VERTEX.x*scale+vec3(0.0,VERTEX.y*scale,0.0);
	world += right*wave*0.006*scale;
	world.y += max(0.0,wave)*cheer*0.07*scale;
	VERTEX = (VIEW_MATRIX*vec4(world,1.0)).xyz;
	// Cards keep a pitch-facing normal so stadium light also shades far crowds.
	NORMAL = (VIEW_MATRIX*vec4(normalize(local_z+vec3(0.0,0.70,0.0)),0.0)).xyz;
	// Entirely rear-facing batches still contain cards near the camera plane.
	// Collapse cards whose body centre is behind it before rasterising alpha.
	vec3 centre_in_view = (VIEW_MATRIX*vec4(root+vec3(0.0,scale,0.0),1.0)).xyz;
	if (centre_in_view.z > -0.10) VERTEX = vec3(0.0,0.0,1.0);
}
void fragment() {
	vec4 original = texture(colour_atlas,atlas_uv);
	vec2 clothing = texture(clothing_atlas,atlas_uv).rg;
	vec3 body = mix(original.rgb,original.rgb*shirt_colour,clothing.r);
	body = mix(body,original.rgb*shorts_colour,clothing.g);
	ALBEDO = body;
	ROUGHNESS = 0.92;
	SPECULAR = 0.12;
	AO = 0.88;
	ALPHA = original.a;
	ALPHA_SCISSOR_THRESHOLD = 0.35;
}
