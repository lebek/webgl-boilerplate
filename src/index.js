import { init } from './render';

var canvas = document.createElement('canvas');
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;
document.body.style.margin = 0;
document.body.style.overflow = 'hidden';
document.body.appendChild(canvas);

init(canvas);
