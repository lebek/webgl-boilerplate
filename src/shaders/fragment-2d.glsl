precision highp float;

#define M_PI 3.1415926535897932384626433832795

uniform vec2 u_resolution;
uniform float u_time;

vec2 opMin(vec2 u, vec2 v) {
return (u.x < v.x) ? u : v;
}

mat3 rotMat(float t, int axis) {
	float theta = -t;
	if (axis == 0) {
		return mat3(
			vec3(1, 0, 0),
			vec3(0, cos(theta), -sin(theta)),
			vec3(0, sin(theta), cos(theta))
		);
	} else if (axis == 1) {

	} else {

	}
}

vec3 opRot(vec3 p, float theta, int axis) {
	return rotMat(theta, axis)*p;
}

float dPlane(vec3 p) {
	return p.y;
}

float dSphere(vec3 p, float radius) {
	return length(p) - radius;
}

/* sucky cylinder */
float dCylinder(vec3 p, float radius, float c) {
	return max(length(p.xz)-radius, abs(p.y)-c);
}

/* accurate cylinder */
float sdCylinder(vec3 p, vec2 h) {
	vec2 d = abs(vec2(length(p.xz),p.y)) - h;
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 opCheapBend(vec3 p, float f) {
	float c = cos(f*p.y);
	float s = sin(f*p.y);
	mat2  m = mat2(c,-s,s,c);
	return vec3(m*p.xy,p.z);
}

vec2 mapNoGround(vec3 p) {
	//vec2 o = vec2(dSphere(p-vec3(0,1,0), 1.0), 90.0);
	//o = opMin(o, vec2(dSphere(p-vec3(3,1,-2), 1.0), 40.0));
	vec3 repeat = vec3(5,0,5);
	//vec3 c = floor(p/repeat);
	//vec3 k = mod(opRot(p, abs(sin(c.x))*0.2*abs(sin(c.z)), 0), repeat) - 0.5*repeat;
	vec3 k = mod(p, repeat) - 0.5*repeat;
	k = p;
	//o = opMin(o, vec2(sdCylinder(k, vec2(0.2, 5.0-2.5*sin(2.0*u_time+c.x))), 30.0));
	return vec2(sdCylinder(opCheapBend(k-vec3(0,0.4,0), 0.2+sin(u_time)*0.3), vec2(0.1, 2.2)), 10.0);
}

vec2 map(vec3 p) {
	vec2 o = mapNoGround(p);
	o = opMin(o, vec2(dPlane(p), 1.0));
	return o;
}

/* TODO: understand */
vec3 calcNormal(vec3 pos)
{
	vec3 eps = vec3(0.001, 0.0, 0.0);
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
		float maxd = 40.0;
		float threshold = 0.001;
		float mat = -0.1;

		for (int i = 0; i < 50; i ++) {
			vec2 o = map(camOrigin + rd * d);
			if (o.x < threshold) break;
			d += o.x/2.0;
			mat = o.y;
		}

		if (d > maxd) mat = -1.0;

		return vec2(d, mat);
	}

	vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
	{
		return a + b*cos(6.28318*(c*t+d));
	}

	void main() {
		vec2 uv = gl_FragCoord.xy / u_resolution.xy;
		uv = -1.0+2.0*uv;
		uv.x *= u_resolution.x/u_resolution.y;
		//vec3 camVel = vec3(-3.0, 0, 0.5);
		//vec3 camVel = vec3(0, 0, 0);
		float r = 10.0;
		float rate = 0.3;
		vec3 camOrigin = vec3(0, 7.0, 0)+vec3(r*sin(rate*u_time), 0, r*cos(rate*u_time));
		vec3 lookAt = vec3(0, 0, 0);

		// camera-to-world
		mat3 ca = setCamera(camOrigin, lookAt, 0.0);

		// ray direction
		vec3 rd = ca * normalize(vec3(uv.xy, 2.0));

		vec2 o = render(camOrigin, rd);
		if (o.y > 0.0) {
			vec3 pos = camOrigin+rd*o.x;
			vec3 n = calcNormal(pos);
			float l = dot(n, vec3(1,1,0));
			vec3 col = 0.45 + 0.3*sin(vec3(0.05, 0.08, 0.10)*o.y);

			if(o.y < 1.5) {
				float f = mod(floor(1.0*pos.z) + floor(1.0*pos.x), 2.0);
				col = 0.4 + 0.1*f*vec3(1.0);
				float t = pow(mapNoGround(pos).x*0.03, 0.3);
				col *= pal(t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20));
				//col = vec3(0,0,0);
			}

			gl_FragColor = vec4(col*l, 1);
			} else {
				gl_FragColor = vec4(uv.y,1.0,1.0,1);
				gl_FragColor = vec4(uv.y,uv.y,uv.y,1);
			}
		}
