precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p)
{
    p=fract(p*vec2(5.3983,5.4472));
   	p+=dot(p.yx,p.xy+vec2(21.5351,14.3137));
    return fract(p.x*p.y*95.4337);
}

float noise(vec2 p)
{
    vec2 f;
    f=fract(p);
    p=floor(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash(p),hash(p+vec2(1.0,0.0)),f.x),
               mix(hash(p+vec2(0.0,1.0)),hash(p+vec2(1.0,1.0)),f.x),f.y);
}

float fbm(vec2 p)
{
    p*=0.09;
    float f=0.;
    float freq=4.0;
    float amp=1.3;
    for(int i=0;i<8;++i)
    {
        f+=noise(p*freq)*amp;
        amp*=0.5;
        freq*=1.79;
    }

    //f+=noise(p*100.0)*0.03;

    return f;
}

float f(vec3 p)
{
    float h=pow(fbm(p.xz), 1.6);
    h+=smoothstep(0.0,1.0,h);
    h=p.y-h;
    return h;
}

vec2 opMin(vec2 a, vec2 b) {
	return a.x < b.x ? a : b;
}

float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

vec2 map(vec3 p) {
	vec2 o = vec2(p.y-1.7, 1.9);
  o = opMin(o, vec2(f(p), 1.0));

  // vec3 r = vec3(3, 0, 3);
  // vec3 k = mod(p-vec3(0,p.y+0.1,0), r) - 0.5*r;
  // o = opMin(o, vec2(sdSphere(k, 0.2), 3.0));
	return o;
}

/* TODO: understand */
vec3 calcNormal(vec3 pos)
{
	vec3 eps = vec3(0.01, 0.0, 0.0);
	vec3 nor = vec3(
		map(pos+eps.xyy).x - map(pos-eps.xyy).x,
		map(pos+eps.yxy).x - map(pos-eps.yxy).x,
		map(pos+eps.yyx).x - map(pos-eps.yyx).x);
	return normalize(nor);
}

/* TODO: understand */
mat3 setCamera(vec3 camOrigin, in vec3 lookAt, float camRotation)
{
	vec3 cw = normalize(lookAt-camOrigin);
	vec3 cp = vec3(sin(camRotation), cos(camRotation),0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
	return mat3(cu, cv, cw);
}

vec2 render(vec3 camOrigin, vec3 rd) {
	float d = 1.0;
	float maxd = 35.0;
	float threshold = 0.001;
	float mat = -0.1;

	for (int i = 0; i < 50; i ++) {
		vec2 o = map(camOrigin + rd * d);

		if (o.x < threshold || d > maxd) break;
		d += o.x/2.0;
		mat = o.y;
		//threshold = d;
	}

	if (d > maxd) mat = -1.0;

	return vec2(d, mat);
}

float shadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k)
{
  float t = mint;
  float res = 1.0;
    for (int i = 0; i < 10000; i++)
    {
        float h = map(ro + rd*t).x;
        if(h<0.001)
            return 0.0;
        res = min(res, k*h/t);
        t += h;
        if (t < maxt) break;
    }
    return res;
}

vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir )  // sun light direction
{
    float fogAmount = 1.0 - exp( -distance*0.05 );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.5,0.6,0.7), // bluish
                           vec3(1.0,0.9,0.7), // yellowish
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
}

void main() {
	vec2 uv = gl_FragCoord.xy / u_resolution.xy;
	uv = -1.0+2.0*uv;
	uv.x *= u_resolution.x/u_resolution.y;
	vec3 camVel = vec3(2.0, 0, 0);
	vec3 lookVel = vec3(0, 0, 0);
	vec3 camOrigin = vec3(0, 5.0, 0)+camVel*u_time;
	vec3 lookAt = vec3(20, 0, 0)+lookVel*u_time+camVel*u_time;

	// float r = 10.0;
	// float rate = 0.3;
	// vec3 camOrigin = vec3(0, 7.0, 0)+vec3(r*sin(rate*u_time), 0, r*cos(rate*u_time));
	// vec3 lookAt = vec3(0, 0, 0);

	// camera-to-world
	mat3 ca = setCamera(camOrigin, lookAt, 0.0);

	// ray direction
	vec3 rd = ca * normalize(vec3(uv.xy, 3.0));

	vec2 o = render(camOrigin, rd);
	vec3 col;
  vec3 lightDir = normalize(vec3(10,4,-6));
	vec3 pos = camOrigin+rd*o.x;
	if (o.y > 0.0) {
		vec3 n = calcNormal(pos);
		float dif = dot(n, lightDir);
    float sh = shadow(pos, lightDir, 0.01, 100.0, 5.0);

		// if(o.y < 1.5) {
		// 	float f = mod(floor(1.0*pos.z) + floor(1.0*pos.x), 2.0);
		// 	col = 0.4 + 0.1*f*vec3(1.0);
		// }

    //col = vec3(sh);
    //col = vec3(dif)*vec3(1.0, 0.8, 0.6)*sh;
		col = vec3(dif)*vec3(1.5, 1.0, 0.3)*sh;

    if (o.y <= 1.0) {
      float x = smoothstep(2.2, 2.7, pos.y);
      col *= mix(vec3(0.14,0.2,0.12), vec3(0.3,0.3,0.3), x);
    } else if (o.y <= 2.0) {
			col = vec3(sh);
		} else if (o.y <= 3.0) {
      col *= vec3(0.3,0.3,0.3)*vec3(sh);
		}
	} else {
		col = vec3(uv.y);
	}

	col = applyFog(col, distance(camOrigin, pos), rd, lightDir);

  col = pow(col, vec3(1.0/2.2));
	gl_FragColor = vec4(col, 1);
}
