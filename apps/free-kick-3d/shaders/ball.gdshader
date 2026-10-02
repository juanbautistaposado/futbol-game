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
 float seam=smoothstep(0.001,0.008,best-second);
 ALBEDO=mix(vec3(0.025),dark?vec3(0.03,0.04,0.05):vec3(0.82,0.84,0.8),seam);
 ROUGHNESS=0.65;
}
