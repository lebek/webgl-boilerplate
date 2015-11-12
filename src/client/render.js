import * as twgl from 'twgl.js';
import Clock from './clock';
import { debounce } from './util';

import vertex2d from './shaders/vertex-2d.glsl';
import fragment2d from './shaders/fragment-2d.glsl';

export function init(canvas) {
  var gl = twgl.getWebGLContext(canvas),
    clock = new Clock();

  function onresize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    setup(gl, canvas, clock, canvas.width, canvas.height);
  }

  window.addEventListener('resize', debounce(onresize, 250));

  onresize();
  clock.start();
}

function setup(gl, canvas, clock, width, height) {
  var program = twgl.createProgramFromSources(gl, [vertex2d, fragment2d]);
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.viewport(0, 0, width, height);
  gl.disable(gl.DEPTH_TEST);
  gl.useProgram(program);

  var resolutionLocation = gl.getUniformLocation(program, 'u_resolution');
  gl.uniform2f(resolutionLocation, width, height);

  clock.ontick = function (t) {
    var timeLocation = gl.getUniformLocation(program, 'u_time');
    gl.uniform1f(timeLocation, t);

    var positionLocation = gl.getAttribLocation(program, 'a_position');

    var buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        new Float32Array([
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
            -1.0,  1.0,
             1.0, -1.0,
             1.0,  1.0]),
        gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }
}
