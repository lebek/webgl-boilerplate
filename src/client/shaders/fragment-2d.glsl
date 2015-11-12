precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  gl_FragColor = vec4(uv,0.5+0.5*sin(u_time),1);
}
