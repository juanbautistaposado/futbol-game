shader_type spatial;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
 vec3 p = normalize(local_position);
 float best = -2.0;
 float second = -2.0;
 bool dark = false;
 float phi = 1.618034;
 for (int i=0;i<32;i++) {
  vec3 center;
  if(i<12) {
   int group=i/4;
   float a=(i%2==0)?1.0:-1.0;
   float b=((i/2)%2==0)?phi:-phi;
   center=group==0?vec3(0,a,b):(group==1?vec3(a,b,0):vec3(b,0,a));
  } else if(i<20) {
   int k=i-12;
   center=vec3(k%2==0?1.0:-1.0,(k/2)%2==0?1.0:-1.0,(k/4)%2==0?1.0:-1.0);
  } else {
   int k=i-20;
   float a=k%2==0?1.0/phi:-1.0/phi;
   float b=(k/2)%2==0?phi:-phi;
   int group=k/4;
   center=group==0?vec3(0,b,a):(group==1?vec3(a,0,b):vec3(b,a,0));
  }
  float d=dot(p,normalize(center));
  if(d>best) { second=best; best=d; dark=i<12; }
  else { second=max(second,d); }
 }
 // Millimetre-scale pressed seams and polyurethane grain, filtered at distance.
 float gap = best-second;
 float aa = max(fwidth(gap),0.0003);
 float seam = smoothstep(0.001-aa,0.007+aa,gap);
 vec3 grain_coord = p*360.0;
 float grain_visibility = 1.0-smoothstep(1.4,4.8,length(fwidth(grain_coord)));
 float grain = sin(grain_coord.x)*sin(grain_coord.y)*sin(grain_coord.z)*grain_visibility;
 vec3 panel = dark ? vec3(0.019,0.024,0.028) : vec3(0.65,0.66,0.63);
 ALBEDO = mix(vec3(0.017,0.019,0.018),panel*(1.0+grain*0.015),seam);
 ROUGHNESS = mix(0.78,dark?0.61:0.66,seam)+grain*0.035;
 SPECULAR = 0.28;
 // Bump from a scalar height is continuous over the sphere's UV seam.
 float height = seam*0.00065+grain*0.000065;
 vec3 qx = dFdx(VERTEX);
 vec3 qy = dFdy(VERTEX);
 vec3 rx = cross(qy,NORMAL);
 vec3 ry = cross(NORMAL,qx);
 float determinant = dot(qx,rx);
 if(abs(determinant)>0.000000001) {
  vec3 gradient = (rx*dFdx(height)+ry*dFdy(height))/determinant;
  NORMAL = normalize(NORMAL-gradient);
 }
}
